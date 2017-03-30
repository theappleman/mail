package acme;

use Rex -base;

desc "Install acmetool";
task "install", make {
	needs main "root" || die "Cannot gain root access";

	file "/etc/systemd/system/acmetool.service",
		content => template('@acmetool.service'),
		on_change => sub { run "systemctl daemon-reload" };
	pkg "dev-lang/go", ensure => "present";
	pkg "dev-vcs/git", ensure => "present";
	pkg "sudo", ensure => "present";

	if (not get_uid "acme") {
		create_user "acme",
			create_home => TRUE,
			ensure => "present";
	}

	file "/var/run/acme",
		ensure => "directory",
		owner => "root",
		group => "root";
	file "/var/run/acme/.well-known",
		ensure => "directory",
		owner => "root",
		group => "root";
	file "/var/run/acme/.well-known/acme-challenge",
		ensure => "directory",
		owner => "acme",
		group => "acme";

	file "/var/lib/acme",
		ensure => "directory",
		owner => "acme",
		group => "acme";

	sudo sub {
		file "/var/lib/acme/conf",
			ensure => "directory";

		file "/var/lib/acme/conf/responses",
			content => template('@response');

		run "go get github.com/hlandau/acme/cmd/acmetool",
			creates => "/home/acme/.local/go/bin/acmetool",
			env => {
				GOPATH => "/home/acme/.local/go",
			};

		run "/home/acme/.local/go/bin/acmetool quickstart --batch",
			creates => "/var/lib/acme/conf/target",
			env => {
				GOPATH => "/home/acme/.local/go",
			};
	}, user => "acme";

	service "acmetool.service", ensure => "started";
};

1;

__DATA__

@acmetool.service
[Unit]
Description=Run acmetool to renew certificates

[Service]
Type=oneshot
User=acme
Group=acme
WorkingDirectory=/home/acme
ExecStart=/home/acme/.local/go/bin/acmetool

[Install]
WantedBy=multi-user.target
@end

@response
"acme-enter-email": "leca@xxoo.ws"
"acme-agreement:https://letsencrypt.org/documents/LE-SA-v1.1.1-August-1-2016.pdf": true
"acmetool-quickstart-choose-server": https://acme-v01.api.letsencrypt.org/directory
"acmetool-quickstart-choose-method": webroot
"acmetool-quickstart-webroot-path": "/var/run/acme/.well-known/acme-challenge"
"acmetool-quickstart-complete": true
"acmetool-quickstart-rsa-key-size": 4096
@end
