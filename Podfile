project 'AppExplorer/AppExplorer.xcodeproj'

# Xcode 27 refuses to build anything with a deployment target below macOS 12.
platform :osx, '12.0'

target 'SoqlXplorer' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SoqlXplorer
  pod 'Sparkle', '~> 1.22'
  pod 'ZKSforce', '~> 58.0.0'
  pod 'ZKParser', '~> 0.8'
end

target 'SoqlXplorerTests' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SoqlXplorer
  pod 'ZKSforce', '~> 58.0.0'
  pod 'ZKParser', '~> 0.8'
  # pod 'ZKSforce', :path => '~/Github/zkSforce/'
end

# The pods declare deployment targets as old as 10.9 (Sparkle), which current
# Xcode treats as an error. Raise them all to match the app.
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
