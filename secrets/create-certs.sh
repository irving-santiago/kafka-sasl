#!/bin/bash

set -o nounset \
    -o errexit \
    -o verbose \
    -o xtrace

pass=confluent

# Generate CA key
openssl req -new -x509 -keyout __snakeoil-ca-1.key -out __snakeoil-ca-1.crt -days 365 -subj '/CN=ca1.test.confluent.io/OU=TEST/O=CONFLUENT/L=PaloAlto/S=Ca/C=US' -passin pass:$pass -passout pass:$pass

# Kafkacat
openssl genrsa -des3 -passout "pass:$pass" -out __kafkacat.client.key 1024
openssl req -passin "pass:$pass" -passout "pass:$pass" -key __kafkacat.client.key -new -out __kafkacat.client.req -subj '/CN=ca1.test.confluent.io/OU=TEST/O=CONFLUENT/L=PaloAlto/S=Ca/C=US'
openssl x509 -req -CA __snakeoil-ca-1.crt -CAkey __snakeoil-ca-1.key -in __kafkacat.client.req -out __kafkacat-ca1-signed.pem -days 9999 -CAcreateserial -passin "pass:$pass"

for i in kafka client
do
	echo $i
	mkdir ./$i
	# Create keystores
	keytool -genkey -noprompt \
				 -alias $i \
				 -dname "CN=$i, OU=Dev, O=CONFLUENT, L=PaloAlto, S=Ca, C=US" \
				 -keystore ./$i/keystore.jks \
				 -keyalg RSA \
				 -storepass $pass \
				 -keypass $pass

	# Create CSR, sign the key and import back into keystore
	keytool -keystore ./$i/keystore.jks -alias $i -certreq -file __$i.csr -storepass $pass -keypass $pass -noprompt

  openssl x509 -req -CA __snakeoil-ca-1.crt -CAkey __snakeoil-ca-1.key -in __$i.csr -out __$i-ca1-signed.crt -days 9999 -CAcreateserial -passin pass:$pass

	keytool -keystore ./$i/keystore.jks -alias CARoot -import -file __snakeoil-ca-1.crt -storepass $pass -keypass $pass -noprompt

  keytool -keystore ./$i/keystore.jks -alias $i -import -file __$i-ca1-signed.crt -storepass $pass -keypass $pass -noprompt

	# Create truststore and import the CA cert.
	keytool -keystore ./$i/truststore.jks -alias CARoot -import -file __snakeoil-ca-1.crt -storepass $pass -keypass $pass -noprompt

  echo "$pass" > ./$i/sslkey_creds
  echo "$pass" > ./$i/keystore_creds
  echo "$pass" > ./$i/truststore_creds

done

rm -rf __*
