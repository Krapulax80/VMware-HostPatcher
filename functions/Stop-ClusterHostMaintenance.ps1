function Stop-ClusterHostMaintenance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$currentClusterHost
    )  
    begin {
        Write-Host #lazy line break
        write-host "Taking out host [$currentClusterHost] from maintenance mode..."
    }    
    process {
        Get-VMHost -Name $currentClusterHost | set-vmhost -State Connected | out-null        
        
        $x = 1
        do {
            $clusterHoststate = $null
            $clusterHoststate = (Get-vmhost -name $currentClusterHost).ConnectionState
            Write-Host "Waiting for $currentClusterHost going to maintenance, please wait ... [check: $x]"
            Start-Sleep -Seconds 5
            $x++
        } until ($clusterHoststate -match "Connected")
    }
    end {
        Write-Host "Host [$currentClusterHost] finished maintenance."
    }
}