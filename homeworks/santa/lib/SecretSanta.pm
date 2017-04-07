package SecretSanta;

use 5.010;
use strict;
use warnings;
use DDP;

sub calculate {
	my @members;
	my @res;
	my %couples;
	foreach my $member (@_) {
		if (ref $member) {
			push @members, $couples{$member->[1]} = $member->[0];
			push @members, $couples{$member->[0]} = $member->[1];
		}
		else {
			push @members, $member;
		}	
	}
	foreach my $person (@members) {
		my $candidate = $members[int(rand(@members))];
		redo if ((exists $couples{$person}) && ($couples{$person} eq $candidate) || ($person eq $candidate));
		push @res, [$person, $candidate];
	}
	return @res;
}

1;
