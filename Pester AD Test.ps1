#Instalar Pester
Install-Module PesterInfrastructureTests -Force -SkipPublisherCheck

#Executar health check do Active Directory
Test-ADPester

#=============================================================
#
#Erros de instalação
#
#Well, I had the same problem. Set my Powershell to TLS 1.2 and it worked for me.
#
#To test this :
#
#1. Open Powershell (As Admin)
#
#2. [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#
#3. Try it again!