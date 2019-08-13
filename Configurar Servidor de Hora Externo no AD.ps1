net stop w32time
w32tm /config /manualpeerlist:"a.st1.ntp.br,0x9 b.st1.ntp.br,0xa c.st1.ntp.br,0x9" /syncfromflags:manual /reliable:yes /update
net start w32time
w32tm /resync