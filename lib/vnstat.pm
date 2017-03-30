package vnstat;

use Rex -base;

desc "Install vnstat";
task "install", make {
	needs main "root" || die "Cannot gain root access";
	pkg "vnstat", ensure => "present";

	file "/etc/systemd/system/vnstat.service",
		content => template('@vnstat'),
		on_change => sub { run "systemd daemon-reload" };

	service "vnstat", ensure => "started";
};

1;

__DATA__

@vnstat
[Unit]
Description=vnstat collector

[Service]
ExecStart=/usr/bin/vnstatd -n

[Install]
WantedBy=multi-user.target
@end
