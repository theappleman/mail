smtpd_tls_cert_file=/var/lib/acme/live/<%= $hostname %>.<%= $domain %>/cert
smtpd_tls_CAfile=/var/lib/acme/live/<%= $hostname %>.<%= $domain %>/chain
smtpd_tls_key_file=/var/lib/acme/live/<%= $hostname %>.<%= $domain %>/privkey
smtpd_use_tls=yes
smtpd_tls_auth_only = yes
smtp_tls_security_level = may
smtp_tls_loglevel = 2
smtpd_tls_received_header = yes

smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes

smtpd_client_restrictions =
	permit_sasl_authenticated,
	defer_if_reject reject_rbl_client b.barracudacentral.org,
	defer_if_reject reject_unknown_reverse_client_hostname,
	reject_unauth_destination
smtpd_recipient_restrictions =
	permit_sasl_authenticated,
	permit_mynetworks,
	reject_unauth_destination

mydestination = localhost

virtual_transport = dovecot
virtual_mailbox_domains = mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
virtual_mailbox_maps = mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
virtual_alias_maps = mysql:/etc/postfix/mysql-virtual-alias-maps.cf
local_recipient_maps = $virtual_mailbox_maps


append_dot_mydomain=no
compatibility_level=2


smtpd_milters           = inet:127.0.0.1:8891
non_smtpd_milters       = $smtpd_milters
milter_default_action   = accept
