package myconst;

use strict;
use warnings;
use Scalar::Util 'looks_like_number';

=encoding utf8

=head1 NAME

myconst - pragma to create exportable and groupped constants

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS
package aaa;

use myconst math => {
        PI => 3.14,
        E => 2.7,
    },
    ZERO => 0,
    EMPTY_STRING => '';

package bbb;

use aaa qw/:math PI ZERO/;

print ZERO;             # 0
print PI;               # 3.14
=cut

sub import {
	my ($caller) = (caller, shift);
	map {die unless defined} @_;
	my %hash = @_ unless @_ % 2 and die;
	my @import;
	while (my ($key, $value) = each %hash){
		die if ref $key eq "ARRAY" or ref $key eq "HASH" or not defined $key or looks_like_number ($key) or not $key =~ /^\w+$/ or ref $value eq "ARRAY";
		map {die if ref $value->{$_} eq "ARRAY" or ref $value->{$_} eq "HASH" or looks_like_number($_) or not $_=~ /^\w+$/} keys %{$value} if (ref $value eq "HASH");
		if (ref $value eq "") {
			push @import, {name => $key, value => $value, group => "all"};
		} elsif (ref $value eq "HASH") {
			push @import, {name => $_, value => $value->{$_}, group => $key} foreach (keys %{$value});
		} else {
			die 'Bad input';
		}
	}
	no strict "refs";
	no warnings;
	map {my $import = $_; *{"$caller::$import->{name}"} = sub(){$import->{value}};} @import;
	*{$caller."::import"} = sub (){
		my ($caller) = (caller, shift);
		foreach my $string (@_){
			if($string =~ /^:all/){
				map {my $import = $_; *{"$caller::$import->{name}"} = sub(){$import->{value}}} @import;
			}elsif($string =~ /^:/){
				map{my $import = $_; *{"$caller::$import->{name}"} = sub(){$import->{value}}} (grep {$string eq ":$_->{group}"} @import);
			}else{
				map{my $import = $_; *{"$caller::$string"} = sub(){$import->{value}} if ($string eq $import->{name})} @import;
			}
		}
	};
}

1;
