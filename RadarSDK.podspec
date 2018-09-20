Pod::Spec.new do |s|
  s.name                  = 'RadarSDK'
  s.version               = '2.0.5'
  s.summary               = 'iOS SDK for Radar, the location platform for mobile apps'
  s.homepage              = 'https://radar.io'
  s.social_media_url      = 'https://twitter.com/radarlabs'
  s.author                = { 'Radar Labs, Inc.' => 'support@radar.io' }
  s.platform              = :ios
  s.source                = { :git => 'https://github.com/radarlabs/radar-sdk-ios.git', :tag => s.version.to_s }
  s.source_files          = 'RadarSDK/RadarSDK.framework/Versions/A/Headers/*.h'
  s.vendored_frameworks   = 'RadarSDK/RadarSDK.framework'
  s.module_name           = 'RadarSDK'
  s.ios.deployment_target = '9.0'
  s.frameworks            = 'CoreLocation'
  s.requires_arc          = true
  s.license               = { :type => 'Copyright',
                              :text => 'Copyright (c) 2018 Radar Labs, Inc. All rights reserved.' }
end
