# Copyright 2001, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility) demo: Traverse window hierarchy

# Usage:  use Win32::ActAcc::aaExplorer;  Win32::ActAcc::aaExplorer::aaExplore($ao);

use strict;

package Win32::ActAcc::aaExplorer;

use Win32::ActAcc;
use Win32::ActAcc::MouseTracker;  
use Data::Dumper;

sub aaExplore
{
	my $ao = shift; # active object, ie, get_itemID == CHILDID_SELF
	Win32::ActAcc::aaExplorer::help();
	MAJOR: while (defined($ao))
	{
		my %i;
		$i{'get_accRole'} = Win32::ActAcc::GetRoleText($ao->get_accRole());
                my $stb = $ao->get_accState();
		$i{'get_accState'} = sprintf("%04x = ", $stb) . Win32::ActAcc::GetStateTextComposite($stb);
		$i{'get_accName'} = $ao->get_accName();
		$i{'get_accDescription'} = $ao->get_accDescription();
		$i{'get_accValue'} = $ao->get_accValue();
		$i{'get_accHelp'} = $ao->get_accHelp();
		$i{'get_accDefaultAction'} = $ao->get_accDefaultAction();
		$i{'get_accKeyboardShortcut'} = $ao->get_accKeyboardShortcut();

		print "=== $i{'get_accRole'}  $i{'get_accName'}\n";
		printAtt(\%i, 'get_accDescription');
		printAtt(\%i, 'get_accValue');
		printAtt(\%i, 'get_accHelp');
		printAtt(\%i, 'get_accDefaultAction');
		printAtt(\%i, 'get_accKeyboardShortcut');

                my $iter = $ao->iterator();
		print "\nChildren, according to iterator " . ref($iter) . ":\n";

		my @ch = $iter->all(); # AccessibleChildren();

		WITH_LIST_OF_CHILDREN: while (1)
		{
			my $i;
			for ($i = 0; $i < @ch; $i++)
			{
				my $expansion = (Win32::ActAcc::CHILDID_SELF() == $ch[$i]->get_itemID()) ? '+' : '.';
				print "$i$expansion ".($ch[$i]->describe()) . "\n";
			}

                        COMMAND_PROMPT: while (1)
                        {
			    print "\nCommand?  Child number?  ";
			    my $fullcmd = <STDIN>;
			    chomp $fullcmd;
			    if ($fullcmd =~ /^\d+$/)
			    {
				    $fullcmd = "go $fullcmd";
			    }
			    print "$fullcmd...\n";
			    my ($cmd,$fullarg) = split(/\s/,$fullcmd,2);
                            if ($cmd =~ /^eval$/i)
                            {
                                my $rvref = \eval($fullarg);
                                if ($@) 
                                {   
                                    warn($@);
                                }
                                else
                                {
                                    print Dumper($rvref) . "\n";
                                }
                            }
                            elsif ($cmd =~ /^mouse/)
                            {
                                $ao = aaTrackMouse();
                                next MAJOR;
                            }
                            else 
                            {
			        my ($cmd,$arg,$remainder) = split(/\s/,$fullcmd,3);

			        if ($arg =~ /^\d/)
			        {
				        $arg = $ch[$arg];
			        }
			        if ($cmd =~ /^go/i)
			        {
				        $ao = $arg;
			        }
                                elsif ($cmd =~ /^with$/i)
                                {
                                    my $aotmp = $ao;
				        $ao = $arg;
                                    my $rvref = \eval($remainder);
                                    if ($@) 
                                    {   
                                        warn($@);
                                    }
                                    else
                                    {
                                        print Dumper($rvref) . "\n";
                                    }
                                    $ao = $aotmp;
                                    next COMMAND_PROMPT;
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
			        elsif ($cmd =~ /^q/)
			        {
				        last MAJOR;
			        }
			        elsif ($cmd =~ /^\?|h/i)
			        {
				        help();
				        next COMMAND_PROMPT;
			        }
			        else {
			          print "What? Try help\n";
				        next COMMAND_PROMPT;
			        }
			            
			        last WITH_LIST_OF_CHILDREN;
                            }
                        }
		}
	}
        print "Thank you\n";
	return;
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
			print ' ' x (25-length($key));
			print $l[0];
			print "\n";

                        if ($#l > 0)
                        {
			    print "   ";
                            print " ...plus more. Try:   eval \$ao->${key}()\n"
                        }
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
        print "  eval X  - evaluate Perl expression X (may reference \$ao)\n";
        print "    eg: eval +[\$ao->AccessibleChildren()]\n";
        print qq(    or: eval join("\\n",map(\$_->describe(),\$ao->AccessibleChildren()))\n);
        print "  mouse   - change context to where you point the mouse\n";
        print "  q       - quit\n";
        print "Suggestion: Size your window so you can see at least 132 columns.\n";
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

1;
