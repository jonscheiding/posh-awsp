function Get-AWSConfigFile {
  <#
    .SYNOPSIS
      Returns the name of the file to use for AWS CLI configuration profiles.

    .DESCRIPTION
      If there is a value in the AWS_CONFIG_FILE environment variable, returns
      that value.  Otherwise, returns the default config file location.

    .LINK
      https://www.github.com/jonscheiding/posh-awsprofile

    .LINK
      https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html
  #>

  [string]$AwsConfigFile = $Env:AWS_CONFIG_FILE

  if([string]::IsNullOrEmpty($AwsConfigFile)) {
    #
    # If the environment variable is not configured, calculate
    # the default location as documented in the AWS CLI docs.
    #
    $Home = $Env:HOME
    
    if($null -eq $Home) {
      $Home = $Env:HOMEDRIVE + $Env:HOMEPATH
    }

    if($null -eq $Home) {
      Write-Warning "Could not determine user's home directory."
      return $null
    }

    [string]$AwsHomeDefault = Join-Path $Home ".aws"
    $AwsConfigFile = Join-Path $AwsHomeDefault "config"
  }

  return $AwsConfigFile
}

function Get-AWSCurrentProfile {
  <#
    .SYNOPSIS
      Returns the currently set AWS CLI profile, or "default" if none has been specified.

    .DESCRIPTION
      This returns the value of the AWS_PROFILE environment variable.  If the variable is
      not set, it will return "default".

      If the variable is set to a value that does not exist as a configured AWS CLI profile,
      a warning will be displayed.

    .LINK
      https://www.github.com/jonscheiding/posh-awsprofile
  #>

  $ProfileItem = (Get-Item -ErrorAction Ignore Env:AWS_PROFILE)
  if($null -eq $ProfileItem) {
    Write-Host "No profile selected; 'default' will be used."
    $ProfileName = "default"
  } else {
    $ProfileName = $ProfileItem.Value
  }

  Test-AWSProfile -ProfileName $ProfileName | Out-Null

  return $ProfileName
}

function Set-AWSCurrentProfile {
  <#
    .SYNOPSIS
      Sets the AWS CLI profile to the provided value, or clears it if $null is passed.

    .DESCRIPTION
      This manipulates the value of the AWS_PROFILE environment variable. If the provided
      value does not exist as a configured AWS CLI profile, a warning will be displayed.

    .PARAMETER ProfileName
      Set the profile to this value.

    .PARAMETER Clear
      Clear the selected profile.

    .PARAMETER NoPersist
      Do not save the updated profile into the user's environment variables; only
      apply it to the current Powershell session.

    .LINK
      https://www.github.com/jonscheiding/posh-awsprofile
  #>

  Param(
    [Parameter(Mandatory=$true, Position=1, ParameterSetName='Set-Profile')]
    [string]$ProfileName,
    [Parameter(Mandatory=$true, ParameterSetName='Clear-Profile')]
    [switch]$Clear,
    [Parameter()]
    [switch]$NoPersist
  )

  switch($PSCmdlet.ParameterSetName) {
    "Clear-Profile" {
      $ProfileName = $null
      Write-Host "Clearing profile for current shell."
      Remove-Item -ErrorAction Ignore Env:AWS_PROFILE
    }
    "Set-Profile" {
      Test-AWSProfile -ProfileName $ProfileName | Out-Null
      Write-Host "Setting profile for current shell to '$ProfileName'."
      Set-Item Env:AWS_PROFILE $ProfileName
    }
  }

  if($NoPersist) {
    return
  }

  Write-Host "Updating user environment variable to persist profile setting."
  [System.Environment]::SetEnvironmentVariable(
    "AWS_PROFILE", $ProfileName, 
    [System.EnvironmentVariableTarget]::User)
}

function Get-AWSAvailableProfiles {
  <#
    .SYNOPSIS
      Displays the list of available AWS CLI profiles.

    .DESCRIPTION
      Shows the list of profiles found in the AWS CLI config file, as returned
      by Get-AWSConfigFile. If that file does not exist, a warning is displayed.

    .LINK
      https://www.github.com/jonscheiding/posh-awsprofile
  #>

  $AwsConfigFile = Get-AWSConfigFile

  if(!(Test-Path $AwsConfigFile -PathType Leaf)) {
    Write-Warning "AWS CLI config file $AwsConfigFile doesn't exist.  Run 'aws configure' to create it."
    return @()
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
  <#
    .SYNOPSIS
      Checks the validity of the provided AWS CLI profile name.

    .DESCRIPTION
      Checks whether the provided name exists in the list of profiles found
      in the AWS CLI config file, as returned by Get-AWSConfigFile. If that
      file does not exist, a warning is displayed.

    .LINK
      https://www.github.com/jonscheiding/posh-awsprofile
  #>

  Param(
    [Parameter(Mandatory=$true, Position=1)]
    $ProfileName
  )

  $AvailableProfiles = Get-AWSAvailableProfiles

  if($AvailableProfiles.Length -eq 0 -or !$AvailableProfiles.Contains($ProfileName)) {
    Write-Warning "No configuration found for profile '$($ProfileName)'."
    return $false
  }

  return $true
}

function Switch-AWSProfile {
  <#
    .SYNOPSIS
      Displays an interactive menu for choosing an AWS CLI profile.

    .DESCRIPTION
      Uses the following keys for navigation of the menu.
        [ Move up the list
        ] Move down the list
        \ Set your profile to the currently selected one
        - Clear your profile
        = Cancel with no changes

      Additionally, you can press any number key to select the profile
      indicated by that key.

    .PARAMETER NoPersist
      Do not save the updated profile into the user's environment variables; only
      apply it to the current Powershell session.

    .LINK
      https://www.github.com/jonscheiding/posh-awsprofile
  #>
  Param(
    [Parameter()]
    [switch] $NoPersist
  )

  $AvailableProfiles = Get-AWSAvailableProfiles
  $CurrentProfile = Get-AWSCurrentProfile

  If($AvailableProfiles.Length -eq 0) {
    Write-Error "There are no profiles configured."
    return
  }

  Write-Host "Use [ and ] to move up and down the list of profiles."
  Write-Host "Use \ to select a profile, - to clear your profile, or = to cancel."

  $SelectedProfile = Read-MenuSelection -Items $AvailableProfiles -CurrentItem $CurrentProfile

  if($SelectedProfile -eq 0) {
    return
  }

  Set-AWSCurrentProfile -ProfileName $SelectedProfile -NoPersist:$NoPersist
}

function Read-MenuSelection {
  <#
    .SYNOPSIS
      Utility function that implements the menu handling for
      Switch-AWSProfile.

    .LINK
      https://www.github.com/jonscheiding/posh-awsprofile
  #>

  Param(
    [Parameter(Mandatory = $true)] $Items,
    [Parameter(Mandatory = $true)] $CurrentItem
  )

  $SelectedItem = $null
  $CurrentIndex = $Items.IndexOf($CurrentItem)
  if($CurrentIndex -lt 0) { $CurrentIndex = 0 }

  #
  # Initially write out the menu items, including a * indicator
  # to point out the currently set profile.
  #
  for($i = 0; $i -lt $Items.Length; $i++) {
    $Indicator = if ($CurrentIndex -eq $i) { "*" } else { " " }
    $Index = if ($i -lt 10) { $i } else { " " }
    Write-Host "$Indicator $Index $($Items[$i])"
  }

  #
  # Keep track of where the cursor ended up so we can update the
  # * indicator
  #
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
      "[" { if ($CurrentIndex -gt 0) { $MoveBy = -1 } }
      "]" { if ($CurrentIndex -lt $Items.Length - 1) { $MoveBy = 1 } }
      "\" { $SelectedItem = $Items[$CurrentIndex] }
      "-" { return $null }
      "=" { return 0 }
    }

    if($MoveBy -ne 0) {
      #
      # If [ or ] was pressed, update where the * indicator is shown.
      #
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