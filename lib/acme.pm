package acme;

use Rex -base;

desc "Install acmetool";
task "install", make {
	needs main "root" || die "Cannot gain root access";

	pkg "dev-lang/go", ensure => "present";
	pkg "dev-vcs/git", ensure => "present";
	if (not get_uid "acme") {
		create_user "acme",
			create_home => TRUE,
			ensure => "present";
	}

	run "go get github.com/hlandau/acme/cmd/acmetool",
		creates => "/home/acme/.local/go/bin/acmetool",
		env => {
			GOPATH => "/home/acme/.local/go",
		},
		user => "acme";
};

1;
