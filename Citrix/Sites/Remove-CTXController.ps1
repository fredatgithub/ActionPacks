﻿#Requires -Version 5.0

<#
    .SYNOPSIS
        Removes a Delivery Controller from an existing Site
    
    .DESCRIPTION  

    .NOTES
        This PowerShell script was developed and optimized for ScriptRunner. The use of the scripts requires ScriptRunner. 
        The customer or user is authorized to copy the script from the repository and use them in ScriptRunner. 
        The terms of use for ScriptRunner do not apply to this script. In particular, ScriptRunner Software GmbH assumes no liability for the function, 
        the use and the consequences of the use of this freely available script.
        PowerShell is a product of Microsoft Corporation. ScriptRunner is a product of ScriptRunner Software GmbH.
        © ScriptRunner Software GmbH

    .COMPONENT
        Requires the library script CitrixLibrary.ps1
        Requires PSSnapIn Citrix*

    .LINK
        https://github.com/scriptrunner/ActionPacks/blob/master/Citrix/Sites
        
    .Parameter SiteServer
        [sr-en] Specifies the address of a XenDesktop controller. 
        This can be provided as a host name or an IP address
        [sr-de] Name oder IP Adresse des XenDesktop Controllers

    .Parameter ControllerName
        [sr-en] Name of the controller
        [sr-de] Name der Controller
    
    .Parameter DBCredentials
        [sr-en] Credentials, that will be used to connect to the SQL Server
        [sr-de] Benutzerkonto des SQL Servers
    
    .Parameter SiteDatabaseCredentials
        [sr-en] Credentials, to connect to the SQL Server associated with the Configuration Site Database
        [sr-de] Benutzerkonto des SQL Servers der Site Datenbank
    
    .Parameter LoggingDatabaseCredentials
        [sr-en] Credentials, to connect to the SQL Server associated with the Configuration Logging Database
        [sr-de] Benutzerkonto des SQL Servers der Logging Datenbank
    
    .Parameter MonitorDatabaseCredentials
        [sr-en] Credentials, to connect to the SQL Server associated with the Configuration Monitor Database
        [sr-de] Benutzerkonto des SQL Servers der Monitor Datenbank
    
    .Parameter RemoveServiceInstanceRegistration
        [sr-en] Removes a service instance from the Configuration Service registry
        [sr-de] Entfernt die Service Instanz Registrierung

    .Parameter DoNotUpdateDatabaseServer
        [sr-en] Results in the permissions associated with the Controller not being automatically removed from the Database
        [sr-de] Berechtigungen werden nicht automatisch von der Datenbank entfernt 
#>

param( 
    [Parameter(Mandatory =$true, ParameterSetName = 'Default')]
    [Parameter(Mandatory =$true, ParameterSetName = 'WithCredentials')]
    [Parameter(Mandatory =$true, ParameterSetName = 'UniqueCredentials')]
    [string]$ControllerName,  
    [Parameter(Mandatory =$true, ParameterSetName = 'WithCredentials')]
    [pscredential]$DBCredentials,     
    [Parameter(Mandatory =$true, ParameterSetName = 'UniqueCredentials')]
    [pscredential]$SiteDatabaseCredentials,    
    [Parameter(Mandatory =$true, ParameterSetName = 'UniqueCredentials')]
    [pscredential]$LoggingDatabaseCredentials,    
    [Parameter(Mandatory =$true, ParameterSetName = 'UniqueCredentials')]
    [pscredential]$MonitorDatabaseCredentials,    
    [Parameter(ParameterSetName = 'Default')]
    [Parameter(ParameterSetName = 'WithCredentials')]
    [Parameter(ParameterSetName = 'UniqueCredentials')]
    [string]$SiteServer,
    [Parameter(ParameterSetName = 'Default')]
    [Parameter(ParameterSetName = 'WithCredentials')]
    [Parameter(ParameterSetName = 'UniqueCredentials')]
    [switch]$RemoveServiceInstanceRegistration ,
    [Parameter(ParameterSetName = 'Default')]
    [switch]$DoNotUpdateDatabaseServer 
)                                                            

try{ 
    StartCitrixSessionAdv -ServerName ([ref]$SiteServer)

    [hashtable]$cmdArgs = @{'ErrorAction' = 'Stop'
                            'AdminAddress' = $SiteServer
                            'ControllerName' = $ControllerName
                            }    

    if($PSCmdlet.ParameterSetName -eq 'Default'){
        if($DoNotUpdateDatabaseServer.IsPresent -eq $true){
            $cmdArgs.Add('DoNotUpdateDatabaseServer',$DoNotUpdateDatabaseServer)
        }
    }
    elseif($PSCmdlet.ParameterSetName -eq 'WithCredentials'){
        $cmdArgs.Add('DatabaseCredentials',$DBCredentials)
    }
    elseif($PSCmdlet.ParameterSetName -eq 'UniqueCredentials'){
        $cmdArgs.Add('SiteDatabaseCredentials',$SiteDatabaseCredentials)
        $cmdArgs.Add('LoggingDatabaseCredentials',$LoggingDatabaseCredentials)
        $cmdArgs.Add('MonitorDatabaseCredentials',$MonitorDatabaseCredentials)
    }

    if($RemoveServiceInstanceRegistration -eq $true){
        $myDcs = Get-BrokerController -AdminAddress $SiteServer 
        foreach($dc in $myDcs.DNSName){
            if($dc -like "$($ControllerName)*" ){
                Get-ConfigRegisteredServiceInstance -AdminAddress $SiteServer -ServiceAccountSid $dc.Sid | Unregister-ConfigRegisteredServiceInstance
                break
            }
        }
      #  
    }
    $null = Remove-XDController @cmdArgs
    $ret = Get-BrokerController -AdminAddress $SiteServer
    if($SRXEnv) {
        $SRXEnv.ResultMessage = $ret
    }
    else{
        Write-Output $ret
    }
}
catch{
    throw 
}
finally{
    CloseCitrixSession
}