#!/usr/bin/env perl

use strict;
use warnings;

sub appendToFile(\%$);

our @alreadyPresent;

#print "$#ARGV\n";
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
	if( /^(?:alias )(["]?[(\w|\.)+\s]+["]?)(?: .*@.*)+/ )
	{
	   $flag = 1; 
	}

	push @alreadyPresent, $1
	    if( $flag == 1 );
    }

    foreach( @matched )
    {
	my ($flag, $repeatOuter, $repeatInner) = (0, 1, 1);
	if( /^(?:alias )(["]?[(\w|\.)+\s]+["]?)( .*@.*)+/ )
	{
	    $flag = 1; 
	}

	if( ($flag == 1) && (defined $1) && (defined $2) )
	{
	    my $name = $1;
	    my $emails = $2;
	    while( $repeatOuter )
	    {
		$repeatInner = 1;
		print "Name:\t$name\n";
		print "Emails:\t$emails\n";
	       
		my $choice = printGroupMenu(%groupsToEmails);
		my @groups = sort keys %groupsToEmails;
		if( isNum($choice) && ($choice >= 0) && ($choice <= $#groups))
		{
		    my $previousEmails = $groupsToEmails{$groups[$choice]};
		    $previousEmails .= $emails;
		    $groupsToEmails{$groups[$choice]} = $previousEmails;
		    $repeatOuter = 0;
		}
		else
		{
		    for( $choice )
		    {
			if(/^(n|N)$/)
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
				       (grep /^["]?$newGroup["]?$/, @alreadyPresent) ) 
				{
				    print "This group already exists, please choose a different name.\n";
				}
				else
				{
				    $emails = substr($emails, 1)
					if( $emails =~ /^\s/ );
				    $groupsToEmails{$newGroup} = $emails;
				    $repeatOuter = 0;
				    $repeatInner = 0;
				}
			    }			    
			}
			elsif(/^(q|Q)$/)
			{
			    appendToFile(%groupsToEmails, $fileName);
			    exit;
			}
			elsif(/^(s|S)$/)
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
	if( ($#groups) >= 0 );
    my $i = 0;
    foreach( @groups )
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
	if( /^\d+$/ );

    return 0;
}
