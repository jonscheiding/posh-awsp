# posh-awsp

[![Build Status](https://img.shields.io/travis/jonscheiding/posh-awsp.svg)](https://travis-ci.org/jonscheiding/posh-awsp)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/posh-awsp.svg)](https://www.powershellgallery.com/packages/posh-awsp)

## Table of contents

- [Overview](#Overview)
- [Installation](#Installation)
- [Quick Start](#Quick-Start)
- [Usage](#Usage)
  - [Get-AWSCurrentProfile](#Get-AWSCurrentProfile)
  - [Set-AWSCurrentProfile](#Set-AWSCurrentProfile)
  - [Get-AWSAvailableProfiles](#Get-AWSAvailableProfiles)
  - [Switch-AWSProfile](#Switch-AWSProfile)

## Overview

posh-awsp is a PowerShell module that makes it easier to manage multiple AWS CLI profiles.  It interacts with your AWS config file (located by default at `~/.aws/config`) and the `AWS_PROFILE` environment variable, which is used by the AWS CLI and PowerShell cmdlets to control which profile to use.

## Installation

posh-awsp is available in the [PowerShell Gallery](https://www.powershellgallery.com/packages/posh-awsp), and can be installed with the following command:

```powershell
Install-Module posh-awsp
```

## Quick Start

To select a profile:

```powershell
awsp some_profile
```

To see a list of available profiles and choose one:

```powershell
awsp
```

## Usage

posh-awsp provides several commands for interacting with your AWS profile configuration.

### `Get-AWSCurrentProfile`

Returns your currently selected profile (i.e. the current value of your `AWS_PROFILE` environment variable), or the value `"default"` if no profile is selected.

```cmd
PS> Get-AWSCurrentProfile
default
```

This command will display a warning if your selected profile does not exist.

```cmd
PS> Get-AWSCurrentProfile
WARNING: No configuration found for profile 'nobody'.
nobody
```

### `Set-AWSCurrentProfile`

Changes your currently selected profile to the one you provide via the `-ProfileName` parameter.

```cmd
PS> Set-AWSCurrentProfile -ProfileName me
Setting profile for current shell to 'me'.
Updating user environment variable to persist profile setting.
```

```cmd
PS> Get-AWSCurrentProfile
me
```

This command will display a warning if the provided profile does not exist, but it will still set the value.

```cmd
PS> Set-AWSCurrentProfile -ProfileName nobody
WARNING: No configuration found for profile 'nobody'.
Setting profile for current shell to 'nobody'.
Updating user environment variable to persist profile setting.
```

```cmd
PS> Get-AWSCurrentProfile
nobody
```

You can also clear the current profile selection.

```cmd
PS> Set-AWSCurrentProfile -Clear
Clearing profile for current shell.
Updating user environment variable to persist profile setting.
```

```cmd
PS> Get-AWSCurrentProfile
No profile selected; 'default' will be used.
default
```

If you don't want to update your user-level environment variable, use the `-NoPersist` flag.
This way, your setting will only take effect for the current PowerShell session.

```cmd
PS> Set-AWSCurrentProfile me -NoPersist
Clearing profile for current shell.
```

### `Get-AWSAvailableProfiles`

Returns the list of available profiles from your profile config file.  This file is located by default at `~/.aws/config`, but the location can be changed by setting the `AWS_CONFIG_FILE` environment variable.

```cmd
PS> Get-AWSAvailableProfiles
default
me
```

If the config file (either the default, or the one specified by the `AWS_CONFIG_FILE` variable) does not exist, this command will print a warning.

```cmd
PS> Get-AWSAvailableProfiles
WARNING: AWS CLI config file C:\Users\me\.aws\config doesn't exist.  Run 'aws configure' to create it.
```

### `Switch-AWSProfile`

Displays an interactive menu that can be used to select a different profile from the available ones.  The current profile is preselected, unless it doesn't exist.

```cmd
PS> Switch-AWSProfile
Use [ and ] to move up and down the list of profiles.
Use \ to select a profile, - to clear your profile, or = to cancel.
  0 default
* 1 me
Setting profile for current shell to 'me'.
```

If the AWS config file does not exist, or contains no profiles, an error will be printed.

```cmd
PS> Switch-AWSProfile
WARNING: AWS CLI config file C:\Users\me\.aws\config doesn't exist.  Run 'aws configure' to create it.
Switch-AWSProfile : There are no profiles configured.
At line:1 char:1
+ Switch-AWSProfile
+ ~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Write-Error], WriteErrorException
    + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException,Switch-AWSProfile
```

You can pass a profile name, in which case this command becomes essentially an alias for `Set-AWSCurrentProfile`.

```cmd
PS> Switch-AWSProfile -ProfileName me
Setting profile for current shell to 'me'.
Updating user environment variable to persist profile setting.
```

You can also pass the `-NoPersist` flag, similarly to `Set-AWSCurrentProfile`.

This command is aliased as `awsp` for quicker access.
