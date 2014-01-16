$myCSVFile = $args[0] # Get the csv file to work with
Add-PSSnapin Microsoft.SharePoint.PowerShell # Load the SharePoint module

# Read the CSV file
function processCSVFile ($myCSVFile) {
    $file = Import-csv $myCSVFile # Open the file
    foreach ($item in $file) { # Loop through the contents of the csv file
        # Things we need to fetch
        $siteURL = $item."site" # Get the site
        $siteList = $item."list" # Get the list
        # Things we'll be updating
        $indexOn = $item."index_on" # Get the column to index on
        $siteViewLimit = $item."limit" # Get the number of items to show
        # Create the view
        write-host "Updating the default view for $siteList..."
        updateDefaultView $siteURL $siteList $indexOn $siteViewLimit
        write-host "Done!"
    }
}

function updateDefaultView ($siteURL, $siteList, $indexOn, $siteViewLimit) {
    # Open a connection to SP and fetch the list to work on
    $spWeb = Get-SPWeb $siteURL # Connect to SharePoint
    $list = $spWeb.Lists[$siteList] # Get the list
    # Get the default view from the list
    #$defaultView = $list.defaultview.url # Find the URL of the default view
    #$defaultViewURL = $siteURL + "/" + $defaultView # Build the complete URL of the default view
    #$spView = $spWeb.GetViewFromUrl($($defaultViewURL)) # Load as the view we want to edit

    $spView = $list.views[$list.DefaultView.Title]
    # Check if the defualt view has the created column visible; add it if not
    if(!$spView.ViewFields.ToStringCollection().Contains("Created")) {
        $spView.ViewFields.add("Created")
    }
    # Filter on the "Created" column
    # Check if a filter already exists
    if ($spView.Query) {
        write-host "A query exists."
        $existingQuery = $spView.Query # Store the existing filter query
        write-host $existingQuery
        # Check if our filter already exists
        if ($existingQuery.Contains("<Gt><FieldRef Name=`"Created`" /><Value Type=`"DateTime`">")) {
            write-host "A filter on Created already exists!"
        }
        # Start checks for sorts
        # Check for multiple filters and a sort
        elseif ($existingQuery.Contains("</OrderBy><Where><And>")) {
            write-host "A sort and multiple filters exists."
            # Build the new query
            $updatedQuery="<Gt><FieldRef Name='Created' /><Value Type='DateTime'><Today OffsetDays='-365' /></Value></Gt></And></Where>"
            # Add another And for our new query
            $replaceStart = $existingQuery.Replace("</OrderBy><Where><And>", "</OrderBy><Where><And><And>")
            # Append our new query to the end of the existing query
            $replaceEnd = $replaceStart.Replace("</Where>", $updatedQuery)
            # Write the finished query
            $completedQuery = $replaceEnd
            $spView.Query = $completedQuery
            $spView.Update()
        }
        # Check if we have a sort and a single filter
        elseif ($existingQuery.Contains("</OrderBy><Where>")) {
            write-host "A sort and a sinlge filter exists."
            # Build the updated query
            $updatedQuery="</OrderBy><Where><And><Gt><FieldRef Name='Created' /><Value Type='DateTime'><Today OffsetDays='-365' /></Value></Gt>"
            # Change </OrderBy><Where> to </OrderBy><Where><And>
            $replaceStart = $existingQuery.Replace("</OrderBy><Where>", $updatedQuery)
            # Change </Where> to </Where><And>
            $replaceEnd = $replaceStart.Replace("</Where>", "</And></Where>")
            # Write the finished query
            $completedQuery = $replaceEnd
            $spView.Query = $completedQuery
            $spView.Update()
        }
        # Check if we have only a single sort
        elseif ($existingQuery.Contains("</OrderBy>")) {
            write-host "A sort and no filters exists."
            # Build the updated query
            $updatedQuery="</OrderBy><Where><Gt><FieldRef Name='Created' /><Value Type='DateTime'><Today OffsetDays='-365' /></Value></Gt></Where>"
            # Replace </OrderBy> with </OrderBy><Where>
            $replaceStart = $existingQuery.Replace("</OrderBy>", $updatedQuery)
            # Write the finished query
            $completedQuery = $replaceStart
            $spView.Query = $completedQuery
            $spView.Update()
        }
        # End checks for sorts
        # Check if we have no sorts but multiple filters
        elseif ($existingQuery.Contains("<Where><And>")) {
            write-host "No sorts and multiple filters exists."
            # Build our updated query
            $updatedQuery="<Gt><FieldRef Name='Created' /><Value Type='DateTime'><Today OffsetDays='-365' /></Value></Gt></And></Where>"
            # Add another And for our new query
            $replaceStart = $existingQuery.Replace("<Where><And>", "<Where><And><And>")
            # Append our new query to the end of the existing query
            $replaceEnd = $replaceStart.Replace("</Where>", $updatedQuery)
            # Write the finished query
            $completedQuery = $replaceStart
            $spView.Query = $completedQuery
            $spView.Update()
        }
        # Check if we have no sorts but a single filter
        elseif ($existingQuery.Contains("<Where>")) {
            write-host "No sorts and a single filter exists."
            # Build the updated query; we need to append And tags
            $updatedQuery="<Where><And><Gt><FieldRef Name='Created' /><Value Type='DateTime'><Today OffsetDays='-365' /></Value></Gt>"
            # Replace <Where> with our <Where><And> query
            $replaceStart = $existingQuery.Replace("<Where>", $updatedQuery)
            # Update closing tags
            $replaceEnd = $replaceStart.Replace("</Where>", "</And></Where>")
            # Write the finished query
            $completedQuery = $replaceEnd
            $spView.Query = $completedQuery
            $spView.Update()
        }
    } # End something exists
    # No existing queries, so just write the filter and be done with it
    else {
        write-host "No sorts and no filters exists."
        $createFilter = "<Where><Gt><FieldRef Name='Created' /><Value Type='DateTime'><Today OffsetDays='-365' /></Value></Gt></Where>"
        $spView.Query = $createFilter
        $spView.Update() # Write the new filter
    }

    #http://sharepoint.stackexchange.com/questions/16839/sharepoint-2010-add-filter-to-a-list-with-powershell

    # Set row limit
    #$setRowLimitTo = $siteViewLimit # do we still need this? Likly needs updating

    # Set column indexing, if any
    if ($indexOn) {
        write-host "Setting column indexing..."
        DisableThreshold $list $spWeb # Disable view threshold so we can set index
        $spField = $list.Fields[$indexOn]
        $spField.Indexed = $true
        $spField.Update() # Update the field to index on
        EnableThreshold $list $spWeb # Index set, turn the threshold back on
        write-host "Done!"
    }
    # Finish and clean up
    $spView.Update() # Make sure all pending view updates were written
    $list.Update() # Make sure all pending list updates were written
    Write-Host ("View '" + $spView.Title + "' updated in list '" + $list.Title + "' on site " + $spWeb.Url)
    $spWeb.Dispose() # Close the connection to SharePoint
} # End of function
function DisableThreshold($list,$web)
{
    [Microsoft.SharePoint.Utilities.SPUtility]::ValidateFormDigest()
    $list.EnableThrottling = $False
    $list.Update()
    
    echo $list.EnableThrottling
    $web.Update()
}
function EnableThreshold($list,$web)
{
    [Microsoft.SharePoint.Utilities.SPUtility]::ValidateFormDigest()
    $list.EnableThrottling = $True
    $list.Update()
    
    echo $list.EnableThrottling
    $web.Update()
}
processCSVFile $myCSVFile # Call the main processing function
write-host "All done! See Ya!"
# END OF FILE