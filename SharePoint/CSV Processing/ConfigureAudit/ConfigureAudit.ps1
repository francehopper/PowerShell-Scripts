$myCSVFile = $args[0] # get the passed file
Add-PSSnapin Microsoft.SharePoint.PowerShell # load the SharePoint module

# Read the CSV file
function processCSV ($myCSVFile) {
    $file = Import-csv $myCSVFile # open the file
    foreach ($item in $file) {
        $siteURL = $item."SiteURL" # get the site
        write-host $siteURL
        $trim = $item."TrimLogs" # get if audit logs should be trimed or not
        write-host $trim
        $daysToKeep = $item."DaysToKeepLogs" # get the number of days the logs should be kept before trimming
        write-host $daysToKeep
        # configure Audit settings for each site
        write-host "Setting Audit options for #siteURL"
        set-auditing $siteURL $trim $daysToKeep
        write-host "Done!"
    }
}

function set-auditing ($siteURL, $trim, $daysToKeep) {
    $webapp = Get-SPWebApplication $siteURL
    $auditmask = [Microsoft.SharePoint.SPAuditMaskType]::Delete -bxor [Microsoft.SharePoint.SPAuditMaskType]::Update -bxor [Microsoft.SharePoint.SPAuditMaskType]::SecurityChange

    $webapp.sites | % {

        $_.TrimAuditLog = $trim
        $_.Audit.AuditFlags = $auditmask
        $_.Audit.Update()
        if ($trim -eq "$true") { # if we're not trimming logs, this option isn't configurable
            $_.AuditLogTrimmingRetention = $daysToKeep
        }
    }
}

processCSV $myCSVFile # call the main processing function
write-host "All done! See Ya!"
# END OF FILE