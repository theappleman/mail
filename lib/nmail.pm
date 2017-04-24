package nmail;

use Rex -base;
use Rex::CMDB;
use dotd;

desc "SMTP server";
task "postfix", make {
	needs main "root" || die "Could not gain root privileges";

	my $mailuser = get(cmdb("mailuser"));
	my $mailuserpass = get(cmdb("mailuserpass"));
	my $mailserver = get(cmdb("mailserver"));
	my $virtual_domains = get(cmdb("virtual_domains"));
	my $virtual_users = get(cmdb("virtual_users"));
	my $virtual_alias = get(cmdb("virtual_aliases"));

	dotd::dotd { conf => "/etc/portage/package.use",
		line => "mail-mta/postfix mysql dovecot-sasl" };
	pkg "postfix", ensure => "present";
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

desc "IMAP server";
task "dovecot", make {
	needs main "root" || die "Could not gain root privileges";

	my $mailuser = get(cmdb("mailuser"));
	my $mailuserpass = get(cmdb("mailuserpass"));
	my $mailserver = get(cmdb("mailserver"));
	my %sysinf = get_system_information;

	dotd::dotd { conf => "/etc/portage/package.use",
		line => "net-mail/dovecot mysql sieve" };

	pkg "dovecot", ensure => "present";
	service "dovecot", ensure => "started";

	file "/mail",
		ensure => "directory",
		owner => "dovecot",
		group => "mail",
		mode  => "0770";

	file "/etc/dovecot/sieve",
		source => "files/sieve",
		on_change => sub { run "sievec /etc/dovecot/sieve" };
	file "/etc/dovecot/dovecot.conf",
		content => template("templates/dovecot.conf.tpl",
			maildir => "mail",
			ssl => is_file("/var/lib/acme/live/mail.0xdc.io/privkey"),
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

desc "DKIM filter";
task "opendkim", make {
	needs main "root" || die "Could not gain root privileges";

	my $mailuser = get(cmdb("mailuser"));
	my $mailuserpass = get(cmdb("mailuserpass"));
	my $mailserver = get(cmdb("mailserver"));

	file "/etc/tmpfiles.d",
		ensure => "directory";
	file "/etc/tmpfiles.d/opendkim.conf",
		content => "D /run/opendkim 0750 milter postfix";
	file "/etc/portage/profile",
		ensure => "directory";
	dotd::dotd { conf => "/etc/portage/profile/package.use.mask",
		line => "mail-filter/opendkim -opendbx" };

	foreach my $line (@{["dev-db/opendbx **","mail-filter/opendkim ~arm","mail-filter/libmilter ~arm"]}) {
		dotd::dotd {
			conf => "/etc/portage/package.accept_keywords",
			line => $line,
		}
	}

	file "/etc/portage/package.use/opendkim",
		on_change => sub { pkg "opendkim", ensure => "latest" },
		content => template('@opendkim.use');
	pkg "opendkim", ensure => "present";
	service "opendkim", ensure => "started";

	file "/run/opendkim",
		ensure => "directory",
		owner => "milter",
		group => "postfix";

	file "/etc/opendkim/TrustedHosts",
		content => "127.0.0.1",
		on_change => sub { service "opendkim" => "restart" };
	file "/etc/opendkim/opendkim.conf",
		content => template("templates/opendkim.conf.tpl",
			mailuser => $mailuser,
			mailuserpass => $mailuserpass,
			mailserver => $mailserver,
			),
			on_change => sub { service "opendkim" => "restart" };
};

desc "Make the mail user";
task "user", make {
	my $mailuser = get(cmdb("mailuser"));
	my $mailuserpass = get(cmdb("mailuserpass"));
	my $mailserver = get(cmdb("mailserver"));
	my $mailhost = get(cmdb("mailhost"));

	run_task "mysql:mkuser", on => connection->server, params => {
		database => $mailserver,
		hostname => $mailhost,
		username => $mailuser,
		password => $mailuserpass,
	};
};

1;


__DATA__

@opendkim.use
mail-filter/opendkim opendbx
net-libs/ldns -ecdsa
@end
