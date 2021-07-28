openssl req -newkey rsa:4096 -x509 -days 365 -nodes -out certificate.cer -keyout secret.key -subj "/C=CA/ST=BC/L=Burnaby/O=Teradici/OU=Software Department/CN=*.$1"
openssl pkcs12 -inkey secret.key -in certificate.cer -export -out cert.pfx -passout pass:$2
