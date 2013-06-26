#!/usr/bin/ruby

require './common.rb'

prepareRuntimeBuild('iOSRuntime.zip')

cd "#{WORKSPACE}/MoSync-source/intlibs/bluetooth"
sh 'ruby workfile.rb CONFIG='

cd WORKSPACE
mkdir_p('MoSync/profiles/runtimes/iphoneos/1/template')

cd "#{WORKSPACE}/MoSync-source/libs"
sh "ruby prepareMAStdNative.rb || echo \"no prepareMAStdNative.rb script\""

cd "#{WORKSPACE}/MoSync-source/runtimes/cpp/platforms/iphone"
cp('Classes/impl/config_platform.h.example', 'Classes/impl/config_platform.h')
sh 'ruby buildLibraries.rb'

# Pack results.
cd WORKSPACE
sh "zip -r9 iOSRuntime.zip MoSync/profiles"
