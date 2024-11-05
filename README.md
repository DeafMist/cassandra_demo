# Демонстрация работы Cassandra на практике

## Dockerfile

### Запуск

1. Создаем image с именем cassandra на основе того, что написано в Dockerfile
```bash
docker build -t cassandra .
```

2. Запускаем контейнер с именем cassandra-demo из image cassandra в режиме -d (detach, то есть в фоне), прокидывая volumes c локальной машины в контейнер для сохранения данных в случае удаления контейнера
```bash
docker run --name cassandra-demo -d -v ./cassandra_data:/var/lib/cassandra cassandra
```

3. Выполнение скрипта создания базы данных
Это действие необходимо, так как docker-entrypoint-initdb.d не работает для Cassandra.
```bash
docker exec cassandra-demo cqlsh  -f /docker-entrypoint-initdb.d/init.cql
```

4. Подключаемся к контейнеру и творим непотребства
```bash
docker exec -it cassandra-demo bash
```

### Остановка контейнеров

```bash
docker stop cassandra-demo
```

## docker-compose

### Запуск

1. Поднимаем контейнеры (-d в очередной раз - detach, то есть фоновый режим)
```bash
docker-compose up -d
```

2. Выполнение скрипта создания базы данных
Это действие необходимо, так как docker-entrypoint-initdb.d не работает для Cassandra.
```bash
docker exec cassandra-demo cqlsh  -f /docker-entrypoint-initdb.d/init.cql
```

### Остановка контейнеров

```bash
docker-compose down
```

## Основные команды CQL

### DDL (Data Definition Language)
Используется для определения структуры базы данных

#### Ключевые пространства

1. Создание ключевого пространства
```
CREATE KEYSPACE test_keyspace
WITH REPLICATION = {
    'class': 'SimpleStrategy',
    'replication_factor': 1
};
```
2. Изменение ключевого пространства
```
ALTER KEYSPACE test_keyspace 
WITH REPLICATION = { 
    'class' : 'NetworkTopologyStrategy', 
    'replication_factor' : 2 
};
```

3. Выбор пространства имен
```
USE keyspace_name;
```

4. Описание пространства имен
```
DESCRIBE keyspace_name;
```

#### Таблицы

Создание таблицы
```
CREATE TABLE IF NOT EXISTS test_keyspace.orders (
    user_id UUID,
    order_date TIMESTAMP,
    order_id UUID,
    amount DECIMAL,
    PRIMARY KEY ((user_id), order_date, order_id)
) WITH CLUSTERING ORDER BY (order_date DESC, order_id ASC);
```

2. Добавление столбца
```
ALTER TABLE test_keyspace.orders 
ADD status TEXT;
```

3. Изменение типа столбца
```
ALTER TABLE test_keyspace.orders 
ALTER status TYPE INT;
```

4. Удаление столбца
```
ALTER TABLE test_keyspace.orders
DROP status;
```

5. Создание индекса
```
CREATE INDEX orders_amount_idx ON test_keyspace.orders(amount);
```

6. Удаление индекса
```
DROP INDEX IF EXISTS test_keyspace.orders_amount_idx;
```

7. Просмотр структуры таблицы
```
DESCRIBE TABLE test_keyspace.orders;
```

8. Создание пользовательского типа данных - и различные команды для его переименования, удаления и прочего
```
CREATE TYPE IF NOT EXISTS test_keyspace.address (
    street TEXT,
    city TEXT,
    zip_code TEXT
);
```

### DML (Data Manipulation Language)

#### Основные запросы

1. Вставка
```
INSERT INTO test_keyspace.orders (user_id, order_date, order_id, amount)
VALUES (uuid(), '2023-10-10 10:00:00', uuid(), 100.00);
```

2. Обновление
```
UPDATE test_keyspace.orders 
SET amount = 120.00 
WHERE user_id = <ваш_user_id> AND order_date = '2023-10-10 10:00:00' AND order_id = <ваш_order_id>;
```

3. Удаление
```
DELETE FROM test_keyspace.orders 
WHERE user_id = <ваш_user_id>;
```

4. Выборка записей
```
SELECT * FROM test_keyspace.orders;
```

5. Фильтрация по столбцу, который не указан в первичном ключе - !!!использование ALLOW FILTERING очень НЕЖЕЛАТЕЛЬНО!!!
```
SELECT * FROM test_keyspace.orders WHERE amount > 50.00 ALLOW FILTERING;
```

6. Установка TTL для записи
```
INSERT INTO test_keyspace.orders (user_id, order_date, order_id, amount) 
VALUES (uuid(), '2023-10-11 10:00:00', uuid(), 150.00) USING TTL 3600; // Удалить через 1 час
```

Тут есть и другие команды, присутствующие в SQL - ORDER BY, DISTINCT, COUNT, SUM, LIMIT, IF и прочие. 

#### Дополнительные запросы, которые могут быть очень полезны

1. Перечень ключевых пространств
```
SELECT * FROM system_schema.keyspaces;
```

2. Перечень таблиц в ключевом пространстве
```
SELECT * FROM system_schema.tables WHERE keyspace_name='test_keyspace';
```

### TCL (Transaction Control Language)

В Cassandra возможности для управления транзакциями несколько ограничены по сравнению с традиционными реляционными базами данных. Однако есть некоторые команды и методы, которые можно использовать.

1. Объединение нескольких команд `INSERT`, `UPDATE`, `DELETE` в единый пакет
```
BEGIN BATCH
INSERT INTO test_keyspace.orders (user_id, order_date, order_id, amount) VALUES (uuid(), '2023-10-11 10:00:00', uuid(), 150.00);
INSERT INTO test_keyspace.orders (user_id, order_date, order_id, amount) VALUES (uuid(), '2023-10-12 11:00:00', uuid(), 200.00);
APPLY BATCH;
```

Важно понимать, что Cassandra не поддерживает стандартные транзакционные команды SQL, такие как `COMMIT` и `ROLLBACK`.

### DCL (Data Control Language)

1. Создание нового пользователя
```
CREATE USER <имя_пользователя> WITH PASSWORD <пароль>;
```

2. Удаление пользователя
```
DROP USER <имя_пользователя>;
```

3. Предоставление привилегий
```
GRANT ALL PERMISSIONS ON KEYSPACE test_keyspace TO <имя_пользователя>;
```

4. Отзыв привилегий
```
REVOKE ALL PERMISSIONS ON KEYSPACE test_keyspace FROM <имя_пользователя>;
```

5. Просмотр привилегий
```
LIST ALL PERMISSIONS OF <имя_пользователя>;
```

6. Создание ролей - cassandra версии 4.0 и выше позволяет создавать роли, которые могут иметь дополнительные уровни сложного управления доступом, что улучшает безопасность.
```
CREATE ROLE <имя_роли> WITH OPTIONS = {
    'login' : true};
```

7. Назначение роли
```
GRANT <имя_роли> TO <имя_пользователя>;
```

8. Просмотр ролей
```
LIST ALL ROLES;
```

## Так в чем же различия между SQL и CQL?

Резюмируем.

### 1. Первичный ключ

- SQL: Устанавливает PRIMARY KEY на основе одного или нескольких столбцов.
- CQL: PRIMARY KEY может состоять из нескольких частей, включая PARTITION KEY и CLUSTERING KEY.

### 2. Запросы на выборку

- SQL: Запросы могут быть очень сложными и включать JOIN для работы с несколькими таблицами.
- CQL: Нет поддержки JOIN; данные обычно моделируются так, чтобы избежать необходимости в них.

### 3. Транзакции

- SQL: Есть средства управления транзакциями, можно задать уровень изолированности транзакций, от которого зависит наличие тех или иных аномалий данных.
- CQL: Нет транзакция как таковых, только некий аналог в виде BATCH. 

### 4. Функции и агрегации

- SQL: Широкая поддержка агрегатных функций и оконных функций.
- CQL: Ограниченная поддержка функций агрегации, использование более простых методов для сбора данных.
