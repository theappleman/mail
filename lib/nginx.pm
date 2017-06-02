package nginx;

use Rex -base;
use dotd;

desc "Install nginx (--rtmp)";
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
		dotd::dotd { conf => "/etc/portage/profile/package.use.mask",
			line => "www-servers/nginx -rtmp" };
		dotd::dotd { conf => "/etc/portage/package.accept_keywords",
			line => "www-servers/nginx:0 ~arm" };
		dotd::dotd { conf => "/etc/portage/package.use",
			line => "www-servers/nginx rtmp" };
		pkg "nginx[rtmp]", ensure => "present";
	}

	dotd::dotd { conf => "/etc/portage/package.use",
		line => "www-servers/nginx nginx_modules_http_sub" };

	pkg "nginx[nginx_modules_http_sub]", ensure => "present";
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
