package Local::Reducer::Sum;

use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

sub new {
	my ($class, %parameters) = @_;
	bless \%parameters, $class;
}

sub reduce_n {
	my ($self, $n) = @_;
	my ($field, $reduced, $row_class, $source) = @{$self}{qw(field reduced row_class source)};
	while ($n--) {
		my $row = $row_class->new(str => $source->next);
		$reduced += $row->{$field} if looks_like_number $row->{$field};
	}
	$self->{reduced} = $reduced;
}

sub reduce_all {
	my $self = shift;
	my ($field, $reduced, $row_class, $source) = @{$self}{qw(field reduced row_class source)};
	while (my $string = $source->next) {
		my $row = $row_class->new(str => $string);
		$reduced += $row->{$field} if looks_like_number $row->{$field};
	}
	$self->{reduced} = $reduced;
}

sub reduced {
	shift->{reduced};
}

1;
