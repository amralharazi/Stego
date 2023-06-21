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
    @IBOutlet weak var photoIV: UIImageView!
    @IBOutlet weak var secretTextView: RoundedTextView!
    
    // MARK: Properties
    private let previewController = QLPreviewController()
    private let imagePicker = UIImagePickerController()
    private var previewItems: [QLPreviewItem] = []
    private var imageToBeEncoded: UIImage?
    
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
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(gesture:)))
        photoIV.addGestureRecognizer(tapGesture)
        photoIV.isUserInteractionEnabled = true
        photoIV.tag = 0
    }
    
    private func configureImagePicker(){
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
    }
    
    private func configureTextView(){
        secretTextView.text = "Enter secret here"
        secretTextView.textColor = .lightGray
        secretTextView.delegate = self
    }
    
    private func configurePreviewController(){
        previewController.dataSource = self
    }
    
    private func showImagePicker(){
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Camera" , style: .default, handler: { action in
            
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true)
        })
        
        let gallery = UIAlertAction(title: "Gallery" , style: .default, handler: { action in
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true)
        })
        let cancel = UIAlertAction(title: "Cancel" , style: .cancel, handler: { action in
            
        })
        alert.addAction(camera)
        alert.addAction(gallery)
        alert.addAction(cancel)
        DispatchQueue.main.async(execute: {
            self.present(alert, animated: true)
        })
    }
    
    private func getImage() -> UIImage? {
        if let image = imageToBeEncoded {
            return image
        } else {
            showPopup(message: PopupString.PopupType.noImageToEncode.rawValue)
            return nil
        }
    }
    
    private func getSecret() -> String? {
        if secretTextView.textColor != .lightGray,
           let secret = secretTextView?.text.trimmingCharacters(in: .whitespacesAndNewlines),
           !secret.isEmpty {
            // Appending /| as a delimiter
            return secret.appending(AppConstants.delimiter)
        } else {
            showPopup(message: PopupString.PopupType.noSecretToEncode.rawValue)
            return nil
        }
    }
    
    private func encode(secret: String, into image: UIImage){
        showLottieAnimation()
        
        var secret = secret
        
        guard let cgImage = image.cgImage else {
            showAlert(withTitle: PopupString.ErrorType.title.rawValue,
                      withMessage: PopupString.ErrorType.unexpectedError.rawValue)
            return
        }
        
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = cgImage.width
        let height           = cgImage.height
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
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {return}
            
            for row in 0 ..< Int(height) {
                for column in 0 ..< Int(width) {
                    
                    let index = (row * bytesPerRow) + (column * bytesPerPixel)
                    
                    let red   = Int(pixelData[index + 1])
                    let green = Int(pixelData[index + 2])
                    let blue  = Int(pixelData[index + 3])
                    
                    guard !secret.isEmpty,
                          PVD.satisfiesFOBCheck(for: (red, green)),
                          PVD.satisfiesFOBCheck(for: (green, blue)) else {continue}
                    
                    //Compute first block
                    let firstBlockStegoColors = self.computeStegoColors(for: (red, green), secret: &secret)
                    
                    //Compute second block
                    let secondBlockStegoColors = self.computeStegoColors(for: (green, blue), secret: &secret)
                    
                    let modifiedGreen = (firstBlockStegoColors.1 + secondBlockStegoColors.0)/2
                    let modifiedRed   = firstBlockStegoColors.0 - (firstBlockStegoColors.1 - modifiedGreen)
                    let modifiedBlue  = secondBlockStegoColors.1 - (secondBlockStegoColors.0 - modifiedGreen)
                    
                    let stegoRed   = UInt8(exactly: modifiedRed) ?? 0
                    let stegoBlue  = UInt8(exactly: modifiedBlue) ?? 0
                    let stegoGreen = UInt8(exactly: modifiedGreen) ?? 0
                    
                    pixelData[index+1] = stegoRed
                    pixelData[index+2] = stegoGreen
                    pixelData[index+3] = stegoBlue
                    
                    if (index == pixelData.count - 1)
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
            
            let stegoImage = UIImage(cgImage: modifiedCGImage)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {return}
                self.hideLottieAnimation()
                self.save(image: stegoImage)
            }
        }
    }
    
    private func computeStegoColors(for colors: (Int, Int), secret: inout String) -> (Int, Int) {
        let d = abs(colors.1 - colors.0)
        
        let pvdCase = PVD.getCase(for: Int(d))
        let capacity = Int(floor(log2(Double(pvdCase.upperLimit - pvdCase.lowerLimit + 1))))
        
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
        
        let deltaD = Int(pvdCase.lowerLimit) + decimalSubSecret
        let m = Double(abs(deltaD - d))
        let flooredHalfM = Int(floor(m/2))
        let ceiledHalfM = Int(ceil(m/2))
        
        if (colors.0 >= colors.1 && deltaD > d)
            || (colors.0 < colors.1 && deltaD <= d) {
            return (colors.0 + ceiledHalfM, colors.1 - flooredHalfM)
        } else if (colors.0 < colors.1 && deltaD > d) {
            return (colors.0 - flooredHalfM, colors.1 + ceiledHalfM)
        } else {
            return (colors.0 - ceiledHalfM, colors.1 + flooredHalfM)
        }
    }
    
    func save(image: UIImage) {
        let fileManager = FileManager.default
        
        do {
            let path = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
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
        if let image = getImage(),
           let secret = getSecret()?.binary {
            encode(secret: secret, into: image)
        }
    }
    
    // MARK: Selectors
    @objc func handleTap(gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else {return}
        if tag == 0 {
            showImagePicker()
        }
    }
}

// MARK:  UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension EncodingVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {return}
        self.photoIV.image = image
        self.imageToBeEncoded = image
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
