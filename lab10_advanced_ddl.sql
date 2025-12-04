--3.1
CREATE TABLE accounts (
id SERIAL PRIMARY KEY,
name VARCHAR(100) NOT NULL,
balance DECIMAL(10, 2) DEFAULT 0.00
);
CREATE TABLE products (
id SERIAL PRIMARY KEY,
shop VARCHAR(100) NOT NULL,
product VARCHAR(100) NOT NULL,
price DECIMAL(10, 2) NOT NULL
);
-- Insert test data
INSERT INTO accounts (name, balance) VALUES
('Alice', 1000.00),
('Bob', 500.00),
('Wally', 750.00);
INSERT INTO products (shop, product, price) VALUES
Level Description Phenomena Allowed
SERIALIZABLE Highest isolation. Transactions appear to
execute serially. None
REPEATABLE
READ
Data read is guaranteed to be the same if read
again. Phantom reads
READ
COMMITTED
Only sees committed data, but may see
different data on re-read.
Non-repeatable reads,
Phantoms
READ
UNCOMMITTED
Can see uncommitted changes from other
transactions.
Dirty reads, Non-repeatable,
Phantoms
('Joe''s Shop', 'Coke', 2.50),
('Joe''s Shop', 'Pepsi', 3.00);

--3.2
BEGIN;
UPDATE accounts SET balance = balance - 100.00
WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00
WHERE name = 'Bob';
COMMIT;
--a) alice - 900, bob - 600 
--b) because if transaction fails, someone will lose money
--c) alice lost 100 dollars into the void 

--3.3
BEGIN;
UPDATE accounts SET balance = balance - 500.00
WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';
-- Oops! Wrong amount, let's undo
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';
--a) was: 1000, now: 500
--b) 1000
--c)when something fails midway, rollback undoes all changes made in the transaction

--3.4
BEGIN;
UPDATE accounts SET balance = balance - 100.00
WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00
WHERE name = 'Bob';
-- Oops, should transfer to Wally instead
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00
WHERE name = 'Wally';
COMMIT;
--a) alice - 900, bob - 500, wally - 850
--b) no, because we rolled back to the savepoint before committing the transaction
--c) SAVEPOINT allows partial rollbacks within a transaction, providing more control and flexibility without aborting the entire transaction

--3.5
--scenario a
--terminal 1
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to make changes and COMMIT
-- Then re-run:
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

--terminal 2 while 1 is running
BEGIN;
DELETE FROM products WHERE shop = 'Joe''s Shop';
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Fanta', 3.50);
COMMIT;

--scenario b

--terminal 1
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to make changes and COMMIT
-- Then re-run:
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

--terminal 2 while 1 is running
BEGIN;
DELETE FROM products WHERE shop = 'Joe''s Shop';
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Fanta', 3.50);
COMMIT;

--a) before commit: original products (coke, pepsi). after commit: fanta only
--b) terminal 1 sees the original products (coke, pepsi) both before and after terminal 2 commits
--c) READ COMMITTED allows seeing committed changes from other transactions,
--while SERIALIZABLE provides a consistent snapshot of the database, preventing
--seeing changes made by other transactions until they are committed

--3.6
--terminal 1
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products
WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2
SELECT MAX(price), MIN(price) FROM products
WHERE shop = 'Joe''s Shop';
COMMIT;

--terminal 2 
BEGIN;
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Sprite', 4.00);
COMMIT;
--a) no, terminal 1 does not see the new product inserted by terminal 2.
--b) a phantom read occurs when a transaction reads a set of rows that satisfy a condition,
--and another transaction inserts or deletes rows that would satisfy that condition,
--causing the first transaction to see a different set of rows if it re-executes the query
--c) the SERIALIZABLE isolation level prevents phantom reads by ensuring that
--transactions operate in a way that appears as if they were executed seriallyly.

--3.7
--terminal 1
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to UPDATE but NOT commit
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to ROLLBACK
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

--terminal 2
BEGIN;
UPDATE products SET price = 99.99
WHERE product = 'Fanta';
-- Wait here (don't commit yet)
-- Then:
ROLLBACK;

--a) yes, terminal 1 saw the price of 99.99 before terminal 2 rolled back. this is problematic because Terminal 1
--read uncommitted data that was later discarded, leading to inconsistencies
--b) a dirty read occurs when a transaction reads data that has been modified by another transaction that has not yet 
--been committed
--c) READ UNCOMMITTED should be avoided in most applications because it can lead to data inconsistencies 
--and unreliable results due to dirty reads

--4.1
BEGIN;

DO $$
DECLARE
    bob_balance DECIMAL(10,2);
BEGIN
    SELECT balance INTO bob_balance
    FROM accounts
    WHERE name = 'Bob'
    FOR UPDATE;

    IF bob_balance < 200 THEN
        RAISE EXCEPTION 'insufficient funds: Bob has only %', bob_balance;
    END IF;

    UPDATE accounts
    SET balance = balance - 200
    WHERE name = 'Bob';

    UPDATE accounts
    SET balance = balance + 200
    WHERE name = 'Wally';
END $$;

COMMIT;

--4.2
BEGIN;

INSERT INTO products (shop, product, price)
VALUES ('Test Shop', 'Sprite', 4.00);

SAVEPOINT sp1;

UPDATE products
SET price = 5.00
WHERE product = 'Sprite' AND shop = 'Test Shop';

SAVEPOINT sp2;

DELETE FROM products
WHERE product = 'Sprite' AND shop = 'Test Shop';

ROLLBACK TO SAVEPOINT sp1;

COMMIT;

--4.3
--scenario:
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name TEXT,
    balance DECIMAL(10,2)
);

INSERT INTO accounts (name, balance)
VALUES ('user', 300.00);

--read uncommitted/commit scenario
--t1
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name='Shared';
-- returns 300

UPDATE accounts SET balance = balance - 200
WHERE name='Shared';
-- balance becomes 100

--t2 at the same time
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name='Shared';
-- also returns 300 (sees committed state at query time)

UPDATE accounts SET balance = balance - 200;
-- now balance becomes -100

--repeatable read
--t1
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM accounts WHERE name='Shared';  -- 300
UPDATE accounts SET balance = balance - 200 WHERE name='Shared';
-- becomes 100

--t2
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM accounts WHERE name='Shared';  -- 300 (snapshot)
UPDATE accounts SET balance = balance - 200;
-- ERROR: could not serialize access due to concurrent update

--serializable
--t1
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT balance FROM accounts WHERE name='Shared'; -- 300
UPDATE accounts SET balance = balance - 200;

--t2
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT balance FROM accounts WHERE name='Shared'; -- 300
UPDATE accounts SET balance = balance - 200;
-- ERROR: could not serialize access due to read/write conflict

--self-assessment:
--1. acid
--atomicity: the operation happens fully or not at all.
--consistency: data stays valid after the transaction.
--isolation: parallel transactions do not affect each other.
--durability: after commit, data is safely stored.
--2. commit makes changes permanent, rollback cancels all changes.
--3. use a savepoint when you want to undo only part of a transaction, not the whole transaction.
--4. isolation levels
--read uncommitted: can read uncommitted changes.
--read committed: reads only committed data.
--repeatable read: same read gives same result inside the transaction.
--serializable: transactions behave as if executed one by one.
--5. a dirty read is reading uncommitted data; allowed only in read uncommitted.
--6. a non-repeatable read is when the same select returns different results because another transaction updated the row.
--7. a phantom read is when new rows appear between two selects; prevented by serializable.
--8. read committed is faster and gives fewer conflicts than serializable in high-traffic systems.
--9. transactions keep data consistent by grouping steps so they don’t interfere during concurrent access.
--10. uncommitted changes are lost if the system crashes.
