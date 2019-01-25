$USER_HOME = $Env:HOMEDRIVE + $Env:HOMEPATH
$AWS_HOME = Join-Path $USER_HOME ".aws"
$AWS_CONFIG_FILE = Join-Path $AWS_HOME "config"

function Get-AwsProfilesList {
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

function Read-AwsProfileName {
  Param(
    [Parameter(Mandatory=$true)]
    [string[]] $Profiles,
    [switch] $Quiet
  )

  if(!$Quiet) {
    Write-Host "Which profile do you want to use?"
    Write-AwsProfilesList -Profiles $Profiles
  }

  $Response = Read-Host -Prompt "Enter index or profile name"
  if ($Profiles[$Response]) {
    return $Profiles[$Response]
  }

  try {
    Test-AwsProfileName -Profiles $Profiles -ProfileName $Response
    return $Response
  } catch { }

  Write-Error "Invalid entry: $Response"
  return Read-AwsProfileName -Profiles $Profiles -Quiet
}

function Write-AwsProfilesList {
  Param(
    [Parameter(Mandatory=$true)]
    [string[]] $Profiles
  )

  $CurrentAwsProfile = Get-AwsProfile

  for($index = 0; $index -lt $Profiles.Length; $index++) {
    Write-Host -NoNewline "$index)" $Profiles[$index]
    if($Profiles[$index] -eq $CurrentAwsProfile) {
      Write-Host -NoNewline " (current)"
    }
    Write-Host ""
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
    [switch] $Persist
  )

  $profiles = Get-AwsProfilesList

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

  if($Persist) {
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

Export-ModuleMember -Function *-AwsProfile
