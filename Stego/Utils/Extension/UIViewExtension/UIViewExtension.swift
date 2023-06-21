//
//  ViewExtension.swift
//  Stegno
//
//  Created by عمرو on 18.06.2023.
//

import UIKit

extension UIView {
    func addBoder(with color: UIColor = .lightGray, cornerRadius: CGFloat = AppConstants.radiusTen, width: CGFloat = 1){
        self.layer.cornerRadius = cornerRadius
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
    }
}
