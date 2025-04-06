#!/bin/bash

# Skriv miljövariabler för databasen
cat <<EOF > /etc/cmdb.env
DB_URL=${db_url}
DB_USER=${db_user}
DB_PASS=${db_pass}
EOF

chmod 600 /etc/cmdb.env

# Ladda om systemd och våran service
systemctl daemon-reload
systemctl restart cmdb.service