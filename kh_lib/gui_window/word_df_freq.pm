package gui_window::word_df_freq;
use base qw(gui_window);

use strict;
use gui_hlist;
use mysql_words;

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $wmw= $self->{win_obj};
	#$self->{win_obj} = $wmw;
	#$wmw->focus;
	$wmw->title($self->gui_jt('ʸ�����ʬ��'));
	
	$wmw->Label(
		-text => $self->gui_jchar('����������'),
		-font => "TKFN"
	)->pack(-anchor => 'w');
	
	my $lis1 = $wmw->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 0,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 2,
		-padx             => 2,
		#-background       => 'white',
		#-selectforeground => 'brown',
		#-selectbackground => 'cyan',
		-indicator => 0,
		-borderwidth        => 0,
		-highlightthickness => 0,
		-selectmode       => 'none',
		-height           => 4,
		-width            => 30,
	)->pack();
	
	$wmw->Label(
		-text => $self->gui_jchar('���ٿ�ʬ��ɽ'),
		-font => "TKFN"
	)->pack(-anchor => 'w');

	my $lis2 = $wmw->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 1,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 5,
		-padx             => 2,
		-background       => 'white',
		-selectforeground => 'brown',
		#-selectbackground => 'cyan',
		-selectmode       => 'extended',
		-height           => 10,
	)->pack(-fill =>'both',-expand => 'yes');
	
	$lis2->header('create',0,-text => $self->gui_jchar('ʸ���'));
	$lis2->header('create',1,-text => $self->gui_jchar('�ٿ�'));
	$lis2->header('create',2,-text => $self->gui_jchar('�ѡ������'));
	$lis2->header('create',3,-text => $self->gui_jchar('�����ٿ�'));
	$lis2->header('create',4,-text => $self->gui_jchar('���ѥѡ������'));
	
	$self->{copy_btn} = $wmw->Button(
		-text => $self->gui_jchar('���ԡ�'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {gui_hlist->copy($self->list2);});} 
	)->pack(-side => 'left',-padx => 5);

	$self->win_obj->bind(
		'<Control-Key-c>',
		sub{ $self->{copy_btn}->invoke; }
	);
	$self->win_obj->Balloon()->attach(
		$self->{copy_btn},
		-balloonmsg => 'Ctrl + C',
		-font => "TKFN"
	);

	my $btn = $wmw->Button(
		-text => $self->gui_jchar('�ץ��å�'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {
			$self->plot;
		});} 
	)->pack(-side => 'left');

	unless ($::config_obj->R){
		$btn->configure(-state => 'disable');
	}

	$wmw->Label(
		-text => $self->gui_jchar('  ����ñ�̡�'),
		-font => "TKFN"
	)->pack(-side => 'left');

	my %pack = (
			#-anchor => 'e',
			#-pady   => 1,
			-side   => 'left'
	);
	$self->{tani_obj} = gui_widget::tani->open(
		parent  => $wmw,
		pack    => \%pack,
		command => sub {$self->count;},
	);

	$wmw->Button(
		-text => $self->gui_jchar('�Ĥ���'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {$self->close;});} 
	)->pack(-side => 'right');

	$self->{list1} = $lis1;
	$self->{list2} = $lis2;
	return $self;
}

sub count{
	my $self = shift;
	return 0 unless $self->{tani_obj};
	my ($r1, $r2) = mysql_words->freq_of_df($self->{tani_obj}->tani);
	
	# ��������
	$self->list1->delete('all');
	my $numb_style = $self->list1->ItemStyle(
		'text',
		-anchor => 'e',
		-font => "TKFN"
	);
	my $row = 0;
	foreach my $i (@{$r1}){
		$self->list1->add($row,-at => "$row");
		$self->list1->itemCreate(
			$row,
			0,
			-text  => $self->gui_jchar($i->[0]),
		);
		$self->list1->itemCreate(
			$row,
			1,
			-text  => $i->[1],
			-style => $numb_style
		);
		++$row;
	}
	
	# �ٿ�ʬ��ɽ
	$self->list2->delete('all');
	$numb_style = $self->list1->ItemStyle(
		'text',
		-anchor => 'e',
		-font => "TKFN"
	);
	my $rcmd = 'hoge <- matrix( c(';
	$row = 0;
	foreach my $i (@{$r2}){
		$rcmd .= "$i->[0],$i->[3],$i->[1],";
		$self->list2->add($row,-at => "$row");
		my $col = 0;
		foreach my $h (@{$i}){
			$self->list2->itemCreate(
				$row,
				$col,
				-text  => $h,
				-style => $numb_style
			);
			++$col;
		}
		++$row;
	}
	chop $rcmd;
	$rcmd .= "), nrow=$row, ncol=3, byrow=TRUE)";
	$self->{rcmd} = $rcmd;
	
	if ($::main_gui->if_opened('w_word_df_freq_plot')){
		$self->plot;
		$self->{win_obj}->focus;
	}
	
	return $self;
}

sub plot{
	# �ץ��åȤ�������Ƥ���ɽ����Window�򳫤�
	my $self = shift;
	return 0 unless $::config_obj->R;

	my $tani = $self->{tani_obj}->tani;
	my %tani_name = (
		'bun' => 'ʸ',
		'dan' => '����',
		'h1'  => 'H1',
		'h2'  => 'H2',
		'h3'  => 'H3',
		'h4'  => 'H4',
		'h5'  => 'H5',
	);
	my $tani_name = $tani;
	if ( $tani_name{$tani} ){
		$tani_name = $tani_name{$tani};
	}

	use kh_r_plot;
	kh_r_plot->clear_env;
	my $flg_error = 0;
	my $plot1 = kh_r_plot->new(
		name      => 'words_DF_freq1',
		command_f => 
			"$self->{rcmd}\n"
			.'plot(hoge[,1],hoge[,3],type="b",lty=1,pch=1,ylab="�ٿ�",'
			.'xlab="ʸ�����'.$tani_name.'��")',
	) or $flg_error = 1;

	my $plot2 = kh_r_plot->new(
		name      => 'words_DF_freq2',
		command_f => 
			"$self->{rcmd}\n"
			.'plot(hoge[,1],hoge[,3],type="b",lty=1,pch=1,ylab="�ٿ�",'
			.'xlab="ʸ�����'.$tani_name.'��", log="x")',
	) or $flg_error = 1;
	
	my $plot3 = kh_r_plot->new(
		name      => 'words_DF_freq3',
		command_f => 
			"$self->{rcmd}\n"
			.'plot(hoge[,1],hoge[,3],lty=1,pch=1,ylab="�ٿ�",'
			.'xlab="ʸ�����'.$tani_name.'��", log="xy")',
	) or $flg_error = 1;
	
	kh_r_plot->clear_env;
	if ($flg_error) {
		$::main_gui->get('w_word_df_freq_plot')->close
			if $::main_gui->if_opened('w_word_df_freq_plot');
		return 0;
	}
	
	if ($::main_gui->if_opened('w_word_df_freq_plot')){
		$::main_gui->get('w_word_df_freq_plot')->renew;
	} else {
		gui_window::word_df_freq_plot->open(
			images => [$plot1,$plot2,$plot3]
		);
	}
}

#--------------#
#   ��������   #

sub list2{
	my $self = shift;
	return $self->{list2};
}
sub list1{
	my $self = shift;
	return $self->{list1};
}
sub win_name{
	return 'w_word_df_freq';
}

1;