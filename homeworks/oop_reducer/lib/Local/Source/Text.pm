package Local::Source::Text;

use strict;
use warnings;

sub new {
	my ($class, %parameters) = @_;
	$parameters{text} = [split $parameters{delimiter} // "\n", $parameters{text}];
	$parameters{number} = scalar $parameters{text};
	bless \%parameters, $class;
}

sub next {
	my $self = shift;
	return undef unless $self->{number};
	return $self->{text}->[$self->{text} - --$self->{number} - 1];
}

1;
