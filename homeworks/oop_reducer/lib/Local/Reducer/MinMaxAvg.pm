package Local::Reducer::MinMaxAvg;

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
	$reduced //= Reduced->new;
	while ($n--) {
		my $row = $row_class->new(str => $source->next);
		$reduced->set ($row->{$field}) if looks_like_number $row->{$field};
	}
	$self->{reduced} = $reduced;
}

sub reduce_all {
	my $self = shift;
	my ($field, $reduced, $row_class, $source) = @{$self}{qw(field reduced row_class source)};
	$reduced //= Reduced->new;
	while (my $string = $source->next) {
		my $row = $row_class->new(str => $string); 
		$reduced->set ($row->{$field}) if looks_like_number $row->{$field};
	}
	$self->{reduced} = $reduced;
}

sub reduced {
	shift->{reduced};
}

{
	package Reduced;
	sub new {
		my ($class, %parameters) = @_;
		bless {max => undef, min => undef, sum => 0, count => 0}, $class;
	}
	sub get_max {
		shift->{max};
	}
	sub get_min {
		shift->{min};
	}
	sub get_avg {
		my $self = shift;
		return $self->{sum} / $self->{count} unless $self->{count} == 0;
	}
	sub set {
		my ($self, $element) = @_;
		$self->{max} //= $element;
		$self->{max} = $element if $self->{max} < $element;
		$self->{min} //= $element;
		$self->{min} = $element if $self->{min} > $element;
		$self->{sum} += $element;
		$self->{count}++;
	}
}

1;
