desc "Bootstraps the repo"
task :bootstrap do
  sh 'bundle'
  sh 'cd Example && bundle exec pod install'
end

desc "Runs the specs"
task :spec do
  sh 'xcodebuild -workspace Example/TWNetworkManagerExample.xcworkspace -scheme \'TWNetworkManagerExample\' test -sdk iphonesimulator | xcpretty -tc; exit ${PIPESTATUS[0]}'
end
