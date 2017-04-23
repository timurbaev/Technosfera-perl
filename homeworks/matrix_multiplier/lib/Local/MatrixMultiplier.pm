package Local::MatrixMultiplier;

use strict;
use warnings;

sub mult {
	my ($mat_a, $mat_b, $max_child) = @_;
	my $res = [];
	my ($x, $y) = (size ($mat_a), size ($mat_b));
	die "Bad matrices\n" if (($x * $y == 0) || ($x != $y));
	$y = $x * $x;
	$max_child = $y if ($y < $max_child);
	my ($m, $n, $r, $w, @reads) = ($y % $max_child, int($y / $max_child));
	for my $i (0..$max_child - 1) {
		pipe ($r, $w);
		if (my $pid = fork) {
			close $w;
			$r->blocking(1);
			push @reads, $r;
		}
		else {
			die "Failed to fork..\n" unless defined $pid;
			close $r;
			if ($i == 0) {
				$n += $m;
				$m = 0;
			}
			foreach my $j ($n * $i + $m..$n * ($i + 1)+ $m - 1) {
				my $ret = 0;
				for $i (0..$x - 1) {
					$ret += (@$mat_a)[int($j / $x)][$i] * (@$mat_b)[$i][int($j % $x)];
				}
				push @$res, $ret;
			}
			foreach my $ret (@$res) {
				print $w "$ret\n";
			}		
			close $w;
			exit 0;
		}
	}
	my $i = 0;
	my $temp = [];
	for my $r (@reads) {
		while (<$r>) {
			chomp $_;
			if ($i == $x) {
				push @$res, $temp;
				$temp = [];
				$i = 0;
			}
			push @$temp, int($_);
			$i++;
		}
		close $r;
	}
	push @$res, $temp;
	return $res;
}

sub size {
	my $m = pop;
	my %hash;
	map {$hash{@$_} = 1} @$m;
	my $width = (keys %hash)[0] if (keys %hash == 1);
	return 0 unless (($width) && ($width == @$m));
	return $width;
}

1;
