package portage;

use Rex -base;

desc "Install portage-sync timer";
task "sync", group => "hosts", make {
	needs main "root" || die "Cannot gain root access";

	file "/etc/portage/repos.conf",
		ensure => "directory";
	file "/etc/portage/repos.conf/gentoo.conf",
		content => template('@gentoo');

	file "/etc/systemd/system/portage-sync.service",
		content => template('@sync.service'),
		on_change => sub { run "systemctl daemon-reload" };
	file "/etc/systemd/system/portage-sync.timer",
		content => template('@sync.timer'),
		on_change => sub { run "systemctl daemon-reload" };

	service "portage-sync.timer", ensure => "started";
};

1;

__DATA__
@gentoo
[DEFAULT]
main-repo = gentoo

[gentoo]
location = /usr/portage
sync-type = rsync
sync-uri = rsync://rsync.gentoo.org/gentoo-portage
auto-sync = yes

# for daily squashfs snapshots
#sync-type = squashdelta
#sync-uri = mirror://gentoo/../snapshots/squashfs
@end

@sync.service
[Unit]
Description=Sync portage trees

[Service]
ExecStart=/usr/sbin/emaint sync -a
@end

@sync.timer
[Unit]
Description=Sync portage trees periodically

[Timer]
OnBootSec=6h
OnUnitActiveSec=24h
AccuracySec=6h
#RandomizedDelaySec=10min

[Install]
WantedBy=timers.target
@end
