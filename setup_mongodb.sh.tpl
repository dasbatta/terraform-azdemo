# Install MongoDB
echo "Installing MongoDB..."
curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
echo 'deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/6.0 multiverse' | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org=6.0.16 mongodb-org-database=6.0.16 mongodb-org-server=6.0.16 mongodb-org-mongos=6.0.16 mongodb-org-tools=6.0.16
sudo sysctl -w vm.max_map_count=262144
sudo systemctl start mongod

# Create MongoDB application user
echo "Creating MongoDB application user..."
sleep 60
mongosh <<EOF
use admin
db.createUser({
  user: "backupuser",
  pwd: "${mongo_password}",
  roles: [{ role: "userAdminAnyDatabase", db: "admin" }, { role: "backup", db: "admin" }, { role: "readWriteAnyDatabase", db: "admin" }]
})
EOF

echo "security:
  authorization: \"enabled\"" | sudo tee -a /etc/mongod.conf
sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf  
sudo systemctl restart mongod

echo "MongoDB setup complete."