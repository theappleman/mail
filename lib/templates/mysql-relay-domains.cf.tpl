user = <%= $mailuser %>
password = <%= $mailuserpass %>
hosts = unix:/var/run/mysqld/mysqld.sock
dbname = <%= $mailserver %>
query = SELECT 1 FROM <%= $virtual_domains %> WHERE name='%s' and relay=1
