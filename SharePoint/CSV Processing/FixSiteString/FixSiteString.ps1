# Get csvs with content
$myKeywordsList = $args[0] # Get the list of keywords to work with
$myLibsList = $args[1] # Get the list of libraries to work with
$mySitesList = $args[2] # Get the list of sites to work with
# Load the SharePoint module
Add-PSSnapin Microsoft.SharePoint.PowerShell
# Process the list of keywords
function processKeywordsList ($myKeywordsList, $myLibsList, $mySitesList) {
    $file = Import-csv $myKeywordsList # Open the file
    write-host "Getting list of keywords..." -foregroundcolor "Yellow"
    $keywordsArray = @()
    foreach ($item in $file) { # Loop through the contents of the csv file
        # Things we need to fetch
        $siteKeywords = $item."keywords" # Get list of keywords
        # Add keywords to array
        $keywordsArray = $keywordsArray + $siteKeywords
    }
    write-host "Done!" -foregroundcolor "DarkGreen"
    processLibrariesList $myLibsList $keywordsArray $mySitesList
}
# Process list of page libraries
function processLibrariesList ($myLibsList, $keywordsArray, $mySitesList) {
    $file = Import-csv $myLibsList # Open the file
    write-host "Getting list of page libraries..." -foregroundcolor "Yellow"
    $libsArray = @()
    foreach ($item in $file) { # Loop through the contents of the csv file
        # Things we need to fetch
        $siteLibs = $item."lib" # Get list of libraries
        # Add libraries to array
        $libsArray = $libsArray + $siteLibs
    }
    write-host "Done!" -foregroundcolor "DarkGreen"
    processSitesList $mySitesList $keywordsArray $libsArray
}
# Process the list of sites
function processSitesList ($mySitesList, $keywordsArray, $libsArray) {
    $file = Import-csv $mySitesList # Open the file
    write-host "Beginning to update pages..." -foregroundcolor "Yellow"
    foreach ($item in $file) { # Loop through the contents of the csv file
        # Things we need to fetch
        $siteURL = $item."siteURL" # Get the site
        # Fix the pages
        write-host "Updating $siteURL..." -foregroundcolor "Gray"
        fixString $siteURL $keywordsArray $libsArray
        write-host "Done!" -foregroundcolor "DarkGreen"
    }
    write-host "Updating complete." -foregroundcolor "DarkGreen"
}
# end csv processing functions
function GetRegxPattern($keyword) {
    return "<%@(.*)$keyword(.*)%>"
}
# main processing function
function fixString ($siteURL, $keywordsArray, $libsArray) {
    # Start a counter we'll use for an array position later
    $currentItemNo = 0
    # Open a connection to SharePoint
    write-host "Connecting to $siteURL..." -foregroundcolor "Yellow"
    $spWeb = Get-SPWeb $siteURL
    # Get the contents of the libraries
    foreach ($library in $libsArray) {
        $curLib = $spWeb.Lists[$library]
        $libItems = $curLib.items
        # Check each item for each of the keywords
        foreach ($item in $libItems) {
            # Step through each keyword
            foreach ($keyword in $keywordsArray) {
                write-host "Building search for item $($item.Title)..." -foregroundcolor "Yellow"
                # Build the regx search
                $search = GetRegxPattern $keyword
                write-host "Checking keywords..." -foregroundcolor "Yellow"
                # Get the number of items in the list
                $totalListItems = $curLib.Items.Count
                # Arrays start at zero so...
                $itemsToProcess = $totalListItems - 1
                # Get the contents of the current page
                $reader = new-object System.IO.StreamReader($curLib.Items[$currentItemNo].File.OpenBinaryStream())
                $str = $reader.ReadToEnd()
                # Search the page for our keyword
                if ($str -match $search) {
                    write-host "Matched on keyword $search" -foregroundcolor "Magenta"
                    # Keyword was found in the page, check it out for editing
                    write-host "Checking out page..." -foregroundcolor "Yellow"
                    $item.File.CheckOut()
                    # Replace the keyword with the new content
                    write-host "Replacing content..." -foregroundcolor "Yellow"
                    $newPageContent = [System.Text.RegularExpressions.Regex]::Replace($str, $search , "")
                    # Write the updated page
                    write-host "Writing update..." -foregroundcolor "Yellow"
                    $item.File.SaveBinary([System.Text.Encoding]::ASCII.GetBytes($newPageContent)) 
                    $item.File.Update()
                    # Check the page in
                    write-host "Checking in..." -foregroundcolor "Yellow"
                    $item.File.CheckIn("")
                    # Publish the page
                    write-host "Publishing..." -foregroundcolor "Yellow"
                    $item.File.Publish("")
                    # Approve the page changes
                    #write-host "Approving..." -foregroundcolor "Yellow"
                    #$item.File.Approve("")
                    write-host "Reticulating splines..." -foregroundcolor "Yellow" # For fun
                    # Next keyword
                    write-host "Done!" -foregroundcolor "DarkGreen"
                } # End keyword found actions
                else {
                    write-host "Keyword $search was not found on $($item.Title)." -foregroundcolor "Red"
                }
            } # End keyword checks
            # Done checking the item for all keywords, increase the array position of the current item so we read the contents of the right item
            $currentItemNo = $currentItemNo + 1
        } # End items loop
    } # End library loop
} # End of function!
processKeywordsList $myKeywordsList $myLibsList $mySitesList
write-host "All done! See Ya!" -foregroundcolor "Green"
# END OF FILE