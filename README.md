# Stego
An advanced steganographic iOS app that utilizes the robust PVD (Pixel Value Differencing) method for secure encoding and decoding of texts and images.


| Encoding Image        | Decoding Image | Encoding Text     | Decoding Text |
| --------------- | --------------- |  --------------- | --------------- |
| <img src="https://github.com/amralharazi/Stego/assets/55652499/0feba174-5faa-4699-b1fa-0347c382bb9e" width="240"> | <img src="https://github.com/amralharazi/Stego/assets/55652499/280a6a5c-4722-474c-8c7d-5f0cfa289b54" width="240"> | <img src="https://github.com/amralharazi/Stego/assets/55652499/dbcbd971-0da2-4756-a947-25ac57c4e1b6" width="240"> | <img src="https://github.com/amralharazi/Stego/assets/55652499/95638a4e-6b86-466a-a430-25f9a2396f41"  width="240">


## Algorithm
#### Encoding:
First, we obtain the CGImage of the image to be encoded. We then extract the data to create a CGContext, which enables us to draw the encoded image. Next, we initialize an array of UInt8 that will store grayscale values of each pixel.

Subsequently, we access each pixel using two nested for loops, iterating over the height and width of the image, ensuring that all pixels are covered. Within the loop, we retrieve the index of the current and the next pixel to access their grayscale values.

Before proceeding, we perform several checks. First, we verify whether the entire secret has been encoded. If not, we check if embedding into the block (current pixel and the consecutive one) will result in fall-off boundary, ensuring that no overflow or underflow occurs during the embedding process.

``` Swift
static func doesFallOffBoundary(block: (Int, Int)) -> Bool {
        let difference = block.1 - block.0
        let pvdCase = PVD.getCase(for: abs(difference))
        let m = Double(pvdCase.upperLimit - difference)
        
        let flooredHalfM = Int(floor(m/2))
        let ceiledHalfM  = Int(ceil(m/2))
        
        let deltaColors: (Int, Int)
        
        if difference % 2 == 0 {
            deltaColors = (block.0 - ceiledHalfM,
                           block.1 + flooredHalfM)
        } else {
            deltaColors = (block.0 - flooredHalfM,
                           block.1 + ceiledHalfM)
        }
        
        if (0...255 ~= deltaColors.0) &&
            (0...255 ~= deltaColors.1) {
            return false
        }
        return true
    }
```

If all conditions are satisfied, we proceed to calculate the stego colors for that block and substitute the original grayscale values with the modified stego-grayscale values.

```swift 
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
```

Now, we can generate the stego image using the CGImage returned from context.makeImage(). This stego image can be exported by the user to the Files app for convenient sharing or storage.

``` swift 
    private func encode(secret: String, into image: UIImage){        
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
```

#### Decoding
Similar to the encoding process, we start by obtaining the CGImage of the image to be decoded. From there, we extract image data to create a CGContext, enabling us to access its pixels. Additionally, we create a UInt8 array to store the grayscale values.

To store the decoded secret, we initialize an empty string variable called "secret." We then iterate over the pixels, checking for fall-off boundaries (FOB) in any of the pixel blocks. If no fall-off boundary is detected, we extract the binary subsecret from each block and append the returned string to the "secret" variable using the following code:

```Swift
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
```
In each loop we check wether the secret contains the delimiter, if so, we terminate the decoding process. If the secret is a text, we show that on the screen, otherwise, the image is opned on a new controller from which it can be saved into the Files app:

``` Swift
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
    }
```

However, if the loop reaches the end without finding the delimiter, we display an alert to notify the user that no secret was found.

```swift 
private func decodeSecretFrom(image: UIImage) {        
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
                self.showAlert(withTitle: PopupString.ErrorType.title.rawValue,
                               withMessage: PopupString.ErrorType.noEncodedSecret.rawValue)
            }
        }
    }
```
## Getting Started
1. Make sure you have Xcode 14 or higher installed on your computer.
2. Download/clone Stego to a dicretory on your computer.
3. Run the current active scheme.
## Usage
You only need to have a photo and a string to get started. Upload the image you want to encode your secret into, then enter the secret. Boom! Now yo have the your secret encoded within the image. You can then export that to Files, and from there share that with other people.
## Limitations
1. As the app converts each 8-bit character into a char, some characters from various languages that use more than one byte in UTF8 will not be correctly represented after decoding. Right now, all one-byte characters and latin characters are functioning properly. 

2. The integrity of the encoded message may be compromised if the image is compressed when saved to Photos or shared via AirDrop. This is something to keep in mind when saving or sharing images. Although the image quality and pixel values are preserved in this instance, emailing the images appears to work without a hitch. It is advised to use email as a dependable way to distribute encoded images without jeopardizing their content. 
## Architecture
* Stego has been implemented utilizing the MVC architecture.
* Model has the important data and logic of the PVD method.
* View has the UI components that will appear on the screen.
* Controller is responsible for handling the interactions of the user with the presented data.
* No backend system is integrated in this app.

## Structure
* Delegate: AppDelegate and SceneDelegate files are saved here.
* Utils: Constants, extensions, loading animation files are under this folder.
* Model: PVD method file can be found here.
* Presentation: All views and their corresponding controllers are in this file. Each is in a different folder.

## Dependencies
Cocoapods is used to manage dependencies in this app. Integrated dependencies are:
* lottie-ios
* IQKeyboardManagerSwift
## References
* Wu, D.-C. and Tsai, W.-H. (2003) A steganographic method for images by pixel-value differencing, Pattern Recognition Letters. Available at: https://www.sciencedirect.com/science/article/abs/pii/S0167865502004026 (Accessed: 20 June 2023).
