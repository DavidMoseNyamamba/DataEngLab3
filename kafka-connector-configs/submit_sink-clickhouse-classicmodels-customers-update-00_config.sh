#!/usr/bin/env bash

curl -X DELETE http://localhost:8083/connectors/sink-clickhouse-classicmodels-customers-update-00

curl -i -X PUT -H "Content-Type:application/json" \
  http://localhost:8083/connectors/sink-clickhouse-classicmodels-customers-update-00/config \
  -d '{
            "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
            "connection.url": "jdbc:clickhouse://clickhouse-server:8123/classicmodels",
            "table.name.format": "customers",
            "tasks.max": "1",
            "topics": "customers",
            "insert.mode": "update",
            "pk.mode": "record_key",
            "pk.fields": "customerNumber",
            "auto.create": "true",
            "auto.evolve": "true",
            "key.converter": "org.apache.kafka.connect.json.JsonConverter",
            "value.converter": "org.apache.kafka.connect.json.JsonConverter"
    }'