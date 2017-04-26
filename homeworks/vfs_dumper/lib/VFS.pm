package VFS;
use utf8;
use strict;
use warnings;
use 5.010;
use File::Basename;
use File::Spec::Functions qw{catdir};
use JSON::XS;
no warnings 'experimental::smartmatch';
use Switch;
use Encode;

sub mode2s {
	my $flags = shift;
	my @m1 = ('other', undef, 'group', undef, 'user', undef);
	for my $i (0..2) {
		my @rwx = ('execute', undef, 'write', undef, 'read', undef);
		for my $j (0..2) {
			@rwx[2 * $j + 1] = $flags & (2 ** (3 * $i + $j)) ? JSON::XS::true : JSON::XS::false;	
		}
		@m1[2 * $i + 1] = {@rwx};
	}
	return {@m1};
}

sub parse {
	my $buf = shift;
	switch (unpack "A", $buf) {
		case 'Z' {return {};}
		case 'D' {return func (\$buf);}
		die "The blob should start from 'D' or 'Z'";
	}
}
sub func {
	my $buf = shift;
	my @sublist;
	while ((my $action, $$buf) = unpack "A A*", $$buf) {
		switch ($action) {
			case 'D' {
				(my $directory, my $flags, $$buf) = unpack "n/A* n A*", $$buf;
				push @sublist, {type => "directory", name => decode('utf-8', $directory), mode => mode2s($flags)};	
			}
			case 'F' {
				(my $file, my $flags, my $len, my $hash, $$buf) = unpack "n/A* n N A20 A*", $$buf;
				push @sublist, {type => "file", size => $len, name => decode('utf-8', $file), mode => mode2s ($flags), hash => unpack "H*", $hash};
			}
			$sublist[-1]->{list} = func($buf) case 'I';
			return [@sublist] case 'U';
			case 'Z' {
				die "Garbage ae the end of the buffer" if $$buf;
				return @sublist;
			}
		}
	}
}

1;
