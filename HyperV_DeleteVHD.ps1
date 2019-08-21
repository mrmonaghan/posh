$VerbosePreference="Continue"
$VMArray = @()
$DelPath = "C:\Users\Public\Documents\Hyper-V\Virtual hard disks"
$GetVHD = Get-ChildItem $DelPath | Select-Object Name

$GetVHD | Format-Table

do {
$input = (Read-Host "Please enter the name of the VHD you wish to delete")
if ($input -ne '') {$VMArray += $input}
}
until ($input -eq '')

foreach ($VHD in $VMArray) {
	if ($GetVHD | Where-Object {$_.name -match $VHD}) {
		Get-ChildItem $DelPath | Where-Object {$_.name -match $VHD} | Remove-Item -Force -confirm
		Write-Verbose "Delete successful!"
		}
	else {
	 Write-Verbose "No files that contain the string '$VHD' found."
	}
}