protocols = imap lmtp
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

service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    mode = 0666
    group = postfix
    user = postfix
  }
  user=mail
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

ssl_cert = <%= "<" %>/var/lib/acme/live/<%= $hostname %>.<%= $domain %>/fullchain
ssl_key = <%= "<" %>/var/lib/acme/live/<%= $hostname %>.<%= $domain %>/privkey
ssl = required
