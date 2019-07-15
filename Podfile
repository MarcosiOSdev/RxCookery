# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'RxCookery' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for RxCookery
  pod 'RxSwift', '4.0.0'
  pod 'RxCocoa', '4.0.0'

  # Books need
  pod 'Action'
  pod "RxGesture"
  pod "RxRealm"




  target 'RxCookeryTests' do
    inherit! :search_paths
    pod 'RxBlocking'
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    #if ['RxCookery','RxSwift', 'RxSwiftExt', 'RxCocoa', 'RxDataSources', 'ProtocolBuffers-Swift'].include? target.name
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.0'
     # end
    end
  end
end
