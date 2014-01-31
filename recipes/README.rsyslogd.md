# rsyslogd - Reliable, Encrypted, Remote logging

[rsyslogd](http://www.rsyslog.com/) is an enhanced syslogd server for linux, supporting remote logging, with secure connection and reliable message delivery.

[libRELP](http://www.librelp.com/) is a reliable logging library, designed to
address some reliability issues with traditional syslog mechanisms.

More info: [rsyslogd SSL manual](http://www.rsyslog.com/doc/rsyslog_secure_tls.html)

More more info: [rsyslogd + RELP + TLS](http://www.rsyslog.com/using-tls-with-relp/)

### Flow diagram


```
+--------------------------+
| Client Source Events     |
|--------------------------|
|(any program which        |
| generates text messages) |
+-------------+------------+
              |                                        +-----------------------+
              |                                        |  Log Destination      |
+-------------v---------------+                        |-----------------------|
| Unix 'logger' program       |                        |Text Fie, or           |
|-------------------------- --|                        |other rsyslogd supported
|Standard unix program,       |                        |destinations           |
|sends messages to unix socket|                        +-----------^-----------+
+-------------+---------------+                                    |
              |                                                    |
              |                                                    |
              |                                                    |
+-------------v---------------+                    +---------------+-------------+
| RSYSLOGD (client config.)   |                    |  RSYSLOGD (server config.)  |
|-----------------------------|   Encrypted        |-----------------------------|
|Receives msg from Unix Socket|   Communication    |Receives msg from TCP        |
|                             +-------------------->  using libRELP, and TLS     |
|Sends Messages to server     |                    |                             |
|   using libRELP,            |                    |Writes messages to log file. |
|   and TLS encryption.       |                    |                             |
+-----------------------------+                    +-----------------------------+
```

### Pre-requisites:

1. rsyslogd 7.5.8 (or later)
2. libRelp + tls support

### Required Certificates:

1. Create Root CA files
    By running `./create_certificate_authority.sh`.

    A file named `ca_public_certificate.pem` will be created (in `./CA/`).
    This is the file which will be used later with both the client and the server machines.

2. Create Server certificate
    Run `./create_certificate.sh rs-server` to create certificates for the server (`rs-server` is just an example for the server name. You can use any identifier you want).

    Several files will be created in the `./CA/servers/rs-server/` directory.
    You will need to copy `rs-server.certificate.pem` and `rs-server.private.key` to the server machine.

3. Create client certificate
    Run `./create_certificate.sh rs-client` to create certificates for the client (`rs-client` is just an example for the client name. You can use any identifier you want).

    Several files will be created in the `./CA/servers/rs-client/` directory.
    You will need to copy `rs-client.certificate.pem` and `rs-client.private.key` to the client machine.

### Configuration

The following configuration demonstrates extabilishing encrypted TLS connection
between a client and a server rsyslog processes. For the purpose of the demonstration,
both programs can be started on the same machine (in which case, change the target IP
to '127.0.0.1').

#### Server configuration

##### Create the following Server configuration file (`server.conf`):

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

Note the following configuration options:

1. **imrelp** is the Input Module for libRELP.
2. The server rsyslog is configured to listen on TCP port 20514.
3. TLS is turned on, and the three required files are provided (NOTE: rsyslogd
    requires full path to all files. Adapt your configuration for based on the
    locations of theses files on your computer).
4. **permitted peers** option will require the sending client's names to match.
5. The **ruleset** is a simple configuration to incoming messages to a file
    (must use full path for the log file name).

##### To start the server, use the following command:

```sh
$ /usr/local/sbin/rsyslogd -n -f $PWD/server.conf -i /tmp/server.pid
```

1. At the time of this writing, most linux distributions use an older version of rsyslogd.
    To use these options (libRELP+TLS) you'll likely need to recompile rsyslog from source code,
    or download the packages from the rsyslogd website.
2. Using `-n` will prevent rsyslogd from forking into the background - Use this for debugging
    and testing purposes, as error messages will appear on the screen.
3. Using a custom configuration file (`-f`) requires a full path (which is why `$PWD` is needed).
4. Your system is likely to already have a running rsyslogd program. Using a different
    PID file (`-i`) allows multiple rsyslogd instances to run on the same machine.



#### client configuration

##### Create the follwing client Config file (`client.conf`):

```
module(load="imuxsock" SysSock.Use="off")
module(load="omrelp")

input(type="imuxsock"
      Socket="/tmp/client.sock"
      CreatePath="on")
action(type="omrelp"
        target="127.0.0.1" port="20514"
        tls="on"
	tls.caCert="/FULL/PATH/ca_public_certificate.pem"
	tls.myCert="/FULL/PATH/rs-client.public.pem"
	tls.myPrivKey="/FULL/PATH/rs-client.private.key"
	tls.authmode="name"
	tls.permittedpeer=["rs-server"]
	action.resumeRetryCount="-1"
	action.resumeInterval="5"
	)
```

Note the following configuration options:

1. **imuxsock** is the input module: this rsyslogd process will accept log messages
    from a unix socket. With `SysSock.use="off"`, this process will not interfere
    with the system's default logging socket (for testing purposes).
2. **omrelp** is the Output Module for libRELP.
3. The client rsyslog is configured to send messages to an rsyslogd server on
    IP **127.0.0.1** (which is the local machine). If you run the server rsyslogd
    and the client rsyslogd on different machines, use the server's IP address here.
4. TLS is turned on, and the three required files are provided (NOTE: rsyslogd
    requires full path to all files. Adapt your configuration for based on the
    locations of theses files on your computer).
5. **permitted peers** option will require the sending server's name to match.
6. **action.resumeRetryCount** will enable retransmission of messages if the connection
    between the client and the server was interrupted (this is what enables the *reliability*
    in libRELP).

##### To start the client, use the following command line:

```sh
 $ /usr/local/sbin/rsyslogd -n -f $PWD/client.conf -i /tmp/client.pid
```

1. At the time of this writing, most linux distributions use an older version of rsyslogd.
    To use these options (libRELP+TLS) you'll likely need to recompile rsyslog from source code,
    or download the packages from the rsyslogd website.
2. Using `-n` will prevent rsyslogd from forking into the background - Use this for debugging
    and testing purposes, as error messages will appear on the screen.
3. Using a custom configuration file (`-f`) requires a full path (which is why `$PWD` is needed).
4. Your system is likely to already have a running rsyslogd program. Using a different
    PID file (`-i`) allows multiple rsyslogd instances to run on the same machine.


#### Testing

On the server machine, open two terminal windows, and run the following:

1. Start the rsyslogd server (as described above). The server will stay in
    the foreground, so keep this terminal window open, and note any error messages.
2. Use `tail -f /tmp/rsyslogd.log` to wait for any messages received by the server.
    (NOTE: The log file might not be created until messages arrived).

On the client machine (which can be the same machine as the server), open two
terminal windows, and run the following:

1. Run the client server (as described above). The client will stay in the foreground,
    so keep this terminal window open, and note any error messages.
2. To send log messages, use the standard linux `logger` program, but direct
    the message to our custom unix socket (from which the client rsyslogd program
    is reading messages):

    `echo "Hello World" | logger -u /tmp/client.sock -d`

If configured correctly, the message "Hello World" should appear in the log file on the server.

