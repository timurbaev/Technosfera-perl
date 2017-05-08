package Local::Row::Simple;

use strict;
use warnings;

sub new {
	my ($class, %parameters) = @_;
	my %hash;
	foreach (split ",", $parameters{str}) {
		my @arr = split ":";
		return undef unless @arr == 2;
		$hash{$arr[0]} = $arr[1];
	}
	bless \%hash, $class;
}

1;
