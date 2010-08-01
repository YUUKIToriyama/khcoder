package gui_window::r_plot::word_cls;
use base qw(gui_window::r_plot);

sub renew_command{
	my $self = shift;
	$self->{photo_pane}->yview(moveto => 0);

	if ($::main_gui->if_opened('w_word_cls_height')){
		$::main_gui->get('w_word_cls_height')->renew(
			$self->{ax}
		);
	}
}

sub photo_pane_width{
	return 490;
}

sub option1_options{
	return [
		'Wardˡ',
		'��ʿ��ˡ',
		'�Ǳ���ˡ'
	];
}

sub option1_name{
	return ' ��ˡ��';
}

sub start{
	my $self = shift;
	$self->{bottom_frame}->Button(
		-text => $self->gui_jchar('ʻ����'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $self->win_obj->after
			(
				10,
				sub {
					if ($::main_gui->if_opened('w_word_cls_height')){
						$::main_gui->get('w_word_cls_height')->renew(
							$self->{ax}
						);
					} else {
						gui_window::word_cls_height->open(
							plots => $self->{merges},
							w_c   => $self->base_name,
							type  => $self->{ax},
						);
					}
				}
			);
		}
	)->pack(-side => 'left',-padx => 2);
}

sub win_title{
	return '��и졦���饹����ʬ��';
}

sub win_name{
	return 'w_word_cls_plot';
}


sub base_name{
	return 'word_cls';
}

1;