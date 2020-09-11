function Send-ClusterStateReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$smtprelay,
        [Parameter(Mandatory)]$mailsender, 
        [Parameter(Mandatory)]$mailrecipients,
        [Parameter(Mandatory)]$startingClusterComplianceState, 
        [Parameter(Mandatory)]$endingClusterComplianceState,
        [Parameter(Mandatory = $false)] $totalTime
    ) 
    
    begin {
        
        # Email parameters
        $TextEncoding = [System.Text.Encoding]::UTF8
        $timer = (Get-Date -Format yyy-MM-dd-HH:mm)
        $EmailSubject = "Cluster host patching report - [$timer]"  
        $EmailBody = $null               
    }
    
    process {

        $EmailBody =
        "
        <font face= ""Century Gothic"">
        Hello,
        <p> Please find cluster patching reports below:  <br>
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
                <p> Entity name (host): <span style=`"color:red`">" + " $($row.Entity) " + "</span> &nbsp;
                Baseline name     : <span style=`"color:red`">" + " $($row.Baseline.Name) " + "</span> &nbsp;
                Baseline status   : <span style=`"color:red`">" + " $($row.Status) " + "</span> <br>
                </li>
                "
            }
            elseif ($row.Status -eq "Compliant") {
                $EmailBody += 
                "
                <li>
                <p> Entity name (host): <span style=`"color:green`">" + " $($row.Entity) " + "</span> &nbsp;Baseline name     : <span style=`"color:green`">" + " $($row.Baseline.Name) " + "</span> &nbsp;
                Baseline status   : <span style=`"color:green`">" + " $($row.Status) " + "</span> <br>
                </li>
                "                              
            }
            else {
                $EmailBody += 
                "
                <li>
                <p> Entity name (host): <span style=`"color:yellow`">" + " $($row.Entity) " + "</span> &nbsp;
                Baseline name     : <span style=`"color:yellow`">" + " $($row.Baseline.Name) " + "</span> &nbsp;
                Baseline status   : <span style=`"color:yellow`">" + " $($row.Status) " + "</span> <br> 
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
        <h2> Total patching time was: $($totalTime) minutes </h2> <br>
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
                <p> Entity name (host): <span style=`"color:red`">" + " $($row.Entity) " + "</span> &nbsp;
                Baseline name     : <span style=`"color:red`">" + " $($row.Baseline.Name) " + "</span> &nbsp;
                Baseline status   : <span style=`"color:red`">" + " $($row.Status) " + "</span> <br>
                </li>
                "
            }
            elseif ($row.Status -eq "Compliant") {
                $EmailBody += 
                "
                <li>
                <p> Entity name (host): <span style=`"color:green`">" + " $($row.Entity) " + "</span> &nbsp;
                Baseline name     : <span style=`"color:green`">" + " $($row.Baseline.Name) " + "</span> &nbsp;
                Baseline status   : <span style=`"color:green`">" + " $($row.Status) " + "</span> <br>
                </li>
                "                              
            }
            else {
                $EmailBody += 
                "
                <li>
                <p> Entity name (host): <span style=`"color:yellow`">" + " $($row.Entity) " + "</span> &nbsp;
                Baseline name     : <span style=`"color:yellow`">" + " $($row.Baseline.Name) " + "</span> &nbsp;
                Baseline status   : <span style=`"color:yellow`">" + " $($row.Status) " + "</span> <br> 
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

        foreach ($recipient in $mailrecipients) {
            Send-Mailmessage -smtpServer $smtprelay -from $mailsender -to $($recipient.recipient) -subject $EmailSubject -body $EmailBody -bodyasHTML -priority High -Encoding $TextEncoding -ErrorAction Continue
        }
        #Send-Mailmessage -smtpServer $smtprelay -from $mailsender -to "GroupInfrastructure@westcoast.co.uk" -subject $EmailSubject -body $EmailBody -bodyasHTML -priority High -Encoding $TextEncoding -ErrorAction Continue
    }
    
    end {
        $EmailBody = $null
    }
}