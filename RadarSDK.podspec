Pod::Spec.new do |s|
  s.name                  = 'RadarSDK'
  s.version               = '3.0.9-alpha'
  s.summary               = 'iOS SDK for Radar, location data infrastructure'
  s.homepage              = 'https://radar.io'
  s.author                = { 'Radar Labs, Inc.' => 'support@radar.io' }
  s.platform              = :ios
  s.source                = { :git => 'https://github.com/radarlabs/radar-sdk-ios.git', :tag => s.version.to_s }
  s.source_files          = 'dist/RadarSDK.framework/Versions/A/Headers/*.h'
  s.public_header_files   = 'dist/RadarSDK.framework/Versions/A/Headers/*.h'
  s.vendored_frameworks   = 'dist/RadarSDK.framework'
  s.module_name           = 'RadarSDK'
  s.ios.deployment_target = '10.0'
  s.frameworks            = 'CoreLocation'
  s.requires_arc          = true
  s.license               = { :type => 'Apache-2.0' }
end
