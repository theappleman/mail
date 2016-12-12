package recap;

use Rex -base;
use Rex::Commands::SCM;

set repository => "recap",
	url => 'https://github.com/rackerlabs/recap';

desc "Install recap";
task "install", group => "hosts", make {
	needs main "root" || die "Cannot gain root access";
	pkg "dev-vcs/git", ensure => "present";
	pkg "bc", ensure => "present";

	checkout "recap",
		path => "/usr/src/recap";

	run "make install",
		cwd => "/usr/src/recap",
		creates => "/usr/sbin/recap";

	file "/etc/systemd/system/recap.service",
		content => template('@service',
			command => "/usr/sbin/recap -B",
			description => "recap"
			),
		on_change => sub { run "systemctl daemon-reload" };
	file "/etc/systemd/system/recap-collect.service",
		content => template('@service',
			command => "/usr/sbin/recap",
			description => "save recap data",
		),
		on_change => sub { run "systemctl daemon-reload" };
	file "/etc/systemd/system/recaplog.service",
		content => template('@service',
			command => "/usr/sbin/recaplog",
			description => "archive logs",
		),
		on_change => sub { run "systemctl daemon-reload" };

	file "/etc/systemd/system/recap-collect.timer",
		content => template('@timer',
			when => "OnCalendar=*:05/10",
		),
		on_change => sub { run "systemctl daemon-reload" };
	file "/etc/systemd/system/recaplog.timer",
		content => template('@timer',
			when => 'OnCalendar=00:00',
		),
		on_change => sub { run "systemctl daemon-reload" };

	service "recap", ensure => "started";
	service "recap", ensure => "start";
};

1;
__DATA__
@service
[Unit]
Description=<%= $description %>
<% unless ($description eq 'recap')  { %>
After=recap.service
<% } %>

[Service]
Type=oneshot
ExecStart=<%= $command %>

[Install]
WantedBy=multi-user.target
<% if ($description eq 'recap')  { %>
Also=recaplog.timer
Also=recap-collect.timer
<% } %>
@end

@timer
[Unit]
Description=Run %p periodically

[Timer]
<%= $when %>

[Install]
WantedBy=recap.service
@end
