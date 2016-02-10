package nmail;

use Rex -base;
use Rex::CMDB;

task "postfix", make {
	my $mailuser = get(cmdb("mailuser"));
	my $mailuserpass = get(cmdb("mailuserpass"));
	my $mailserver = get(cmdb("mailserver"));
	my $virtual_domains = get(cmdb("virtual_domains"));
	my $virtual_users = get(cmdb("virtual_users"));
	my $virtual_alias = get(cmdb("virtual_aliases"));

	file "/etc/portage/package.use/mail-mta",
		content => "mail-mta/postfix mysql dovecot-sasl";
	pkg "postfix", ensure => "latest";
	service "postfix", ensure => "started";

	file "/etc/postfix/main.cf",
		content => template("templates/main.cf.tpl",
		),
		on_change => sub { service "postfix" => "restart" };
	file "/etc/postfix/master.cf",
		content => template("templates/master.cf.tpl",
		),
		on_change => sub { service "postfix" => "restart" };
	file "/etc/postfix/mysql-virtual-mailbox-domains.cf",
		content => template("templates/mysql-virtual-mailbox-domains.cf.tpl",
			mailuser => $mailuser,
			mailuserpass => $mailuserpass,
			mailserver => $mailserver,
			virtual_domains => $virtual_domains,
		),
		on_change => sub { service "postfix" => "restart" };
	file "/etc/postfix/mysql-virtual-mailbox-maps.cf",
		content => template("templates/mysql-virtual-mailbox-maps.cf.tpl",
			mailuser => $mailuser,
			mailuserpass => $mailuserpass,
			mailserver => $mailserver,
			virtual_users => $virtual_users,
		),
		on_change => sub { service "postfix" => "restart" };
	file "/etc/postfix/mysql-virtual-alias-maps.cf",
		content => template("templates/mysql-virtual-alias-maps.cf.tpl",
			mailuser => $mailuser,
			mailuserpass => $mailuserpass,
			mailserver => $mailserver,
			virtual_aliases => $virtual_alias,
			virtual_users => $virtual_users,
		),
		on_change => sub { service "postfix" => "restart" };
};

task "dovecot", make {
	my $mailuser = get(cmdb("mailuser"));
	my $mailuserpass = get(cmdb("mailuserpass"));
	my $mailserver = get(cmdb("mailserver"));

	file "/etc/portage/package.use/net-mail",
		content => "net-mail/dovecot mysql sieve";

	pkg "dovecot", ensure => "latest";
	service "dovecot", ensure => "started";

	file "/etc/dovecot/sieve",
		source => "files/sieve",
		on_change => sub { run "sievec /etc/dovecot/sieve" };
	file "/etc/dovecot/dovecot.conf",
		content => template("templates/dovecot.conf.tpl",
			maildir => "mail",
		),
		on_change => sub { service "dovecot" => "restart" };
	file "/etc/dovecot/dovecot-sql.conf.ext",
		content => template("templates/dovecot-sql.conf.ext.tpl",
			mailuser => $mailuser,
			mailuserpass => $mailuserpass,
			mailserver => $mailserver,
		),
		on_change => sub { service "dovecot" => "restart" };
};

1;
