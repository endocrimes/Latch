Pod::Spec.new do |s|
  s.name               = "Latch"
  s.version            = "1.0.0"
  s.summary            = "A simple Swift Keychain Wrapper for iOS"
  s.homepage           = "https://github.com/DanielTomlinson/Latch"
  s.license            = "MIT"
  s.author             = { "Daniel Tomlinson" => "Dan@Tomlinson.io" }
  s.social_media_url   = "http://twitter.com/dantoml"
  s.platform           = :ios
  s.source             = { :git => "#{s.homepage}.git", :tag => s.version }
  s.source_files       = "Classes", "Latch/*.{h,swift}"
  s.framework          = "Security"
end
