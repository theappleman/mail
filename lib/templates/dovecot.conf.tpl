protocols = imap
mail_location = maildir:/<%= $maildir %>/%u
mail_privileged_group = mail
first_valid_uid = 0

disable_plaintext_auth = yes
auth_mechanisms = plain login

passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}
userdb {
  driver = static
  args = uid=mail gid=mail home=/<%= $maildir %>/%u
}

service imap-login {
  inet_listener imap {
    port = 0
  }
}
service pop3-login {
  inet_listener pop3 {
    port = 0
  }
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0666
    user = postfix
    group = postfix
  }
  unix_listener auth-userdb {
    mode = 0600
    user = mail
  }
  user = dovecot
}
service auth-worker {
  user = mail
}

<% if ($ssl) { %>
ssl_cert = <%= "<" %>/var/lib/acme/live/mail.0xdc.io/fullchain
ssl_key = <%= "<" %>/var/lib/acme/live/mail.0xdc.io/privkey
ssl = required

ssl_protocols = !SSLv2 !SSLv3
ssl_cipher_list = AES128+EECDH:AES128+EDH
ssl_prefer_server_ciphers = yes
ssl_dh_parameters_length = 4096
<% } %>


plugin {
  sieve_default = /etc/dovecot/sieve
}

protocol lda {
  postmaster_address = postmaster@%d
  mail_plugins = sieve
}
