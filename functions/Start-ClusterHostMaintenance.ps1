function Start-ClusterHostMaintenance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$currentClusterHost
    )  
    
    begin {
        # Put the host into maintenance mode then wait 30 seconds
        write-host "Placing $currentClusterHost into maintenance mode..."
        Get-VMHost -Name $currentClusterHost | set-vmhost -State Maintenance | out-null
    }
    
    process {
        $clusterHoststate = $null
        $z = 1
        do {
            $clusterHoststate = (Get-vmhost -name $currentClusterHost).ConnectionState
            Write-Host "Waiting for $currentClusterHost going to maintenance, please wait ... [try: $z]" -ForegroundColor Yellow
            Start-Sleep -Seconds 5
            $z++
        } until ($clusterHoststate -match "Maintenance")
    }
    
    end {
        Write-Host "... $currentClusterHost is now in maintenace mode, continuing..." -ForegroundColor Green 
    }
}