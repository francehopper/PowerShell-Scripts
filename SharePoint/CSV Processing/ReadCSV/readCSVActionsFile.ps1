# read csv file
# Disable this line when calling this file from a file
$myCSVFile = $args[0] # get the passed file
# load up SharePoint modules
# this script is intended to run on a SharePoint server!
Add-PSSnapin Microsoft.SharePoint.PowerShell # disabled while coding

function processSite ($myCSVFile) {
    $file = Import-csv $myCSVFile # open the file
    foreach ($item in $file) {
        $siteName = $item."site" # get the sites
        $siteAction = $item."action" # get the actions
        $siteTarget = $item."target_site_collection" # get the targets

        #echo "$siteName, $siteAction, $siteTarget" # debug to show values are being read

        if ($siteAction -eq "DELETE") {
            deleteSite $siteName
        }
        if ($siteAction -eq "ARCHIVE") {
            archiveSite $siteName $siteTarget
        }
    }
}

function deleteSite ($site) {
    write-host "Deleting site $site..."
    #Remove-SPWeb –Identity "$site" –Confirm:$False # delete the site
    write-host "Done!"
}

function archiveSite ($site, $target) {
    # archive the site via a backup and restore
    Write-host "Exporting $site..."
    $siteName = $site.split("/") | select -last 1
    $path = "C:\Backup\" + $siteName + "_backup.cmp"
    write-host $path
    Export-SPWeb $site -Path $path -Force # disabled while coding
    write-host "Done!"
    write-host "Importing $site to $target..."
    New-SPWeb $target
    Import-SPWeb $target -Path $path -UpdateVersions Overwrite -Force # disabled while coding
    write-host "Done!"
}
# Disable this line when calling this file from a file
processSite $myCSVFile # call the main processing function
write-host "All done! See Ya!"
# END OF FILE