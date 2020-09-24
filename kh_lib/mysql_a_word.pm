package mysql_a_word;
use strict;
use mysql_exec;

# 基本形IDリストの取得
sub new{
	my $class = shift;
	my %args = @_;

	# 「その他」品詞対策
	#if ($args{genkei} =~ /\((.*)\)/){
	#	$args{hinshi} = $1;
	#	$args{genkei} = substr( $args{genkei}, 0, index($args{genkei},'(') );
	#	use Jcode;
	#	print Jcode->new("$args{genkei}, $args{hinshi}\n")->sjis;
	#}

	# エスケープ
	$args{genkei} =~ s/'/\\'/go;

	my $self = \%args;
	bless $self, $class;

	my $sql = "
		SELECT genkei.id
		FROM genkei, hselection #, hinshi
		WHERE
			    genkei.khhinshi_id = hselection.khhinshi_id
			and hselection.ifuse = 1
			and genkei.nouse = 0
			and genkei.name = \'$args{genkei}\'
	";
	if ($args{khhinshi}){
		$sql .= "			and hselection.name = \'$args{khhinshi}\'";
	}
	#if ($args{hinshi}){
	#	die("unknown parameter \"hinshi\"!");
	#}
	
	#print "genkei ids: ";
	my $t = mysql_exec->select($sql,1)->hundle;
	while (my $i = $t->fetch){
		#print "$i->[0],";
		push @{$self->{genkei_id_s}}, $i->[0];
	}
	#print "\n";
	return $self;
}

sub genkei_ids{
	my $self = shift;
	return $self->{genkei_id_s};
}

# 表層語IDリストを返す
sub hyoso_id_s{
	my $self = shift;
	
	unless ($self->{genkei_id_s}){
		return 0;
	}
	
	my $sql = "SELECT hyoso.id\n";
	$sql .= "FROM hyoso, genkei";
	if ($self->{katuyo}){ $sql .= ",katuyo "; }
	$sql .= "\n";
	$sql .= "WHERE\n\tgenkei.id = hyoso.genkei_id\n";
	#if ($self->{hinshi}){
	#	$sql .= "\tAND hyoso.hinshi_id = hinshi.id\n";
	#	$sql .= "\tAND hinshi.name = $self->{hinshi}\n";
	#}
	if ( length($self->{katuyo}) ){
		$sql .= "\tAND hyoso.katuyo_id = katuyo.id\n";
		$sql .= "\tAND katuyo.name = '$self->{katuyo}\'\n";
	}
	
	if ( length($self->{hyoso}) ){
		$sql .= "\tAND hyoso.name = binary '$self->{hyoso}'\n";
	}
	
	$sql .= "\tAND (\n";
	my $n = 0;
	foreach my $i (@{$self->{genkei_id_s}}){
		$sql .= "\t\t";
		if ($n > 0){ $sql .= 'OR '; }
		$sql .= "genkei.id = $i \n";
		++$n;
	}
	$sql .= "\t) ";
	
	#print "$sql\n";
	#return 0;
	
	my $t = mysql_exec->select($sql,1)->hundle;
	my @result;
	#print "hyoso ids: ";
	while (my $i = $t->fetch){
		#print "$i->[0],";
		push @result, $i->[0];
	}
	#print "\n";
	if (@result){
		#print "@result";
		#print "hyoso id ok!\n";
		return \@result;
	} else {
		return 0;
	}
}


1;