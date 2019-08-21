[CmdletBinding()]
Param ()

#Logging Configuration Options
$Date = Get-Date -Format MM-dd-yyyy
$ScriptName = $MyInvocation.MyCommand.Name
$FilePath = "C:\Scripts\Logs\$ScriptName\$Date.txt"

#Begins transcription
Start-Transcript -Path $FilePath -Append
"$Date run of script beginning..."

#Set Path for Data, global preferences
$Data = Import-CSV C:\Storage\Files\Users.csv
$ErrorActionPreference = "Continue"
$VerbosePreference = "Continue"

$Results = @()

foreach ($User in $data) {
    $UserResult = [PSCustomObject] @{
        UPN = $null
        Password = $null
        Status = $null
        Reason = $null
       }
    $UPN = ($User.FirstName[0]+$User.Surname.replace(' ',''))
    if (!(Get-ADUser -Filter {samaccountname -eq $UPN})) {

        $PasswordGen = (([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9 | sort-object {Get-Random})[0..8] -join '') + "Z"
        $Password = ConvertTo-SecureString -String $PasswordGen -AsPlainText -Force
        Write-Host "Creating user $UPN..." -ForegroundColor Green
        $UserParams = @{
            DisplayName = ($User.FirstName + " " + $User.surname)
            Name = ($User.FirstName + " " + $User.surname)
            UserPrincipalName = $UPN + '@domain.local'
            SamAccountName = $UPN
            GivenName = $User.FirstName
            Surname = $user.Surname
            Title = $User.Department
            Enabled = $true
            AccountPassword = $Password
            ChangePasswordAtLogon = $true
            }
        New-AdUser @UserParams
        $UserResult.UPN = $UPN
        $UserResult.Password = $PasswordGen
        $UserResult.Status = "Success!"
        }
    else {
        Write-Host "User $UPN already exists!" -ForegroundColor Red
        $UserResult.UPN = $UPN
        $UserResult.Status = "Failure"
        $UserResult.Reason = "UPN $UPN already exists."
      }
$Results += $UserResult
}

$Results

#The End!
"Script complete! Logs found at $FilePath"
"$Date run of script ended."
Stop-Transcript
