[string]$AWS_HOME_DEFAULT = Join-Path ($Env:HOMEDRIVE + $Env:HOMEPATH) ".aws"
[string]$AWS_CONFIG_FILE = $Env:AWS_CONFIG_FILE

if ($null -eq $AWS_CONFIG_FILE) { 
  $AWS_CONFIG_FILE = Join-Path $AWS_HOME_DEFAULT "config" 
}

function Get-AWSProfile {
  $AwsProfile = $Env:AWS_PROFILE
  if($null -eq $AwsProfile) {
    return "default"
  }

  return $AwsProfile
}
