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

This tool is useful in the specific scenario where you need to interact with multiple different AWS accounts, either with different credentials or with different assumed roles; or, with different AWS regions.  It assumes you have configured your AWS CLI config and credentials files with multiple named profiles.  Ths is described in detail in [AWS's documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html), but here is a brief example:

`~/.aws/config`

```ini
[profile development]
region = us-east-1
[profile development/other-region]
source_profile = development
region = us-east-2
[profile development/assumed-role]
source_profile = development
role_arn = arn:aws:iam:123456789000:role/SomeAssumedRole
[profile production]
region = us-east-1
[default]
region = us-east-1
```

`~/.aws/credentials`

```ini
[development]
aws_access_key_id=AKIAIOSFODNNEXAMPLE1
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCEXAMPLEKEY1
[production]
aws_access_key_id=AKIAIOSFODNNEXAMPLE2
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCEXAMPLEKEY2
[default]
aws_access_key_id=AKIAIOSFODNNEXAMPLE3
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCEXAMPLEKEY3
```

## Installation

posh-awsp is available in the [PowerShell Gallery](https://www.powershellgallery.com/packages/posh-awsp), and can be installed with the following command:

```powershell
Install-Module posh-awsp
```

You might also consider installing my other module, [posh-awsvault](https://github.com/jonscheiding/posh-awsvault), if you want secure credential management with [aws-vault](https://github.com/99designs/aws-vault).

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
Setting profile for current session to 'me'.
To change the profile setting for future sessions, run this command with the -Persist argument.
```

```cmd
PS> Get-AWSCurrentProfile
me
```

This command will display a warning if the provided profile does not exist, but it will still set the value.

```cmd
PS> Set-AWSCurrentProfile -ProfileName nobody
WARNING: No configuration found for profile 'nobody'.
Setting profile for current session to 'nobody'.
To change the profile setting for future sessions, run this command with the -Persist argument.
```

```cmd
PS> Get-AWSCurrentProfile
nobody
```

You can also clear the current profile selection.

```cmd
PS> Set-AWSCurrentProfile -Clear
Clearing profile setting for current session.
To change the profile setting for future sessions, run this command with the -Persist argument.
```

```cmd
PS> Get-AWSCurrentProfile
No profile selected; 'default' will be used.
default
```

If you want to update your user-level environment variable, use the `-Persist` flag.
This way, your setting will take effect for all future PowerShell sessions.

```cmd
PS> Set-AWSCurrentProfile me -Persist
Clearing profile for current session.
Updating user environment variable to change profile setting for future sessions.
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

Displays an interactive menu that can be used to select a different profile from the available ones. You can use the arrow keys to navigate the menu to select a profile. The current profile is preselected, unless it doesn't exist.

```cmd
PS> Switch-AWSProfile
Press Delete to clear your profile setting.
Press Escape to cancel.
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
To update the profile setting for future sessions, run this command with the -Persist argument.
```

You can also pass the `-Persist` flag, similarly to `Set-AWSCurrentProfile`.

This command is aliased as `awsp` for quicker access.
