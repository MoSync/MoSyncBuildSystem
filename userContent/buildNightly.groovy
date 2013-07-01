import hudson.*
import hudson.model.*
import jenkins.*
import jenkins.model.*

def build = Thread.currentThread().executable;

def newFile(String dir) {
	return new File(build.getWorkspace().toString() + '/' + dir);
}

def exec(String cmd, String dir) {
	def f = newFile(dir);
	out.println "${f}: ${cmd}";
	def p = cmd.execute(null, f);
	p.waitForProcessOutput(out, out);
	int res = p.exitValue();
	if(res == 0)
		return;
	out.println "Command failed: ${res}";
	exit(res);
}

class Repo {
	String name, url, branch, hash;

	Repo(String n, String u, String b) {
		name = n;
		url = u;
		branch = b;
	}
}

repos = [
	new Repo('MOSYNC', 'git://github.com/fredrikeldh/MoSync.git', 'gcc4-bb10'),
	new Repo('BINUTILS', 'git://github.com/fredrikeldh/binutils-mapip2.git', 'mosync'),
	new Repo('GCC', 'git://github.com/fredrikeldh/gcc4-mapip2.git', 'float'),
	new Repo('ECLIPSE', 'git://github.com/fredrikeldh/Eclipse.git', 'master'),
]

def buildHash = '';
for(r in repos) {
	def cmd = "git ls-remote ${r.url} ${r.branch}";
	out.println cmd;
	r.hash = cmd.execute().text.find(~/\w*/);
	out.println r.hash;

	buildHash += r.hash;
}

def lastBuildHashFile = build.getWorkspace().child("lastBuildHash");

if(lastBuildHashFile.exists())
{
	def lastBuildHash = lastBuildHashFile.readToString();
	if(lastBuildHash == buildHash)
	{
		out.println "Hashes are the same, no need to build.";
		build.result = Result.NOT_BUILT;
		return 0;
	}
}

def buildParams = [
	new StringParameterValue('BUILD_MODE', 'nightly'),
	new StringParameterValue('Clean workspace', 'true'),
	new StringParameterValue('Build eclipse', 'true'),
	new StringParameterValue('Skip long builds', 'false'),
];

for(r in repos) {
	buildParams += [
		new StringParameterValue(r.name+'_REPO', r.url),
		new StringParameterValue(r.name+'_BRANCH', r.branch),
		new StringParameterValue(r.name+'_HASH', r.hash),
	]
}

def SDKJob = Hudson.instance.getJob('Meta_Build_GCC4_MoSync_SDK');
def future = SDKJob.scheduleBuild2(0, new Cause.UpstreamCause(build), new ParametersAction(buildParams));
out.println "Waiting for the completion of ${SDKJob.displayName}";
def SDKBuild = future.get();

if(SDKBuild.result == Result.SUCCESS)
{
	out.println "MoSync SDK build ${SDKBuild.getAbsoluteUrl()} was successful";
	lastBuildHashFile.write(buildHash,'ASCII');

	// If nightlyPostBuildStep.rb exists, run it, with the paths of all the artifacts as parameters.

	if(newFile('nightlyPostBuildStep.rb').exists())
	{
		String cmd = 'ruby nightlyPostBuildStep.rb';
		def artifacts = SDKBuild.getArtifacts();
		for(a in artifacts) {
			def path = a.getFile().getPath();
			cmd += ' ' + path;
		}
		exec(cmd, '.');
	}
}
else
{
	out.println "MoSync SDK build ${SDKBuild.getAbsoluteUrl()} failed";
	build.result = Result.FAILURE;
	return 1;
}
