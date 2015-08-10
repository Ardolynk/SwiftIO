//
//  TCPChannel.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 6/23/15.
//  Copyright (c) 2015 schwa.io. All rights reserved.
//

import Foundation

import Darwin

// TODO: This is a very very very very early WIP

public class TCPChannel {

    public let address:Address
    public let port:UInt16
    public var readHandler:(Void -> Void)? = nil
    public var errorHandler:(ErrorType -> Void)? = loggingErrorHandler

    private var resumed:Bool = false
    private var queue:dispatch_queue_t!
    private var socket:Int32!

    public init(address:Address, port:UInt16, readHandler:(Void -> Void)? = nil) {
        self.address = address
        self.port = port
        if let readHandler = readHandler {
            self.readHandler = readHandler
        }
    }

    public convenience init(hostname:String = "0.0.0.0", port:UInt16, family:ProtocolFamily? = nil, readHandler:(Void -> Void)? = nil) throws {
        let addresses:[Address] = try Address.addresses(hostname, `protocol`: .TCP, family: family)
        self.init(address:addresses[0], port:port, readHandler:readHandler)
    }

    public func resume() throws {
        debugLog?("Resuming")

        socket = Darwin.socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)
        if socket < 0 {
            errorHandler?(Error.generic("socket() failed"))
            return
        }

//let flags = Darwin.fcntl(socket, F_GETFL, 0)
//fcntl(socket, F_SETFL, flags | O_NONBLOCK)

        var addr = address.to_sockaddr(port: port)

        let result = withUnsafePointer(&addr) {
            (ptr:UnsafePointer <sockaddr>) -> Int32 in
            return Darwin.connect(socket, ptr, socklen_t(sizeof(sockaddr)))
        }

        guard result == 0 else {
            cleanup()
            throw Error.posix(errno, "connect() failed")
        }

        queue = dispatch_queue_create("io.schwa.SwiftIO.TCP", DISPATCH_QUEUE_CONCURRENT)
        guard queue != nil else {
            cleanup()
            throw(Error.generic("dispatch_queue_create() failed"))
        }

    }

    public func cancel() throws {
    }

    public func send(data:NSData, address:Address! = nil, writeHandler:((Bool,Error?) -> Void)? = loggingWriteHandler) throws {
        // TODO
    }

    internal func read() {
        // TODO

    }

    internal func cleanup() {
        if let socket = self.socket {
            Darwin.close(socket)
        }
        self.socket = nil
        self.queue = nil
    }
}

// MARK: -

internal func loggingReadHandler(datagram:Datagram) {
    debugLog?("READ")
}

internal func loggingErrorHandler(error:ErrorType) {
    debugLog?("ERROR: \(error)")
}

internal func loggingWriteHandler(success:Bool, error:Error?) {
    if success {
        debugLog?("WRITE")
    }
    else {
        loggingErrorHandler(error!)
    }
}
