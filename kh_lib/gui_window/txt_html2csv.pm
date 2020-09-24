package gui_window::txt_html2csv;
use base qw(gui_window);

use strict;

use mysql_html2csv;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	#$win->focus;
	$win->title($self->gui_jt(kh_msg->get('win_title'))); # CSVファイルに変換
	
	#$self->{win_obj} = $win;

	my $lf = $win->LabFrame(
		-label => 'Option',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');
	
	$lf->Label(
		-text => kh_msg->get('unit'), # どの単位を1行（1ケース）として出力しますか？
		-font => "TKFN"
	)->pack(-anchor => 'w');
	
	my $f1 = $lf->Frame()->pack(-fill => 'x',-pady => 3);
	
	$f1->Label(
		-text => kh_msg->get('select'), #   選択：
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');
	
	my %pack = (
			-anchor => 'e',
			-pady   => 1,
			-side   => 'left'
	);
	$self->{tani_obj} = gui_widget::tani->open(
		parent => $f1,
		pack   => \%pack
	);
	
	$win->Button(
		-text => kh_msg->gget('cancel'), # キャンセル
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->close;}
	)->pack(-side => 'right',-padx => 2);

	$win->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->save;}
	)->pack(-side => 'right');
	
	
	return $self;
}

#--------------------#
#   ファンクション   #

sub save{
	my $self = shift;
	
	my @types = (
		[ "csv file",[qw/.csv/] ],
		["All files",'*']
	);
	my $path = $self->gui_jg(
		$self->win_obj->getSaveFile(
			-defaultextension => '.csv',
			-filetypes        => \@types,
			-title            =>
				$self->gui_jt(kh_msg->get('saving')), # CSVファイルの保存
			-initialdir       => gui_window->gui_jchar($::config_obj->cwd)
		)
	);
	
	if ($path){
		$path = gui_window->gui_jg_filename_win98($path);
		$path = gui_window->gui_jg($path);
		$path = $::config_obj->os_path($path);
		mysql_html2csv->exec(
			tani => $self->tani,
			file => $path,
		);
	}
	
	$self->close;
}


#--------------#
#   アクセサ   #

sub tani{
	my $self = shift;
	return $self->{tani_obj}->tani;
}

sub win_name{
	return 'w_txt_html2csv';
}

1;