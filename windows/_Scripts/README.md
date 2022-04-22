# ssh-copy-id.ps1

Check if directory `c:\Users\%USERNAME%\AppData\Local\Microsoft\WindowsApps\` is in the environment path variable:

```powershell
$env:path
```

Copy `ssh-copy-id.ps1` to `c:\Users\%USERNAME%\AppData\Local\Microsoft\WindowsApps\` folder.

# wireguard-exclude-ip.py

This script generates `AllowedIP` list with a feature to exclude your local (or any) IPs or networks you want.

Edit the `exclude` list to match your use case and run the script:

```
python wireguard-exclude-ip.py
```

Author: [Daniel Lautenbacher](https://www.lautenbacher.io/en/lamp-en/wireguard-exclude-a-single-ip-address/)