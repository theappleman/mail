user = <%= $mailuser %>
password = <%= $mailuserpass %>
hosts = unix:/var/run/mysqld/mysqld.sock
dbname = <%= $mailserver %>
query = select concat(username,':', password) as credentials from <% virtual_credentials %> where domain_name_id='%s'
