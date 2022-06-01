//
//  Button3D.swift
//  FJButton3D
//
//  Created by Federico Jordán on 19/10/17.
//  Modified by Oliver
//  Copyright © 2017 LettersWar. All rights reserved.
//
import UIKit
import AVFoundation

protocol FJButton3DDelegate: class {
    func didTap(onButton3D button3d: FJButton3D)
    func didStartTap(onButton3D button3d: FJButton3D)
    func didEndTap(onButton3D button3d: FJButton3D)
}

extension FJButton3DDelegate {
    func didStartTap(onButton3D button3d: FJButton3D) {}
    func didEndTap(onButton3D button3d: FJButton3D) {}
}

enum FJButton3DStyle {
    case pressed
    case `default`
}

@IBDesignable
class FJButton3D: UIView {

    private let zValue: CGFloat = 5
    private let roundedPercentage: CGFloat = 0.2
    private var behindView = UIView()
    private var frontView = UIView()
    var titleLabel = UILabel()
    private var player: AVAudioPlayer?
    private var pressDate: Date?
    private var imageView = UIImageView()
    private var imageSize: CGSize?
    
    @IBInspectable var pressed: Bool = false {
        didSet(oldValue) {
            if oldValue != pressed {
                updatePressedStatus()
            }
        }
    }
    
    var style = FJButton3DStyle.default
    
    weak var delegate: FJButton3DDelegate?
    
    @IBInspectable var frontColor: UIColor = UIColor.white {
        didSet(oldValue) {
            frontView.backgroundColor = frontColor
        }
    }
    
    @IBInspectable var behindColor: UIColor = UIColor.lightGray {
        didSet(oldValue) {
            behindView.backgroundColor = behindColor
        }
    }
    
    @IBInspectable var textColor: UIColor = UIColor.black {
        didSet(oldValue) {
            titleLabel.textColor = textColor
        }
    }
    
    @IBInspectable var text: String = "" {
        didSet(oldValue) {
            titleLabel.text = text.uppercased()
            titleLabel.font = UIFont(name:"KarmaticArcade", size: 30)
            titleLabel.adjustsFontSizeToFitWidth = true
            titleLabel.minimumScaleFactor = 0.5
        }
    }
    
    @IBInspectable var image: UIImage? = nil {
        didSet(oldValue) {
            imageView.image = image
        }
    }
    
    @IBInspectable var imageTint: UIColor? = nil {
        didSet(oldValue) {
            
        }
    }
    
    @IBInspectable var size: CGFloat = 40 {
        didSet(oldValue) {
            imageSize = CGSize(width: size, height: size)
        }
    }
    
    @IBInspectable var sound: Bool = true {
        didSet(oldValue) {
            
        }
    }
    
    func playSound(_ sound: Sound) {
        guard let path = Bundle.main.path(forResource: sound.rawValue, ofType:"mp3") else {
            return }
        let url = URL(fileURLWithPath: path)
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    override func awakeFromNib() {
        backgroundColor = UIColor.clear
        prepareBehindView()
        prepareFrontView()
        prepareTitleLabel()
        prepareImage()

        isUserInteractionEnabled = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        behindView.frame = frame
        behindView.frame.origin = CGPoint(x: 0, y: 0)
        behindView.frame.origin.y += zValue
        frontView.frame = frame
        frontView.frame.origin = CGPoint(x: 0, y: 0)
        titleLabel.frame = frame
        titleLabel.frame.origin = CGPoint(x: 0, y: 0)
        if let imageSize = imageSize {
            let x = (frame.size.width-imageSize.width)/2
            let y = (frame.size.height-imageSize.height)/2
            imageView.frame = CGRect(x: x, y: y, width: imageSize.width, height: imageSize.height)
        }
    }
    
    private func prepareBehindView() {
        behindView.frame = frame
        addSubview(behindView)
        behindView.frame.origin = CGPoint(x: 0, y: 0)
        behindView.frame.origin.y += zValue
        behindView.layer.borderWidth = 0.0
        behindView.layer.cornerRadius = frame.height*roundedPercentage
        behindView.backgroundColor = behindColor
    }
    
    private func prepareFrontView() {
        frontView.frame = frame
        addSubview(frontView)
        frontView.frame.origin = CGPoint(x: 0, y: 0)
        frontView.layer.borderWidth = 0.0
        frontView.layer.cornerRadius = frame.height*roundedPercentage
        frontView.backgroundColor = frontColor
    }
    
    private func prepareTitleLabel() {
        titleLabel.frame = frame
        addSubview(titleLabel)
        titleLabel.frame.origin = CGPoint(x: 0, y: 0)
        titleLabel.text = text.uppercased()
        titleLabel.textColor = textColor
        titleLabel.textAlignment = .center
        titleLabel.isUserInteractionEnabled = true
    }
    
    private func prepareImage() {
        imageView.frame = frame
        addSubview(imageView)
        imageView.frame.origin = CGPoint(x: 0, y: 0)
        imageView.contentMode = .scaleAspectFit
        if let imageTint = imageTint {
            imageView.tintColor = imageTint
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.didStartTap(onButton3D: self)
        if style == .pressed {
            if pressed == false {
                pressed = !pressed
            }
        } else {
            pressed = true
        }
        pressDate = Date()
        if sound {
            playSound(.buttonPress)
        }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.didEndTap(onButton3D: self)
        if style != .pressed {
            pressed = false
            if let pressDate = pressDate, let difference = Calendar.current.dateComponents([.nanosecond], from: pressDate, to: Date()).nanosecond {
                if difference > 500000000 {
                    if sound {
                        playSound(.buttonPress)
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }
        }
        if let touch = touches.first?.location(in: self.superview!), frame.contains(touch) {
            delegate?.didTap(onButton3D: self)
        }
    }
    
    private func updatePressedStatus() {
        if pressed == false {
            frontView.frame.origin.y -= zValue
            titleLabel.frame.origin.y -= zValue
            imageView.frame.origin.y -= zValue
        } else {
            frontView.frame.origin.y += zValue
            titleLabel.frame.origin.y += zValue
            imageView.frame.origin.y += zValue
        }
    }
}
