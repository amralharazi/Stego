//
//  ShadowedView.swift
//  Fastfull
//
//  Created by عمرو on 4.01.2023.
//

import UIKit

class ShadowedView: RoundedView {
    
    // MARK:  Subviews
    override var bounds: CGRect {
        didSet {
            setupShadow(radius)
        }
    }

    private func setupShadow(_ cornerRadius: CGFloat = 0) {
        self.layer.masksToBounds = false
        self.layer.cornerRadius = cornerRadius
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 5
        self.layer.shadowOpacity = 0.08
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width:cornerRadius, height: cornerRadius)).cgPath
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
    }
}
