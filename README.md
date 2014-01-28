# SSL (self-signed) certificate recipes

This repository contains scripts and examples (tested!) of creating and using self-signed SSL certificates in common programs and scenarios.

This is not a program per-se, just a collection of useful information.

## Note about Security

The scripts and examples are for demonstration purposes **only**. They should not be used in a production environment - but could be used to test and debug encrypted connection and servers.

## Typical Usage


1) create a self-signed certificate authority (just once):

```sh
$ ./create_certificate_authority.sh
Generating Certificate-Signing-Request (CSR) for new CA
Generating Self-Signed Public Certificate for new CA

Certificate Authority created
  directory: ./CA
  Public Certificate file (for distribution): ca_public_certificate.pem
```

2) Create self-signed certificates for as many servers and clients as you want:

```sh
$ ./create_certificate.sh myserver.com
Generating Key and Certificate Signing Request (CSR) for domain myserver.com ...
Generating Public Certificate for domain myserver.com...
Generating Public PEM for domain myserver.com ...
Generating Combined Private+Certificate PEM file for domain myserver.com ...
Generating PKCS12(PFX/P12) file for domain myserver.com ...

Self-Signed Certificate created for 'myserver.com'

Files created in: ./CA/servers/myserver.com :
  myserver.com.private.key.pem  - Private key (without password)
  myserver.com.public.crt       - Public Certificate (CRT format)
  myserver.com.public.pem       - Public Certificate (PEM format)
  myserver.com.combined.pem     - Private key AND Public Certificate,
                                  Combined into one file
                                 (PEM format, without password)
  myserver.com.p12              - PKCS#12/PFX file (containing both
                                  private key and public certificate,
                                  with password 123456
```

3) Configure your servers to use the certificates from step 2.

4) Distrubte the Root CA's public certificate to your clients (e.g. Firefox / iPhone / cURL / etc. )


## Recipes

The following examples are in the `./recipes` directory:

1. Installing Root CA's certificate on clients
    *. Windows, Mac-OS, iPhone/iPad, Firefox, Chrome
2. **Apache2** Server Configuration
    1. Typical Server-side SSL (self-signed certificate)
    2. SSL-Client-Side-Certificate (where server authentications the client)
3. **Lighttpd** Server Configuration
    1. Typical Server-side SSL (self-signed certificate)
    2. SSL-Client-Side-Certificate (where server authentications the client)
4. Using **cURL** (server-side + client-side)
5. Using **wget** (server-side + client-side)
6. Creating secure network tunnel with **stunnel**
7. Creating secure remote logging with **rsyslogd**
8. Installing and Using Client-Side-Certificates on clients
    *. Firefox, iPhone/iPad


## Contributing

Suggestions for improvements (or bug fixes) are welcomed, as well as new recipes for more programs.


## Info

License: BSD-3-Clause

Copyright (C) 2014 A. Gordon ( AssafGordon@gmail.com )

