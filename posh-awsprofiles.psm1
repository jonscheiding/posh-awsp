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
