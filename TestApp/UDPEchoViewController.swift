//
//  UDPEchoViewController.swift
//  SwiftIO
//
//  Created by Bart Cone on 12/23/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Cocoa

import SwiftIO

class UDPEchoViewController: NSViewController {
    
    var udpServer: UDPChannel!
    var udpClient: UDPChannel!
    var family: ProtocolFamily?
    let port: UInt16 = 20000

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: On my iMac INET6 breaks and seems to be the default when resolving local host
        family = .INET

        // server
        udpServer = try! UDPChannel(hostname: "localhost", port: port, family: family) {
            (datagram) in
            log?.debug("UDPEcho: Server received - \(datagram)")
            try! self.udpServer.send(datagram.data, address: datagram.from.0, port: datagram.from.1, writeHandler: nil)
        }

        // client
        // TODO: UDPChannels should not need an address, just to write.
        udpClient = try! UDPChannel(hostname: "localhost", port: port + 1, family: family) {
            (datagram) in
            log?.debug("UDPEcho: Client received - \(datagram)")
        }
        try! udpClient.resume()
    }

    @IBAction func startStopServer(sender: SwitchControl) {
        if sender.on {
            try! udpServer.resume()
        }
        else {
            try! udpServer.cancel()
        }
    }

    @IBAction func pingServer(sender: AnyObject) {
        let data = "0xDEADBEEF".dataUsingEncoding(NSUTF8StringEncoding)!
        let remoteServer = try! Address(address: "localhost", family: family)
        try! udpClient.send(data, address: remoteServer, port: port)
    }


}