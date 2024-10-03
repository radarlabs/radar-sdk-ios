Pod::Spec.new do |s|
    s.name                  = 'RadarSDKLocationPermission'
    s.version               = '3.19.0-beta.1'
    s.summary               = 'Location permissions plugin for RadarSDK'
    s.homepage              = 'https://radar.com'
    s.author                = { 'Radar Labs, Inc.' => 'support@radar.com' }
    s.platform              = :ios
    s.source                = { :git => 'https://github.com/radarlabs/radar-sdk-ios.git', :tag => s.version.to_s }
    s.source_files          = ["RadarSDKLocationPermission/RadarSDKLocationPermission/*.{h,m}", "RadarSDKLocationPermission/RadarSDKLocationPermission/Include/*.h"]
    s.module_name           = 'RadarSDKLocationPermission'
    s.ios.deployment_target = '10.0'
    s.frameworks            = 'CoreLocation'
    s.requires_arc          = true
    s.license               = { :type => 'Apache-2.0' } 
  end
  