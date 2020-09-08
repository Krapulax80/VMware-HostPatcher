function Enable-HA {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$clusterName
    ) 
    begin {
        Write-host "Enabling HA on the [$clusterName] cluster"        
    }
    
    process {    
        Set-Cluster -cluster $clusterName -HAEnabled:$true -Confirm:$false
    }
    
    end {
        write-Host "HA has been enabled on the [$clusterName] cluster"        
    }
}