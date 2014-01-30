$path = Split-Path -Path $MyInvocation.MyCommand.Path
$LogPath = "$path\Logs\Log-$(Get-Date -format yyyyMMdd-hhmmss).txt"
Start-Transcript -path $LogPath
$myCSVFile = $args[0] # get the passed file
# Read the CSV file
function processCSV ($myCSVFile) {
    $sitesToStrip = @()
    $file = Import-csv $myCSVFile # open the file
    foreach ($item in $file) {
        $siteURL = $item."site" # get the site
        stripURL $siteUrl
    }
}
function stripURL ($SiteURL) {
    $replaceURL = $siteURL.replace("Lists", "\")
    $splitURL = $replaceURL.Split("\")
    $procSite = $splitURL[0]
    $procSite | out-default
}
processCSV $myCSVFile # call the main processing function
write-host "All done! See Ya!"
stop-transcript
# END OF FILE