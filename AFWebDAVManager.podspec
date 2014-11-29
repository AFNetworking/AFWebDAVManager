Pod::Spec.new do |s|
  s.name         = "AFWebDAVManager"
  s.version      = "0.0.1"
  s.summary      = "AFNetworking extension for WebDAV"
  s.homepage     = "https://github.com/AFNetworking/AFWebDAVManager"
  s.social_media_url = "https://twitter.com/AFNetworking"
  s.license      = 'MIT'
  s.author       = { "Mattt Thompson" => "m@mattt.me" }
  s.source       = { :git => "https://github.com/AFNetworking/AFWebDAVManager.git", :tag => "0.0.1" }

  s.source_files = 'AFWebDAVManager'
  s.requires_arc = true

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'

  s.dependency 'AFNetworking', '~> 2.4'
  s.dependency 'Ono', '~> 1.1'
end
