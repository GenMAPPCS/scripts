#!/usr/bin/perl 

use warnings;
use strict;
use XML::LibXML;
use Encode;

##
## Input: xml file from APRSIS. The input file name is provided as an argument at runtime.
##
## Output:
## 1. Persons and attrs (PersonID, FullName, NonhostName, NonhostCountry)
## 2. Subprojects and attrs (Sub_ID, Title, Type)
## 3. Publiciations and attrs (PublicationID, PMUID)
## 4. Person-subproject links and attr (Investigator_Type)
## 5. Paper-subproject links
##
## This parser requires the XML::LibXML perl module. Install this from CPAN with the following commands:
## perl -MCPAN -e shell
## at cpan prompt: install XML::LibXML 

## get input filename
my $inputxml = "";
if (scalar(@ARGV) == 1)
        {
        $inputxml = $ARGV[0];
        if (!($inputxml =~ /\.xml/))
                {
                print "Incorrect argument for input filename. Try again.\n";
                exit;
                }
        }
else
        {
        print "Too many arguments. Try again.\n";
        exit;
        }

my $filename = (split(".xml", $inputxml))[0];

## convert to utf-8 and scrub error lines
my $utffile = $filename."-utf.xml";
open (XML, "$inputxml") or die "Can't open $inputxml: $!";
open (UTF, ">$utffile") or die "Can't open $utffile: $!";
while (<XML>){
        my $line = $_;
        unless ($line =~ /^ERROR:/){
                print UTF encode('utf8', $line);
        }
}
close XML;
close UTF;

## setup output files
my $personsattrs = $filename."-persons_1.txt";
unless ( open(PERSONS, ">$personsattrs") )
       {
         print "could not open file $personsattrs\n";
         exit;
        }
print PERSONS "PersonID\tFullName\tNonHostName\tNonHostCountry\n";

my $subprojectattrs = $filename."-subprojects_2.txt";
unless ( open(SUBPROJECTS, ">$subprojectattrs") )
       {
         print "could not open file $subprojectattrs\n";
         exit;
        }
print SUBPROJECTS "Sub_ID\tTitle\tType\n";

my $projectnetwork = $filename."-person-subproject_4.txt";
unless ( open(PERSONTOSUBPROJECT, ">$projectnetwork") )
       {
         print "could not open file $projectnetwork\n";
         exit;
        }
print PERSONTOSUBPROJECT "Investigator\tSubproject\tInvestigator Type\n";

my $publicationattrs = $filename."-publications_3.txt";
unless ( open(PUBLICATIONS, ">$publicationattrs") )
       {
         print "could not open file $publicationattrs\n";
         exit;
        }
print PUBLICATIONS "PublicationID\tPMUID\n";

my $pubstoprojects = $filename."-publication-subproject_5.txt";
unless ( open(PUBSTOPROJECT, ">$pubstoprojects") )
       {
         print "could not open file $pubstoprojects\n";
         exit;
        }
print PUBSTOPROJECT "PublicationID\tPMUID\n";

## Combined file with links between subproject-paper and subproject-person. One edge attribute for investigator
## type, only appplicable for part of the data
my $combinednetwork = $filename."-combined_network.txt";
unless ( open(COMBINED, ">$combinednetwork") )
       {
         print "could not open file $combinednetwork\n";
         exit;
        }
print COMBINED "Project\tPublication/Person\tInvestigator Type\n";

## setup parser and specify input
my $parser = XML::LibXML->new();
my $dom = $parser->parse_file($utffile); 
unlink($utffile); #delete temp file

## start parsing tree
my $root = $dom->documentElement();  
 
########## 
## Get persons

my @persons = $root->getElementsByTagName('Person');

foreach my $person (@persons) {
	
	my $nonhostCountry = '';
	my $nonhostName = '';
	
	my $personID = $person->getAttribute('Person_ID');
	my $fullName = $person->getElementsByTagName('Full_Name');
	
	if ($person->getElementsByTagName('Nonhost_Name') && $person->getElementsByTagName('Nonhost_Country'))
		{
		$nonhostCountry = $person->getElementsByTagName('Nonhost_Country');
		$nonhostName = $person->getElementsByTagName('Nonhost_Name');	
		}
	else ## if blank, use UCSD
		{
		$nonhostName = 'UCSD';
		$nonhostCountry = 'USA';
		}
	
	print PERSONS "$personID\t$fullName\t$nonhostName\t$nonhostCountry\n";
}

##########
## Get subprojects

my @subprojects = $root->getElementsByTagName('Subproject'); 
	
foreach my $subproject (@subprojects) {
	
	my $subID = $subproject->getAttribute('Sub_ID');
	my $subType = $subproject->getElementsByTagName('Type');
	my $subTitle = $subproject->getElementsByTagName('Title');
	
	$subTitle =~ s/\n/ /sg;  ##substitute newline for space
	
	if ($subproject->getElementsByTagName('Publication_ID')) {
		
		my $pubID = $subproject->getElementsByTagName('Publication_ID'); ## if multiple pubIDs, this produces a multi-ID string

		if (length($pubID) > 6) {

			#my @pmuids = split(/(\d{6})/, $pubID);  ## this produces an array with a null string at every other element 
			my @pmuids = $pubID =~ m/(\d{6})/g;
			foreach my $p (@pmuids) {
			print PUBSTOPROJECT "$subID\t$p\n";
			print COMBINED "$subID\t$p\tNA\n";
			}
		}
	
		else {
			print PUBSTOPROJECT "$subID\t$pubID\n";
			print COMBINED "$subID\t$pubID\tNA\n";
		}
	}
	
	print SUBPROJECTS "$subID\t$subTitle\t$subType\n";
	
	my @investigators = $subproject->getElementsByTagName('Investigator');
	
	foreach my $investigator (@investigators) {
		my $personID = $investigator->getElementsByTagName('Person_ID');
		my $investigatorType = $investigator->getElementsByTagName('Investigator_Type');
		
		print PERSONTOSUBPROJECT "$personID\t$subID\t$investigatorType\n";
		print COMBINED "$subID\t$personID\t$investigatorType\n";
	}
}

##########

## Get publications
my @publications = $root->getElementsByTagName('Publication'); 

foreach my $publication (@publications)	{
	
	my $publicationID = $publication->getAttribute('Publication_ID');
	my $PMUID = $publication->getElementsByTagName('PM_UID');
	
	print PUBLICATIONS  "$publicationID\t$PMUID\n";
}

##########

print "\n\nDone\n\n";
close PERSONS;
close PUBLICATIONS;
close SUBPROJECTS;
close PUBSTOPROJECT;
close PERSONTOSUBPROJECT;
