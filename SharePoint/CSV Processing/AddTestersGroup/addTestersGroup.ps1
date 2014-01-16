$myCSVFile = $args[0] # get the passed file
Add-PSSnapin Microsoft.SharePoint.PowerShell # load the SharePoint module

function processCSV ($myCSVFile) {
    $file = Import-csv $myCSVFile # open the file
    $sites = @()
    $testers = @()
    foreach ($item in $file) {
        $siteURL = $item."site" # get the site
        $sites += $siteURL
        $testerUsername = $item."username" # get the list
        $testers += $testerUsername
    }
    # build the groups
        write-host "Building..."
        buildGroup $sites $testers
        write-host "Done!"
}

function buildGroup ($sites, $testers) {
	# Get the site to set groups on
	foreach ($site in $sites) {
        write-host "Building group for $site..."
		$web = Get-SPWeb $site

		# Build the Testers group
		$web.SiteGroups.Add("$web Testers", $web.Site.Owner, $web.Site.Owner, "This group grants full permissions to users for the $web site for the purposes of UAT Testing.")
		$testersGroup = $web.SiteGroups["$web Testers"]
		$testersGroup.AllowMembersEditMembership = $true
		$testersGroup.Update()

		# Add users to group
		#domain\username

		foreach ($tester in $testers) {
			write-host "Adding $tester to the $site Testers group..."
            #$user = $web.Site.RootWeb.EnsureUser($tester)
			#$testersGroup.AddUser($user)
            write-host "Added $tester."
		}

		# Create a new assignment (group and permission level pair) which will be added to the web object
		$testersGroupAssignment = new-object Microsoft.SharePoint.SPRoleAssignment($testersGroup)

		# Get permission level to apply
		$testerRoleDefinition = $web.Site.RootWeb.RoleDefinitions["Full Control"]

		# Assign permission level
		$testersGroupAssignment.RoleDefinitionBindings.Add($testerRoleDefinition)

		# Add group to site
		$web.RoleAssignments.Add($testersGroupAssignment)

		# Update the site and clean up
		$web.Update()
		$web.Dispose()
	}
}

processCSV $myCSVFile # call the main processing function
write-host "All done! See Ya!"
# END OF FILE