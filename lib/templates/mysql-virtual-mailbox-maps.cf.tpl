user = <%= $mailuser %>
password = <%= $mailuserpass %>
hosts = unix:/var/run/mysqld/mysqld.sock
dbname = <%= $mailserver %>
query = SELECT 1 FROM <%= $virtual_users %> WHERE name='%s'
