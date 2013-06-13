#!/usr/bin/ruby

# usage: copyExtras.rb <MoSync-source> <MoSyncDir>

if(ARGV.size != 2)
	raise 'usage: copyExtras.rb <MoSync-source> <MoSyncDir>'
end

MoSyncSourceDir = ARGV[0]
MoSyncDir = ARGV[1]

require 'fileutils'
require "#{MoSyncSourceDir}/rules/task.rb"
require "#{MoSyncSourceDir}/examples/parse_example_list.rb"

include FileUtils::Verbose

# templates
cd MoSyncSourceDir
CopyDirWork.new(MoSyncDir, 'templates').invoke

# examples
cd "#{MoSyncSourceDir}/examples"
list = parseExampleList
list.each do |subdir|
	CopyDirWork.new("#{MoSyncDir}/examples", subdir).invoke
end
CopyDirWork.new("#{MoSyncDir}", 'examples', "#{MoSyncSourceDir}/examples", false).invoke

# DLL files
def cft(dst, src)
	CopyFileTask.new(nil, dst, FileTask.new(nil, src)).invoke
end

def copyBin(name, srcDir)
	cft("#{MoSyncDir}/bin/#{name}", "#{srcDir}#{name}")
end

if(HOST == :win32)
	[
		'libstdc++-6.dll',
		'libgcc_s_dw2-1.dll',
		'libz-1.dll',
		'libintl-8.dll',
		'libmpc-2.dll',
		'libmpfr-1.dll',
		'libgmp-10.dll',
	].each do |name|
		copyBin(name, '/mingw/bin/')
	end
end

if(HOST == :darwin)
	[
		#'libintl.8.dylib',
		'libmpc.3.dylib',
		'libmpfr.4.dylib',
		'libgmp.10.dylib',
	].each do |name|
		copyBin(name, '/opt/local/lib/')
	end
end

if(HOST == :linux)
	# Android tools
	require "#{ENV['WORKSPACE_ROOT']}/Settings.rb"
	DirTask.new(nil, "#{MoSyncDir}/bin/android").invoke
	sdk = $SETTINGS[:android_sdk]
	bin = "#{MoSyncSourceDir}/tools/ReleasePackageBuild/build_package_tools/mosync_bin/android"
	[
		"#{sdk}/platform-tools/aapt",
		"#{sdk}/platform-tools/adb",
		"#{sdk}/tools/zipalign",
		"#{bin}/apkbuilder.jar",
		"#{bin}/tools-stripped.jar",
	].each do |src|
		cft("#{MoSyncDir}/bin/android/#{File.basename(src)}", src)
	end
	cft("#{MoSyncDir}/bin/android/android-17.jar", "#{sdk}/platforms/android-17/android.jar")

	# compile dx
	cd "#{MoSyncSourceDir}/tools/android/dx"
	sh 'ruby build.rb'
	mv('dx.jar', "#{MoSyncDir}/bin/android/dx.jar")
end
