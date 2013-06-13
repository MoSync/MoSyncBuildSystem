require "#{WORKSPACE}/MoSync-source/rules/dynlibconv.rb"

MOSYNCDIR = WORKSPACE+'/MoSync'

# Find all required dynlibs.
EXECUTABLES = Dir.glob("#{INSTALLDIR}/*") + Dir.glob("#{MOSYNCDIR}/bin/**/*")
dlls = {}
EXECUTABLES.each do |e|
	paths = DynLibConv.run_otool(e)
	paths.each do |path|
		if(path.start_with?('/opt/local/lib') && !path.end_with?(':'))
			if(!dlls[path])
				puts "New dll: #{path}"
				dlls[path] = true
			end
		end
	end
end

newOnes = dlls
while(newOnes.size != 0)
	nn = {}
	newOnes.each do |path,dummy|
		paths = DynLibConv.run_otool(path)
		paths.each do |path|
			if(path.start_with?('/opt/local/lib') && !path.end_with?(':'))
				if(!dlls[path])
					puts "New dll: #{path}"
					dlls[path] = true
					nn[path] = true
				end
			end
		end
	end
	newOnes = nn
end

dlls.each do |path,dummy|
	cp_u(path, "#{MOSYNCDIR}/bin/")
end

# Copy them to bin.

# Make sure all dynlibs are writable.
sh "chmod -R +w #{MOSYNCDIR}/bin/*"

# Convert library paths in dynlibs and executables, so they'll work on other machines that don't have '/opt/local/lib'.

list = Dir.glob("#{MOSYNCDIR}/bin/**/*")

DynLibConv.run("/sw/lib", "@loader_path", list)
DynLibConv.run("/opt/local/lib", "@loader_path", list)

# GCC and binutils
DynLibConv.run("/opt/local/lib", "@loader_path/../../../../bin", Dir.glob("#{INSTALLDIR}/*"))
DynLibConv.run("/opt/local/lib", "@loader_path/../bin", Dir.glob("#{MOSYNCDIR}/mapip2/*"))

# MoRE / dgles
DynLibConv.run("#{WORKSPACE}/MoSync-source/build/release_4.2.1", "@loader_path", ["#{MOSYNCDIR}/bin/MoRE"])
