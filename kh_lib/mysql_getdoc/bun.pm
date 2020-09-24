package mysql_getdoc::bun;
use base qw(mysql_getdoc);
use strict;

sub if_next{
	my $self = shift;
	my $max = mysql_exec->select("
		SELECT max(bun_idt)
		FROM hyosobun
	",1)->hundle->fetch->[0];
	if ($self->{doc_id} < $max){
		return 1;
	} else {
		return 0;
	}
}

sub get_doc_id{
	my $self = shift;
	return mysql_exec->select("
		SELECT bun_idt
		FROM hyosobun
		WHERE
			hyosobun.id = $self->{hyosobun_id}
	",1)->hundle->fetch->[0];
}

sub get_body{
	my $self = shift;
	return mysql_exec->select("
		SELECT hyoso.name, hyoso.id
		FROM hyoso, hyosobun
		WHERE
			hyosobun.bun_idt = $self->{doc_id}
			AND hyosobun.hyoso_id = hyoso.id
		ORDER BY hyosobun.id
	",1)->hundle->fetchall_arrayref;
}

sub get_header{
	my $self = shift;
	my $headers;
	
	my $id_info = mysql_exec->select("
		SELECT bun_idt, h1_id, h2_id, h3_id, h4_id, h5_id, dan_id, bun_id
		FROM hyosobun
		WHERE
			bun_idt = $self->{doc_id}
		LIMIT 1
	",1)->hundle->fetch;
	
	my $current = 6;
	if ($id_info->[6] == 0 && $id_info->[7] == 0){
		for (my $n = 5; $n > 0; --$n){
			if ($id_info->[$n]){
				$current = $n;
				last;
			}
		}
	}
	my @possible;
	for (my $n = 1; $n < $current; ++$n){
		push @possible, "h$n";
	}
	
	foreach my $i (@possible){
		if (                                      # タグがあるかチェック
			mysql_exec->select(
				"select status from status where name = \'$i\'",1
			)->hundle->fetch->[0]
		){
			my $sql = "SELECT rowtxt\n";
			$sql   .= "FROM bun_r, bun_bak\n";
			$sql   .= "WHERE\n";
			$sql   .= "    bun_bak.id = bun_r.id\n";
			$sql   .= "    AND bun_id = 0\n";
			$sql   .= "    AND dan_id = 0\n";
			my $frag = 0; my $n = 5;
			foreach my $h ('h5','h4','h3','h2','h1'){
				if ($i eq $h){$frag = 1}
				if ($frag){
					$sql .= "    AND $h"."_id = $id_info->[$n]\n";
				} else {
					$sql .= "    AND $h"."_id = 0\n";
				}
				--$n;
			}
			$sql   .= "LIMIT 1";
			my $h = mysql_exec->select("$sql",1)->hundle->fetch;
			if ($h){
				$h = $h->[0];
				$headers .= "$h\n";
			}
		}
	}
	
	return $headers;
}



1;
