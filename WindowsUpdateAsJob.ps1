#GLOBAL VARIABLES. NO TOUCHY.
$Jobs = @()
$VerbosePreference = "Continue"

#Target Machines
$ServerGroup = "Domain Servers"
$Host = Read-Host 'Enter Name of VM Host'
$Servers = Get-ADGroupMember $ServerGroup | Select-Object -ExpandProperty Name | Out-GridView -Passthru -Title "Select Servers to Update"

#Logging Configuration Options
$Date = Get-Date -Format MM-dd-yyyy
$ScriptName = $MyInvocation.MyCommand.Name
$FilePath = "C:\Scripts\Logs\$ScriptName\$Date.txt"

#Begins transcription
Start-Transcript -Path $FilePath -Append
Write-Host "$Date run of script beginning..."

#region Functions

function Send-SESEmail {
[CmdletBinding()]

Param(
    [Parameter(Mandatory)]
    [string]$To,

    [Parameter(Mandatory)]
    [String]$Subject,

    [Parameter(Mandatory)]
    $Body,

    [Parameter()]
    [String]$Attachment


    )

begin {
    $AWSSMTPUsername = "<USERNAME>"
    $AWSSMTPSecret = "<SECRET_KEY>"


    $SECURE_KEY = $(ConvertTo-SecureString -AsPlainText -String $AWSSMTPSecret -Force)
    $creds = $(New-Object System.Management.Automation.PSCredential ($AWSSMTPUsername, $SECURE_KEY))

    $Params = @{
        To = $To
        From = "<FROM_ADDRESS>"
        Subject = $Subject
        Body = $Body
        SmtpServer = "<AWS_SES_URL>"
        Credential = $Creds
        Port = 587
        UseSSL = $True
        }
}

process {
    if ($Attachment) {
        $Params.Attachments = $Attachment
        }
    }

end {
    Send-MailMessage @Params
    }
}

#Check the status of the PSWindowsUpdate module and prompt for installation if it is not detected
function Get-PSWindowsUpdateStatus {
    if (!(Get-InstalledModule "PSWindowsUpdate" -ErrorAction Ignore)) {
        Write-Host "PSWindowsUpdate is not installed on $env:COMPUTERNAME. Would you like to proceed with installation?"
        Install-Module -Name "PSWindowsUpdate" -AllowClobber -Force -Confirm
        Write-Host "PSWindowsUpdate has been installed on $env:COMPUTERNAME. Proceeding..."
         }
    else {
        Write-Host "PSWindowsUpdate is installed and up-to-date on $env:COMPUTERNAME. Proceeding..."
         }
}

#Check for, download, and install Windows Updates. Prevents automatic reboot.
function Get-AllUpdates {
    Invoke-WUJob -Script {Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot | Out-File C:\PSWindowsUpdate.log} -RunNow -confirm:$False
    }

#endregion Functions

#Checks status of PSWindowsUpdate module on all machines provided in $Servers
foreach ($server in $Servers) {
     Invoke-Command -ComputerName $Server -ScriptBlock ${function:Get-PSWindowsUpdateStatus}
}

#Runs Get-AllUpdates function on all machines listed in $Servers as a job
foreach ($server in $Servers) {
     $Jobs += (Invoke-Command -ComputerName $Server -ScriptBlock ${function:Get-AllUpdates})
     Write-Host "Job beginning on $Server"
}

#Monitor the status of the Scheduled Tasks created by Invoke-WUJob cmdlet, add results to $RunTasks and $CompleteTasks. Refresh every 5 seconds until all tasks are out of Running state.
$runtime = 0
DO{
    $runtime++
    $Elapsed = $runtime*5
    Write-Host "Starting loop $runtime. Elapsed time $Elapsed seconds" -F Yellow
    $TaskStatus = Invoke-Command -ComputerName $Servers -ScriptBlock {Get-ScheduledTask -TaskName "PSWindowsUpdate"}
    Write-Host "Checking Task Status..."
    $RunTask = $TaskStatus | Where-Object {$_.state -eq "Running" -or $_.state -eq "4"}
    $CompleteTask = $TaskStatus | Where-Object {$_.state -eq "Ready" -or $_.state -eq "3"}

    "WAITING ON:"
    $RunTask | Select-Object PSComputerName,Description,State

    Write-Host "Refreshing..."
    Start-Sleep -seconds 5
    }
UNTIL ($TaskStatus.state -notcontains "Running" -and $TaskStatus.state -notcontains "4" )

#Pauses script and prompts user to review the results of $Jobs before proceeding with a keypress
Write-Host "PLEASE REVIEW THE ABOVE INFORMATION AND CONFIRM IT IS CORRECT BEFORE PROCEEDING"
$CompleteTask | Format-Table
Send-SESEmail -To mmonaghan@nextdigital.ca -Subject 'Updates Complete, Reboot Pending' -Body 'Please press Enter on the script host to continue'
pause

$RebootServers = $CompleteTask.PSComputername | Out-GridView -Passthru -Title "Select Servers to Reboot"

Write-Host "Rebooting $RebootServers"
Invoke-Command -ComputerName $Host -ScriptBlock {$using:RebootServers | Restart-VM -Force -Confirm -Wait -For IPAddress}
Write-Host "Reboot Complete!"

$CompiledLogs = @()

foreach ($server in $Servers) {
    Write-Host "Retrieving logs from " + $Server
    $CompiledLogs += Invoke-Command -ComputerName $Server -ScriptBlock {Get-Content C:\PSWindowsUpdate.log}
    Write-Host "Done!"
    }
Write-Host "Compiling logs..."
$CompiledLogs | Out-File C:\CompiledLogs.log
Write-Host "Done! See C:\CompiledLogs.log for details."
Write-Host "$Date run of script ended."
Stop-Transcript