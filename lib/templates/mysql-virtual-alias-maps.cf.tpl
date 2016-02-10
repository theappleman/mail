user = <%= $mailuser %>
password = <%= $mailuserpass %>
hosts = unix:/var/run/mysqld/mysqld.sock
dbname = <%= $mailserver %>
query = select name from <%= $virtual_users %> where id=(select target_id from <%= $virtual_aliases %> where concat(source,"@",(select name from <%= $virtual_domains %> where id=domain_id))='%s' order by id asc limit 1);
