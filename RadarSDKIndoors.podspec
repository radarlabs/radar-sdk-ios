Pod::Spec.new do |s|
  s.name                  = 'RadarSDKIndoors'
  s.version               = '3.22.0-beta.1'
  s.summary               = 'Indoor positioning plugin for RadarSDK, the leading geofencing and location tracking platform'
  s.homepage              = 'https://radar.com'
  s.author                = { 'Radar Labs, Inc.' => 'support@radar.com' }
  s.platform              = :ios
  s.source                = { :git => 'https://github.com/radarlabs/radar-sdk-ios.git', :tag => s.version.to_s, :submodules => true }
  s.source_files          = ["RadarSDKIndoors/RadarSDKIndoors/*.{h,m}", "RadarSDKIndoors/RadarSDKIndoors/Include/*.h"]
  s.module_name           = 'RadarSDKIndoors'
  s.ios.deployment_target = '12.0'
  s.frameworks            = 'CoreBluetooth', 'CoreMotion', 'CoreLocation'
  s.requires_arc          = true
  s.license               = { :type => 'Apache-2.0' }
end