//
//  ViewController.swift
//  Stegno
//
//  Created by عمرو on 18.06.2023.
//

import UIKit

enum ProcessType {
    case encode, decode
}

class MainVC: UIViewController {
    
    // MARK: Subviews
    @IBOutlet weak var encodeView: ShadowedView!
    @IBOutlet weak var decodeView: ShadowedView!
    
    // MARK: Viewcycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    
    // MARK: Helpers
    private func configureSubviews(){
        addGestureRecognizer()
    }
    
    private func addGestureRecognizer(){
        let views = [encodeView, decodeView]
        
        for i in views.indices {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(gesture:)))
            views[i]?.addGestureRecognizer(tapGesture)
            views[i]?.isUserInteractionEnabled = true
            views[i]?.tag = i
        }
    }
    
    private func showSecretTypeSheet(to process: ProcessType) {
        let alert = UIAlertController(title: "Secret Type",
                                      message: "Please select secret type you want to process.",
                                      preferredStyle: .actionSheet)
        let text = UIAlertAction(title: "Text",
                                 style: .default) { _ in
            self.goToScreenTo(process: process, secretType: .text)
        }
        
        let Image = UIAlertAction(title: "Image",
                                  style: .default) { _ in
            self.goToScreenTo(process: process, secretType: .image)
        }
        
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel)
        
        alert.addAction(text)
        alert.addAction(Image)
        alert.addAction(cancel)
        DispatchQueue.main.async(execute: {
            self.present(alert, animated: true)
        })
    }
    
    private func goToScreenTo(process: ProcessType, secretType: SecretType) {
        if process == .encode {
            goToEncodingScreenToProcess(secretType: secretType)
        } else {
            goToDecodingScreenToProcess(secretType: secretType)
        }
    }
    
    // MARK: Selectors
    @objc func handleTap(gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else {return}
        
        if tag == 0 {
            showSecretTypeSheet(to: .encode)
        } else {
            showSecretTypeSheet(to: .decode)
        }
    }
}

// MARK: Navigations
extension MainVC {
    private func goToEncodingScreenToProcess(secretType: SecretType){
        let storyboard = UIStoryboard(name: Storyboard.Encoding.rawValue, bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: VCIdentifier.EncodingVC.rawValue) as? EncodingVC {
            viewController.secretType = secretType
            viewController.modalPresentationStyle = .fullScreen
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    private func goToDecodingScreenToProcess(secretType: SecretType){
        let storyboard = UIStoryboard(name: Storyboard.Decoding.rawValue, bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: VCIdentifier.DecodingVC.rawValue) as? DecodingVC {
            viewController.secretType = secretType
            viewController.modalPresentationStyle = .fullScreen
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
