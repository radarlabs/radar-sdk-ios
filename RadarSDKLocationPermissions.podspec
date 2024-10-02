Pod::Spec.new do |s|
    s.name                  = 'RadarSDKLocationPermissions'
    s.version               = '3.18.1'
    s.summary               = 'Location permissions plugin for RadarSDK'
    s.homepage              = 'https://radar.com'
    s.author                = { 'Radar Labs, Inc.' => 'support@radar.com' }
    s.platform              = :ios
    s.source                = { :git => 'https://github.com/radarlabs/radar-sdk-ios.git', :tag => s.version.to_s }
    s.source_files          = ["RadarSDKLocationPermissions/RadarSDKLocationPermissions/*.{h,m}", "RadarSDKLocationPermissions/RadarSDKLocationPermissions/Include/*.h"]
    s.module_name           = 'RadarSDKLocationPermissions'
    s.ios.deployment_target = '10.0'
    s.frameworks            = 'CoreLocation'
    s.requires_arc          = true
    s.license               = { :type => 'Apache-2.0' } 
  end
  