# Copyright 2000, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %h = (
    'NAME'		=> 'Win32::ActAcc',
    'VERSION_FROM'	=> 'ActAcc.pm', # finds $VERSION
    'ABSTRACT_FROM'	=> 'ActAcc.pod', # finds $VERSION
    'PREREQ_PM'		=> {'Win32::OLE'=>0.13},
    'LIBS'		=> [':nosearch OleAcc.lib'], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other',
	'EXE_FILES' => ['aadigger.pl','aaEvents.pl','aaWhereAmI.pl'],
	'MYEXTLIB'=>'ActAccEL.lib',
	'AUTHOR' => 'Phill Wolf (pbwolf@cpan.org)',
	'depend' => +{'ActAcc.c'=>'ActAcc.xsh AO.xsh EM.xsh'},
	'clean' => +{'FILES'=>'README.pod ActAccEM.dll ActAccEM.obj ActAccEM.exp'},
);

#debugging
if (0)
{
	$h{'OPTIMIZE'} = "/Od /GZ /FdActAcc.pdb /Zi /D_DEBUG";
}

WriteMakefile(%h);


sub MY::postamble
{  
	my @a = <DATA>;
	return join('',@a);   
}

__END__

all:: $(INST_ARCHAUTODIR)\ActAccEM.dll

ActAccEM_CCFLAGS = -MTd -W4 -Od -D_DEBUG -DWIN32 

ActAccEL.obj: ActAccEL.x AAEvtMon.h
        $(CC) -c -TP $(ActAccEM_CCFLAGS) ActAccEL.x

ActAccEL.lib: ActAccEL.obj
        lib /name:ActAccEL.lib ActAccEL.obj

ActAccEM.obj: ActAccEM.x AAEvtMon.h ActAccEL.lib
        $(CC) -c -TP $(ActAccEM_CCFLAGS) ActAccEM.x
#		echo INSTALLBIN=$(INSTALLBIN)
#		echo INSTALLSITEARCH=$(INSTALLSITEARCH)
#		echo INST_LIBDIR=$(INST_LIBDIR)
#		echo INST_ARCHLIB=$(INST_ARCHLIB)
#		echo INST_BIN=$(INST_BIN)
#		echo INST_EXE=$(INST_EXE)
#		echo INST_LIB=$(INST_LIB)
#		echo INST_ARCHAUTODIR=$(INST_ARCHAUTODIR)

ActAccEM_LDDLFLAGS = -dll -nologo -machine:x86

$(INST_ARCHAUTODIR)\ActAccEM.dll ActAccEM.lib: ActAccEM.obj
        $(LD) -out:$(INST_ARCHAUTODIR)\ActAccEM.dll -implib:ActAccEM.lib $(ActAccEM_LDDLFLAGS) ActAccEL.lib ActAccEM.obj kernel32.lib 


