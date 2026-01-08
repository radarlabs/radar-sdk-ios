Pod::Spec.new do |s|
  s.name                  = 'RadarSDK'
  s.version               = '3.25.1'
  s.summary               = 'iOS SDK for Radar, the leading geofencing and location tracking platform'
  s.homepage              = 'https://radar.com'
  s.author                = { 'Radar Labs, Inc.' => 'support@radar.com' }
  s.platform              = :ios
  s.source                = { :git => 'https://github.com/radarlabs/radar-sdk-ios.git', :tag => s.version.to_s }
  s.source_files          = ["RadarSDK/*.{h,m,swift}", "RadarSDK/Internal/*.{h,m,swift}", "RadarSDK/Include/*.h"]
  s.module_name           = 'RadarSDK'
  s.ios.deployment_target = '12.0'
  s.frameworks            = 'CoreLocation'
  s.requires_arc          = true
  s.license               = { :type => 'Apache-2.0' }
  s.resource_bundles      = {'RadarSDK' => ['RadarSDK/PrivacyInfo.xcprivacy']}
  s.pod_target_xcconfig   = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version         = '6.0'
end
