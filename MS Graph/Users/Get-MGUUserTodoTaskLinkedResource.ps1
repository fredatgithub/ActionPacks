﻿#Requires -Version 5.0
#requires -Modules Microsoft.Graph.Users

<#
    .SYNOPSIS
        Read the properties and relationships of a linkedResource object
    
    .DESCRIPTION          

    .NOTES
        This PowerShell script was developed and optimized for ScriptRunner. The use of the scripts requires ScriptRunner. 
        The customer or user is authorized to copy the script from the repository and use them in ScriptRunner. 
        The terms of use for ScriptRunner do not apply to this script. In particular, ScriptRunner Software GmbH assumes no liability for the function, 
        the use and the consequences of the use of this freely available script.
        PowerShell is a product of Microsoft Corporation. ScriptRunner is a product of ScriptRunner Software GmbH.
        © ScriptRunner Software GmbH

    .COMPONENT
        Requires Library script MS Graph\_LIB_\MGLibrary
        Requires Modules Microsoft.Graph.Users

    .LINK
        https://github.com/scriptrunner/ActionPacks/tree/master/MS%20Graph/Users

    .Parameter UserId
        [sr-en] User identifier
        [sr-de] Benutzer ID

    .Parameter TodoTaskListId 
        [sr-en] Id of todo task list
        [sr-de] Todo-Tasklist ID

    .Parameter TodoTaskId 
        [sr-en] Id of todo task
        [sr-de] Task ID

    .Parameter LinkedResourceId 
        [sr-en] Unique identifier of linkedResource
        [sr-de] Ressourcen ID
#>

param( 
    [Parameter(Mandatory = $true)]
    [string]$UserId,
    [Parameter(Mandatory = $true)]
    [string]$TodoTaskListId,
    [Parameter(Mandatory = $true)]
    [string]$TodoTaskId,
    [string]$LinkedResourceId 
)

Import-Module Microsoft.Graph.Users

try{
    ConnectMSGraph 
    [hashtable]$cmdArgs = @{ErrorAction = 'Stop'
                'UserId' = $UserId
                'TodoTaskListId' = $TodoTaskListId
                'TodoTaskId' = $TodoTaskId
    }
    if($PSBoundParameters.ContainsKey('LinkedResourceId') -eq $false){
        $cmdArgs.Add('All',$null)
    }
    else{
        $cmdArgs.Add('LinkedResourceId',$LinkedResourceId)
    }
    $result = Get-MgUserTodoTaskLinkedResource @cmdArgs | Sort-Object ApplicationName
    
    if($SRXEnv) {
        $SRXEnv.ResultMessage = $result
    }
    else{
        Write-Output $result
    }    
}
catch{
    throw 
}
finally{
    DisconnectMSGraph
}