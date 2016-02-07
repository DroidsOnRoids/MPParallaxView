//
//  ViewController.swift
//  MPParallaxView
//
//  Created by Michal Pyrka on 11/08/2015.
//  Copyright (c) 2015 Michal Pyrka. All rights reserved.
//

import UIKit
import MPParallaxView

public enum AssetsNames: String {
    case Interstellar = "noblurintersterllarbackground"
    case Spectre = "noblurspectrebackground"
}

class ViewController: UIViewController {
    
    private var blurredPosterImageView: UIImageView?
    @IBAction func segmentedControlChanged(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            setupInterstellar()
        } else {
            setupSpectre()
        }
    }
    
    func setupInterstellar() {
        view.backgroundColor = UIColor(red: 198.0/255.0, green: 215.0/255.0, blue: 224.0/255.0, alpha: 1.0)
            blurredPosterImageView?.image = UIImage.imageFromAssets(.Interstellar)
        let parallaxView = view.subviews.filter { $0 is MPParallaxView }.first as? MPParallaxView
        if let parallaxView = parallaxView {
            parallaxView.prepareForNewViews()
            self.interstellarAssets().forEach { parallaxView.addSubview($0) }
            parallaxView.prepareParallaxLook()
        }
    }
    
    func setupSpectre() {
        view.backgroundColor = UIColor(red: 250.0/255.0, green: 250.0/255.0, blue: 250.0/255.0, alpha: 1.0)
        blurredPosterImageView?.image = UIImage.imageFromAssets(.Spectre)
        let parallaxView = view.subviews.filter { $0 is MPParallaxView }.first as? MPParallaxView
        if let parallaxView = parallaxView {
            parallaxView.prepareForNewViews()
            let assets: [UIImageView] = self.spectreAssets()
            assets.forEach { parallaxView.addSubview($0) }
            parallaxView.prepareParallaxLook()
            if let logo = assets.first {
                logo.frame = CGRectOffset(logo.frame, -50, 0)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UISegmentedControl.appearance().setTitleTextAttributes(
            [NSForegroundColorAttributeName : UIColor.whiteColor()],
            forState: .Selected)
        setupBlur()
    }
    
    private func setupBlur() {
        let blurImageView = UIImageView(image: UIImage.imageFromAssets(.Interstellar))
        blurImageView.frame = view.frame
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurImageView.addSubview(blurEffectView)
        view.insertSubview(blurImageView, atIndex: 0)
        blurredPosterImageView = blurImageView
        setupZIndex()
    }
    
    private func setupZIndex() {
        (view.subviews.filter { $0 is MPParallaxView }.first as? MPParallaxView)?.layer.zPosition = 100
        (view.subviews.filter { $0 is UISegmentedControl}.first)?.layer.zPosition = 50
        blurredPosterImageView?.layer.zPosition = 1
    }
    
}

extension UIViewController {
    
    func parallaxViewFrame() -> CGRect {
        return (view.subviews.filter { $0 is MPParallaxView }.first as? MPParallaxView)?.frame ?? CGRectZero
    }
    
    func interstellarAssets() -> [UIImageView] {
        let interstellarImages = [("1", 0), ("2", 10), ("3", 2), ("4", 4), ("5", 12)]
            .flatMap { nameAndOffset -> UIImageView in
                let imageView = UIImageView(image: UIImage(named: nameAndOffset.0))
                imageView.tag = nameAndOffset.1
                return imageView
        }
        interstellarImages.forEach { $0.frame = parallaxViewFrame() }
        return interstellarImages
    }
    
    func spectreAssets() -> [UIImageView] {
        let spectreImageViews = [("007", 30), ("lea", 4), ("james", 7), ("spectrelogo", 8)]
            .flatMap { nameAndOffset -> UIImageView in
                let imageView = UIImageView(image: UIImage(named: nameAndOffset.0))
                imageView.tag = nameAndOffset.1
                return imageView
        }
        spectreImageViews.forEach { $0.frame = parallaxViewFrame() }
        spectreImageViews.first?.frame = CGRectMake(parallaxViewFrame().origin.x, parallaxViewFrame().origin.y, parallaxViewFrame().size.width * 1.9, parallaxViewFrame().size.height)
        return spectreImageViews
    }
}

extension UIImage {

    class func imageFromAssets(asset: AssetsNames) -> UIImage? {
        return UIImage(named: asset.rawValue)
    }
}