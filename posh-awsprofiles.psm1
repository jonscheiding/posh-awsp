function Get-AWSConfigFile {
  [string]$AwsConfigFile = $Env:AWS_CONFIG_FILE

  if([string]::IsNullOrEmpty($AwsConfigFile)) {
    [string]$AwsHomeDefault = Join-Path ($Env:HOMEDRIVE + $Env:HOMEPATH) ".aws"
    $AwsConfigFile = Join-Path $AwsHomeDefault "config"
  }

  return $AwsConfigFile
}

function Get-AWSCurrentProfile {
  $ProfileName = (Get-Item -ErrorAction Ignore Env:AWS_PROFILE)
  if($null -eq $ProfileName) {
    return "default"
  }

  Test-AWSProfile -ProfileName $ProfileName.Value | Out-Null

  return $ProfileName.Value
}

function Set-AWSCurrentProfile {
  Param(
    [Parameter(Mandatory=$true, Position=1)] [AllowNull()]
    $ProfileName
  )

  if($null -eq $ProfileName) {
    Remove-Item -ErrorAction Ignore Env:AWS_PROFILE
  } else {
    Set-Item Env:AWS_PROFILE $ProfileName
    Test-AWSProfile -ProfileName $ProfileName | Out-Null
  }
}

function Get-AWSAvailableProfiles {
  $AwsConfigFile = Get-AWSConfigFile

  if(!(Test-Path $AwsConfigFile -PathType Leaf)) {
    Throw "AWS CLI config file $AwsConfigFile doesn't exist.  Run 'aws configure' to create it."
  }

  $AwsConfig = Get-Content $AwsConfigFile
  $Profiles = $AwsConfig `
    | Select-String -pattern "^\s*\[profile (.*)\s*\]$" `
    | ForEach-Object { $_.Matches.Groups[1].Value }

  return @("default") + $Profiles
}

function Test-AWSProfile {
  Param(
    [Parameter(Mandatory=$true, Position=1)]
    $ProfileName
  )

  $AvailableProfiles = Get-AWSAvailableProfiles

  if(!$AvailableProfiles.Contains($ProfileName)) {
    Write-Warning "No configuration found for profile '$($ProfileName)'."
    return $false
  }

  return $true
}