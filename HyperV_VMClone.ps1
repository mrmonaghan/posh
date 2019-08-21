#GLOBAL VARIABLES#
$VerbosePreference="Continue"
$ErrorActionPreference='stop'

#Logging Configuration Options
$Date = Get-Date -Format MM-dd-yyyy
$ScriptName = $MyInvocation.MyCommand.Name
$FilePath = "C:\Scripts\Logs\$ScriptName\$Date.txt"

#Begins transcription
Start-Transcript -Path $FilePath -Append
Write-Host "$Date run of script beginning..."

#SET PATHS HERE
$VMName = Read-Host Enter VM Name
$TemplatePath = "C:\Storage\VHDX\Template.vhdx"
$DestPath = "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\$VMName.vhdx"

#Reboots VM with Confirmation, waits 1 hour for IP Address before continuing
function Restart-VMUnattended {
	Restart-VM -Name $VMName -Wait -For IPAddress -Timeout 3600 -Force
}

#Copy Template VHD defined on line 7 to Path defined on line 8
Write-Verbose "Copying $TemplatePath..."
Get-Item $TemplatePath | Copy-Item -Destination $DestPath
Write-Verbose "Copy completed successfully!"

#Parameters for new VM
$VM = @{
	Name = $VMName
	MemoryStartupBytes = 512MB
	Generation = 2
	VHDPath = $DestPath
	BootDevice = "VHD"
	Path = "C:\ProgramData\Microsoft\Windows\Hyper-V"
	SwitchName = "Internal01"
}

#Create VM using above parameters with confirmation
Write-Verbose "Create new machine with the following parameters?"
$VM
New-VM @VM -Confirm
Write-Verbose "$VMName creation complete!"

#Start newly-created VM
Write-Verbose "Starting VM..."
Start-VM $VMname
Write-Verbose "Done!"

#Set delay to allow for VM to boot to OS
Write-Host "Waiting for connection (20s delay)..."
Start-Sleep -Seconds 20

#Create PSObject for service account credentials
Write-Host "Passing service account credentials..."
$secpasswd = ConvertTo-SecureString "<PASSWORD>" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("<ACCT_NAME>", $secpasswd)

#Remotely invoke sysprep, sleeps script until sysprep.exe has exited on the VM.
Write-Verbose "Starting Sysprep to generate new SID. This will likely take a few minutes."
Invoke-Command -VMName $VMName -Credential $mycreds -ScriptBlock {
    $process = Start-Process -FilePath "C:\Windows\System32\sysprep\sysprep.exe" -ArgumentList '/generalize /oobe /quit' -Passthru

    do {Start-Sleep -Seconds 1 }
     until ($Process.HasExited)
}
Write-Verbose "Sysprep complete!"

#Reboot VM following sysprep
Write-Verbose "Restarting VM. This will take several minutes following a Sysprep."
Restart-VMUnattended
Write-Verbose "Restart complete!"

#Rename VM's ComputerName
Write-Verbose "Setting ComputerName to $VMName..."
Invoke-Command -VMName $VMName -Credential $mycreds -ScriptBlock {Rename-Computer $using:VMName}
Write-Verbose "Done!"

#Reboot VM to apply new name
Write-Verbose "Restarting VM to apply new name..."
Restart-VMUnattended
Write-Verbose "Restart complete!"

#Create PSObject to pass credentials with permissions to add computer to domain. Also defines domain string
$domainpasswd = ConvertTo-SecureString "<PASSWORD>" -AsPlainText -Force
$domaincreds = New-Object System.Management.Automation.PSCredential ("<ACCT_NAME>", $domainpasswd)
$Domain = "domain.local"

#Add VM to $Domain defined on line 79.
Write-Verbose "Adding computer to $Domain..."
Invoke-Command -VMName $VMName -Credential $mycreds -ScriptBlock {Add-Computer -DomainName $using:domain -Credential $using:domaincreds}
Write-Verbose "Domain join complete!"

#Reboot machine following domain join.
Write-Verbose "Restarting VM to complete configuration..."
Restart-VMUnattended
Write-Verbose "Restart complete!"

#The End!
Write-Verbose "Script complete! Logs found at $FilePath"
Write-Verbose "$Date run of script ended."
Stop-Transcript
