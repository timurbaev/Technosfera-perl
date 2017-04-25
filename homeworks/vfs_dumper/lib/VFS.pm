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
		case 'D' {
			my $func;
			$func = sub {
				my @sublist;
				while ((my $action, $buf) = unpack "A A*", $buf) {
					switch ($action) {
						case 'D' {
							(my $high, my $low, $buf) = unpack("C2 A*", $buf);
							my $len = $high * 256 + $low;
							(my $directory, $high, $low, $buf) = unpack("A$len C2 A*", $buf);
							push @sublist, {type => "directory", name => decode('utf-8', $directory), mode => mode2s($high * 256 + $low)};	
						}
						case 'F' {
							(my $high, my $low, $buf) = unpack("C2 A*", $buf);
							my $len = $high * 256 + $low;
							(my $file, $high, $low, my $high1, my $high2, my $low1, my $low2, my $hash, $buf) = unpack("A$len C2 C4 A20 A*", $buf);
							push @sublist, {type => "file", size => $high1 * 16777216 + $high2 * 65536 + $low1 * 256 + $low2, name => decode('utf-8', $file), mode => mode2s ($high * 256 + $low), hash => unpack "H*", $hash};
						}
						$sublist[-1]->{list} = $func->() case 'I';
						return [@sublist] case 'U';
						case 'Z' {
							die "Garbage ae the end of the buffer" if $buf;
							return @sublist;
						}
					}
				}
			};
			return $func->();
		}
		die "The blob should start from 'D' or 'Z'";
	}
}

1;
