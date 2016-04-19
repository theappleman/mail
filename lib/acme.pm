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
	if (not get_uid "acme") {
		create_user "acme",
			create_home => TRUE,
			ensure => "present";
	}

	run "go get github.com/hlandau/acme/cmd/acmetool",
		creates => "/home/acme/.local/go/bin/acmetool",
		env => {
			GOPATH => "/home/acme/.local/go",
		},
		user => "acme";
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
@end
