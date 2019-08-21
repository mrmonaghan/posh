[CmdletBinding()]
param (
    [Parameter(Mandatory)]
        [string]$TargetServer

)

$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

##Pulls a list of SAMAccountNames from the file you provide, checks for them in $FilePath, and deletes them
$UserArray = @(Invoke-Command -ComputerName $TargetServer -ScriptBlock {Get-ADUser -Filter {Enabled -ne $true} | Select SamAccountName})
$FilePath = "C:\Users"

Foreach ($User in $UserArray) {
    Get-ChildItem -Path $FilePath | Where-Object {$_.Name -eq $User} | Remove-Item -Force -confirm
    }



                  