function Get-AWSCurrentProfile {
  $ProfileName = (Get-Item -ErrorAction Ignore Env:AWS_PROFILE)
  if($null -eq $ProfileName) {
    return "default"
  }

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
  }
}
