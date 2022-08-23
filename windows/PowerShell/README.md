## Setting up PowerShell profile

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

More info at:
- <https://github.com/JanDeDobbeleer/oh-my-posh>
- <https://github.com/dahlbyk/posh-git>

## Note

This guide is to be used together with [WindowsTerminal](../WindowsTerminal) configuration.