//
//  UIViewControllerExtension.swift
//  Stegno
//
//  Created by عمرو on 18.06.2023.
//

import UIKit

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func showPopup(message: String, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        self.present(alertController, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0){
                alertController.dismiss(animated: true, completion: completion)
            }
        }
    }
    
    func showAlert(withTitle title: String, withMessage message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: { action in
        })
        alert.addAction(ok)
        DispatchQueue.main.async(execute: {
            self.present(alert, animated: true)
        })
    }
    
    func showLottieAnimation(){
        if let vc = self.navigationController as? LottieCoveredNVC {
            self.view.isUserInteractionEnabled = false
            vc.showLoadingAnimation()
        }
    }
    
    func hideLottieAnimation(){
        if let vc = self.navigationController as? LottieCoveredNVC {
            self.view.isUserInteractionEnabled = true
            vc.hideLoadingAnimation()
        }
    }
    
    // MARK:  Selector
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
