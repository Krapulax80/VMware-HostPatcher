function Update-ClusterHostBaseline {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$currentClusterHost,
        [Parameter(Mandatory)]$hostComplianceState
    )  
    begin {
        write-host "Updating [$($currentBaseline.baseline.name)] on [$($currentClusterHost.Name)] "
    }
    process {
        $stopWatch = [system.diagnostics.stopwatch]::StartNew()        
        Get-baseline -name $currentBaseline.baseline.name | update-entity -entity $currentClusterHost -confirm:$false
        $stopWatch.stop()
    }
    end {
        Write-Host "Baseline applied on [$($currentClusterHost.Name)] took [$($stopWatch.Elapsed.TotalMinutes)] minutes to complete this baseline update." 
    }
}