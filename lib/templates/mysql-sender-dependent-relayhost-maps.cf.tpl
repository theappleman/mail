user = <%= $mailuser %>
password = <%= $mailuserpass %>
hosts = unix:/var/run/mysqld/mysqld.sock
dbname = <%= $mailserver %>
query = select relayhost from <%= $virtual_credentials %> where '%s' in (username, concat("@", domain_name_id)) limit 1
