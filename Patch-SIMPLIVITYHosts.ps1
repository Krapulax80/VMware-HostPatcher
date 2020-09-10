<#
    .SYNOPSIS
      Patching VMware hosts 
    .DESCRIPTION
  
    .PARAMETER Menu
      
    .INPUTS
      The script needs to have this structure:
      - "config" folder in the same folder as the script
      - "config.csv", "hostlist.txt" and "VMexceptionlist.txt" in the config folder (these are excluded from GitHub)
    .OUTPUTS

    .NOTES
      Version:        3.0
      Author:         Mike Ward & Fabrice Semti
      Creation Date:  26/08/2020
      Purpose/Change: Initial function development
    .EXAMPLE
  
      . "\\tsclient\C\Users\fabrice.semti\OneDrive - Westcoast Limited\Desktop\PublicPowerShell\Scripts\VMware-HostPatcher\Patch-SIMPLIVITYHosts.ps1"
  
      Patch-SIMPLIVITYHosts 

      or

      Patch-SIMPLIVITYHosts -Live:$True

      # if "-Live" is  not set, the script will use the contents of the clusterlist.txt file; this is for test purposes

  #>    
[CmdletBinding()]
param (
  [Parameter(Mandatory = $false)][switch]$Live
  # ,
  # [Parameter(Mandatory = $false)][switch]$SkipOVC
)
      
begin {
  $ErrorActionPreference = "Stop"         
  $CurrentPath = $config = $null
  $CurrentPath = Split-Path -Parent $PSCommandPath
  # Define log files
  $date = Get-date -Format yyyy-MM-dd
  ## transcript
  $logfile = $CurrentPath + "\" + "logs" + "\" + $date + "_clusterpatcher_actions.log"
  Start-Transcript $logfile -Force
  ## errors
  $ErrorFile = $CurrentPath + "\" + "logs" + "\" + $date + "_clusterpatcher_error.log"
  $Error.clear()
  # Import config file        
  $config = Import-Csv "$currentPath/config/config.csv"
  #   # List of hosts
  #   $listofhosts = Get-Content  "$currentPath/config/hostlist.txt"
  #   # List of VM-s to leave online
  #   $listofhosts = Get-Content  "$currentPath/config/VMexceptions.txt"          
  # Connect to the VI server
  connect-viserver $config.VIserver
  # Set WebOperationTimeout to 1 hour to stop the script timing out and erroring
  Set-PowerCLIConfiguration -scope Session -WebOperationTimeoutSeconds 3600 -Confirm:$false  
  # Cluster list
  if ($Live) {
    $listofclusters = (get-cluster).Name # cluster names to work with
  }
  else {
    $listofclusters = Get-Content "$currentPath/config/clusterlist.txt" 
    $OVCSkip = "False"
    # Functions (script will uses these to execute the process)
    $functions = (Get-ChildItem "$currentPath/functions").FullName
    foreach ($f in $functions) {
      Write-Host -ForegroundColor Cyan "Importing function $f"
      if ($f -match ".ps1") {
        . $f
      }
    }   
    # Vriables for emailing
    $smtprelay = $config.SMTPRelay
    $mailsender = $config.mailsender
    $mailrecipients = Import-csv "$currentPath/config/recipients.csv"
  }  
}
      
process {       
  # Process each cluster in the list
  Foreach ($clusterName in $listofclusters) {
    # Process each cluster in the given list
    Write-Host #lazy line break for readability
    Write-Host "Processing $clusterName"
    Write-Host "===================================================================="    
    # Turn OVC check off, if the cluster is not a Simplivity-one
    if (  (!($clusterName -match "ALWCLESX001")) -and (!($clusterName -match "BNWCLESX001"))  ) {
      $OVCSkip = "True"
    }
    # Collect the compliance state of the cluster at the work start
    $startingClusterComplianceState = $null
    $startingClusterComplianceState = Get-compliance -entity (get-cluster $clusterName) | Where-Object { ($_.Baseline.Name -notlike "*VMware Tools Upgrade to Match Host (Predefined)*") -and ($_.Baseline.Name -notlike "*VM Hardware Upgrade to Match Host (Predefined)*") }
    if (!($startingClusterComplianceState.Status -contains "NotCompliant")) {
      # If the cluster compliance status does not contains "NotCompliant" entities, skip the rest of the work - as the cluster then compliant.
      Write-Host "Cluster [$clusterName] is fully compliant, skipping remediation work." -ForegroundColor Green
        
    }      
    else {
      # Else (if the status shows "NotCompliant") process all the hosts
      Write-Host "Cluster [$clusterName] needs remediation work." -ForegroundColor Yellow
      # First we disable High Availability in the cluster, as that would prevent our work.
      Disable-HA -clustername $clusterName
        
      # Collect the list of cluster member hosts in the cluster
      $clusterHosts = get-cluster -name $clusterName | Get-VMHost
      Write-Host "Number of hosts in the $clusterName cluster: " -nonewline
      Write-Host -ForegroundColor Magenta "$($clusterHosts.count)"
      $clusterhostnumber = 0
      # Loop through each cluster member host
      Foreach ($currentClusterHost in $clusterHosts) {
        $clusterhostnumber++
        Write-Host #lazy line break for readability
        Write-Host "Processing $currentClusterHost -  [Host $clusterhostnumber out of $($clusterHosts.count) hosts] "
        Write-Host "====================================================================" 
        # Repeat these steps, while there is "NotCompliant" updates on each host
        do {
            
          # Gather current compliance state of the cluster member host
          $hostComplianceState = $null
          $hostComplianceState = (get-compliance -entity $currentClusterHost)
          if (!($hostComplianceState.status -contains "NotCompliant")) {
            # If the host status is compliant, only report this, no further work to be done.
            Write-Host "Host [$currentClusterHost] is fully compliant, skipping remediation work." -ForegroundColor Green
          } 
          else {
            # Else (if the status shows "NotCompliant") process this host
            Write-Host "Host [$currentClusterHost] needs remediation work." -ForegroundColor Yellow   
            # If the cluster is a Simplivity-one, we need to turn off the OVC VM-s first
            if ($OVCSkip -eq "True") {
              Write-Host "Non-Simplivity cluster - skipping OVC work" -ForegroundColor DarkGreen
            }
            else {
              Write-Host "Simplivity cluster - shutting down OVC-VMs" -ForegroundColor DarkYellow
              Stop-OVCVMs -currentclusterhost $currentClusterHost
            } 
                
            # Now we put the host into maintenance
            Start-ClusterHostMaintenance -currentclusterhost $currentClusterHost
            # Loop trough each baseline of the host and update which needs update
            Foreach ($currentBaseline in $hostComplianceState) {
              Write-Host #lazy line break for readability
              Write-Host "Processing $($currentBaseline.Baseline.Name)"
              Write-Host "====================================================================" 
              if (!($currentBaseline.Status -match "Notcompliant")) {
                # If the baseline is compliant, reporting only
                Write-Host "Baseline [$($currentBaseline.Baseline.Name)] is compliant, skipping remediation work." -ForegroundColor Black -BackGroundColor Green                
              }
              else {
                # Else (if the baseline status shows "NotCompliant") process this host
                Write-Host "Baseline [$($currentBaseline.Baseline.Name)] needs remediation work." -ForegroundColor Black -BackGroundColor Yellow  
                # Update the non-compliant baselines on the  host
                Update-ClusterHostBaseline -currentclusterhost $currentClusterHost -hostComplianceState $hostComplianceState 
              }
            }
            # Now the host should be updated, so we end the maintenance
            Stop-ClusterHostMaintenance -currentclusterhost $currentClusterHost
            # If the cluster is a Simplivity-one, we need to start the OVC VM-s back
            if ($OVCSkip -eq "True") {
              Write-Host "Non-Simplivity cluster - skipping OVC work" -ForegroundColor DarkGreen               
            }
            else {
              Write-Host "Simplivity cluster - starting up OVC-VMs" -ForegroundColor DarkYellow
              Start-OVCVMs -currentclusterhost $currentClusterHost
              # Wait 10 min so OVC is safely back on
              Write-host "Starting 10 min cooldown period to allow OVC to come online. Time for a cup of coffee!" -ForeGroundColor Magenta
              Start-sleep -seconds 600
            } 
          }   
        } while ($hostComplianceState.status -contains "NotCompliant") # because of this "while", we will repeat the above "do" block until the "while" is true (in other words, while we find any "noncompliant" baseline)
      }
      # Finally we turn back on High Availability
      Enable-HA -clustername $clusterName
    }
    # Collect the compliance state of the cluster at the work start
    Start-Sleep -seconds 60 # short break to allow compliance 
    $endingClusterComplianceState = $null
    $endingClusterComplianceState = Get-compliance -entity (get-cluster $clusterName) | Where-Object { ($_.Baseline.Name -notlike "*VMware Tools Upgrade to Match Host (Predefined)*") -and ($_.Baseline.Name -notlike "*VM Hardware Upgrade to Match Host (Predefined)*") }  
    # Finally send report
    if ($startingClusterComplianceState -match $endingClusterComplianceState ) {
      Write-Host "Compliance level of cluster [$clusterName] did not change. Report not sent." -ForegroundColor Yellow
    }
    else {
      Write-Host "Sending report on pre- and post-patching compliance status." -ForegroundColor Green
      Send-ClusterStateReport -smtprelay $smtprelay -mailsender $mailsender -mailrecipients $mailrecipients -startingClusterComplianceState $startingClusterComplianceState -endingClusterComplianceState $endingClusterComplianceState
    }      
  }
}

end {
  # Log errors
  if ($Error) { 
    "[WARN] ERRORS FOUND DURING SCRIPT RUN" | Out-File $ErrorFile -Force
    $Error | Out-File $ErrorFile -Append 
  }
  else { 
    "[INFO] NO ERRORS DURING SCRIPT RUN" | Out-File $ErrorFile -Force
  } 
  # Disconnect VI-server session
  Disconnect-viserver -confirm:$false
  # End transcript logs
  Stop-Transcript
  Write-Host -ForegroundColor Cyan "Please review $logfile for full details of actions."
  Write-Host -ForegroundColor Cyan "Please review $ErrorFile for errors during script run"
}
