Import-Module posh-git
Import-Module oh-my-posh
Set-Theme Agnoster

function New-Guid {
    Set-Variable -Name "guidValue" -Value ([guid]::NewGuid())
    Set-Clipboard $guidValue
    Write-Output "`nUnique GUID is generated and copied to clipboard.`n`nThe value is:`n$guidValue`n"
}