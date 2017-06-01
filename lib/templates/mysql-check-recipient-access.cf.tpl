user = <%= $mailuser %>
password = <%= $mailuserpass %>
hosts = unix:/var/run/mysqld/mysqld.sock
dbname = <%= $mailserver %>
query = select concat(action, " ", message) from <%= $virtual_recipients %> where address='%s';
