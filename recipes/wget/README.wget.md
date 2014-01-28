ing Self-signed Certificates with WGET

[GNU WGET](http://www.gnu.org/software/wget/) is a command-line program to download files over the web.

### Generating Certificates

When you generate the Root CA's certificate (to later sign the server's certificate):

```sh
$ ./create_certificate_authoriy.sh
```

A file named `ca_public_certificate.pem` will be created (in `./CA/`). This is the file which will be used with "wget".

### Trying without a certificate

When connecting to a web server which uses self-signed certificate, **wget** will reject the server's certificate and refuse to download the file:

```
$ wget https://myserver.com
--2014-01-27 21:39:41--  https://myserver.com/
Resolving myserver.com... 1.2.3.4
Connecting to myserver.com|1.2.3.4|:443... connected.
ERROR: cannot verify myserver.com's certificate, issued by `/C=US/ST=NY/O=Trusted-R-Us Inc./OU=IT Department/CN=Trusted-R-US.com/emailAddress=trusty@trusted-r-us.com':
  Self-signed certificate encountered.
To connect to myserver.com insecurely, use `--no-check-certificate'.
```

### Adding the Self-Signed Root CA certificate

When explictly adding the self-signed root CA's certificate, **wget** will successfully validate the server's certificate:

```sh
$ wget --ca-certificate=ca_public_certificate.pem https://myserver.com
--2014-01-27 21:41:28--  http://myserver.com/
Resolving myserver.com... 1.2.3.4
Connecting to myserver.com|1.2.3.4|:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 13 [text/html]
Saving to: `index.html'

100%[===============================================================>] 13          ```

### Sending Client-Side Certificate

If the webserver is configured to require Client-Side certificates (see apache2/lighttpd recipes for instructions), do the following:

**Step 1:** Create a new certificate for this client:

```sh
$ ./create_certificate foobarclient
```

The script will create several files (in `./CA/servers/foobarclient`), the file we need is `foobarclient.combined.pem`, which contains both the private key and the public certificate for this client).

**Step 2:** Use **wget** with the client certificate

```sh
wget --certificate=foobarclient.combined.pem \
     --ca-certificate=ca_public_certificate.pem https://myserver.com
--2014-01-27 21:41:28--  http://myserver.com/
Resolving myserver.com... 1.2.3.4
Connecting to myserver.com|1.2.3.4|:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 13 [text/html]
Saving to: `index.html'

100%[===============================================================>] 13

```


### Security Considerations

1. This recipe *is not* secure.
2. It does not demonstrate good security practices (e.g. no passwords on private keys, no file-permission modifications, etc.).
3. It should be used **only** for testing and learning purposes.
4. The client-side-certificate is **only** as secure as your clients: if someone gains access to the client, he can steal the client's certificate.
