package gui_window::r_plot_opt::cod_netg;
use base qw(gui_window::r_plot_opt);

sub innner{
	my $self = shift;
	my $lf = $self->{labframe};

	# 共起ネットワークのオプション
	$self->{net_obj} = gui_widget::r_net->open(
		parent  => $lf,
		command => sub{ $self->calc; },
		pack    => { -anchor   => 'w'},
		r_cmd   => $self->{command_f},
		type    => 'codes',
	);

	$self->{old_additional_plots} = $self->{net_obj}{check_additional_plots};

	return $self;
}

sub calc{
	my $self = shift;
	$self->_configure_mother;

	my $r_command = '';
	if ($self->{command_f} =~ /\A(.+)# END: DATA.+/s){
		$r_command = $1;
	} else {
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->gget('r_net_msg_fail'),
		);
		print "$self->{command_f}\n";
		$self->close;
		return 0;
	}

	$r_command .= "# END: DATA\n";

	my $wait_window = gui_wait->start;
	use plotR::network;
	my $plotR = plotR::network->new(
		$self->{net_obj}->params,
		font_size         => $self->{font_obj}->font_size,
		font_bold         => $self->{font_obj}->check_bold_text,
		plot_size         => $self->{font_obj}->plot_size,
		r_command         => $r_command,
		plotwin_name      => 'cod_netg',
	);

	# プロットWindowを開く
	$wait_window->end(no_dialog => 1);
	
	if ($::main_gui->if_opened('w_cod_netg_plot')){
		$::main_gui->get('w_cod_netg_plot')->close;
	}

	return 0 unless $plotR;

	if ( $self->{old_additional_plots} !=  $self->{net_obj}{check_additional_plots}){
		if ($self->{net_obj}{check_additional_plots}) {
			$self->{ax} = $self->{ax} + 3 if $self->{ax} > 0;
		} else {
			$self->{ax} = $self->{ax} - 3;
		}
		
	}

	gui_window::r_plot::cod_netg->open(
		plots       => $plotR->{result_plots},
		msg         => $plotR->{result_info},
		msg_long    => $plotR->{result_info_long},
		ax          => $self->{ax},
		#no_geometry => 1,
	);

	$plotR = undef;


	$self->close;
	undef $self;

	return 1;

}

sub win_title{
	return kh_msg->get('win_title'); # コーディング・共起ネットワーク：調整
}

sub win_name{
	return 'w_cod_netg_plot_opt';
}

1;