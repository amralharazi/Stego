//
//  PVDRange.swift
//  Stegno
//
//  Created by عمرو on 18.06.2023.
//

import Foundation

struct PVD {
    enum Range {
        case r1
        case r2
        case r3
        case r4
        case r5
        case r6
        
        var lowerLimit: Double {
            switch self {
            case .r1:
                return 0
            case .r2:
                return 8
            case .r3:
                return 16
            case .r4:
                return 32
            case .r5:
                return 64
            case .r6:
                return 128
            }
        }
        
        var upperLimit: Double {
            switch self {
            case .r1:
                return 7
            case .r2:
                return 15
            case .r3:
                return 31
            case .r4:
                return 63
            case .r5:
                return 127
            case .r6:
                return 255
            }
        }
        
        var numberOfBits: Int {
            switch self {
            case .r1, .r2:
                return 8
            case .r3:
                return 16
            case .r4:
                return 32
            case .r5:
                return 64
            case .r6:
                return 128
            }
        }
    }
    
    static func getCase(for number: Int) -> PVD.Range {
        switch number {
        case 0...7:
            return .r1
        case 8...15:
            return .r2
        case 16...31:
            return .r3
        case 32...63:
            return .r4
        case 64...127:
            return .r5
        case 128...255:
            return .r6
        default:
            return .r1
        }
    }
    
    static func satisfiesFOBCheck(for colors: (Int, Int)) -> Bool {
        
        let difference = colors.1 - colors.0
        let pvdCase = PVD.getCase(for: abs(difference))
        let m = pvdCase.upperLimit - Double(difference)
        
        let flooredHalfM = Int(floor(m/2))
        let ceiledHalfM = Int(ceil(m/2))
        
        let deltaColors: (Int, Int)
        if difference % 2 == 0 {
            deltaColors = (colors.0 - ceiledHalfM, colors.1 + flooredHalfM)
        } else {
            deltaColors = (colors.0 - flooredHalfM, colors.1 + ceiledHalfM)
        }
        
        if (0...255 ~= deltaColors.0) && (0...255 ~= deltaColors.1) {
            return true
        }
        return false
    }
}
