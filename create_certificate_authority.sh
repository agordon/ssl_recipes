#!/bin/sh

URL="https://github.com/agordon/ssl_recipes"
LICENSE="BSD-3-Clause"
COPYRIGHT="Copyright (C) 2014 A. Gordon (assafgordon@gmail.com)"


## This script asks the user for common configuration values.
## These will be used to create the certificates by other scripts.
##

# The default password for the CA's private key. NOT SECURE!
# Just for demonstrating purposes.
PASSWORD="12345"
DAYS=3650

# Default directory for this new CA
CA_DIR=$(dirname "$0")/CA

# Default location of the openssl.cnf file.
OPEN_SSL_CONFIG_FILE=$(dirname "$0")/openssl.cnf

# If 'yes', user will be asked for details (name,organization,country,state,email,etc)
# If 'no', default (silly) values will be used.
ASK_DETAILS=no

# Silly default values for the Certificate Authority
# Hopefully it will be obviously to users this is a demonstration only, and should not be trusted.
DEFAULT_CA_COMMON_NAME="Trusted-R-US.com"
DEFAULT_COUNTRY_NAME="US"
DEFAULT_STATE_NAME="NY"
DEFAULT_CITY_NAME="Elephant Hills"
DEFAULT_EMAIL_ADDRESS="trusty@trusted-r-us.com"
DEFAULT_ORGANIZATION="Trusted-R-Us Inc."
DEFAULT_ORGANIZATION_UNIT="IT Department"

usage()
{
echo "
Self-Signed Certificate Authority Generator

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

 --password X	Use 'X' as the password protecting the CA's private key
		(default: '$PASSWORD').
		NOTE:
		The 'create_server_secrtificate.sh' script also uses '$PASSWORD'
		as the default. If you use a different password, you'll have
		to specify it for that script as well.

Example:

  # Run this script once, to create one Root CA:
  \$ $0
  Generating Certificate-Signing-Request (CSR) for new CA
  Generating Self-Signed Public Certificate for new CA

  Certificate Authority created
    directory: ./CA
    Public Certificate file (for distribution): ./CA/CA/public/ca_public_certificate.pem

  # Then create self-signed certificates for as many servers as you'd like:
  \$ ./create_certificate.sh myserver.com
  \$ ./create_certificate.sh foobar.org
  \$ ./create_certificate.sh yahoo.com

Output files:

In the '$CA_DIR' directory, the followings will be created:

   $CA_DIR/CA/private/ca_key.pem -
	This is the CA's private Key. With a real CA, this is the most
	important file. DO NOT SHARE IT.  If it's lost or leaked or compromised,
	You security is effectively broken, as anyone can fake a new
	certificates as this CA.
	In this SSL demonstration script, the key is protected by a password
	(default '$PASSWORD').


    $CA_DIR/CA/public/ca_public_certificate.pem -
	This is the public root certificate for this CA.
	This file can (should) be distributed to all clients connecting to
	any server whose certificate is signed by this CA.
	See the 'recipes' directory for examples of installing this root
	certificate on different clients (e.g. Firefox, iPhone, etc.)

    $CA_DIR/servers -
	Newly created keys and certificates for servers will be placed here.

    $CA_DIR/log -
	If anything goes wrong during CA generationg, check this file.
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
	--password)	PASSWORD="$2"
			shift
			;;
	--config)	OPEN_SSL_CONFIG_FILE="$2"
			[ -z "$OPEN_SSL_CONFIG_FILE" ] && { echo "Error: Config file must not be empty">&2 ; exit 1 ; }
			shift
			;;
	*)		echo "Error: unknown option '$1'. See --help for help">&2
			exit 1
			;;
	esac
	shift;
done

##
## Verify OpenSSL Config File
##
[ -e "$OPEN_SSL_CONFIG_FILE" ] || { echo "Error: openssl configuratino file ($OPEN_SSL_CONFIG_FILE) not found. Can not continue.">&2 ; exit 1 ; }

##
## Verify new CA directory
##
if [ -d "$CA_DIR" ]; then
	echo "Error: CA directory ($CA_DIR) already exists. Delete it to create a new CA, or use '--ca-dir DIR' to specify a different directory. see --help for more detauls." >&2
	exit 1
fi


##
## Set CA's details
##
if [ "$ASK_DETAILS" = "yes" ]; then
	printf "Enter Common Name [$DEFAULT_CA_COMMON_NAME]: "
	read CA_COMMON_NAME
	[ -z "$CA_COMMON_NAME" ] && CA_COMMON_NAME="$DEFAULT_CA_COMMON_NAME"
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
	[ -z "$CA_COMMON_NAME" ] && CA_COMMON_NAME="$DEFAULT_CA_COMMON_NAME"
	[ -z "$ORGANIZATION_NAME" ] && ORGANIZATION_NAME="$DEFAULT_ORGANIZATION"
	[ -z "$ORGANIZATION_UNIT_NAME" ] && ORGANIZATION_UNIT_NAME="$DEFAULT_ORGANIZATION_UNIT"
	[ -z "$COUNTRY" ] && COUNTRY="$DEFAULT_COUNTRY_NAME"
	[ -z "$STATE" ] && STATE="$DEFAULT_STATE_NAME"
	[ -z "$CITY" ] && CITY="$DEFAULT_CITY_NAME"
	[ -z "$EMAIL" ] && EMAIL="$DEFAULT_EMAIL_ADDRESS"
fi

##
## Create a new directory structure to store the CA files.
##
mkdir "$CA_DIR" || exit 1
mkdir "$CA_DIR/CA" || exit 1
mkdir "$CA_DIR/CA/private" || exit 1
mkdir "$CA_DIR/CA/public" || exit 1
mkdir "$CA_DIR/CA/newcerts" || exit 1
mkdir "$CA_DIR/CA/CSRS/" || exit 1
mkdir "$CA_DIR/servers" || exit 1
touch $CA_DIR/CA/index.txt
echo 01 > $CA_DIR/CA/crtnumber
LOG_FILE="$CA_DIR/CA/log"




SETTINGS="$COUNTRY
$STATE
$CITY
$ORGANIZATION_NAME
$ORGANIZATION_UNIT_NAME
$CA_COMMON_NAME
$EMAIL

"

# Tech.Note:
# Out 'openssl.cnf' is specially configured to use environment variable CA_DIR
# as the base directory for the CA-related files.
# Look for 'dir=${ENV::CA_DIR}' in the 'openssl.cnf' file.
# If this variable isn't defined, 'openssl' will fail.
export CA_DIR

# Tech.Note:
# Our 'openssl.cnf' is specially configured to use environment variable SAN
# for SubjectAlternativeName open - but it's not needed when creating the CA.
# It will be used for signing certificates with wild-card domains.
# If this variable isn't defined, 'openssl' will fail.
export SAN=""

echo "Generating Certificate-Signing-Request (CSR) for new CA" | tee -a "$LOG_FILE"
echo "$SETTINGS" | \
    openssl req -new -config "$OPEN_SSL_CONFIG_FILE" \
          -keyout "$CA_DIR/CA/private/ca_key.pem" \
          -out "$CA_DIR/CA/CSRS/ca_csr.pem" \
          -passout pass:"$PASSWORD" >> "$LOG_FILE" 2>&1
if [ "$?" -ne 0 ]; then
	echo ""
	echo "Error: creating CSR for CA failed." >&2
	echo "       more information can be cound in the log file ($LOG_FILE):" >&2
	exit 1
fi


echo "Generating Self-Signed Public Certificate for new CA" | tee -a "$LOG_FILE"
openssl ca -create_serial -passin pass:"$PASSWORD" \
	-config "$OPEN_SSL_CONFIG_FILE" \
	-out "$CA_DIR/CA/public/ca_public_certificate.pem" \
	-outdir "$CA_DIR/CA/newcerts" \
	 -days "$DAYS" -batch \
	-keyfile "$CA_DIR/CA/private/ca_key.pem" \
	-selfsign -extensions v3_ca \
	-infiles "$CA_DIR/CA/CSRS/ca_csr.pem" >> "$LOG_FILE" 2>&1

if [ "$?" -ne 0 ]; then
	echo ""
	echo "Error: creating Self-Signed public certificate for CA failed." >&2
	echo "       more information can be cound in the log file ($LOG_FILE):" >&2
	exit 1
fi

echo ""
echo "Certificate Authority created"
echo "  directory: $CA_DIR"
echo "  Public Certificate file (for distribution): $CA_DIR/CA/public/ca_public_certificate.pem"
echo ""
