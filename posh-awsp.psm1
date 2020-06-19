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

    .PARAMETER Quiet
      Suppress informational output.

    .LINK
      https://www.github.com/jonscheiding/posh-awsprofile
  #>

  Param(
    [Parameter()]
    [switch] $Quiet
  )

  $ProfileItem = (Get-Item -ErrorAction Ignore Env:AWS_PROFILE)
  if($null -eq $ProfileItem) {
    if(!$Quiet) { Write-Host "No profile selected; 'default' will be used." }

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

      If profile has default region is set, then AWS_REGION environment variable is also updated.

    .PARAMETER ProfileName
      Set the profile to this value.

    .PARAMETER ProfileRegion
      Set the region to this value.

    .PARAMETER Clear
      Clear the selected profile.

    .PARAMETER Persist
      Save the updated profile into the user's environment variables so that it persists
      across PowerShell restarts.

    .PARAMETER Quiet
      Suppress informational output.

    .LINK
      https://www.github.com/jonscheiding/posh-awsprofile
  #>

  Param(
    [Parameter(Mandatory=$true, Position=0, ParameterSetName='Set-Profile')]
    [string]$ProfileName,
    [Parameter(Mandatory=$true, Position=1, ParameterSetName='Set-Profile')]
    [string]$ProfileRegion,
    [Parameter(Mandatory=$true, ParameterSetName='Clear-Profile')]
    [switch]$Clear,
    [Parameter()]
    [switch]$Persist,
    [Parameter()]
    [switch] $Quiet
  )

  Write-Host ''

  switch($PSCmdlet.ParameterSetName) {
    "Clear-Profile" {
      $ProfileName = $null
      if(!$Quiet) { Write-Host "Clearing profile setting for current session." }
      Remove-Item -ErrorAction Ignore Env:AWS_PROFILE
    }
    "Set-Profile" {
      Test-AWSProfile -ProfileName $ProfileName | Out-Null
      if(!$Quiet) { Write-Host "Setting profile for current session to '$ProfileName'." }
      Set-Item Env:AWS_PROFILE $ProfileName

      if(!$Quiet) { Write-Host "Setting profile region for current session to '$ProfileRegion'." }
      Set-Item Env:AWS_REGION $ProfileRegion
    }
  }

  if(!$Persist) {
    if(!$Quiet) { Write-Host "To change the profile setting for future sessions, run this command with the -Persist argument." }
    return
  }

  if(!(Test-IsWindows)) {
    Write-Warning "The -Persist argument is not supported on non-Windows platforms."
    return
  }

  if(!$Quiet) { Write-Host "Updating user environment variable to change profile setting for future sessions." }
  [System.Environment]::SetEnvironmentVariable(
    "AWS_PROFILE", $ProfileName,
    [System.EnvironmentVariableTarget]::User)

  [System.Environment]::SetEnvironmentVariable(
    "AWS_REGION", $ProfileRegion,
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

function Get-AWSRegionForProfile {
  <#
    .SYNOPSIS
      Get the region value for a profile

    .DESCRIPTION
      Get the region from a named profile, as returned by Get-AWSConfigFile.
      If region not set, then returns null
      If that file does not exist, a warning is displayed.

    .LINK
      https://www.github.com/jonscheiding/posh-awsprofile
  #>

  Param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ProfileName
  )

  function Get-IniFile
  {
      param(
          [parameter(Mandatory = $true)] [string] $filePath
      )

      $anonymous = "NoSection"

      $ini = @{}
      switch -regex -file $filePath
      {
          "^\[(.+)\]$" # Section
          {
              $section = $matches[1]
              $ini[$section] = @{}
              $CommentCount = 0
          }

          "^(;.*)$" # Comment
          {
              if (!($section))
              {
                  $section = $anonymous
                  $ini[$section] = @{}
              }
              $value = $matches[1]
              $CommentCount = $CommentCount + 1
              $name = "Comment" + $CommentCount
              $ini[$section][$name] = $value
          }

          "(.+?)\s*=\s*(.*)" # Key
          {
              if (!($section))
              {
                  $section = $anonymous
                  $ini[$section] = @{}
              }
              $name,$value = $matches[1..2]
              $ini[$section][$name] = $value
          }
      }

      return $ini
  }

  $AwsConfigFile = Get-AWSConfigFile

  if(!(Test-Path $AwsConfigFile -PathType Leaf)) {
    Write-Warning "AWS CLI config file $AwsConfigFile doesn't exist.  Run 'aws configure' to create it."
    return $null
  }

  $AwsConfigIni = Get-IniFile $AwsConfigFile

  if ($ProfileName -ne 'default') {
    $ProfileName = "profile $ProfileName"
  }

  $Region = $null
  if ($AwsConfigIni.ContainsKey($ProfileName)) {
    $Region = $AwsConfigIni[$ProfileName].region
  }

  return $Region
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
    Write-Warning "No configuration found for AWS profile '$($ProfileName)'."
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

    .PARAMETER ProfileName
      When provided, skips the menu and directly sets the profile name.

    .PARAMETER Persist
      Save the updated profile into the user's environment variables so that it persists
      across PowerShell restarts.

    .LINK
      https://www.github.com/jonscheiding/posh-awsprofile
  #>
  Param(
    [Parameter(Position=0)]
    [string] $ProfileName,
    [Parameter()]
    [switch] $Persist
  )

  $ProfileRegion = ''
  if([string]::IsNullOrEmpty($ProfileName)) {
    $AvailableProfiles = Get-AWSAvailableProfiles
    $CurrentProfile = Get-AWSCurrentProfile

    if($AvailableProfiles.Length -eq 0) {
      Write-Error "There are no profiles configured."
      return 1
    }

    Write-Host `
      "Press Delete to clear your profile setting.`nPress Escape to cancel."

    $ProfileName = Read-MenuSelection -Items $AvailableProfiles -CurrentItem $CurrentProfile
    $ProfileRegion = Get-AWSRegionForProfile -ProfileName $ProfileName
  }

  if($ProfileName -eq 0) {
    Write-Host "Leaving profile as '$CurrentProfile'."
  } elseif([string]::IsNullOrEmpty($ProfileName)) {
    Set-AWSCurrentProfile -Clear -Persist:$Persist
  } else {
    Set-AWSCurrentProfile -ProfileName $ProfileName -ProfileRegion $ProfileRegion -Persist:$Persist
  }

  Write-Host ""
  return
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
    $Name = if ($CurrentIndex -eq $i) { "`e[36m$($Items[$i])`e[0m" } else { "$($Items[$i])" }
    $Index = if ($i -lt 10) { $i } else { " " }
    Write-Host "$Indicator $Index $Name"
  }

  #
  # Keep track of where the cursor ended up so we can update the
  # * indicator
  #
  $CursorTop = [Console]::CursorTop - $Items.Length

  while($null -eq $SelectedItem) {
    $MoveBy = 0
    $Key = [Console]::ReadKey($true)

    switch($Key.Key) {
      "UpArrow"   { if ($CurrentIndex -gt 0) { $MoveBy = -1 } }
      "DownArrow" { if ($CurrentIndex -lt $Items.Length - 1) { $MoveBy = 1 } }
      "Enter"     { $SelectedItem = $Items[$CurrentIndex] }
      "Escape"    { return 0 }
      "Delete"    { return $null }
    }

    if([char]::IsNumber($Key.KeyChar)) {
      $Index = [int]::Parse($Key.KeyChar)
      if ($Index -lt $Items.Length) {
        $SelectedItem = $Items[$Index]
      }
    }

    if($MoveBy -ne 0) {
      #
      # If [ or ] was pressed, update where the * indicator is shown.
      #
      [Console]::SetCursorPosition(0, $CursorTop + $CurrentIndex)
      Write-Host -NoNewline "  $CurrentIndex $($Items[$CurrentIndex])"
      $CurrentIndex += $MoveBy
      [Console]::SetCursorPosition(0, $CursorTop + $CurrentIndex)
      Write-Host -NoNewline "* $CurrentIndex `e[36m$($Items[$CurrentIndex])`e[0m"
      [Console]::SetCursorPosition(0, $CursorTop + $Items.Length)
    }
  }

  return $SelectedItem
}

function Test-IsWindows {
  <#
    .SYNOPSIS
      Utility function that checks if we are currently running on Windows.

    .LINK
      https://www.github.com/jonscheiding/posh-awsprofile
  #>

  if(!(Get-Variable -Name IsWindows -ErrorAction SilentlyContinue)) {
    #
    # No $IsWindows variable means we're on PowerShell Core 5.1 or
    # PowerShell Desktop, both of which are Windows-only.
    #
    return $true
  }

  return $IsWindows
}

New-Alias -Name awsp -Value Switch-AWSProfile -Force
