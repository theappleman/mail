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

desc "Take btrfs snapshots regularly";
task "snapshot", group => "servers", make {
	needs main "root" || die "Cannot gain root access";

	file "/usr/local/sbin/btrfs-snap",
		content => template('@snap'),
		mode => "0700";
	file "/etc/systemd/system/btrfs-snap.service",
		content => template('@snap.service'),
		on_change => sub { run "systemctl daemon-reload" };
	file "/etc/systemd/system/btrfs-snap.timer",
		content => template('@snap.timer'),
		on_change => sub { run "systemctl daemon-reload" };

	service "btrfs-snap.timer", ensure => "started";
};

1;

__DATA__
@scrub
#!/bin/bash

mount -t btrfs | awk '{print$3}' | xargs --no-run-if-empty -n1 btrfs fi show | awk '/devid/{print$NF}' | uniq | xargs --no-run-if-empty -n1 btrfs scrub start -Bd
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

@snap
#!/bin/bash

date=$(date +%Y-%m-%d)

mount -t btrfs | awk '{if(dev[$1] == ""){dev[$1]=$3; print$3}}' | while read devpath; do
	test -d $devpath/.btrfs/snapshots/ || mkdir -p $devpath/.btrfs/snapshots/
	btrfs subv snap $devpath $devpath/.btrfs/snapshots/$date
done
@end

@snap.service
[Unit]
Description=btrfs filesystem snapshot

[Service]
ExecStart=/usr/local/sbin/btrfs-snap
@end

@snap.timer
[Unit]
Description=Periodically snapshot btrfs filesystems

[Timer]
OnCalendar=05:00:00

[Install]
WantedBy=timers.target
@end
