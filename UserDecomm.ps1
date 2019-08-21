#########################################################################################################
##Before beginning, place a .csv with the user's or users' full name in a NAME column at the root of C:##
#########################################################################################################

#AD Variables
$Csv = Import-CSV C:\Users.csv
$userlist = $Csv.name
$disabled = get-adgroup "<ENTER USER GROUP HERE>" -Properties @("primaryGroupToken")
$TargetOU = "<ENTER TARGET OU HERE>"


###ACTIVE DIRECTORY FUNCTIONS###

#Disable the User
foreach ($User in $userlist) {
    Get-AdUser -Filter {Name -eq $user} | Disable-ADAccount
}

#Set user City field to DISABLED
foreach ($User in $userlist) {
    Get-AdUser -Filter {Name -eq $user} | Set-ADUser -City "DISABLED"
}

#Add User to group specified in $disabled variable
foreach ($User in $userlist) {
    Get-AdUser -Filter {Name -eq $user} | Add-ADPrincipalGroupMembership -MemberOf $disabled
}

#Set user primary group to $disabled
foreach ($User in $userlist) {
    Get-AdUser -Filter {Name -eq $user} | Set-ADUser -Replace @{primaryGroupID=$disabled.primaryGroupToken}
}


#Remove user from all other groups. Primary group is automatically skipped.
foreach ($User in $userlist) {
    Get-AdUser -Filter {Name -eq $user} -Properties Memberof | ForEach-Object {
    $_.MemberOf | Remove-ADGroupMember -Members $_.DistinguishedName -Confirm:$false
    }
}

#Move User to Inactive Users OU
foreach ($User in $userlist) {
   Get-AdUser -Filter {Name -eq $user} | Move-ADObject -Targetpath $TargetOU
}
#Create Exchange.Online Session
function Connect-O365 {
$office365Credential = Get-Credential
$global:office365= New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $office365Credential  -Authentication Basic   –AllowRedirection
Import-PSSession $office365
}

#Start O365 PS-Remote Session
Connect-O365
Connect-MsolService -Credential $office365Credential

##EXCHANGE ONLINE VARIABLES##
$Users = $Csv.name
$mailboxes = Get-Mailbox | Get-MailboxStatistics | where-object {$Users -eq $_.DisplayName}
$Under = @()
$Over = @()

#Get user mailboxes and sort into $Over or $Under based on TotalItemSize parameter
foreach ($mailbox in $mailboxes) {
    if ((($mailbox.TotalItemSize | Select-String -Pattern '(?<=\()\S+').matches.value -as [Double]) -lt 16mb) {
        $Under += $mailbox
        }
    else {
    $Over += $mailbox
   }
 }

#Convert all mailboxes in $Under to Shared
$under.displayname | Set-Mailbox -Type Shared

#Export $Over to CSV to Review Later
$Over | Select-Object DisplayName,TotalItemSize | Export-Csv C:\Over50GB.csv

##MSONLINE VARIABLES##
$UnderUPN = $Under.displayName | Get-Mailbox | Select-Object Name
$domain = '<DOMAIN>'
$SKUType = '<O365 SKU NAME>'
$domainFull = '<FULL DOMAIN>'

#Find O365 Accounts based on UPN and remove licenses from any on the $Under list
foreach ($UPN in $UnderUPN) {
$UserAccountUPN = $Upn.Name + $domainFull
$AccountSkuID = $domain + ':' + $SKUType
Get-MsolUser -UserPrincipalName $UserAccountUPN | Set-MSolUserLicense -RemoveLicenses $AccountSkuID
}

