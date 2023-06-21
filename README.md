# Stego
An advanced steganographic iOS app that utilizes the robust PVD (Pixel Value Differencing) method for secure encoding and decoding of strings.
| Encoding        | Decoding |
| --------------- | --------------- |
| <img src="https://github.com/amralharazi/Stegno/assets/55652499/17165769-ddfb-425b-9448-cb36771a7316" width="240"> | <img src="https://github.com/amralharazi/Stegno/assets/55652499/24ad4653-97dd-40ad-a81b-ddf5e649bbbb" width="240"> |


## Algorithm
#### Encoding:
First, we obtain the CGImage of the image to be encoded. We then extract the data to create a CGContext, which enables us to draw the encoded image. Next, we initialize a UInt8 array that will store pixel values, with each pixel consisting of four elements: ARGB, representing alpha, red, green, and blue channels, respectively.

Subsequently, we access each pixel using nested for loops, iterating over the height and width of the image, ensuring that all pixels are covered. Within the loop, we retrieve the index of the current pixel and extract the RGB color values.

Before proceeding, we perform several checks. First, we verify whether the entire secret has been encoded. If not, we check if embedding into either of the color channel pairs (red-green or green-blue) will result in fall0off boundary, ensuring that no overflow or underflow occurs during the embedding process.

``` Swift
func satisfiesFOBCheck(for colors: (Int, Int)) -> Bool {
        
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
```

If all conditions are satisfied, we proceed to calculate the stego colors for that particular pixel and substitute the original RGB values with the modified RGB values.

```swift 
func computeStegoColors(for colors: (Int, Int), secret: inout String) -> (Int, Int) {
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
        
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = cgImage.width
        let height           = cgImage.height
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapInfo       = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        var pixelData        = [UInt8](repeating: 0, count: bytesPerRow * height)
        
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
                self.save(image: stegoImage)
            }
        }
    }
```

#### Decoding
Similar to the encoding process, we start by obtaining the CGImage of the image to be decoded. From there, we extract image data to create a CGContext, enabling us to access its pixels. Additionally, we create a UInt8 array to store the pixel values.

To store the decoded secret, we initialize an empty string variable called "secret." We then iterate over the pixels, checking for fall-off boundaries (FOB) in any of the pixel blocks. If no fall-off boundary is detected, we extract the binary subsecret from each block and append the returned string to the "secret" variable using the following code:

```Swift
func getSubsecretFrom(colors: (Int, Int)) -> String {
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
```
After each loop we check wether the secret has reach the delimiter, and each 8 bits are converted to their corresponding char and that gets appended to another var initialized in the controller called "secret":

``` Swift
func hasReachedDelimiter(in secret: inout String) -> Bool {
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
```

If the condition returns true, the loop terminates, and we display the decoded string on the screen. However, if the loop reaches the end without finding the delimiter, we display an alert to notify the user that no secret was found.

```swift 
func decodeSecretFrom(image: UIImage) {
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
                self.showAlert(withTitle: PopupString.ErrorType.title.rawValue,
                               withMessage: PopupString.ErrorType.noEncodedSecret.rawValue)
            }
        }
    }
```
## Getting Started
1. Make sure you have Xcode 14 or higher installed on your computer.
2. To install thrid-part libraries, make sure Cocoapods is installed too.
3. Download/clone Stego to a dicretory on your computer.
4. Run the current active scheme.
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
* View&Controller: All views and their corresponding controllers are in this file. Each is in a different folder.

## Dependencies
Cocoapods is used to manage dependencies in this app. Integrated dependencies are:
* lottie-ios
* IQKeyboardManagerSwift
## References
* Prasad, S. and Kumar Pal, A. An RGB colour image steganography scheme using overlapping block-based ... Available at: https://royalsocietypublishing.org/doi/10.1098/rsos.161066 (Accessed: 20 June 2023). 
* Wu, D.-C. and Tsai, W.-H. (2003) A steganographic method for images by pixel-value differencing, Pattern Recognition Letters. Available at: https://www.sciencedirect.com/science/article/abs/pii/S0167865502004026 (Accessed: 20 June 2023).
