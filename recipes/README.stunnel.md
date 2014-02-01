# stunnel

[stunnel](https://www.stunnel.org/index.html) is an SSL encryption wrapper.

It can be used to transparently encrypt TCP connections between a client and a server.

### Flow diagram:

```
   +-------------------------+
   | "Real" Server           |                +--------------------+
   |-------------------------|                |   Client           |
   |netcat (nc)              |                |--------------------|
   |                         |                | Netcat(nc)         |
   |listening on             |                |                    |
   |  localhost:1111         |                | Sending messages to|
   |                         |                |  localhost:1113    |
   |Displaying messages      |                |                    |
   |  on screen              |                +---------+----------+
   +-------------------------+                          |
              ^                                         |
              |                                         |
              |                                         |
              |                                         |
              |                                         |
    +---------+-----------------+             +---------v----------+
    | Server STunnel            |             |  Client STunnel    |
    |---------------------------|             |--------------------|
    |Listening for ENCRYPTED    |             |Listening on        |
    | connections on            |             |   Localhost:1113   |
    |  Localhost:1112           |             |                    |
    |                           <-------------+                    |
    |Forwardning messages to    |             |Sending ENCRYPTED   |
    |  Localhost:1111           |             | messages to        |
    |                           |             |    localhost:1112  |
    +---------------------------+             +--------------------+
```

### Certificates:

1. Create CA:

    `./create_certificate_authority.sh`

2. Create communication certificates

    `./create_certificate.sh srvr`

    `./create_certificate.sh clnt`

### Using same certificate for both sides

This is a less secure option, but it works, none-the-less. The server and the client programs
can use the same certificate file, without requiring a certificate authority.

Start the following programs, each a new terminal window:

1. "Real" Server program (Listening on port 1111): `nc -l 127.0.0.1 1111`
2. Server STUNNEL: `stunnel    -p srvr.combined.pem -f -d 1112 -r 127.0.0.1:1111 -P /tmp/srvr.pid`
3. Client STUNNEL: `stunnel -c -p srvr.combined.pem -f -d 1113 -r 127.0.0.1:1112 -P /tmp/clnt.pid`
4. Send a message from the "real" clinet: `echo Hello World | nc 127.0.0.1 1113`

The message should appear on the "real server".


### Using a different certificate for each side

When using different certificates on each side, you must specifiy the Root CA
file (for each stunnel to be able to validate the other's certificate).

Open two terminal windows on the server:

1. Run the "real" server: `nc -l 127.0.0.1 1111`
2. Run stunnel for the server side: `stunnel    -A .ca_public_certificate.pem -p srvr.combined.pem -f -d 1112 -r 127.0.0.1:1111 -P /tmp/srvr.pid`
3. Run stunnel for the client side: `stunnel -c -A .ca_public_certificate.pem -p clnt.combined.pem -f -d 1113 -r 127.0.0.1:1112 -P /tmp/clnt.pid`
4. Send a message from the "real" clinet: `echo Hello World | nc 127.0.0.1 1113`

The message should appear on the "real server".

### Try it!

The following should 'just work', and open four terminal windows (copy & paste it into a terminal):

```sh
./create_certificate_authority.sh
./create_certificate.sh srvr
./create_certificate.sh clnt

# Start 'real server'
xterm -T "Real Server" -hold -e "nc -l 127.0.0.1 1111" &

# Start the 'stunnel' server
xterm -T "Stunnel-Server-Side" -hold -e \
   "stunnel -A ./CA/CA/public/ca_public_certificate.pem  \
            -p ./CA/servers/srvr/srvr.combined.pem -f -d 1112 \
            -r 127.0.0.1:1111 -P /tmp/srvr.pid" &

# Start the 'stunnel' client
xterm -T "Stunnel-Client-Side" -hold -e \
    "stunnel -c -A ./CA/CA/public/ca_public_certificate.pem \
                -p ./CA/servers/clnt/clnt.combined.pem \
                -f -d 1113 -r localhost:1112 -P /tmp/clnt.pid" &

# Give them all a chance to start
sleep 1

# Send a message from the client
xterm -T "Real Client" -hold -e "echo Hello World | nc localhost 1113" &
```

