function Update-ClusterHostBaseline {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] $currentClusterHost,
        [Parameter(Mandatory)] $hostComplianceState,
        [Parameter(Mandatory = $false)] $totalTime
    )  
    begin {
        write-host "Updating [$($currentBaseline.baseline.name)] on [$($currentClusterHost.Name)] "
        $stopWatch = [system.diagnostics.stopwatch]::StartNew()  
    }
    process {   
        
        try {
            #Remediate-Inventory -Baseline $currentBaseline.baseline -Entity $currentClusterHost -HostDisableMediaDevices:$true -Confirm:$false          
            Get-baseline -name $currentBaseline.baseline.name | update-entity -entity $currentClusterHost -confirm:$false
        }
        catch {
            Write-Host "We found an error" -ForegroundColor Red
            Write-Host "$_.Exception.Message"  -ForegroundColor Red
        }

    }
    end {
        $stopWatch.stop()
        Write-Host "Baseline applied on [$($currentClusterHost.Name)] took [$($stopWatch.Elapsed.TotalMinutes)] minutes to complete this baseline update." 
        if ($totalTime.ispresent) {
            $totalTime += $stopWatch.Elapsed.TotalMinutes
        }
    }
}