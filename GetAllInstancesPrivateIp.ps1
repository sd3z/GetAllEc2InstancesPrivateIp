$globalObjs = @()


if($regions -eq $null) { $regions = (Get-AWSRegion).Region }
if($creds -eq $null) { $creds = (Get-AWSCredentials -ProfileLocation $profile_location -ListProfileDetail).ProfileName }


foreach ($cred in $creds) {
    foreach ($region in $regions) {
    $instances =  Get-EC2Instance -ProfileName $cred -region  $region  `
             |%{ $_.RunningInstance } `
             | Select-Object InstanceId,PublicDnsName,PrivateIpAddress,@{Name='TagValues'; Expression={($_.Tag |%{ $_.Value }) -join ','}}

    foreach ($instance in $instances) {    
           if($vpc.IsDefault -ne "True") {
                $funcObj = New-Object System.Object
                $funcObj | Add-Member -type NoteProperty -Name PrivateIpAddress -Value $instance.PrivateIpAddress
                $funcObj | Add-Member -type NoteProperty -Name InstanceId -Value $instance.InstanceId
                $funcObj | Add-Member -type NoteProperty -Name PublicDnsName -Value $instance.PublicDnsName
                $funcObj | Add-Member -type NoteProperty -Name TagValues -Value $instance.TagValues
                $funcObj | Add-Member -type NoteProperty -Name Test -Value (Test-Connection -Count 1 $instance.PrivateIpAddress -Quiet -TimeToLive 5)
                $funcObj | Add-Member -type NoteProperty -Name Account -Value $cred
                $funcObj | Add-Member -type NoteProperty -Name Region -Value $region
                $globalObjs += $funcObj
                write-host $funcObj.KeyName
                }
    }
    }
}


$globalObjs | ConvertTo-Csv -Delimiter ','
