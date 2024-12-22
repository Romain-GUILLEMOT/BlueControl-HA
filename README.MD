#BlueControl HA
##Control Bluetooch of MacOS device from Home Assistant

You need to install blueutil

```shell
brew install blueutil
```
script bluetooch_control.sh a crée a la racine du dossier utilisateur avec
#!/bin/zsh
/opt/homebrew/bin/blueutil --power $1
