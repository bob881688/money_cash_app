UPDATE log_data
SET info = :info,
    stock_amount = :stock_amount,
    balance = :balance
WHERE log_id = :log_id;