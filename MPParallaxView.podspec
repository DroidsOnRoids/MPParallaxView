#
# Be sure to run `pod lib lint MPParallaxView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = "MPParallaxView"
    s.version          = "0.1.1"
    s.summary          = "Apple TV Parallax effect in Swift."
    s.description      = <<-DESC
    Show UIView with parallax effect from new Apple TV.
    DESC
    s.homepage         = "https://github.com/DroidsOnRoids/MPParallaxView"
    s.license          = 'MIT'
    s.author           = { "Michal Pyrka" => "michal.pyrka@droidsonroids.pl" }
    s.source           = { :git => "https://github.com/DroidsOnRoids/MPParallaxView.git", :tag => s.version.to_s }
    s.social_media_url = 'https://twitter.com/mike_p3'
    s.platform     = :ios, '9.0'
    s.requires_arc = true
    s.source_files = 'Pod/Classes/MPParallaxView.swift'
    s.resource_bundles = {
    'MPParallaxView' => ['Pod/Assets/gloweffect.png']
    }
    s.frameworks = 'UIKit'
end
