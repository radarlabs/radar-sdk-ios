Pod::Spec.new do |s|
  s.name                  = 'RadarSDK'
  s.version               = '3.2.0-beta.1'
  s.summary               = 'iOS SDK for Radar, the leading geofencing and location tracking platform'
  s.homepage              = 'https://radar.io'
  s.author                = { 'Radar Labs, Inc.' => 'support@radar.io' }
  s.platform              = :ios
  s.source                = { :git => 'https://github.com/radarlabs/radar-sdk-ios.git', :tag => s.version.to_s }
  s.vendored_frameworks   = 'dist/RadarSDK.xcframework'
  s.module_name           = 'RadarSDK'
  s.ios.deployment_target = '10.0'
  s.frameworks            = 'CoreLocation'
  s.requires_arc          = true
  s.license               = { :type => 'Apache-2.0' }
end
