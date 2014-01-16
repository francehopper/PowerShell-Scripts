function Get-LocalLogonInformation
{
    try
    {
        $ADSystemInfo = New-Object -ComObject ADSystemInfo
        $type = $ADSystemInfo.GetType()

        New-Object -TypeName PSObject -Property @{
            UserDistinguishedName = $type.InvokeMember('UserName','GetProperty',$null,$ADSystemInfo,$null)
            ComputerDistinguishedName = $type.InvokeMember('ComputerName','GetProperty',$null,$ADSystemInfo,$null)
            SiteName = $type.InvokeMember('SiteName','GetProperty',$null,$ADSystemInfo,$null)
            DomainShortName = $type.InvokeMember('DomainShortName','GetProperty',$null,$ADSystemInfo,$null)
            DomainDNSName = $type.InvokeMember('DomainDNSName','GetProperty',$null,$ADSystemInfo,$null)
            ForestDNSName = $type.InvokeMember('ForestDNSName','GetProperty',$null,$ADSystemInfo,$null)
            PDCRoleOwnerDistinguishedName = $type.InvokeMember('PDCRoleOwner','GetProperty',$null,$ADSystemInfo,$null)
            SchemaRoleOwnerDistinguishedName = $type.InvokeMember('SchemaRoleOwner','GetProperty',$null,$ADSystemInfo,$null)
            IsNativeModeDomain = $type.InvokeMember('IsNativeMode','GetProperty',$null,$ADSystemInfo,$null)
        }
    }
    catch
    {
        throw
    }
}

Get-LocalLogonInformation