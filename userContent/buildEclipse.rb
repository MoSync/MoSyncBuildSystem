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
env(:BUILD_MODE)
env(:TIMESTAMP)


mkdir_p('MoSync/bin')
# checkout code
checkout('Eclipse', ECLIPSE_REPO, ECLIPSE_BRANCH, ECLIPSE_HASH, 'eclipse-source', false)
checkout('MoSync', MOSYNC_REPO, MOSYNC_BRANCH, MOSYNC_HASH, 'MoSync-source', false)

# copy the target platform file
cd WORKSPACE
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

if(BUILD_MODE != "re")
	@splash = "\"#{revisionText}\" #{TIMESTAMP.strip} #{MOSYNC_HASH.strip} #{ECLIPSE_HASH.strip}"
else
	@splash = "\"#{revisionText}\" #{TIMESTAMP.strip} "##{MOSYNC_HASH.strip} #{ECLIPSE_HASH.strip}"
end

File.open("MoSync/bin/version.dat", "w") do |file|
	file.puts revisionText
	file.puts TIMESTAMP
	puts "Date: #{TIMESTAMP}"
	file.puts MOSYNC_HASH
	puts "MoSync Hash: #{MOSYNC_HASH}"
	file.puts ECLIPSE_HASH
	puts "Eclipse Hash: #{ECLIPSE_HASH}"
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

FileUtils.mv Dir.glob("buildresult/I.MoSync/MoSync-*-trimmed.zip"), WORKSPACE
