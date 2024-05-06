# Set terminal prompt theme
# Requirements:
# - Install-Module -Name posh-git
# - choco install starship
Import-Module posh-git
$env:STARSHIP_CONFIG = "$env:userprofile\.starship\starship.toml"
Invoke-Expression (&starship init powershell)

# Set general aliases
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name eth -Value Get-NetAdapter

# Set-up kubectl completion
# Requirements:
# - Install-Module -Name PSKubectlCompletion
# - Set-Alias command should be before Register-KubectlCompletion
Import-Module PSKubectlCompletion
Set-Alias -Name k -Value kubectl
Register-KubectlCompletion

##################### FUNCTIONS #####################

<#
.SYNOPSIS
    Generate new GUID (Globally Unique Identifier) and copy it to clipboard.
.EXAMPLE
    New-Guid
#>
function New-Guid {
    Set-Variable -Name "guidValue" -Value ([guid]::NewGuid())
    Set-Clipboard $guidValue
    Write-Output "`nUnique GUID is generated and copied to clipboard.`n`nThe value is:`n$guidValue`n"
}

function dev {
    Set-Location -Path 'E:\_git\krsmanovic\'
    Get-ChildItem
}

<#
.SYNOPSIS
    Synchronize local git repos with main/master remote branch and delete merged branches.
#>
function sync-repos {
    $mainDir = "E:\_git"
    $fold = "krsmanovic", "github.com"
    foreach($f in $fold) {
      Set-Location -Path "$mainDir\$f"
      Get-ChildItem -recurse -force | where {$_.name -eq ".git"} | foreach {
        cd $_.parent.FullName;
        Write-Output "`n-- $f/$((Get-Item .).BaseName)`n";
        $headBranch = $((git remote show origin | Where-Object {$_ -Match "HEAD branch:"}) -split ' ' | select -Last 1);
        Write-Output "HEAD branch is: $headBranch"
        $merged = $(git branch --merged).trim();
        git rev-parse --verify main 2>&1 | Out-Null;
        if ($lastExitCode -eq 0) {
          git checkout main
          git pull
          $merged = $(git branch --merged).trim()
          if (($merged | Where-Object {$_ -NotMatch "main|$headBranch"} | Measure-Object -Line | Select-Object -ExpandProperty Lines) -gt 0) {
            $mergedCleanup = $($merged | Where-Object {$_ -NotMatch "main"})
            git branch -d $mergedCleanup
          }
        }
        else {
          git checkout master
          git pull
          $merged = $(git branch --merged).trim()
          if (($merged | Where-Object {$_ -NotMatch "master|$headBranch"} | Measure-Object -Line | Select-Object -ExpandProperty Lines) -gt 0) {
            $mergedCleanup = $($merged | Where-Object {$_ -NotMatch "master"})
            git branch -d $mergedCleanup
          }
        };
        cd ..;
      }
    }
}

<#
.SYNOPSIS
    Generate a random password 12 characters long. You can pass paramenter value to override the default.
.EXAMPLE
    generate-password 20
#>
function generate-password {
    param(
        [int]$maxChars=12
    )

    $newPassword = ""
    $rand = New-Object System.Random
    0..$maxChars | ForEach-Object {$newPassword += [char]$rand.Next(48,122)}

    return $newPassword
}

<#
.SYNOPSIS
    Calculate SHA256 hash value for a file.
.EXAMPLE
    sha256 c:\test.txt
.EXAMPLE
    sha256 test.txt
#>
function sha256 {
  Get-FileHash -Path $args -Algorithm sha256 | Select-Object -ExpandProperty Hash
}

<#
.SYNOPSIS
    Calculate SHA1 hash value for a file.
.EXAMPLE
    sha1 c:\test.txt
.EXAMPLE
    sha1 test.txt
#>
function sha1 {
  Get-FileHash -Path $args -Algorithm sha1 | Select-Object -ExpandProperty Hash
}

<#
.SYNOPSIS
    Calculate MD5 hash value for a file.
.EXAMPLE
    md5 c:\test.txt
.EXAMPLE
    md5 test.txt
#>
function md5 {
  Get-FileHash -Path $args -Algorithm md5 | Select-Object -ExpandProperty Hash
}

<#
.SYNOPSIS
    Print process start time.
.EXAMPLE
    starttime -app notepad
#>
function starttime {
  param (
      [Parameter(Mandatory=$false)] [string]$app = "WowClassic"
  )
  Get-Process | Where {$_.Name -eq "$app"} | select name, starttime
}
