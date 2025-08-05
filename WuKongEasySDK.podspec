Pod::Spec.new do |spec|
  spec.name         = "WuKongEasySDK"
  spec.version      = "1.0.0"
  spec.summary      = "A lightweight iOS SDK for WuKongIM real-time messaging"
  spec.description  = <<-DESC
                      WuKongIM iOS EasySDK is a lightweight iOS SDK that allows you to add real-time chat functionality to iOS applications in 5 minutes. 
                      
                      Features:
                      - Easy integration with just a few lines of code
                      - Real-time messaging with WebSocket
                      - Automatic reconnection with exponential backoff
                      - Thread-safe event handling
                      - Memory-safe event listeners
                      - Comprehensive error handling
                      - Support for iOS 12.0+
                      - Swift Package Manager and CocoaPods support
                      DESC

  spec.homepage     = "https://github.com/WuKongIM/WuKongEasySDK-iOS"
  spec.license      = { :type => "Apache-2.0", :file => "LICENSE" }
  spec.author       = { "WuKongIM" => "support@wukongim.com" }
  
  spec.ios.deployment_target = "12.0"
  spec.osx.deployment_target = "10.15"
  spec.tvos.deployment_target = "13.0"
  spec.watchos.deployment_target = "6.0"
  
  spec.swift_version = "5.7"
  
  spec.source       = { :git => "https://github.com/WuKongIM/WuKongEasySDK-iOS.git", :tag => "#{spec.version}" }
  
  spec.source_files = "Sources/WuKongEasySDK/**/*.swift"
  
  spec.frameworks = "Foundation", "Network"
  
  spec.requires_arc = true
  
  # Documentation
  spec.documentation_url = "https://docs.wukongim.com"
  
  # Metadata
  spec.social_media_url = "https://twitter.com/wukongim"
  
  # Dependencies
  # No external dependencies - pure Swift implementation
  
  # Test spec
  spec.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/WuKongEasySDKTests/**/*.swift'
    test_spec.frameworks = 'XCTest'
  end
end
