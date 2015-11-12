//
//  ViewController.swift
//  MPParallaxView
//
//  Created by Michal Pyrka on 11/08/2015.
//  Copyright (c) 2015 Michal Pyrka. All rights reserved.
//

import UIKit
import MPParallaxView

class ViewController: UIViewController {

    @IBAction func segmentedControlChanged(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            setupInterstellar()
        } else {
            setupSpectre()
        }
    }
    
    func setupInterstellar() {
        view.backgroundColor = UIColor(red: 198.0/255.0, green: 215.0/255.0, blue: 224.0/255.0, alpha: 1.0)
        let parallaxView = view.subviews.filter { $0 is MPParallaxView }.first as?MPParallaxView
        if let parallaxView = parallaxView {
            parallaxView.subviews.forEach { $0.removeFromSuperview() }
            interstellarAssets().forEach { parallaxView.addSubview($0) }
            parallaxView.prepareParallaxLook()
        }
    }
    
    func setupSpectre() {
        view.backgroundColor = UIColor(red: 250.0/255.0, green: 250.0/255.0, blue: 250.0/255.0, alpha: 1.0)
        let parallaxView = view.subviews.filter { $0 is MPParallaxView }.first as?MPParallaxView
        if let parallaxView = parallaxView {
            parallaxView.subviews.forEach { $0.removeFromSuperview() }
            parallaxView.contentView.subviews.forEach { $0.removeFromSuperview() }
            let assets: [UIImageView] = spectreAssets()
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

