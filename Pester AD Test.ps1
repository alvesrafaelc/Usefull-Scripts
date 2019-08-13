#Instalar Pester
Install-Module PesterInfrastructureTests -Force -SkipPublisherCheck

#Executar health check do Active Directory
Test-ADPester