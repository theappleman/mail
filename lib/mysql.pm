package mysql;

use Rex -base;

desc "Install MySQL";
task "install", make {
	needs main "root" || die "Cannot gain root access";
	pkg "virtual/mysql", ensure => "present";

	run "/usr/share/mysql/scripts/mysql_install_db",
		cwd => "/usr",
		creates => "/var/lib/mysql/ibdata1";

	run "systemd-tmpfiles --create",
		creates => "/var/run/mysqld";

	file "/etc/mysql/zz-mybind.cnf",
		"ensure" => "absent";
	file "/etc/mysql/mybind.cnf",
		content => template('@mybind.cnf'),
		on_change => sub { service "mysqld" => "restart" };
	delete_lines_according_to qr{^bind-address}, "/etc/mysql/my.cnf",
		on_change => sub { service "mysqld" => "restart" };
	service "mysqld", ensure => "started";

	my $pwgen;
	LOCAL {
		$pwgen = run "pwgen -s";
	};

	run "mysqladmin password $pwgen";
	file "/root/.my.cnf",
		content => template('@my.cnf', password => $pwgen),
		if $? == 0;

	run q|mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"|;
	run q|mysql -e "DELETE FROM mysql.user WHERE User=''"|;
	run q|mysql -e "DROP DATABASE IF EXISTS test"|;
	run q|mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"|;
	run q|mysql -e "FLUSH PRIVILEGES"|;
};

desc "Ensure mysql user exists";
task "mkuser", make {
	needs main "root" || die "Cannot gain root access";
	my $params = shift;

	my $db = $params->{database} || die "No database given";
	my $user = $params->{username} || die "No username given";
	my $host = $params->{hostname} || die "No hostname given";
	my $pass = $params->{password} || die "No password given";
	my $glvl = $params->{grantlvl} || "ALL";

	if (length($user) > 15) {
		Rex::Logger::info("Username is (potentially) too long for MySQL, continuing...","warn");
		Rex::Logger::info("Username $user is ".length($user)." long","warn");
	}

	run qq|mysql -e "CREATE DATABASE IF NOT EXISTS $db"|;
	run qq|mysql -e "grant $glvl on $db.* to '$user'\@'$host' identified by '$pass'"|,
		unless => qq/mysql -e "select user from mysql.user" | grep -q $user/;
};

1;

__DATA__
@mybind.cnf
[mysqld]
bind-address = ::
@end

@my.cnf
[client]
user=root
password=<%= $password %>
@end
