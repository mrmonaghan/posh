<#
 .Synopsis
  Copies Active Directory group membership from a user to one or more other users.

 .Description
  Copies Active Directory group membership from a user to one or more other users.

 .Parameter From
  Selects the user to copy group membership from.

 .Parameter To
  Selects the user or users to apply copied group membership to.

 .Example
   # Copy permissions from UserA to UserB
   Copy-ADUserPermissions -From UserA -To UserB

 .Example
   # Copy permissions from UserA to UserB and UserC
   Copy-ADUserPermissions -From UserA -To UserB, UserC
#>
Function Copy-ADUserPermissons {
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory)]
        [object]$From,

        [Parameter(Mandatory)]
        [object]$To

    )

    begin {
        $SourceGroups = Get-ADPrincipalGroupMembership $From
        $TargetUsersArray = New-Object System.Collections.Generic.List[System.Object]
        $ResultsArray = New-Object System.Collections.Generic.List[System.Object]
        foreach ($User in $To) {
            $TargetUsersArray.Add((Get-ADUser $User))
        }

    }
    process {
        foreach ($Group in $SourceGroups) {
            Add-ADGroupMember -Identity $Group -Members $TargetUsersArray
        }

    }
    end {
        foreach ($User in $TargetUsersArray) {
            $UserResultObject = [PSCustomObject]@{
                UPN = $User.SamAccountName
                Status = $null
            }
            $TargetUserGroupMembership = Get-ADPrincipalGroupMembership $User
            $Comparison = Compare-Object -ReferenceObject $SourceGroups -DifferenceObject $TargetUserGroupMembership
            if (!($Comparison)) {
                $UserResultObject.Status = 'Complete'
                }
            else {$UserResultObject.Status = 'Failed'}
            $ResultsArray.Add($UserResultObject)
        }
        Write-Output $ResultsArray
    }
}
