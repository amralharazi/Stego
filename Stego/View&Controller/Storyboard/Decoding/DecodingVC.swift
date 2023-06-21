//
//  DecodingVC.swift
//  Stegno
//
//  Created by عمرو on 18.06.2023.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class DecodingVC: UIViewController {
    
    // MARK: Subviews
    @IBOutlet weak var photoIV: UIImageView!
    @IBOutlet weak var secretTextView: RoundedTextView!
    
    // MARK: Properties
    private let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.image])
    private var imageToBeDecoded: UIImage?
    private var secret = ""
    
    // MARK: Viewcycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
    }
    
    // MARK: Helpers
    private func configureSubviews(){
        configureDocumentPicker()
        addGestureRecognizer()
        configureTextView()
    }
    
    private func addGestureRecognizer(){
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(gesture:)))
        photoIV.addGestureRecognizer(tapGesture)
        photoIV.isUserInteractionEnabled = true
        photoIV.tag = 0
    }
    
    private func configureTextView(){
        secretTextView.text = "Secret will appear here"
        secretTextView.textColor = .lightGray
        secretTextView.isEditable = false
    }
    
    private func configureDocumentPicker() {
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
    }
    
    private func getImage() -> UIImage? {
        if let image = imageToBeDecoded {
            return image
        } else {
            showPopup(message: PopupString.PopupType.noImageToDecode.rawValue)
            return nil
        }
    }
    
    private func loadImageFromFile(at fileURL: URL) -> UIImage? {
        do {
            let imageData = try Data(contentsOf: fileURL)
            let image = UIImage(data: imageData)
            return image
        } catch {
            showAlert(withTitle: PopupString.ErrorType.title.rawValue,
                      withMessage: error.localizedDescription)
            return nil
        }
    }
    
    private func decodeSecretFrom(image: UIImage) {
        showLottieAnimation()
        
        var secret = ""
        
        guard let stegoCGImage = image.cgImage else {
            showAlert(withTitle: PopupString.ErrorType.title.rawValue,
                      withMessage: PopupString.ErrorType.unexpectedError.rawValue)
            return
        }
        
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = stegoCGImage.width
        let height           = stegoCGImage.height
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapInfo       = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        var pixelData        = [UInt8](repeating: 0, count: bytesPerRow * height)
        
        guard let context = CGContext(data: &pixelData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            showAlert(withTitle: PopupString.ErrorType.title.rawValue,
                      withMessage: PopupString.ErrorType.unexpectedError.rawValue)
            return
        }
        context.draw(stegoCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {return}
            
            for row in 0 ..< Int(height) {
                for column in 0 ..< Int(width) {
                    let index = (row * bytesPerRow) + (column * bytesPerPixel)
                    
                    let red   = Int(pixelData[index + 1])
                    let green = Int(pixelData[index + 2])
                    let blue  = Int(pixelData[index + 3])
                    
                    guard PVD.satisfiesFOBCheck(for: (red, green)),
                          PVD.satisfiesFOBCheck(for: (green, blue)) else {continue}
                    
                    //Get first subsecret
                    let firstSubsecret = self.getSubsecretFrom(colors: (red, green))
                    secret += firstSubsecret
                    
                    //Get second subsecret
                    let secondSubsecret = self.getSubsecretFrom(colors: (green, blue))
                    secret += secondSubsecret
                    
                    if hasReachedDelimiter(secret: &secret){
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else {return}
                            self.terminateSearch()
                        }
                        return
                    }
                }
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {return}
                self.hideLottieAnimation()
                self.showAlert(withTitle: PopupString.ErrorType.title.rawValue,
                               withMessage: PopupString.ErrorType.noEncodedSecret.rawValue)
            }
        }
    }
    
    private func getSubsecretFrom(colors: (Int, Int)) -> String {
        let difference = abs(colors.1 - colors.0)
        let pvdCase = PVD.getCase(for: Int(difference))
        let blockCapacity = Int(floor(log2(Double(pvdCase.upperLimit - pvdCase.lowerLimit + 1))))
        let subSecretDecimal = difference - Int(pvdCase.lowerLimit)
        var subSecretBinary = String(subSecretDecimal, radix: 2)
        
        if subSecretBinary.count < blockCapacity {
            subSecretBinary = subSecretBinary.pad(toSize: blockCapacity, rightDirection: false)
        }
        
        return subSecretBinary
    }
    
    private func hasReachedDelimiter(secret: inout String) -> Bool {
        let strideLength = 8
        let count = secret.count
        
        for index in stride(from: self.secret.count*8, to: count, by: strideLength) {
            let startIndex = secret.index(secret.startIndex, offsetBy: index)
            if let endIndex = secret.index(startIndex, offsetBy: strideLength, limitedBy: secret.endIndex) {
                let char = String(secret[startIndex..<endIndex]).binaryToString()
                self.secret.append(char ?? "")
            }
        }
        return self.secret.contains(AppConstants.delimiter)
    }
    
    private func terminateSearch(){
            hideLottieAnimation()
            let secretWithoutDelimiter = secret.components(separatedBy: AppConstants.delimiter).first
            secretTextView.text = secretWithoutDelimiter
            secretTextView.textColor = .black
    }
    
    // MARK: Actions
    @IBAction func decodeBtnPressed(_ sender: Any) {
        if let image = getImage() {
            decodeSecretFrom(image: image)
        }
    }
    
    // MARK: Selectors
    @objc func handleTap(gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else {return}
        if tag == 0 {
            present(documentPicker, animated: true)
        }
    }
}

// MARK: UIDocumentPickerDelegate
extension DecodingVC: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else {return}
        
        let isAccessing = fileURL.startAccessingSecurityScopedResource()
        if isAccessing {
            if let image = loadImageFromFile(at: fileURL) {
                self.photoIV.image = image
                self.imageToBeDecoded = image
            } else {
                showAlert(withTitle: PopupString.ErrorType.title.rawValue,
                          withMessage: PopupString.ErrorType.unexpectedError.rawValue)
            }
            fileURL.stopAccessingSecurityScopedResource()
            
        }
    }
}
