package kh_nbayes::Util;

use List::Util qw(max sum);

sub knb2lst{
	my $class = shift;
	my $self = {@_};
	bless $self, $class;

	# 学習結果の読み込み
	$self->{cls} = Algorithm::NaiveBayes->restore_state($self->{path});
	my $fixer = 0;
	foreach my $i (values %{$self->{cls}{model}{smoother}}){
		$fixer = $i if $fixer > $i;
	}

	# データ整形[1]
	my @labels = $self->{cls}->labels;
	my @rows;
	my %printed = ();
	foreach my $i (@labels){ # $i = ラベル
		foreach my $h (keys %{$self->{cls}{model}{probs}{$i}}){ # $h = 語
			unless ( $printed{$h} ){
				my $current = [ $h ];
				foreach my $k (@labels){ # $k = ラベル
					push @{$current},
						(
							   $self->{cls}{model}{probs}{$k}{$h}
							|| $self->{cls}{model}{smoother}{$k} 
						)
						- $fixer
					;
				}
				push @rows, $current;
				$printed{$h} = 1;
			}
		}
	}

	$self->{info}{instances} = $self->{cls}{instances};
	$self->{info}{words} = @rows;
	$self->{info}{labels} = \@labels;

	# 事前確率
	my $prior_probs = [kh_msg->get('prior')]; # [事前確率]
	foreach my $i (@labels){
		push @{$prior_probs}, $self->{cls}{model}{prior_probs}{$i} - $fixer;
	}
	push @rows, $prior_probs;

	$self->{cls} = undef; # メモリのクリア

	# データ整形[2]
	my $c = @labels;
	my @sort;
	foreach my $i (
		sort { sum( @{$b}[1..$c] ) <=> sum( @{$a}[1..$c] ) } 
		@rows
	){
		my @current = ();
		# スコア
		foreach my $h ( @{$i} ){
			push @current, $h;
		}
		
		# 分散
		my $sum = sum( @{$i}[1..$c] );
		my $s = 0;
		foreach my $h ( @{$i}[1..$c] ){
			$s += ( $sum / $c - $h ) ** 2;
		}
		$s /= $c;
		push @current, $s;
		
		# 行の%
		foreach my $h ( @{$i}[1..$c] ){
			push @current, $h / $sum * 100;
		}
		
		push @sort, \@current;
	}
	undef @rows;

	$self->{rows} = \@sort;
	return $self;
}

sub rows{
	my $self = shift;
	return $self->{rows};
}
sub instances{
	my $self = shift;
	return $self->{info}{instances};
}
sub words{
	my $self = shift;
	return $self->{info}{words};
}
sub labels{
	my $self = shift;
	return @{$self->{info}{labels}};
}


sub make_csv{
	my $self = shift;
	
	my $csv = shift;
	print "$csv\n";
	
	# 書き出し
	use File::BOM;
	open (COUT, '>:encoding(utf8):via(File::BOM)', $csv) or 
		gui_errormsg->open(
			type    => 'file',
			thefile => "$csv",
		);

	my @labels = $self->labels;

	my $header = '';
	$header .= ','.kh_msg->get('h_score','gui_window::use_te_g').',';  #',スコア,';
	for (my $n = 1; $n <= $#labels; ++$n){
		$header .= ',';
	}
	$header .= ','.kh_msg->get('pcnt','gui_window::word_freq')."\n";#",行の%\n";

	$header .= kh_msg->gget('words').','; #"抽出語,";
	foreach my $i (@labels){
		$header .= kh_csv->value_conv($i).',';
	}
	$header .= kh_msg->get('variance','gui_window::bayes_view_knb').','; #'分散,';
	foreach my $i (@labels){
		$header .= kh_csv->value_conv($i).',';
	}
	chop $header;
	print COUT "$header\n";

	foreach my $i ( @{$self->{rows}} ){
		my $c = 0;
		my $t = '';
		foreach my $h (@{$i}){
			if ($c){
				$t .= "$h,";
			} else {
				$t .= kh_csv->value_conv($h).',';
			}
			++$c;
		}
		chop $t;
		print COUT "$t\n";
	}
	close (COUT);
	
	return 1;
}

1;
