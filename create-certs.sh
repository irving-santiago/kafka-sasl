#!/bin/bash

set +x
cd secrets

pass=devpassword
dname="/CN=ca1.test.io/OU=Dev/O=TEST/L=Tokyo/S=Tokyo/C=JP"
dname_tail="OU=Dev, O=TEST, L=Tokyo, S=Tokyo, C=JP"
crt=cert.crt
crtkey="temp.$crt.key"

rm -rf temp*
rm -f cert*
# Generate CA key
openssl req -new -x509 -keyout $crtkey -out $crt -days 9999 -subj $dname -passin pass:$pass -passout pass:$pass

# Kafkacat
openssl genrsa -des3 -passout "pass:$pass" -out temp.clientkey 1024
openssl req -passin "pass:$pass" -passout "pass:$pass" -key temp.clientkey -new -out temp.clientreq -subj $dname
openssl x509 -req -CA $crt -CAkey $crtkey -in temp.clientreq -out temp.client.pem -days 9999 -CAcreateserial -passin "pass:$pass"

for i in kafka client
do
	rm -rf ./$i
	mkdir ./$i
	# Create keystores
	keytool -genkey -noprompt \
				 -alias $i \
				 -dname "CN=$i, $dname_tail" \
				 -keystore ./$i/keystore.jks \
				 -keyalg RSA \
				 -storepass $pass \
				 -keypass $pass

  csr="temp.$i.csr"
  signedcrt="temp.$i.crt"
	# Create CSR, sign the key and import back into keystore
	keytool -keystore ./$i/keystore.jks -alias $i -certreq -file $csr -storepass $pass -keypass $pass -noprompt
  openssl x509 -req -CA $crt -CAkey $crtkey -in $csr -out $signedcrt -days 9999 -CAcreateserial -passin pass:$pass
	keytool -keystore ./$i/keystore.jks -alias CARoot -import -file $crt -storepass $pass -keypass $pass -noprompt
  keytool -keystore ./$i/keystore.jks -alias $i -import -file $signedcrt  -storepass $pass -keypass $pass -noprompt

	# Create truststore and import the CA crt.
	keytool -keystore ./$i/truststore.jks -alias CARoot -import -file $crt -storepass $pass -keypass $pass -noprompt

  if [ "$i" = "kafka" ]; then
	  keytool -genkey -noprompt \
	  			 -alias localhost \
	  			 -dname "CN=localhost, $dname_tail" \
	  			 -keystore ./$i/localhost.keystore.jks \
	  			 -keyalg RSA \
	  			 -storepass $pass \
	  			 -keypass $pass
    csr="temp.localhost.csr"
    signedcrt="temp.localhost.crt"
	  # Create CSR, sign the key and import back into keystore
	  keytool -keystore ./$i/localhost.keystore.jks -alias localhost -certreq -file $csr -storepass $pass -keypass $pass -noprompt
    openssl x509 -req -CA $crt -CAkey $crtkey -in $csr -out $signedcrt -days 9999 -CAcreateserial -passin pass:$pass
	  keytool -keystore ./$i/localhost.keystore.jks -alias CARoot_localhost -import -file $crt -storepass $pass -keypass $pass -noprompt
    keytool -keystore ./$i/localhost.keystore.jks -alias localhost -import -file $signedcrt  -storepass $pass -keypass $pass -noprompt

	  # Create truststore and import the CA crt.
	  keytool -keystore ./$i/localhost.truststore.jks -alias CARoot_localhost -import -file $crt -storepass $pass -keypass $pass -noprompt

    keytool -importkeystore -srckeystore ./$i/localhost.keystore.jks -destkeystore ./$i/keystore.jks -srcstorepass $pass -deststorepass $pass -noprompt
    keytool -exportcert -keystore ./$i/localhost.truststore.jks -alias CARoot_localhost -file temp.localhost.temp.cert -storepass $pass -noprompt
    keytool -importcert -keystore ./$i/truststore.jks -alias CARoot_localhost -file temp.localhost.temp.cert -storepass $pass -noprompt
  fi

  echo "$pass" > ./$i/creds
done

#rm -rf temp*
