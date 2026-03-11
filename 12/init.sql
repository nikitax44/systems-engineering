CREATE TABLE IF NOT EXISTS default.numbers_kafka (
    val String
) ENGINE = Kafka() SETTINGS
    kafka_broker_list = 'kafka:9092',
    kafka_topic_list = 'numbers',
    kafka_group_name = 'clickhouse-group',
    kafka_format = 'LineAsString',
    kafka_num_consumers = 1;

CREATE TABLE IF NOT EXISTS default.numbers_dlq_kafka (
    val String,
    error String,
    error_time DateTime
) ENGINE = Kafka() SETTINGS
    kafka_broker_list = 'kafka:9092',
    kafka_topic_list = 'numbers_dlq',
    kafka_group_name = 'clickhouse-dlq-group',
    kafka_format = 'JSONEachRow';

CREATE TABLE IF NOT EXISTS default.numbers_data (
    number Int64,
    processed_at DateTime DEFAULT now()
) ENGINE = MergeTree() ORDER BY processed_at;

CREATE MATERIALIZED VIEW IF NOT EXISTS default.numbers_processor TO default.numbers_data AS
SELECT
    assumeNotNull(toInt64OrNull(val)) AS number,
    now() as processed_at
FROM default.numbers_kafka
WHERE (toInt64OrNull(val) IS NOT NULL) AND (toInt64OrNull(val) != 0);

CREATE MATERIALIZED VIEW IF NOT EXISTS default.numbers_dlq_zeros_processor TO default.numbers_dlq_kafka AS
SELECT
    val,
    'Zeros are not allowed' as error,
    now() as error_time
FROM default.numbers_kafka
WHERE (toInt64OrNull(val) IS NOT NULL) AND (toInt64OrNull(val) = 0);

CREATE MATERIALIZED VIEW IF NOT EXISTS default.numbers_dlq_err_processor TO default.numbers_dlq_kafka AS
SELECT
    val,
    'Failed to parse as Int64' as error,
    now() as error_time
FROM default.numbers_kafka
WHERE toInt64OrNull(val) IS NULL;

CREATE TABLE IF NOT EXISTS default.numbers_summary_pos (
    sign String,
    total_sum Int64,
    count UInt64,
) ENGINE = SummingMergeTree() ORDER BY sign;

CREATE TABLE IF NOT EXISTS default.numbers_summary_neg (
    sign String,
    total_sum Int64,
    count UInt64,
) ENGINE = SummingMergeTree() ORDER BY sign;


CREATE MATERIALIZED VIEW IF NOT EXISTS default.numbers_aggregation_pos TO default.numbers_summary_pos AS
SELECT
    'positive_sum' as sign,
    sum(number) as total_sum,
    count() as count
FROM default.numbers_data
WHERE number > 0;

CREATE MATERIALIZED VIEW IF NOT EXISTS default.numbers_aggregation_neg TO default.numbers_summary_neg AS
SELECT
    'negative_sum' as sign,
    sum(number) as total_sum,
    count() as count
FROM default.numbers_data
WHERE number < 0;
