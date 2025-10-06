#!/bin/sh

if [ $# -lt 1 ]; then
  echo "Usage: $0 <version_string>"
  exit 1
fi

# sed has slightly different syntax on linux vs mac
if [ $(uname -s) = "Darwin" ]; then
    alias sed_inplace="sed -E -i ''"
else
    alias sed_inplace="sed -E -i"
fi

version_full=$1
version="${version_full%%-*}"

sed_inplace "s/s.version( +)= '(.+)'/s.version\1= '$version_full'/" RadarSDK.podspec
sed_inplace "s/s.version( +)= '(.+)'/s.version\1= '$version_full'/" RadarSDKMotion.podspec
sed_inplace "s/s.version( +)= '(.+)'/s.version\1= '$version_full'/" RadarSDKIndoors.podspec

sed_inplace "s/let version = \"(.+)\"/let version = \"$version_full\"/" Package.swift

sed_inplace "s/MARKETING_VERSION = .+;/MARKETING_VERSION = $version;/" RadarSDK.xcodeproj/project.pbxproj
sed_inplace "s/MARKETING_VERSION = .+;/MARKETING_VERSION = $version;/" RadarSDKMotion/RadarSDKMotion.xcodeproj/project.pbxproj
sed_inplace "s/MARKETING_VERSION = .+;/MARKETING_VERSION = $version;/" RadarSDKIndoors/RadarSDKIndoors.xcodeproj/project.pbxproj

sed_inplace "s/return @\"[0-9]+\.[0-9]+\.[0-9]+\"; \/\/ SDK VERSION/return @\"$version_full\"; \/\/ SDK VERSION/" RadarSDK/RadarUtils.m
sed_inplace "s/public static let sdkVersion: String = .*\"/public static let sdkVersion: String = \"$version_full\"/" RadarSDK/RadarUtils.swift
