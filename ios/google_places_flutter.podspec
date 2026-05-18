#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint google_places_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'google_places_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Flutter bridge to Google Places SDK on Android and iOS.'
  s.description      = <<-DESC
Wraps the official Google Places SDK for Android and Google Places SDK for iOS
(autocomplete search and place details).
                       DESC
  s.homepage         = 'https://github.com/satpal002/google_places_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Satpal Yadav' => 'satpal002@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'GooglePlaces', '~> 8.5'
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
