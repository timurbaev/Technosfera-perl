package Local::Source::FileHandle;

use strict;
use warnings;

sub new {
	my ($class, %parameters) = @_;
	bless \%parameters, $class;
}

sub next {
	my $self = shift;
	my ($fh, $str) = ($self->{fh});
	chomp $str and return $str if defined ($str = <$fh>) or return undef;
}

1;
