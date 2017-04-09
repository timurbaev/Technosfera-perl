package Anagram;

use 5.010;
use strict;
use warnings;
use Encode;
=encoding UTF8

=head1 SYNOPSIS

Поиск анаграмм

=head1 anagram($arrayref)

Функцию поиска всех множеств анаграмм по словарю.

Входные данные для функции: ссылка на массив - каждый элемент которого - слово на русском языке в кодировке utf8

Выходные данные: Ссылка на хеш множеств анаграмм.

Ключ - первое встретившееся в словаре слово из множества
Значение - ссылка на массив, каждый элемент которого слово из множества, в том порядке в котором оно встретилось в словаре в первый раз.

Множества из одного элемента не должны попасть в результат.

Все слова должны быть приведены к нижнему регистру.
В результирующем множестве каждое слово должно встречаться только один раз.
Например

anagram(['пятак', 'ЛиСток', 'пятка', 'стул', 'ПяТаК', 'слиток', 'тяпка', 'столик', 'слиток'])

должен вернуть ссылку на хеш


{
    'пятак'  => ['пятак', 'пятка', 'тяпка'],
    'листок' => ['листок', 'слиток', 'столик'],
}

=cut

sub anagram {
    my $words_list = shift;
    my %result;
    	foreach my $word (@$words_list) {
		my $word = lc (decode('utf-8', $word));
		my $sorted = join ('', sort split ('', $word));
		my @words;
		@words = @{$result{$sorted}} if (exists $result{$sorted});
		push @words, $word;
		$result{$sorted} = \@words;
	}
	foreach my $key (keys %result) {
		my @words = @{$result{$key}};
		delete $result{$key};
		$key = encode ('utf-8', $words[0]);
		my %hash;
		@words = sort (grep{!$hash{$_}++} @words);
		foreach my $value (@words) {
			$value = encode ('utf-8', $value);
		}
		$result{$key} = \@words if ($key && (@words > 1));
	}
    return \%result;
}

1;
