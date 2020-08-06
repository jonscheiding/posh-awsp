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
    $AwsHome = $Env:HOME

    if($null -eq $AwsHome) {
      $AwsHome = $Env:HOMEDRIVE + $Env:HOMEPATH
    }

    if($null -eq $AwsHome) {
      Write-Error "Could not determine user's home directory."
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
      Remove-Item -ErrorAction Ignore Env:AWS_REGION
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
  if ($null -eq $AwsConfigFile) {
    Write-Error "Cannot find AWS config file"
    return $null
  }

  $NoSection = "NoSection"

  $IniFile = [ordered]@{}
  switch -regex -file $AwsConfigFile
  {
    "^\[(.+)\]$" # Section
    {
      $Section = $matches[1] -Replace 'profile ',''
      $IniFile[$Section] = @{}
      $CommentCount = 0
    }

    "^(;.*)$" # Comment
    {
      if (!($Section))
      {
          $Section = $NoSection
          $IniFile[$Section] = @{}
      }
      $Value = $matches[1]
      $CommentCount = $CommentCount + 1
      $Name = "Comment" + $CommentCount
      $IniFile[$Section][$Name] = $Value
    }

    "(.+?)\s*=\s*(.*)" # Key
    {
      if (!($Section))
      {
          $Section = $NoSection
          $IniFile[$Section] = @{}
      }
      $Name,$Value = $matches[1..2]
      $IniFile[$Section][$Name] = $Value
    }
  }

  $AwsProfiles = @()
  foreach ($ProfileName in $IniFile.Keys) {
    $AwsProfiles += @{ Name = $ProfileName; Region = $IniFile[$ProfileName]['region']}
  }

  return $AwsProfiles
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

  $AvailableProfileNames = Get-AWSAvailableProfiles | ForEach-Object { $_.Name }

  if($AvailableProfileNames.Length -eq 0 -or !$AvailableProfileNames.Contains($ProfileName)) {
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

  $AvailableProfiles = Get-AWSAvailableProfiles
  if([string]::IsNullOrEmpty($ProfileName)) {
    $CurrentProfile = Get-AWSCurrentProfile

    if($AvailableProfiles.Length -eq 0) {
      Write-Error "There are no profiles configured."
      return 1
    }

    Write-Host "`nPress `e[31mDelete`e[0m to clear your profile setting."
    Write-Host "Press `e[33mEscape`e[0m to cancel."

    $SelectedProfile = Read-MenuSelection -Items $AvailableProfiles -CurrentItem $CurrentProfile
  } else {
    $SelectedProfile = $AvailableProfiles | Where-Object { $_.Name -eq $ProfileName } Select-Object -First 1
  }

  if("esc" -eq $SelectedProfile) {
    Write-Host "Leaving profile as '$CurrentProfile'."
    return
  }
  
  if($null -ne $SelectedProfile) {
    Set-AWSCurrentProfile -ProfileName $SelectedProfile.Name -ProfileRegion $SelectedProfile.Region -Persist:$Persist
  } else {
    Set-AWSCurrentProfile -Clear -Persist:$Persist
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

  function Get-ProfileName {
    Param(
      [Parameter(Mandatory = $true)] $Index
    )

    if ($null -eq $Items[$Index].Region) {
      return "$($Items[$Index].Name)"
    }
    return "$($Items[$Index].Name) ($($Items[$Index].Region))"
  }

  #
  # Initially write out the menu items, including a * indicator
  # to point out the currently set profile.
  #
  for($i = 0; $i -lt $Items.Length; $i++) {
    $Indicator = if ($CurrentIndex -eq $i) { "*" } else { " " }
    $Name = if ($CurrentIndex -eq $i) { "`e[36m$(Get-ProfileName $i)`e[0m" } else { "$(Get-ProfileName $i)" }
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
      "Escape"    { return "esc" }
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
      Write-Host -NoNewline "  $CurrentIndex $(Get-ProfileName $CurrentIndex)"
      $CurrentIndex += $MoveBy
      [Console]::SetCursorPosition(0, $CursorTop + $CurrentIndex)
      Write-Host -NoNewline "* $CurrentIndex `e[36m$(Get-ProfileName $CurrentIndex)`e[0m"
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
