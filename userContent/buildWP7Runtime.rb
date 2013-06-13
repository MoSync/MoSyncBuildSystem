#!/usr/bin/ruby

require './common.rb'

prepareRuntimeBuild('WP7Runtime.zip')

# Build Blackberry 10 native.
cd "#{WORKSPACE}/MoSync-source"
sh 'cp \jenkins-files\local_config.rb rules'
sh 'ruby workfile.rb libs MODE=bb10'

cd "#{WORKSPACE}/MoSync-source/runtimes/cpp/platforms/bb10/MoSync"
# Clear config file. We need it to exist but be empty.
open('config.rb', 'w').close
sh 'ruby workfile.rb'

# Build Windows Phone 7
cd WORKSPACE
mkdir_p('MoSync/profiles/runtimes/winphone/1/template')
mkdir_p('MoSync/profiles/runtimes/winphone/1/mosyncExtensionTemplate')

cd "#{WORKSPACE}/MoSync-source/runtimes/csharp/windowsphone"

sh "ruby buildLibraries.rb"

sh "Xcopy /E /I /Y template #{WORKSPACE}\\MoSync\\profiles\\runtimes\\winphone\\1\\template\\"
sh "Xcopy /E /I /Y mosync\\mosyncExtensionTemplate #{WORKSPACE}\\MoSync\\profiles\\runtimes\\winphone\\1\\mosyncExtensionTemplate\\"

# Pack results.
cd WORKSPACE
sh "zip -r9 WP7Runtime.zip MoSync/profiles MoSync/lib"
