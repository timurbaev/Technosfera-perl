#!/usr/bin/perl

use strict;
use warnings;
our $VERSION = 1.0;


my $filepath = $ARGV[0];
die "USAGE:\n$0 <log-file>\n"  unless $filepath;
die "File '$filepath' not found\n" unless -f $filepath;

my $parsed_data = parse_file($filepath);
report($parsed_data);
exit;

sub parse_file {
    my $file = shift;
    my $fd;
    if ($file =~ /\.bz2$/) {
        open $fd, "-|", "bunzip2 < $file" or die "Can't open '$file' via bunzip2: $!";
    } else {
        open $fd, "<", $file or die "Can't open '$file': $!";
    }
    my $result;
    while (my $log_line = <$fd>) {
		$log_line =~ qr/^(?<IP>(\d+\.){3}\d+)\s\[(?<TimeStamp>[^:]+(:\d\d){2})[^\]]+\]\s"(?<Request>[^"]+)"\s(?<Status>\d+)\s(?<Amount>\d+)\s"(?<Refferer>[^"]+)"\s"(?<UA>[^"]+)"\s"(?<Compression>[\d\.-]+)"$/x or next;
		my $Status = $+{Status};
		my $Amount = $+{Amount};
		for my $IP ($+{IP}, 'total') {
			$result->{$IP}{IP} = $IP;
			$result->{$IP}{mins}{$+{TimeStamp}} = 1;
			$result->{$IP}{$Status} += $Amount;
			$result->{$IP}{data} += int ($Amount * ($+{Compression} eq '-' ? 1.0 : $+{Compression})) if $Status eq '200';
			$result->{$IP}->{count}++;
		}
    }
    close $fd;
	for my $row (values %$result) {
		$row->{'mins'} = keys %{$row->{'mins'}};
	}
    return $result;
}

sub report {
    my $result = shift;
	my $total = delete $result->{'total'};
	my @table = sort {$b->{'count'} <=> $a->{'count'}} values %$result;
	my @status = sort grep {$_ =~ m/\d+/} keys %{$total};
	return unless @table;
	my @headers = ('IP', 'count', 'avg', 'data', @status);
	print join ("\t", @headers) . "\n";
	@table = @table[0..9] if @table > 10;
	foreach my $row ($total, @table) {
		$row->{$_} //= 0 and $row->{$_} = int ($row->{$_} / 1024) foreach ('data', @status);
		$row->{'avg'} = sprintf("%.2f", $row->{'count'} / $row->{'mins'});
		print join("\t", map {$row->{$_}} @headers) . "\n";
	}
}
