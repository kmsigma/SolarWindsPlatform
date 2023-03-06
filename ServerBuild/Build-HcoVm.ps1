#region Variable Declaration
$VMName = "KMSHCOPPE01Av" # Server Name
$CPUCount     = 4       # Number of CPU's to give the VM
$CPUReserve   = 50      # Percentage of CPU's being reserved
$RAMBoot      = 8GB     # Startup Memory
$RAMMin       = 8GB     # Minimum Memory (should be the same as RAMBoot)
$RAMMax       = 16GB    # Maximum Memory
$DynamicDisks = $true   # Use Dynamic Disks?
$Vlan         = 3030    # VLAN assignment for the Network Adapter
# Sizes and count of the disks
$VHDSizes = [ordered]@{ "C" = 40GB + 46400KB; # Boot
                        "D" = 26GB + 46400KB; # Page 
                        "E" = 40GB + 46400KB; # Programs
                        "F" = 10GB + 46400KB; # Web
                        "G" = 10GB + 46400KB; # Logs
                      }
#endregion

# Assume that we want to make all the VHDs in the default location for this server.
$VHDRoot = Get-Item -Path ( Get-VMHost | Select-Object -ExpandProperty VirtualHardDiskPath )
 
# Convert the hash table of disks into PowerShell Objects (easier to work with)
$VHDs = $VHDSizes.Keys | ForEach-Object { New-Object -TypeName PSObject -Property ( [ordered]@{ "ServerName" = $VMName; "Drive" = $_; "SizeBytes" = $VHDSizes[$_] } ) }
# Extend this object with the name that we'll want to use for the VHD
### My naming scheme is [MACHINENAME]_[DriveLetter].vhdx - adjust to match your own.
$VHDs | Add-Member -MemberType ScriptProperty -Name VHDPath -Value { Join-Path -Path $VHDRoot -ChildPath ( $this.ServerName + "_" + $this.Drive + ".vhdx" ) } -Force
 
# Create the VHDs
$VHDs | ForEach-Object { 
    if ( -not ( Test-Path -Path $_.VHDPath -ErrorAction SilentlyContinue ) )
    {
        Write-Verbose -Message "Creating VHD at $( $_.VHDPath ) with size of $( $_.SizeBytes / 1GB ) GB"
        New-VHD -Path $_.VHDPath -SizeBytes $_.SizeBytes -Dynamic:$DynamicDisks | Out-Null
    }
    else
    {
        Write-Host "VHD: $( $_.VHDPath ) already exists!" -ForegroundColor Red
    }
}


# Step 1 - Create the VM itself (shell) with no Hard Drives to Start
$VM = New-VM -Name $VMName -MemoryStartupBytes $RAMBoot -SwitchName ( Get-VMSwitch | Select-Object -First 1 -ExpandProperty Name ) -NoVHD -Generation 2 -BootDevice NetworkAdapter
# Step 2 - Bump the CPU Count
$VM | Set-VMProcessor -Count $CPUCount -Reserve $CPUReserve
# Step 3 - Set the Memory for the VM
$VM | Set-VMMemory -DynamicMemoryEnabled:$true -StartupBytes $RAMBoot -MinimumBytes $RAMMin -MaximumBytes $RAMMax
# Step 4 - Set the VLAN for the Network device
$VM | Get-VMNetworkAdapter | Set-VMNetworkAdapterVlan -Access -VlanId $Vlan
# Step 5 - Add Each of the VHDs
$VHDs | ForEach-Object { $VM | Add-VMHardDiskDrive -Path $_.VHDPath }
