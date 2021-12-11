#Install the PowerShell Azure AD Module.
#Install-Module AzureAD -force

#Check that the AzureAD Powershell Module has been installed successfully 
#Get-InstalledModule

#module can be actually used
#Get-Module -Listavailable

# nivshemer@gmail.com AzureCloud  ******************************
#Connect-AzureAD
#get-azureaddomain
#Connect-AzureAD -TenantId {YOUR_TENANT_ID}


#install the Azure AD PowerShell module
#install-module azuread
#import-module azuread

#Check that the module is ready to use
#get-module azuread
if (Get-Module -ListAvailable -Name AzureAD) {
    Write-Log  "Module exists"
} 
else {
    Write-Log  "Module does not exist, installing azuread"
    install-module azuread
    import-module azuread
}
#New session 
#Connect-AzureAD

#Retrieve existing groups from AD
#get-azureadgroup

#creates a new security group
#New-AzureADGroup -Description "Marketing" -DisplayName "Marketing" -MailEnabled $false -SecurityEnabled $true -MailNickName "Marketing"

#Filter groups
#Get-AzureADGroup -Filter "DisplayName eq 'Varonis Assignment Group'"
#Write-Log -Message "iteration end" 

function Write-Log { 
    param ( 
        [string]$Message
    ) 
            
    $logFile = "$Env:programdata\logs\log.log"
    try 
    { 
        if((test-path $logFile))
        {
            if(Select-String -Path $logFile -Pattern "End of iteration")
            {
                $hour = (Get-Date -Format 'HH.mm.ss') 
                Rename-Item -Path $logFile -NewName "log_$hour.log"
            }
        }
        else
        {
            if(!(Test-Path -Path "$Env:programdata\logs" ))
            {
                New-Item -ItemType directory -Path "$Env:programdata\logs"  -ErrorAction SilentlyContinue -Verbose 
            }
        }
        $DateTime = Get-Date -Format 'MM/dd/yy HH:mm:ss'        
        [System.IO.File]::AppendAllText($logFile, "$DateTime - $Message" + [System.Environment]::NewLine)
        
        #Replplaced with [System.IO.File] because some issue that the log file was in use
		Add-Content -Value "$DateTime - $Message" -Path $logFile -ErrorAction stop                            
    } 
    catch 
    { 
        Add-Content -Value "$DateTime $_.Exception.Message" -Path $logFile -ErrorAction stop    
        Write-Log "ERROR: Creating Log file failed"
        Write-Log $_.Exception.Message   
    } 
}



function AddADGroupName()
{
    param(
    [Parameter(Mandatory=$true)][string]$ADGroupName
    )
    try {
        if(( (Get-AzureADGroup -Filter "DisplayName eq '$ADGroupName'") -eq $false ))
        {
            Write-Log  "Adding New ADGroupName to Azure Active Directory groups : $ADGroupName"
            New-AzureADGroup -Description $ADGroupName -DisplayName $ADGroupName -MailEnabled $false -SecurityEnabled $true -MailNickName $ADGroupName
        }
        else
        {
             Write-Log  "AzureADGroup already exists: $ADGroupName"
        }
    
    }
    catch
    {
        Write-Error $_.Exception.Message
        Write-Log  $_.Exception.Message 
        Write-Log "End of iteration"
        break
    }
    
}


function CheckADGroupNameExists()
{
    param(
    [Parameter(Mandatory=$true)][string]$ADGroupName
    )
    try {
        if(( (Get-AzureADGroup -Filter "DisplayName eq '$ADGroupName'") -eq $true ))
        {
            Return $true
        }
        else
        {
            Return $false
        }
    }
    catch
    {
        Write-Error $_.Exception.Message
        Write-Log "End of iteration"
        break
    }
    
}

function AddUserToAZAD()
{
    param(
    [Parameter(Mandatory=$true)][string]$DisplayName,
    [Parameter(Mandatory=$true)][string]$UserPrincipalName,
    [Parameter(Mandatory=$true)][string]$Password
    )
    try {
        if((CheckAZUser -UserPrincipalName $UserPrincipalName) -eq $false)
        {
            Write-Log  "Adding New user to Azure Active Directory : $DisplayName, $UserPrincipalName, $Password"
            New-AzureADUser -DisplayName $DisplayName -PasswordProfile  
            -UserPrincipalName $UserPrincipalName -AccountEnabled $true -MailNickName $DisplayName        
        }
        else
        {
             Write-Log  "UserPrincipalName already exists: $UserPrincipalName"
        }

    
    }
    catch
    {
        Write-Error $_.Exception.Message
        Write-Log "End of iteration"
        break
    }
    
}

Function CheckAZUser()
{
  param(
    [Parameter(Mandatory=$true)][string]$UserPrincipalName
 )
        #check if azure AD connection
        try {
                #check if user exists  
                if($UserPrincipalName)
                {
                $UserPrincipalName = $UserPrincipalName.ToString()
                $azureaduser = Get-AzureADUser -All $true | Where-Object {$_.Userprincipalname -eq "$UserPrincipalName"}
                    #check if something found    
                    if($azureaduser)
                    {
                        Write-Log  "User: $UserPrincipalName was found in $displayname AzureAD." 
                        return $true
                    }
                    else
                    {
                        Write-Log  "User $UserPrincipalName was not found in $displayname Azure AD " 
                        return $false
                    }
                }
            }
        catch
            {
                Write-Error $_.Exception.Message
                Write-Log "End of iteration"
                break
            }

}



function AddUserToAZACGroup
{
  param(
    [Parameter(Mandatory=$true)][string]$UserPrincipalName,
    [Parameter(Mandatory=$true)][string]$GroupName
 )

        try {
                $azureaduser = Get-AzureADUser -All $true | Where-Object {$_.Userprincipalname -eq "$UserPrincipalName"}
                $GroupObj = Get-AzureADGroup -SearchString $GroupName
                $UserObj = Get-AzureADUser -SearchString $azureaduser
                Add-AzureADGroupMember -ObjectId $GroupObj.ObjectId -RefObjectId $UserObj.ObjectId
                Write-Log  "User $UserPrincipalName was added successfully to Azure AD $GroupName at ((Get-Date).DateTime).ToString()" 
            }
        catch
            {
                Write-Log  "Could not Add user:$UserPrincipalName to GroupName:$GroupName at ((Get-Date).DateTime).ToString()" 
                Write-Log "End of iteration"
                break
            }


}

function main 
{

    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $PasswordProfile.Password = "P@ssw0rd"
    $GroupName = "Varonis Assignment Group"
    try{
        AddADGroupName -ADGroupName $GroupName
        if((CheckADGroupNameExists -ADGroupName $GroupName) -eq "$false")
        {
            Write-Error "ADGroupName - $GroupName doesn't exists"
            break
        }

        for($i = 0; $i -le 20;$i++)
        {
            AddUserToAZAD -DisplayName "Test User $i" -UserPrincipalName "TestUser$i@Varonis.com" -Password $PasswordProfile.Password
            AddUserToAZACGroup -UserPrincipalName "TestUser$i@Varonis.com" -GroupName $GroupName
        }

    }
    catch
    {
        Write-Log "End of iteration"
    }
    

}

main