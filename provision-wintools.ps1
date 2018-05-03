# vagrant captures all stderr and terminates provisioning process if something shows up there regardless of the scrip exit code
# so we show everything on stdout, even errors, so vagrant proceeds to other provisioners even though some powershell commands may have failed here
# otherwise you might want to use [Console]::Error.WriteLine("
$ProgressPreference = 'SilentlyContinue' # helps with download speed for invoke-webrequest

$linkfolder="c:\bin"
. c:\vagrant\software-installer.ps1 # get the install function

$i=@()

# PowerPoint is no longer supported by Microsoft and may no longer be downlaodable. It may require system reboot before it is installed
# if it still fails to install - run the install manually to see the error. if the error relates to an ASP library try installing or *removing* .NET 3.5 - Get-WindowsFeature -name Net-Framework-Core
# https://answers.microsoft.com/en-us/windows/forum/all/unable-to-install-any-application-error/fb0ca806-ce16-486f-84fc-5c0d82102f5a 
$i+=@{
	name='Power Point viewer'
	program='C:\Program Files (x86)\Microsoft Office\Office14\PPTVIEW.EXE'
	installer='PowerPointViewer.exe'
	installcmd='.\PowerPointViewer.exe /quiet /passive'
	url='https://download.microsoft.com/download/E/6/7/E675FFFC-2A6D-4AB0-B3EB-27C9F8C8F696/PowerPointViewer.exe'
}
$i+=@{
	# https://www.google.com/intl/en/chrome/?standalone=1&platform=win64
	name='Chrome'
	program='C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
	link='c.bat'
	installer='ChromeStandaloneSetup64.exe'
	installcmd='.\ChromeStandaloneSetup64.exe /silent /install'
	url='https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7BC100A399-A153-5FBA-941A-C0C2F5B5159C%7D%26lang%3Den%26browser%3D3%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers%26ap%3Dx64-stable/chrome/install/ChromeStandaloneSetup64.exe'
	#https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7BE0DB5C84-67B2-A9D1-49C3-D019504B77AB%7D%26lang%3Den%26browser%3D4%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers%26ap%3Dx64-stable-statsdef_1%26installdataindex%3Ddefaultbrowser/chrome/
	#https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7BA024641A-81C0-533A-53CB-AE9534821219%7D%26lang%3Den%26browser%3D4%26usagestats3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dfalse%26installdataindex%3Ddefaultbrowser/update2/installers/ChromeStandaloneSetup.exe"
}
$i+=@{
	name='Far Manager'
	program='c:\Program Files\Far Manager\Far.exe'
	link='far.bat'
	installer='Far30b5100.x64.20171126.msi'
	installcmd='msiexec /q /i Far30b5100.x64.20171126.msi'
 	#installcmd='start -wait -filepath "c:\windows\system32\msiexec.exe" -argumentlist /i,"Far30b5100.x64.20171126.msi"'
	#installcmd='start -wait -filepath "msiexec" -argumentlist /i,"Far30b5100.x64.20171126.msi"'
	url='https://www.farmanager.com/files/Far30b5100.x64.20171126.msi'
}
$i+=@{
	name='Webex Extension'
	program='C:\Program Files (x86)\Google\Chrome\Application\Plugins\npatgpc.dll'
	installer='Cisco_WebEx_Add-On.exe'
	installcmd='.\Cisco_WebEx_Add-On.exe | out-null'
	url='https://join-test.webex.com/client/WBXclient-32.11.0-388/Cisco_WebEx_Add-On.exe?v=1.17.0.3066'
}
<# WebEx chrome plugin installs as a dev plugin, still requires a confirmation when chrome starts. 
$i+=@{
	name='Webex Plugin'
	program='C:\Users\vagrant\AppData\Local\Google\Chrome\User Data\Default\Extensions\jlhmfgmfgeifomenelglieieghnjghma\1.0.12_0\manifest.json'
	installer='Cisco-WebEx-Extension.crx'
	installcmd='& "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --load-extension=Cisco-WebEx-Extension.crx'
	url='http://www.cisco.com/c/dam/en/us/td/docs/collaboration/webex_centers/esp/Cisco-WebEx-Extension_crx.zip'
	unzip='Cisco-WebEx-Extension_crx.zip'
}
#>
$i+=@{
	name='Docker client'
	program="$linkfolder\docker.exe"
	installer='docker\docker.exe'
	installcmd="cp docker\docker.exe $linkfolder\"
	url='https://download.docker.com/win/static/edge/x86_64/docker-17.10.0-ce.zip'
	unzip='docker-17.10.0-ce.zip'
}
$i+=@{
	name='X11 server'
	program='C:\Program Files\VcXsrv\vcxsrv.exe' 
	installer='vcxsrv-64.1.19.6.0.installer.exe'
	installcmd='.\vcxsrv-64.1.19.6.0.installer.exe /S'
	url="https://cytranet.dl.sourceforge.net/project/vcxsrv/vcxsrv/1.19.6.0/vcxsrv-64.1.19.6.0.installer.exe"
}
<# 	# need mesa version on windows server core because it does not have opengl installed
$i+=@{
	name='X11 Mesa server'
	program='C:\Program Files (x86)\Xming\Xming.exe' 
	installer='Xming-mesa-6-9-0-31-setup.exe'  
	installcmd='.\Xming-mesa-6-9-0-31-setup.exe /verysilent /norestart'
	url='https://downloads.sourceforge.net/project/xming/Xming-mesa/6.9.0.31/Xming-mesa-6-9-0-31-setup.exe'
}
#>
$i+=@{
	name='ngrok port forwarder'
	program="$linkfolder\ngrok.exe" 
	installer='ngrok.exe' 
	installcmd="cp ngrok.exe $linkfolder\"
	url='https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-windows-amd64.zip'
	unzip='ngrok-stable-windows-amd64.zip'
}
$i+=@{
	name='CSV viewer'
	program='C:\Program Files\Tad\Tad.exe'
	installer='Tad.Setup.0.8.5.exe'
	installcmd='.\Tad.Setup.0.8.5.exe /S'
	url='https://github.com/antonycourtney/tad/releases/download/v0.8.5/Tad.Setup.0.8.5.exe'
}
#SkypeMeetingsApp.msi
#https://az801095.vo.msecnd.net/prod/LWA/plugins/windows/SkypeMeetingsApp.msi
# install with .\SkypeMeetingsApp.msi not by msiexec /i SkypeMeetingsApp.msi 

<# Excel viewer cant open CSV files
$i+=@{
	name='Excel viewer'
	program='C:\Program Files (x86)\Microsoft Office\Office12\XLVIEW.EXE'
	installer='ExcelViewer.exe'
	installcmd='.\ExcelViewer.exe /quiet /passive'
	#installprocess='ExcelViewer'
	url='https://download.microsoft.com/download/e/a/9/ea913c8b-51a7-41b7-8697-9f0d0a7274aa/ExcelViewer.exe'
	hash='e0a5a388255244f1f5eb2fbf46bdc7292f7e3d8e'
}
#>

DownloadInstallLink $i 'c:\vagrant' 'c:\bin'

if (!(Get-NetFirewallRule | where {$_.Name -eq "X11External"})) {
	Write-Host "Enabling X11 remote connections..."
	# open firewall 
	New-NetFirewallRule -Name "X11External" -DisplayName "X org server remote connection to TCP/6000 for display :0" -Protocol tcp -LocalPort 6000 -Action Allow -Enabled True | out-null
}
