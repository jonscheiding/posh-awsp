$USER_HOME = $Env:HOMEDRIVE + $Env:HOMEPATH
$AWS_HOME = Join-Path $USER_HOME ".aws"
$AWS_CONFIG_FILE = Join-Path $AWS_HOME "config"

function Get-AwsProfiles {
  if(!(Test-Path $AWS_CONFIG_FILE -PathType Leaf)) {
    Throw "AWS CLI config file $AWS_CONFIG_FILE doesn't exist.  Run 'aws configure' to create it."
  }

  $awsConfig = Get-Content $AWS_CONFIG_FILE
  $profiles = $awsConfig `
    | Select-String -pattern "^\s*\[profile (.*)\s*\]$" `
    | %{ $_.Matches.Groups[1].Value } `

  return @("default") + $profiles
}

function Test-AwsProfileName {
  Param(
    [Parameter(Mandatory=$true)]
    [string[]] $Profiles,
    [Parameter(Mandatory=$true)]
    [string] $ProfileName
  )

  if($Profiles | ?{ $_ -eq $ProfileName }) {
    return
  }

  Throw "Profile $ProfileName doesn't exist.  Run 'aws configure --profile $ProfileName' to create it."
}

function Show-Menu {
  Param(
    [Parameter(Mandatory=$true)]
    [string[]] $Items,
    [Parameter(Mandatory=$false)]
    [string] $CurrentItem
  )

  $currentIndex = $Items.IndexOf($currentIndex)
  if($currentIndex -eq -1) {
    $currentIndex = 0
  }

  $cursorTop = [Console]::CursorTop
  $selectedItem = $null

  for($index = 0; $index -lt $Items.Length; $index++) {
    $indicator = if($index -eq $currentIndex) { "*" } else { " " }
    Write-Host "$indicator $index)" $Profiles[$index]
  }

  while($null -eq $selectedItem) {
    $moveBy = 0
    $Response = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
  
    switch($Response.VirtualKeyCode) {
      38 { if($currentIndex -gt 0) { $moveBy = -1 } }
      40 { if($currentIndex -lt $Items.Length - 1) { $moveBy = +1 } }
      13 { $selectedItem = $Items[$currentIndex] }
      default {
        if($Items[$Response.Character]) {
          $selectedItem = $Items[$Response.Character]
        }
      }
    }

    if($moveBy -ne 0) {
      [Console]::SetCursorPosition(0, $cursorTop + $currentIndex)
      Write-Host -NoNewline " "
      $currentIndex += $moveBy
      [Console]::SetCursorPosition(0, $cursorTop + $currentIndex)
      Write-Host -NoNewline "*"
      [Console]::SetCursorPosition(0, $cursorTop + $Items.Length)
    }
  }

  return $selectedItem
}

function Read-AwsProfileName {
  Param(
    [Parameter(Mandatory=$true)]
    [string[]] $Profiles
  )

  Write-Host "Select your profile:"

  $currentProfile = Get-AwsProfile
  $selectedProfile = Show-Menu -Items $Profiles -CurrentItem $currentProfile

  return $selectedProfile
}

function Write-AwsProfilesList {
  Param(
    [Parameter(Mandatory=$true)]
    [string[]] $Profiles,
    [Parameter(Mandatory=$false)]
    [int] $CurrentIndex = 0
  )

  for($index = 0; $index -lt $Profiles.Length; $index++) {
    $indicator = If($index -eq $CurrentIndex) { "> " } else { "  " }
    Write-Host $indicator $Profiles[$index]
  }
}

function Get-AwsProfile {
  $AwsProfile = $Env:AWS_PROFILE
  if(!$AwsProfile) {
    return "default"
  }

  return $AwsProfile
}

function Set-AwsProfile {
  Param(
    [Parameter(Mandatory=$false, Position=1)]
    [string] $ProfileName,
    [Parameter(Mandatory=$false)]
    [switch] $Transient = $false
  )

  $profiles = Get-AwsProfiles

  if($ProfileName) {
    Test-AwsProfileName -Profiles $Profiles -ProfileName $ProfileName
  } else {
    $ProfileName = Read-AwsProfileName -Profiles $Profiles
  }

  Write-Host "Selecting profile '$ProfileName'."

  if($ProfileName -eq "default") {
    $ProfileName = $null
  }

  $Env:AWS_PROFILE = $ProfileName

  if(!$Transient) {
    Write-Host "Persisting selection."
    Write-Host "Note: Will not affect currently running shells. Run 'Update-AwsProfile' to refresh them."
    
    [Environment]::SetEnvironmentVariable("AWS_PROFILE", $ProfileName, [System.EnvironmentVariableTarget]::User)
  }
}

function Update-AwsProfile {
  $persistedAwsProfile = [Environment]::GetEnvironmentVariable("AWS_PROFILE", [System.EnvironmentVariableTarget]::User)
  if($persistedAwsProfile) {
    $Env:AWS_PROFILE = $persistedAwsProfile
  }

  Get-AwsProfile
}

Export-ModuleMember -Function *-AwsProfile,*-AwsProfiles

