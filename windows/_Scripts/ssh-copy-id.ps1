$keyFilePath = Read-Host "Please enter full path to public key file (leave blank for default: C:\Users\$env:USERNAME\.ssh\id_rsa.pub)"

if ([string]::IsNullOrWhiteSpace($keyFilePath)) {
    $keyFilePath = "C:\Users\$env:USERNAME\.ssh\id_rsa.pub"
}

$sshServer = Read-Host "Please enter the ssh server (user@hostname or user@ip)"

type $keyFilePath | ssh $sshServer "cat >> .ssh/authorized_keys"