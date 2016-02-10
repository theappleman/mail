driver = mysql
connect = host=127.0.0.1 dbname=<%= $mailserver %> user=<%= $mailuser %> password=<%= $mailuserpass %>
default_pass_scheme = SHA512-CRYPT
password_query = SELECT name as user, password FROM <%= $virtual_users %> WHERE name='%u';
iterate_query = SELECT name as user FROM <%= $virtual_users %>;
