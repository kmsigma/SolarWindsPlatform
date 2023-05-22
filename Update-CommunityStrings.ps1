<#
Script: Update-CommunityStrings.ps1

Purpose: Bulk update read-only and read-write community strings

Inspired by: https://thwack.solarwinds.com/product-forums/the-orion-platform/i/feature-requests/mass-update-community-string

========================================================= DISCLAIMER =========================================================
Please note, any custom scripts or other content posted herein are provided as a suggestion or recommendation to you for your internal use. This is not part of the SolarWinds software that you have purchased from SolarWinds, and the information set forth herein may come from third party customers. Your organization should internally review and assess to what extent, if any, such custom scripts or recommendations will be incorporated into your environment. Any custom scripts obtained herein are provided to you "AS IS" without indemnification, support, or warranty of any kind, express or implied. You elect to utilize the custom scripts at your own risk, and you will be solely responsible for the incorporation of the same, if any.
#>

# SolarWinds PowerShell Module Required, if it fails, stop executing
Import-Module -Name SwisPowerShell -ErrorAction Stop

# Update to your server (or IP), username, and password here.
$SwisConnection = Connect-Swis -Hostname 'yourSolarWindsServer.domain.local' -Username 'YourUsername' -Password 'Yo|_|Rc0mpl3xP@ssw[]rd'

# Community Strings to find
$OldRoCommunity = 'Old Read-Only Community String Here'
$OldRwCommunity = 'Old Read-Write Community String Here'
# Community String to update to
$NewRoCommunity = 'New Read-Only Community String Here'
$NewRwCommunity = 'New Read-Write Community String Here'

# Query to get all the nodes with the legacy Read-Only Community String from NPM enties
$SwqlRoQueryNpm = @"
SELECT [Nodes].NodeID
     , [Nodes].IPAddress
     , [Nodes].Caption
     , [Nodes].Community AS [ROCommunity]
     , [Nodes].RWCommunity
     , [Nodes].Uri
FROM Orion.Nodes AS [Nodes]
WHERE [Nodes].ObjectSubType = 'SNMP'
  AND [Nodes].Community = '$( $OldRoCommunity )'
ORDER BY [Nodes].Caption
"@

# Query to get all the nodes with the legacy Read-Write Community String from NPM entities
$SwqlRwQueryNpm = @"
SELECT [Nodes].NodeID
     , [Nodes].IPAddress
     , [Nodes].Caption
     , [Nodes].Community AS [ROCommunity]
     , [Nodes].RWCommunity
     , [Nodes].Uri
FROM Orion.Nodes AS [Nodes]
WHERE [Nodes].ObjectSubType = 'SNMP'
  AND [Nodes].RWCommunity = '$( $OldRwCommunity )'
ORDER BY [Nodes].Caption
"@

# Query to get all the nodes with the legacy Read-Only Community String from NCM enties
$SwqlRoQueryNcm = @"
SELECT [NcmNodes].CoreNodeID AS [NodeID]
     , [NcmNodes].NodeCaption AS [Caption]
     , [NcmNodes].AgentIP AS IPAddress
     , [NcmNodes].Community AS [ROCommunity]
     , [NcmNodes].CommunityReadWrite AS [RWCommunity]
     , [NcmNodes].Uri
FROM Cirrus.Nodes AS [NcmNodes]
WHERE ROCommunity = '$( $OldRoCommunity )'
ORDER BY [Caption]
"@

# Query to get all the nodes with the legacy Read-Write Community String from NCM entities
$SwqlRwQueryNcm = @"
SELECT [NcmNodes].CoreNodeID AS [NodeID]
     , [NcmNodes].NodeCaption AS [Caption]
     , [NcmNodes].AgentIP AS IPAddress
     , [NcmNodes].Community AS [ROCommunity]
     , [NcmNodes].CommunityReadWrite AS [RWCommunity]
     , [NcmNodes].Uri
FROM Cirrus.Nodes AS [NcmNodes]
WHERE RWCommunity = '$( $OldRwCommunity )'
ORDER BY [Caption]
"@

# Retrieve data from the SolarWinds Information Service for Read-Only and Read-Write Community Strings (NPM-based)
$NodesToUpdateRoCommunityNpm = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlRoQueryNpm
$NodesToUpdateRwCommunityNpm = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlRwQueryNpm

# Retrieve data from the SolarWinds Information Service for Read-Only and Read-Write Community Strings (NCM-based)
$NodesToUpdateRoCommunityNcm = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlRoQueryNcm
$NodesToUpdateRwCommunityNcm = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlRwQueryNcm

#region Update NPM entities
ForEach ( $NodeRoNpm in $NodesToUpdateRoCommunityNpm ) {
    Write-Host "NPM: Updating RO Community String for $( $NodeRoNpm.Caption) from '$( $NodeRoNpm.ROCommunity )' to '$NewRoCommunity'"
    # Uncomment the below line to actually do the work
    # Set-SwisObject -SwisConnection $SwisConnection -Uri $NodeRoNpm.Uri -Properties @{ Community = $NewRoCommunity }
}

ForEach ( $NodeRwNpm in $NodesToUpdateRwCommunityNpm ) {
    Write-Host "NPM: Updating RO Community String for $( $NodeRwNpm.Caption) from '$( $NodeRwNpm.RWCommunity )' to '$NewRwCommunity'"
    # Uncomment the below line to actually do the work
    # Set-SwisObject -SwisConnection $SwisConnection -Uri $NodeRwNpm.Uri -Properties @{ RWCommunity = $NewRwCommunity }
}
#endregion Update NPM entities

#region Update NCM entities
ForEach ( $NodeRoNcm in $NodesToUpdateRoCommunityNcm ) {
    Write-Host "NCM: Updating RO Community String for $( $NodeRoNcm.Caption) from '$( $NodeRoNcm.ROCommunity )' to '$NewRoCommunity'"
    # Uncomment the below line to actually do the work
    # Set-SwisObject -SwisConnection $SwisConnection -Uri $NodeRoNcm.Uri -Properties @{ Community = $NewRoCommunity }
}

ForEach ( $NodeRwNcm in $NodesToUpdateRwCommunityNcm ) {
    Write-Host "NCM: Updating RO Community String for $( $NodeRwNcm.Caption) from '$( $NodeRwNcm.RWCommunity )' to '$NewRwCommunity'"
    # Uncomment the below line to actually do the work
    # Set-SwisObject -SwisConnection $SwisConnection -Uri $NodeRwNcm.Uri -Properties @{ CommunityReadWrite = $NewRwCommunity }
}
#region Update NCM entities