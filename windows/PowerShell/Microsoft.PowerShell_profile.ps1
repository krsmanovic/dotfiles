Import-Module posh-git
Import-Module oh-my-posh
Set-Theme Agnoster

function new-guid {
    [guid]::NewGuid()   
}