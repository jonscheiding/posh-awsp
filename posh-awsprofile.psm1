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
    Write-Host "Clearing profile for current shell."
    Remove-Item -ErrorAction Ignore Env:AWS_PROFILE
  } else {
    Write-Host "Setting profile for current shell to '$ProfileName'."
    Test-AWSProfile -ProfileName $ProfileName | Out-Null
    Set-Item Env:AWS_PROFILE $ProfileName
  }
}

function Get-AWSAvailableProfiles {
  $AwsConfigFile = Get-AWSConfigFile

  if(!(Test-Path $AwsConfigFile -PathType Leaf)) {
    Throw "AWS CLI config file $AwsConfigFile doesn't exist.  Run 'aws configure' to create it."
  }

  $AwsConfig = Get-Content $AwsConfigFile
  $Profiles = $AwsConfig `
    | Select-String -Pattern "^\s*\[\s*(profile\s*(?<profile>.*)|(?<profile>default))\s*\]\s*$" `
    | ForEach-Object { 
        $_.Matches[0].Groups["profile"].Value
      }

  return $Profiles
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

function Switch-AWSProfile {
  $AvailableProfiles = Get-AWSAvailableProfiles
  $CurrentProfile = Get-AWSCurrentProfile

  Write-Host "Use [ and ] to move up and down the list of profiles."
  Write-Host "Use \ to select a profile, - to clear your profile, or = to cancel."

  $SelectedProfile = Read-MenuSelection -Items $AvailableProfiles -CurrentItem $CurrentProfile

  if($SelectedProfile -eq 0) {
    return
  }

  Set-AWSCurrentProfile -ProfileName $SelectedProfile
}

function Read-MenuSelection {
  Param(
    [Parameter(Mandatory = $true)] $Items,
    [Parameter(Mandatory = $true)] $CurrentItem
  )

  $SelectedItem = $null
  $CurrentIndex = $Items.IndexOf($CurrentItem)
  if($CurrentIndex -lt 0) { $CurrentIndex = 0 }

  for($i = 0; $i -lt $Items.Length; $i++) {
    $Indicator = if ($CurrentIndex -eq $i) { "*" } else { " " }
    $Index = if ($i -lt 10) { $i } else { " " }
    Write-Host "$Indicator $Index $($Items[$i])"
  }

  $CursorTop = [Console]::CursorTop - $Items.Length

  while($null -eq $SelectedItem) {
    $MoveBy = 0
    $Key = [Console]::ReadKey($true)
    
    switch($Key.KeyChar) {
      {[char]::IsNumber($_)} {
        $Index = [int]::Parse($_)
        if ($Index -lt $Items.Length) {
          $SelectedItem = $Items[$Index]
        }
      }
      "[" {
        if ($CurrentIndex -gt 0) { $MoveBy = -1 }
      }
      "]" {
        if ($CurrentIndex -lt $Items.Length - 1) { $MoveBy = 1 }
      }
      "\" {
        $SelectedItem = $Items[$CurrentIndex]
      }
      "-" { return $null }
      "=" { return 0 }
      default { Write-Host $_ }
    }

    if($MoveBy -ne 0) {
      [Console]::SetCursorPosition(0, $CursorTop + $CurrentIndex)
      Write-Host -NoNewline " "
      $CurrentIndex += $MoveBy
      [Console]::SetCursorPosition(0, $CursorTop + $CurrentIndex)
      Write-Host -NoNewline "*"
      [Console]::SetCursorPosition(0, $CursorTop + $Items.Length)
    }
  }

  return $SelectedItem
}