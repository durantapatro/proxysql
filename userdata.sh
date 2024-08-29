#!/bin/bash

apt-get update
echo  "Installing mysql-server and mysql-client..." 
sudo apt -y install mysql-server
apt-get -y install mysql-client
sudo systemctl start mysql.service
echo  "Installed mysql client Successfully..." 

# Step 1: Install ProxySQL
echo "Installing ProxySQL..."

apt-get update
apt-get install -y --no-install-recommends lsb-release wget apt-transport-https ca-certificates gnupg
wget -O - 'https://repo.proxysql.com/ProxySQL/proxysql-2.6.x/repo_pub_key' | apt-key add - 
echo deb https://repo.proxysql.com/ProxySQL/proxysql-2.6.x/$(lsb_release -sc)/ ./ | tee /etc/apt/sources.list.d/proxysql.list
apt-get update
apt-get install proxysql
echo "ProxySQL Installed Successfully..."


git clone https://github.com/durantapatro/proxysql.git
sudo rm /etc/proxysql.cnf
sudo cp proxysql/proxysql.cnf /etc/
systemctl start proxysql


#echo  "Installing proxysql and Running from tecks_proxysql.cnf"

#proxysql -c /etc/teks_proxysql.cnf
#systemctl start proxysql






# Step 2: Connect to ProxySQL and Configure Admin Credentials
#echo "Configuring ProxySQL admin credentials..."
# mysql -u admin -padmin -h 127.0.0.1 -P6032 --prompt 'ProxySQLAdmin> ' << EOF
# UPDATE global_variables SET variable_value='admin:admin' WHERE variable_name='admin-admin_credentials';
# LOAD ADMIN VARIABLES TO RUNTIME;
# SAVE ADMIN VARIABLES TO DISK;
# EOF

# Step 3: Add Backends to ProxySQL
#echo "Adding MySQL backends..."
# mysql -u admin -padmin -h 127.0.0.1 -P6032 --prompt 'ProxySQLAdmin> ' << EOF
# INSERT INTO mysql_group_replication_hostgroups (writer_hostgroup, backup_writer_hostgroup, reader_hostgroup, offline_hostgroup, active, max_writers, writer_is_also_reader, max_transactions_behind) VALUES (2, 4, 3, 1, 1, 3, 1, 100);
# INSERT INTO mysql_servers(hostgroup_id,hostname,port) VALUES (1,'10.0.0.1',3306);
# INSERT INTO mysql_servers(hostgroup_id,hostname,port) VALUES (1,'10.0.0.2',3306);
# INSERT INTO mysql_servers(hostgroup_id,hostname,port) VALUES (1,'10.0.0.3',3306);
# LOAD MYSQL SERVERS TO RUNTIME;
# SAVE MYSQL SERVERS TO DISK;
# EOF
#echo "MySQL backends Added..."

# Step 4: Configure Monitoring on MySQL Server
echo "Configuring monitoring on MySQL server..."
#mysql -u root -p -e "
mysql -e "
CREATE USER 'monitor'@'%' IDENTIFIED BY 'monitor';
#GRANT SELECT on sys.* to 'monitor'@'%';
#GRANT SELECT on performance_schema.* to 'monitor'@'%';
GRANT USAGE, REPLICATION CLIENT ON *.* TO 'monitor'@'%';
FLUSH PRIVILEGES;
"

echo "Configuring ProxySQL to use the monitor user..."
mysql -u admin -padmin -h 127.0.0.1 -P6032 --prompt 'ProxySQLAdmin> ' << EOF
# UPDATE global_variables SET variable_value='monitor' WHERE variable_name='mysql-monitor_username';
# UPDATE global_variables SET variable_value='monitor' WHERE variable_name='mysql-monitor_password';
UPDATE global_variables SET variable_value='2000' WHERE variable_name IN ('mysql-monitor_connect_interval','mysql-monitor_ping_interval','mysql-monitor_read_only_interval');
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
EOF

# # Step 5: Backendâs Health Check
# echo "Performing backend health checks..."
# mysql -u admin -ppassword -h 127.0.0.1 -P6032 --prompt 'ProxySQLAdmin> ' << EOF
# SHOW TABLES FROM monitor;
# SELECT * FROM monitor.mysql_server_connect_log ORDER BY time_start_us DESC LIMIT 3;
# SELECT * FROM monitor.mysql_server_ping_log ORDER BY time_start_us DESC LIMIT 3;
# LOAD MYSQL SERVERS TO RUNTIME;
# SAVE MYSQL VARIABLES TO DISK;
# EOF

# Step 6: Create MySQL Users
echo "Creating MySQL users..."
mysql -e "
CREATE USER 'duranta'@'%' IDENTIFIED BY 'duranta';
GRANT ALL PRIVILEGES ON *.* TO 'duranta'@'%';
CREATE USER 'stnduser'@'%' IDENTIFIED BY 'stnduser';
GRANT ALL PRIVILEGES ON *.* TO 'stnduser'@'%';
"

# echo "Adding MySQL user to ProxySQL..."
# mysql -u admin -ppassword -h 127.0.0.1 -P6032 --prompt 'ProxySQLAdmin> ' << EOF
# INSERT INTO mysql_users(username, password, default_hostgroup) VALUES ('duranta', 'duranta', 2);
# LOAD MYSQL USERS TO RUNTIME;
# SAVE MYSQL USERS TO DISK;
# EOF

# # Step 7: Enable Web Interface in ProxySQL
# echo "Enabling the web interface..."
# mysql -u admin -ppassword -h 127.0.0.1 -P6032 --prompt 'ProxySQLAdmin> ' << EOF
# SET admin-web_enabled='true';
# LOAD ADMIN VARIABLES TO RUNTIME;
# SAVE ADMIN VARIABLES TO DISK;
# EOF

echo "ProxySQL configuration complete."