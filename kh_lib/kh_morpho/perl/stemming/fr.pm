package kh_morpho::perl::stemming::fr;
use strict;
use base qw( kh_morpho::perl::stemming );

sub init{
	my $self = shift;
	
	$self->{splitter} = Lingua::Sentence->new('fr');
	$self->{stemmer}  = Lingua::Stem::Snowball->new(
		lang     => 'fr',
		encoding => 'UTF-8'
	);
	
	return $self;
}

sub tokenize{
	my $self = shift;
	my $t    = shift;

	# 文末処理
	$t =~ s/(.+)(["|''|']{0,1}[\.|\!+|\?+|\!+\?|\?+\!+]["|''|']{0,1})\s*$/$1 $2/go;

	# コンマ
	$t =~ s/(\S),(\s|\Z)/$1 ,$2/go;

	# ダブルクォートやカッコ類
	$t =~ s/(''|``|"|\(|\)|\[|\]|\{|\})(\S)/$1 $2/go;
	$t =~ s/(\S)(''|``|"|\(|\)|\[|\]|\{|\})/$1 $2/go;

	# シングルクォート
	$t =~ s/(\S)'(\s|\Z)/$1 '$2/go;
	$t =~ s/(\s|^)'(\S)/\$' $2/go;

	# フランス語特有 「l'語」「s'語」「c'語」「d'語」
	$t =~ s/(\s|^)([l|s|c|d]')(\S)/$1$2 $3/gio;

	# 重複しているスペースを削除
	$t =~ s/  */ /go;

	my @words_hyoso = split / /, $t;

	return(\@words_hyoso, undef);
}


1;
