Param(
  [Parameter(Mandatory = $true)]
  [string] $ModuleVersion,
  [Parameter(Mandatory = $true)] 
  [string] $NuGetApiKey,
  [Parameter()]
  [switch] $WhatIf
)

$ModuleManifestPath = ".\posh-awsp.psd1"
$PublishPath = ".\publish\posh-awsp"

$CopySettings = @{
  Path = ".\*"
  Destination = $PublishPath
  Exclude = @(
    ".git", ".gitignore", ".travis.yml", "publish", "build"
  )
}

$PublishSettings = @{
  Path = $PublishPath
  NuGetApiKey = $NuGetApiKey
  WhatIf = $WhatIf
}

Update-ModuleManifest -PassThru -Path $ModuleManifestPath -ModuleVersion $ModuleVersion

if (Test-Path -Path $PublishPath) { Remove-Item -Force -Recurse $PublishPath | Out-Null }
New-Item -ItemType directory -Path $PublishPath | Out-Null
Copy-Item -Verbose @CopySettings

Publish-Module -Verbose @PublishSettings
