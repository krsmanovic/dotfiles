Get-Service -Name wuauserv | Stop-Service -Force -verbose -ErrorAction SilentlyContinue

$folders = @(
    'j:\download'
    'C:\ProgramData\Microsoft\Windows\WER'
    'C:\Windows\SoftwareDistribution'
    'C:\Windows\Logs\CBS'
    'C:\Windows\Temp'
    'C:\Windows\prefetch'
    'C:\inetpub\logs\LogFiles'
    'C:\Users\*\Downloads'
    'C:\Users\*\AppData\Local\Temp'
    'C:\Users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files'
    'C:\Users\*\AppData\Local\Microsoft\Windows\History'
    'C:\Users\*\AppData\Local\Microsoft\Windows\INetCookies'
)
foreach($f in $folders) {
    Get-ChildItem -Path "$f\*" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-30))} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -Confirm:$false
}

Get-Service -Name wuauserv | Start-Service -Verbose