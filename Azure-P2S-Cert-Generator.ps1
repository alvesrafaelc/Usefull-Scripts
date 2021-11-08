#Root Certificate 5 anos. Para definir o tempo do certificado, altere o parametro ou exclua-o para gerar certificado de 1 ano "-NotAfter (Get-Date).AddYears(5)":

$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature -Subject "CN=LeonardoP2SRootNew" -KeyExportPolicy Exportable -NotAfter (Get-Date).AddYears(5) -HashAlgorithm sha256 -KeyLength 2048 -CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

#Client Certificate 5 anos. Para definir o tempo do certificado, altere o parametro ou exclua-o para gerar certificado de 1 ano "-NotAfter (Get-Date).AddYears(5)":

New-SelfSignedCertificate -Type Custom -DnsName P2SChildCert -KeySpec Signature -Subject "CN=LeonardoP2SChildCertNew" -KeyExportPolicy Exportable -NotAfter (Get-Date).AddYears(5) -HashAlgorithm sha256 -KeyLength 2048 -CertStoreLocation "Cert:\CurrentUser\My" -Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")

# Manual de configuração de certificado no Azure

# Utilize o KB abaixo para exportar os certificados de Root e Client
# https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-certificates-point-to-site