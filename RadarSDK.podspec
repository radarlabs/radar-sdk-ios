Pod::Spec.new do |s|
  s.name                  = 'RadarSDK'
  s.version               = '3.2.0-alpha.1'
  s.summary               = 'iOS SDK for Radar, the leading geofencing and location tracking platform'
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
  s.pod_target_xcconfig   = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig  = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end
