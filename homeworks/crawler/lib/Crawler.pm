package Crawler;

use 5.010;
use strict;
use warnings;

use AnyEvent::HTTP;
use Web::Query;
use URI;
use HTML::LinkExtor;
$AnyEvent::HTTP::MAX_PER_HOST = 100;
=encoding UTF8

=head1 NAME

Crawler

=head1 SYNOPSIS

Web Crawler

=head1 run($start_page, $parallel_factor)

Сбор с сайта всех ссылок на уникальные страницы

Входные данные:

$start_page - Ссылка с которой надо начать обход сайта

$parallel_factor - Значение фактора паралельности

Выходные данные:

$total_size - суммарный размер собранных ссылок в байтах

@top10_list - top-10 страниц отсортированный по размеру.

=cut

sub run {
	my ($start_page, $parallel_factor) = @_;
	$start_page or die "You must setup url parameter";
	$parallel_factor or die "You must setup parallel factor > 0";
	my $required = 1000;
	my %visited;
	my @urls = ($start_page);
	my $threads = 0;
	my $cv = AnyEvent->condvar;
	$cv->begin;
	my $next;
	$next = sub {
		$threads++;
		unless ((keys(%visited) < $required) && (@urls)) {
			$cv->send;
			return;
		}
		my $link = shift @urls;
		$cv->begin;
		http_head
		$link,
		sub {
			my ($body, $header) = @_;
			if ($header->{"content-type"} =~ "text/html") {	
				$cv->begin;
				http_get
				$link,
				sub {
					$body = shift;
					$visited{$link} = length $body;
					foreach my $link (HTML::LinkExtor->new(undef, $link)->parse($body)->links()) {
						next if (ref $$link[2] eq "URI::_foreign");
						my $s = $$link[2]->as_iri;
						$s = $1 if ($s =~ "(.+)#.*");
						push @urls, $s if ($s =~ "^$start_page" && !($visited{$s}));
					}
					my $min = @urls < $parallel_factor ? @urls : $parallel_factor;
					$next->() while ($threads <= $min);
					$threads--;
					$cv->end;
					return;
				};
			}
			$cv->end;
		};

	};
	$next->();
	$cv->end;
	$cv->recv;
	my $total_size = 0;	
	for my $name (sort {$visited{$a} <=> $visited{$b}} keys %visited) {   
		if (keys %visited > $required) {
			delete $visited{$name};
		}
		else {
			$total_size += $visited{$name};
		}
	}
	my @top10_list = (sort {$visited{$b} <=> $visited{$a}} keys %visited)[0..9];
	return $total_size, @top10_list;
}

1;
