#!/usr/bin/env perl

use strict;
use warnings;
use Switch;

sub appendToFile(\%$);

our @alreadyPresent;

print "$#ARGV\n";
if( $#ARGV < 0 )
{
    print "Usage : perl AddGroupsToMutt.pl <MuttAliasFile>\n";
    exit;
}
else
{
    my ($fileName) = @ARGV;
    open FILE, $fileName or die "Could not open the file : $!.\n";

    my $separator = $\;
    $\ = undef;
    my @text = <FILE>;
    $\ = $separator;

    close FILE;
#print @text;

    my @matched = grep(/^alias/, @text);
    my %groupsToEmails = ();
    
    foreach( @matched )
    {
	my $flag = 0;
	if( /^(alias )(\".*\")( .*@.*)+/ )#(.*@.*( )*)+/ ) 
	{
	   $flag = 1; 
	}
	elsif( /^(alias )(\w+)( .*@.*)+/ )
	{
	    $flag = 1;
	}

	push @alreadyPresent, $2
	    if( $flag == 1 );
    }

    foreach( @matched )
    {
	my ($flag, $repeatOuter, $repeatInner) = (0, 1, 1);
	if( /^(alias )(\".*\")( .*@.*)+/ )#(.*@.*( )*)+/ ) 
	{
	   $flag = 1; 
	}
	elsif( /^(alias )(\w+)( .*@.*)+/ )
	{
	    $flag = 1;
	}

	if( ($flag == 1) && (defined $2) && (defined $3) )
	{
	    while( $repeatOuter )
	    {
		$repeatInner = 1;
		print "Name:\t$2\n";
		print "Emails:\t$3\n";
	       
		my $choice = printGroupMenu(%groupsToEmails);
		my @groups = sort keys %groupsToEmails;
		if( isNum($choice) && ($choice >= 0) && ($choice < (scalar @groups)) )
		{
		    my $emails = $groupsToEmails{$groups[$choice]};
		    $emails .= $3;
		    $groupsToEmails{$groups[$choice]} = $emails;
		    $repeatOuter = 0;
		}
		else
		{
		    switch($choice)
		    {
			case 'n' 
			{
			    while( $repeatInner )
			    {
				print "Enter the name of the new group or 'p' for returning to the previous menu: ";
				my $newGroup = <STDIN>;
				chomp $newGroup;
				if( $newGroup eq "p" )
				{
				    $repeatInner = 0;
				}
				elsif( exists $groupsToEmails{$newGroup} || 
				       (grep /$newGroup/, @alreadyPresent) || 
				       (grep /\"$newGroup\"/, @alreadyPresent))
				{
				    print "This group already exists, please choose a different name.\n";
				}
				else
				{
				    $groupsToEmails{$newGroup} = substr($3, 1);
				    $repeatOuter = 0;
				    $repeatInner = 0;
				}
			    }			    
			}
			case "q"
			{
			    appendToFile(%groupsToEmails, $fileName);
			    exit;
			}
			case "s"
			{
			    $repeatOuter = 0;
			    last;
			}
			else
			{
			    print "Invalid choice!\n"
			}
		    }
		}
	    }
	}
	print "\n\n";
    }
    appendToFile(%groupsToEmails, $fileName);
}

sub appendToFile(\%$)
{
    my $groupsToEmails = shift;
    my %hash = %$groupsToEmails;
    my $fileName = shift;

    open FILE, ">> $fileName" || die "Could not open $fileName : $!\n";
    foreach( sort keys %hash )
    {
	print FILE "alias \"$_\" $hash{$_}\n";
    }
}

sub printGroupMenu
{
    my %groupsToEmails = @_;
    my @groups = sort keys %groupsToEmails;
    print "Menu : \n";
    print "\tPress 'n' for adding this contact to a new group\n";
    print "\tPress 's' for skipping this contact\n";
    print "\tPress 'q' for exiting.\n";
    print "\tSelect the group number from the following for adding this contact to an existing group.\n"
	if( (scalar @groups) > 0 );
    my $i = 0;
    foreach( sort (keys %groupsToEmails) )
    {
	print "\t\t$i => $_\n";
	$i++;
    }

    print "\tYour choice: ";

    my $choice = <STDIN>;
    chomp $choice;
    $choice;
}

sub isNum
{
    $_ = shift;
    return 1
	if( /(\d)+/ );

    return 0;
}
