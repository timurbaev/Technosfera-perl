package Local::Source::Array;

use strict;
use warnings;

sub new {
	my ($class, %parameters) = @_;
	$parameters{number} = scalar @{$parameters{array}};
	bless \%parameters, $class;
}

sub next {
	my $self = shift;
	return undef unless $self->{number};
	return $self->{array}->[@{$self->{array}} - --$self->{number} - 1];
}

1;
