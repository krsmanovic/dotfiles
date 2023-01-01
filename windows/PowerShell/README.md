## Setting up PowerShell profile

Copy contents of the `Microsoft.PowerShell_profile.ps1` file to the path resulted from this command:

```powershell
$PROFILE
```

## Prerequisites

Install posh-git, starship and kubectl completion:

```powershell
Install-Module -Name posh-git -Scope CurrentUser
choco install starship
Install-Module -Name PSKubectlCompletion
```

More info at:
- <https://github.com/dahlbyk/posh-git>
- <https://starship.rs/>
- <https://kubernetes.io/docs/tasks/tools/included/optional-kubectl-configs-pwsh/>

## Note

This guide is to be used together with [WindowsTerminal](../WindowsTerminal) configuration.