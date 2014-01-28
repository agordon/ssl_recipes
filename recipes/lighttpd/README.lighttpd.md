# lighttpd - Installing Self-Signed Server Certificate

This recipe shows how to setup [lighttpd](http://www.lighttpd.net/) webserver to use the self-signed SSL certificates.

### Generating Certificates

**Step 1** - Create certificate Authority:

```sh
$ ./create_certificate_authoriy.sh
```

A file named `ca_public_certificate.pem` will be created (in `./CA/`), and this file should be copied to the server running lighttpd.

**Step 2** - Create certificate for the server:

```sh
$ ./create_certificate.sh myserver.com
```

1. The domain name `myserver.com` should match your domain name.
2. The generated certificate automatically includes all subdomains (e.g. `www.myserver.com` and `foo.bar.myserver.com` are all included).
3. A file named `myserver.com.combined.pem` will be created (in `./CA/servers/myserver.com`) and should be copied to the server running lighttpd.

### Enabling SSL on lighttpd

This guide will not cover lighttpd/SSL configuration in details (there are better tutorials on line).
A good place to start is the [lighttpd SSL](http://redmine.lighttpd.net/projects/1/wiki/Docs_SSL) manual.

1. In `/etc/lighttpd/conf-available` there should be a file named `10-ssl.conf`.
2. Link or copy this file to `/etc/lighttpd/conf-enabled`
3. Restart the server, with `sudo /sbin/service lighttpd restart`
4. Verify that apache server is listening on port 443 (HTTPS port), by running `sudo netstat -ntlp | grep 443` - This should list the lighttpd process.

### Adding the Self-signed certificates

Open the file `10-ssl.conf`, and add/update the following statements (update the file paths as necessary):

```
ssl.engine  = "enable"
ssl.ca-file = "/FULL/PATH/ca_public_certificate.pem"
ssl.pemfile = "/FULL/PATH/myserver.com.combined.pem"
ssl.use-sslv3 = "enable"
```

Restart lighttpd with `sudo /sbin/service lighttpd restart`, and the new self-signed certificates should take effect.

### Enabling Client-Side-Certificates

Client-Side-Certificates allow the **lighttpd server** to authenticate the client.
The client will send its certificate to the server (and since the client's certificate is signed by our Root CA, and the server has the Root CA's certificate, the client's certificate will be valid).

Clients without a valid certificate will not be able to complete the SSL handshake with the server, and will be rejected.

To enable Client Certificate verification, add the following statements to the `10-ssl.conf` file (from the above section):

```
ssl.verifyclient.activate = "enable"
ssl.verifyclient.enforce = "enable"
ssl.verifyclient.depth = "10"
ssl.verifyclient.username = "SSL_CLIENT_S_DN_emailAddress"
```

The **.username** settings will name the value of the email address of the client's certificate to appear as the HTTP_REMOTE_USER variable in lighttpd (for downstream scripts and CGIs).

*NOTE:* For this to work, you'll need to create a new certificate (for each client), and install it (see other recipes).

### Security Considerations

1. This recipe *is not* secure.
2. It does not demonstrate good security practices (e.g. no passwords on private keys, no file-permission modifications, etc.).
3. It should be used **only** for testing and learning purposes.
4. The client-side-certificate is **only** as secure as your clients: if someone gains access to the client, he can steal the client's certificate.

