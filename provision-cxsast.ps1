$ProgressPreference = 'SilentlyContinue' # helps with download speed for invoke-webrequest

$installfolder='c:\vagrant'
$linkfolder="C:\Users\vagrant\AppData\Local\Microsoft\WindowsApps"
$sa_password='admin' # MSSQL 'sa' password
$admin_password='hlTgLz69abv2jGHWAyj57N8MO3K4L8uBY93mEe0K3JE=' # 'admin' password for checkmarx 'admin@cx' user.
$admin_password_salt='nTwTPeNHlHdhcxk0IXapiQ=='

cd $installfolder

$i=@()
$i+=@{
	name='MSSQL 2017 Express Core Installer'
	program='temp\setup.exe'
	installer='SQLEXPR_x64_ENU.exe'
	installcmd='.\SQLEXPR_x64_ENU.exe /u /x:$installfolder\temp'
	url='https://download.microsoft.com/download/E/F/2/EF23C21D-7860-4F05-88CE-39AA114B014B'
	<# can also be installed in one go as:
 	sql_express_download_url "https://go.microsoft.com/fwlink/?linkid=829176"
 	Invoke-WebRequest -Uri $env:sql_express_download_url -OutFile sqlexpress.exe ; \
        Start-Process -Wait -FilePath .\sqlexpress.exe -ArgumentList /qs, /x:setup ; \
        .\setup\setup.exe /q /ACTION=Install /INSTANCENAME=SQLEXPRESS /FEATURES=SQLEngine /UPDATEENABLED=0 /SQLSVCACCOUNT='NT AUTHORITY\System' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS ; \
        Remove-Item -Recurse -Force sqlexpress.exe, setup
	#>
}
$i+=@{
	name='MSSQL 2017 Express Core'
	program='C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\Binn\sqlservr.exe'
	installer='temp\setup.exe'
	# there is a backtick in front of the $ to escape it in powershell. If you copy-paste that command directly remove the backtick
	installcmd='temp\setup.exe /Q /ACTION=INSTALL /FEATURES=SQLEngine /ROLE="AllFeatures_WithDefaults" /INSTANCENAME=SQLEXPRESS /SQLCOLLATION=SQL_Latin1_General_CP1_CI_AS /SQLSVCSTARTUPTYPE=Automatic /SQLSVCACCOUNT="NT Service\MSSQL`$SQLEXPRESS" /SQLSYSADMINACCOUNTS="BUILTIN\Administrators" "NT AUTHORITY\NETWORK SERVICE" /ADDCURRENTUSERASSQLADMIN="True" /IAcceptSQLServerLicenseTerms="True" /SkipRules=RebootRequiredCheck /BROWSERSVCSTARTUPTYPE="Automatic" /UpdateEnabled="False" /TCPENABLED="1"'
}
$i+=@{
	name='CxSAST'
	program='C:\Program Files\Checkmarx\Checkmarx Engine Server\Engine Server\CxEngineAgent.exe'
	installer='CxSetup.exe'
	installcmd=".\CxSetup.exe /install /quiet MSSQLEXP=0" # MSSQLEXP=1 SQLAUTH=1 SQLUSER=sa SQLPWD=$sa_password SQLSERVER=localhost\SQLEXPRESS"
}

# Download, install, link
foreach($e in $i) {
	if ($e.containsKey('installer') -and !(Test-Path "$installfolder\$($e.installer)") -and $e.containsKey('url')) {
		if ($e.containsKey('unzip')) {
			if (!(Test-Path "$installfolder\$($e.unzip)")) {
				try {
					Write-Output "Downloading $($e.name)"
					Invoke-WebRequest $e.url -OutFile "$installfolder\$($e.unzip)" -UseBasicParsing
				} catch {
					Write-Host "!!! Can not download $($e.name): $($_.Exception.Message)"
					exit 1
				}
			}
			try {
				Write-Output "Unzipping $($e.name)"
				Expand-Archive $e.unzip -DestinationPath $installfolder
			} catch {
				Write-Host "!!! Can not unzip $($e.name): $($_.Exception.Message)"
				if (Test-Path "$installfolder\$($e.installer)"){
					rm "$installfolder\$($e.installer)"
				}
				exit 1
			}
			rm $e.unzip
		} else {
			try {
				Write-Output "Downloading $($e.name)"
				Invoke-WebRequest $e.url -OutFile "$installfolder\$($e.installer)" -UseBasicParsing
			} catch {
				Write-Host "!!! Can not download $($e.name): $($_.Exception.Message)"
				exit 1
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

# disable MSSQL telemetry

$val = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Microsoft SQL Server\140\" -Name "CustomerFeedback"
if($val.CustomerFeedback -ne 0) {
	Write-Host "Disabling MSSQL telemetry..."
	Set-ItemProperty -Path "HKLM:\Software\Microsoft\Microsoft SQL Server\140\" -Name "CustomerFeedback" -Type DWord -Value 0
	Set-ItemProperty -Path "HKLM:\Software\Microsoft\Microsoft SQL Server\140\" -Name "EnableErrorReporting" -Type DWord -Value 0
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL14.SQLEXPRESS\CPE" -Name "CustomerFeedback" -Type DWord -Value 0
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL14.SQLEXPRESS\CPE" -Name "EnableErrorReporting" -Type DWord -Value 0
	Set-ItemProperty -Path "HKLM:\Software\Wow6432Node\Microsoft\Microsoft SQL Server\140\" -Name "CustomerFeedback" -Type DWord -Value 0
	Set-ItemProperty -Path "HKLM:\Software\Wow6432Node\Microsoft\Microsoft SQL Server\140\" -Name "EnableErrorReporting" -Type DWord -Value 0
}

if (!(Get-NetFirewallRule | where {$_.Name -eq "MSSQLExternal"})) {
	Write-Host "Enabling MSSQL remote connections..."
	# open firewall
	New-NetFirewallRule -Name "MSSQLExternal" -DisplayName "MS SQL Server allow remote connection to TCP/1433" -Protocol tcp -LocalPort 1433 -Action Allow -Enabled True | out-null
	New-NetFirewallRule -Name "MSSQLExternalBrowse" -DisplayName "MS SQL Server allow remote discovery of TCP/1433" -Protocol udp -LocalPort 1434 -Action Allow -Enabled True | out-null
	# enable remote port 1433 connection (which is not specified even though the server is installed with TCP enabled)
	Get-CimInstance -Namespace root/Microsoft/SqlServer/ComputerManagement14 -ClassName ServerNetworkProtocolProperty -Filter "InstanceName='SQLEXPRESS' and ProtocolName = 'Tcp' and IPAddressName='IPAll'" | ? { $_.PropertyName -eq 'TcpPort' } | Invoke-CimMethod -Name SetStringValue -Arguments @{ StrValue = '1433' } | out-null

	<# MS does it slightly differently:
	stop-service MSSQL`$SQLEXPRESS
        set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql14.SQLEXPRESS\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpdynamicports -value '' ; \
        set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql14.SQLEXPRESS\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpport -value 1433 ; \
        #>

	# enable SQL auth
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQLServer" -Name "LoginMode" -Type DWord -Value 2
	Restart-Service 'MSSQL$SQLEXPRESS'
	# create sa user
	& "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\SQLCMD.EXE" -Q "ALTER LOGIN sa WITH CHECK_POLICY = OFF; alter login sa with password='$sa_password' unlock; alter login sa enable;"
}


# Check for license and it's correctness
if (!(Test-Path "license.cxl")) {
  # first generate the HID, we'll need it later
  $hidall=(& "c:\Program Files\Checkmarx\HID\HID.exe") | out-string
  Write-Host "Please provide a license.cxl file for the following HID: $hidall" -ForegroundColor red
} elseif (!(Test-Path("c:\program files\Checkmarx\Licenses\license.cxl"))) {
  # check if the provided license is correct by searching for the trimmed HID inside cxl. cxl needs to be converted from utf32 to utf8
  $hidall=(& "c:\Program Files\Checkmarx\HID\HID.exe") | out-string
  $hid=(Select-String -inputObject $hidall -Pattern "#([^_]*)").Matches.Groups[1].Value
  if (!((Get-content -Path "license.cxl") -match $hid)){
	Write-Host "license.cxl does not match the HID for this container: $hidall" -ForegroundColor red
	exit 1
  } else {
	Write-Host "Deploying the license..." -ForegroundColor green
	copy license.cxl "c:\program files\Checkmarx\Licenses\license.cxl"
	Restart-Service CxScanEngine
	Restart-Service CxJobsManager
	Restart-Service CxScansManager
	Restart-Service CxSystemManager
  }
}

if (!(Test-Path("C:\Users\vagrant\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"))){
	Write-Output "Copying bookmarks"
	# start chrome so it has a chance to create the user profile
	#& "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
	#Start-Sleep -m 5000
	#taskkill /IM chrome.exe
	cp "$installfolder\Bookmarks" "C:\Users\vagrant\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
}

if (!(Test-Path("C:\Program Files\Checkmarx\Checkmarx Audit\CxAudit.exe"))){
	Write-Output "Creating a shortcut for CxAudit"
	Write-Output "@start ""CxAudit"" ""C:\Program Files\Checkmarx\Checkmarx Audit\CxAudit.exe""" | out-file -encoding ascii "$linkfolder\a.bat"
}

# set Checkmarx admin password
Write-Output "Setting admin password"
& "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\SQLCMD.EXE" -Q "UPDATE [CxDB].[dbo].Users SET Password = '$admin_password', SaltForPassword = '$admin_password_salt', IsAdviseChangePassword = 0 WHERE username='admin@cx'"

<#
& "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\SQLCMD.EXE" -Q "
set IDENTITY_INSERT [CxDB].[dbo].Users on;
insert [CxDB].[dbo].Users ([Id],[UserName],[Password],[DateCreated],[BusinessUnitID],[FirstName],[LastName],[Email],[ValidationKey],[IsAdmin],[IsActive],[IsBusinessUnitAdmin],[JobTitle],[Phone],[Company],[ExpirationDate],[Country],[FullPath],[UPN],[TeamId],[is_deprecated],[CellPhone],[Skype],[Language],[IsAdviseChangePassword],[SaltForPassword],[LastLoginDate],[FailedLogins],[FailedLoginDate],[Role])
values (2,'admin@cx','$admin_password','2018-03-19',-1,'admin','admin','admin@cx.com','',0,1,0,'','','','2113-03-03',NULL,'admin','admin@cx@Cx','00000000-0000-0000-0000-000000000000',0,NULL,NULL,'1033',0,'$admin_password_salt',NULL,0,NULL,17);
set IDENTITY_INSERT [CxDB].[dbo].Users off;
"
#>
