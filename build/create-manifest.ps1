Param(
  [Parameter(Mandatory = $true)] $Version
)

$ModuleSettings = @{
  Path = ".\posh-awsp.psd1"
  ModuleVersion = $Version
  RootModule = ".\posh-awsp.psm1"
  GUID = "a66e9bab-da01-46e2-884d-55797027a362"
  Author = "Jon Scheiding"
  Description = "PowerShell cmdlets for managing your AWS CLI profile."
  FunctionsToExport = @(
    "Get-AWSCurrentProfile", 
    "Get-AWSAvailableProfiles", 
    "Set-AWSCurrentProfile", 
    "Switch-AWSProfile"
  )
}

New-ModuleManifest @ModuleSettings -PassThru
Test-ModuleManifest -Path $ModuleSettings.Path
