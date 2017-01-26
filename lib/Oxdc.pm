package Oxdc;

use Rex -base;
use Rex::Commands::SCM;
use Rex::CMDB;

set repository => "0xdc",
	url => 'https://github.com/theappleman/0xdc-cfg.git',
	type => "git";

desc "Install 0xdc app";
task "install", make {
	needs main "root" || die "Cannot gain root access";
	pkg "dev-vcs/git", ensure => "present";
	pkg "sudo", ensure => "present";

	my $accpw;
	my $Oxdc = get cmdb("Oxdc");

	LOCAL sub {
		$accpw = run "pwgen -s 97 1";
	};

	account "_0xdc",
		password => $accpw;
	file "/home/_0xdc",
		ensure => "directory",
		owner => "_0xdc",
		group => "_0xdc";

	run "mysql -e 'create database $Oxdc->{database}'",
		unless => "mysql -e 'show databases' | grep -q $Oxdc->{database}";

	run "mysql -e 'grant all on $Oxdc->{database}.* to \"$Oxdc->{username}\"@\"$Oxdc->{hostname}\" identified by \"$Oxdc->{password}\"'",
		unless => "mysql -e 'select user,host from mysql.user' | grep -q $Oxdc->{username}";

	file "/etc/nginx/vhosts.d/0xdc.conf",
		content => template("lib/templates/0xdc.conf.tpl",
			ssl => is_file("/var/lib/acme/live/0xdc.io/privkey")
			),
		on_change => sub { service "nginx" => "reload" };

	file "/etc/systemd/user/0xdc.service",
		content => template('@service');
	#use Data::Dumper; say Dumper $Oxdc;

	sudo { user => "_0xdc", command => sub {
		checkout "0xdc",
			path => "/home/_0xdc/0xdc-cfg";
		file "/home/_0xdc/.0xdc.cfg",
			content => template('@0xdc.cfg',
				Oxdc => $Oxdc,
			),
			owner => "_0xdc",
			group => "_0xdc",
			mode => "0600";

		run "pyvenv-3.4 env",
			cwd => "/home/_0xdc/0xdc-cfg",
			creates => "/home/_0xdc/0xdc-cfg/env/bin/activate";
		run ". env/bin/activate && pip install -r requirements.txt",
			cwd => "/home/_0xdc/0xdc-cfg";
		run "systemctl --user restart 0xdc";
	  }
	};
};

1;

__DATA__

@0xdc.cfg
SECRET_KEY=<%= $Oxdc->{secret_key} %>
DB_DEFAULT_HOST=<%= $Oxdc->{hostname} %>
DB_DEFAULT_NAME=<%= $Oxdc->{database} %>
DB_DEFAULT_USER=<%= $Oxdc->{username} %>
DB_DEFAULT_PASSWORD=<%= $Oxdc->{password} %>
DEBUG=<%= $Oxdc->{debug} %>
ALLOWED_HOST=<%= $hostname %>
@end

@service
[Unit]
Description=Django syscfg

[Service]
Type=simple
EnvironmentFile=/home/_0xdc/.0xdc.cfg
ExecStartPre=/home/_0xdc/0xdc-cfg/env/bin/python /home/_0xdc/0xdc-cfg/manage.py collectstatic --no-input
ExecStartPre=/home/_0xdc/0xdc-cfg/env/bin/python /home/_0xdc/0xdc-cfg/manage.py migrate
ExecStart=/home/_0xdc/0xdc-cfg/env/bin/gunicorn syscfg.wsgi:application
WorkingDirectory=/home/_0xdc/0xdc-cfg
@end
