package nginx;

use Rex -base;

desc "Install nginx";
task "install", make {
	needs main "root" || die "Cannot gain root access";

	append_if_no_such_line "/etc/portage/package.accept_keywords",
		"=www-servers/nginx-1.9*",
		on_change => sub { pkg "nginx", ensure => "latest" };

	file "/etc/portage/package.use/www-servers",
		content => "www-servers/nginx rtmp nginx_modules_http_sub",
		on_change => sub { pkg "nginx", ensure => "latest" };

	pkg "nginx", ensure => "present";
	service "nginx", ensure => "started";

	file "/etc/nginx/nginx.conf",
		source => "lib/files/nginx.conf",
		on_change => sub { service "nginx" => "reload" };

	file "/etc/nginx/acme-challenge.conf",
		source => "lib/files/nginx/acme-challenge.conf",
		on_change => sub { service "nginx" => "reload" };

	file "/etc/nginx/ssl.conf",
		source => "lib/files/nginx/ssl.conf",
		on_change => sub { service "nginx" => "reload" };

	file "/var/www/rtmp",
		ensure => "directory",
		owner  => "nginx",
		group  => "nginx";
};

1;
