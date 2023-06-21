//
//  File.swift
//  CoGuard
//
//  Created by عمرو on 4.06.2023.
//

import Foundation

import UIKit
import Lottie

class LottieCoveredNVC: UINavigationController {
    
    // MARK: Views
    private var animationView = LottieAnimationView()
    private var coverView = UIView()
    
    // MARK: Viewcycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAnimationView()
    }
    
    // MARK: Helpers
    private func setupAnimationView(){
        animationView.animation = LottieAnimation.named(LoadingAnimation.binary)
        animationView.frame = CGRect(x: 0, y: 0, width: view.bounds.width*0.8, height: view.bounds.height)
        animationView.center = view.center
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        
        coverView.frame = self.view.bounds
        coverView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
    }
    
    
    func showLoadingAnimation(){
        animationView.play()
        if let navigationController = navigationController {
            navigationController.view.addSubview(coverView)
            navigationController.view.addSubview(animationView)
        } else {
            view.addSubview(coverView)
            view.addSubview(animationView)
        }
    }
    
    func hideLoadingAnimation(){
        animationView.stop()
        animationView.removeFromSuperview()
        coverView.removeFromSuperview()
    }
    
}
