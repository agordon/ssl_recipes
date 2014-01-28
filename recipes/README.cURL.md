# Using Self-signed Certificates with cURL

[cURL](http://curl.haxx.se/) is a command-line program to download files over the web.

### Generating Certificates

When you generate the Root CA's certificate (to later sign the server's certificate):

```sh
$ ./create_certificate_authoriy.sh
```

A file named `ca_public_certificate.pem` will be created (in `./CA/`). This is the file which will be used with "cURL".

### Trying without a certificate

When connecting to a web server which uses self-signed certificate, **cURL** will reject the server's certificate and refuse to download the file:

```
$ curl https://myserver.com
curl: (60) SSL certificate problem: self signed certificate in certificate chain
More details here: http://curl.haxx.se/docs/sslcerts.html

curl performs SSL certificate verification by default, using a "bundle"
 of Certificate Authority (CA) public keys (CA certs). If the default
 bundle file isn't adequate, you can specify an alternate file
 using the --cacert option.
If this HTTPS server uses a certificate signed by a CA represented in
 the bundle, the certificate verification probably failed due to a
 problem with the certificate (it might be expired, or the name might
 not match the domain name in the URL).
If you'd like to turn off curl's verification of the certificate, use
 the -k (or --insecure) option.
```

### Adding the Self-Signed Root CA certificate

When explictly adding the self-signed root CA's certificate, **cURL** will successfully validate the server's certificate:

```sh
$ curl --cacert ca_public_certificate.pem https://myserver.com > file.txt
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    13  100    13    0     0    110      0 --:--:-- --:--:-- --:--:--   116
```

### Sending Client-Side Certificate

If the webserver is configured to require Client-Side certificates (see apache2/lighttpd recipes for instructions), do the following:

**Step 1:** Create a new certificate for this client:

```sh
$ ./create_certificate foobarclient
```

The script will create several files (in `./CA/servers/foobarclient`), the file we need is `foobarclient.combined.pem`, which contains both the private key and the public certificate for this client).

**Step 2:** Use **cURL** with the client certificate

```sh
curl --cert foobarclient.combined.pem \
     --cacert ca_public_certificate.pem https://myserver.com > file.txt
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    13  100    13    0     0    110      0 --:--:-- --:--:-- --:--:--   116
```

If the webserver requires client-side-certificate and you did not specify one, the following error will appear:

```sh
curl: (35) error:14094410:SSL routines:SSL3_READ_BYTES:sslv3 alert handshake failure
```

### Security Considerations

1. This recipe *is not* secure.
2. It does not demonstrate good security practices (e.g. no passwords on private keys, no file-permission modifications, etc.).
3. It should be used **only** for testing and learning purposes.
4. The client-side-certificate is **only** as secure as your clients: if someone gains access to the client, he can steal the client's certificate.
