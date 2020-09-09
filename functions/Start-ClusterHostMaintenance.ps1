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
        $x = 1
        do {
            $clusterHoststate = $null            
            $clusterHoststate = (Get-vmhost -name $currentClusterHost).ConnectionState
            Write-Host "Waiting for $currentClusterHost going to maintenance, please wait [try: $x]"
            Start-Sleep -Seconds 5
            Write-Host " Host [$currentClusterHost] state is [$clusterHoststate]"
            $x++
        } until ($clusterHoststate -match "Maintenance")
    }
    
    end {
        Write-Host "... $currentClusterHost is now in maintenace mode, continuing"
    }
}