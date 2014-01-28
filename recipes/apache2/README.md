## Apache2 - Installing Self-Signed Server Certificate

This recipe shows how to setup Apache2 webserver to use the self-signed SSL certificates.

### Generating Certificates

**Step 1** - Create certificate Authority:

```sh
$ ./create_certificate_authoriy.sh
```

A file named `ca_public_certificate.pem` will be created (in `./CA/`), and this file should be copied to the server running apache.

**Step 2** - Create certificate for the server:

```sh
$ ./create_certificate.sh myserver.com
```

1. The domain name `myserver.com` should match your domain name.
2. The generated certificate automatically includes all subdomains (e.g. `www.myserver.com` and `foo.bar.myserver.com` are all included).
3. A file named `myserver.com.combined.pem` will be created (in `./CA/servers/myserver.com`) and should be copied to the server running apache.

### Enabling SSL on Apache

This guide will not cover Apache/SSL configuration in details (there are better tutorials on line). In general, the following should exist:

1. An SSL module file (in `./mods-available/ssl.conf`). To enable it, run `sudo a2enmod ssl`
2. An SSL default configuration (in `./sites-available/default-ssl`, at least in Debian/Ubuntu). To Enable it, run `sudo a2ensite default-ssl`.
3. Restarting apache, run `sudo /sbin/service apache2 restart`
4. Verify that apache server is listening on port 443 (HTTPS port), by running `sudo netstat -ntlp | grep 443` - This should list the apache/httpd process.

### Adding the Self-signed certificates

Open the file `default-ssl`, and add the following two statements (update the file paths as necessary):

```
<IfModule mod_ssl.c>
<VirtualHost _default_:443>
        ServerAdmin webmaster@localhost
        ServerName myserver.com

        SSLCertificateFile    /FULL/PATH/myserver.com.combined.pem
        SSLCACertificateFile  /FULL/PATH/ca_public_certificate.pem
        <...>
```

Restart apache with `sudo /sbin/service apache2 restart`, and the new self-signed certificates should take effect.


### Enabling Client-Side-Certificates

Client-Side-Certificates allow the **apache server** to authenticate the client.
The client will send its certificate to the server (and since the client's certificate is signed by our Root CA, and the server has the Root CA's certificate, the client's certificate will be valid).

Clients without a valid certificate will not be able to complete the SSL handshake with the server, and will be rejected.

To enable Client Certificate verification, add the following statements to the `default-ssl` file (from the above section):

```
        SSLUserName SSL_CLIENT_S_DN_CN
        SSLVerifyClient require
```

The **SSLUserName** settings will name the value of the "Common Name" of the client's certificate to appear as the HTTP_REMOTE_USER variable in Apache (for downstream scripts and CGIs).

*NOTE:* For this to work, you'll need to create a new certificate (for each client), and install it (see other recipes).

### Security Considerations

1. This recipe *is not* secure.
2. It does not demonstrate good security practices (e.g. no passwords on private keys, no file-permission modifications, etc.).
3. It should be used **only** for testing and learning purposes.
4. The client-side-certificate is **only** as secure as your clients: if someone gains access to the client, he can steal the client's certificate.
