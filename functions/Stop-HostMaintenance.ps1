function Stop-HostMaintenance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$esxhost
    )  

    if ( ((Get-vmhost -name $esxhost).ConnectionState) -eq "Maintenance") {
        Write-host "Removing host from Maintenance Mode"
        [void] (Get-VMHost -Name $esxhost | set-vmhost -State Connected)
    }
   
    $vmHostState = $null
    $x = 1
    do {
        [void] ($vmHostState = (Get-vmhost -name $esxhost).ConnectionState)
        Write-Host "Waiting for $esxhost to exit maintenance mode, please wait ... [try: $x]" -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        $x++
    } until ($vmHostState -match "Connected")

    Write-Host "... $esxhost is no longer in maintenance mode, continuing" -ForegroundColor Green    
    # Giving the host extra 30 seconds to get to maintenance
    # Write-Host "Giving the host another 30 seconds to complete maintenance finish"
    # Start-sleep -seconds 30   
  
}