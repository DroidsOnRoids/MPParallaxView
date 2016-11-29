Pod::Spec.new do |s|
    s.name             = "MPParallaxView"
    s.version          = "0.3.0"
    s.summary          = "Apple TV Parallax effect in Swift."
    s.description      = <<-DESC
    Show UIView with parallax effect from new Apple TV.
    DESC
    s.homepage         = "https://github.com/DroidsOnRoids/MPParallaxView"
    s.license          = { :type => "MIT", :file => "LICENSE" }
    s.author           = { "Michal Pyrka" => "michal.pyrka@droidsonroids.pl" }
    s.source           = { :git => "https://github.com/DroidsOnRoids/MPParallaxView.git", :tag => s.version.to_s }
    s.social_media_url = 'https://twitter.com/mike_p3'
    s.platform     = :ios, '9.0'
    s.source_files = 'MPParallaxView.swift'
    s.resource_bundles = { 'MPParallaxView' => ['Assets/gloweffect.png'] }
    s.frameworks = 'UIKit', 'CoreMotion'
end
