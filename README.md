##  kafka-sasl-ssl

Example sals-ssl kafka cluster with a schema-registry node

### Run the thing
1. Create the certs
   ```
   ./create-certs.sh
   ```
2. Start the cluster
   ```
   docker-compose up -d
   ```
3. If the cluster doesn't start correctly you may want to do:
   ```
   sbt service/run
   docker-compose up -d --build --force-recreate
   ```

### Connect to the cluster

If you want to produce and consume from the from a JVM based app or from the CLI you will need to 
use either the config in secrets/conf/host.client.sasl_scram.config or something similar

Since the paths in this config file are relative you will need to start your consumers/producers from
the root directory, otherwise you will need to use absolute paths.
