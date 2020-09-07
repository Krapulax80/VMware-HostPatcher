function Update-HostBaseline {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$esxhost ,
        [Parameter(Mandatory)]$hostbasecomp
    )  

    Write-Host
    Write-Host "The host $esxhost is not compliant for the "$hostbasecomp.Baseline.name" Baseline, attempting to remediate this baseline." -ForegroundColor Yellow

    # ... Remediate selected host for baseline ...
    write-host "Deploying "$hostbasecomp.Baseline.name" Baseline" -ForegroundColor Yellow

    # Start the stopwatch
    $stopWatch = [system.diagnostics.stopwatch]::StartNew()

    Get-baseline -name $hostbasecomp.Baseline.name | update-entity -entity $currentesxhost -confirm:$false

    # Stop the stopwatch
    $stopWatch.stop()
    Write-Host -ForegroundColor Black -BackgroundColor Yellow "Host $esxhost took  $($stopWatch.Elapsed.TotalMinutes) minutes to complete baseline updates."   
}