user = <%= $mailuser %>
password = <%= $mailuserpass %>
hosts = 127.0.0.1
dbname = <%= $mailserver %>
query = SELECT 1 FROM <%= $virtual_domains %> WHERE name='%s'
