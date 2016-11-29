//
//  MPParallaxView.swift
//
//  Created by Michal Pyrka on 29/10/15.
//  Copyright © 2015 MP. All rights reserved.
//

import UIKit
import CoreMotion

public enum ViewState {
    case initial, pick, putDown
}

public enum ParallaxType {
    case basedOnHierarchyInParallaxView(parallaxOffsetMultiplier: CGFloat?)
    case basedOnTag
    case custom(parallaxOffset: CGFloat)
}

private struct AccelerometerMovement {
    let x: Double
    let y: Double
}

open class MPParallaxView: UIView {
    @IBInspectable open var initialParallaxOffset: CGFloat = 5.0
    @IBInspectable open var zoomMultipler: CGFloat = 0.02
    @IBInspectable open var parallaxOffsetDuringPick: CGFloat = 15.0
    @IBInspectable open var multiplerOfIndexInHierarchyToParallaxOffset: CGFloat = 7.0
    @IBInspectable open var initialShadowRadius: CGFloat = 10.0
    @IBInspectable open var finalShadowRadius: CGFloat = 20.0
    
    fileprivate(set) open var state: ViewState = .initial {
        didSet {
            if state != oldValue {
                animateForGivenState(state)
            }
        }
    }
    fileprivate(set) open var contentView: UIView = UIView()
    @IBInspectable open var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
            contentView.layer.cornerRadius = cornerRadius
        }
    }
    open var parallaxType: ParallaxType = .basedOnTag
    @IBInspectable open var iconStyle: Bool = true
    var glowEffect: UIImageView = UIImageView()
    
    //MARK: CoreMotion
    fileprivate lazy var motionManager: CMMotionManager = CMMotionManager()
    fileprivate var accelerometerMovement: AccelerometerMovement?
    @IBInspectable open var accelerometerEnabled: Bool = false {
        didSet {
            if !accelerometerEnabled && motionManager.isAccelerometerActive {
                motionManager.stopAccelerometerUpdates()
            }
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        prepareParallaxLook()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareParallaxLook()
    }
    
    //MARK: Setup layout
    
    open func prepareParallaxLook() {
        setupLayout()
        addShadowPath()
        setupContentView()
    }
    
    open func prepareForNewViews() {
        if accelerometerEnabled {
            glowEffect.alpha = 0.0
            layer.transform = CATransform3DIdentity
            contentView.subviews.forEach { subview in
                subview.layer.transform = CATransform3DIdentity
            }
        }
        subviews.forEach { $0.removeFromSuperview() }
        contentView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        prepareForMotionDetection()
    }
    
    fileprivate func prepareForMotionDetection() {
        if let currentQueue = OperationQueue.current, accelerometerEnabled {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: currentQueue) { data, error in
                self.accelerometerMovement = AccelerometerMovement(x: data?.acceleration.x ?? 0.0, y: data?.acceleration.y ?? 0.0)
                UIView.animate(withDuration: 0.1, animations: {
                    self.applyParallaxEffectOnView(basedOnTouch: nil)
                    self.applyGlowEffectOnView(basedOnAccelerometerMovement: self.accelerometerMovement)
                }) 
            }
        }
    }
    
    fileprivate func setupLayout() {
        layer.shadowRadius = initialShadowRadius
        layer.shadowOpacity = 0.6
        layer.shadowColor = UIColor.black.cgColor
        cornerRadius = iconStyle ? 5.0 : 0.0
        backgroundColor = .clear
    }
    
    fileprivate func setupContentView() {
        contentView.frame = bounds
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .white
        subviews.forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = true
            subview.removeFromSuperview()
            contentView.addSubview(subview)
        }
        resizeSubviewsForParallax()
        if let glowImage = UIImage(named: "gloweffect") {
            glowEffect = UIImageView(image: glowImage)
            glowEffect.alpha = 0.0
            contentView.addSubview(glowEffect)
        }
        addSubview(contentView)
    }
    
    fileprivate func resizeSubviewsForParallax() {
        let offset: CGFloat = initialParallaxOffset
        contentView.subviews.forEach { subview in
            subview.frame.origin = CGPoint(x: -offset, y: -offset)
            subview.frame.size = CGSize(width: subview.frame.size.width + offset * 2.0, height: subview.frame.size.height + offset * 2.0)
        }
    }
    
    fileprivate func addShadowPath() {
        let path = UIBezierPath()
        let xOffset: CGFloat = 4.0
        let yOffset: CGFloat = 20.0
        path.move(to: CGPoint(x: xOffset, y: bounds.height))
        path.addLine(to: CGPoint(x: bounds.width - xOffset, y: bounds.height))
        path.addLine(to: CGPoint(x: bounds.width - xOffset, y: yOffset))
        path.addLine(to: CGPoint(x: xOffset, y: yOffset))
        path.close()
        layer.shadowPath = path.cgPath
    }
    
    //MARK: Animations
    
    fileprivate func makeZoomInEffect() {
        contentView.subviews.forEach { subview in
            subview.center = CGPoint(x: subview.center.x - widthZoom(subview), y: subview.center.y - heightZoom(subview))
            subview.frame.size = CGSize(width: subview.frame.size.width + widthZoom(subview) * 2.0, height: subview.frame.size.height + heightZoom(subview) * 2.0)
        }
    }
    
    fileprivate func makeZoomOutEffect() {
        UIView.animate(withDuration: 0.3, animations: {
            self.contentView.subviews.forEach { subview in
                subview.center = CGPoint(x: subview.center.x + self.widthZoom(subview), y: subview.center.y + self.heightZoom(subview))
                subview.frame.size = CGSize(width: subview.frame.size.width - self.widthZoom(subview) * 2.0, height: subview.frame.size.height - self.heightZoom(subview) * 2.0)
            }
        }) 
    }
    
    fileprivate func animateForGivenState(_ state: ViewState) {
        switch state {
        case .pick:
            animatePick()
            makeZoomInEffect()
        case .putDown:
            animateReturn()
            makeZoomOutEffect()
        case .initial:
            break
        }
    }

    fileprivate func addShadowGroupAnimation(shadowOffset: CGSize, shadowRadius: CGFloat, duration: TimeInterval, layer: CALayer) {
        if let presentationLayer = layer.presentation() {
            let offsetAnimation = CABasicAnimation(keyPath: "shadowOffset")
            offsetAnimation.fromValue = NSValue(cgSize: presentationLayer.shadowOffset)
            offsetAnimation.toValue = NSValue(cgSize: shadowOffset)

            let radiusAnimation = CABasicAnimation(keyPath: "shadowRadius")
            radiusAnimation.fromValue = presentationLayer.shadowRadius as NSNumber
            radiusAnimation.toValue = shadowRadius

            let animationGroup = CAAnimationGroup()

            animationGroup.duration = duration
            animationGroup.animations = [offsetAnimation, radiusAnimation]

            layer.add(animationGroup, forKey: "shadowAnim")
        }

        layer.shadowRadius = shadowRadius
        layer.shadowOffset = shadowOffset
    }
    
    fileprivate func pickAnimation() {
        let shadowOffset = CGSize(width: 0.0, height: 30.0);
        addShadowGroupAnimation(shadowOffset: shadowOffset, shadowRadius: finalShadowRadius, duration: 0.02, layer: layer)
    }
    
    fileprivate func putDownAnimation() {
        let shadowOffset = CGSize.zero
        addShadowGroupAnimation(shadowOffset: shadowOffset, shadowRadius: initialShadowRadius, duration: 0.4, layer: layer)
    }

    fileprivate func animatePick() {
        pickAnimation()
    }

    fileprivate func animateReturn() {
        putDownAnimation()
    }

    fileprivate func parallaxOffset(forView view: UIView) -> CGFloat {
        switch parallaxType {
        case .basedOnHierarchyInParallaxView(let parallaxOffsetMultiplier):
            if let indexInSuperview = view.superview?.subviews.index(of: view) {
                return CGFloat(indexInSuperview) * (parallaxOffsetMultiplier ?? multiplerOfIndexInHierarchyToParallaxOffset)
            } else {
                return 5.0
            }
        case .custom(let parallaxOffset):
            return parallaxOffset
        case .basedOnTag:
            return CGFloat(view.tag) * 2.0
        }
    }
    
    fileprivate func applyParallaxEffectOnSubviews(xOffset: CGFloat, yOffset: CGFloat) {
        var parallaxOffsetToSet: CGFloat
        for subview in contentView.subviews {
            parallaxOffsetToSet = parallaxOffset(forView: subview)
            let xParallaxOffsetAndSuperviewOffset = xOffset * CGFloat(parallaxOffsetToSet)
            let yParallaxOffsetAndSuperviewOffset = yOffset * CGFloat(parallaxOffsetToSet)
            subview.layer.transform = CATransform3DMakeTranslation(xParallaxOffsetAndSuperviewOffset, yParallaxOffsetAndSuperviewOffset, 0)
        }
    }
    
    fileprivate func applyParallaxEffectOnView(basedOnTouch touch: UITouch?) {
        var parallaxOffset = parallaxOffsetDuringPick
        var offsetX: CGFloat = 0.0, offsetY: CGFloat = 0.0
        if let accelerometerMovement = accelerometerMovement {
            offsetX = CGFloat(accelerometerMovement.x * 0.25)
            offsetY = CGFloat(accelerometerMovement.y * -0.25)
            parallaxOffset *= 2.0
        }
        
        if let touch = touch, let superview = superview, offsetX == 0.0 && offsetY == 0.0 {
            offsetX = (0.5 - touch.location(in: superview).x / superview.bounds.width) * -1
            offsetY = (0.5 - touch.location(in: superview).y / superview.bounds.height) * -1
        }
        
        var t = CATransform3DMakeScale(1.1, 1.1, 1.1)
        t.m34 = 1.0/(-500)
        let xAngle = (offsetX * parallaxOffset) * CGFloat(M_PI / 180.0)
        let yAngle = (offsetY * parallaxOffset) * CGFloat(M_PI / 180.0)
        t = CATransform3DRotate(t, xAngle, 0, -(0.5 - offsetY), 0)
        layer.transform = CATransform3DRotate(t, yAngle, (0.5 - offsetY) * 2, 0, 0)
        applyParallaxEffectOnSubviews(xOffset: offsetX, yOffset: offsetY)
    }
    
    fileprivate func removeParallaxEffectFromView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.glowEffect.alpha = 0.0
            self.layer.transform = CATransform3DIdentity
            self.contentView.subviews.forEach { subview in
                subview.layer.transform = CATransform3DIdentity
            }
        }) 
    }
    
    //MARK: Glow effect
    fileprivate func applyGlowAlpha(_ glowAlpha: CGFloat) {
        if glowAlpha < 1.0 && glowAlpha > 0.0 {
            glowEffect.alpha = glowAlpha
        }
    }
    
    fileprivate func applyGlowEffectOnView(basedOnTouch touch: UITouch?) {
        let changeAlphaValue: CGFloat = 0.05
        if let touch = touch, touch.location(in: self).y > bounds.height / 2 {
            glowEffect.center = touch.location(in: self)
            applyGlowAlpha(glowEffect.alpha + changeAlphaValue)
        } else {
            applyGlowAlpha(glowEffect.alpha - changeAlphaValue)
        }
    }
    
    fileprivate func applyGlowEffectOnView(basedOnAccelerometerMovement movement: AccelerometerMovement?) {
        guard let movement = movement, let superview = superview else { return }
        let bigMultiplerForAccelerometerToGlowOffset: Double = Double(superview.bounds.size.width * 2.0)
        glowEffect.center = CGPoint(x: center.x + CGFloat(movement.x * bigMultiplerForAccelerometerToGlowOffset),
            y: center.y + CGFloat(movement.y *
                bigMultiplerForAccelerometerToGlowOffset) * -1.0)
        let changeAlphaValue: CGFloat = 0.05
        if glowEffect.center.y > center.y {
            applyGlowAlpha(glowEffect.alpha + changeAlphaValue)
        } else {
            applyGlowAlpha(glowEffect.alpha - changeAlphaValue)
        }
    }
    
    //MARK: On touch actions
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        state = .pick
        applyParallaxEffectOnView(basedOnTouch: Array(touches).first)
        applyGlowEffectOnView(basedOnTouch: Array(touches).first)
        super.touchesMoved(touches, with: event)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        state = .putDown
        removeParallaxEffectFromView()
        super.touchesEnded(touches, with: event)
    }
}

extension MPParallaxView {
    
    func heightZoom(_ viewToCalculate: UIView) -> CGFloat {
        return viewToCalculate.bounds.size.height * zoomMultipler
    }
    
    func widthZoom(_ viewToCalculate: UIView) -> CGFloat {
        return viewToCalculate.bounds.size.width * zoomMultipler
    }
}
