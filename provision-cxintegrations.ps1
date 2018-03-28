$ProgressPreference = 'SilentlyContinue' # helps with download speed for invoke-webrequest

$DOCKER_HOST_NAME='host'
$DOCKER_HOST_IP="192.168.50.1" # Linux Virtual Box and Docker host
$DISPLAY="192.168.50.5:0" # Windows guest (this VM)

$installfolder='c:\vagrant'
$linkfolder="C:\Users\vagrant\AppData\Local\Microsoft\WindowsApps"

cd $installfolder

$i=@()

$i+=@{
	name='Git client'
	program='C:\Program Files\Git\bin\git.exe'
	link='git.bat'
	linkcmd='"C:\Program Files\Git\bin\git.exe" %*'
	installer='Git-2.16.2-64-bit.exe'
	installcmd='.\Git-2.16.2-64-bit.exe /verysilent ; sqlcmd -Q "update [CxDB].[dbo].[CxComponentConfiguration] set value=''C:\Program Files\Git\bin\git.exe'' where id=176"'
	url='https://github.com/git-for-windows/git/releases/download/v2.16.2.windows.1/Git-2.16.2-64-bit.exe'
}
$i+=@{
	name='Jenkins'
	linkcmd="start ""Jenkins"" cmd.exe @cmd /k ""docker.exe run --name jenkins --rm -p 8081:8080 -v jenkins:/var/jenkins_home cxai/cxjenkins""
                 ping 127.0.0.1 -n 2 > nul
                 c.bat http://host:8081/"
	link='jenkins.bat'
}
$i+=@{
	name='Jira'
	linkcmd="start ""Jira"" cmd.exe @cmd /k ""docker.exe run --name jira --rm -p 8082:8080 -v jira:/var/atlassian/jira cxai/cxjira""
                 ping 127.0.0.1 -n 3 > nul
                 c.bat http://host:8082/"
	link='jira.bat'
}
$i+=@{
	name='IntelliJ'
	linkcmd="start ""XMing"" ""C:\Program Files\VcXsrv\vcxsrv.exe"" :0 -ac -clipboard -multiwindow -silent-dup-error
                 start ""IntelliJ"" cmd.exe @cmd /k ""docker run --name intellij --rm -it -e DISPLAY=$DISPLAY -v intellij:/root/ cxai/cxintellij"""
	link='ij.bat'
}
$i+=@{
	name='Checkmarx CLI'
	linkcmd="docker.exe run --name cli --rm cxai/cxcli"
	link='cxcli.bat'
}
$i+=@{
	name='MSSQL Operations Studio'
	linkcmd="start ""XMing"" ""C:\Program Files\VcXsrv\vcxsrv.exe"" :0 -ac -clipboard -multiwindow -silent-dup-error
                 start ""MSSQLOps"" cmd.exe @cmd /k ""docker run --name sqlops --rm -e DISPLAY=$DISPLAY -v sqlops:/root/ alexivkin/mssqlops"""
	link='sqlops.bat'
}
$i+=@{
	# download vs files
	# https://docs.microsoft.com/en-us/visualstudio/install/install-vs-inconsistent-quality-network
	name='Visual Studio Installer'
	program="$installfolder\vs2017layout\vs_community.exe"
	installer="vs_community.exe"
	# .NET web and .NET desktop development
	installcmd=".\vs_community.exe --layout $installfolder\vs2017layout --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --add Component.GitHub.VisualStudio --includeOptional --lang en-US"
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
$i+=@{
	name='Visual Studio Plugin'
	program="C:\USERS\VAGRANT\APPDATA\LOCAL\MICROSOFT\VISUALSTUDIO\15.0_*\EXTENSIONS\*\CxViewerVSIX.dll"
	#program="C:\PROGRAM FILES (X86)\MICROSOFT VISUAL STUDIO\2017\COMMUNITY\COMMON7\IDE\EXTENSIONS\5BDAFS24.OCD\CxViewerVSIX.dll" # plugin installed with the /admin option
	installer='CxViewerVSIX_8.50.1.vsix'
	installcmd="& ""C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\VSIXInstaller.exe"" /q $installfolder\CxViewerVSIX_8.50.1.vsix"
	url='https://download.checkmarx.com/8.5.0/Plugins/CxViewerVSIX_8.50.1.zip'
	unzip='CxViewerVSIX_8.50.1.zip'
}

# Download, install, link
foreach($e in $i) {
	if ($e.containsKey('installer') -and !(Test-Path "$installfolder\$($e.installer)") -and $e.containsKey('url')) {
		Write-Output "Downloading $($e.name)"
		if ($e.containsKey('unzip')) {
			try {
				Invoke-WebRequest $e.url -OutFile "$installfolder\$($e.unzip)" -UseBasicParsing  
				if ($e.containsKey('unzippwd')) {
					Expand-Archive $e.unzip -DestinationPath $installfolder
				} else {
					Expand-Archive $e.unzip -DestinationPath $installfolder -Password $e.unzippwd 
				}
				rm $e.unzip
			} catch {
				Write-Host ">>> Can not download and unzip $($e.name): $($_.Exception.Message)"
			}
		} else {
			try {
				Invoke-WebRequest $e.url -OutFile "$installfolder\$($e.installer)" -UseBasicParsing
			} catch {
				Write-Host ">>> Can not download $($e.name): $($_.Exception.Message)"
		       	}
		}
	}
	if ($e.containsKey('program') -and !(Test-Path $e.program) -and (Test-Path "$installfolder\$($e.installer)")) {
		Write-Output "Installing $($e.name)"
		Invoke-Expression $($e.installcmd) # out-host does not work on invoke-expression. to make it synchronous, i.e. wait for it to complete
		Start-Sleep -m 1000
		if ($e.installcmd -match "[^\\]*\.exe") { # monitor install by the short name
			Wait-Process $Matches[0].replace(".exe","") -erroraction 'silentlycontinue'
		}
		if (!(Test-Path $e.program)){
			Write-Host ">>> $($e.name) install may have failed. "
			#exit 1
		}
	}
	if ($e.ContainsKey('link') -and !(Test-Path "$linkfolder\$($e.link)")){
		Write-Output "Linking $($e.name) to $linkfolder\$($e.link)"
		if ($e.containsKey('linkcmd')) {
			Write-Output "@echo off`r`n$($e.linkcmd)" | out-file -encoding ascii "$linkfolder\$($e.link)" # all this extra quoting just to make commands with spaces work
		} else {
			Write-Output "@start ""$($e.name)"" ""$($e.program)"" %*" | out-file -encoding ascii "$linkfolder\$($e.link)" # all this extra quoting just to make commands with spaces work
		}
	}
}

if(!(Test-Connection -Cn $DOCKER_HOST_NAME -BufferSize 16 -Count 1 -ea 0 -quiet)){
	Write-Output "Adding $DOCKER_HOST_IP to hosts file as $DOCKER_HOST_NAME"
 	$DOCKER_HOST_IP + "`t`t" + $DOCKER_HOST_NAME | Out-File -encoding ASCII -append "$env:windir\System32\drivers\etc\hosts"
}

if (!(Test-Path env:DOCKER_HOST) -or ((Get-Item env:DOCKER_HOST).Value -ne "tcp://$DOCKER_HOST_NAME")){
	Write-Output "Setting DOCKER_HOST to tcp://$DOCKER_HOST_NAME"
	[Environment]::SetEnvironmentVariable("DOCKER_HOST", "tcp://$DOCKER_HOST_NAME", [EnvironmentVariableTarget]::Machine)
	$env:DOCKER_HOST='tcp://192.168.50.1' # for just this environment
}

if (get-content "C:\Program Files\Checkmarx\CheckmarxWebPortal\Web\web.config" | select-string 'EnableIssueTracking" value="false'){
	Write-Output "Enabling Jira integration"
	(Get-Content "C:\Program Files\Checkmarx\CheckmarxWebPortal\Web\web.config") -replace 'EnableIssueTracking" value="[^"]*','EnableIssueTracking" value="true' | out-file -encoding ascii "C:\Program Files\Checkmarx\CheckmarxWebPortal\Web\web.config"
	sqlcmd -Q "insert [CxDB].[dbo].[IssueTrackingSystems] values ('Jira docker container','JIRA','<?xml version=""1.0"" encoding=""utf-16""?><CxJIRATrackingSystem xmlns:xsd=""http://www.w3.org/2001/XMLSchema"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"">  <ServerURL>http://192.168.50.1:8082</ServerURL>  <Username>admin</Username>  <Password>028198209196130100040198045168245158099231166232</Password></CxJIRATrackingSystem>')"
	#Restart-Service W3SVC
}

