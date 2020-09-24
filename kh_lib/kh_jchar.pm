package kh_jchar;
use strict;
use vars qw($converter);

my %char_code = ();
if (eval 'require Encode::EUCJPMS'){
	$char_code{euc}  = 'eucJP-ms';
	$char_code{sjis} = 'cp932';
} else {
	$char_code{euc}  = 'euc-jp';
	$char_code{sjis} = 'cp932';
}

BEGIN{
	if (eval 'require NKF'){
		$converter = 'nkf';
	}
	elsif( $] > 5.008 ){
		require Encode;
		$converter = 'encode';
	} else {
		use Jcode;
		$converter = 'jcode';
	}
	# print "Jcode conv: $converter\n";
}

# ファイル丸ごと変換

sub to_euc{
	my $sjistoeuc = $_[1];
	
	my $temp_file = 'temp.txt';
	while (-e $temp_file){
		$temp_file .= '.tmp';
	}
	#print "kh_jachar temp-file: $temp_file\n";
	
	open (EUC,"$sjistoeuc")
		or gui_errormsg->open(type => 'file',thefile => "$sjistoeuc");
	open (TEMP,">$temp_file")
		or gui_errormsg->open(type => 'file',thefile => "$temp_file");
	my $n = 0; my $temp = '';
	while (<EUC>){
		$temp .= $_;
		if ($n == 1000){
			$temp = kh_jchar->s2e($temp);
			print TEMP "$temp";
			$n = 0; $temp = '';
		}
		++$n;
	}
	if ($temp){
		$temp = kh_jchar->s2e($temp);
		print TEMP "$temp";
	}
	close (EUC);
	close (TEMP);
	unlink ("$sjistoeuc");
	rename ("$temp_file","$sjistoeuc");
}

sub to_sjis{
	my $sjistoeuc = $_[1];

	my $temp_file = 'temp.txt';
	while (-e $temp_file){
		$temp_file .= '.tmp';
	}
	#print "kh_jachar temp-file: $temp_file\n";

	open (EUC,"$sjistoeuc")
		or gui_errormsg->open(type => 'file',thefile => "$sjistoeuc");
	open (TEMP,">$temp_file")
		or gui_errormsg->open(type => 'file',thefile => "$temp_file");
	my $n = 0; my $temp = '';
	while (<EUC>){
		$temp .= $_;
		if ($n == 1000){
			$temp = kh_jchar->e2s($temp);
			print TEMP "$temp";
			$n = 0; $temp = '';
		}
		++$n;
	}
	if ($temp){
		$temp = kh_jchar->e2s($temp);
		print TEMP "$temp";
	}

	close (EUC);
	close (TEMP);
	unlink ("$sjistoeuc");
	rename ("$temp_file","$sjistoeuc");
}

# ファイルの文字コードを判別

sub check_code{
	my $the_file = $_[1];
	my $silent   = $_[2];
	my $lines    = $_[3];
	
	$lines = 1000 unless $lines;
	
	if ( defined($::project_obj) ){
		my $chk = $::project_obj->assigned_icode;
		if (
			   ( $::project_obj->file_target eq $the_file )
			&& ( $chk )
		) {
			return $chk;
		}
	}
	print "Checking icode (jp1)... " unless $silent;
	
	open (TEMP,$the_file)
		or gui_errormsg->open(type => 'file',thefile => $the_file);
	my $n = 0;
	my $t;
	while (<TEMP>){
		$_ =~ s/\x0D\x0A$|\x0D$|\x0A$/\n/;
		chomp;
		next unless length($_);
		$t .= $_;
		++$n;
		last if $n > $lines;
	}
	close (TEMP);

	#print "checking icode...(icode)\n";

	use Jcode;
	my $icode = Jcode->new($t)->icode;

	$icode = 'euc' if $icode eq 'euc-jp';
	$icode = 'euc' if $icode eq 'eucJP-ms';
	$icode = 'sjis' if $icode eq 'shiftjis';
	$icode = 'sjis' if $icode eq 'cp932';
	$icode = 'jis' if  $icode eq '7bit-jis';

	print "$icode\n" unless $silent;
	return $icode;
}

sub check_code2{
	my $the_file = $_[1];
	my $silent   = $_[2];
	my $lines    = $_[3];
	
	$lines = 1000 unless $lines;
	
	if ( defined($::project_obj) ){
		my $chk = $::project_obj->assigned_icode;
		if (
			   ( $::project_obj->file_target eq $the_file )
			&& ( $chk )
		) {
			return $chk;
		}
	}
	print "Checking icode (jp2)... " unless $silent;
	
	open (TEMP,$the_file)
		or gui_errormsg->open(type => 'file',thefile => $the_file);
	my $n = 0;
	my $t;
	while (<TEMP>){
		$_ =~ s/\x0D\x0A$|\x0D$|\x0A$/\n/;
		chomp;
		next unless length($_);
		$t .= $_;
		++$n;
		last if $n > $lines;
	}
	close (TEMP);

	#print "checking icode...(icode)\n";

	use Jcode;
	my $icode = Jcode->new($t)->icode;

	my %char_code = ();
	$char_code{shiftjis} = 'cp932';
	$char_code{sjis} = 'cp932';
	if (eval 'require Encode::EUCJPMS'){
		$char_code{euc}  = 'eucJP-ms';
	} else {
		$char_code{euc}  = 'euc-jp';
	}

	$icode = $char_code{$icode} if $char_code{$icode};

	print "$icode\n" unless $silent;
	return $icode;
}

sub check_code3{
	my $the_file = $_[1];
	my $silent   = $_[2];
	my $lines    = $_[3];
	
	$lines = 1000 unless $lines;
	
	print "Checking icode (jp3)... " unless $silent;
	
	open (TEMP,$the_file)
		or gui_errormsg->open(type => 'file',thefile => $the_file);
	my $n = 0;
	my $t;
	while (<TEMP>){
		$_ =~ s/\x0D\x0A$|\x0D$|\x0A$/\n/;
		chomp;
		next unless length($_);
		$t .= $_;
		++$n;
		last if $n > $lines;
	}
	close (TEMP);

	my @candi = (
		$char_code{euc},
		'cp932',
		'7bit-jis'
	);
	if ($^O eq 'darwin'){
		push @candi, 'MacJapanese';
	}

	use Encode::Guess;
	my $enc = guess_encoding($t, @candi);
	print ref $enc ? $enc->name : $enc unless $silent;
	print "\n" unless $silent;

	if (ref $enc){
		$enc = $enc->name;
	} elsif ($enc =~ /MacJapanese/ && $^O eq 'darwin') {
		$enc = 'MacJapanese';
	} elsif ($enc =~ /utf8/i){
		$enc = 'utf8';
	} elsif ($enc =~ /cp932/){
		$enc = 'cp932';
	} elsif ($enc =~ /euc/){
		$enc = $char_code{euc};
	} elsif ($enc =~ /^No / ){
		warn("\nFailed to guess encoding of the text.\nMaybe, you need to clean up your data...\n");
		$enc = 'utf8';
	} else {
		die("something wrong with icode! $enc");
	}

	return $enc;
}

# ファイルの文字コードを判別(英語)

sub check_code_en{
	my $the_file = $_[1];
	my $silent   = $_[2];
	my $lines    = $_[3];
	
	$lines = 50000 unless $lines;
	
	print "Checking icode (en)... " unless $silent;
	
	open (TEMP,$the_file)
		or gui_errormsg->open(type => 'file',thefile => $the_file);
	my $n = 0;
	my $t;
	while (<TEMP>){
		$t .= $_;
		++$n;
		last if $n > $lines;
	}
	close (TEMP);

	#use Devel::Size qw(size total_size);
	#print size($t);

	use Encode::Guess;
	my $enc = guess_encoding($t, qw/latin1 cp1252/);
	print ref $enc ? $enc->name : $enc unless $silent;
	print "\n" unless $silent;
	if (ref $enc){
		$enc = $enc->name;
	} elsif ($enc =~ /utf8/i) {
		$enc = 'utf8';
	} elsif ($enc =~ /cp1252/){
		$enc = 'cp1252';
	} elsif ($enc =~ /latin1/){
		$enc = 'latin1';
	} elsif ($enc =~ /^No / ){
		warn("\nFailed to guess encoding of the text: $enc\n\nMaybe, you need to clean up your data...\n");
		$enc = 'utf8';
	} else {
		warn("Something wrong with text encoding: $enc\n\nPlease make a UTF-8 text without any non-printing characters or control characters.");
		$enc = 'utf8';
	}

	return $enc;
}

# ファイルの文字コードを判別(対応コードすべて)

sub check_code_all{
	my $the_file = $_[1];
	my $silent   = $_[2];
	my $lines    = $_[3];
	
	$lines = 50000 unless $lines;
	
	print "Checking icode (en)... " unless $silent;
	
	open (TEMP,$the_file)
		or gui_errormsg->open(type => 'file',thefile => $the_file);
	my $n = 0;
	my $t;
	while (<TEMP>){
		$t .= $_;
		++$n;
		last if $n > $lines;
	}
	close (TEMP);

	#use Devel::Size qw(size total_size);
	#print size($t);

	use Encode::Guess;
	my $enc = guess_encoding($t, qw/cp932 euc-jp ISO-2022-JP latin1 cp1252/);
	print ref $enc ? $enc->name : $enc unless $silent;
	print "\n" unless $silent;
	if (ref $enc){
		$enc = $enc->name;
	} elsif ($enc =~ /utf8/) {
		$enc = 'utf8';
	} elsif ($enc =~ /euc-jp/) {
		$enc = 'euc-jp';
	} elsif ($enc =~ /cp932/) {
		$enc = 'cp932';
	} elsif ($enc =~ /ISO-2022-JP/){
		$enc = 'ISO-2022-JP';
	} elsif ($enc =~ /cp1252/){
		$enc = 'cp1252';
	} elsif ($enc =~ /latin1/){
		$enc = 'latin1';
	} elsif ($enc =~ /^No / ){
		warn("\nFailed to guess encoding of the text.\nMaybe, you need to clean up your data...\n");
		$enc = 'utf8';
	} else {
		die("something wrong with icode! $enc");
	}

	return $enc;
}

# 文字列変換

sub s2e{
	my $conv = '_s2e_'.$kh_jchar::converter;
	kh_jchar->$conv($_[1]);
}
sub _s2e_nkf{
	return NKF::nkf('-e -S',$_[1]);
}
sub _s2e_encode{
	Encode::from_to($_[1],$char_code{sjis},$char_code{euc});
	return $_[1];
}
sub _s2e_jcode{
	return Jcode->new($_[1],'sjis')->euc;
}


sub e2s{
	my $conv = '_e2s_'.$kh_jchar::converter;
	kh_jchar->$conv($_[1]);
}
sub _e2s_nkf{
	return NKF::nkf('-s -E',$_[1]);
}
sub _e2s_encode{
	Encode::from_to($_[1],$char_code{euc},$char_code{sjis});
	return $_[1];
}
sub _e2s_jcode{
	return Jcode->new($_[1],'euc')->sjis;
}


1;
