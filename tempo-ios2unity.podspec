Pod::Spec.new do |spec|
  spec.name             = 'tempo-ios2unity'
  spec.version          = '0.0.2'
  spec.swift_version    = '5.6'
  spec.author           = { 'Tempo Engineering' => 'development@tempoplatform.com' }
  spec.license          = { :type => 'MIT', :file => 'LICENSE.txt' }
  spec.homepage         = 'https://github.com/Tempo-Platform/tempo-ios2unity'
  spec.source           = { :git => 'https://github.com/Tempo-Platform/tempo-ios2unity.git', :tag => spec.version.to_s }
  spec.summary          = 'Tempo Branded Levels SDK to display in-game content'

  spec.ios.deployment_target = '11.0'

  spec.source_files  = 'tempo-ios2unity/**/*.{h,m,swift}'
  spec.resource_bundles = {
    'tempo-ios2unity' => ['tempo-ios2unity/Resources/**/*']
  }
  
  spec.pod_target_xcconfig = { 'PRODUCT_BUNDLE_IDENTIFIER' => 'com.tempoplatform.tempo-ios2unity' }
end
