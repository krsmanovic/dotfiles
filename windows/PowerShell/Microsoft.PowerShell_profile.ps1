oh-my-posh --init --shell pwsh --config j:\prgms\ohmyposhv3-v2.json | Invoke-Expression
Set-PoshPrompt -Theme powerlevel10k_rainbow

function New-Guid {
    Set-Variable -Name "guidValue" -Value ([guid]::NewGuid())
    Set-Clipboard $guidValue
    Write-Output "`nUnique GUID is generated and copied to clipboard.`n`nThe value is:`n$guidValue`n"
}

function dev {
    Set-Location -Path 'E:\_git\krsmanovic\'
    Get-ChildItem
}