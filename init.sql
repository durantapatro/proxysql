-- Filename: /path/to/init.sql

-- Create the 'monitor' user
CREATE USER IF NOT EXISTS 'monitor'@'%' IDENTIFIED BY 'monitor';

-- Grant USAGE and REPLICATION CLIENT privileges
GRANT USAGE, REPLICATION CLIENT ON *.* TO 'monitor'@'%';

-- Apply the changes
FLUSH PRIVILEGES;
