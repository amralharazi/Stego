//
//  RoundedView.swift
//  Etikit
//
//  Created by عمرو on 25.01.2023.
//

import Foundation
import UIKit

@IBDesignable
public class RoundedView: UIView {
    
    @IBInspectable var isCircle: Bool = false  {didSet{setupView()}}
    @IBInspectable var radius: Double = 0.0  {didSet{setupView()}}
    @IBInspectable var roundTopCorners: Bool = false {didSet{setupView()}}
    @IBInspectable var roundBottomCorners: Bool = false {didSet{setupView()}}
    @IBInspectable var roundLeftCorners: Bool = false {didSet{setupView()}}
    @IBInspectable var roundRightCorners: Bool = false {didSet{setupView()}}
    
    @IBInspectable var isBordered: Bool = false {didSet{setupBorder()}}
    @IBInspectable var borderColor: UIColor = .lightGray {didSet{setupBorder()}}
    @IBInspectable var borderWidth: CGFloat = 1 {didSet{setupBorder()}}
    
    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setupView()
        setupBorder()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupBorder()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = isCircle ? (frame.height/2.0) : radius
    }
    
    private func setupView(){
        guard !isCircle else {return}
        
        if roundTopCorners {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
        
        if roundBottomCorners {
            layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        
        if roundRightCorners {
            layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }
        
        if roundLeftCorners {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        }
    }
    
    private func setupBorder(){
        guard isBordered else {return}
        addBoder(with: borderColor, width: borderWidth)
    }
}
