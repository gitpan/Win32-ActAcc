# Copyright 2000, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility) demo: Traverse window hierarchy

use strict;
use Win32::OLE;
use Win32::ActAcc;

use Data::Dumper;

# main
sub main
{
	Win32::OLE->Initialize();
	my $ao = Win32::ActAcc::Desktop();
	print "\naaDigger - Navigates tree of Accessible Objects\n\n";
	help();
	menu($ao);
}

sub printAtt
{
	my $phash = shift;
	my $key = shift;

	my $v = $$phash{$key};
	if (defined($v))
	{
		my @l = split("\n",$v);
		my $l0 = $l[0];
		if (length($l0))
		{
			print "   ";
			print $key;
			print ' ' x (19-length($key));
			print $l[0];
			print "\n";
		}
	}
}

sub help
{
	print "Windows shown as: " .  Win32::ActAcc::AO::describe_meta() . "\n";
	print "Commands:\n";
	print "  99      - expand window by number (specify number from the list)\n";
	print "  ..      - go 'up' one level, to parent of current window\n";
	print "  /regexp - find children matching regexp\n";
	print "  tree    - display children hierarchically\n";
	print "  all     - expand list to include invisible children\n";
}

sub menu
{
	my $ao = shift; # active object, ie, get_itemID == CHILDID_SELF
	while (1)
	{
		if (!defined($ao))
		{
			print "Thank you\n";
			return;
		}

		my %i;
		$i{'Role'} = Win32::ActAcc::GetRoleText($ao->get_accRole());
		$i{'State'} = Win32::ActAcc::GetStateTextComposite($ao->get_accState());
		$i{'Name'} = $ao->get_accName();
		$i{'Description'} = $ao->get_accDescription();
		$i{'Value'} = $ao->get_accValue();
		$i{'Help'} = $ao->get_accHelp();
		$i{'DefaultAction'} = $ao->get_accDefaultAction();
		$i{'KeyboardShortcut'} = $ao->get_accKeyboardShortcut();

		print "=== $i{'Role'}  $i{'Name'}\n";
		printAtt(\%i, 'Description');
		printAtt(\%i, 'Value');
		printAtt(\%i, 'Help');
		printAtt(\%i, 'DefaultAction');
		printAtt(\%i, 'KeyboardShortcut');

		print "\nChildren:\n";

		my @ch = $ao->AccessibleChildren();

		WITH_LIST_OF_CHILDREN: while (1)
		{
			my $i;
			for ($i = 0; $i < @ch; $i++)
			{
				my $expansion = (Win32::ActAcc::CHILDID_SELF() == $ch[$i]->get_itemID()) ? '+' : '.';
				print "$i$expansion ".($ch[$i]->describe()) . "\n";
			}

			print "\nCommand?  Child number?  ";
			my $fullcmd = <STDIN>;
			chomp $fullcmd;
			if ($fullcmd =~ /^\d/)
			{
				$fullcmd = "go $fullcmd";
			}
			print "$fullcmd...\n";
			my ($cmd,$arg) = split(/\s/,$fullcmd);
			if ($arg =~ /^\d/)
			{
				$arg = $ch[$arg];
			}
			if ($cmd =~ /^go/i)
			{
				$ao = $arg;
			}
			elsif ($cmd =~ /^\.\./)
			{
				my $p = $ao->get_accParent();
				$ao = $p;
			}
			elsif ($cmd =~ m!^/!)
			{
				my $re = qr($');
				for (my $i = 0; $i <= $#ch; $i++)
				{
					print "$i...\r";
					my @L;
					my $ach = $ch[$i];
					$ch[$i]->findDescendant(qr($re), \@L);
					if (@L) 
					{
						print "\n" . join("\n",map($_->describe(), @L))."\n";
					}
				}
			}
			elsif ($cmd =~ /^visible$/)
			{
				#@ch = grep(!($_->get_accState() & Win32::ActAcc::STATE_SYSTEM_INVISIBLE()), @ch);
				@ch = $ao->AccessibleChildren(Win32::ActAcc::STATE_SYSTEM_INVISIBLE(), 0);
				next WITH_LIST_OF_CHILDREN;
			}
			elsif ($cmd =~ /^all$/)
			{
				@ch = $ao->AccessibleChildren(0, 0);
				next WITH_LIST_OF_CHILDREN;
			}
			elsif ($cmd =~ /^tree$/)
			{
				tree($ao);
			}
			elsif ($cmd =~ /^\?|h/i)
			{
				help();
				next WITH_LIST_OF_CHILDREN;
			}
			else {
			  print "What? Try help\n";
			}
			    
			last WITH_LIST_OF_CHILDREN;
		}
	}
}

sub tree
{
	my $ao = shift;
	my $level = shift;

	print "" . (' ' x $level) . ($ao->describe()) . "\n";

	my @ch = $ao->AccessibleChildren();
	foreach(@ch)
	{
		tree($_, 1+$level);
	}
}

&main;

