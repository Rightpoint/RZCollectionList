PROJ_PATH="RZCollectionList-Demo/RZCollectionList-Demo.xcodeproj"
BUILD_SCHEME="RZCollectionList-Demo"

#
# Install
#
task :install do
  # don't care if this fails on travis
  sh("brew update") rescue nil
  sh("brew upgrade xctool") rescue nil
end

#
# Build
#

task :build do
  sh("xctool -project '#{PROJ_PATH}' -scheme '#{BUILD_SCHEME}' -sdk iphonesimulator build") rescue nil
  exit $?.exitstatus
end

#
# Test
#

task :test do
  sh("xctool -project '#{PROJ_PATH}' -scheme '#{BUILD_SCHEME}' -sdk iphonesimulator clean test -simulator iphone7.1 -freshInstall") rescue nil
  exit $?.exitstatus
end


#
# Analyze
#

task :analyze do
  sh("xctool -project '#{PROJ_PATH}' -scheme '#{BUILD_SCHEME}' -sdk iphonesimulator analyze -failOnWarnings") rescue nil
  exit $?.exitstatus
end

#
# Clean
#

task :clean do
  sh("xctool -project '#{PROJ_PATH}' -scheme '#{BUILD_SCHEME}' -sdk iphonesimulator clean") rescue nil
end

#
# Default
#

task :default => 'build'
