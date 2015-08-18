//
//  BinaryStreams.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 6/25/15.
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




import SwiftUtilities

public protocol BinaryInputStream {
    func read(length:Int) throws -> DispatchData <Void>
}

// MARK: -

public extension BinaryInputStream {

    func read <T:BinaryDecodable> () throws -> T {
        return try read(sizeof(T))
    }

    func read <T:BinaryDecodable> (size:Int) throws -> T {
        let data = try read(size)
        return try data.map() {
            (data, buffer) in
            let value = try T.decode(buffer)
            return value
        }
    }
}

// MARK: -

public protocol BinaryInputStreamable {
     static func readFrom <Stream:BinaryInputStream> (stream:Stream) throws -> Self
}

public extension BinaryInputStream {
    func read <T:BinaryInputStreamable> () throws -> T {
        return try T.readFrom(self)
    }
}

// MARK: -

//extension Int32: BinaryInputStreamable {
//     public static func readFrom <Stream:BinaryInputStream> (stream:Stream, handler:(ReadResult <Int32>) -> Void) throws {
//
////        try! stream.read() {
////            (readResult:ReadResult <Int32>) in
////
////            handler(readResult)
////
////        }
//     }
//}
