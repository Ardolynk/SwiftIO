//
//  IntegerType+BinaryInputStreamable.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/5/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

private func readFrom <T: BinaryDecodable> (stream: BinaryInputStream) throws -> T {
    let size = sizeof(T)
    let data = try stream.readData(length: size)
    return try data.createMap() {
        (data, buffer) in
        let value = try T.decode(buffer, endianness: stream.endianness)
        return value
    }
}

// MARK: -

extension UInt: BinaryInputStreamable {
    public static func readFrom(stream: BinaryInputStream) throws -> UInt {
        return try SwiftIO.readFrom(stream)
    }
}

extension UInt8: BinaryInputStreamable {
    public static func readFrom(stream: BinaryInputStream) throws -> UInt8 {
        return try SwiftIO.readFrom(stream)
    }
}

extension UInt16: BinaryInputStreamable {
    public static func readFrom(stream: BinaryInputStream) throws -> UInt16 {
        return try SwiftIO.readFrom(stream)
    }
}

extension UInt32: BinaryInputStreamable {
    public static func readFrom(stream: BinaryInputStream) throws -> UInt32 {
        return try SwiftIO.readFrom(stream)
    }
}

extension UInt64: BinaryInputStreamable {
    public static func readFrom(stream: BinaryInputStream) throws -> UInt64 {
        return try SwiftIO.readFrom(stream)
    }
}

// MARK: -

extension Int: BinaryInputStreamable {
    public static func readFrom(stream: BinaryInputStream) throws -> Int {
        return try SwiftIO.readFrom(stream)
    }
}

extension Int8: BinaryInputStreamable {
    public static func readFrom(stream: BinaryInputStream) throws -> Int8 {
        return try SwiftIO.readFrom(stream)
    }
}

extension Int16: BinaryInputStreamable {
    public static func readFrom(stream: BinaryInputStream) throws -> Int16 {
        return try SwiftIO.readFrom(stream)
    }
}

extension Int32: BinaryInputStreamable {
    public static func readFrom(stream: BinaryInputStream) throws -> Int32 {
        return try SwiftIO.readFrom(stream)
    }
}

extension Int64: BinaryInputStreamable {
    public static func readFrom(stream: BinaryInputStream) throws -> Int64 {
        return try SwiftIO.readFrom(stream)
    }
}

// MARK: -

extension Float: BinaryInputStreamable {
    public static func readFrom(stream: BinaryInputStream) throws -> Float {
        return try SwiftIO.readFrom(stream)
    }
}

extension Double: BinaryInputStreamable {
    public static func readFrom(stream: BinaryInputStream) throws -> Double {
        return try SwiftIO.readFrom(stream)
    }
}
