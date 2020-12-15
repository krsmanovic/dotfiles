$keyFilePath = Read-Host "Please enter full path to public key file"
$sshServer = Read-Host "Please enter the ssh server in format user@hostname or user@ip"

type $keyFilePath | ssh $sshServer "cat >> .ssh/authorized_keys"