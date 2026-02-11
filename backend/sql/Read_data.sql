SELECT log_id, record_date, info, stock_amount, balance
FROM log_data
WHERE user_id = :user_id
ORDER BY record_date DESC, log_id ASC;