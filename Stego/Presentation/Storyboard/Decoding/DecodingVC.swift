//
//  DecodingVC.swift
//  Stegno
//
//  Created by عمرو on 18.06.2023.
//

import UIKit
import QuickLook
import MobileCoreServices
import UniformTypeIdentifiers

class DecodingVC: UIViewController {
    
    // MARK: Subviews
    @IBOutlet weak var secretTextView: RoundedTextView!
    @IBOutlet weak var stegoImageView: UIImageView!
    @IBOutlet weak var shadowedView: ShadowedView!
    
    // MARK: Properties
    private let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.image])
    private let previewController = QLPreviewController()
    private var previewItems: [QLPreviewItem] = []
    private var secret = ""
    var secretType: SecretType?
    
    // MARK: Viewcycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
    }
    
    // MARK: Helpers
    private func configureSubviews(){
        configurePreviewController()
        configureDocumentPicker()
        addGestureRecognizer()
        configureTextView()
    }
    
    private func configurePreviewController(){
        previewController.dataSource = self
    }
    
    private func configureDocumentPicker() {
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
    }
    
    private func addGestureRecognizer(){
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(gesture:)))
        stegoImageView.addGestureRecognizer(tapGesture)
        stegoImageView.isUserInteractionEnabled = true
        stegoImageView.tag = 0
    }
    
    private func configureTextView(){
        if secretType == .text {
            secretTextView.text = "Secret will appear here"
            secretTextView.textColor = .lightGray
            secretTextView.isEditable = false
        } else {
            shadowedView.alpha = 0
        }
    }
    
    private func getStegoImage() -> UIImage? {
        if let image = stegoImageView.image {
            return image
        } else {
            showPopup(message: PopupString.PopupType.noImageToDecode.rawValue)
            return nil
        }
    }
    
    private func loadImageFromFile(at url: URL) -> UIImage? {
        do {
            let imageData = try Data(contentsOf: url)
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
        
        let colorSpace       = CGColorSpaceCreateDeviceGray()
        let width            = stegoCGImage.width
        let height           = stegoCGImage.height
        let bytesPerPixel    = 1
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapInfo       = CGImageAlphaInfo.none.rawValue
        var pixelData        = [UInt8](repeating: 0, count: bytesPerRow * height)
        let maxPixel         = pixelData.count - 1
        
        guard let context = CGContext(data: &pixelData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else {
            showAlert(withTitle: PopupString.ErrorType.title.rawValue,
                      withMessage: PopupString.ErrorType.unexpectedError.rawValue)
            return
        }
        context.draw(stegoCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {return}
            
        outerloop: for row in 0 ..< Int(height) {
            for column in stride(from: 0, to: Int(width), by: 2) {
                
                let currentPixelIndex = (row * bytesPerRow) + column
                let nextPixelIndex    = currentPixelIndex + 1
                
                guard nextPixelIndex <= maxPixel else { break outerloop}
                
                let currentPixelGrayValue = Int(pixelData[currentPixelIndex])
                let nextPixelGrayValue    = Int(pixelData[nextPixelIndex])
                
                guard !PVD.doesFallOffBoundary(block: (currentPixelGrayValue, nextPixelGrayValue)) else {continue}
                
                let subserect =  self.getSubsecretFrom(colors: (currentPixelGrayValue, nextPixelGrayValue))
                secret += subserect
                
                if secret.contains(AppConstants.delimiter.binary) {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {return}
                        let secret = secret.components(separatedBy: AppConstants.delimiter.binary).first!
                        self.terminateDecoding(with: secret)
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
        let difference = colors.1 - colors.0
        let pvdCase = PVD.getCase(for: abs(difference))
        let blockCapacity = pvdCase.capacity
        
        let subSecretDecimal: Int
        if difference >= 0 {
            subSecretDecimal = difference - pvdCase.lowerLimit
        } else {
            subSecretDecimal = -difference - pvdCase.lowerLimit
        }
        
        var subSecretBinary = String(subSecretDecimal, radix: 2)
        
        if subSecretBinary.count < blockCapacity {
            subSecretBinary = subSecretBinary.pad(toSize: blockCapacity, rightDirection: false)
        }
        return subSecretBinary
    }
    
   
    private func terminateDecoding(with secret: String){
        if secretType == .text {
            self.secretTextView.text = convertBinaryStringToText(secret)
            secretTextView.textColor = .black
        } else if let imageData = convertBinaryStringToData(secret),
                let image = UIImage(data: imageData) {
                    save(image: image)
        } else {
            showAlert(withTitle: PopupString.ErrorType.title.rawValue,
                      withMessage: PopupString.ErrorType.unexpectedError.rawValue)
        }
        hideLottieAnimation()
    }
    
    private func convertBinaryStringToText(_ binaryString: String) -> String {
        let strideLength = 8
        let count = binaryString.count
        var secret = ""
        
        for index in stride(from: 0, to: count, by: strideLength) {
            let startIndex = binaryString.index(binaryString.startIndex, offsetBy: index)
            if let endIndex = binaryString.index(startIndex, offsetBy: strideLength, limitedBy: binaryString.endIndex) {
                if let char = String(binaryString[startIndex..<endIndex]).binaryToString() {
                    secret.append(char)
                }
            }
        }
        return secret
    }
    
    
    private func convertBinaryStringToData(_ binaryString: String) -> Data? {
        var byteArray = [UInt8]()
        var currentIndex = binaryString.startIndex
        
        while currentIndex < binaryString.endIndex {
            let endIndex = binaryString.index(currentIndex, offsetBy: 8)
            let byteString = binaryString[currentIndex..<endIndex]
            
            if let byte = UInt8(byteString, radix: 2) {
                byteArray.append(byte)
            } else {
                return nil
            }
            currentIndex = endIndex
        }
        
        return Data(byteArray)
    }
    
    private func save(image: UIImage) {
        let fileManager = FileManager.default
        
        do {
            let path = try fileManager.url(for: .documentDirectory,
                                           in: .userDomainMask
                                           , appropriateFor: nil,
                                           create: false)
            let fileURL = path.appendingPathComponent("decodedImage.png")
            
            if let pngData = image.pngData() {
                do {
                    try pngData.write(to: fileURL, options: .atomic)
                    previewItems.append(fileURL as QLPreviewItem)
                    presentPreviewScreen()
                } catch {
                    showAlert(withTitle: PopupString.ErrorType.title.rawValue,
                              withMessage: error.localizedDescription)
                    return
                }
            }
        } catch {
            showAlert(withTitle: PopupString.ErrorType.title.rawValue,
                      withMessage: error.localizedDescription)
        }
    }
    
    // MARK: Actions
    @IBAction func decodeBtnPressed(_ sender: Any) {
        if let image = getStegoImage() {
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
                stegoImageView.image = image
                stegoImageView.contentMode = .scaleAspectFill
            } else {
                showAlert(withTitle: PopupString.ErrorType.title.rawValue,
                          withMessage: PopupString.ErrorType.unexpectedError.rawValue)
            }
            fileURL.stopAccessingSecurityScopedResource()
        }
    }
}

// MARK:  QLPreviewControllerDataSource
extension DecodingVC: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        previewItems.count
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        previewItems[index]
    }
}

// MARK: Navigations
extension DecodingVC {
    private func presentPreviewScreen(){
        previewController.modalPresentationStyle = .fullScreen
        self.navigationController?.present(previewController, animated: true, completion: nil)
    }
}
