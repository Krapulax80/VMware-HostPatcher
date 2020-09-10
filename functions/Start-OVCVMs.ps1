function Start-OVCVMs {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]$currentClusterHost
  )  
  begin {
    Write-Host "Let's find and start up the OVC VM-s on the current [$currentClusterHost] host"  
  } 
  process {
    get-vmhost -Name $currentClusterHost.name | Get-VM | where-object { $_.Name -like "OmniStack*" } | Start-VM
    $x = 1
    do {
      $vmState = $null
      $vmState = (get-vmhost -Name $currentClusterHost.name | get-vm | where-object { $_.Name -like "OmniStack*" }).PowerState
      Write-Host "Waiting for OVC on $($currentClusterHost.name) to power on... [check: $x]"
      Start-Sleep -Seconds 60
      $x++
    } until ($vmState -notcontains "PoweredOff")     
  }   
  end {
    Write-Host "... OVC VMs has been started on $($currentClusterHost.name)."          
  }
}