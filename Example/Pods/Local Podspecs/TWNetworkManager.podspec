Pod::Spec.new do |s|
  s.name     = 'TWNetworkManager'
  s.version  = '1.0.0'
  s.license      = { :type => "MIT", :file => "LICENSE.md" }
  s.summary = 'Simple Objective C download and image cache manager'
  s.description  = 'TWNetworkManager is a simple wrapper for NSURLSession and NSCache in order to make the download and caching faster. Attention: This purpose is NOT to replace AFNetworking. TWNetworkManager is simple and provides enough for most use cases.'
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
