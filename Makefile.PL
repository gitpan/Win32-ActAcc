# Copyright 2000, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %h = (
    'NAME'		=> 'Win32::ActAcc',
    'VERSION_FROM'	=> 'ActAcc.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Win32::GuiTest'=>0.6, 'Win32::OLE'=>0.13}, # e.g., Module::Name => 1.1
    'LIBS'		=> [':nosearch OleAcc.lib'], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other',
	'EXE_FILES' => ['ActAccEM.dll','aadigger.pl'],
	'MYEXTLIB'=>'ActAccEM.lib',
	'AUTHOR' => 'Phill Wolf (pbwolf@bellatlantic.net)',
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

ActAccEM_CCFLAGS = -MTd -W4 -Od -D_DEBUG -DWIN32 
ActAccEM.obj: ActAccEM.x AAEvtMon.h
        $(CC) -c -TP $(ActAccEM_CCFLAGS) ActAccEM.x

#echo INSTALLBIN=$(INSTALLBIN)
#echo INSTALLSITEARCH=$(INSTALLSITEARCH)
#echo INST_LIBDIR=$(INST_LIBDIR)
#echo INST_ARCHLIB=$(INST_ARCHLIB)
#echo INST_BIN=$(INST_BIN)
#echo INST_EXE=$(INST_EXE)
#echo INST_LIB=$(INST_LIB)

ActAccEM_LDDLFLAGS = -dll -nologo -machine:x86

ActAccEM.dll ActAccEM.lib: ActAccEM.obj
        $(LD) -out:ActAccEM.dll -implib:ActAccEM.lib $(ActAccEM_LDDLFLAGS) ActAccEM.obj kernel32.lib 


