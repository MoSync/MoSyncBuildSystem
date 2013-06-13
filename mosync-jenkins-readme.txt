12:50 2013-06-13
Required plugins:
Copy Artifact Plugin
Copy To Slave Plugin
Groovy Plugin
Ruby Plugin
Workspace Cleanup Plugin
Git Plugin
Parameterized Trigger Plugin
ZenTimestamp Plugin

13:34 2013-06-13
Failure to install these plugins results in this message:
	"You have data stored in an older format and/or unreadable data."
If you see it, make sure the plugins are installed, then restart Jenkins.

DO NOT "Discard Unreadable Data".
Doing so would break the jobs.
