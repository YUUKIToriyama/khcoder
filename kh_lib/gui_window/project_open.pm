package gui_window::project_open;
use strict;
use Jcode;
use Tk;
use Tk::HList;
use base qw(gui_window);
use gui_window::project_edit;
use gui_jchar;

#----------------#
#   Window作成   #
#----------------#

sub _new{
	my $self = shift;

	# Minimize Console
	if (
		 $::config_obj->os eq 'win32'
		&& (
			   (defined($PerlApp::VERSION) && substr($PerlApp::VERSION,0,1) >= 7)
			|| (defined($main::ENV{KHCPUB}) && $main::ENV{KHCPUB} == 2)
		)
	){
		require Win32::API;
		my $FindWindow = new Win32::API('user32', 'FindWindow', 'PP', 'N');
		my $ShowWindow = new Win32::API('user32', 'ShowWindow', 'NN', 'N');
		my $hw = $FindWindow->Call( 0, 'Console of KH Coder' );
		$ShowWindow->Call( $hw, 7 );
	}

	my $mw = $::main_gui->mw;
	# Window作成
	my $few = $self->{win_obj};
	#$self->{win_obj} = $few;
	#$few->focus;
	#$few->grab;
	$few->title($self->gui_jt( kh_msg->get('win_title') ));

	# リスト作成
	my $plis = $few->Scrolled(
		'HList',
		-scrollbars=> 'osoe',
		-header => 1,
		-width => 55,
		-command => sub{$self->_open;},
		-itemtype => 'text',
		-columns => 4,
		-padx => 6,
		-background=> 'white',
		-selectforeground   => $::config_obj->color_ListHL_fore,
		-selectbackground   => $::config_obj->color_ListHL_back,
		-selectborderwidth  => 0,
		-highlightthickness => 0,
		#-selectmode => 'single',
	)->pack(-fill=>'both',-expand => 'yes');
	$self->{g_list} = $plis;

	$plis->header('create',0,-text => kh_msg->get('target_file') ); # $self->gui_jchar('対象ファイル')
	$plis->header('create',1,-text => kh_msg->get('lang') ); # 言語
	$plis->header('create',2,-text => kh_msg->get('memo')); # $self->gui_jchar('説明（メモ）')
	$plis->header('create',3,-text => kh_msg->get('dir')); # $self->gui_jchar('ディレクトリ')

	# ボタン
	my $b1 = $few->Button(
		-text => kh_msg->get('del'), #$self->gui_jchar('削除'),
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->delete;}
	)->pack(-side => 'left',-padx => 2,-pady => 2);

	$few->Button(
		-text => kh_msg->gget('cancel'),
		#-padx => 3,
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->close;}
	)->pack(-anchor => 'w',-side => 'right',-padx => 2,-pady => 2);
	
	my $b3 = $few->Button(
		-text => kh_msg->get('open'),#$self->gui_jchar('開く'),
		#-padx => 3,
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->_open;}
	)->pack(-anchor => 'w',-side => 'right',-padx => 2,-pady => 2);

	$few->Label(
		-text => '    '
	)->pack(-anchor => 'w',-side => 'right',-padx => 2,-pady => 2);

	my $b2 = $few->Button(
		-text => kh_msg->get('edit'),#$self->gui_jchar('編集'),
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->edit;}
	)->pack(-anchor => 'w',-side => 'right',-padx => 2,-pady => 2);
	
	$few->Button(
		-text => kh_msg->get('new'),#$self->gui_jchar('新規'),
		#-padx => 2,
		-font => "TKFN",
		-width => 8,
		-command => sub{
			$self->close;
			gui_window::project_new->open;
		}
	)->pack(-anchor => 'w',-side => 'right',-padx => 2,-pady => 2);
	
	$few->Label(
		-text => '        '
	)->pack(-anchor => 'w',-side => 'right',-padx => 2,-pady => 2);
	
	$self->{g_buttons} = [$b1,$b2,$b3];
	
	$self->refresh;
	
	# 各種バインド
	$self->win_obj->bind(
		'<Key-Return>',
		sub {$self->_open}
	);
	$self->win_obj->bind(
		'<KP_Enter>',
		sub {$self->_open}
	);

	#$self->win_obj->bind(
	#	'<Key-Down>',
	#	sub {
	#		my @s = $self->list->infoSelection;
	#		if ($self->{max} > $s[0]){
	#			$self->list->selectionClear;
	#			$self->list->selectionSet($s[0] + 1);
	#		}
	#	}
	#);
	#$self->win_obj->bind(
	#	'<Key-Up>',
	#	sub {
	#		my @s = $self->list->infoSelection;
	#		if ($s[0] > 0){
	#			$self->list->selectionClear;
	#			$self->list->selectionSet($s[0] - 1);
	#		}
	#	}
	#);
	
	#MainLoop;
	return $self;
}

#--------------------#
#   ファンクション   #
#--------------------#

sub edit{
	my $self = shift;
	$self->if_selected_ed or return 0;
	gui_window::project_edit->open($self->projects,$self->selected,$self);
}

sub delete{
	my $self = shift;
	$self->if_selected('del') or return 0;
	$self->projects->delete($self->selected);
	
	$self->refresh;
}

sub _open{
	my $self = shift;
	$self->if_selected or return 0;
	my $project = $self->projects->a_project($self->selected);
	$project->open or return 0;

	$::main_gui->close_all;
	$::main_gui->menu->refresh;
	$::main_gui->inner->refresh;

	$::config_obj->ini_backup;

	return 1;
}

#--------------#
#   選択確認   #

sub if_selected{
	my $self = shift;
	my $option = shift;
	
	my @temp = $self->list->infoSelection;
	if (@temp == 1){
		my $current_file;
		eval{ $current_file = $::project_obj->file_target; };
		if (
			( defined($current_file) )
			&& (
				   $self->projects->a_project("$temp[0]")->file_target
				eq $current_file
			)
		){
			if ($option eq 'del') {
				gui_errormsg->open(
					type   => 'msg',
					window  => \$self->win_obj,
					msg    => kh_msg->get('opened'),#"そのプロジェクトは現在開かれています。\n指定された操作を実行できません。"
				);
				return 0;
			} else {
				$::main_gui->close_all;
				$::main_gui->menu->refresh;
				$::main_gui->inner->refresh;
				return 0;
			}
		}
		$self->{selected} = $temp[0];
		return 1;
	} else {
		gui_errormsg->open(
			type   => 'msg',
			window  => \$self->win_obj,
			msg    => kh_msg->get('select_one'),#"プロジェクトを選択してください"
		);
		return 0;
	}
}

sub if_selected_ed{
	my $self = shift;
	my @temp = $self->list->infoSelection;
	if (@temp == 1){
		$self->{selected} = $temp[0];
		return 1;
	} else {
		gui_errormsg->open(
			type   => 'msg',
			window  => \$self->win_obj,
			msg    => kh_msg->get('select_one'),#"プロジェクトを選択してください"
		);
		return 0;
	}
}

#--------------------------#
#   リストのリフレッシュ   #

sub refresh{
	my $self = shift;
	$self->projects(kh_projects->read);
	$self->list->delete('all');

	my $n = 0;
	foreach my $i (@{$self->projects->list}){
		my $lang = $i->lang_method->[0];
		$lang = 'l_'.$lang;
		$lang = kh_msg->get($lang, 'gui_window::sysconfig');
		
		$self->list->add($n,-at => $n);
		$self->list->itemCreate($n,0,-text => $self->gui_jchar($i->file_short_name));
		$self->list->itemCreate($n,1,-text => $self->gui_jchar($lang));
		$self->list->itemCreate($n,2,-text => $self->gui_jchar($i->comment));
		$self->list->itemCreate($n,3,-text => $self->gui_jchar($i->file_dir));
		
		++$n;
	}
	
	$self->{max} = $n - 1;
	if ($n){
		#$self->list->selectionSet(0);
		$self->list->anchorSet(0);
		$self->list->selectionSet(0);
		$self->list->focus;
	}
	
}

#--------------#
#   アクセサ   #
#--------------#

sub projects{
	my $self = shift;
	if ($_[0]){
		$self->{projects} = $_[0];
	}
	return $self->{projects};
}

sub list{
	my $self = shift;
	return $self->{g_list};
}

sub buttons{
	my $self = shift;
	return $self->{g_buttons}
}

sub selected{
	my $self = shift;
	return $self->{selected};
}

sub win_name{
	return 'w_open_pro';
}

1;