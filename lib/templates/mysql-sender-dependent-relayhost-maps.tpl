user = <%= $mailuser %>
password = <%= $mailuserpass %>
hosts = unix:/var/run/mysqld/mysqld.sock
dbname = <%= $mailserver %>
query = select concat('@',domain_name_id) as domain, relayhost from <% virtual_credentials %> where domain_name_id='%s'
