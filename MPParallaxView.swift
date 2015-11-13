//
//  MPParallaxView.swift
//
//  Created by Michal Pyrka on 29/10/15.
//  Copyright © 2015 MP. All rights reserved.
//

import UIKit
import CoreMotion

public enum ViewState {
    case Initial, Pick, PutDown
}

public enum ParallaxType {
    case BasedOnHierarchyInParallaxView(parallaxOffsetMultiplier: CGFloat?)
    case BasedOnTag
    case Custom(parallaxOffset: CGFloat)
}

private struct AccelerometerMovement {
    let x: Double
    let y: Double
}

public class MPParallaxView: UIView {
    @IBInspectable public var initialParallaxOffset: CGFloat = 5.0
    @IBInspectable public var zoomMultipler: CGFloat = 0.02
    @IBInspectable public var parallaxOffsetDuringPick: CGFloat = 15.0
    @IBInspectable public var multiplerOfIndexInHierarchyToParallaxOffset: CGFloat = 7.0
    @IBInspectable public var initialShadowRadius: CGFloat = 10.0
    @IBInspectable public var finalShadowRadius: CGFloat = 20.0
    
    private(set) public var state: ViewState = .Initial {
        didSet {
            if state != oldValue {
                animateForGivenState(state)
            }
        }
    }
    private(set) public var contentView: UIView = UIView()
    @IBInspectable public var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
            contentView.layer.cornerRadius = cornerRadius
        }
    }
    public var parallaxType: ParallaxType = .BasedOnTag
    @IBInspectable public var iconStyle: Bool = true
    var glowEffect: UIImageView = UIImageView()
    
    //MARK: CoreMotion
    private lazy var motionManager: CMMotionManager = CMMotionManager()
    private var accelerometerMovement: AccelerometerMovement?
    @IBInspectable public var accelerometerEnabled: Bool = false {
        didSet {
            if !accelerometerEnabled && motionManager.accelerometerActive {
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
    
    public func prepareParallaxLook() {
        setupLayout()
        addShadowPath()
        setupContentView()
    }
    
    public func prepareForNewViews() {
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
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        prepareForMotionDetection()
    }
    
    private func prepareForMotionDetection() {
        if let currentQueue = NSOperationQueue.currentQueue() where accelerometerEnabled {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdatesToQueue(currentQueue) { data, error in
                self.accelerometerMovement = AccelerometerMovement(x: data?.acceleration.x ?? 0.0, y: data?.acceleration.y ?? 0.0)
                UIView.animateWithDuration(0.1) {
                    self.applyParallaxEffectOnView(basedOnTouch: nil)
                    self.applyGlowEffectOnView(basedOnAccelerometerMovement: self.accelerometerMovement)
                }
            }
        }
    }
    
    private func setupLayout() {
        layer.shadowRadius = initialShadowRadius
        layer.shadowOpacity = 0.6
        layer.shadowColor = UIColor.blackColor().CGColor
        cornerRadius = iconStyle ? 5.0 : 0.0
        backgroundColor = .clearColor()
    }
    
    private func setupContentView() {
        contentView.frame = bounds
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .whiteColor()
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
    
    private func resizeSubviewsForParallax() {
        let offset: CGFloat = initialParallaxOffset
        contentView.subviews.forEach { subview in
            subview.frame.origin = CGPoint(x: -offset, y: -offset)
            subview.frame.size = CGSize(width: subview.frame.size.width + offset * 2.0, height: subview.frame.size.height + offset * 2.0)
        }
    }
    
    private func addShadowPath() {
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: 4, y: CGRectGetHeight(bounds)))
        path.addLineToPoint(CGPoint(x: CGRectGetWidth(bounds) - 4, y: CGRectGetHeight(bounds)))
        path.addLineToPoint(CGPoint(x: CGRectGetWidth(bounds) - 4, y: 20))
        path.addLineToPoint(CGPoint(x: 4, y: 20))
        path.closePath()
        layer.shadowPath = path.CGPath
    }
    
    //MARK: Animations
    
    private func makeZoomInEffect() {
        contentView.subviews.forEach { subview in
            subview.center = CGPoint(x: subview.center.x - widthZoom(subview), y: subview.center.y - heightZoom(subview))
            subview.frame.size = CGSize(width: subview.frame.size.width + widthZoom(subview) * 2, height: subview.frame.size.height + heightZoom(subview) * 2)
        }
    }
    
    private func makeZoomOutEffect() {
        UIView.animateWithDuration(0.3) {
            self.contentView.subviews.forEach { subview in
                subview.center = CGPoint(x: subview.center.x + self.widthZoom(subview), y: subview.center.y + self.heightZoom(subview))
                subview.frame.size = CGSize(width: subview.frame.size.width - self.widthZoom(subview) * 2, height: subview.frame.size.height - self.heightZoom(subview) * 2)
            }
        }
    }
    
    private func animateForGivenState(state: ViewState) {
        switch state {
        case .Pick:
            animatePick()
            makeZoomInEffect()
        case .PutDown:
            animateReturn()
            makeZoomOutEffect()
        case .Initial:
            break
        }
    }

    private func addShadowGroupAnimation(shadowOffset shadowOffset: CGSize, shadowRadius: CGFloat, duration: NSTimeInterval, layer: CALayer) {
        if let presentationLayer = layer.presentationLayer() as? CALayer {

            let offsetAnimation = CABasicAnimation(keyPath: "shadowOffset")
            offsetAnimation.fromValue = NSValue(CGSize: presentationLayer.shadowOffset)
            offsetAnimation.toValue = NSValue(CGSize: shadowOffset)

            let radiusAnimation = CABasicAnimation(keyPath: "shadowRadius")
            radiusAnimation.fromValue = presentationLayer.shadowRadius as NSNumber
            radiusAnimation.toValue = shadowRadius

            let animationGroup = CAAnimationGroup()

            animationGroup.duration = duration
            animationGroup.animations = [offsetAnimation, radiusAnimation]

            layer.addAnimation(animationGroup, forKey: "shadowAnim")
        }
        layer.shadowRadius = shadowRadius
        layer.shadowOffset = shadowOffset
    }
    
    private func pickAnimation() {
        let shadowOffset = CGSize(width: 0.0, height: 30.0);
        addShadowGroupAnimation(shadowOffset: shadowOffset, shadowRadius: finalShadowRadius, duration: 0.02, layer: layer)
    }
    
    private func putDownAnimation() {
        let shadowOffset = CGSizeZero
        addShadowGroupAnimation(shadowOffset: shadowOffset, shadowRadius: initialShadowRadius, duration: 0.4, layer: layer)
    }

    private func animatePick() {
        pickAnimation()
    }

    private func animateReturn() {
        putDownAnimation()
    }

    private func parallaxOffset(forView view: UIView) -> CGFloat {
        switch parallaxType {
        case .BasedOnHierarchyInParallaxView(let parallaxOffsetMultiplier):
            if let indexInSuperview = view.superview?.subviews.indexOf(view) {
                return CGFloat(indexInSuperview) * (parallaxOffsetMultiplier ?? multiplerOfIndexInHierarchyToParallaxOffset)
            } else {
                return 5.0
            }
        case .Custom(let parallaxOffset):
            return parallaxOffset
        case .BasedOnTag:
            return CGFloat(view.tag) * 2.0
        }
    }
    
    private func applyParallaxEffectOnSubviews(xOffset xOffset: CGFloat, yOffset: CGFloat) {
        var parallaxOffsetToSet: CGFloat
        for subview in contentView.subviews {
            parallaxOffsetToSet = parallaxOffset(forView: subview)
            let xParallaxOffsetAndSuperviewOffset = xOffset * CGFloat(parallaxOffsetToSet)
            let yParallaxOffsetAndSuperviewOffset = yOffset * CGFloat(parallaxOffsetToSet)
            subview.layer.transform = CATransform3DMakeTranslation(xParallaxOffsetAndSuperviewOffset, yParallaxOffsetAndSuperviewOffset, 0)
        }
    }
    
    private func applyParallaxEffectOnView(basedOnTouch touch: UITouch?) {
        var parallaxOffset = parallaxOffsetDuringPick
        var offsetX: CGFloat = 0.0, offsetY: CGFloat = 0.0
        if let accelerometerMovement = accelerometerMovement {
            offsetX = CGFloat(accelerometerMovement.x * 0.25)
            offsetY = CGFloat(accelerometerMovement.y * -0.25)
            parallaxOffset *= 2.0
        }
        
        if let touch = touch, let superview = superview where offsetX == 0.0 && offsetY == 0.0 {
            offsetX = (0.5 - touch.locationInView(superview).x / superview.bounds.width) * -1
            offsetY = (0.5 - touch.locationInView(superview).y / superview.bounds.height) * -1
        }
        
        var t = CATransform3DMakeScale(1.1, 1.1, 1.1)
        t.m34 = 1.0/(-500)
        let xAngle = (offsetX * parallaxOffset) * CGFloat(M_PI / 180.0)
        let yAngle = (offsetY * parallaxOffset) * CGFloat(M_PI / 180.0)
        t = CATransform3DRotate(t, xAngle, 0, -(0.5 - offsetY), 0)
        layer.transform = CATransform3DRotate(t, yAngle, (0.5 - offsetY) * 2, 0, 0)
        applyParallaxEffectOnSubviews(xOffset: offsetX, yOffset: offsetY)
    }
    
    private func removeParallaxEffectFromView() {
        UIView.animateWithDuration(0.5) {
            self.glowEffect.alpha = 0.0
            self.layer.transform = CATransform3DIdentity
            self.contentView.subviews.forEach { subview in
                subview.layer.transform = CATransform3DIdentity
            }
        }
    }
    
    //MARK: Glow effect
    private func applyGlowAlpha(glowAlpha: CGFloat) {
        if glowAlpha < 1.0 && glowAlpha > 0.0 {
            glowEffect.alpha = glowAlpha
        }
    }
    
    private func applyGlowEffectOnView(basedOnTouch touch: UITouch?) {
        let changeAlphaValue: CGFloat = 0.05
        if let touch = touch where touch.locationInView(self).y > bounds.height / 2 {
            glowEffect.center = touch.locationInView(self)
            applyGlowAlpha(glowEffect.alpha + changeAlphaValue)
        } else {
            applyGlowAlpha(glowEffect.alpha - changeAlphaValue)
        }
    }
    
    private func applyGlowEffectOnView(basedOnAccelerometerMovement movement: AccelerometerMovement?) {
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
    
    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        state = .Pick
        applyParallaxEffectOnView(basedOnTouch: Array(touches).first)
        applyGlowEffectOnView(basedOnTouch: Array(touches).first)
        super.touchesMoved(touches, withEvent: event)
    }
    
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        state = .PutDown
        removeParallaxEffectFromView()
        super.touchesEnded(touches, withEvent: event)
    }
}

extension MPParallaxView {
    
    func heightZoom(viewToCalculate: UIView) -> CGFloat {
        return viewToCalculate.bounds.size.height * zoomMultipler
    }
    
    func widthZoom(viewToCalculate: UIView) -> CGFloat {
        return viewToCalculate.bounds.size.width * zoomMultipler
    }
}