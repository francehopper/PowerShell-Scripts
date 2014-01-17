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
        write-host "keywordsArray now contains $keywordsArray" -foregroundcolor "Gray" #debug 
    }
    #processSitesList $mySitesList $keywordsArray
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
        write-host "libsArray now contains $libsArray" -foregroundcolor "Gray" #debug
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
        write-host "Keywords are: $keywordsArray" -foregroundcolor "Gray" #debug
        write-host "libraries are: $libsArray" -foregroundcolor "Gray" #debug
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
    # Build what we need to write to the page
    $content = '"<%@ Register TagPrefix="WpNs1" Namespace="Microsoft.SharePoint.Portal.WebControls" Assembly="Microsoft.SharePoint.Portal, Version=12.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"%>
<%@ Register TagPrefix="WpNs0" Namespace="AERotatorWebpart" Assembly="AERotatorWebpart, Version=1.0.0.0, Culture=neutral, PublicKeyToken=8db6b6736dcbda89"%>
<%-- _lcid="1033" _version="12.0.4518" _dal="1" --%>
<%-- _LocalBinding --%>
<%@ Page language="C#" MasterPageFile="~masterurl/default.master"    Inherits="Microsoft.SharePoint.WebPartPages.WebPartPage,Microsoft.SharePoint,Version=12.0.0.0,Culture=neutral,PublicKeyToken=71e9bce111e9429c" meta:progid="SharePoint.WebPartPage.Document" %>
<%@ Register Tagprefix="SharePoint" Namespace="Microsoft.SharePoint.WebControls" Assembly="Microsoft.SharePoint, Version=12.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> <%@ Register Tagprefix="Utilities" Namespace="Microsoft.SharePoint.Utilities" Assembly="Microsoft.SharePoint, Version=12.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> <%@ Import Namespace="Microsoft.SharePoint" %> <%@ Register Tagprefix="WebPartPages" Namespace="Microsoft.SharePoint.WebPartPages" Assembly="Microsoft.SharePoint, Version=12.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %>"'
    # Start a counter we'll use for an array position later
    $currentItemNo = 0
    # Open a connection to SharePoint
    write-host "Connecting to $siteURL..." -foregroundcolor "Yellow"
    $spWeb = Get-SPWeb $siteURL
    write-host "Value of spWeb is $spWeb" -foregroundcolor "Gray" #debug
    # Get the contents of the libraries
    foreach ($library in $libsArray) {
        write-host "Working on $library in libsArray..." -foregroundcolor "Gray" #debug
        $curLib = $spWeb.Lists[$library]
        write-host "Current library list is $curLib." -foregroundcolor "Gray" #debug
        $libItems = $curLib.items
        # Check each item for each of the keywords
        foreach ($item in $libItems) {
            write-host "Current item is $($item.Title)." -foregroundcolor "Gray" #debug
            # Step through each keyword
            foreach ($keyword in $keywordsArray) {
                write-host "Current keyword is $keyword" -foregroundcolor "Gray" #debug
                write-host "Building search for item $($item.Title)..." -foregroundcolor "Yellow"
                # Build the regx search
                $search = GetRegxPattern $keyword
                #write-host "Search is $search" -foregroundcolor "Gray"
                write-host "Search is $search" -foregroundcolor "Gray" #debug
                write-host "Checking keywords..." -foregroundcolor "Yellow"
                # Get the number of items in the list
                $totalListItems = $curLib.Items.Count
                write-host "There are $totalListItems items in $curLib" -ForegroundColor "Magenta" #debug
                # Arrays start at zero so...
                $itemsToProcess = $totalListItems - 1
                write-host "Processing array position $currentItemNo" -ForegroundColor "DarkRed" #debug
                # Get the contents of the current page
                $reader = new-object System.IO.StreamReader($curLib.Items[$currentItemNo].File.OpenBinaryStream())
                $str = $reader.ReadToEnd()
                write-host "Page content is $str" -foregroundcolor "White" #debug
                # Search the page for our keyword
                if ($str -match $search) {
                    write-host "Matched on keyword $search" -foregroundcolor "Magenta"
                    # Keyword was found in the page, check it out for editing
                    # write-host "Checking out page..." -foregroundcolor "Yellow"
                    # $item.File.CheckOut()
                    # # Replace the keyword with the new content
                    # write-host "Replacing content..." -foregroundcolor "Yellow"
                    # $item["Page Content"] = $item["Page Content"].replace($search, $content)
                    # # Write the updated page
                    # write-host "Writing update..." -foregroundcolor "Yellow"
                    # $item.Update()
                    # # Check the page in
                    # write-host "Checking in..." -foregroundcolor "Yellow"
                    # $item.File.CheckIn()
                    # # Publish the page
                    # write-host "Publishing..." -foregroundcolor "Yellow"
                    # $item.File.Publish()
                    # # Approve the page changes
                    # write-host "Approving..." -foregroundcolor "Yellow"
                    # $item.File.Approve()
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
    
# Eventually, end function
    # Get pages list
        # Loop through list of pages
    # Get the page
    #$pweb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($SPWeb)
    #$pages = $pweb.GetPublishingPages($pweb)
    


    # # Process each keyword
    # foreach ($keyword in $keywordsArray) {
    #     $search = GetRegxPattern $keyword
    #     # Check the page for each keyword
    #     if ($page.PageContent -match $search) {
    #         # Checkout the page
    #         $item.File.CheckOut()
    #         # Replace the page content
    #         $item["Page Content"] = $item["Page Content"].replace($search, $content)
    #         # Write the update
    #         $item.Update()
    #         # Check the page back in
    #         $item.File.CheckIn()
    #         # Publish it
    #         $item.File.Publish()
    #         # Approve it
    #         $item.File.Approve()
    #     }
    # }

    # === Old crap to remove ===
    # Page contains our search
    

    # Get the page to check for issues

    # Get the page as a string?
    # Looks like we can just do a content search instead
    #if ($bla["Page Content"].contains($search))

    # Check if the page has the keyword

    # Page has the keyword
        # Checkout the page for editing
        #$bla.CheckOut

        # Replace the keyword with the fix

        # Write the update

        # Check the item back in
        #$bla.CheckIn()


    # Open a connection to SP and fetch the list to work on
    #$spWeb = Get-SPWeb $siteURL # Connect to SharePoint
    #$spList = $spWeb.Lists[$siteList]

    # Open a connection to the web
#     $web = New-Object System.Net.WebClient
#     #$web.UseDefaultCredentials=$true
#     # Feed the stupid proxy our creds to get out to the web
#     $web.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
#     # Dunno why this is needed; Google said to have it
#     $web | Get-Member

#     # Fetch our site as a string
#     $siteAsString = $web.DownloadString($siteUrl)
#     # What we'll be replacing with?
#     $content = '"<%@ Register TagPrefix="WpNs1" Namespace="Microsoft.SharePoint.Portal.WebControls" Assembly="Microsoft.SharePoint.Portal, Version=12.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"%>
# <%@ Register TagPrefix="WpNs0" Namespace="AERotatorWebpart" Assembly="AERotatorWebpart, Version=1.0.0.0, Culture=neutral, PublicKeyToken=8db6b6736dcbda89"%>
# <%-- _lcid="1033" _version="12.0.4518" _dal="1" --%>
# <%-- _LocalBinding --%>
# <%@ Page language="C#" MasterPageFile="~masterurl/default.master"    Inherits="Microsoft.SharePoint.WebPartPages.WebPartPage,Microsoft.SharePoint,Version=12.0.0.0,Culture=neutral,PublicKeyToken=71e9bce111e9429c" meta:progid="SharePoint.WebPartPage.Document" %>
# <%@ Register Tagprefix="SharePoint" Namespace="Microsoft.SharePoint.WebControls" Assembly="Microsoft.SharePoint, Version=12.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> <%@ Register Tagprefix="Utilities" Namespace="Microsoft.SharePoint.Utilities" Assembly="Microsoft.SharePoint, Version=12.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %> <%@ Import Namespace="Microsoft.SharePoint" %> <%@ Register Tagprefix="WebPartPages" Namespace="Microsoft.SharePoint.WebPartPages" Assembly="Microsoft.SharePoint, Version=12.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %>"'

#     # What we need to replace
#     $keyword = "AERotatorWebpart"
#     # Assuming this is what we want
#     if ($siteAsString -match $keyword) {
#         # Build the pattern to replace
#         $pattern = GetRegxPattern $keyword
#         # Replace the bad string or something
#         $replaced = [System.Text.RegularExpressions.Regex]::Replace($content, $pattern , "")
#     }
}
processKeywordsList $myKeywordsList $myLibsList $mySitesList
write-host "All done! See Ya!" -foregroundcolor "Green"
# END OF FILE