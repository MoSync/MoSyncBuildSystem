#!/usr/bin/ruby

require './common.rb'
require 'fileutils'

# Define constants.
env(:ECLIPSE_REPO)
env(:ECLIPSE_BRANCH)
env(:ECLIPSE_HASH)
env(:ECLIPSE_VERSION)
env(:MOSYNC_REPO)
env(:MOSYNC_BRANCH)
env(:MOSYNC_HASH)

mkdir_p('MoSync/bin')
# checkout code
eHash = checkout('Eclipse', ECLIPSE_REPO, ECLIPSE_BRANCH, ECLIPSE_HASH, 'eclipse-source', false)
mHash = checkout('MoSync', MOSYNC_REPO, MOSYNC_BRANCH, MOSYNC_HASH, 'MoSync-source', false)

# copy the target platform file
cd WORKSPACE
mkdir_p('eclipse-source/com.mobilesorcery.sdk.product/build')
cp_u("../target-platform-#{ECLIPSE_VERSION}.zip", 'eclipse-source/com.mobilesorcery.sdk.product/build/target-platform.zip')

# prepare the install and start-up splash screen
majorMinorRevision = "MoSync-source/tools/ReleasePackageBuild/major_minor_revision.txt"
# read major and minor version information
if(File.exist?(majorMinorRevision))
	puts "major_minor_revision.txt exists"
	versionInfo = []
	File.open(majorMinorRevision, "r") do |infile|
		while (line = infile.gets)
			versionInfo.push(line)
		end
	end
end

versionSuffix = (versionInfo[2] == nil) ? "":versionInfo[2].strip
revisionText = case BUILD_MODE
when "nightly"
	"Nightly Build"
when "sandbox", "macpack", "winpack", "re"
	"Developer Snapshot"
when "featured"
	"Version #{versionInfo[0].strip}.#{versionInfo[1].strip} #{versionSuffix}"
else
	"Developer\'s Snapshot"
end

timestamp = TIMESTAMP
if(!timestamp)
	timestamp = "#{BUILD_ID}-#{BUILD_NUMBER}"
end
# Can't use strip! on frozen strings.
timestamp = timestamp.strip

if(BUILD_MODE != "re")
	@splash = "\"#{revisionText}\" #{timestamp} #{mHash} #{eHash}"
else
	@splash = "\"#{revisionText}\" #{timestamp} "##{MOSYNC_HASH.strip} #{ECLIPSE_HASH.strip}"
end

File.open("MoSync/bin/version.dat", "w") do |file|
	file.puts revisionText
	file.puts timestamp
	puts "Date: #{timestamp}"
	file.puts mHash
	puts "MoSync Hash: #{mHash}"
	file.puts eHash
	puts "Eclipse Hash: #{eHash}"
end

puts "Splash:"
puts @splash

cd "MoSync-source/tools/SplashScreenGenerator"
sh "ruby main.rb " + @splash
cp_u("splash.bmp", WORKSPACE + "/eclipse-source/com.mobilesorcery.sdk.product/")
cp_u("installer_splash.bmp", WORKSPACE + "/installer_splash.bmp")

# build eclipse
cd WORKSPACE + '/eclipse-source/com.mobilesorcery.sdk.product/build'
sh "ant release"

# Store results for archiving.
FileUtils.mv Dir.glob("buildresult/I.MoSync/MoSync-*-trimmed.zip"), WORKSPACE

cd WORKSPACE
FileUtils.mv "MoSync/bin/version.dat", WORKSPACE
