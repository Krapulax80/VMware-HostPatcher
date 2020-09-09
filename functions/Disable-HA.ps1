function Disable-HA {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$clusterName
    )    
    begin {
        write-host "Disabling HA on the [$clusterName] cluster, this will allow us to remediate the hosts in this cluster."
    }
    process {
        Set-Cluster -cluster $clusterName -HAEnabled:$false -Confirm:$false | out-null
    }
    end {
        Write-Host "HA has been disabled on the [$clusterName] cluster."         
    }
}