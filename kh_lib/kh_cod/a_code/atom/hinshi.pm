# 抽出語を使った指定　（品詞と活用形の指定に対応）

package kh_cod::a_code::atom::hinshi;
use base qw(kh_cod::a_code::atom);
use strict;

use mysql_a_word;
use mysql_exec;
use POSIX qw(log10);

#-----------------#
#   SQL文の準備   #
#-----------------#

my %sql_join = (
	'bun' =>
		'bun.id = hyosobun.bun_idt',
	'dan' =>
		'
			    dan.dan_id = hyosobun.dan_id
			AND dan.h5_id = hyosobun.h5_id
			AND dan.h4_id = hyosobun.h4_id
			AND dan.h3_id = hyosobun.h3_id
			AND dan.h2_id = hyosobun.h2_id
			AND dan.h1_id = hyosobun.h1_id
		',
	'h5' =>
		'
			    h5.h5_id = hyosobun.h5_id
			AND h5.h4_id = hyosobun.h4_id
			AND h5.h3_id = hyosobun.h3_id
			AND h5.h2_id = hyosobun.h2_id
			AND h5.h1_id = hyosobun.h1_id
		',
	'h4' =>
		'
			    h4.h4_id = hyosobun.h4_id
			AND h4.h3_id = hyosobun.h3_id
			AND h4.h2_id = hyosobun.h2_id
			AND h4.h1_id = hyosobun.h1_id
		',
	'h3' =>
		'
			    h3.h3_id = hyosobun.h3_id
			AND h3.h2_id = hyosobun.h2_id
			AND h3.h1_id = hyosobun.h1_id
		',
	'h2' =>
		'
			    h2.h2_id = hyosobun.h2_id
			AND h2.h1_id = hyosobun.h1_id
		',
	'h1' =>
		'h1.h1_id = hyosobun.h1_id'
);
my %sql_group = (
	'bun' =>
		'hyosobun.bun_idt',
	'dan' =>
		'hyosobun.dan_id, hyosobun.h5_id, hyosobun.h4_id, hyosobun.h3_id, hyosobun.h2_id, hyosobun.h1_id',
	'h5' =>
		'hyosobun.h5_id, hyosobun.h4_id, hyosobun.h3_id, hyosobun.h2_id, hyosobun.h1_id',
	'h4' =>
		'hyosobun.h4_id, hyosobun.h3_id, hyosobun.h2_id, hyosobun.h1_id',
	'h3' =>
		'hyosobun.h3_id, hyosobun.h2_id, hyosobun.h1_id',
	'h2' =>
		'hyosobun.h2_id, hyosobun.h1_id',
	'h1' =>
		'hyosobun.h1_id'
);

my $dn;

#--------------------#
#   WHERE節用SQL文   #
#--------------------#

sub expr{
	my $self = shift;
	my $t = $self->tables;
	unless ($t){ return '0';}
	
	$t = $t->[0];
	my $col = (split /\_/, $t)[2].(split /\_/, $t)[3];
	my $sql = "IFNULL(".$self->parent_table.".$col,0)";
	return $sql;
}

sub idf{
	my $self = shift;
	return 0 unless $self->tables;
	
	# 全文書数の取得・保持
	unless (
		($dn->{$self->{tani}}) && ($dn->{check} eq $::project_obj->file_target)
	){
		$dn->{$self->{tani}} = mysql_exec->select(
			"SELECT COUNT(*) FROM $self->{tani}",1
		)->hundle->fetch->[0];
		$dn->{check} = $::project_obj->file_target;
	}
	
	# 計算
	my $df;
	$df = mysql_exec->select(
		"SELECT COUNT(*) FROM $self->{tables}[0]",1
	)->hundle->fetch->[0];
	return 0 unless $df;
	
	return log10($dn->{$self->{tani}} / $df);
}

#---------------------------------------#
#   コーディング準備（tmp table作成）   #
#---------------------------------------#

sub ready{
	my $self = shift;
	my $tani = shift;
	$self->{tani} = $tani;
	
	# 表層語リスト作成
	my $list;
	if ($self->raw =~ /^(.+)\-\->(.+)\->(.+)$/o) {   # 品詞＆活用 指定
		#print Jcode->new("g: $1, h: $2, k: $3\n")->sjis;
		
		$list = mysql_a_word->new(
			genkei => $1,
			khhinshi => $2,
			katuyo => $3
		)->hyoso_id_s;
	}
	elsif ($self->raw =~ /^(.+)\-\->(.+)\=>(.+)$/o) {   # 品詞＆表層 指定
		#print Jcode->new("g: $1, h: $2, hs: $3\n")->sjis;
		$list = mysql_a_word->new(
			genkei => $1,
			khhinshi => $2,
			hyoso => $3
		)->hyoso_id_s;
	}
	elsif ($self->raw =~ /^(.+)\-\->(.+)$/o) {      # 品詞指定
		#print Jcode->new("g: $1, h: $2\n")->sjis;
		$list = mysql_a_word->new(
			genkei => $1,
			khhinshi => $2,
		)->hyoso_id_s;
	}
	elsif ($self->raw =~ /^(.+)\->(.+)$/o) {       # 活用指定
		#print Jcode->new("g: $1, k: $2\n")->sjis;
		$list = mysql_a_word->new(
			genkei => $1,
			katuyo => $2
		)->hyoso_id_s;
	}
	elsif ($self->raw =~ /^(.+)=>(.+)$/o) {       # 表層指定
		#print Jcode->new("g: $1, k: $2\n")->sjis;
		$list = mysql_a_word->new(
			genkei => $1,
			hyoso => $2
		)->hyoso_id_s;
	}
	else {
		print "atom::hinshi, something wrong?\n";
	}
	
	$self->{hyosos} = $list;
	
	unless ( $list ){
		print 
			"atom::hinshi, could not find : \"".$self->raw."\"\n";
		return '';
	}
	
	# テーブル名決定とキャッシュのチェック
	my $debug = 0;
	my @c_c = kh_cod::a_code->cache_check(
		tani => $tani,
		kind => 'hinshi',
		name => $self->raw
	);
	my $table = 'ct_'."$tani"."_hinshi_$c_c[1]";
	$self->{tables} = ["$table"];
	
	print "cache: $table" if $debug;
	if ($c_c[0]){
		print " hit\n" if $debug;
		return $self;
	} else {
		print "\n" if $debug;
	}
	
	# テーブル作成
	mysql_exec->do("
		CREATE TABLE $table (
			id INT primary key not null,
			num INT
		)
	",1);
	my $sql;
	$sql = "
		INSERT
		INTO $table (id, num)
		SELECT $tani.id, count(*)
		FROM $tani, hyosobun
		WHERE
			$sql_join{$tani} AND (
	";
	my $n = 0;
	foreach my $i (@{$list}){
		if ($n){$sql .= " OR ";}
		$sql .= "hyoso_id = $i\n";
		++$n;
	}
	$sql .= ")\n";
	$sql .= "GROUP BY $sql_group{$tani}";

	mysql_exec->do($sql,1);
	return $self;
}

#-------------------------------#
#   利用するtmp tableのリスト   #

sub tables{
	my $self = shift;
	return $self->{tables};
}

#----------------#
#   親テーブル   #
sub parent_table{
	my $self = shift;
	my $new  = shift;
	
	if (length($new)){
		$self->{parent_table} = $new;
	}
	return $self->{parent_table};
}

sub hyosos{
	my $self = shift;
	return $self->{hyosos};
}

sub pattern{
	return '.+\->.+|.+=>.+';
}
sub name{
	return 'hinshi';
}


1;
