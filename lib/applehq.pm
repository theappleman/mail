package applehq;

use Rex -base;
use Rex::Commands::SCM;
use Rex::CMDB;

set repository => "applehq",
	url => 'https://github.com/theappleman/applehq.eu.git',
	type => "git";

desc "Install app";
task "install", make {
	needs main "root" || die "Cannot gain root access";
	pkg [qw|dev-vcs/git sudo local-lib App-cpanminus|], ensure => "present";

	my $accpw;

	LOCAL sub {
		$accpw = run "pwgen -s 97 1";
	};

	account "applehq",
		password => $accpw;
	file "/home/applehq",
		ensure => "directory",
		owner => "applehq",
		group => "applehq";

	file "/etc/nginx/vhosts.d/applehq.eu.conf",
		content => template("lib/templates/applehq.eu.conf.tpl",
			ssl => is_file("/var/lib/acme/live/applehq.eu/privkey")
			),
		on_change => sub { service "nginx" => "reload" };

	file "/etc/systemd/user/applehq.service",
		content => template('@service');

	# Enable linger
	file "/var/lib/systemd/linger",
		ensure => "directory";
	file "/var/lib/systemd/linger/applehq",
		ensure => "present";

	sudo { user => "applehq", command => sub {
		foreach my $csdir (@{[".config",".config/systemd",".config/systemd/user"]}) {
			file "/home/applehq/$csdir",
				ensure => "directory";
		}

		checkout "applehq",
			path => "/home/applehq/applehq.eu";

		#run "perl -Mlocal::lib /usr/bin/cpanm Mojolicious",
		#	creates => "/home/applehq/perl5";
		run "systemctl --user enable --now applehq";
	  }
	};
};

1;

__DATA__
@service
[Unit]
Description=applehq.eu mojolicious

[Service]
Type=simple
ExecStart=/usr/bin/perl -Mlocal::lib script/ahqweb daemon
WorkingDirectory=/home/applehq/applehq.eu

[Install]
WantedBy=default.target
@end
