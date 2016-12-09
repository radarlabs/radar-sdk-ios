Pod::Spec.new do |s|
  s.name                  = 'RadarSDK'
  s.version               = '1.1.4'
  s.summary               = 'iOS SDK for Radar, a full-stack developer toolkit for location context and tracking'
  s.homepage              = 'https://www.onradar.com'
  s.social_media_url      = 'https://twitter.com/radarlabs'
  s.author                = { 'Radar Labs, Inc.' => 'support@onradar.com' }
  s.platform              = :ios
  s.source                = { :git => 'https://github.com/RadarLabs/RadarSDK-iOS.git', :tag => '1.1.4' }
  s.source_files          = 'RadarSDK/RadarSDK.framework/Versions/A/Headers/*.h'
  s.vendored_frameworks   = 'RadarSDK/RadarSDK.framework'
  s.module_name           = 'RadarSDK'
  s.ios.deployment_target = '8.0'
  s.frameworks            = 'CoreLocation'
  s.requires_arc          = true
  s.xcconfig              = { 'LIBRARY_SEARCH_PATHS' => '"$(PODS_ROOT)/RadarSDK"',
                              'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/Headers/RadarSDK"' }
  s.license               = { :type => 'Copyright',
                              :text => 'Copyright (c) 2016 Radar Labs, Inc. All rights reserved.' }
end