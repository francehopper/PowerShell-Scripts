$myCSVFile = $args[0] # get the passed file
#Add-PSSnapin "Microsoft.SharePoint.PowerShell" # load the SharePoint module

# Read the CSV file
function processSite ($myCSVFile) {
    $file = Import-csv $myCSVFile # open the file
    foreach ($item in $file) {
        $siteURL = $item."URL" # get the site URL
        $siteName = $item."Name" # get the name of the collection
        $siteWapp = $item."Web App" # get the web app
        $siteDB = $item."ContentDB" # get the filter
        $siteLanguage = $item."Language" # get the site language
        $siteTemplate = $item."Template" # get the template for the site collection
        $siteOwner = $item."Owner" # get the site Owner
        $siteSecondaryOwner = $item."Secondary Owner" # get the secondary site owner
        # go and create the view
        write-host "Creating the site collection for $siteName..."
        createSiteCollection $siteURL $siteName $siteWapp $siteDB $siteLanguage $siteTemplate $siteOwner $siteSecondaryOwner
        #write-host "$siteURL, $siteName, $siteWapp, $siteDB, $siteLanguage, $siteTemplate, $siteOwner, $siteSecondaryOwner"
        write-host "Done!"
    }
}

function createSiteCollection ($siteURL, $siteName, $siteWapp, $siteDB, $siteLanguage, $siteTemplate, $siteOwner, $siteSecondaryOwner) {
    if ($siteWapp) {
        $webApp = Get-SPWebApplication $siteWapp
    }
    if ($siteLanguage -eq "English") {
        $siteLanguage = "1033"
    }
    

    # URL is required
    if (!$siteURL) {
        write-host "Site URL is required!"
        write-host "Failed to build $siteName."
    }
    # Owner is required
    elseif (!$siteOwner) {
        write-host "A primary site owner is required!"
        write-host "Failed to build $siteName."
    }
    # WebApp is optional

    # DB is optional

    # Language is optional
    

    # Template is optional

    # SecondaryOwner is optional

    # Build site
    else {
        New-SPSite $siteURL -OwnerAlias $siteOwner -SecondaryOwnerAlias $siteSecondaryOwner -ContentDatabase $siteDB -HostHeaderWebApplication $webApp -Language $siteLanguage -Name $siteName -Template $siteTemplate 
    }
}

processSite $myCSVFile # call the main processing function
write-host "All done! See Ya!"
# END OF FILE