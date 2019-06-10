function Get-AWSConfigFile {
  [string]$AwsConfigFile = $Env:AWS_CONFIG_FILE

  if($null -eq $AwsConfigFile) {
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

  return $ProfileName.Value
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

function Set-AWSCurrentProfile {
  Param(
    [Parameter(Mandatory=$true, Position=1)] [AllowNull()]
    $ProfileName
  )

  if($null -eq $ProfileName) {
    Remove-Item -ErrorAction Ignore Env:AWS_PROFILE
  } else {
    Set-Item Env:AWS_PROFILE $ProfileName
  }
}
