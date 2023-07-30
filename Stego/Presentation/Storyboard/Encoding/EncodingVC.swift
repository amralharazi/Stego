//
//  EncodingVC.swift
//  Stegno
//
//  Created by عمرو on 18.06.2023.
//

import UIKit
import QuickLook

class EncodingVC: UIViewController {
    
    // MARK: Subviews
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var shadowedView: ShadowedView!
    @IBOutlet weak var secretTextView: RoundedTextView!
    @IBOutlet weak var secretImageView: RoundedIV!
    
    // MARK: Properties
    private let previewController = QLPreviewController()
    private let imagePicker = UIImagePickerController()
    private var previewItems: [QLPreviewItem] = []
    private var tappedImageView: UIImageView?
    private var uploadImage = UIImage(named: Assets.uploadImage)
    var secretType: SecretType?
    
    // MARK: Viewcycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
    }
    
    // MARK: Helpers
    private func configureSubviews(){
        hideKeyboardWhenTappedAround()
        configurePreviewController()
        configureImagePicker()
        addGestureRecognizer()
        configureTextView()
    }
    
    private func addGestureRecognizer(){
        let views = [coverImageView, secretImageView]
        
        for i in views.indices {
            let tapGesture = UITapGestureRecognizer(target: self,
                                                    action: #selector(handleTap(gesture:)))
            views[i]?.image = uploadImage
            views[i]?.addGestureRecognizer(tapGesture)
            views[i]?.isUserInteractionEnabled = true
            views[i]?.tag = i
        }
    }
    
    private func configureImagePicker(){
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
    }
    
    private func configureTextView(){
        if secretType == .text {
            secretTextView.text = "Enter secret here"
            secretTextView.textColor = .lightGray
            secretTextView.delegate = self
            secretImageView.isHidden = true
        } else {
            shadowedView.isHidden = true
        }
    }
    
    private func configurePreviewController(){
        previewController.dataSource = self
    }
    
    private func getCoverImage() -> UIImage? {
        if let image = coverImageView.image,
        image != uploadImage {
            return image.withFixedOrientation
        } else {
            showPopup(message: PopupString.PopupType.noImageToEncode.rawValue)
            return nil
        }
    }
    
    private func getSecret() -> String? {
        if secretType == .text {
            return getSecretTextBinaryString()
        } else {
            return getImageDataBinaryString()
        }
    }
    
    private func getSecretTextBinaryString() -> String? {
        if secretTextView.textColor != .lightGray,
           let secret = secretTextView?.text.trimmingCharacters(in: .whitespacesAndNewlines),
           !secret.isEmpty {
            return secret.appending(AppConstants.delimiter).binary
        } else {
            showPopup(message: PopupString.PopupType.noSecretToEncode.rawValue)
            return nil
        }
    }
    
    private func getImageDataBinaryString() -> String? {
        if let image = secretImageView.image,
        image != uploadImage {
            if let imageData = imageData(from: image) {
                var binaryString = binaryString(from: imageData)
                let delimeter = (AppConstants.delimiter).binary
                binaryString.append(delimeter)
                return binaryString
            } else {
                showPopup(message: PopupString.ErrorType.unexpectedError.rawValue)
                return nil
            }
        } else {
            showPopup(message: PopupString.PopupType.noSecretImageToEncode.rawValue)
            return nil
        }
    }
    
    private func imageData(from image: UIImage) -> Data? {
        return image.jpegData(compressionQuality: 0.0)
    }
    
    private func binaryString(from imageData: Data) -> String {
        var binaryString = ""
        let byteArray = [UInt8](imageData)
        
        for byte in byteArray {
            let binaryValue = String(byte, radix: 2)
            let paddedBinaryValue = binaryValue.pad(toSize: 8, rightDirection: false)
            binaryString.append(paddedBinaryValue)
        }
        return binaryString
    }
    
    private func encode(secret: String, into image: UIImage){
        showLottieAnimation()
        
        var secret = secret
        
        guard let cgImage = image.cgImage else {
            showAlert(withTitle: PopupString.ErrorType.title.rawValue,
                      withMessage: PopupString.ErrorType.unexpectedError.rawValue)
            return
        }
        
        let colorSpace       = CGColorSpaceCreateDeviceGray()
        let width            = cgImage.width
        let height           = cgImage.height
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
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {return}
            
        outerloop: for row in 0 ..< Int(height) {
            for column in stride(from: 0, to: Int(width), by: 2) {
                
                let currentPixelIndex = (row * bytesPerRow) + column
                let nextPixelIndex    = currentPixelIndex + 1
                
                guard nextPixelIndex <= maxPixel,
                      !secret.isEmpty  else { break outerloop}
                
                let currentPixelGrayValue = Int(pixelData[currentPixelIndex])
                let nextPixelGrayValue    = Int(pixelData[nextPixelIndex])
                
                guard !PVD.doesFallOffBoundary(block: (currentPixelGrayValue,
                                                       nextPixelGrayValue)) else {continue}
                
                let stegoColors = computeStegoColors(for: (currentPixelGrayValue,
                                                           nextPixelGrayValue),
                                                     secret: &secret)
                
                let currentPixelStegoColor = UInt8(exactly: stegoColors.0) ?? 0
                let nextPixelStegoColor    = UInt8(exactly: stegoColors.1) ?? 0
                
                pixelData[currentPixelIndex] = currentPixelStegoColor
                pixelData[nextPixelIndex]    = nextPixelStegoColor
                
                if ((nextPixelIndex + 1) > maxPixel)
                    && !secret.isEmpty {
                    showAlert(withTitle: PopupString.ErrorType.title.rawValue,
                              withMessage: PopupString.ErrorType.largeSecret.rawValue)
                }
            }
        }
            
            guard let modifiedCGImage = context.makeImage() else {
                showAlert(withTitle: PopupString.ErrorType.title.rawValue,
                          withMessage: PopupString.ErrorType.unexpectedError.rawValue)
                return
            }
            
            let stegoImage = UIImage(cgImage: modifiedCGImage,
                                     scale: image.scale,
                                     orientation: image.imageOrientation)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {return}
                self.hideLottieAnimation()
                self.coverImageView.image = stegoImage
                self.save(image: stegoImage)
            }
        }
    }
    
    private func computeStegoColors(for block: (Int, Int), secret: inout String) -> (Int, Int) {
        let difference = block.1 - block.0
        
        let pvdCase = PVD.getCase(for: abs(difference))
        let capacity = pvdCase.capacity
        
        var subSecret: String
        if  capacity <= secret.count {
            subSecret = String(secret.prefix(capacity))
            secret.removeFirst(capacity)
        } else {
            subSecret = secret.pad(toSize: capacity)
            secret.removeAll()
        }
                
        guard let decimalSubSecret = Int(subSecret, radix: 2) else {
            showAlert(withTitle: PopupString.ErrorType.title.rawValue,
                      withMessage: PopupString.ErrorType.unexpectedError.rawValue)
            return (0,0) }
        
        let deltaDifference = (Int(pvdCase.lowerLimit) + decimalSubSecret) * (difference < 0 ? -1 : 1)
        let m = Double(deltaDifference - difference)
        let flooredHalfM = Int(floor(m/2))
        let ceiledHalfM = Int(ceil(m/2))
        
        if difference % 2 == 0 {
            return (block.0 - ceiledHalfM,
                    block.1 + flooredHalfM)
        } else {
            return (block.0 - flooredHalfM,
                    block.1 + ceiledHalfM)
        }
    }
    
    private func showImagePicker(){
        let alert = UIAlertController(title: nil,
                                      message: nil,
                                      preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Camera",
                                   style: .default,
                                   handler: { action in
            
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true)
        })
        
        let gallery = UIAlertAction(title: "Gallery",
                                    style: .default,
                                    handler: { action in
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true)
        })
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: { action in
            
        })
        alert.addAction(camera)
        alert.addAction(gallery)
        alert.addAction(cancel)
        DispatchQueue.main.async(execute: {
            self.present(alert, animated: true)
        })
    }
    
    private func save(image: UIImage) {
        let fileManager = FileManager.default
        
        do {
            let path = try fileManager.url(for: .documentDirectory,
                                           in: .userDomainMask
                                           , appropriateFor: nil,
                                           create: false)
            let fileURL = path.appendingPathComponent("encodedImage.png")
            
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
    @IBAction func encodeBtnPressed(_ sender: Any) {
        if let image = getCoverImage(),
           let secret = getSecret() {
            encode(secret: secret, into: image)
        }
    }
    
    // MARK: Selectors
    @objc func handleTap(gesture: UITapGestureRecognizer) {
        tappedImageView = gesture.view as? UIImageView
        showImagePicker()
    }
}

// MARK:  UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension EncodingVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {return}
        tappedImageView?.image = image
        tappedImageView?.contentMode = .scaleAspectFill
        dismiss(animated: true, completion: nil)
    }
}

// MARK:  QLPreviewControllerDataSource
extension EncodingVC: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        previewItems.count
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        previewItems[index]
    }
}

// MARK:  UITextViewDelegate
extension EncodingVC: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Enter secret here"
            textView.textColor = .lightGray
        }
    }
}

// MARK: Navigations
extension EncodingVC {
    private func presentPreviewScreen(){
        previewController.modalPresentationStyle = .fullScreen
        self.navigationController?.present(previewController, animated: true, completion: nil)
    }
}
