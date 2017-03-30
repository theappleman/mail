smtp      inet  n       -       n       -       -       smtpd
  -o smtpd_tls_security_level=may
submission inet n       -       n       -       -       smtpd
smtps     inet  n       -       n       -       -       smtpd
  -o smtpd_tls_wrappermode=yes

smtp      unix  -       -       n       -       -       smtp
rewrite   unix  -       -       n       -       -       trivial-rewrite
cleanup   unix  n       -       n       -       0       cleanup
anvil     unix  -       -       n       -       1       anvil
qmgr      unix  n       -       n       300     1       qmgr
tlsmgr    unix  -       -       n       1000?   1       tlsmgr
retry     unix  -       -       n       -       -       error
pickup    unix  n       -       n       60      1       pickup
scache    unix  -       -       n       -       1       scache
virtual   unix  -       n       n       -       -       virtual
bounce    unix  -       -       n       -       0       bounce
defer     unix  -       -       n       -       0       bounce

dovecot   unix  -       n       n       -       -       pipe
  flags=ODRhu user=mail:mail argv=/usr/libexec/dovecot/dovecot-lda -f ${sender} -a ${original_recipient} -d ${user}@${nexthop}
