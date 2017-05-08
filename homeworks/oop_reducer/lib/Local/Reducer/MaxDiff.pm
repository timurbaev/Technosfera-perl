package Local::Reducer::MaxDiff;

use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

sub new {
	my ($class, %parameters) = @_;
	bless \%parameters, $class;
}

sub reduce_n {
	my ($self, $n) = @_;
	my ($bottom, $reduced, $row_class, $source, $top) = @{$self}{qw(bottom reduced row_class source top)};
	$reduced //= 0;
	while ($n--) {
		my $row = $row_class->new(str => $source->next);
		my ($rtop, $rbottom) = ($row->{$top}, $row->{$bottom});		
		if (looks_like_number $rtop and looks_like_number $rbottom) {
			$reduced = $rtop - $rbottom if ($rtop - $rbottom > $reduced);
		}
	}
	$self->{reduced} = $reduced;
}

sub reduce_all {
	my $self = shift;
	my ($bottom, $reduced, $row_class, $source, $top) = @{$self}{qw(bottom reduced row_class source top)};
	$reduced //= 0;
	while (my $string = $source->next) {
		my $row = $row_class->new(str => $string);
		my ($rtop, $rbottom) = ($row->{$top}, $row->{$bottom});		
		if (looks_like_number $rtop and looks_like_number $rbottom) {
			$reduced = $rtop - $rbottom if ($rtop - $rbottom > $reduced);
		}
	}
	$self->{reduced} = $reduced;
}

sub reduced {
	shift->{reduced};
}

1;
