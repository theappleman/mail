package btrfs;

use Rex -base;

desc "Install btrfs-progs";
task "install", make {
	needs main "root" || die "Cannot gain root access";
	pkg "btrfs-progs", ensure => "present";
};

desc "Install scrub timer";
task "scrub", make {
	needs main "root" || die "Cannot gain root access";

	file "/usr/local/sbin/btrfs-scrub",
		content => template('@scrub'),
		mode => "0700";
	file "/etc/systemd/system/btrfs-scrub.service",
		content => template('@scrub.service'),
		on_change => sub { run "systemctl daemon-reload" };
	file "/etc/systemd/system/btrfs-scrub.timer",
		content => template('@scrub.timer'),
		on_change => sub { run "systemctl daemon-reload" };
	
	service "btrfs-scrub.timer", ensure => "started";
};

1;

__DATA__
@scrub
#!/bin/bash

mount -t btrfs | awk '{print$1}' | uniq | xargs --no-run-if-empty -n1 btrfs scrub start -Bd
@end

@scrub.service
[Unit]
Description=btrfs filesystem scrub

[Service]
ExecStart=/usr/local/sbin/btrfs-scrub
@end

@scrub.timer
[Unit]
Description=Periodically run btrfs scrub

[Timer]
OnBootSec=30min
OnUnitActiveSec=1w

[Install]
WantedBy=timers.target
@end
