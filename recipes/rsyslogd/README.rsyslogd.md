# TODO: rsyslogd

[rsyslogd](http://www.rsyslog.com/) is an enhanced syslogd server for linux, supporting remote logging, with secure connection and reliable message delivery.

### Pre-requisites:

1. rsyslogd 7.5.8 (or later)
2. libRelp + tls support

More info: [rsyslogd SSL manual](http://www.rsyslog.com/doc/rsyslog_secure_tls.html)

More more info: [rsyslogd + RELP + TLS](http://www.rsyslog.com/using-tls-with-relp/)

### Certificates:

1. Create CA
2. Create Server certificate
3. Create client certificate


### Configuration


#### client configuration


Client Config file:

```
module(load="imuxsock" SysSock.Use="off")
module(load="omrelp")

input(type="imuxsock" Socket="/tmp/client.sock" CreatePath="on")
action(type="omrelp" target="127.0.0.1" port="20514" tls="on"
	tls.caCert="/FULL/PATH/ca_public_certificate.pem"
	tls.myCert="/FULL/PATH/rs-client.public.pem"
	tls.myPrivKey="/FULL/PATH/rs-client.private.key"
	tls.authmode="name"
	tls.permittedpeer=["rs-server"])
```

Client command line:

```sh
 $ /usr/local/sbin/rsyslogd -n -f $PWD/client.conf -i /tmp/client.pid
```


#### Server configuration

Server configu file:

```
module(load="imrelp" ruleset="relp")
input(type="imrelp" port="20514" tls="on"
	tls.caCert="/FULL/PATH/ca_public_certificate.pem"
	tls.myCert="/FULL/PATH/rs-server.public.pem"
	tls.myPrivKey="/FULL/PATH/rs-server.private.key"
	tls.authMode="name"
	tls.permittedpeer=["rs-client"])
ruleset (name="relp") { action(type="omfile" file="/tmp/rsyslogd.log") }
```

Server command line:

```sh
$ /usr/local/sbin/rsyslogd -n -f $PWD/server.conf -i /tmp/server.pid
```

#### Testing

Open four terminal windows:

1. Run server
2. Run client
3. Run `tail -f /tmp/rsyslogd.log`
4. Send log messages: `echo "Hello Relp/TLS World" | logger -u /tmp/client.sock -d`

