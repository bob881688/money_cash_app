CREATE TABLE IF NOT EXISTS log_data (
    log_id           SERIAL PRIMARY KEY,
    user_id          INTEGER,
    record_date      DATE DEFAULT CURRENT_DATE,
    info             VARCHAR(100),
    stock_amount     INTEGER,
    balance          INTEGER
);

CREATE TABLE IF NOT EXISTS user_balance (
    user_id          INTEGER,
    balance          BIGINT
);