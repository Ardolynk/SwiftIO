//
//  Socket.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/9/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Darwin

import SwiftUtilities

public class Socket {

    public private(set) var descriptor: Int32

    public init(_ descriptor: Int32) {
        self.descriptor = descriptor
    }

    deinit {
        if descriptor >= 0 {
            tryElseFatalError() {
                try close()
            }
        }
    }

    func close() throws {
        Darwin.close(descriptor)
        descriptor = -1
    }

}

// MARK: Socket options

extension Socket {

    public typealias SocketType = Int32

    public var type: SocketType {
        get {
            return socketOptions.type
        }
    }

    public func setNonBlocking(nonBlocking: Bool) throws {
        SwiftIO.setNonblocking(descriptor, nonBlocking)
    }

}

// MARK: -

public extension Socket {

    convenience init(domain: Int32, type: Int32, `protocol`: Int32) throws {
        let descriptor = Darwin.socket(domain, type, `protocol`)
        if descriptor < 0 {
            throw Errno(rawValue: errno) ?? Error.Unknown
        }
        self.init(descriptor)
    }

}

// MARK: -

public extension Socket {

    func connect(address: Address) throws {
        var addr = address.to_sockaddr()
        let status = Darwin.connect(descriptor, &addr, socklen_t(addr.sa_len))
        guard status == 0 else {
            throw Errno(rawValue: errno) ?? Error.Unknown
        }
    }

    func bind(address: Address) throws {
        var addr = address.to_sockaddr()
        let status = Darwin.bind(descriptor, &addr, socklen_t(addr.sa_len))
        if status != 0 {
            throw Errno(rawValue: errno) ?? Error.Unknown
        }
    }

    func listen(backlog: Int = 1) throws {
        precondition(type == SOCK_STREAM, "\(__FUNCTION__) should only be used on `SOCK_STREAM` sockets")

        let status = Darwin.listen(descriptor, Int32(backlog))
        if status != 0 {
            throw Errno(rawValue: errno) ?? Error.Unknown
        }
    }

    func accept() throws -> (Socket, Address) {
        precondition(type == SOCK_STREAM, "\(__FUNCTION__) should only be used on `SOCK_STREAM` sockets")

        var incoming = sockaddr()
        var incomingSize = socklen_t(sizeof(sockaddr))
        let socket = Darwin.accept(descriptor, &incoming, &incomingSize)
        if socket < 0 {
            throw Errno(rawValue: errno) ?? Error.Unknown
        }

        let address = try Address.fromSockaddr(incoming)
        return (Socket(socket), address)
    }

    func getAddress() throws -> Address {
        var addr = sockaddr()
        var addrSize = socklen_t(sizeof(sockaddr))
        let status = getsockname(descriptor, &addr, &addrSize)
        if status != 0 {
            throw Errno(rawValue: errno) ?? Error.Unknown
        }
        return try Address.fromSockaddr(addr)
    }

    func getPeer() throws -> Address {
        var addr = sockaddr()
        var addrSize = socklen_t(sizeof(sockaddr))
        let status = getpeername(descriptor, &addr, &addrSize)
        if status != 0 {
            throw Errno(rawValue: errno) ?? Error.Unknown
        }
        return try Address.fromSockaddr(addr)
    }
}

// MARK: -

public extension Socket {

    @available(*, deprecated, message="Hardcoded for IPV4")
    static func TCP() throws -> Socket {
        return try Socket(domain: PF_INET, type: SOCK_STREAM, `protocol`: IPPROTO_TCP)
    }

    @available(*, deprecated, message="Hardcoded for IPV4")
    static func UDP() throws -> Socket {
        return try Socket(domain: PF_INET, type: SOCK_DGRAM, `protocol`: IPPROTO_UDP)
    }

}
