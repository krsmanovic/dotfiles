#oh-my-posh --init --shell pwsh --config c:\Users\Che\Documents\PowerShell\Modules\oh-my-posh\5.12.1\themes\powerline.omp.json | Invoke-Expression

Import-Module posh-git

$env:STARSHIP_CONFIG = "$env:userprofile\.starship\starship.toml"

Invoke-Expression (&starship init powershell)

Set-Alias -Name ll -Value Get-ChildItem

function New-Guid {
    Set-Variable -Name "guidValue" -Value ([guid]::NewGuid())
    Set-Clipboard $guidValue
    Write-Output "`nUnique GUID is generated and copied to clipboard.`n`nThe value is:`n$guidValue`n"
}

function dev {
    Set-Location -Path 'E:\_git\krsmanovic\'
    Get-ChildItem
}
