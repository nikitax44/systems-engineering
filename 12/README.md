produce: `docker-compose exec kafka kafka-console-producer --topic numbers --bootstrap-server localhost:9092`

pos summary: `docker-compose exec clickhouse clickhouse-client -q "select * from numbers_summary_pos final"`

neg summary: `docker-compose exec clickhouse clickhouse-client -q "select * from numbers_summary_neg final"`

read errors: `docker-compose exec kafka kafka-console-consumer --bootstrap-server kafka:9092 --topic numbers_dlq --from-beginning`
