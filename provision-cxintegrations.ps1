$ProgressPreference = 'SilentlyContinue' # helps with download speed for invoke-webrequest

$DOCKER_HOST_NAME='host'
$DOCKER_HOST_IP="192.168.50.1" # Linux Virtual Box and Docker host
$THIS_VM="192.168.50.5" # Windows guest (this VM)
$sharedfolder='/home/alex/Shared Folder' # name of the folder on the docker host that will be mapped into the containers. It's best if it matches the shared folder from vagrantfile 

. c:\vagrant\software-installer.ps1 # get the install function

$i=@()

$i+=@{
	name='Git client'
	program='C:\Program Files\Git\bin\git.exe'
	link='git.bat'
	linkcmd='"C:\Program Files\Git\bin\git.exe" %*'
	installer='Git-2.16.2-64-bit.exe'
	installcmd='.\Git-2.16.2-64-bit.exe /verysilent ; sqlcmd -Q "update [CxDB].[dbo].[CxComponentConfiguration] set value=''C:\Program Files\Git\bin\git.exe'' where [Key] like ''GIT_EXE_PATH''" '
	url='https://github.com/git-for-windows/git/releases/download/v2.16.2.windows.1/Git-2.16.2-64-bit.exe'
}
$i+=@{
	name='Jenkins'
	linkcmd="start ""Jenkins"" cmd.exe @cmd /k ""docker.exe run --name jenkins --rm -p 8081:8080 -v jenkins:/var/jenkins_home --add-host cxserver:$THIS_VM cxai/cxjenkins""
                 ping 127.0.0.1 -n 2 > nul
                 c.bat http://host:8081/"
	link='jenkins.bat'
}
$i+=@{
	name='Jira'
	linkcmd="start ""Jira"" cmd.exe @cmd /k ""docker.exe run --name jira --rm -p 8082:8080 -v jira:/var/atlassian/jira --add-host cxserver:$THIS_VM cxai/cxjira""
                 ping 127.0.0.1 -n 3 > nul
                 c.bat http://host:8082/"
	link='jira.bat'
}
$i+=@{
	name='IntelliJ'
	linkcmd="start ""X11"" ""C:\Program Files\VcXsrv\vcxsrv.exe"" :0 -ac -clipboard -multiwindow -silent-dup-error
                 start ""IntelliJ"" cmd.exe @cmd /k ""docker run --name intellij --rm -it -e DISPLAY=${THIS_VM}:0 -v intellij:/root/ --add-host cxserver:$THIS_VM cxai/cxintellij"""
	link='ij.bat'
}
$i+=@{
	name='Eclipse'
	linkcmd="start ""X11"" ""C:\Program Files\VcXsrv\vcxsrv.exe"" :0 -ac -clipboard -multiwindow -silent-dup-error
                 start ""Eclipse"" cmd.exe @cmd /k ""docker run --name eclipse --rm -it -e DISPLAY=${THIS_VM}:0 -v eclipse:/home/developer/ --add-host cxserver:$THIS_VM cxai/cxeclipse"""
	link='e.bat'
}
$i+=@{
	name='TeamCity'
	linkcmd="start ""TeamCity"" cmd.exe @cmd /k ""docker.exe run --name teamcity --rm -p 8111:8111 -v teamcity:/data/teamcity_server/datadir --add-host cxserver:$THIS_VM cxai/cxteamcity""
                 ping 127.0.0.1 -n 3 > nul
                 c.bat http://host:8111/"
	link='tc.bat'
}
$i+=@{
	name='Checkmarx CLI'
	linkcmd="docker.exe run --name cli --rm --mount src=""$sharedfolder"",dst=/code/,type=bind cxai/cxcli %*"
	link='cxcli.bat'
}
$i+=@{
	name='MSSQL Operations Studio'
	linkcmd="start ""X11"" ""C:\Program Files\VcXsrv\vcxsrv.exe"" :0 -ac -clipboard -multiwindow -silent-dup-error
                 start ""MSSQLOps"" cmd.exe @cmd /k ""docker run --name sqlops --rm -e DISPLAY=${THIS_VM}:0 -v sqlops:/root/ alexivkin/mssqlops"""
	link='sqlops.bat'
}
$i+=@{
	# download vs files
	# https://docs.microsoft.com/en-us/visualstudio/install/install-vs-inconsistent-quality-network
	name='Visual Studio Installer'
	program=".\vs2017layout\vs_community.exe"
	installer="vs_community.exe"
	# .NET web and .NET desktop development
	installcmd=".\vs_community.exe --layout ,\vs2017layout --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --add Component.GitHub.VisualStudio --includeOptional --lang en-US"
	# C++ desktop development
	#installcmd='.\vs_community.exe --layout c:\vs2017layout --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended --lang en-US'
	url='https://aka.ms/vs/15/release/vs_community.exe'
}
$i+=@{
	name='Visual Studio'
	program="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\devenv.exe"
	link='vs.bat'
	installer='.\vs2017layout\vs_community.exe'
	installcmd=".\vs2017layout\vs_community.exe --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --add Component.GitHub.VisualStudio --includeOptional  --quiet --wait"
	# system needs to be rebooted after the VS install - use  --norestart to stop`
}
# may need a reboot before the plugin can be installed
$i+=@{
	name='Visual Studio Plugin'
	program="C:\USERS\VAGRANT\APPDATA\LOCAL\MICROSOFT\VISUALSTUDIO\15.0_*\EXTENSIONS\*\CxViewerVSIX.dll"
	#program="C:\PROGRAM FILES (X86)\MICROSOFT VISUAL STUDIO\2017\COMMUNITY\COMMON7\IDE\EXTENSIONS\5BDAFS24.OCD\CxViewerVSIX.dll" # plugin installed with the /admin option
	installer='CxViewerVSIX_8.50.1.vsix'
	installcmd="& ""C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\VSIXInstaller.exe"" /q .\CxViewerVSIX_8.50.1.vsix"
	url='https://download.checkmarx.com/8.5.0/Plugins/CxViewerVSIX_8.50.1.zip'
	unzip='CxViewerVSIX_8.50.1.zip'
}

DownloadInstallLink $i 'c:\vagrant' 'c:\bin'

if(!(Test-Connection -Cn $DOCKER_HOST_NAME -BufferSize 16 -Count 1 -ea 0 -quiet)){
	Write-Output "Adding $DOCKER_HOST_IP to hosts file as $DOCKER_HOST_NAME"
 	$DOCKER_HOST_IP + "`t`t" + $DOCKER_HOST_NAME | Out-File -encoding ASCII -append "$env:windir\System32\drivers\etc\hosts"
}

if (!(Test-Path env:DOCKER_HOST) -or ((Get-Item env:DOCKER_HOST).Value -ne "tcp://$DOCKER_HOST_NAME")){
	Write-Output "Setting DOCKER_HOST to tcp://$DOCKER_HOST_NAME"
	[Environment]::SetEnvironmentVariable("DOCKER_HOST", "tcp://$DOCKER_HOST_NAME", [EnvironmentVariableTarget]::Machine)
	$env:DOCKER_HOST="tcp://$DOCKER_HOST_NAME" # for just this environment
}

if (get-content "C:\Program Files\Checkmarx\CheckmarxWebPortal\Web\web.config" | select-string 'EnableIssueTracking" value="false'){
	Write-Output "Enabling Jira integration"
	(Get-Content "C:\Program Files\Checkmarx\CheckmarxWebPortal\Web\web.config") -replace 'EnableIssueTracking" value="[^"]*','EnableIssueTracking" value="true' | out-file -encoding ascii "C:\Program Files\Checkmarx\CheckmarxWebPortal\Web\web.config"
	# & "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\SQLCMD.EXE" -Q 
	# gotta love these doublequote doublequote escapes
	sqlcmd -Q "insert [CxDB].[dbo].[IssueTrackingSystems] values ('Jira docker container','JIRA','<?xml version=""""1.0"""" encoding=""""utf-16""""?><CxJIRATrackingSystem xmlns:xsd=""""http://www.w3.org/2001/XMLSchema"""" xmlns:xsi=""""http://www.w3.org/2001/XMLSchema-instance"""">  <ServerURL>http://host:8082</ServerURL>  <Username>admin</Username>  <Password>028198209196130100040198045168245158099231166232</Password></CxJIRATrackingSystem>')"
	#Restart-Service W3SVC
}
