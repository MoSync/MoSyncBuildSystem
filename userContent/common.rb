require 'fileutils'
include FileUtils::Verbose

# Define helpers.
def sh(cmd)
	puts cmd
	success = system(cmd)
	raise "Command failed" unless(success)
end

@ENV = {}

def env(name)
	e = ENV[name.to_s]
	#raise "Missing environment variable #{name}!" if(!e)
	self.class.const_set(name, e)
	@ENV[name.to_s] = e
end

Remote = Struct.new(:url, :branch)

# Define constants.
env(:WORKSPACE)
env(:BUILD_MODE)
env(:TIMESTAMP)
env(:NODE_LABELS)
env(:WORKSPACE_ROOT)
env(:CLEAN_WORKSPACE)
env(:BUILD_ID)
env(:BUILD_NUMBER)

if(CLEAN_WORKSPACE == 'true')
	# Save the .rb files
	cd WORKSPACE
	tempDir = WORKSPACE + '_temp'
	sh "rm -rf #{tempDir}"
	mkdir_p(tempDir)
	sh "cp *.rb #{tempDir}/"
	# Clean the workspace
	cd WORKSPACE_ROOT
	sh "rm -rf #{WORKSPACE}/*"
	# Restore the .rb files
	sh "cp #{tempDir}/* #{WORKSPACE}/"
	cd WORKSPACE
end

NodeLabels = NODE_LABELS.split(' ')

mkdir_p("#{WORKSPACE_ROOT}/repos")

def remoteMapFileName(jenkinsName)
	"#{WORKSPACE_ROOT}/repos/#{jenkinsName}_remoteMap.txt"
end

# line format: "remoteName url [branch]"
# generate unique remoteNames, like "r#{number}"
def readRemoteMap(jenkinsName)
	fn = remoteMapFileName(jenkinsName)
	remoteMap = {}
	return remoteMap, 'r1' if(!File.exist?(fn))

	number = 1
	file = open(fn, 'r')
	file.each do |line|
		p = line.split(' ')
		raise hell if(p.size < 2 || p.size > 3)
		name, url, branch = p
		remoteMap[Remote.new(url, branch)] = name
		if(name.start_with?('r'))
			i = name[1..-1].to_i
			number = i if(i > number)
		end
	end
	file.close

	nextName = "r#{number+1}"

	return remoteMap, nextName
end

def writeRemoteMap(nextName, remote, jenkinsName)
	# append
	file = open(remoteMapFileName(jenkinsName), 'a')
	file.puts "#{nextName} #{remote.url} #{remote.branch}"
	file.close
end

# Checkout source.
def checkout(jenkinsName, remoteUrl, branch, hash, localDir, lf)
	jenkins_repo = "#{WORKSPACE_ROOT}/repos/#{jenkinsName}"
	sh "git init --bare #{jenkins_repo}" if(!File.exist?(jenkins_repo))
	cd jenkins_repo

	remoteMap, nextName = readRemoteMap(jenkinsName)
	r = Remote.new(remoteUrl, branch)
	if(!remoteMap[r])
		sh "git remote add -t #{branch} #{nextName} \"#{remoteUrl}\""
		remoteMap[r] = nextName
		writeRemoteMap(nextName, r, jenkinsName)
	end

	rn = remoteMap[r]
	sh "git fetch #{rn}"
	if(!hash || hash.length == 0)
		rp = "git rev-parse #{rn}/#{branch}"
		sh rp	# make sure the command doesn't fail; open() doesn't do that.
		hash = open("|#{rp}").read.strip
	end
	cd WORKSPACE
	if(!File.exist?(localDir))
		sh "git clone -n -s \"#{jenkins_repo}\" #{localDir}"
		cd localDir
		if(lf)
			sh "git config core.eol lf"
			sh "git config core.safecrlf false"
			sh "git config core.autocrlf false"
		end
	else
		cd localDir
		sh "git reset --hard"
	end
	sh "git checkout #{hash}"
	cd '..'
	open("MoSync/bin/version_#{jenkinsName}.txt", 'w') do |file|
		file.puts hash
	end
	# return value is used by buildEclipse.rb
	return hash
end

# Copy src file to dest directory, if dest file is older than src.
def cp_u(src, dest)
	dstFile = dest + '/' + File.basename(src)
	if(uptodate?(dstFile, [src]))
		puts "#{dstFile} is up-to-date."
	else
		cp(src, dest)
	end
end

def prepareRuntimeBuild(zipName)
	rm_f(zipName)
	raise "Deletion of old file (#{zipName}) failed!" if(File.exist?(zipName))

	# Define constants.
	env(:MOSYNC_REPO)
	env(:MOSYNC_BRANCH)
	env(:MOSYNC_HASH)
	env(:BUILD_NUMBER)

	# Set up target directory.
	rm_rf('MoSync')
	mkdir_p('MoSync/bin')

	# Checkout code.
	checkout('MoSync', MOSYNC_REPO, MOSYNC_BRANCH, MOSYNC_HASH, 'MoSync-source', false)

	# Build MoSync base.
	cd 'MoSync-source'
	sh 'ruby workfile.rb base CONFIG='
end

def buildRuntimes(zipName, platforms)
	prepareRuntimeBuild(zipName)

	if(platforms.include?('wm'))
		cd 'intlibs/bluetooth'
		sh 'ruby workfile.rb CONFIG='
	end

	# Copy Settings.rb.
	cp("#{WORKSPACE_ROOT}/Settings.rb", "#{WORKSPACE}/MoSync-source/tools/RuntimeBuilder/Settings.rb")

	if(platforms.include?('s60'))
		sh "junction C:\\bd#{BUILD_NUMBER} #{WORKSPACE}\\MoSync-source"
		cd "C:/bd#{BUILD_NUMBER}/tools/ConcurrentBuild"
		sh "ruby ConcurrentBuild.rb #{WORKSPACE}/MoSync C:\\bd%BUILD_NUMBER% #{platforms}"
		sh "junction -d C:\\bd#{BUILD_NUMBER}"
	else
		# Build runtimes.
		cd "#{WORKSPACE}/MoSync-source/tools/ConcurrentBuild"
		sh "ruby ConcurrentBuild.rb #{WORKSPACE}/MoSync #{WORKSPACE}/MoSync-source #{platforms}"
	end

	# Pack results.
	cd WORKSPACE
	sh "zip -r9 #{zipName} MoSync/profiles"
end

# set up target directories
ENV['MOSYNCDIR'] = File.expand_path('MoSync')
