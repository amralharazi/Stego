//
//  RoundedIV.swift
//  Indirme
//
//  Created by عمرو on 6.02.2023.
//
import UIKit

@IBDesignable
class RoundedIV: UIImageView {
    
    @IBInspectable public var isCircle: Bool =  false
    @IBInspectable public var radius: Double = 10.0
    
    @IBInspectable var isBordered: Bool = false {didSet{setupBorder()}}
    @IBInspectable var borderColor: UIColor = .lightGray {didSet{setupBorder()}}
    @IBInspectable var borderWidth: CGFloat = 1 {didSet{setupBorder()}}

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = isCircle ? (frame.width/2.0) : radius
    }
    
    private func setupBorder(){
        guard isBordered else {return}
        addBoder(with: borderColor, cornerRadius: radius, width: borderWidth)
    }
}
