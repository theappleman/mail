package dotd;

use Rex -base;

require Exporter;

our @EXPORT = qw|dotd|;

task "dotd", make {
	my $params = shift;
	my $root = $params->{root} || 0;
	my $conf = $params->{conf} || die 'Required parameter: conf';
	my $line = $params->{line} || die 'Required parameter: line';

	if (!is_file($conf)) {
		file $conf,
			ensure => "directory";
		$conf .= "/zz-rex";
		file $conf,
			ensure => "present";
	}
	append_if_no_such_line $conf, $line;
}, { dont_register => TRUE };

1;
