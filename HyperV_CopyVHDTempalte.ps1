$VerbosePreference="Continue"
$VMName = Read-Host Enter VM Name:
$TemplatePath = "C:\Users\Administrator\Downloads\Templates\DC\Virtual Hard Disks\Template.vhdx"
$DestPath = "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\$VMName.vhdx"

Write-Verbose "Copying $TemplatePath..."
Get-Item $TemplatePath | Copy-Item -Destination $DestPath
Write-Verbose "VHD copy completed successfully! You may now manually select your new VHD from the Hyper-V MMC."