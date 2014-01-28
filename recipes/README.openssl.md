# TODO

### Basic command

```sh
$ printf "GET / HTTP/0.9\r\n" | \
     openssl s_client -CAfile ca_public_certificate.pem \
                      -connect myserver.com:443 -ssl3 -crlf -quiet
```

Successful certificate validation will produce:

```
verify return:1
depth=0 /C=US/ST=MA/L=Creek Mill/O=Foo Bars, Inc./OU=Pre-Sales/CN=housegordon.com/emailAddress=joe@foobars.com
verify return:1
```

Unsuccessful validation will produce:

```
depth=1 /C=US/ST=NY/O=Trusted-R-Us Inc./OU=IT Department/CN=Trusted-R-US.com/emailAddress=trusty@trusted-r-us.com
verify error:num=19:self signed certificate in certificate chain
verify return:0
```


**NOTE:** openssl will continue to send our HTTP request to the server,
regardless of whether the server's certificate validated or not.




