//
//  UDPMavlinkReceiver.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 4/22/15.
//
//  Copyright (c) 2014, Jonathan Wight
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Darwin

import SwiftUtilities

/**
 *  A GCD based UDP listener.
 */
public class UDPChannel {
    
    public let address: Address
    public let port: UInt16
    public var qos = QOS_CLASS_DEFAULT
    
    public var readHandler: (Datagram -> Void)? = loggingReadHandler
    public var errorHandler: (ErrorType -> Void)? = loggingErrorHandler
    
    private var resumed: Bool = false
    private var receiveQueue: dispatch_queue_t!
    private var sendQueue: dispatch_queue_t!
    private var source: dispatch_source_t!
    private var socket: Socket!
    
    // MARK: - Initialization
    
    public init(address: Address, port: UInt16, readHandler: (Datagram -> Void)? = nil) throws {
        self.address = address
        self.port = port
        if let readHandler = readHandler {
            self.readHandler = readHandler
        }
    }
    
    public convenience init(hostname: String = "0.0.0.0", port: UInt16, family: ProtocolFamily? = nil, readHandler: (Datagram -> Void)? = nil) throws {
        let addresses: [Address] = try Address.addresses(hostname, `protocol`: .UDP, family: family)
        try self.init(address: addresses[0], port: port, readHandler: readHandler)
    }
    
    // MARK: - Actions
    
    public func resume() throws {
        log?.debug("Resuming")
        
        do {
            socket = try Socket.UDP()
        }
        catch let error {
            cleanup()
            errorHandler?(error)
        }
        
        // set reuse socket option
        socket.reuse = true
        
        let queueAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos, 0)
        
        try createReceiveQueue(withQueueAttribute: queueAttribute)
        try createSendQueue(withQueueAttribute: queueAttribute)
        
        source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, UInt(socket.descriptor), 0, receiveQueue)
        guard source != nil else {
            cleanup()
            throw Error.Generic("dispatch_source_create() failed")
        }
        
        dispatch_source_set_cancel_handler(source) {
            [weak self] in
            guard let strong_self = self else {
                return
            }
            
            log?.debug("Cancel handler")
            
            strong_self.cleanup()
            strong_self.resumed = false
        }
        
        dispatch_source_set_event_handler(source) {
            [weak self] in
            guard let strong_self = self else {
                return
            }
            
            do {
                try strong_self.read()
            }
            catch let error {
                strong_self.errorHandler?(error)
            }
        }
        
        dispatch_source_set_registration_handler(source) {
            [weak self] in
            guard let strong_self = self else {
                return
            }
            
            do {
                try strong_self.socket.bind(strong_self.address, port: strong_self.port)
                
                strong_self.resumed = true
                
                log?.debug("Listening on \(strong_self.address)")
            }
            catch let error {
                strong_self.errorHandler?(error)
                
                tryElseFatalError() {
                    try strong_self.cancel()
                }
                
                return
            }
        }
        
        dispatch_resume(source)
    }
    
    public func cancel() throws {
        if resumed == true {
            assert(source != nil, "Cancel called with source = nil.")
            dispatch_source_cancel(source)
        }
    }
    
    public func send(data: NSData, address: Address? = nil, port: UInt16? = nil, writeHandler: ((Bool,ErrorType?) -> Void)? = loggingWriteHandler) throws {
        let data = DispatchData <Void> (start: data.bytes, count: data.length)
        try send(data, address: address ?? self.address, port: port ?? self.port, writeHandler: writeHandler)
    }
    
    public func send(data: DispatchData <Void>, address: Address! = nil, port: UInt16, writeHandler: ((Bool,ErrorType?) -> Void)? = loggingWriteHandler) throws {
        precondition(receiveQueue != nil, "Cannot send data without a queue")
        precondition(resumed == true, "Cannot send data on unresumed queue")
        
        dispatch_async(sendQueue) {
            
            [weak self] in
            guard let strong_self = self else {
                return
            }
            
            log?.debug("Send")
            
            let address: Address = address ?? strong_self.address
            var addr = address.to_sockaddr(port: port)
            
            let result = data.createMap() {
                (_, buffer) in
                return Darwin.sendto(strong_self.socket.descriptor, buffer.baseAddress, buffer.count, 0, &addr, socklen_t(addr.sa_len))
            }
            
            
            if result == data.length {
                writeHandler?(true, nil)
            }
            else if result < 0 {
                writeHandler?(false, Error.Generic("sendto() failed"))
            }
            if result < data.length {
                writeHandler?(false, Error.Generic("sendto() failed"))
            }
        }
    }
    
    internal func read() throws {
        
        let data: NSMutableData! = NSMutableData(length: 4096)
        
        var addressData = Array <Int8> (count: Int(SOCK_MAXADDRLEN), repeatedValue: 0)
        let (result, address, port) = try addressData.withUnsafeMutableBufferPointer() {
            (inout ptr: UnsafeMutableBufferPointer <Int8>) -> (Int, Address?, UInt16?) in
            var addrlen: socklen_t = socklen_t(SOCK_MAXADDRLEN)
            let result = Darwin.recvfrom(socket.descriptor, data.mutableBytes, data.length, 0, UnsafeMutablePointer<sockaddr> (ptr.baseAddress), &addrlen)
            guard result >= 0 else {
                return (result, nil, nil)
            }
            
            let addr = UnsafeMutablePointer<sockaddr> (ptr.baseAddress).memory
            let address = try Address(addr: addr)
            
            let port = UInt16(networkEndian: addr.port)
            return (result, address, port)
        }
        
        guard result >= 0 else {
            let error = Error.Generic("recvfrom() failed")
            errorHandler?(error)
            throw error
        }
        
        data.length = result
        let datagram = Datagram(from: (address!, port!), timestamp: Timestamp(), data: DispatchData <Void> (buffer: data.toUnsafeBufferPointer()))
        readHandler?(datagram)
    }
    
    // MARK: - GCD
    
    private func createReceiveQueue(withQueueAttribute attribute: dispatch_queue_attr_t!) throws {
        receiveQueue = dispatch_queue_create("io.schwa.SwiftIO.UDP.receiveQueue", attribute)
        guard receiveQueue != nil else {
            cleanup()
            throw Error.Generic("dispatch_queue_create() failed")
        }
    }
    
    private func createSendQueue(withQueueAttribute attribute: dispatch_queue_attr_t!) throws {
        sendQueue = dispatch_queue_create("io.schwa.SwiftIO.UDP.sendQueue", attribute)
        guard sendQueue != nil else {
            cleanup()
            throw Error.Generic("dispatch_queue_create() failed")
        }
    }
    
    // MARK: - Cleanup
    
    internal func cleanup() {
        defer {
            socket = nil
            receiveQueue = nil
            sendQueue = nil
            source = nil
        }
        
        do {
            try socket.close()
        }
        catch let error {
            errorHandler?(error)
        }
    }
}