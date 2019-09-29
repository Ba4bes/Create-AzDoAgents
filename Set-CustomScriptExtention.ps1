<#
.SYNOPSIS
    Adds an agent to an Azure Windows VM through an Extention
.DESCRIPTION
    Adds a custom script extension to a VM while pasing parameters.
    Meant to be run in an Azure DevOps Pipeline
.EXAMPLE
    .\Set-CustomScriptExtension.ps1 -ResourcegroupName Group -Pat ono4ntoiantlawf430ng40agn -Pool AgentPool1

    This takes the VMs in the Resource group Group and adds them as agent to AgentPool1
.PARAMETER ResourceGroupName
    The name of the Resource group where the VMs are
.PARAMETER Pat
    The PAT-Key to connect ot Azure DevOps, needs te be able to manage agents
.PARAMETER Pool
    The agent pool the agent should be added to. Needs to be created beforehand.
.NOTES
    Barbara Forbes
    4bes.nl
    @ba4bes
#>
param (
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$ResourceGroupName,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$OrganizationName,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$Pat,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$Pool,
    [parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]$AgentFileName
)

# Find the VMs in the resource group
$VMs = Get-AzResource -ResourceType Microsoft.Compute/virtualMachines -ResourceGroupName $ResourceGroupName
if ($null -eq $VMs) {
    Throw "No VMs foud in the resourcegroup"
}
$Location = (Get-AzResourceGroup $ResourceGroupName).Location

foreach ($VM in $VMs) {
    $VmName = $VM.Name
    $protectedSettings = @{
        "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File C:\temp\Install-Agent.ps1 -Pat $Pat -Pool $Pool -Agentname $VmName -OrganizationName $OrganizationName -AgentFileName $AgentFileName"
    }

    # See if the WinRMextension is still active. If it is, uninstall it as only one Custom Script extension is permitted.
    $VMExtention = Get-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $VmName | Where-Object {$_.Name -eq "WinRMCustomScriptExtension" -or $_.Name -eq "Install-Agent" }
    if ($VMExtention) {
        $VMExtention | Remove-AzVMExtension -Force
    }

    # Create the parameters for the extension
    $parameters = @{
        ResourceGroupName  = $ResourceGroupName
        VmName             = $VmName
        Location           = $Location
        Name               = "install-agent"
        Publisher          = "Microsoft.Compute"
        ExtensionType      = "CustomScriptExtension"
        TypeHandlerVersion = "1.9"
        ProtectedSettings  = $protectedSettings
    }

    # Create the extension
    Set-AzVMExtension @Parameters -Verbose

}

