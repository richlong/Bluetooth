# Uncomment this line to define a global platform for your project
# platform :ios, '8.0'
# Uncomment this line if you're using Swift
use_frameworks!

target 'BluetoothTest' do

pod 'FLEX', '~> 2.0'

end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
    # Configure Pod targets for Xcode 8 compatibility
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
