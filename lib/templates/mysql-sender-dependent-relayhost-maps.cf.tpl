user = <%= $mailuser %>
password = <%= $mailuserpass %>
hosts = unix:/var/run/mysqld/mysqld.sock
dbname = <%= $mailserver %>
query = select relayhost from <%= $virtual_credentials %> where concat("@", domain_name_id)='%s' limit 1
