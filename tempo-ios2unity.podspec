#
# Run `pod lib lint tempo-ios2unity' to validate the spec after any changes
#
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |spec|
  spec.name             = 'tempo-ios2unity'
  spec.version          = '0.0.1'
  spec.swift_version    = '5.6.1'
  spec.author           = { 'Tempo Engineering' => 'development@tempoplatform.com' }
  spec.license          = { :type => 'MIT', :file => 'LICENSE' }
  spec.homepage         = 'https://github.com/Tempo-Platform/tempo-ios2unity'
  #spec.readme           = 'https://github.com/Tempo-Platform/tempo-ios2unity/blob/main/README.md'
  spec.source           = { :git => 'https://github.com/Tempo-Platform/tempo-ios2unity.git', :tag => spec.version.to_s }
  spec.summary          = 'Tempo Branded Levels SDK to display in-game content'

  spec.ios.deployment_target = '11.0'

  spec.source_files  = 'tempo-ios2unity/**/*.{h,m,swift}'
  spec.resource_bundles = {
      'tempo-ios2unity' => ['tempo-ios2unity/Resources/**/*']
    }
  
  spec.tvos.pod_target_xcconfig  = { 'EXCLUDED_ARCHS[sdk=appletvsimulator*]' => 'arm64', }
  spec.tvos.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=appletvsimulator*]' => 'arm64' }
  spec.pod_target_xcconfig       = { 'PRODUCT_BUNDLE_IDENTIFIER': 'com.tempoplatform.tempo-ios2unity' }
end
