#!/usr/bin/perl

use strict;
use warnings;

use Cwd 'abs_path';
use Shell::Command;
use Test::Most;

chdir 't/etc/' or die $!;

$ENV{'HOME'} = abs_path ('.homerooms_home');
$ENV{'XDG_CONFIG_HOME'} = $ENV{'HOME'}.'/.config';

system ("echo 'Yes, do as I say' | ./fig delete test1");

my $output = `./fig status`;

ok $output eq "", 'No repos set up anymore.';

# Regression test: `delete` must remove tracked paths whose names contain
# whitespace (or globbing characters). A naive `for file in $(git ls-files)`
# word-splits such names and silently leaves the files on disk.
my $tricky = $ENV{'HOME'} . '/delete me';
touch $tricky;
system ("./fig init deletews");
system ("./fig deletews add '$tricky'");
ok -e $tricky, 'file with space in name staged for deletion';
system ("echo 'Yes, do as I say' | ./fig delete deletews");
ok ! -e $tricky, 'delete removes tracked file whose name contains a space';

done_testing;
