Pod::Spec.new do |s|
  s.name     = 'TWNetworkManager'
  s.version  = '1.4'
  s.license      = { :type => "MIT", :file => "LICENSE.md" }
  s.summary = 'Lightweight Objective-C network downloader with caching support based on NSURLSession'
  s.description  = 'TWNetworkManager is a wrapper for NSURLSession with some extras and convenience methods. The purpose is NOT to replace AFNetworking. I just wanted to have a simple NSURLSession wrapper with caching support that everyone else can adapt easily.'
  s.homepage = 'https://github.com/tapwork/TWNetworkManager'
  s.social_media_url = 'https://twitter.com/cmenschel'
  s.authors  = { 'Christian Menschel' => 'christian@tapwork.de' }
  s.source = {
    :git => 'https://github.com/tapwork/TWNetworkManager.git',
    :tag => s.version.to_s
  }
  s.ios.deployment_target = '7.0'
  s.source_files = 'Classes/**.{h,m}'
  s.requires_arc = true
end
