#Find VM across multiple vCenters, get information where a VM exactly is in the hierarchy

Write-Host "`nvCenter VM Search Script"
Write-Host "Please enter your credentials to connect to both vCenters"
$username = Read-Host "Username"
$response = Read-Host "Password" -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($response))

Try{
    Write-Host "Connecting to exampleVIServer..."
    Connect-VIServer -Server exampleVIServer -User $username -Password $password -ErrorAction Stop 

    Write-Host "Connecting to exampleVIServer..."
    Connect-VIServer -Server exampleVIServer -User $username -Password $password -ErrorAction Stop 
    Write-Host ""
}
Catch{
    Write-Host "`nThere was an issue connecting to one or both of the vCenters, please check connectivity or ability to authenticate"
    Exit
}

Function FindVM {
    $targetVMInfo = New-Object PSObject
    Write-Host "Press Ctrl+C to exit script at any time"
    $inputVM = Read-Host "Enter Target VM"
    Try {
        Get-VM $inputVM -ErrorAction Stop | Out-Null
    }
    Catch {
        Write-Host "`nTarget VM could not be found"
    FindVM 
    }
    $targetVM = Get-VM $inputVM 
    $targetVMInfo | Add-Member -MemberType NoteProperty -Name "VM Name" -Value $($targetVM.Name)
    $targetVMInfo | Add-Member -MemberType NoteProperty -Name "Datacenter Name" -Value $($targetVM | Get-DataCenter)
    $targetVMInfo | Add-Member -MemberType NoteProperty -Name "Cluster Name" -Value $(($targetVM | Get-Cluster).Name)
    $targetVMInfo | Add-Member -MemberType NoteProperty -Name "Host Name" -Value $(($targetVM | Get-VMHost).Name)
    $targetVMInfo | Format-Table -AutoSize
    FindVM 
}

FindVM