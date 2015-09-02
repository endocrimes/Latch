Pod::Spec.new do |s|
  s.name               = "Latch"
  s.version            = "1.0.0"
  s.summary            = "A simple Swift Keychain Wrapper for iOS"
  s.homepage           = "https://github.com/endocrimes/Latch"
  s.license            = "MIT"
  s.author             = { "Danielle Lancashire" => "Dan@Tomlinson.io" }
  s.social_media_url   = "http://twitter.com/endocrimes"
  s.platform           = :ios, "8.0"
  s.source             = { :git => "#{s.homepage}.git", :tag => s.version }
  s.source_files       = "Classes", "Latch/*.{h,swift}"
  s.framework          = "Security"
end
