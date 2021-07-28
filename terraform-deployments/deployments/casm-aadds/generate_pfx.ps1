
# Define your own DNS name used by your managed domain
$dnsName="*." + $args[0]
$Password=$args[1]
$dir=Get-Location

$cert = New-SelfSignedCertificate -DnsName $dnsName -CertStoreLocation $dir
echo "DIRECTORY: " + $dir
$pwd = ConvertTo-SecureString -String $Password -Force -AsPlainText

Export-PfxCertificate -Cert $cert -FilePath $dir\cert.pfx -Password $pwd