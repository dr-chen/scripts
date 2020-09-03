# Need to give correct permissions to Service Account
# Finds any expired user, disables user in Active Directory just in case, generates log

Function GetNumericFullDate {
    $currentDate = Get-Date
    $numericYear = $currentDate.Year
    $numericMonth = "{0:D2}" -f ($currentDate.Month)
    $numericDay = "{0:D2}" -f ($currentDate.Day)
    $numericHour = "{0:D2}" -f ($currentDate.Hour)
    $numericMinute = "{0:D2}" -f ($currentDate.Minute)
    $numericSecond = "{0:D2}" -f ($currentDate.Second)

    $numericFullDate = "$numericYear" + "$numericMonth" + "$numericDay"
    $numericFullDateTime = "$numericYear" + "$numericMonth" + "$numericDay" + "$numericHour" + "$numericMinute" + "$numericSecond" 
    $numericFullDateTime 
}

Function NewJSONLog ($adUser) {
    $cleanScriptName = ""
    $rawScriptName = $PSCommandPath -match "[^\\]+(?=\.ps1$)"
    If($rawScriptName){$cleanScriptName = "$($matches[0]).ps1"}

    $cleanScriptPath = "$PSScriptRoot\"
    
    $numericFullDateTime = GetNumericFullDate 

    $psObject = New-Object -TypeName PSObject -Property (@{"DateTimeLogged" = "$(Get-Date)";
    "ActionRequestedBy" = "AUTO";
    "ActionTaken" = "Employee ID $($adUser.EmployeeNumber) ($($adUser.GivenName) $($adUser.Surname) - $($adUser.Name)) was set to expire on $userLastDate";
    "ScriptServiceAcct" = "$([Environment]::UserName)";
    "ScriptServer" = "$(hostname)";
    "ScriptPath" = "$cleanScriptPath";
    "ScriptName" = "$($cleanScriptName)";
    "ScriptPurpose" = "Personnel Offboarding";
    "ScriptForDept" = "Human Resources";
    "ScriptRecovery" = "Re-enable $($adUser) account"})

    $log = $psObject | ConvertTo-Json -Compress

    $log | Out-File "$PSScriptRoot\Logs\$($numericFullDateTime).$($adUser.EmployeeNumber).json"
}

$allADUsers = Get-ADUser -Filter * -Properties AccountExpirationDate, extensionAttribute11

# Go through all users, check expiration date and legal hold status. If Legal hold, place in special OU, otherwise place in Archive
Foreach ($user in $allADUsers){
    $currentDate = Get-Date
    $userDN = $user.DistinguishedName
    $userEnabled = $user.Enabled
    $userExpirationDate = $user.AccountExpirationDate
    $userLegalHold = $user.extensionAttribute11

    If ($userExpirationDate){
        $7DaysAfterExpiration = $userExpirationDate.AddDays(7)
        If ($7DaysAfterExpiration -lt $currentDate){
            If ($userEnabled){
                Disable-ADAccount $userDN
                If ($userLegalHold){
                    Move-ADObject -Identity $userDN -TargetPath "OU=SpecialOU,OU=Archive,DC=SomeDomain,DC=Com"
                    "Legal"
                    $userDN
                    $userExpirationDate
                    $7DaysAfterExpiration
                    "$($user.SamAccountName)"
                }
                Else {
                    Move-ADObject -Identity $userDN -TargetPath "OU=Users,OU=Archive,DC=SomeDomain,DC=Com"
                    $userDN
                    $userExpirationDate
                    $7DaysAfterExpiration
                    "$($user.SamAccountName)"
                }
                NewJSONLog $user
            }
        }
    }
}