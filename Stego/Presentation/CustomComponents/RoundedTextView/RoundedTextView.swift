//
//  RoundedTextView.swift
//  CoGuard
//
//  Created by عمرو on 24.05.2023.
//

import UIKit

@IBDesignable
class RoundedTextView: UITextView {
    @IBInspectable var radius: CGFloat = 10 {didSet{setRadius()}}
    @IBInspectable var isBordered: Bool = false
    @IBInspectable var borderColor: UIColor = .lightGray {didSet{setupBorder()}}
    @IBInspectable var borderWidth: CGFloat = 0 {didSet{setupBorder()}}
    @IBInspectable var padding: CGFloat = 10 {didSet{setPadding()}}
        
    // MARK:  Init
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setPadding()
    }
    
    // MARK:  Helpers
    private func setup() {
        font = .systemFont(ofSize: 14, weight: .medium)
        textAlignment = .left
        autocorrectionType = .no
        spellCheckingType = .no
        clipsToBounds = true
    }
    
    private func setRadius(){
        layer.cornerRadius = radius
    }
    
    private func setupBorder(){
        guard isBordered else {return}
        addBoder(with: borderColor, width: borderWidth)
    }
    
    private func setPadding(){
        contentInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
    }    
}
