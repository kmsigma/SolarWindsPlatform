<#
Updated for Hybrid Cloud Observability installer and Windows Server 2022

#>
$ProgramsDrive = "E:\"
$WebDrive      = "F:\"
$LogDrive      = "G:\"

# Enable Disk IO performance counters in task manager
Start-Process -FilePath "C:\Windows\System32\diskperf.exe" -ArgumentList "-Y" -Wait

if ( -not ( Test-Path -Path "C:\inetpub" -ErrorAction SilentlyContinue ) )
{
    $Redirections = @()
    $Redirections += New-Object -TypeName PSObject -Property ( [ordered]@{ Order = [int]6; SourcePath = "C:\inetpub"; TargetDrive = $WebDrive } )
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
}

# this is a list of the Windows Features that we'll need (omitting MSMQ for Orion Platform 2020.2.6+)
# it's being filtered for those which are not already installed
$Roles = (
    'FS-Data-Deduplication', 
    'Storage-Services', 
    'Web-Server', 
    'Web-WebServer', 
    'Web-Common-Http', 
    'Web-Default-Doc', 
    'Web-Dir-Browsing', 
    'Web-Http-Errors', 
    'Web-Static-Content', 
    'Web-Health', 
    'Web-Http-Logging', 
    'Web-Log-Libraries', 
    'Web-Request-Monitor', 
    'Web-Performance', 
    'Web-Stat-Compression', 
    'Web-Dyn-Compression', 
    'Web-Security', 
    'Web-Filtering', 
    'Web-Windows-Auth', 
    'Web-App-Dev', 
    'Web-Net-Ext45', 
    'Web-Asp-Net45', 
    'Web-ISAPI-Ext', 
    'Web-ISAPI-Filter', 
    'Web-Mgmt-Tools', 
    'Web-Mgmt-Console', 
    'Web-Mgmt-Compat', 
    'Web-Metabase', 
    'NET-Framework-45-Features', 
    'NET-Framework-45-Core', 
    'NET-Framework-45-ASPNET', 
    'NET-WCF-Services45', 
    'NET-WCF-TCP-PortSharing45', 
    'Web-Scripting-Tools'
)
$Features = Get-WindowsFeature -Name $Roles | Where-Object { -not $_.Installed }
$Features | Add-WindowsFeature

# <-- Need a reboot here
#Restart-Computer -ComputerName . -Force -Confirm:$false