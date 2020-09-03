# Can be run as a scheduled task, monitors a network path, if .dat file is found, we automatically disable account based on user information in .dat file. Send email for notification.

# Get the path 
$monitorDirectory = Get-ChildItem -Path "\\someserver\peoplesoft\hrproduction\hr\outbound\powershell_ad"

Foreach ($item in $monitorDirectory){
    $itemAttribute = $item.Attributes
    $itemName = $item.Name
    $itemFullName = $item.FullName
    $itemDirectory = $item.DirectoryName
    $archiveDirectory = "$itemDirectory\archive"

    # Check if it's a directory
    If ($itemAttribute -eq "Directory"){
        Continue
    }

    # Check if the file extension is .dat, if it is, find the user
    If ($itemName -match ".dat"){
        $userInfo = Import-CSV $itemFullName
        $userLastDate = "$($userInfo.LAST_DATE_WORKED) 17:00:00"
        
        $cleanEmployeeIdentifier = $itemName -replace ".dat"
        $adUser = Get-ADUser -Filter {employeeidentifier -like $cleanEmployeeIdentifier} -Properties employeeidentifier
        $adDN = $adUser.DistinguishedName

        # If user is found, perform actions
        If ($adUser){
            Write-Host "`nSetting Expiration Date for $($adUser.Name)"
            Set-ADAccountExpiration -Identity $adDN -DateTime $userLastDate
            Write-Host "`nMoving $($adUser.Name) .dat file to 'archive' folder"

            $date = Get-Date
            $year = $date.Year
            $month = "{0:D2}" -f ($date.Month)
            $day = "{0:D2}" -f ($date.Day)
            $hour = "{0:D2}" -f $($date.Hour)
            $minute = "{0:D2}" -f $($date.Minute)
            $second = "{0:D2}" -f $($date.Second)
            $yyyymmdd = "$year" + "$month" + "$day" 
            $fullDate = "$year" + "$month" + "$day" + "$hour" + "$minute" + "$second"

            Move-Item $itemFullName "$($archiveDirectory)\$($fullDate).$($itemName)"
            
            # Name of the report (used in targeting the path for D:\Logs and D:\Reports)
            #$reportName = "MonitorOffboardFolder"

            # Email subject with the date in yyyymmdd format
            $reportNameEmail = "Active Directory Deactivation Notice - $($adUser.employeeidentifier) (Informational)"

            # Set up and send email with attachment
            $From = "AUTOMATION_Offboard@somedomain.com"
            #$To = "debug@somedomain.com"
            $To = "HR@somedomain.com"
            $Bcc = "debug@somedomain.com"
            $Subject = "$reportNameEmail"
            $Body = "Employee ID $($adUser.employeeidentifier) ($($adUser.GivenName) $($adUser.Surname) - $($adUser.Name)) was set to expire on $userLastDate. If you wanted to change the expiration date, please save the employee record with the new date.

Do not reply to this email. Please contact the Service Desk at 1-234-567-8901.

Thank you.

***NOTICE*** The information contained in this e-mail must be treated as confidential in accordance with... Any dissemination or reproduction of this e-mail or the information contained herein is prohibited unless a specific determination has been made that the recipient has a valid business requirement for the information."

            $SMTPServer = "smtpserver.somedomain.com"

            Write-Host "`nSending Report..."
            Send-MailMessage -From $From -to $To -Bcc $Bcc -Subject $Subject `
            -Body $Body -SmtpServer $SMTPServer 

            $cleanScriptName = ""
            $rawScriptName = $PSCommandPath -match "[^\\]+(?=\.ps1$)"
            If($rawScriptName){$cleanScriptName = "$($matches[0]).ps1"}

            $cleanScriptPath = "$PSScriptRoot\"

            $psObject = New-Object -TypeName PSObject -Property (@{"DateTimeLogged" = "$(Get-Date)";
            "ActionRequestedBy" = "AUTO";
            "ActionTaken" = "Employee ID $($adUser.employeeidentifier) ($($adUser.GivenName) $($adUser.Surname) - $($adUser.Name)) was set to expire on $userLastDate";
            "ScriptServiceAcct" = "$([Environment]::UserName)";
            "ScriptServer" = "$(hostname)";
            "ScriptPath" = "$cleanScriptPath";
            "ScriptName" = "$($cleanScriptName)";
            "ScriptPurpose" = "Personnel Offboarding";
            "ScriptForDept" = "Human Resources";
            "ScriptRecovery" = "Re-enable $($adUser) account"})

            $log = $psObject | ConvertTo-Json -Compress

            $log | Out-File "$PSScriptRoot\Logs\$($fullDate).$($adUser.employeeidentifier).json"

        }

    }
    
}

