CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    iin CHAR(12) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    status VARCHAR(20) CHECK (status IN ('active', 'blocked', 'frozen')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    daily_limit_kzt DECIMAL(15, 2) DEFAULT 100000.00
);

CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    account_number VARCHAR(20) UNIQUE NOT NULL,
    currency VARCHAR(3) CHECK (currency IN ('KZT', 'USD', 'EUR', 'RUB')),
    balance DECIMAL(15, 2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP
);

CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency VARCHAR(3),
    to_currency VARCHAR(3),
    rate DECIMAL(10, 6),
    valid_from TIMESTAMP,
    valid_to TIMESTAMP
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_account_id INT REFERENCES accounts(account_id),
    to_account_id INT REFERENCES accounts(account_id),
    amount DECIMAL(15, 2),
    currency VARCHAR(3),
    exchange_rate DECIMAL(10, 6),
    amount_kzt DECIMAL(15, 2),
    type VARCHAR(20) CHECK (type IN ('transfer', 'deposit', 'withdrawal')),
    status VARCHAR(20) CHECK (status IN ('pending', 'completed', 'failed', 'reversed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    description TEXT
);

CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50),
    record_id INT,
    action VARCHAR(10),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(50),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET
);

INSERT INTO customers (iin, full_name, status, daily_limit_kzt) VALUES 
('111111111111', 'Bob1', 'active', 100000),
('222222222222', 'Bob2', 'frozen', 200000),
('333333333333', 'Bob3', 'active', 300000),
('444444444444', 'Bob4', 'frozen', 400000),
('555555555555', 'Bob5', 'active', 500000),
('666666666666', 'Bob6', 'frozen', 600000),
('777777777777', 'Bob7', 'active', 700000),
('888888888888', 'Bob8', 'frozen', 800000),
('999999999999', 'Bob9', 'active', 900000),
('101010101010', 'Bob10', 'frozen', 100000);

INSERT INTO accounts (customer_id, account_number, currency, balance) VALUES 
(1, 'KZ001', 'KZT', 1000000),
(2, 'KZ002', 'USD', 2000),
(3, 'KZ003', 'KZT', 30000),
(4, 'KZ004', 'USD', 40000),
(5, 'KZ005', 'KZT', 50000),
(6, 'KZ006', 'USD', 60000),
(7, 'KZ007', 'KZT', 70000),
(8, 'KZ008', 'USD', 80000),
(9, 'KZ009', 'KZT', 90000),
(10, 'KZ0010', 'KZT', 150000);

INSERT INTO exchange_rates (from_currency, to_currency, rate, valid_from, valid_to) VALUES 
('USD', 'KZT', 495.00, NOW(), '2030-01-01'),
('EUR', 'KZT', 520.00, NOW(), '2030-01-01'),
('EUR', 'USD', 1.17, NOW(), '2030-01-01'),
('EUR', 'KZT', 520.00, NOW(), '2030-01-01'),
('EUR', 'USD', 1.17, NOW(), '2030-01-01'),
('EUR', 'KZT', 520.00, NOW(), '2030-01-01'),
('EUR', 'USD', 1.17, NOW(), '2030-01-01'),
('EUR', 'KZT', 520.00, NOW(), '2030-01-01'),
('KZT', 'EUR', 0.0016, NOW(), '2030-01-01'),
('KZT', 'KZT', 1.00, NOW(), '2030-01-01');


--1
CREATE OR REPLACE PROCEDURE process_transfer(
    p_from_acc_num VARCHAR,
    p_to_acc_num VARCHAR,
    p_amount DECIMAL,
    p_currency VARCHAR,
    p_description TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_from_id INT;
    v_to_id INT;
    v_from_balance DECIMAL;
    v_cust_status VARCHAR;
    v_cust_id INT;
    v_daily_limit DECIMAL;
    v_daily_spent DECIMAL;
    v_rate DECIMAL := 1.0;
    v_amount_kzt DECIMAL;
    v_txn_id INT;
BEGIN
    
    INSERT INTO audit_log (table_name, action, changed_by, new_values)
    VALUES ('transactions', 'INSERT', CURRENT_USER, jsonb_build_object('type', 'attempt', 'from', p_from_acc_num));

    
    SELECT a.account_id, a.balance, c.status, c.customer_id, c.daily_limit_kzt
    INTO v_from_id, v_from_balance, v_cust_status, v_cust_id, v_daily_limit
    FROM accounts a
    JOIN customers c ON a.customer_id = c.customer_id
    WHERE a.account_number = p_from_acc_num AND a.is_active = TRUE
    FOR UPDATE; 

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sender account not found or inactive';
    END IF;

    
    SELECT account_id INTO v_to_id 
    FROM accounts WHERE account_number = p_to_acc_num AND is_active = TRUE
    FOR UPDATE;

    IF NOT FOUND THEN 
        RAISE EXCEPTION 'Receiver account not found or inactive'; 
    END IF;

    
    IF v_cust_status <> 'active' THEN
        RAISE EXCEPTION 'Customer is %', v_cust_status;
    END IF;

    
    IF p_currency = 'KZT' THEN
        v_amount_kzt := p_amount;
    ELSE
        SELECT rate INTO v_rate FROM exchange_rates 
        WHERE from_currency = p_currency AND to_currency = 'KZT' 
        ORDER BY valid_from DESC LIMIT 1;
        v_amount_kzt := p_amount * v_rate;
    END IF;

    
    SELECT COALESCE(SUM(amount_kzt), 0) INTO v_daily_spent
    FROM transactions 
    WHERE from_account_id = v_from_id 
      AND created_at::DATE = CURRENT_DATE 
      AND status = 'completed';

    IF (v_daily_spent + v_amount_kzt) > v_daily_limit THEN
        RAISE EXCEPTION 'Daily limit exceeded. Spent: %, Attempt: %, Limit: %', v_daily_spent, v_amount_kzt, v_daily_limit;
    END IF;

    
    
    IF v_from_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;

    
    UPDATE accounts SET balance = balance - p_amount WHERE account_id = v_from_id;
    
    UPDATE accounts SET balance = balance + p_amount WHERE account_id = v_to_id; 

    
    INSERT INTO transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, description, completed_at)
    VALUES (v_from_id, v_to_id, p_amount, p_currency, v_rate, v_amount_kzt, 'transfer', 'completed', p_description, NOW())
    RETURNING transaction_id INTO v_txn_id;

    
    INSERT INTO audit_log (table_name, record_id, action, changed_by)
    VALUES ('transactions', v_txn_id, 'COMPLETED', CURRENT_USER);

EXCEPTION WHEN OTHERS THEN
    
    INSERT INTO audit_log (table_name, action, changed_by, new_values)
    VALUES ('transactions', 'FAILED', CURRENT_USER, jsonb_build_object('error', SQLERRM));
    RAISE; 
END;
$$;

--2

CREATE OR REPLACE VIEW customer_balance_summary AS
SELECT 
    c.full_name,
    a.account_number,
    a.balance,
    a.currency,
    
    (a.balance * COALESCE((SELECT rate FROM exchange_rates er WHERE er.from_currency = a.currency AND er.to_currency = 'KZT' LIMIT 1), 1)) AS balance_in_kzt,
    c.daily_limit_kzt,
    
    RANK() OVER (ORDER BY (a.balance * COALESCE((SELECT rate FROM exchange_rates er WHERE er.from_currency = a.currency AND er.to_currency = 'KZT' LIMIT 1), 1)) DESC) as balance_rank
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id;

CREATE OR REPLACE VIEW daily_transaction_report AS
SELECT 
    created_at::DATE as txn_date,
    type,
    COUNT(*) as txn_count,
    SUM(amount_kzt) as total_volume,
    AVG(amount_kzt) as avg_amount,
    
    SUM(SUM(amount_kzt)) OVER (ORDER BY created_at::DATE) as running_total,
    
    (SUM(amount_kzt) - LAG(SUM(amount_kzt)) OVER (ORDER BY created_at::DATE)) / NULLIF(LAG(SUM(amount_kzt)) OVER (ORDER BY created_at::DATE), 0) * 100 as growth_pct
FROM transactions
GROUP BY created_at::DATE, type;

CREATE OR REPLACE VIEW suspicious_activity_view WITH (security_barrier = true) AS
SELECT 
    t.*,
    c.full_name
FROM transactions t
JOIN accounts a ON t.from_account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
WHERE 
    t.amount_kzt > 5000000 
    OR
    t.from_account_id IN (
        
        SELECT from_account_id 
        FROM transactions 
        WHERE created_at > NOW() - INTERVAL '1 hour'
        GROUP BY from_account_id 
        HAVING COUNT(*) > 10
    );

--3

    CREATE INDEX idx_trans_account_date ON transactions (from_account_id, created_at) INCLUDE (amount, status);
    CREATE INDEX idx_active_accounts ON accounts (account_number) WHERE is_active = TRUE;
    CREATE INDEX idx_cust_iin_hash ON customers USING HASH (iin);
    CREATE INDEX idx_lower_email ON customers (LOWER(email));
    CREATE INDEX idx_audit_json ON audit_log USING GIN (new_values);

--4

CREATE OR REPLACE PROCEDURE process_salary_batch(
    p_company_acc_num VARCHAR,
    p_batch_data JSONB 
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_company_balance DECIMAL;
    v_total_batch DECIMAL := 0;
    v_rec JSONB;
    v_emp_acc_id INT;
    v_success_count INT := 0;
    v_failed_count INT := 0;
    v_failed_details JSONB := '[]'::JSONB;
    v_lock_key INT := hashtext(p_company_acc_num); 
BEGIN
    
    
    IF NOT pg_try_advisory_xact_lock(v_lock_key) THEN
        RAISE EXCEPTION 'Batch processing already in progress for this company';
    END IF;

    
    SELECT account_id, balance INTO v_company_id, v_company_balance
    FROM accounts WHERE account_number = p_company_acc_num FOR UPDATE;

    
    SELECT SUM((item->>'amount')::DECIMAL) INTO v_total_batch
    FROM jsonb_array_elements(p_batch_data) item;

    IF v_company_balance < v_total_batch THEN
        RAISE EXCEPTION 'Insufficient company funds for full batch';
    END IF;

    
    FOR v_rec IN SELECT * FROM jsonb_array_elements(p_batch_data)
    LOOP
        BEGIN
            
            SELECT a.account_id INTO v_emp_acc_id
            FROM accounts a 
            JOIN customers c ON a.customer_id = c.customer_id
            WHERE c.iin = v_rec->>'iin' AND a.currency = 'KZT' 
            LIMIT 1;

            IF v_emp_acc_id IS NULL THEN
                RAISE EXCEPTION 'Employee account not found for IIN %', v_rec->>'iin';
            END IF;

            
            
            
            
            UPDATE accounts SET balance = balance + (v_rec->>'amount')::DECIMAL 
            WHERE account_id = v_emp_acc_id;

            UPDATE accounts SET balance = balance - (v_rec->>'amount')::DECIMAL 
            WHERE account_id = v_company_id;

            
            INSERT INTO transactions (from_account_id, to_account_id, amount, amount_kzt, type, status, description)
            VALUES (v_company_id, v_emp_acc_id, (v_rec->>'amount')::DECIMAL, (v_rec->>'amount')::DECIMAL, 'transfer', 'completed', 'Salary: ' || (v_rec->>'description'));

            v_success_count := v_success_count + 1;

        EXCEPTION WHEN OTHERS THEN
            
            v_failed_count := v_failed_count + 1;
            v_failed_details := v_failed_details || jsonb_build_object('iin', v_rec->>'iin', 'error', SQLERRM);
            
        END;
    END LOOP;

    
    RAISE NOTICE 'Batch Complete. Success: %, Failed: %', v_success_count, v_failed_count;
    RAISE NOTICE 'Failures: %', v_failed_details;

END;
$$;