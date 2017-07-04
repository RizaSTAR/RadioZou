# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end

# 「設定」にライセンス表記をコピーする
  require 'fileutils'
  
  #Pods-acknowledgements.plistを移動する
  FileUtils.cp_r('Pods/Target Support Files/Pods-RadioZou/Pods-RadioZou-Acknowledgements.plist', 'RadioZou/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end


target 'RadioZou' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for RadioZou
  pod 'RealmSwift'
  
  pod 'Material', '~> 2.0'
  
  pod 'AFNetworking', '~> 2.0'
  
  pod 'SwiftyJSON'
  
  pod 'SVProgressHUD'

  pod 'WSCoachMarksView', '~> 0.2'
  
  pod 'DZNEmptyDataSet'
  
  target 'RadioZouTests' do
    inherit! :search_paths
    # Pods for testing
	pod 'RealmSwift'
  end

  target 'RadioZouUITests' do
    inherit! :search_paths
    # Pods for testing
  end
  

end
