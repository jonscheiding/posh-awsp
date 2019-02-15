# posh-awsp

PowerShell cmdlets for managing your AWS CLI profiles.

## Usage

These cmdlets allow you to easily work with your named AWS CLI profiles.

List your available profiles:

    PS> Get-AwsProfiles
    default
    certica/dev
    certica/ab
    certica/master

See which profile you're currently using:

    PS> Get-AwsProfile
    certica/ab

Choose a different profile:

    PS> Set-AwsProfile certica/dev
    Selecting profile 'certica/dev'.
    Persisting selection.
    Note: Will not affect other open running shells. Run 'Update-AwsProfile' to refresh them.

Refresh your profile setting (if you had other PowerShell windows open when you did 'Set-AwsProfile'):

    PS> Update-AwsProfile
    certica/dev

Choose a different profile, but only have the setting apply to your current PowerShell window:

    PS> Set-AwsProfile -Transient certica/ab
    Selecting profile 'certica/ab'.

Choose a different profile from a menu of available profiles:

    PS> Set-AwsProfile
    Select your profile:
      0) default
      1) certica/dev
    * 2) certica/ab
      3) certica/architect
      4) certica/qa
      5) certica/staging
      6) certica/master
      7) personal
    Selecting profile 'certica/ab'.
    Persisting selection.
    Note: Will not affect other open running shells. Run 'Update-AwsProfile' to refresh them.

## Installation

  1. Make sure you have PowerShellGet installed:  
    https://docs.microsoft.com/en-us/powershell/gallery/installing-psget
  2. Install the 'posh-awsp' module.  
      `PS> Install-Module posh-awsp`
