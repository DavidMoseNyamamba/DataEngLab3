# Lab Submission

## Team Members

1. DAVID MOSE NYAMAMBA, 151353, 202509-C  
2. TIMOTHY YONGA, 138362, 202509-C  
3. GRACE WANJIGI, 145639, 202509-C  
4. ANDY NJOGU, 120745, 202509-C   
5. DAVID KIMONDO, 120751, 202509-C 

## Section 1: Deduplication Strategies

Deduplication is a fundamental concern in analytic systems because duplicated or out-of-order records corrupt aggregates, inflate counts, and distort historical state. In streaming and CDC-driven pipelines, multiple events for the same business key (inserts, updates, deletes, or retried messages) are common; deduplication ensures the warehouse reflects the correct, current state.

a. Importance of an upsert  
An "upsert" (update-or-insert) makes writes idempotent and preserves the latest correct state for a given key. Upserts are essential when CDC sources emit change events or when pipelines must be retryable. Without upserts, repeated ingestion can create duplicate rows or conflicting snapshots; with upserts you can replace or merge incoming records into an existing row keyed by the business primary key. Upserts support convergence of eventual consistency and reduce the need for expensive read-time deduplication.

b. Deduplication strategies applied in data warehouses  
Deduplication is typically implemented at three stages:

- Ingestion-time deduplication: deduplicate before storage by using streaming processors (e.g., Kafka Streams, ksqlDB, Flink) that track offsets, dedupe by event id, or de-duplicate using stateful operators. This reduces storage and downstream compute but requires state and careful retention policies.

- Storage-engine deduplication: rely on database features to collapse duplicates during merges or compactions. This is efficient for large volumes because the engine implements compaction internally and can work in the background without changing the ingestion pipeline.

- Query-time deduplication: use SQL constructs (GROUP BY + argMax, ROW_NUMBER() OVER(...) filters or LATEST_BY_OFFSET) to pick the most recent record per key at read time. This provides flexibility but increases query cost and latency.

c. ClickHouse-specific strategies and engines  
ClickHouse offers storage engines tailored for deduplication:

- ReplacingMergeTree([version_col]): keeps at most one row per primary key after merges. If a version (timestamp or sequence) column is provided, the row with the highest version is retained; without it, the last inserted row is chosen (less deterministic). This engine is ideal for CDC upserts when a monotonic timestamp or commit sequence is available.

- CollapsingMergeTree(sign_col): uses a sign column (+1 insert, -1 delete) and collapses row pairs with opposite signs during merges. It is suitable when the upstream produces explicit delete markers and you want the merge process to nullify insert-delete pairs.

- AggregatingMergeTree / SummingMergeTree: these engines store aggregated states or combine numeric columns, enabling deduplication by aggregation (e.g., keeping aggregated metrics rather than raw events). They are useful when reducing cardinality is the goal rather than preserving raw event-level detail.

- TTL + Merge rules: combined with merge trees, TTL or partitioning can prune older duplicates and manage data lifecycle.

d. Retrieving only the most recent version and filtering duplicates  
ClickHouse offers multiple read-side techniques:

- FINAL modifier (costly): `SELECT * FROM table FINAL` forces merge-time deduplication while reading. It returns the post-merge state but can be expensive and should be used sparingly.

- argMax family functions (recommended): `SELECT pk, argMax(value, version) FROM table GROUP BY pk` returns the value associated with the max version. This is efficient because it avoids `FINAL` and is deterministic when a version column exists.

- GROUP BY with aggregation: use `MAX(version)` and then join back to get full rows or use `anyHeavy` / `anyLast` style aggregations where appropriate.

- CollapsingMergeTree semantics: rely on periodic merges to remove cancelled pairs; read as usual once compaction has completed.

- Windowing (in other warehouses): `ROW_NUMBER() OVER (PARTITION BY pk ORDER BY ts DESC)` then filter WHERE rn = 1. This is a general SQL pattern if ClickHouse-specific functions are unavailable.

e. Examples

- ReplacingMergeTree table definition (orders):
```sql
CREATE TABLE classicmodels.orderdetails
(
  orderNumber Int32,
  productCode String,
  orderLineNumber Int32,
  quantityOrdered Int32,
  priceEach Float64,
  op_ts DateTime64(3)
)
ENGINE = ReplacingMergeTree(op_ts)
PRIMARY KEY (orderNumber, productCode, orderLineNumber);
```
Retrieve current state:
```sql
SELECT
  orderNumber, productCode, orderLineNumber,
  argMax(quantityOrdered, op_ts) AS quantityOrdered,
  argMax(priceEach, op_ts) AS priceEach
FROM classicmodels.orderdetails
GROUP BY orderNumber, productCode, orderLineNumber;
```

- CollapsingMergeTree example (with sign):
```sql
CREATE TABLE classicmodels.products_changes
(
  productCode String,
  productName String,
  sign Int8
)
ENGINE = CollapsingMergeTree(sign)
PRIMARY KEY (productCode);
```
Ingest +1 for insert/update and -1 for delete; after merges the table yields current state.

f. Practical guidance  
- Prefer ReplacingMergeTree with a reliable monotonically increasing version or timestamp for deterministic upserts.  
- Disable sink auto-create in connectors; create ClickHouse tables manually with correct types to avoid JDBC mapping issues.  
- Use argMax or grouped aggregation in queries for efficient reads; reserve `FINAL` for debugging or small datasets.  
- If deletes are frequent and explicit, CollapsingMergeTree can model logical deletes using sign semantics.

## Section 2: Additional Data Ingestion

Ingest more data into:
1. Fact table: `orderDetails`  
2. Dimension table: `products`

Part A — ClickHouse table creation (add to container-volumes/clickhouse/ClickHouseTables.sql):  
Provide table DDL matching CDC semantics (example DDL for two tables):

```sql
-- Add to container-volumes/clickhouse/ClickHouseTables.sql
CREATE DATABASE IF NOT EXISTS classicmodels;

CREATE TABLE IF NOT EXISTS classicmodels.orderdetails
(
  orderNumber Int32,
  productCode String,
  orderLineNumber Int32,
  quantityOrdered Int32,
  priceEach Float64,
  op_ts DateTime64(3)
)
ENGINE = ReplacingMergeTree(op_ts)
PRIMARY KEY (orderNumber, productCode, orderLineNumber);

CREATE TABLE IF NOT EXISTS classicmodels.products
(
  productCode String,
  productName Nullable(String),
  productLine Nullable(String),
  productScale Nullable(String),
  productVendor Nullable(String),
  productDescription Nullable(String),
  quantityInStock Int32,
  buyPrice Float64,
  MSRP Float64,
  op_ts DateTime64(3)
)
ENGINE = ReplacingMergeTree(op_ts)
PRIMARY KEY (productCode);
```

Part B — Source connector update (kafka-connector-configs/submit_source-mysql-classicmodels-00_config.sh):  
Update the connector to include the `table.whitelist` entries for `orderdetails` and `products` and ensure Debezium produces op timestamps and a proper topic name transform. Example connector options to add:
- "table.whitelist": "classicmodels.orderdetails,classicmodels.products"
- transforms: to strip schema prefix (RegexRouter or ExtractTopic)
Ensure connector rest submission script is updated accordingly.

Part C — Sink connectors (kafka-connector-configs):  
Create six sink configs (three for orderdetails: insert/update/delete; three for products). Recommended approach: use a ClickHouse-specific sink or JDBC sink configured for upserts:
- Disable `auto.create` and `auto.evolve`.
- Use pk.mode=record_key and pk.fields matching primary keys.
- Enable delete handling (e.g., delete.enabled=true) if connector supports it.
Name examples:
- sink-clickhouse-classicmodels-orderdetails-insert-00.json
- sink-clickhouse-classicmodels-orderdetails-update-00.json
- sink-clickhouse-classicmodels-orderdetails-delete-00.json
- sink-clickhouse-classicmodels-products-insert-00.json
- sink-clickhouse-classicmodels-products-update-00.json
- sink-clickhouse-classicmodels-products-delete-00.json

Part D — Validation and screenshots  
Steps to validate:
1. Confirm tables exist in ClickHouse:
   - `docker exec -it clickhouse-server clickhouse-client --query "USE classicmodels; SHOW TABLES;"`
2. Show latest state:
   - `docker exec -it clickhouse-server clickhouse-client --query "SELECT * FROM classicmodels.products ORDER BY op_ts DESC LIMIT 10;"`
   - `docker exec -it clickhouse-server clickhouse-client --query "SELECT * FROM classicmodels.orderdetails ORDER BY op_ts DESC LIMIT 10;"`
3. Check connector status:
   - `curl http://localhost:8083/connectors/<connector-name>/status`
4. Take screenshots of the ClickHouse query output, Kafka Connect status, and relevant Kafka topics (ksqlDB SHOW TOPICS or kafka-topics.sh).

Place screenshots below this line (insert images captured after verifying pipelines).

---
