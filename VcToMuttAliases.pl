#!/usr/bin/env perl

use strict;
use warnings;

if( $#ARGV <= 0 )
{
    print "Usage ./vctomuttalias <vcfile> <muttaliasefile>\n";
    exit;
}

my ($vcFile, $muttAlias) = @ARGV;

if( !(-e $vcFile) )
{
    print "VCF file doesn't exists\n";
    exit;
}
else
{
    open VCF, $vcFile or die "Unable to open $vcFile\n";
    open MA, ">> $muttAlias" or die "Unable to open $muttAlias\n";
    my %namesToEmails = ();

    while(<VCF>)
    {
	if( /^(BEGIN:VCARD)/ )
	{
	    my ($name, $email) = ("", "");
	    my $nameTrue = 0;
	    $_ = <VCF>;
	    $_ = <VCF>;
	    chomp;
	    if( /^(FN:)(.*)/ )
	    {
		if(defined $2 && $2 ne "")
		{
		    $nameTrue = 1;
		    $name = $2;
		}
	    }
	    $_ = <VCF>;
	    $_ = <VCF>;
	    if( /(^EMAIL.*:)(.*)/ )
	    {
		chomp($email = $2);
		if( $nameTrue == 0 )
		{
		    $name = substr($email, 0, index($email, "@"));
		}
	    }

	    if( exists $namesToEmails{$name} )
	    {
		my $value = $namesToEmails{$name};
		$value .= " ";
		$value .= $email;
		$namesToEmails{$name} = $value;
	    }
	    else
	    {
		$namesToEmails{$name} = $email;
	    }
	}
    }

    for( sort( keys (%namesToEmails) ) )
    {
	print MA "alias \"$_\" $namesToEmails{$_}\n";
    }
}


