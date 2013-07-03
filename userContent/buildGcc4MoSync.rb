#!/usr/bin/ruby

require './common.rb'

rm_f('mosync.zip')

# Define constants.
env(:GCC_REPO)
env(:GCC_BRANCH)
env(:GCC_HASH)
env(:BINUTILS_REPO)
env(:BINUTILS_BRANCH)
env(:BINUTILS_HASH)
env(:MOSYNC_REPO)
env(:MOSYNC_BRANCH)
env(:MOSYNC_HASH)
env(:MSYS_BIN)

# dump test file
if(NodeLabels.include?('windows'))
	open('test.bat', 'w') do |file|
		file.puts '@ECHO OFF'
		file.puts
		@ENV.each do |key, val|
			file.puts "set #{key}=#{val}"
		end
		file.puts
		file.puts "ruby #{File.basename(__FILE__)}"
	end
end

# set up target directories
mkdir_p('MoSync/bin')
mkdir_p('MoSync/mapip2')
installdir = 'MoSync/libexec/gcc/mapip2/4.6.3'
mkdir_p("#{installdir}/ldscripts")
installdir = File.expand_path(installdir)

# checkout code
checkout('MoSync', MOSYNC_REPO, MOSYNC_BRANCH, MOSYNC_HASH, 'MoSync-source', false)
checkout('binutils', BINUTILS_REPO, BINUTILS_BRANCH, BINUTILS_HASH, 'binutils', true)
checkout('gcc', GCC_REPO, GCC_BRANCH, GCC_HASH, 'gcc', true)

# Build binutils.
cd 'MoSync-source'
sh 'ruby workfile.rb base CONFIG='
cd '../binutils'
# create config files
open('config.rb', 'w') do |file|
	file.puts "CONFIG_TARGET = 'mapip2'"
	file.puts "CONFIG_INSTALLDIR = \"#{installdir}\""
	file.puts "CONFIG_MOSYNC_SOURCE_DIR = \"#{File.expand_path('../MoSync-source')}\""
end
sh 'ruby workfile.rb CONFIG='

# Build GCC.
cd WORKSPACE+'/gcc'
if(File.exist?('build/release/Makefile') && File.exist?('build/release/config.status'))
	cmd = './make-all-gcc.sh'
else
	if(NodeLabels.include?('windows'))
		cmd = './configure-mingw-release.sh'
	elsif(NodeLabels.include?('mac106'))
		cmd = './configure-darwin-release.sh'
	elsif(NodeLabels.include?('linux'))
		cmd = './configure-linux-release.sh'
	else
		raise "Unsupported platform!"
	end
end
if(NodeLabels.include?('windows'))
	sh "set PATH=#{MSYS_BIN};%PATH% && bash #{cmd}"
	EXE = '.exe'
else
	sh cmd
	EXE = ''
end

# Install GCC.
cd WORKSPACE+'/gcc/build/release/gcc'
cp_u('xgcc'+EXE, WORKSPACE+'/MoSync/mapip2')
cp_u('cpp'+EXE, installdir)
cp_u('cc1'+EXE, installdir)
cp_u('cc1plus'+EXE, installdir)

# Copy examples and templates and whatever else might be needed by a non-source installation.
cd WORKSPACE
sh "ruby copyExtras.rb \"#{WORKSPACE}/MoSync-source\" \"#{WORKSPACE}/MoSync\""

# Build MoSync.
cd WORKSPACE+'/MoSync-source'
sh 'ruby workfile.rb all_libs'
sh 'ruby workfile.rb CONFIG='

cd WORKSPACE
if(NodeLabels.include?('mac106'))
	# Constants are visible in required files, but non-const variables are not.
	INSTALLDIR = installdir
	require './addGcc4MoSyncOsxStuff.rb'
end

# Pack results.
cd WORKSPACE
sh "zip -9 -r mosync.zip MoSync --exclude=MoSync/build/*"
