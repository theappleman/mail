##
## opendkim.conf -- configuration file for OpenDKIM filter
##
Canonicalization        relaxed/relaxed
ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts
InternalHosts           refile:/etc/opendkim/TrustedHosts
LogWhy                  Yes
MinimumKeyBits          1024
Mode                    sv
PidFile                 /var/run/opendkim/opendkim.pid
Socket                  inet:8891@localhost
Syslog                  Yes
SyslogSuccess           Yes
TemporaryDirectory      /var/tmp
UMask                   022
UserID                  milter:milter

SigningTable            dsn:mysql://<%= $mailuser %>:<%= $mailuserpass %>@127.0.0.1/<%= $mailserver %>/table=nsamail_dkimdomain?keycol=domain_name_id?datacol=id
KeyTable                dsn:mysql://<%= $mailuser %>:<%= $mailuserpass %>@127.0.0.1/<%= $mailserver %>/table=nsamail_dkimdomain?keycol=id?datacol=domain_name_id,selector,private_key
