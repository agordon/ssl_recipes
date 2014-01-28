#!/bin/sh

URL="https://github.com/agordon/ssl_recipes"
LICENSE="BSD-3-Clause"
COPYRIGHT="Copyright (C) 2014 A. Gordon (assafgordon@gmail.com)"


# Password to unlock the CA's private key
CA_PASSWORD="12345"
# Password for the p12 file (used by web browsers, e.g. Firefox, iPhone)
P12_PASSWORD="123456"

DAYS=3650

OPEN_SSL_CONFIG_FILE=./openssl.cnf

CA_DIR="./CA"

# Silly Values for Server's certificate.
DEFAULT_COUNTRY_NAME="US"
DEFAULT_STATE_NAME="MA"
DEFAULT_CITY_NAME="Creek Mill"
DEFAULT_EMAIL_ADDRESS="joe@foobars.com"
DEFAULT_ORGANIZATION="Foo Bars, Inc."
DEFAULT_ORGANIZATION_UNIT="Marketing"

ASK_DETAILS=no

usage()
{
echo "
Self-Signed Certificate Generator

*** THIS SCRIPT SHOULD BE USED FOR EXPERIMENTATION ONLY ***
*** DO NOT USE THE GENERATED KEYS/CERTIFICATES IN PRODUCTION ENVIRONMENTS ***

Homepage: $URL
License:  $LICENSE
$COPYRIGHT

Usage: $0 [OPTIONS]

Options:
 -h, --help	show this help screen and exit.

 --ask          Ask the user for details (Name,Email,Organization, etc.)
		instead of using silly defaults. Since this script is geared
		towards SSL experimentation, the silly defaults should be fine.

 --ca-dir DIR	Create the KEY and Certificates and other required files
		in directory 'DIR' (default: '$CA_DIR').
		NOTE:
		The 'create_server_secrtificate.sh' script also uses '$CA_DIR'
		as the default. If you use a different directory, you'll have
		to specify it for that script as well.

 --config FILE	Use 'FILE' as the openssl configuration file
		(default: '$OPEN_SSL_CONFIG_FILE').
		NOTE:
		The provided 'openssl.cnf' file is pre-set to work best with
		these scripts. Using different configuration might break things.

 --ca-password X	Use 'X' as the password protecting the CA's private key
			(default: '$CA_PASSWORD').

 --p12-password X       Use 'X' as the password protecting the PKCS#12/P12 file.
                        (default: '$P12_PASSWORD').

Example:

  # First, create a CA (just once)
  \$ ./create_certificate_authoriy.sh
  Generating Certificate-Signing-Request (CSR) for new CA
  Generating Self-Signed Public Certificate for new CA

  Certificate Authority created
    directory: ./CA
    Public Certificate file (for distribution): ./CA/CA/public/ca_public_certificate.pem

  # Then create self-signed certificates for as many servers as you'd like:
  \$ $0 myserver.com
  Generating Key and Certificate Signing Request (CSR) for domain myserver.com ...
  Generating Public Certificate for domain myserver.com...
  Generating Public PEM for domain myserver.com ...
  Generating Combined Private+Certificate PEM file for domain myserver.com ...
  Generating PKCS12(PFX/P12) file for domain myserver.com ...

  Self-Signed Certificate created for 'myserver.com'

  Files created in: ./CA/servers/myserver.com :
    ./CA/servers/myserver.com/myserver.com.private.key.pem  - Private key (without password)
    ./CA/servers/myserver.com/myserver.com.public.crt       - Public Certificate (CRT format)
    ./CA/servers/myserver.com/myserver.com.public.pem       - Public Certificate (PEM format)
    ./CA/servers/myserver.com/myserver.com.combined.pem     - Private key AND Public Certificate,
                                                Combined into one file
                                                (PEM format, without password)
    ./CA/servers/myserver.com/myserver.com.p12              - PKCS#12/PFX file (containing both
                                                private key and public certificate,
                                                with password 123456

  # Create more certificates for more domains or clients
  \$ $0 foobar.org
  \$ $0 JohnDoe

Output files:

For a given domain (e.g. 'foobar'), the following files will be created
in directory '$CA_DIR/servers/foobar' :


   foobar.private.key.pem  - Private key (without password)

   foobar.public.crt       - Public Certificate (CRT format)

   foobar.public.pem       - Public Certificate (PEM format)

                             The above public CRT and PEM files contain the same
                             information in different formats (many programs requires either).

   foobar.combined.pem     - Private key AND Public Certificate, Combined into one file.
                             NOTE: The private key in this file is UN-PROTECTED.
                             Programs like 'stunnel' require this combined file format.
                             Servers like Apache2 and lighttpd can accept this combined file,
                             or use the individual KEY and CRT/PEM files.

   foobar.p12              - PKCS#12/PFX file (containing both private key and public certificate,
                             with password 123456). P12 files can be imported into a client
                             web browser (e.g. Firefox, Safari, Safari on iPhone)
                             when used for SSL-Client-Side-Certificates.

See files in directory 'recipes' for many examples of using these files.

"
}


##
## Parse command line
##
while test "$#" -gt 0 ;
do
	case "$1" in
	-h|--help)	usage
			exit
			;;
	--ask)		ASK_DETAILS=yes;;
	--ca-dir)	CA_DIR="$2"
			[ -z "$CA_DIR" ] && { echo "Error: CA-Directory must not be empty">&2 ; exit 1 ; }
			shift
			;;
	--ca-password)	CA_PASSWORD="$2"
			shift
			;;
	--key-password) KEY_PASSWORD="$2"
			shift
			;;
	--p12-password) P12_PASSWORD="$2"
			shift
			;;
	--config)	OPEN_SSL_CONFIG_FILE="$2"
			[ -z "$OPEN_SSL_CONFIG_FILE" ] && { echo "Error: Config file must not be empty">&2 ; exit 1 ; }
			shift
			;;
	-*)		echo "Error: unknown option '$1'. See --help for help">&2
			exit 1
			;;
	*)		# Any non-option parameter, assume it's the domain name.
			[ -z "$DOMAIN_NAME" ] || { echo "Error: Domain name already specified ($DOMAIN_NAME), Can't specify a second domain name ($1). See --help for details.">&2 ; exit 1 ; }
			DOMAIN_NAME="$1"
			[ -z "$DOMAIN_NAME" ] && { echo "Error: domain name must not be empty" >&2 ; exit 1 ; }
	esac
	shift;
done
[ -z "$DOMAIN_NAME" ] && { echo "Error: missing domain name. See --help for details." >&2 ; exit 1 ; }


##
## Sanitize Domain Name
##
SANITIZED_DOMAIN_NAME=$(echo "$DOMAIN_NAME" | tr -dc 'A-Za-z0-9.-')
[ "$SANITIZED_DOMAIN_NAME" = "$DOMAIN_NAME" ] || { echo "Error: invalid domain name ($DOMAIN_NAME) - must contain only letters,digits,period or dash." >&2 ; exit 1 ; }
# Make it lower case
DOMAIN_NAME=$(echo "$DOMAIN_NAME" | tr 'A-Z' 'a-z')

##
## Verify OpenSSL configuratino file
##
[ -e "$OPEN_SSL_CONFIG_FILE" ] || { echo "Error: openssl configuratino file ($OPEN_SSL_CONFIG_FILE) not found. Can not continue.">&2 ; exit 1 ; }


##
## Verify Previously-created CA directory
##
[ -d "$CA_DIR" ] || { echo "Error: CA directory ($CA_DIR) not found" >&2 ; exit 1 ; }
# This file is referenced from 'openssl.cnf', and must exist
[ -e "$CA_DIR/CA/private/ca_key.pem" ] || { echo "Error: CA directory ($CA_DIR) missing CA-Private-Key file ($CA_DIR/CA/private/ca_key.pem) - was it created with 'create_CA.sh' script?" >&2 ; exit 1 ; }

[ -d "$CA_DIR/servers" ] || { echo "Error: CA directory ($CA_DIR) missing the 'servers' sub-directory. - was it created with 'create_CA.sh' script?" >&2 ; exit 1 ; }

## Ensure it's a new server, not existing for this CA
[ -d "$CA_DIR/servers/$DOMAIN_NAME" ] && { echo "Error: Certificate already created for server '$DOMAIN_NAME'. To re-create it, delete the directory '$CA_DIR/servers/$DOMAIN_NAME' ." >&2 ; exit 1 ; }


##
## Ask for details (name, email, organization) if needed
##
if [ "$ASK_DETAILS" = "yes" ]; then
	printf "Enter Organization name [$DEFAULT_ORGANIZATION]: "
	read ORGANIZATION_NAME
	[ -z "$ORGANIZATION_NAME" ] && ORGANIZATION_NAME="$DEFAULT_ORGANIZATION"
	printf "Enter Organization Unit name [$DEFAULT_ORGANIZATION_UNIT]: "
	read ORGANIZATION_UNIT_NAME
	[ -z "$ORGANIZATION_UNIT_NAME" ] && ORGANIZATION_UNIT_NAME="$DEFAULT_ORGANIZATION_UNIT"
	printf "Enter Country [$DEFAULT_COUNTRY_NAME]: "
	read COUNTRY
	[ -z "$COUNTRY" ] && COUNTRY="$DEFAULT_COUNTRY_NAME"
	printf "Enter State/Province [$DEFAULT_STATE_NAME]: "
	read STATE
	[ -z "$STATE" ] && STATE="$DEFAULT_STATE_NAME"
	printf "Enter City/Locality [$DEFAULT_CITY_NAME]: "
	read CITY
	[ -z "$CITY" ] && CITY="$DEFAULT_CITY_NAME"
	printf "Enter Email [$DEFAULT_EMAIL_ADDRESS]: "
	read EMAIL
	[ -z "$EMAIL" ] && EMAIL="$DEFAULT_EMAIL_ADDRESS"
else
	[ -z "$ORGANIZATION_NAME" ] && ORGANIZATION_NAME="$DEFAULT_ORGANIZATION"
	[ -z "$ORGANIZATION_UNIT_NAME" ] && ORGANIZATION_UNIT_NAME="$DEFAULT_ORGANIZATION_UNIT"
	[ -z "$COUNTRY" ] && COUNTRY="$DEFAULT_COUNTRY_NAME"
	[ -z "$STATE" ] && STATE="$DEFAULT_STATE_NAME"
	[ -z "$CITY" ] && CITY="$DEFAULT_CITY_NAME"
	[ -z "$EMAIL" ] && EMAIL="$DEFAULT_EMAIL_ADDRESS"
fi


##
## Create server directory
##
SERVER_DIR="$CA_DIR/servers/$DOMAIN_NAME"
mkdir "$SERVER_DIR" || exit 1
LOG_FILE="$SERVER_DIR/log"


# Tech.Note:
# Out 'openssl.cnf' is specially configured to use environment variable CA_DIR
# as the base directory for the CA-related files.
# Look for 'dir=${ENV::CA_DIR}' in the 'openssl.cnf' file.
# If this variable isn't defined, 'openssl' will fail.
export CA_DIR

##Note: this beautiful hack allows an alternative Domain names to be signed with a single certificate.
## 1. Taken from here: http://blog.loftninjas.org/2008/11/11/configuring-ssl-requests-with-subjectaltname-with-openssl/
## 2. The SAN environment variable is used in "openssl.cnf" file to read the list of domains.
## 3. Seems like the alternative domains OVERRIDE the common name.
##    So the common-name should be listed here as well
##    (i.e. if the common name is "foo.cshl.edu" and the alternative name just is "bar.cshl.edu",
##     then "foo.cshl.edu" is not used as a valid signed server).
##  4. The following signs both the root server, and a wildcard of sub domains.
export SAN="DNS:$DOMAIN_NAME, DNS:*.$DOMAIN_NAME"

SETTINGS="$COUNTRY
$STATE
$CITY
$ORGANIZATION_NAME
$ORGANIZATION_UNIT_NAME
$DOMAIN_NAME
$EMAIL

"

echo "Generating Key and Certificate Signing Request (CSR) for domain $DOMAIN_NAME ..." | tee -a "$LOG_FILE"
echo "$SETTINGS" | \
    openssl req -new -keyout "$SERVER_DIR/$DOMAIN_NAME.private.key.pem" \
		    -config "$OPEN_SSL_CONFIG_FILE" \
		    -out "$SERVER_DIR/$DOMAIN_NAME.csr.pem" \
		    -nodes \
		    -days "$DAYS" >> "$LOG_FILE" 2>&1
if [ "$?" -ne 0 ]; then
	echo ""
	echo "Error: creating KEY & CSR for domain $DOMAIN_NAME failed." >&2
	echo "       more information can be cound in the log file ($LOG_FILE):" >&2
	exit 1
fi

echo "Generating Public Certificate for domain $DOMAIN_NAME... " | tee -a "$LOG_FILE"
yes | openssl ca -policy policy_anything \
	-config "$OPEN_SSL_CONFIG_FILE" \
	-passin pass:"$CA_PASSWORD" \
	-out "$SERVER_DIR/$DOMAIN_NAME.public.crt" \
	-infiles "$SERVER_DIR/$DOMAIN_NAME.csr.pem" >> $LOG_FILE 2>&1
if [ "$?" -ne 0 ]; then
	echo ""
	echo "Error: Creating Public Certificate for domain $DOMAIN_NAME failed." >&2
	echo "       more information can be cound in the log file ($LOG_FILE):" >&2
	exit 1
fi

echo "Generating Public PEM for domain $DOMAIN_NAME ... " | tee -a "$LOG_FILE"
openssl x509 -in "$SERVER_DIR/$DOMAIN_NAME.public.crt" \
	-out "$SERVER_DIR/$DOMAIN_NAME.public.pem" \
	-outform PEM >> "$LOG_FILE" 2>&1
if [ "$?" -ne 0 ]; then
	echo ""
	echo "Error: Creating Public PEM for domain $DOMAIN_NAME failed." >&2
	echo "       more information can be cound in the log file ($LOG_FILE):" >&2
	exit 1
fi

echo "Generating Combined Private+Certificate PEM file for domain $DOMAIN_NAME ..."
( cat "$SERVER_DIR/$DOMAIN_NAME.private.key.pem" \
	"$SERVER_DIR/$DOMAIN_NAME.public.pem" ; \
	echo "" ) > "$SERVER_DIR/$DOMAIN_NAME.combined.pem"

echo "Generating PKCS12(PFX/P12) file for domain $DOMAIN_NAME ..."
openssl pkcs12 -nodes \
	-inkey "$SERVER_DIR/$DOMAIN_NAME.private.key.pem" \
	-in "$SERVER_DIR/$DOMAIN_NAME.public.crt" \
	-export \
	-out "$SERVER_DIR/$DOMAIN_NAME.p12" \
	-name "$DOMAIN_NAME" \
	-passout pass:"$P12_PASSWORD"
if [ "$?" -ne 0 ]; then
	echo ""
	echo "Error: Creating P12 for domain $DOMAIN_NAME failed." >&2
	echo "       more information can be cound in the log file ($LOG_FILE):" >&2
	exit 1
fi

echo ""
echo "Self-Signed Certificate created for '$DOMAIN_NAME'"
echo ""
echo "Files created in: $SERVER_DIR :"
echo "  $SERVER_DIR/$DOMAIN_NAME.private.key.pem  - Private key (without password)"
echo "  $SERVER_DIR/$DOMAIN_NAME.public.crt       - Public Certificate (CRT format)"
echo "  $SERVER_DIR/$DOMAIN_NAME.public.pem       - Public Certificate (PEM format)"
echo "  $SERVER_DIR/$DOMAIN_NAME.combined.pem     - Private key AND Public Certificate,"
echo "                                              Combined into one file"
echo "                                              (PEM format, without password)"
echo "  $SERVER_DIR/$DOMAIN_NAME.p12              - PKCS#12/PFX file (containing both"
echo "                                              private key and public certificate,"
echo "                                              with password $P12_PASSWORD"
echo ""
