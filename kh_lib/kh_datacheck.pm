package kh_datacheck;
use strict;
use kh_msg;

my $euc_code = '';
if (eval 'require Encode::EUCJPMS'){
	$euc_code = 'eucJP-ms';
} else {
	$euc_code = 'euc-jp';
}

my %errors = (
	'error_m1'  => kh_msg->get('error_m1'),#'長すぎる見出し行があります（自動修正不可）',
	'error_c1'  => kh_msg->get('error_c1'),#'文字化けを含む行があります',
	'error_c2'  => kh_msg->get('error_c2'),#'望ましくない半角記号が含まれている行があります',
	'error_n1a' => kh_msg->get('error_n1a'),#'長すぎる行があります',
	'error_n1b' => kh_msg->get('error_n1b'),#'長すぎる上に、スペース・句点等が適当な位置に含まれていない行があります（自動修正不可）',
	'error_mn' => kh_msg->get('error_mn'),#'H1〜H5タグを使った見出し作成に失敗している可能性があります（自動修正不可）',
);

sub run{
	my $class = shift;
	my $self;
	$self->{file_source} = $::config_obj->os_path( $::project_obj->file_target );
	$self->{file_temp}   = 'temp.txt';
	while (-e $self->{file_temp}){
		$self->{file_temp} .= '.tmp';
	}
	bless $self, $class;

	# 文字コードのチェック
	my $icode = kh_jchar->check_code($self->{file_source});
	unless (
		   $icode eq 'sjis'
		|| $icode eq 'euc'
		|| $icode eq 'jis'
		|| $icode eq 'utf8'
	) {
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('error_charcode')#"分析対象ファイルの文字コード判別に失敗しました。\nプロジェクト編集画面で文字コードを指定して下さい。\nプロジェクト編集画面を開くには、メニューから「プロジェクト」→「開く」→「編集」をクリックします。"
		);
		return 0;
	}

	# 改行コードの統一
	my $file_lines = $::project_obj->file_TempTXT;
	my $line_count1 = 0;
	open (SOURCE,"$self->{file_source}") or
		gui_errormsg->open(
			type => 'file',
			thefile => $self->{file_source}
		);
	open (LINES, '>', $file_lines) or
		gui_errormsg->open(
			type => 'file',
			thefile => $file_lines
		);
	while (<SOURCE>) {
		s/[\x0D\x0A]+/\n/go;
		print LINES $_;
		++$line_count1;
	}
	close (SOURCE);
	close (LINES);
	
	# 内容チェックの実行
	open (SOURCE,$file_lines) or
		gui_errormsg->open(
			type => 'file',
			thefile => $self->{file_source}
		);
	open (EDITED,">$self->{file_temp}") or 
		gui_errormsg->open(
			type => 'file',
			thefile => $self->{file_temp}
		);
	binmode(SOURCE);

	my $n = 1;
	while (<SOURCE>){
		s/\x0D\x0A|\x0D|\x0A/\n/g;
		chomp;
		
		my $ci = Jcode->new($_,$icode)->euc;
		
		my $co = '';
		my ($t_c1, $t_c2, $t_n1a, $t_n1b);
		
		# 見出し行
		if ($ci =~ /^<(H)([1-5])>(.*)<\/H\2>$/i){
			if (length($ci) > 8000){
				$self->{error_m1}{flag} = 1;
				push @{$self->{error_m1}{array}}, [$n, $ci];
			}
			( $co, $t_c1, $t_c2, $t_n1a, $t_n1b ) = &my_cleaner::exec($3);
			$co = "<$1$2>$co</$1$2>";
		}
		# 通常の行
		else {
			( $co, $t_c1, $t_c2, $t_n1a, $t_n1b ) = &my_cleaner::exec($ci);
			if ($t_n1a and not $t_n1b){
				$self->{error_n1a}{flag} = 1;
				push @{$self->{error_n1a}{array}}, [$n, $ci];
			}
			if ($t_n1b){
				$self->{error_n1b}{flag} = 1;
				push @{$self->{error_n1b}{array}}, [$n, $ci];
			}
			if ($ci =~ /<H[1-5]>.+|.+<\/H[1-5]>/i){
				$self->{error_mn}{flag} = 1;
				push @{$self->{error_mn}{array}}, [$n, $ci];
			}
		}
		if ($t_c1){
			$self->{error_c1}{flag} = 1;
			push @{$self->{error_c1}{array}}, [$n, $ci];
		}
		if ($t_c2){
			$self->{error_c2}{flag} = 1;
			push @{$self->{error_c2}{array}}, [$n, $ci];
		}
		++$n;
		print EDITED Jcode->new($co,'euc')->$icode, "\n";
	}
	close (EDITED);
	close (SOURCE);
	unlink ($file_lines);
	
	# 改行コードの不統一が発見された場合
	my $line_count2 = $n - 1;
	unless  ($line_count1 == $line_count2) {
		print "lines: $line_count1, $line_count2\n";
		$self->{error_c2}{flag} = 1;
		unless (defined($self->{error_c2}{array})) {
			$self->{error_c2}{array} = [];
		}
	}

	# レポート（概要）の作成
	my $if_errors = 0;
	my $msg = '';
	foreach my $i ('error_m1','error_n1b','error_mn','error_c1','error_c2','error_n1a'){
		if ($self->{$i}{flag}){
			my $num = @{$self->{$i}{array}};
			$num = '?' unless $num;
			$msg .= "  * $errors{$i}: $num".kh_msg->get('lines')."\n";
			
			# 自動修正できるかどうかで分ける
			if (
				   $i eq 'error_m1'
				|| $i eq 'error_n1b'
				|| $i eq 'error_mn'
			){
				++$self->{auto_ng};
			} else {
				++$self->{auto_ok};
			}
		}
	}
	if ($msg){
		$msg = kh_msg->get('errors_summary')."\n".$msg; # "分析対象ファイル内に以下の問題点が発見されました（要約表示）："
		$self->{repo_sum} = $msg;
	} else {
		$msg = kh_msg->get('looks_good'); #"分析対象ファイル内に既知の問題点は発見されませんでした。\n前処理を安全に実行できると考えられます。";
		gui_errormsg->open(
			type => 'msg',
			msg  => $msg,
			icon => 'info',
		);
		$self->clean_up;
		return 1;
	}
	
	# レポート（詳細）の作成
	$msg = kh_msg->get('errors_detail')."\n";#"分析対象ファイル内に以下の問題点が発見されました（詳細表示）：\n";
	foreach my $i ('error_m1','error_n1b','error_mn','error_c1','error_c2','error_n1a'){
		if ($self->{$i}{flag}){
			my $num = @{$self->{$i}{array}};
			$num = '?' unless $num;
			$msg .= "\n* $errors{$i}: $num".kh_msg->get('lines')."\n";
			
			foreach my $h (@{$self->{$i}{array}}){
				$msg .= "l. $h->[0]\t"; # 行番号
				my $line;
				if (length($h->[1]) > 60 ){
					my $n = 60;
					while (
						   substr($h->[1],0,$n) =~ /\x8F$/
						or substr($h->[1],0,$n) =~ tr/\x8E\xA1-\xFE// % 2
					) {
						--$n;
					}
					$line = substr($h->[1],0,$n)."...\n";
				} else {
					$line .= "$h->[1]\n";
				}
				$line = Encode::decode($euc_code, $line);
				$msg .= $line;
			}
		}
	}
	$msg = Encode::encode('cp932', $msg, sub{'?'});
	$msg = Encode::decode('cp932', $msg);

	$self->{repo_full} = $msg;

	gui_window::datacheck->open($self);
}

#------------------------#
#   詳細レポートを保存   #

sub save{
	my $self = shift;
	my $path = shift;

	open (REPORT,">$path") or 
		gui_errormsg->open(
			type => 'file',
			thefile => $path
		);

	print REPORT Jcode->new( $self->{repo_full} )->euc;

	close (REPORT);
	
	if ($::config_obj->os eq 'win32'){
		kh_jchar->to_sjis($path);
	}
}

#--------------#
#   自動修正   #

sub edit{
	my $self = shift;

	# バックアップ作成
	my $file_target = $::config_obj->os_path( $::project_obj->file_target );
	$self->{file_backup} = $::project_obj->file_backup;
	rename($file_target, $self->{file_backup}) or
		gui_errormsg->open(
			type => 'file',
			thefile => $self->{file_backup}
		);

	# 修正（置換）
	rename($self->{file_temp}, $file_target) or
		gui_errormsg->open(
			type => 'file',
			thefile => $file_target
		);

	# Diff作成
	if ( 0 ) {
	#if (-s $self->{file_backup} < 50*1024*1024 ) {
		$self->{diff} = 1;
		use Text::Diff;
		my $diff = diff(
			$self->{file_backup},
			$::project_obj->file_target,
			{STYLE => "OldStyle"}
		);
		$self->{file_diff} = $::project_obj->file_diff;
		open (DIFFO, ">$self->{file_diff}") or 
			gui_errormsg->open(
				type => 'file',
				thefile => $self->{file_diff}
			);
		print DIFFO $diff;
		close (DIFFO);
	} else {
		$self->{diff} = 0;
	}

	# レポート（詳細）の再作成
	if ($self->{auto_ng}){
		my $msg = kh_msg->get('errors_detail')."\n";#"分析対象ファイル内に以下の問題点が発見されました（詳細表示）：\n";
		foreach my $i ('error_m1','error_n1b','error_mn','error_c1','error_c2','error_n1a'){
			if ($self->{$i}{flag}){
			
				# 自動修正できるかどうかで分ける
				if (
					   $i eq 'error_m1'
					|| $i eq 'error_n1b'
					|| $i eq 'error_mn'
				){
					next;
				}
				
				#unless ( $errors{$i} =~ /自動修正不可/ ){
				#	next;
				#}
				
				my $num = @{$self->{$i}{array}};
				$num = '?' unless $num;
				$msg .= "\n* $errors{$i}： $num".kh_msg->get('lines')."\n";
				
				foreach my $h (@{$self->{$i}{array}}){
					$msg .= "l. $h->[0]\t"; # 行番号
					my $line;
					if (length($h->[1]) > 60 ){
						my $n = 60;
						while (
							   substr($h->[1],0,$n) =~ /\x8F$/
							or substr($h->[1],0,$n) =~ tr/\x8E\xA1-\xFE// % 2
						) {
							--$n;
						}
						$line = substr($h->[1],0,$n)."...\n";
					} else {
						$line = "$h->[1]\n";
					}
					$line = Encode::decode($euc_code, $line);
					$msg .= $line;
				}
			}
		}
		$msg = Encode::encode('cp932', $msg, sub{'?'});
		$msg = Encode::decode('cp932', $msg);
		$self->{repo_full} = $msg;
	} else {
		$self->{repo_full} = kh_msg->get('corrected')."\n"; #"既知の問題点はすべて修正されています。\n";
	}
	
	#print "back up [0]: $self->{file_backup}\n";
	return $self;
}

#----------------------------------#
#   終了処理：一時ファイルの削除   #

sub clean_up{
	my $self = shift;
	unlink($self->{file_temp}) if -e $self->{file_temp};
}

#--------------------------------------------------------------#
#   整形（文字化け部分削除・半角記号削除・折り返し）ルーチン   #
#--------------------------------------------------------------#

package my_cleaner;

BEGIN{
	use vars qw($ascii $twoBytes $threeBytes $ctrl $rep $character_undef);
	$ascii           = '[\x00-\x7F]';
	$twoBytes        = '[\x8E\xA1-\xFE][\xA1-\xFE]';
	$threeBytes      = '\x8F[\xA1-\xFE][\xA1-\xFE]';
	$ctrl            = '[[:cntrl:]]';                         # 制御文字
	$character_undef = '(?:[\xA9-\xAF\xF5-\xFE][\xA1-\xFE]|'  # 9-15,85-94区
		. '\x8E[\xE0-\xFE]|'                                     # 半角カタカナ
		. '\xA2[\xAF-\xB9\xC2-\xC9\xD1-\xDB\xEB-\xF1\xFA-\xFD]|' # 2区
		. '\xA3[\xA1-\xAF\xBA-\xC0\xDB-\xE0\xFB-\xFE]|'          # 3区
		. '\xA4[\xF4-\xFE]|'                                     # 4区
		. '\xA5[\xF7-\xFE]|'                                     # 5区
		. '\xA6[\xB9-\xC0\xD9-\xFE]|'                            # 6区
		. '\xA7[\xC2-\xD0\xF2-\xFE]|'                            # 7区
		. '\xA8[\xC1-\xFE]|'                                     # 8区
		. '\xCF[\xD4-\xFE]|'                                     # 47区
		. '\xF4[\xA7-\xFE]|'                                     # 84区
		. '\x8F[\xA1-\xFE][\xA1-\xFE])';                         # 3バイト文字
}

sub exec{
	my $t = shift;
	
	my $flag_bake     = 0;
	my $flag_hankaku  = 0;
	my $flag_long     = 0;
	my $flag_longlong = 0;

	# morpho_analyzer
	if (
		   $::config_obj->c_or_j eq 'chasen'
		|| $::config_obj->c_or_j eq 'mecab'
	){                                            # chasen・mecabを使う場合
		if ($t =~ /'|\\|"|<|>|$ctrl|\|/){
			$flag_hankaku = 1;
		}
		# 半角記号の削除
		$t =~ s/'/’/g;
		$t =~ s/\\/¥/g;
		$t =~ s/"/”/g;
		$t =~ s/\|/｜/g;
		$t =~ s/</＜/g;
		$t =~ s/>/＞/g;
		$t =~ s/$ctrl/ /g;
		$t =~ s/ /　/g;
	} else {                                      # chasen・mecab以外の場合
		if ($t =~ /<|>|$ctrl/){
			$flag_hankaku = 1;
		}
		# 半角記号の削除
		$t =~ s/</＜/g;
		$t =~ s/>/＞/g;
		$t =~ s/$ctrl/ /g;
	}

	my $max = 8000; 
	$max = 4000 if $::config_obj->c_or_j eq 'mecab';
	if (length($t) > $max){
		$flag_long = 1;
	}

	# 一文字ずつ処理
	my @chars = $t =~ /$ascii|$twoBytes|$threeBytes/og;

	my $n = 0;
	my $r = '';
	my $cu = '';
	foreach my $i (@chars){
		# 化けている文字はスキップ（機種依存文字・3バイト文字もスキップ）
		if (
			   ($i =~ /$character_undef/o)
			|| (
				   ($i =~ /$ascii/o)
				&! ($i =~ /[[:print:]]/o)
			)
		){
			$flag_bake = 1;
			next;
		}
		
		# 半角カナの修正
		if ($i =~ /(?:\x8E[\xA6-\xDF])/){ 
			$i = Jcode->new($i,'euc')->h2z;
			$flag_hankaku = 1;
		}
		
		# 折り返し
		if (
			( $n > 200   )
			&& ( $flag_long )
			&& (
				   $i eq ' '
				|| $i eq '　'
				|| $i eq '。'
				|| $i eq '.'
				|| $i eq '-'
				|| $i eq '−'
				|| $i eq '—'
			)
		){
			$cu .= "$i\n";
			$r .= $cu;
			if (length($cu) > $max){
				$flag_longlong = 1;
			}
			$cu = '';
			$n = -1;
		} else {
			$cu .= $i;
		}
		++$n;
	}
	if (length($cu) > $max){
		$flag_longlong = 1;
	}
	$r .= "$cu";
	#$r = Jcode->new($r,'euc')->sjis;
	
	return ($r,$flag_bake,$flag_hankaku,$flag_long,$flag_longlong);
}

1;