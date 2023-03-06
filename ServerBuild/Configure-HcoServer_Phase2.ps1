<#
Updated for Hybrid Cloud Observability installer and Windows Server 2022
Phase 2
#>
$ProgramsDrive = "E:\"
$WebDrive      = "F:\"
$LogDrive      = "G:\"


if ( -not ( Get-Command -Name "Get-WebSite" -ErrorAction SilentlyContinue ) ) {
	Import-Module -Name WebAdministration -WarningAction SilentlyContinue
}

Get-WebSite -Name "Default Web Site" | Remove-WebSite -Confirm:$false
# Older .NET Versions
Remove-WebAppPool -Name ".NET v2.0" -Confirm:$false -ErrorAction SilentlyContinue # Old .NET
Remove-WebAppPool -Name ".NET v2.0 Classic" -Confirm:$false -ErrorAction SilentlyContinue # Old .NET
Remove-WebAppPool -Name "Classic .NET AppPool" -Confirm:$false -ErrorAction SilentlyContinue # Old .NET
# Current Versions for Server 2022
Remove-WebAppPool -Name ".NET v4.5" -Confirm:$false -ErrorAction SilentlyContinue 
Remove-WebAppPool -Name ".NET v4.5 Classic" -Confirm:$false -ErrorAction SilentlyContinue
Remove-WebAppPool -Name "DefaultAppPool" -Confirm:$false -ErrorAction SilentlyContinue

# XML Object that will be used for processing
$ConfigFile = New-Object -TypeName System.Xml.XmlDocument
 
# Change the Application Host settings
$ConfigFilePath = "C:\Windows\System32\inetsrv\config\applicationHost.config"
 
# Load the Configuration File
$ConfigFile.Load($ConfigFilePath)
# Save a backup if one doesn't already exist
if ( -not ( Test-Path -Path "$ConfigFilePath.orig" -ErrorAction SilentlyContinue ) )
{
    Write-Host "Making Backup of $ConfigFilePath with '.orig' extension added" -ForegroundColor Yellow
    $ConfigFile.Save("$ConfigFilePath.orig")
}
# change the settings (create if missing, update if existing)
$ConfigFile.configuration.'system.applicationHost'.log.centralBinaryLogFile.SetAttribute("directory", [string]( Join-Path -Path $LogDrive -ChildPath "inetpub\logs\LogFiles" ) )
$ConfigFile.configuration.'system.applicationHost'.log.centralW3CLogFile.SetAttribute("directory", [string]( Join-Path -Path $LogDrive -ChildPath "inetpub\logs\LogFiles" ) )
$ConfigFile.configuration.'system.applicationHost'.sites.siteDefaults.logfile.SetAttribute("directory", [string]( Join-Path -Path $LogDrive -ChildPath "inetpub\logs\LogFiles" ) )
$ConfigFile.configuration.'system.applicationHost'.sites.siteDefaults.logfile.SetAttribute("logFormat", "W3C" )
$ConfigFile.configuration.'system.applicationHost'.sites.siteDefaults.logfile.SetAttribute("logExtFileFlags", "Date, Time, ClientIP, UserName, SiteName, ComputerName, ServerIP, Method, UriStem, UriQuery, HttpStatus, Win32Status, BytesSent, BytesRecv, TimeTaken, ServerPort, UserAgent, Cookie, Referer, ProtocolVersion, Host, HttpSubStatus" )
$ConfigFile.configuration.'system.applicationHost'.sites.siteDefaults.logfile.SetAttribute("period", "Hourly")
$ConfigFile.configuration.'system.applicationHost'.sites.siteDefaults.traceFailedRequestsLogging.SetAttribute("directory", [string]( Join-Path -Path $LogDrive -ChildPath "inetpub\logs\FailedReqLogFiles" ) )
$ConfigFile.configuration.'system.webServer'.httpCompression.SetAttribute("directory", [string]( Join-Path -Path $WebDrive -ChildPath "inetpub\temp\IIS Temporary Compressed Files" ) )
$ConfigFile.configuration.'system.webServer'.httpCompression.SetAttribute("maxDiskSpaceUsage", "2048" )
$ConfigFile.configuration.'system.webServer'.httpCompression.SetAttribute("minFileSizeForComp", "5120" )
# Save the file
$ConfigFile.Save($ConfigFilePath)
Remove-Variable -Name ConfigFile -ErrorAction SilentlyContinue


# XML Object that will be used for processing
$ConfigFile = New-Object -TypeName System.Xml.XmlDocument
 
# Change the Compilation settings in teh ASP.NET Web Config
$ConfigFilePath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\Config\web.config"
Write-Host "Editing [$ConfigFilePath]" -ForegroundColor Yellow
# Load the Configuration File
$ConfigFile.Load($ConfigFilePath)
# Save a backup if one doesn't already exist
if ( -not ( Test-Path -Path "$ConfigFilePath.orig" -ErrorAction SilentlyContinue ) )
{
    Write-Host "Making Backup of $ConfigFilePath with '.orig' extension added" -ForegroundColor Yellow
    $ConfigFile.Save("$ConfigFilePath.orig")
}
# change the settings (create if missing, update if existing)
$ConfigFile.configuration.'system.web'.compilation.SetAttribute("tempDirectory", [string]( Join-Path -Path $WebDrive -ChildPath "inetpub\temp") )
$ConfigFile.configuration.'system.web'.compilation.SetAttribute("maxConcurrentCompilations", "16")
$ConfigFile.configuration.'system.web'.compilation.SetAttribute("optimizeCompilations", "true")
Write-Host "Saving [$ConfigFilePath]" -ForegroundColor Yellow
$ConfigFile.Save($ConfigFilePath)
# Save the file
$ConfigFile.Save($ConfigFilePath)
Remove-Variable -Name ConfigFile -ErrorAction SilentlyContinue


$Redirections = @()
$Redirections += New-Object -TypeName PSObject -Property ( [ordered]@{ Order = [int]1; SourcePath = "C:\ProgramData\SolarWinds"; TargetDrive = $ProgramsDrive } )
$Redirections += New-Object -TypeName PSObject -Property ( [ordered]@{ Order = [int]2; SourcePath = "C:\ProgramData\SolarWindsAgentInstall"; TargetDrive = $ProgramsDrive } )
$Redirections += New-Object -TypeName PSObject -Property ( [ordered]@{ Order = [int]3; SourcePath = "C:\Program Files\SolarWinds"; TargetDrive = $ProgramsDrive } )
$Redirections += New-Object -TypeName PSObject -Property ( [ordered]@{ Order = [int]4; SourcePath = "C:\Program Files\Common Files\SolarWinds"; TargetDrive = $ProgramsDrive } )
$Redirections += New-Object -TypeName PSObject -Property ( [ordered]@{ Order = [int]5; SourcePath = "C:\Program Files (x86)\SolarWinds"; TargetDrive = $ProgramsDrive } )
$Redirections += New-Object -TypeName PSObject -Property ( [ordered]@{ Order = [int]6; SourcePath = "C:\Program Files (x86)\Common Files\SolarWinds"; TargetDrive = $ProgramsDrive } )
$Redirections += New-Object -TypeName PSObject -Property ( [ordered]@{ Order = [int]7; SourcePath = "C:\ProgramData\SolarWinds\Logs"; TargetDrive = $LogDrive } )
$Redirections += New-Object -TypeName PSObject -Property ( [ordered]@{ Order = [int]8; SourcePath = "C:\Program Files\SolarWinds\Orion\Web"; TargetDrive = $WebDrive } )
$Redirections | Add-Member -MemberType ScriptProperty -Name TargetPath -Value { $this.SourcePath.Replace("C:\", $this.TargetDrive ) } -Force
  
ForEach ( $Redirection in $Redirections | Sort-Object -Property Order )
{
    # Check to see if the target path exists - if not, create the target path
    if ( -not ( Test-Path -Path $Redirection.TargetPath -ErrorAction SilentlyContinue ) )
    {
        Write-Host "Creating Path for Redirection [$( $Redirection.TargetPath )]" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $Redirection.TargetPath | Out-Null
    }
    # Execute it
    Write-Host "Creating Junction point from $( $Redirection.SourcePath ) --> $( $Redirection.TargetPath ) " -NoNewline
    New-Item -ItemType Junction -Path $Redirection.SourcePath -Value $Redirection.TargetPath | Out-Null
    Write-Host "[COMPLETED]" -ForegroundColor Green
}

