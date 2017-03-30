package sysstat;

use Rex -base;
use Rex::Commands::SCM;
use dotd;

desc "Install sysstat";
task "install", group => "hosts", make {
	my $params = shift;

	needs main "root" || die "Cannot gain root access";

	dotd::dotd { conf => "/etc/portage/package.accept_keywords",
		line => "app-admin/sysstat ~arm" };

	pkg "sysstat", ensure => "present";

	if ($params->{timers}) {
		Rex::Logger::info("Enabling custom systemd timers, bgo #535788", "warn");
		file "/etc/systemd/system/sysstat-collect.timer",
			content => template('@timer',
				description => "Run system activity accounting tool every 10 minutes",
				when => "*:00/10",
			),
			on_change => sub { run "systemd daemon-reload" };
		file "/etc/systemd/system/sysstat-summary.timer",
			content => template('@timer',
				description => "Generate summary of yesterday's process accounting",
				when => "00:07:00"
			),
			on_change => sub { run "systemd daemon-reload" };

		file "/etc/systemd/system/sysstat-collect.service",
			content => template('@service',
				description => "system activity accounting tool",
				documentation => "man:sa1(8)",
				exec => "/usr/lib/sa/sa1 1 1"
			),
			on_change => sub { run "systemd daemon-reload" };

		file "/etc/systemd/system/sysstat-summary.service",
			content => template('@service',
				description => "Generate daily summary of process accounting",
				documentation => "man:sa2(8)",
				exec => "/usr/lib/sa/sa2 -A"
			),
			on_change => sub { run "systemd daemon-reload" };
	} else {
		file "/etc/systemd/system/sysstat-collect.service", ensure => "absent";
		file "/etc/systemd/system/sysstat-collect.timer", ensure => "absent";
		file "/etc/systemd/system/sysstat-summary.service", ensure => "absent";
		file "/etc/systemd/system/sysstat-summary.timer", ensure => "absent";
	}

	service "sysstat", ensure => "started";
	service "sysstat", ensure => "start";
};

1;

__DATA__
@timer
[Unit]
Description=<%= $description %>

[Timer]
OnCalendar=<%= $when %>

[Install]
WantedBy=sysstat.service
@end

@service
[Unit]
Description=<%= $description %>
Documentation=<%= $documentation %>

[Service]
Type=oneshot
#User=@CRON_OWNER@
ExecStart=<%= $exec %>
