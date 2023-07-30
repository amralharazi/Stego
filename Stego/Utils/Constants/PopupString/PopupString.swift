//
//  PopupString.swift
//  Stegno
//
//  Created by عمرو on 19.06.2023.
//

import Foundation

enum PopupString {
    case error(ErrorType)
    case poppup(PopupType)
    
    enum ErrorType: String {
        case title = "Error"
        case unexpectedError = "An unexpected error happened."
        case noEncodedSecret = "Found no secret in this image."
        case largeSecret = "The secret is too large and cannot be embedded into the uploaded image."
    }
    
    enum PopupType: String {
        case noImageToEncode = "Add an image to encode your secret into."
        case noSecretToEncode =  "Enter a secret to be encoded."
        case noSecretImageToEncode =  "Enter a secret image to be encoded."
        case noImageToDecode = "Add an image to decode your secret."
    }
}

