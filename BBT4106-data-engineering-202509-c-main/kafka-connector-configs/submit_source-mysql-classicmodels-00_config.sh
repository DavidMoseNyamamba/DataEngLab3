#!/usr/bin/env bash

curl -X DELETE http://localhost:8083/connectors/source-mysql-classicmodels-00

curl -i -X PUT -H "Content-Type:application/json" \
  http://localhost:8083/connectors/source-mysql-classicmodels-00/config \
  -d '{
            "connector.class": "io.debezium.connector.mysql.MySqlConnector",
            "database.hostname": "mysql",
            "database.port": "3306",
            "database.user": "root",
            "database.password": "5trathm0re",
            "database.server.id": "42",
            "database.allowPublicKeyRetrieval":"true",
            "database.server.name": "mysql",
            "table.whitelist": "classicmodels.payments, classicmodels.customers",
            "database.history.kafka.bootstrap.servers": "broker:9092",
            "database.history.kafka.topic": "dbhistory.classicmodels" ,
            "decimal.handling.mode": "double",
            "include.schema.changes": "true",

            "transforms": "unwrap,dropTopicPrefix",
            "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
            "transforms.dropTopicPrefix.type":"org.apache.kafka.connect.transforms.RegexRouter",
            "transforms.dropTopicPrefix.regex":"classicmodels.classicmodels.(.*)",
            "transforms.dropTopicPrefix.replacement":"$1",

            "key.converter.schema.registry.url": "http://schema-registry:8081",
            "value.converter.schema.registry.url": "http://schema-registry:8081",


            "key.converter.schemas.enable": "true",
            "value.converter.schemas.enable": "true",
            "value.converter": "org.apache.kafka.connect.json.JsonConverter",
            "key.converter": "org.apache.kafka.connect.json.JsonConverter",

            "topic.prefix": "classicmodels", 
            "database.include.list": "classicmodels", 
            "schema.history.internal.kafka.bootstrap.servers": "broker:9092", 
            "schema.history.internal.kafka.topic": "schemahistory.classicmodels"
    }'
