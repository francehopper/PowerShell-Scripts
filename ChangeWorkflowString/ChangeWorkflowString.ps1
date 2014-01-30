# Get workflow text files
$path = Split-Path -Path $MyInvocation.MyCommand.Path
$theSource = get-content "$path\source.txt"
$theTarget = get-content "$path\target.txt"
# Strip line breaks from files
$theSource = [System.Text.RegularExpressions.Regex]::Replace($theSource.Replace("\t",""), "\t\n|\r", "")
$theTarget = [System.Text.RegularExpressions.Regex]::Replace($theTarget.Replace("\t",""), "\t\n|\r", "")
# --- BEGIN Reviewers > Approvers ---
# Build search pattern
$reviewers = "<my:Reviewers>(.*)</my:Reviewers>" #DON'T DELETE!
# Perform match
$matchReviewers = [System.Text.RegularExpressions.Regex]::Matches($theSource, $reviewers) #DON'T DELETE!
# Replace my tags with pc tags
$updatedReviewers = $matchReviewers | %{$_.Groups[1].value.Replace("my:","pc:")} #DON'T DELETE!
write-host "Updated Reviewers: $updatedReviewers" #debug
# --- BEGIN CC > CC ---
# Build search pattern
$oldCC = "<my:CC>(.*)</my:CC>" #DON'T DELETE!
# Perform match
$matchOldCC = [System.Text.RegularExpressions.Regex]::Matches($theSource, $oldCC) #DON'T DELETE!
# Replace my tags with pc tags
$updatedCC = $matchOldCC | %{$_.Groups[1].value.Replace("my:","pc:")} #DON'T DELETE!
write-host "Updated CC: $updatedCC" #debug
# --- BEGIN DueDate > DueDateForAllTasks ---
$dueDate = "<my:DueDate xsi:nil=`"true`">(.*)</my:DueDate>" # Build search
$matchDueDate = [System.Text.RegularExpressions.Regex]::Matches($theSource, $dueDate) # Do match
$updatedDueDate = $matchDueDate | %{$_.Groups[1].value} # No replacements needed, so just grab the value
write-host "Updated due date: $updatedDueDate" #debug
# --- BEGIN Description > NotificationMessage
$description = "<my:Description>(.*)</my:Description>" # Build search
$matchDescription = [System.Text.RegularExpressions.Regex]::Matches($theSource, $description) # Do match
$updatedDescription = $matchDescription | %{$_.Groups[1].value} # No replacements needed, so just grab the value
write-host "Updated Description: $updatedDescription" #debug
# --- BEGIN StopOnAnyReject > CancelonRejection ---
$StopOnAnyReject = "<my:StopOnAnyReject>(.*)</my:StopOnAnyReject>" # Build search
$matchSOAR = [System.Text.RegularExpressions.Regex]::Matches($theSource, $StopOnAnyReject) # Do match
$updatedSOAR = $matchSOAR | %{$_.Groups[1].value} # No replacements needed, so just grab the value
write-host "Updated SOAR: $updatedSOAR" #debug
# --- BEGIN ItemChangeStop > CancelonChange ---
$ItemChangeStop = "<my:ItemChangeStop>(.*)</my:ItemChangeStop>" # Build search
$matchICS = [System.Text.RegularExpressions.Regex]::Matches($theSource, $ItemChangeStop) # Do match
$updatedICS = $matchICS | %{$_.Groups[1].value} # No replacements needed, so just grab the value
write-host "Updated ICS: $updatedICS" #debug
# --- BEGIN TimePerTaskVal > DurationforSerialTasks ---
$TimePerTaskVal = "<my:TimePerTaskVal>(.*)</my:TimePerTaskVal>" # Build search
$matchTime = [System.Text.RegularExpressions.Regex]::Matches($theSource, $TimePerTaskVal) # Do match
$updatedTime = $matchTime | %{$_.Groups[1].value} # No replacements needed, so just grab the value
write-host "Updated Time: $updatedTime" #debug
# --- BEGIN DefaultTaskType > DurationUnits ---
$defaultTaskType = "<my:DefaultTaskType>(.*)</my:DefaultTaskType>" # Build search
$matchType = [System.Text.RegularExpressions.Regex]::Matches($theSource, $defaultTaskType) # Do match
# Calculate replacement value
$updatedType = ""
switch($matchType.Groups[1].Value){
    "1"{$updatedType = "Day"}
    "2"{$updatedType = "Week"}
}
write-host "Updated Type: $updatedType" #debug
# --- Do Replacements ---
# Update Reviewers > Approvers
$targetstring = [System.Text.RegularExpressions.Regex]::Replace((Get-Content "$path\target.txt"), "\t\n|\r", "")
[System.Text.RegularExpressions.Regex]::Replace($targetstring, "<d:Assignee>(.*)</d:Assignee>", "<d:Assignee>$updatedReviewers</d:Assignee>") | Set-Content "$path\target.txt"
# Update CC
$targetstring = [System.Text.RegularExpressions.Regex]::Replace((Get-Content "$path\target.txt"), "\t\n|\r", "")
[System.Text.RegularExpressions.Regex]::Replace($targetstring, "<d:CC>(.*)</d:CC>", "<d:CC>$updatedCC</d:CC>") | Set-Content "$path\target.txt"
# Update DueDate
$targetstring = [System.Text.RegularExpressions.Regex]::Replace((Get-Content "$path\target.txt"), "\t\n|\r", "")
[System.Text.RegularExpressions.Regex]::Replace($targetstring, "<d:DueDateforAllTasks>(.*)</d:DueDateforAllTasks>", "<d:DueDateforAllTasks>$updatedDueDate</d:DueDateforAllTasks>") | Set-Content "$path\target.txt"
# Update Description
$targetstring = [System.Text.RegularExpressions.Regex]::Replace((Get-Content "$path\target.txt"), "\t\n|\r", "")
[System.Text.RegularExpressions.Regex]::Replace($targetstring, "<d:NotificationMessage>(.*)</d:NotificationMessage>", "<d:NotificationMessage>$updatedDescription</d:NotificationMessage>") | Set-Content "$path\target.txt"
# Update StopOnAnyReject
$targetstring = [System.Text.RegularExpressions.Regex]::Replace((Get-Content "$path\target.txt"), "\t\n|\r", "")
[System.Text.RegularExpressions.Regex]::Replace($targetstring, "<d:CancelonRejection>(.*)</d:CancelonRejection>", "<d:CancelonRejection>$updatedSOAR</d:CancelonRejection>") | Set-Content "$path\target.txt"
# Update ItemChangeStop
$targetstring = [System.Text.RegularExpressions.Regex]::Replace((Get-Content "$path\target.txt"), "\t\n|\r", "")
[System.Text.RegularExpressions.Regex]::Replace($targetstring, "<d:CancelonChange>(.*)</d:CancelonChange>", "<d:CancelonChange>$updatedICS</d:CancelonChange>") | Set-Content "$path\target.txt"
# Update TimePerTaskVal
$targetstring = [System.Text.RegularExpressions.Regex]::Replace((Get-Content "$path\target.txt"), "\t\n|\r", "")
[System.Text.RegularExpressions.Regex]::Replace($targetstring, "<d:DurationforSerialTasks>(.*)</d:DurationforSerialTasks>", "<d:DurationforSerialTasks>$updatedTime</d:DurationforSerialTasks>") | Set-Content "$path\target.txt"
# Update DefaultTaskType
$targetstring = [System.Text.RegularExpressions.Regex]::Replace((Get-Content "$path\target.txt"), "\t\n|\r", "")
[System.Text.RegularExpressions.Regex]::Replace($targetstring, "<d:DurationUnits>(.*)</d:DurationUnits>", "<d:DurationUnits>$updatedType</d:DurationUnits>") | Set-Content "$path\target.txt"
# END OF FILE