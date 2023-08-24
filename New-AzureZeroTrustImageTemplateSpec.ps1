[CmdletBinding(SupportsShouldProcess)]
param (
	[Parameter(Mandatory)]
	[string]$TemplateSpecName,

    [Parameter(Mandatory)]
	[string]$Location,

    [Parameter(Mandatory)]
	[string]$ResourceGroupName
)

New-AzTemplateSpec `
    -Name ZTA `
    -ResourceGroupName test2_group `
    -Version '1.0' `
    -Location usgovvirginia `
    -DisplayName "Zero Trust Image Template" `
    -TemplateFile '.\solution.json' `
    -UIFormDefinitionFile '.\uiDefinition.json' `
    -Force