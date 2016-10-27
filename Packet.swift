//
//  Packet.swift
//  BluetoothTest
//
//  Created by Rich Long on 27/10/2016.
//  Copyright © 2016 Rich Long. All rights reserved.
//

import Foundation

//Utility class
class Packet {
    
    //Creates CRC
    //@param: Array of Uint8 (hex) values
    //@return: uint CRC calculation
    class func getCRC(forPacket data:[UInt8]) -> UInt8 {
        
        var counter = 0
        var total:UInt8 = data.first!
        //Skips first and last
        while counter < data.count - 2 {
            total = total + data[counter + 1]
            counter += 1
        }
        return (total & 0xFF)
    }
    
    //Creates packet
    //@param: firstBytes = first bytes of packet with instruction
    //@return: array of UInt8 Bytes
    class func createPacket(firstBytes:[UInt8]) -> [UInt8] {
        
        var packet:[UInt8] = []
        
        //Create empty packet - 16 bit, last bit is crc added later
        var counter = 0
        while counter < 15 {
            packet.append(0x00)
            counter += 1
        }
        
        //Add existing bytes
        counter = 0
        while counter < firstBytes.count {
            packet[counter] = firstBytes[counter]
            counter += 1
        }
        
        //Add CRC
        packet.append(getCRC(forPacket: packet))
        
        return packet
    }
    
}
