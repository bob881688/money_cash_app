CREATE TABLE IF NOT EXISTS log_data (
    log_id           SERIAL PRIMARY KEY,
    user_id          INTEGER,
    record_date      DATE DEFAULT CURRENT_DATE,
    info             VARCHAR(100),
    stock_amount     INTEGER,
    balance          INTEGER
);

CREATE TABLE IF NOT EXISTS users (
    user_id          SERIAL,
    username         VARCHAR(50) NOT NULL PRIMARY KEY,
    password         VARCHAR(255) NOT NULL,
    email            VARCHAR(100) NOT NULL,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active        BOOLEAN DEFAULT TRUE
);