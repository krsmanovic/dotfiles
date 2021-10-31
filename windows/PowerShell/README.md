Copy file `ohmyposhv3-v2.json` to desired location and update `Microsoft.PowerShell_profile.ps1` to properly reference it.

Copy the `Microsoft.PowerShell_profile.ps1` file to the path resulted from this command:

```powershell
$PROFILE
```

## Prerequisites

Install posh-git and oh-my-posh:

```powershell
Install-Module posh-git -Scope CurrentUser
Install-Module oh-my-posh -Scope CurrentUser
winget install JanDeDobbeleer.OhMyPosh
```

More info at <https://github.com/JanDeDobbeleer/oh-my-posh>

## Note

This guide is to be used together with [WindowsTerminal](../WindowsTerminal) configuration.