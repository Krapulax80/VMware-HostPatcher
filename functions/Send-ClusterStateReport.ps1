function Send-ClusterStateReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$smtprelay,
        [Parameter(Mandatory)]$mailsender, 
        [Parameter(Mandatory)]$mailrecipients,
        [Parameter(Mandatory)]$startingClusterComplianceState, 
        [Parameter(Mandatory)]$endingClusterComplianceState
    ) 
    
    begin {
        
        # Email parameters
        $SmtpServer = $smtprelay
        $ReportSender = $mailsender

        $TextEncoding = [System.Text.Encoding]::UTF8
        $timer = (Get-Date -Format yyy-MM-dd-HH:mm)
        $EmailSubject = "Cluster host patching report - [$timer]"  
        $ReportRecipients = $mailrecipients
        $EmailBody = $null               
    }
    
    process {

        $EmailBody =
        "
        <font face= ""Century Gothic"">
        Hello,
        <p> Please find cluster reports below:  <br>
        "

        # Report of state before the patching #############################################################################################################################################################
        $EmailBody += 
        "
        <h1> <span style=`"color:blue`">" + " Pre-Patch report:  " + "</span> </h1> <br>
        "

        $EmailBody += 
        "
        <ul style=""list-style-type:disc"">
        "
        
        foreach ($row in $startingClusterComplianceState) {
            if ($row.Status -eq "NotCompliant") {
                $EmailBody += 
                "
                <li>
                <p> Entity name (host): <span style=`"color:red`">" + " $($row.Entity) " + "</span> <br> 
                <p> Baseline name     : <span style=`"color:red`">" + " $($row.Baseline.Name) " + "</span> <br>
                <p> Baseline status   : <span style=`"color:red`">" + " $($row.Status) " + "</span> <br>
                </li>
                "
            }
            elseif ($row.Status -eq "Compliant") {
                $EmailBody += 
                "
                <li>
                <p> Entity name (host): <span style=`"color:green`">" + " $($row.Entity) " + "</span> <br> 
                <p> Baseline name     : <span style=`"color:green`">" + " $($row.Baseline.Name) " + "</span> <br>
                <p> Baseline status   : <span style=`"color:green`">" + " $($row.Status) " + "</span> <br>
                </li>
                "                              
            }
            else {
                $EmailBody += 
                "
                <li>
                <p> Entity name (host): <span style=`"color:yellow`">" + " $($row.Entity) " + "</span> <br> 
                <p> Baseline name     : <span style=`"color:yellow`">" + " $($row.Baseline.Name) " + "</span> <br>
                <p> Baseline status   : <span style=`"color:yellow`">" + " $($row.Status) " + "</span> <br> 
                </li>
                "                 
            }
        }

        $EmailBody += 
        "
        </ul>
        "  
        
        # Report of state after the patching #############################################################################################################################################################
        $EmailBody += 
        "
        <h1> <span style=`"color:blue`">" + " Post-Patch report:  " + "</span> </h1> <br>
        "

        $EmailBody += 
        "
        <ul style=""list-style-type:disc"">
        "
        
        foreach ($row in $endingClusterComplianceState) {
            if ($row.Status -eq "NotCompliant") {
                $EmailBody += 
                "
                <li>
                <p> Entity name (host): <span style=`"color:red`">" + " $($row.Entity) " + "</span> <br> 
                <p> Baseline name     : <span style=`"color:red`">" + " $($row.Baseline.Name) " + "</span> <br>
                <p> Baseline status   : <span style=`"color:red`">" + " $($row.Status) " + "</span> <br>
                </li>
                "
            }
            elseif ($row.Status -eq "Compliant") {
                $EmailBody += 
                "
                <li>
                <p> Entity name (host): <span style=`"color:green`">" + " $($row.Entity) " + "</span> <br> 
                <p> Baseline name     : <span style=`"color:green`">" + " $($row.Baseline.Name) " + "</span> <br>
                <p> Baseline status   : <span style=`"color:green`">" + " $($row.Status) " + "</span> <br>
                </li>
                "                              
            }
            else {
                $EmailBody += 
                "
                <li>
                <p> Entity name (host): <span style=`"color:yellow`">" + " $($row.Entity) " + "</span> <br> 
                <p> Baseline name     : <span style=`"color:yellow`">" + " $($row.Baseline.Name) " + "</span> <br>
                <p> Baseline status   : <span style=`"color:yellow`">" + " $($row.Status) " + "</span> <br> 
                </li>
                "                 
            }
        }

        $EmailBody += 
        "
        </ul>
        "                         
            
        $EmailBody +=            
        "
            <p> Thank you. <br>
            <p>Regards, <br>
            Westcoast Group IT
            </P>
            </font>
            "

        foreach ($recipient in $ReportRecipients) {
            Send-Mailmessage -smtpServer $SmtpServer -from $ReportSender -to $recipient -subject $EmailSubject -body $EmailBody -bodyasHTML -priority High -Encoding $TextEncoding
        }
        
    }
    
    end {
        $EmailBody = $null
    }
}