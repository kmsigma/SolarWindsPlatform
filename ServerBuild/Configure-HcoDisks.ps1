#region Build Disk List
$DiskInfo  = @()
$DiskInfo += New-Object -TypeName PSObject -Property ( [ordered]@{ DiskNumber = [int]1; DriveLetter = "D"; Label = "Page File" } )
$DiskInfo += New-Object -TypeName PSObject -Property ( [ordered]@{ DiskNumber = [int]2; DriveLetter = "E"; Label = "Programs" } )
$DiskInfo += New-Object -TypeName PSObject -Property ( [ordered]@{ DiskNumber = [int]3; DriveLetter = "F"; Label = "Web" } )
$DiskInfo += New-Object -TypeName PSObject -Property ( [ordered]@{ DiskNumber = [int]4; DriveLetter = "G"; Label = "Logs" } )
#endregion

#region Online & Enable RAW disks
Get-Disk | Where-Object { $_.OperationalStatus -eq "Offline" } | Set-Disk -IsOffline:$false
Get-Disk | Where-Object { $_.PartitionStyle -eq "RAW" } | ForEach-Object { Initialize-Disk -Number $_.Number -PartitionStyle GPT }
#endregion

#region Create Partitions & Format
$FullFormat = $true # indicates a "quick" format
<#ForEach ( $Disk in $DiskInfo )
{
    # Create Partition and then Format it
        New-Partition -DiskNumber $Disk.DiskNumber -UseMaximumSize -DriveLetter $Disk.DriveLetter | Format-Volume -FileSystem NTFS -AllocationUnitSize 64KB -Force -Confirm:$false -Full:$FullFormat -NewFileSystemLabel $Disk.Label
     
    # Disable Indexing via WMI
    $WmiVolume = Get-WmiObject -Query "SELECT * FROM Win32_Volume WHERE DriveLetter = '$( $Disk.DriveLetter ):'"
    $WmiVolume.IndexingEnabled = $false
    $WmiVolume.Put()
}
#>
# Trying it a different way to see if we can parallelize the process
$DiskInfo | ForEach-Object -Process {
	$Partition = New-Partition -DiskNumber $_.DiskNumber -UseMaximumSize -DriveLetter $_.DriveLetter
	$Partition | Format-Volume -FileSystem 'NTFS' -AllocationUnitSize 64KB -Force -Confirm:$false -Full:$FullFormat -NewFileSystemLabel $_.Label
}

# Assign 'Windows' label to C: Drive
Get-Volume -DriveLetter C | Set-Volume -NewFileSystemLabel 'Windows'

#endregion

#region Set Page Files
$CompSys = Get-WmiObject -Class Win32_ComputerSystem -EnableAllPrivileges
# is the system set to use system managed page files
if ( $CompSys.AutomaticManagedPagefile )
{
    # if so, turn it off
    $CompSys.AutomaticManagedPagefile = $false
    $CompSys.Put()
}
# Set the size to 16GB + 257MB (per Microsoft Recommendations) and move it to the D:\ Drive
# as a safety-net I also keep 257MB for the mini-dump on the C:\ Drive.
$PageFileSettings = @()
$PageFileSettings += "c:\pagefile.sys 257 257"
$PageFileSettings += "d:\pagefile.sys 16641 16641"
 
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\" -Name "pagingfiles" -Type multistring -Value $PageFileSettings
#endregion

Write-Host "This is a good time to rename the computer if that's what you want to do." -ForegroundColor Red