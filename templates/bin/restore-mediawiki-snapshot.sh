#!/usr/bin/env bash

# generated from "<%= template %>"

mysqldump \
    --host="$(mysqlbackups "<%= config['mediawiki']['source_db'] %>" | head -1)" \
    --user="<%= config['mediawiki']['source_user'] %>" \
    --password="<%= config['mediawiki']['source_password'] %>" \
  "<%= config['mediawiki']['source_db'] %>" \
| mysql \
    --host=rdbms \
    --user="<%= config['mediawiki']['target_user'] %>" \
    --password="<%= config['mediawiki']['target_password'] %>" \
  "<%= config['mediawiki']['target_db'] %>"
EOF

chmod +x deployment/bin/"<%= config['mediawiki']['self'] %>"
