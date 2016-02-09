user = <%= $mailuser %>
password = <%= $mailuserpass %>
hosts = 127.0.0.1
dbname = <%= $mailserver %>
query = select name from <%= $virtual_users %> where id=(select target_id from <%= $virtual_aliases %> where concat("@",(select name from <%= $virtual_domains %> where id=domain_id))='%s');
