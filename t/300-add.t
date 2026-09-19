#!/usr/bin/perl

use strict;
use warnings;

use Cwd 'abs_path';

use Shell::Command;
use Test::Most;

chdir 't/etc/' or die $!;

$ENV{'HOME'} = abs_path ('.homerooms_home');
$ENV{'XDG_CONFIG_HOME'} = $ENV{'HOME'}.'/.config';

chdir '.homerooms_home' or die $!;

eval {
	touch 'a';
};

die $@ if $@;

system (".././fig test1 add 'a'");

my $output = `.././fig status`;

ok $output eq "test1:
A  ~/a

", 'Adding a file works';

$output = `.././fig status --terse`;

ok $output eq "test1:
A  ~/a
", 'Terse output works';

done_testing;

