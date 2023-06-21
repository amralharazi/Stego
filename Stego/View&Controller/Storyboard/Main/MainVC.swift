//
//  ViewController.swift
//  Stegno
//
//  Created by عمرو on 18.06.2023.
//

import UIKit

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
    
    // MARK: Selectors
    @objc func handleTap(gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else {return}
        
        if tag == 0 {
            goToEecodingScreen()
        } else {
            goToDecodingScreen()
        }
    }
}

// MARK: Navigations
extension MainVC {
    private func goToEecodingScreen(){
        let storyboard = UIStoryboard(name: Storyboard.Encoding.rawValue, bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: VCIdentifier.EncodingVC.rawValue) as? EncodingVC {
            viewController.modalPresentationStyle = .fullScreen
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    private func goToDecodingScreen(){
        let storyboard = UIStoryboard(name: Storyboard.Decoding.rawValue, bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: VCIdentifier.DecodingVC.rawValue) as? DecodingVC {
            viewController.modalPresentationStyle = .fullScreen
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
