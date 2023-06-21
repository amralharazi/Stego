//
//  StringExtension.swift
//  Stegno
//
//  Created by عمرو on 18.06.2023.
//

import Foundation

extension String {
    func pad(toSize: Int, rightDirection: Bool = true) -> String {
        var padded = self
        for _ in 0..<(toSize - self.count) {
            if rightDirection {
                padded = padded + "0"
            } else {
                padded = "0" + padded
            }
        }
        return padded
    }
    
    func binaryToString() -> String? {
        guard let asciiValue = UInt8(self, radix: 2) else {
            return nil
        }
        
        let character = Character(UnicodeScalar(asciiValue))
        return String(character)
    }
    
    var binary: String {
        let binaryData = Data(self.utf8)
        return  binaryData.reduce("") { (acc, byte) -> String in
            acc + String(byte, radix: 2).pad(toSize: 8, rightDirection: false)
        }
    }
    
    func removeTrailingZeros() -> String {
        return self.trimmingCharacters(in: CharacterSet(charactersIn: "0"))
    }
}
