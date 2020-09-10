function Stop-OVCVMs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$currentClusterHost
    )     
    begin {
        Write-Host "Let's find and shut down the OVC VM-s safely from the current [$currentClusterHost] host"            
    }
    process {
        Get-Vmhost -Name $currentClusterHost.name | Get-VM | where-object { $_.Name -like "OmniStack*" } | Shutdown-VMGuest -Confirm:$false
        
        # Wait for the VM-s to go down
        $x = 1
        do {
            $vmState = $null 
            $vmState = (get-vmhost -Name $currentClusterHost.name | get-vm | where-object { $_.Name -like "OmniStack*" }).PowerState
            Write-Host "Waiting for OVC VM on host  $($currentClusterHost.name) to safely shutdown... [check: $x]"
            Start-Sleep -Seconds 60
            $x++
        } until ($vmState -notcontains "PoweredOn")
    }
    
    end {
        Write-Host "... OVC VMs has been safely shut down on $($currentClusterHost.name)."        
    }
}