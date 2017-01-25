package nginx;

use Rex -base;

desc "Install nginx";
task "install", make {
	needs main "root" || die "Cannot gain root access";
	my $params = shift;

	run "nginx-latest",
		command => sub {
			pkg "nginx", ensure => "latest";
			service "nginx" => "restart";
		},
		only_notified => TRUE;

	if ($params->{rtmp}) {
		file "/etc/portage/profile",
			ensure => "directory";
		append_if_no_such_line "/etc/portage/profile/package.use.mask",
			"www-servers/nginx -rtmp";
		append_if_no_such_line "/etc/portage/package.accept_keywords",
			"www-servers/nginx:0 ~arm";
		file "/etc/portage/package.use/www-servers",
			content => "www-servers/nginx rtmp",
			on_change => sub { notify "run", "nginx-latest" };
	}

	file "/etc/portage/package.use/www-servers",
		content => "www-servers/nginx nginx_modules_http_sub",
		on_change => sub { notify "run", "nginx-latest" };

	pkg "nginx", ensure => "present";
	service "nginx", ensure => "started";

	file "/etc/nginx/nginx.conf",
		source => "lib/files/nginx.conf",
		on_change => sub { service "nginx" => "reload" };

	file "/etc/nginx/conf.d",
		ensure => "directory";
	file "/etc/nginx/vhosts.d",
		ensure => "directory";

	file "/etc/nginx/acme-challenge.conf",
		source => "lib/files/nginx/acme-challenge.conf",
		on_change => sub { service "nginx" => "reload" };

	file "/etc/nginx/ssl.conf",
		source => "lib/files/nginx/ssl.conf",
		on_change => sub { service "nginx" => "reload" };

	if ($params->{rtmp}) {
		file "/var/www/rtmp",
			ensure => "directory",
			owner  => "nginx",
			group  => "nginx";
		file "/etc/nginx/conf.d/rtmp.conf",
			content => template("templates/rtmp.conf.tpl"),
			on_change => sub { service "nginx" => "reload" };
	}
};

1;
