<#
 .Synopsis
  Copies Active Directory group membership from one user to another.

 .Description
  Copies Active Directory group membership from one user to another. Also logs errors
  into a toggleable ShowError list

 .Parameter From
  Selects the user to copy groups from.

 .Parameter ShowErrors
  Displays any errors encountered at the end of the cmdlet

 .Example
   # Copy permissions from UserA to UserB
   Copy-ADUserPermissions -From UserA -To UserB

 .Example
   # Copy permissions from UserA to UserB and display errors
   Copy-ADUserPermissions -From UserA -To UserB -ShowErrors
#>
Function Copy-ADUserPermissons {
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory)]
        [object]$From,

        [Parameter(Mandatory)]
        [object]$To,

        [Parameter()]
        [switch]$ShowErrors

    )

    begin {
        $SourceGroups = Get-ADPrincipalGroupMembership $From
        $TargetUser = Get-ADUser $To
        $ErrorArray = New-Object System.Collections.Generic.List[System.Object]
        }
    process {
        foreach ($Group in $SourceGroups) {
            try {
                Add-ADGroupMember -Identity $Group -Member $TargetUser
            }
            catch {
                $ErrorArray.Add($Error)
            }
        }
    }
    end {
        $Results = Get-ADPrincipalGroupMembership $TargetUser | Select-Object -ExpandProperty Name
        $Username = $TargetUser.Name
        Write-Host "$Username's new group membership:"
        Write-Output $Results
        if ($PSBoundParameters.ContainsKey('ShowErrors')) {
            Write-Error $ErrorArray
        }
    }
}