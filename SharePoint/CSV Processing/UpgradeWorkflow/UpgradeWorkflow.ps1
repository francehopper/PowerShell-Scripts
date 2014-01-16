$myCSVFile = $args[0] # get the passed file
Add-PSSnapin Microsoft.SharePoint.PowerShell # load the SharePoint module

# Read the CSV file
function processCSV ($myCSVFile) {
    $file = Import-csv $myCSVFile # open the file
    foreach ($item in $file) {
        $siteURL = $item."ParentWeb" # get the site
        write-host $siteURL
        $siteList = $item."ListName" # get the name of the list with the wf in need of upgrade
        write-host $siteList
        $siteWfTemplate = $item."WorkflowType" # get the template type
        write-host $siteWfTemplate
        $siteWfName = $item."WorkflowName" # get the name for the Workflow
        write-host $siteWfName
        # Upgrade the workflows
        write-host "Upgrading the workflows for $siteURL..."
        upgradeWorkflows $siteURL $siteList $siteWfName $siteWfTemplate
        write-host "Done!"
    }
}

function upgradeWorkflows ($siteURL, $siteList, $siteWfName, $siteWfTemplate) {
    # Get the site
    $web = Get-SPWeb $siteURL
    # Get required lists
    $list = $web.Lists[$siteList]
    $taskList = $web.Lists["Workflow Tasks"]
    $workflowHistoryList = $web.Lists["Workflow History"]

    Write-Host "Upgrading $siteWfName on list $siteList on site $siteURL..."

    # Build the name of the new Workflow
    $newWorkflowName = $siteWfName + " Upgraded"

    # Determine the template to use
    if ($siteWfTemplate -eq "Approval") {
        $templateToUse = "Approval - SharePoint 2010"
    }
    elseif ($siteWfTemplate -eq "Collect Feedback") {
        $templateToUse = "Collect Feedback - SharePoint 2010"
    }
    elseif ($siteWfTemplate -eq "Collect Signatures") {
        $templateToUse = "Collect Signatures - SharePoint 2010"
    }
    else {
        write-host "A non-standard template or no template was selected for $siteWfName on list $siteList on site $siteURL."
        write-host "Impossible to automatically upgrade this workflow."
    }

    # Calculate the basetemplate
    $culture = Get-Culture
    $basetemplate = $web.WorkflowTemplates.GetTemplateByName($templateToUse,$culture);

    # Build the Workflow
    $newWorkflow=[Microsoft.SharePoint.Workflow.SPWorkflowAssociation]::CreateListAssociation($basetemplate, $newWorkflowName, $taskList, $workflowHistoryList)  

    # Add the workflow and clean up
    $list.AddWorkflowAssociation($newWorkflow)
    $list.Update()
    $web.Dispose()

}

processCSV $myCSVFile # call the main processing function
write-host "All done! See Ya!"
# END OF FILE