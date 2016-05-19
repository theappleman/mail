package mysql;

use Rex -base;

desc "Install MySQL";
task "install", make {
	needs main "root" || die "Cannot gain root access";
	pkg "mysql", ensure => "present";
	service "mysqld", ensure => "started";

	# check root user exists
	run "mysql -e 'select user,host from mysql.user where user = \"root\";' | grep -q root";
	say "mysql rc: $?";
};

1;
