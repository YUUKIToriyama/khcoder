package mysql_ready::df;
use strict;
use Benchmark;

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
		'h1.h1_id = hyosobun.h1_id',
);


sub calc{
	my $class = shift;
	my $self = shift;

	# 見出しが存在するかどうかをチェック
	my @avail = ();
	foreach my $tani ('bun','dan','h1','h2','h3','h4','h5'){
		if ( mysql_exec->table_exists($tani) ){
			push @avail, $tani;
			#print "t: $tani\n";
		}
	}

	# 集計の準備と実行
	my $switch = 'exec1';
	foreach my $tani (@avail){
		my $heap = '';
		if ( $::config_obj->use_heap && $self->{use_heap_act} ){
			$heap = 'TYPE=HEAP';
			print " df: heap ";
		}
		
		# 文以外の単位では中間テーブルを作成（hyosobun.idと各単位.idを直結）
		my $tain_hb = '';
		unless ($tani eq 'bun'){
			my $t0 = new Benchmark;
			$tain_hb = $tani.'_hb';
			
			my_threads->$switch("
				mysql_exec->drop_table(\"$tain_hb\");
				mysql_exec->do(\"
					CREATE TABLE $tain_hb(
						hyosobun_id INT primary key,
						tid         INT
					) $heap
				\",1);
				mysql_exec->do(\"
					INSERT INTO $tain_hb (hyosobun_id, tid)
					SELECT hyosobun.id, $tani.id
					FROM hyosobun, $tani
					WHERE
						$sql_join{$tani}
				\",1);
			");
			
			my $t1 = new Benchmark;
			#print "TMP\t",timestr(timediff($t1,$t0)),"\n";
		}
		
		# テーブル準備
		my $t0 = new Benchmark;
		my_threads->$switch("
			mysql_exec->drop_table(\"df_$tani\");
			mysql_exec->do(\"
				CREATE TABLE df_$tani(
					genkei_id INT primary key,
					f         INT
				)
			\",1);
		");

		# 集計の実行
		if ($tani eq 'bun'){  # 文単位
			my_threads->$switch("
				mysql_exec->do(\"
					INSERT INTO df_$tani (genkei_id, f)
					SELECT genkei.id, COUNT(DISTINCT $tani.id)
					FROM hyosobun, $tani, hyoso, genkei
					WHERE
						$sql_join{$tani}
						AND hyosobun.hyoso_id = hyoso.id
						AND hyoso.genkei_id = genkei.id
					GROUP BY genkei.id
				\",1);
			");
		} else {              # 文以外の単位
			my_threads->$switch("
				mysql_exec->do(\"
					INSERT INTO df_$tani (genkei_id, f)
					SELECT genkei.id, COUNT(DISTINCT tid)
					FROM hyosobun, $tain_hb, hyoso, genkei
					WHERE
						    hyosobun.id = $tain_hb.hyosobun_id
						AND hyosobun.hyoso_id = hyoso.id
						AND hyoso.genkei_id = genkei.id
					GROUP BY genkei.id
				\",1);
			");
		}

		my $t1 = new Benchmark;
		#print "Main\t",timestr(timediff($t1,$t0)),"\n";

		#print "$switch\n";		
		if ($switch eq 'exec1'){
			$switch = 'exec2';
		} else {
			$switch = 'exec1';
		}
	}
	
	my_threads->wait1;
	my_threads->wait2;
	
	# 中間テーブルをHEAPからMyISAMに変換
	$switch = 'exec1';                            # スレッド固定で順次処理
	if ($::config_obj->use_heap){
		foreach my $tani (@avail){
			if ($tani eq 'bun' ){
				next;
			}
			my $tain_hb = $tani.'_hb';
			my $heap_table = $tain_hb.'_heap';
			my_threads->$switch("
				mysql_exec->drop_table(\"$heap_table\");
				mysql_exec->do(\"ALTER TABLE $tain_hb RENAME $heap_table\",1);
				mysql_exec->do(\"
					CREATE TABLE $tain_hb(
						hyosobun_id INT primary key,
						tid         INT
					)
				\",1);
				mysql_exec->do(\"
					INSERT INTO $tain_hb (hyosobun_id, tid)
					SELECT hyosobun_id, tid
					FROM $heap_table
				\",1);
				mysql_exec->drop_table(\"$heap_table\");
			");
		}
		my_threads->wait1;                        # スレッド固定で順次処理
	}
	
	return 1;
}

sub old{
		my $tani;
		
		# テーブル作製
		mysql_exec->drop_table("df_$tani");
		mysql_exec->do("
			CREATE TABLE df_$tani(
				genkei_id INT primary key,
				f         INT
			)
		",1);
		# 集計の実行
		my $sql1 = "INSERT INTO df_$tani (genkei_id, f)\n";
		my $sql2 = "SELECT genkei.id, COUNT(DISTINCT $tani.id)\n";
		$sql2 .= "FROM hyosobun, $tani, hyoso, genkei\n";
		$sql2 .= "WHERE\n$sql_join{$tani}";
		$sql2 .= "\tAND hyosobun.hyoso_id = hyoso.id\n";
		$sql2 .= "\tAND hyoso.genkei_id = genkei.id\n";
		$sql2 .= "GROUP BY genkei.id";
}

1;