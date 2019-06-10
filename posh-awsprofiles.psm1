[string]$AWS_HOME_DEFAULT = Join-Path ($Env:HOMEDRIVE + $Env:HOMEPATH) ".aws"
[string]$AWS_CONFIG_FILE = $Env:AWS_CONFIG_FILE

if ($null -eq $AWS_CONFIG_FILE) { 
  $AWS_CONFIG_FILE = Join-Path $AWS_HOME_DEFAULT "config" 
}

function Get-AWSProfile {
  $ProfileName = $Env:AWS_PROFILE
  if($null -eq $ProfileName) {
    return "default"
  }

  return $ProfileName
}

function Set-AWSProfile {
  Param(
    [Parameter(Mandatory=$true, Position=1)] [AllowNull()]
    $ProfileName
  )

  if($null -eq $ProfileName -and $null -ne $Env:AWS_PROFILE) {
    Remove-Item Env:\AWS_PROFILE
  } else {
    $Env:AWS_PROFILE = $ProfileName
  }
}
