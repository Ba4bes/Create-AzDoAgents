<#
.SYNOPSIS
    Install AzDo Agent with the config files
.DESCRIPTION
    Script takes config files, unpacks them and performs a silent install
.EXAMPLE
    .\Install-Agent.ps1 -AgentName Agent01 -AgentfileName vsts-agent-win-x64-2.155.1.zip -OrganizationName example -Pat 245tag43gr -Pool Agentpool1

    Installs Agent01, by using the installpackage vsts-agent-win-x64-2.155.1.zip, in the pool AgentPool1 in the organization Example
.NOTES
    Barbara Forbes
    4bes.nl
    @ba4bes
#>
param (
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$AgentName,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$AgentFileName,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$OrganizationName,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$Pat,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$Pool
)

# Install Nuget and the AZ module to make the script work.
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module Az -Force

Import-Module Az
$Zipfile = $AgentFileName +".zip"
if (Test-Path "C:\Temp\$AgentFileName") {

}
else {
    $regex = $AgentFileName -match '\d\.\d*\.\d'
    $Version = $Matches[0]
    $url = "https://vstsagentpackage.azureedge.net/agent/$Version/$AgentFileName.zip"
    $output = "C:\Temp\$ZipFile"
    $Download = New-Object System.Net.WebClient
    $Download.DownloadFile($url, $output)
    Expand-Archive -LiteralPath "C:\temp\$ZipFile" -DestinationPath "C:\Temp\$AgentFileName" -Force
}
Set-Location "C:\Temp\$AgentFileName"

& .\config.cmd --unattended --url https://dev.azure.com/$OrganizationName --auth pat --token $pat --pool $pool --agent $agentname --replace --runAsService
