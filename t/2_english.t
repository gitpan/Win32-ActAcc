# Copyright 2000, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility) test suite

use strict;
use Data::Dumper;
use Win32::GuiTest;
use Win32::ActAcc;
use Win32::OLE;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

my @t;

push(@t, sub{&t_GetRoleText;});
push(@t, sub{&t_GetStateText;});

print "1..".@t."\n";

Win32::OLE->Initialize();

for (my $i = 1; $i <= @t; $i++)
{
	my $passed;
	eval { my $r = &{$t[$i-1]}; $passed=1; print "$r $i\n"; };
	if (!$passed)
	{
		print "not ok $i\n";
		print STDERR $@."\n";
	}
}

sub t_GetRoleText
{
	die unless 'window' eq Win32::ActAcc::GetRoleText(Win32::ActAcc::ROLE_SYSTEM_WINDOW());
	"ok";
}

sub t_GetStateText
{
	die unless 'invisible' eq Win32::ActAcc::GetStateText(Win32::ActAcc::STATE_SYSTEM_INVISIBLE());
	"ok";
}

