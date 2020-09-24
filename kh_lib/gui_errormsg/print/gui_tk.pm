package gui_errormsg::print::gui_tk;
use strict;
use base qw(gui_errormsg::print);

# ダイアログボックス表示
sub print{
	use Tk;
	my $self = shift;

	# 親Windowが存在するかどうかを確認
	my $window;
	if (Exists(${$self->{window}})){
		$window = ${$self->{window}};
	}
	elsif (Exists($::main_gui->mw)) {
		$window = $::main_gui->mw;
	}
	
	if ($window){
		if ($^O eq 'darwin') {
		#if (1) {
			print "Trying out a different dialog method for darwin...\n";
			require Tk::Dialog;
			
			#require Tk::DialogBox;
			#require Tk::DialogBox_kh;
			#*Tk::DialogBox::Show = \&Tk::DialogBox_kh::Show;
			
			my $dialog_win = $window->Dialog(
				-title => 'KH Coder',
				-text => gui_window->gui_jchar("$self->{msg}"),
				-bitmap => $self->icon,
				-default_button => 'OK',
				-buttons => [kh_msg->gget('ok')],
			);
			$dialog_win->Show(-popover => $window);
		} else {
			$window->messageBox(
				-icon => $self->icon,
				-type => 'OK',
				-title => 'KH Coder',
				-message => gui_window->gui_jchar("$self->{msg}"),
			);
		}

	} else {
		# use Win32;
		# Win32::MsgBox("$self->{msg}",'16','KH Coder');
		print "$self->{msg}\n";
	}

}

# デフォルトのダイアログ形式

sub icon{
	my $self = shift;
	if ($self->{icon}){
		return $self->{icon};
	} else {
		return 'warning';
	}
}


1;
