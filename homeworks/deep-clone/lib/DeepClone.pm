package DeepClone;

use 5.010;
use strict;
use warnings;

=encoding UTF8

=head1 SYNOPSIS

Клонирование сложных структур данных

=head1 clone($orig)

Функция принимает на вход ссылку на какую либо структуру данных и отдаюет, в качестве результата, ее точную независимую копию.
Это значит, что ни один элемент результирующей структуры, не может ссылаться на элементы исходной, но при этом она должна в точности повторять ее схему.

Входные данные:
* undef
* строка
* число
* ссылка на массив
* ссылка на хеш
Элементами ссылок на массив и хеш, могут быть любые из указанных выше конструкций.
Любые отличные от указанных типы данных -- недопустимы. В этом случае результатом клонирования должен быть undef.

Выходные данные:
* undef
* строка
* число
* ссылка на массив
* ссылка на хеш
Элементами ссылок на массив или хеш, не могут быть ссылки на массивы и хеши исходной структуры данных.

=cut

sub clone {
	my %cloned;
	my $bad;
	my $copy;
	$copy = sub {
		my $orig = shift;
		return $cloned{$orig} if ((defined $orig) && (exists $cloned{$orig}));		
		if (ref $orig eq 'ARRAY') {
			my @array = @$orig;
			$cloned{$orig} = \@array;
			foreach my $key (@array) {
				$key = $copy->($key);
			}
			return \@array;
		}
		elsif (ref $orig eq 'HASH') {
			my %hash = %$orig;
			$cloned{$orig} = \%hash;
			for my $value (values %hash) {
				$value = $copy->($value);
			}
			return \%hash;
		}
		elsif (ref $orig eq '') {
			return $orig;
		}
		else {
			return $bad = 1;
		}
	};
	$copy = $copy->(shift);
	$copy = undef if $bad;
	return $copy;
}

1;
