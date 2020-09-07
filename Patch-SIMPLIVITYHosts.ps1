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
      Version:        0.1
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


  }  
}
      
process {
        
  Foreach ($clustername in $listofclusters) {

    if (  (!($clustername -match "ALWCLESX001")) -and (!($clustername -match "BNWCLESX001"))  ) {
      $OVCSkip = "True"
    }

    # Let's check compliance for first host in cluster
    write-host "Checking host: $currentclusterhost"
    #Get list of hosts in specified cluster
    $clusterhosts = get-cluster -name $clustername | Get-VMHost
    $clusterhostcount = $clusterhosts.count
    write-host "Number of hosts to be checked in the $clustername cluster is $clusterhostcount"

    # Loop through each host
    Foreach ($currentclusterhost in $clusterhosts) {

      $y = 1
      do {
        # Let's check compliance for first host in cluster
        write-host "Checking host: $currentclusterhost - attempt: $y "
        $clusterBaselineStatus = $null
        $clusterBaselineStatus = (get-compliance -entity $currentclusterhost)
        # Do remediation, if non-compliant host found
        if ($clusterBaselineStatus -contains "NotCompliant") {
          Write-Host "Host $currentclusterhost is not compliant in one or more baselines, I will remediate this host." -ForegroundColor Yellow

          Foreach ($currentclusterhostcomp in $clusterBaselineStatus) {

            #If host is compliant for a baseline let's output this
            write-host "Checking baselines for compliance on $currentclusterhost."
            If ($currentclusterhostcomp.status -eq "Compliant") {
              Write-Host "$currentclusterhost is compliant for the "$currentclusterhostcomp.Baseline.Name" Baseline, continuing..."
            }
            #For baselines not compliant on the host let's start remediation
            else {

              Write-Host "$currentclusterhost is not compliant for the "$currentclusterhostcomp.Baseline.name" Baseline, starting remediation..."

              #First we need to disable HA in the cluster
              write-host "Disabling HA on the $clustername cluster, this will allow us to remediate the host"
              set-cluster -cluster $clustername -HAEnabled:$false -Confirm:$false | out-null
              write-host "HA has been disabled on the $clustername cluster. Continuing..."

              if ($OVCSkip -eq "True") {
                Write-Host -ForegroundColor DarkYellow "In non-simplivity mode, skipping OVC VM check"
              }
              else {
                #Let's find and shut down the OVC safely from the current host
                get-vmhost -Name $currentclusterhost.name | Get-VM | where-object { $_.Name -like "OmniStack*" } | Shutdown-VMGuest -Confirm:$false
                Write-Host "Let's find and shut down the OVC safely from the current host"
                #write-host "Waiting 2 minutes for OVC to cleanly shut down"
                $vmState = $null
                $x = 1
                do {
                  $vmState = (get-vmhost -Name $currentclusterhost.name | get-vm | where-object { $_.Name -like "OmniStack*" }).PowerState
                  Write-Host "Waiting for OVC on $($currentclusterhost.name) to safely shutdown ... [try: $x]" -ForegroundColor Yellow
                  Start-Sleep -Seconds 5
                  $x++
                } until ($vmState -notcontains "PoweredOn")
                Write-Host "... OVC has been safely shut down on $($currentclusterhost.name). Continuing..." -ForegroundColor Green
                # start-sleep -seconds 120
              }


              # Put the host into maintenance mode then wait 30 seconds
              write-host "Placing $currentclusterhost into maintenance mode..."
              Get-VMHost -Name $currentclusterhost | set-vmhost -State Maintenance | out-null

              $clusterHostState = $null
              $z = 1
              do {
                $clusterHostState = (Get-vmhost -name $currentclusterhost).ConnectionState
                Write-Host "Waiting for $currentclusterhost going to maintenance, please wait ... [try: $z]" -ForegroundColor Yellow
                Start-Sleep -Seconds 5
                $z++
              } until ($clusterHostState -match "Maintenance")
              Write-Host "... $currentclusterhost is now in maintenace mode, continuing..." -ForegroundColor Green 

              # Check baselines and update
              write-host "Fetching all baseines for $currentclusterhost, then we will apply to the host any that are not complaint..."
              # Start the stopwatch
              $stopWatch = [system.diagnostics.stopwatch]::StartNew()
              get-baseline -name $currentclusterhostcomp.baseline.name | update-entity -entity $currentclusterhost -confirm:$false
              # Stop the stopwatch
              $stopWatch.stop()
              Write-Host -ForegroundColor Black -BackgroundColor Yellow "Baseline applied, $currentclusterhost took $($stopWatch.Elapsed.TotalMinutes) minutes to complete baseline updates." 

              #Bring the host back online now it's remediated
              write-host "Removing $currentclusterhost from Maintenance Mode"
              Get-VMHost -Name $currentclusterhost | set-vmhost -State Connected | out-null

              if ($OVCSkip -eq "True") {
                Write-Host -ForegroundColor DarkYellow "In non-simplivity mode, skipping OVC VM check"                
              }
              else {
                #Now let's power up the OVC for this host
                write-host "Powering up the OVC for the host"
                get-vmhost -Name $currentclusterhost.name | Get-VM | where-object { $_.Name -like "OmniStack*" } | Start-VM
                $vmState = $null
                $q = 1
                do {
                  $vmState = (get-vmhost -Name $currentclusterhost.name | get-vm | where-object { $_.Name -like "OmniStack*" }).PowerState
                  Write-Host "Waiting for OVC on $($currentclusterhost.name) to power on... [try: $x]" -ForegroundColor Yellow
                  Start-Sleep -Seconds 5
                  $q++
                } until ($vmState -notcontains "PoweredOff")
                Write-Host "... OVC is now powered on $($currentclusterhost.name)." -ForegroundColor Green       
                # Write-Host "Let's wait 5 minutes before starting the next host to give enough time for the OVC to boot up and sync cluster storage."
                # start-sleep -seconds 300
              }
              write-host "$currentclusterhost has now been fully remediated"
            }
          }

        }
        else {
          Write-Host "Host $currentclusterhost is fully compliant." -ForegroundColor Green
        }

        $y++
        Start-Sleep -seconds 5

      } until ($clusterBaselineStatus -notcontains "NotCompliant" )
    }

    write-host "Enabling HA on the $clustername cluster"
    set-cluster -cluster $clustername -HAEnabled:$true -Confirm:$false
    write-host "HA has now been enabled on the $clustername cluster"
  }
        
}
      
end {
  disconnect-viserver -confirm:$false
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
#TODO: - add web timeout to 1 hour - OK
#TODO: - Do statement until OVC has shut down instead of a 5 minute timer - OK
#TODO: - Logic check on each sweep of baselines to check again (not rely on cached variable - OK
#TODO: - Stopwatch - OK
#TODO: - Transcript logging - OK