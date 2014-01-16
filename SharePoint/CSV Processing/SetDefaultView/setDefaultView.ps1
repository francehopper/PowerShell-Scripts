$myCSVFile = $args[0] # Get the passed csv file
Add-PSSnapin Microsoft.SharePoint.PowerShell # Load the SharePoint module

# Read the CSV file
function processSite ($myCSVFile) {
    $file = Import-csv $myCSVFile # Open the file csv file
    foreach ($item in $file) {
        # Get the sites and lists to work on
        $siteURL = $item."site" # get the site
        $siteList = $item."list" # get the list
        # Get paramaters to set
        $siteFilterOn = $item."sort_field" # Get the field to sort on
        $siteFilterDirection = $item."direction" # Get the sort direction
        $indexOn = $item."index_on" # Get the column to index on, if any
        $siteViewLimit = $item."limit" # Get the number of items to show
        $siteViewName = $item."view_name" # Get the name for the new view
        # Create the view
        write-host "Creating default view for $siteList..."
        createView $siteURL $siteList $siteFilterOn $siteFilterDirection $indexOn $siteViewLimit $siteViewName
        write-host "Done!"
    }
}

function createView ($siteURL, $siteList, $siteFilterOn, $siteFilterDirection, $indexOn, $siteViewLimit, $siteViewName) {
    # Open a connect to SP and fetch the list to work on
    $web = Get-SPWeb $siteURL
    $list = $web.GetList(($web.ServerRelativeUrl.TrimEnd("/") + "/" + $siteList))

    # Add the column names from the ViewField property to a string collection
    $viewFields = New-Object System.Collections.Specialized.StringCollection
    $viewFields.Add("DocIcon") > $null
    $viewFields.Add("LinkFilename") > $null
    $viewFields.Add("Created") > $null
    $viewFields.Add("Modified") > $null
    $viewFields.Add("Editor") > $null
    $viewFields.Add("FileSizeDisplay") > $null

    # Determine sort direction
    if ($siteFilterDirection -eq "Descending") {
        $viewQuery = "<OrderBy><FieldRef Name='$siteFilterOn' Ascending='False' /></OrderBy>"
    }

    if ($siteFilterDirection -eq "Ascending") {
        $viewQuery = "<OrderBy><FieldRef Name='$siteFilterOn' Ascending='True' /></OrderBy>"
    }

    # Set the name of the view
    $viewName = $siteViewName

    # Set number of rows to display per page
    $setRowLimitTo = $siteViewLimit

    # Set paged view and default to True
    $setViewToPaged = $true
    $setViewToDefault = $true

    # Set column indexing, if any
    if ($indexOn) { # If the indexOn varible = null, no indexing to set
        $spField = $list.Fields[$indexOn]
        $spField.Indexed = $true
        $spField.Update()
    }

    # Build the view to be created
    $myListView = $list.Views.Add($viewName, $viewFields, $viewQuery, $setRowLimitTo, $setViewToPaged, $setViewToDefault)

    # Update list and view to apply changes
    $myListView.Update()
    $list.Update()

    # Finish and clean up
    Write-Host ("View '" + $myListview.Title + "' created in list '" + $list.Title + "' on site " + $web.Url)
    $web.Dispose()
}

processSite $myCSVFile # Call the main processing function
write-host "All done! See Ya!"
# END OF FILE