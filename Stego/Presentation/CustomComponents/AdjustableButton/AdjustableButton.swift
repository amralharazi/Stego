//
//  AdjustableButton.swift
//  CoGuard
//
//  Created by عمرو on 16.05.2023.
//

import UIKit

@IBDesignable
class AdjustableButton: UIButton {
    
    @IBInspectable public var cornerRadius: CGFloat {
        get { layer.cornerRadius }
        set { layer.cornerRadius = newValue }
    }
    
    @IBInspectable public var borderWidth: CGFloat {
        get { layer.borderWidth }
        set { layer.borderWidth = newValue }
    }
    
    @IBInspectable public var borderColor: UIColor? {
        get { layer.borderColor.flatMap { UIColor(cgColor: $0) } }
        set { layer.borderColor = newValue?.cgColor }
    }
    
    @IBInspectable var textColor: UIColor = .white {didSet{ setTitleColor(textColor, for: .normal)}}
    @IBInspectable var textSize: CGFloat = 14 {didSet{updateFont()}}
    @IBInspectable var boldText: Bool = false {didSet{updateFont()}}
    
    // MARK: Init
    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = AppConstants.radiusTen
    }
    
    // MARK:  Helpers
    private func setupButton(){
        setTitleColor(.white, for: .normal)
        titleLabel?.font =  .systemFont(ofSize: textSize, weight: boldText ? .semibold : .medium)
        titleLabel?.adjustsFontSizeToFitWidth = true
        tintColor = .white
    }
    
    private func updateFont(){
        titleLabel?.font =  .systemFont(ofSize: textSize, weight: boldText ? .semibold : .medium)
    }
}
