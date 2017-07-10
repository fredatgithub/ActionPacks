﻿#Requires -Modules ActiveDirectory

<#
    .SYNOPSIS
         Gets the properties of the Active Directory account
    
    .DESCRIPTION

    .Parameter Username
        Display name, SAMAccountName, DistinguishedName or user principal name of Active Directory account

    .Parameter DomainAccount
        Active Directory Credential for remote execution without CredSSP
    
    .Parameter Properties
        List of properties to expand. Use * for all properties

    .Parameter DomainName
        Name of Active Directory Domain
    
    .Parameter AuthType
        Specifies the authentication method to use
#>

param(
    [Parameter(Mandatory = $true,ParameterSetName = "Local or Remote DC")]
    [Parameter(Mandatory = $true,ParameterSetName = "Remote Jumphost")]
    [string]$Username,
    [Parameter(Mandatory = $true,ParameterSetName = "Remote Jumphost")]
    [PSCredential]$DomainAccount,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [string[]]$Properties="Name,GivenName,Surname,DisplayName,Description,Office,EmailAddress,OfficePhone,Title,Department,Company,Street,PostalCode,City,SAMAccountName",
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [string]$DomainName,
    [Parameter(ParameterSetName = "Local or Remote DC")]
    [Parameter(ParameterSetName = "Remote Jumphost")]
    [ValidateSet('Basic', 'Negotiate')]
    [string]$AuthType="Negotiate"
)

Import-Module ActiveDirectory

#Clear
$ErrorActionPreference='Stop'

$Script:User
if($PSCmdlet.ParameterSetName  -eq "Remote Jumphost"){
    if([System.String]::IsNullOrWhiteSpace($DomainName)){
        $Domain = Get-ADDomain -Current LocalComputer -AuthType $AuthType -Credential $DomainAccount
    }
    else{
        $Domain = Get-ADDomain -Identity $DomainName -AuthType $AuthType -Credential $DomainAccount
    }
    $Script:User= Get-ADUser -Server $Domain.PDCEmulator -Credential $DomainAccount -AuthType $AuthType `
        -Filter {(SamAccountName -eq $Username) -or (DisplayName -eq $Username) -or (DistinguishedName -eq $Username) -or (UserPrincipalName -eq $Username)} -Properties *
}
else{
    if([System.String]::IsNullOrWhiteSpace($DomainName)){
        $Domain = Get-ADDomain -Current LocalComputer -AuthType $AuthType 
    }
    else{
        $Domain = Get-ADDomain -Identity $DomainName -AuthType $AuthType 
    }
    $Script:User= Get-ADUser -Server $Domain.PDCEmulator -AuthType $AuthType `
        -Filter {(SamAccountName -eq $Username) -or (DisplayName -eq $Username) -or (DistinguishedName -eq $Username) -or (UserPrincipalName -eq $Username)} -Properties *
}
if($null -ne $Script:User){
    $resultMessage = New-Object System.Collections.Specialized.OrderedDictionary
    if($Properties -eq '*'){
        foreach($itm in $Script:User.PropertyNames){
            if($null -ne $Script:User[$itm].Value){
                $resultMessage.Add($itm,$Script:User[$itm].Value)
            }
        }
    }
    else {
        foreach($itm in $Properties.Split(',')){
            $resultMessage.Add($itm,$Script:User[$itm.Trim()].Value)
        }
    }
    if($SRXEnv) {
        $SRXEnv.ResultMessage = $resultMessage  | Format-Table -HideTableHeaders -AutoSize
    }
    else{
        Write-Output $resultMessage | Format-Table -HideTableHeaders -AutoSize
    }
}
else{
    if($SRXEnv) {
        $SRXEnv.ResultMessage = "User $($Username) not found"
    }    
    Write-Error "User $($Username) not found"
}