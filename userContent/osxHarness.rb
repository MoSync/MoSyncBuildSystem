require 'fileutils'
include FileUtils::Verbose

WORKSPACE = pwd
INSTALLDIR = File.expand_path('MoSync/libexec/gcc/mapip2/4.6.3')

# Copy src file to dest directory, if dest file is older than src.
def cp_u(src, dest)
	dstFile = dest + '/' + File.basename(src)
	if(uptodate?(dstFile, [src]))
		puts "#{dstFile} is up-to-date."
	else
		cp(src, dest)
	end
end

def sh(cmd)
	puts cmd
	success = system(cmd)
	raise "Command failed" unless(success)
end

require './addGcc4MoSyncOsxStuff.rb'
