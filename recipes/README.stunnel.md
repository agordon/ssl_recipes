# TODO: stunnel

[stunnel](https://www.stunnel.org/index.html) is an SSL encryption wrapper.

### Certificates:

1. Create CA
2. Create communication certificate (use it on both sides, not secure)

### Running

Open two terminal windows on the server:

1. Run the "real" server: `nc -l -p 1111`
2. Run stunnel for the server side: `stunnel -p communication.pem -f -d 1112 -r localhost:1111 -P /tmp/stunnel.server.pid`

Open two terminal windows on the client:

1. Run stunnel for the client side: `stunnel -p communication.pem -f -c -d 1113 -r server-or-ip:1112 -P /tmp/stunnel.client.pid`
2. Run the "real" client: `nc localhost 1113`

Type something on the "real client" (and press ENTER).

The message should appear on the "real server".

