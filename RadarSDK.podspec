Pod::Spec.new do |s|
  s.name                  = 'RadarSDK'
  s.version               = '3.13.5'
  s.summary               = 'iOS SDK for Radar, the leading geofencing and location tracking platform'
  s.homepage              = 'https://radar.com'
  s.author                = { 'Radar Labs, Inc.' => 'support@radar.com' }
  s.platform              = :ios
  s.source                = { :git => 'https://github.com/radarlabs/radar-sdk-ios.git', :tag => s.version.to_s }
  s.source_files          = ["RadarSDK/*.{h,m}", "RadarSDK/Internal/*.{h,m}", "RadarSDK/Include/*.h"]
  s.module_name           = 'RadarSDK'
  s.ios.deployment_target = '10.0'
  s.frameworks            = 'CoreLocation'
  s.requires_arc          = true
  s.license               = { :type => 'Apache-2.0' }
  s.resource_bundles      = {'RadarSDK' => ['RadarSDK/PrivacyInfo.xcprivacy']}
  s.script_phase = {
    :name => 'Check NSLocationAlwaysAndWhenInUseUsageDescription in Info.plist',
    :script => %q{
      info_plist="$SRCROOT/Waypoint/$INFOPLIST_FILE"
      # if ! /usr/libexec/PlistBuddy -c "Print :NSLocationAlwaysAndWhenInUseUsageDescription" "$info_plist" &>/dev/null; then
      #  echo "NSLocationAlwaysAndWhenInUseUsageDescription not found in Info.plist, setting a dummy value."
      /usr/libexec/PlistBuddy -c "Add :NSLocationAlwaysAndWhenInUseUsageDescription string PlaceholderString" "$info_plist"
      #else
        # echo "NSLocationAlwaysAndWhenInUseUsageDescription exists in Info.plist."
      #fi
    },
    :execution_position => :before_compile
  }
end
