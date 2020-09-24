package gui_window::stop_words::stemming_pt;

use strict;
use base qw(gui_window::stop_words);





#--------------#
#   アクセサ   #

sub method{
	return 'stemming';
}

sub method_name{
	return 'Snowball Stemming';
}

sub locale_name{
	return 'pt';
}

sub win_name{
	return 'w_stopwords_stteming_pt';
}
1;