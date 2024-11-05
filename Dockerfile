# Берем за основу официальный образ Cassandra
FROM cassandra:latest

# Копируем cql-скрипт в контейнер
COPY ./init.cql /docker-entrypoint-initdb.d/init.cql