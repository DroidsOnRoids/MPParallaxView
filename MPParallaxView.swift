//
//  MPParallaxView.swift
//
//  Created by Michal Pyrka on 29/10/15.
//  Copyright © 2015 MP. All rights reserved.
//

import UIKit

public enum ViewState {
    case Initial, Pick, PutDown
}

public enum ParallaxType {
    case BasedOnHierarchyInParallaxView
    case BasedOnTag
    case Custom(Int)
}

public let initialParallaxOffset: CGFloat = 5.0
public let zoomMultipler: CGFloat = 0.02
public let parallaxOffsetDuringPick: CGFloat = 15.0
public let multiplerOfIndexInHierarchyToParallaxOffset: CGFloat = 7.0
public let initialShadowRadius: CGFloat = 10.0

public class MPParallaxView: UIView {
    
    public var state: ViewState = .Initial {
        didSet {
            if state != oldValue {
                animateForGivenState(state)
            }
        }
    }
    var contentView: UIView = UIView()
    public var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
            contentView.layer.cornerRadius = cornerRadius
        }
    }
    public var parallaxType: ParallaxType = .BasedOnTag
    public var iconStyle: Bool = true
    var glowEffect: UIImageView = UIImageView()
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        prepareParallaxLook()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareParallaxLook()
    }
    
    //MARK: Setup layout
    
    func prepareParallaxLook() {
        setupLayout()
        addShadowPath()
        setupContentView()
    }
    
    func setupLayout() {
        layer.shadowRadius = initialShadowRadius
        layer.shadowOpacity = 0.6
        layer.shadowColor = UIColor.blackColor().CGColor
        cornerRadius = iconStyle ? 5.0 : 0.0
        backgroundColor = .clearColor()
    }
    
    func setupContentView() {
        contentView.frame = bounds
        contentView.layer.masksToBounds = true
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
    
    func resizeSubviewsForParallax() {
        let offset: CGFloat = initialParallaxOffset
        contentView.subviews.forEach { subview in
            subview.frame.origin = CGPoint(x: -offset, y: -offset)
            subview.frame.size = CGSize(width: subview.frame.size.width + offset * 2.0, height: subview.frame.size.height + offset * 2.0)
        }
    }
    
    func addShadowPath() {
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: 4, y: CGRectGetHeight(bounds)))
        path.addLineToPoint(CGPoint(x: CGRectGetWidth(bounds) - 4, y: CGRectGetHeight(bounds)))
        path.addLineToPoint(CGPoint(x: CGRectGetWidth(bounds) - 4, y: 20))
        path.addLineToPoint(CGPoint(x: 4, y: 20))
        path.closePath()
        layer.shadowPath = path.CGPath
    }
    
    //MARK: Animations
    
    func makeZoomInEffect() {
        contentView.subviews.forEach { subview in
            subview.center = CGPoint(x: subview.center.x - widthZoom(subview), y: subview.center.y - heightZoom(subview))
            subview.frame.size = CGSize(width: subview.frame.size.width + widthZoom(subview) * 2, height: subview.frame.size.height + heightZoom(subview) * 2)
        }
    }
    
    func makeZoomOutEffect() {
        UIView.animateWithDuration(0.3) {
            self.contentView.subviews.forEach { subview in
                subview.center = CGPoint(x: subview.center.x + self.widthZoom(subview), y: subview.center.y + self.heightZoom(subview))
                subview.frame.size = CGSize(width: subview.frame.size.width - self.widthZoom(subview) * 2, height: subview.frame.size.height - self.heightZoom(subview) * 2)
            }
        }
    }
    
    func animateForGivenState(state: ViewState) {
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
    
    func animatePick() {
        layer.addAnimation(pickAnimation(), forKey: nil)
    }
    
    func groupAnimation(shadowOffset shadowOffset: CGSize, shadowRadius: CGFloat, duration: NSTimeInterval) -> CAAnimationGroup {
        let offsetAnimation = CABasicAnimation(keyPath: "shadowOffset")
        offsetAnimation.toValue = NSValue(CGSize: shadowOffset)
        
        let radiusAnimation = CABasicAnimation(keyPath: "shadowRadius")
        radiusAnimation.toValue = shadowRadius
        
        let animationGroup = CAAnimationGroup()
        animationGroup.fillMode = kCAFillModeForwards
        animationGroup.removedOnCompletion = false
        animationGroup.duration = duration
        animationGroup.animations = [offsetAnimation, radiusAnimation]
        return animationGroup
    }
    
    func pickAnimation() -> CAAnimationGroup {
        return groupAnimation(shadowOffset: CGSize(width: 0.0, height: 30.0), shadowRadius: 20.0, duration: 0.02)
    }
    
    func putDownAnimation() -> CAAnimationGroup {
        return groupAnimation(shadowOffset: CGSize(width: 0.0, height: 0.0), shadowRadius: initialShadowRadius, duration: 0.4)
    }
    
    func animateReturn() {
        self.layer.addAnimation(putDownAnimation(), forKey: nil)
    }
    
    func parallaxOffset(forView view: UIView) -> CGFloat {
        switch parallaxType {
        case .BasedOnHierarchyInParallaxView:
            if let indexInSuperview = view.superview?.subviews.indexOf(view) {
                return CGFloat(indexInSuperview) * multiplerOfIndexInHierarchyToParallaxOffset
            } else {
                return 5.0
            }
        case .Custom(let customValue):
            return CGFloat(customValue)
        case .BasedOnTag:
            return CGFloat(view.tag) * 2.0
        }
    }
    
    func applyParallaxEffectOnSubviews(xOffset xOffset: CGFloat, yOffset: CGFloat) {
        var parallaxOffsetToSet: CGFloat
        for subview in contentView.subviews {
            parallaxOffsetToSet = parallaxOffset(forView: subview)
            let xParallaxOffsetAndSuperviewOffset = xOffset * CGFloat(parallaxOffsetToSet)
            let yParallaxOffsetAndSuperviewOffset = yOffset * CGFloat(parallaxOffsetToSet)
            subview.layer.transform = CATransform3DMakeTranslation(xParallaxOffsetAndSuperviewOffset, yParallaxOffsetAndSuperviewOffset, 0)
        }
    }
    
    func applyParallaxEffectOnView(basedOnTouch touch: UITouch?) {
        if let touch = touch, let superview = superview {
            let offsetX = (0.5 - touch.locationInView(superview).x / superview.bounds.width) * -1
            let offsetY = (0.5 - touch.locationInView(superview).y / superview.bounds.height) * -1
            var t = CATransform3DMakeScale(1.1, 1.1, 1.1)
            t.m34 = 1.0/(-500)
            let xAngle = (offsetX * parallaxOffsetDuringPick) * CGFloat(M_PI / 180.0)
            let yAngle = (offsetY * parallaxOffsetDuringPick) * CGFloat(M_PI / 180.0)
            t = CATransform3DRotate(t, xAngle, 0, -(0.5 - offsetY), 0)
            layer.transform = CATransform3DRotate(t, yAngle, (0.5 - offsetY) * 2, 0, 0)
            applyParallaxEffectOnSubviews(xOffset: offsetX, yOffset: offsetY)
        }
    }
    
    func applyGlowAlpha(glowAlpha: CGFloat) {
        if glowAlpha < 1.0 && glowAlpha > 0.0 {
            glowEffect.alpha = glowAlpha
        }
    }
    
    func applyGlowEffectOnView(basedOnTouch touch: UITouch?) {
        let changeAlphaValue: CGFloat = 0.05
        if let touch = touch where touch.locationInView(self).y > bounds.height / 2 {
            glowEffect.center = touch.locationInView(self)
            applyGlowAlpha(glowEffect.alpha + changeAlphaValue)
        } else {
            applyGlowAlpha(glowEffect.alpha - changeAlphaValue)
        }
    }
    
    func removeParallaxEffectFromView() {
        UIView.animateWithDuration(0.5) {
            self.glowEffect.alpha = 0.0
            self.layer.transform = CATransform3DIdentity
            self.contentView.subviews.forEach { subview in
                subview.layer.transform = CATransform3DIdentity
            }
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