#!/usr/bin/env perl

use strict;
use warnings;

our %alreadyPresent;

if( $#ARGV <= 0 )
{
    print "Usage ./VcToMuttAlias <vcfile> <muttaliasefile>\n";
    exit;
}

my ($vcFile, $muttAlias) = @ARGV;

if( !(-e $vcFile) )
{
    print "vCard format file doesn't exists\n";
    exit;
}
else
{
    open VCF, $vcFile or die "Unable to open $vcFile\n";
    open MA, $muttAlias or die "Unable to open $muttAlias\n";
    
    my $separator = $\;
    my @text = <MA>;
    $\ = $separator;

    my @matched = grep(/^(?:alias )(["]?[(\w|\.)+\s]+["]?)( .*@.*)+/, @text);
    my $i = 0;
    my @namesOnly;

    foreach( @matched )
    {
	if( /^(?:alias )(["]?[(\w|\.)+\s]+["]?)( .*@.*)+/ )
	{
	    if( defined $1 && defined $2 )
	    {
		my $name = $1;
		my $emails = $2;
		if( $emails =~ /^ /)
		{
		    $emails = substr( $emails, 1);
		}
		$alreadyPresent{$name} = $emails;		
	    }
	    $namesOnly[$i++] = $1;
	}
    }

    my %namesToEmails = ();

    while(<VCF>)
    {
	if( /^(?:BEGIN:VCARD)/ )
	{
	    my ($name, $email) = ("", "");
	    my $nameTrue = 0;
	    my $dontAddToNamesToEmails = 0;
	    $_ = <VCF>;
	    $_ = <VCF>;
	    chomp;
	    if( /^(?:FN:)(.*)/ )
	    {
		if(defined $1 && $1 ne "")
		{
		    $nameTrue = 1;
		    $name = $1;
		}
	    }
	    $_ = <VCF>;
	    $_ = <VCF>;
	    if( /^(?:EMAIL.*:)(.*)/ )
	    {
		chomp($email = $1);
		if( $nameTrue == 0 )
		{
		    $name = substr($email, 0, index($email, "@"));
		}
	    }

	    my $matchedName;

	    next
		if( isDuplicate(\@namesOnly, $name, $email, \$matchedName) == 1);

	    while( defined $matchedName && exists $alreadyPresent{$matchedName} )
	    {
		my $choice = printMenu($name, $email, $matchedName);
		if( $choice =~ /^[n|N]$/ )
		{
		    print "Please enter a new name for this contact : ";
		    $name = <STDIN>;
		    chomp $name;
		    my $isDup = isDuplicate(\@namesOnly, $name, $email, \$matchedName);
		    last
			if( ($isDup == 0 ) && !(exists $namesToEmails{$name}));
		   
		    next;
		}
		elsif( $choice =~ /^[s|S]$/ )
		{
		    $dontAddToNamesToEmails = 1;
		    last;
		}
		elsif( $choice =~ /^[m|M]$/ )
		{
		    my $value = $alreadyPresent{$matchedName};
		    $value .= " ";
		    $value .= $email;
		    $alreadyPresent{$matchedName} = $value;
		    $dontAddToNamesToEmails = 1;
		    last;
		}
		elsif( $choice =~ /^[r|R]$/ )
		{
		    delete $alreadyPresent{$matchedName};
		}
	    }

	    if( exists $namesToEmails{$name} )
	    {
		my $value = $namesToEmails{$name};
		$value .= " ";
		$value .= $email;
		$namesToEmails{$name} = $value;
	    }
	    elsif( !$dontAddToNamesToEmails )
	    {
		$namesToEmails{$name} = $email;
	    }
	}
    }

    open MA, "> $muttAlias" or die "Unable to open $muttAlias\n";

    foreach( @text )
    {
	if( /^(?:alias )(["]?[(\w|\.)+\s]+["]?)( .*@.*)+/ )
	{
	    if( exists $alreadyPresent{$1} )
	    {
		print MA "alias $1 $alreadyPresent{$1}\n";
	    }
	}
	else
	{
	    print MA $_;
	}
    }

    for( sort( keys (%namesToEmails) ) )
    {
	print MA "alias \"$_\" $namesToEmails{$_}\n";
    }
}

sub printMenu
{
    my($name, $emails, $match) = @_;

    while( 1 )
    {
	print "An alias with $name already exists, having following email-ids:\n";
	print "$alreadyPresent{$match}\n";

	print "Emails associated with contact in VCF file:\n";
	print "$emails\n";

	print "Options :\n";
	print "\tFor choosing a different name for the new alias, type 'n'\n";
	print "\tFor kepping the older contact only, type 's'\n";
	print "\tFor merging the two contacts, type 'm'\n";
	print "\tFor replacing the older alias with the new alias, type 'r'\n";

	my $choice = <STDIN>;
	chomp $choice;
	if( $choice =~ /^[n|N|s|S|m|M|r|R]$/ )
	{
	    return $choice;
	}
	else
	{
	    print "Invalid choice!\n";
	}
    }
}

sub isDuplicate
{
    my ($namesOnlyRef, $name, $email, $matchedNameRef) = @_;
    my @matches = grep /^(["]?$name["]?)$/, @{$namesOnlyRef};
    if( $#matches == 0 )
	{    
	    $$matchedNameRef = $matches[$#matches];
	    my $value = $alreadyPresent{$$matchedNameRef};
	    $value = substr($value, 1)
		if( $value =~ /^ / );
	    my @emails = split / /, $value;
	    foreach( @emails )
	    {
		if( $email eq $_ )
		{
		    return 1; # a duplicate exists 
		}
	    }
	    return 2; # 2 means that there is an alias already existing with $name, but have different email ids
	}

    return 0; # 0 for no duplicates
}
