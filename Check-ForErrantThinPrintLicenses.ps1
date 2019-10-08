Import-Module TPPowershell,ActiveDirectory
$TpURL = 'http:<TP-URL-HERE>'
$DCName = '<DC-NAME-HERE>'
Write-Host -F Yellow "Enter ThinPrint Credentials:"
Connect-TP -TPUrl $TpURL

Write-Host "Building List of ThinPrint Users..."
$TPUserList = Get-TPUser
$DisabledADUserRaw = Invoke-Command -ComputerName $DCName -ScriptBlock {Get-AdUser -Filter * | Where-Object {$_.Enabled -ne $True}}
Write-Host "Building List of Disabled AD Users..."
$DisabledADUserNames = $DisabledADUserRaw.Name
$RawResultsList = New-Object System.Collections.Generic.List[System.Object]

Write-Host "Compiling list of Enabled ThinPrint users..."
foreach ($User in $TPUserList) {
    $ResultObject = [pscustomobject]@{
        Displayname = $User.DisplayName
        Enabled = $null
        }
    $EnabledResult = Get-TPUserSettings -UserID $User.UserID | Where-Object {$_.UserEnabled -eq "True"} | Select -ExpandProperty UserEnabled
    $ResultObject.Enabled = $EnabledResult
    $RawResultsList.Add($ResultObject)
    }
$FilteredResultsList = $RawResultsList | Where-Object {$_.Enabled -ne $null}
$FinalResultsList = $FilteredResultsList.DisplayName

Write-Host "Comparing ThinPrint Licenses and Disabled AD Users"
$Output = Compare-Object -ReferenceObject $FinalResultsList -DifferenceObject $DisabledADUserNames -IncludeEqual -ExcludeDifferent

Write-Host -F Yellow "The following users have disabled AD Object and active licenses in ThinPrint:"
$Output.InputObject

