#!/usr/bin/perl 

use warnings;
use strict;
use XML::LibXML;
use Encode;

## Script processes output from GoogleGroupsScraper (http://saturnboy.com/2010/03/scraping-google-groups)
##
## Input: xml file directly from scraper. One file per google group. The input file name is provided as an argument at runtime.
##
## Output: File with list of unanswered posts in the last week. Topic, author name and date is recorded.
## The output is written to an existing file, with the existing contents preserved (adds at the top of the file)
## This report file can be posted on a website or emailed.
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
        
## setup logfile and read in contents. 
## rather than appending, this method (reading / overwriting) allows for adding new content at the beginning of file.
my $statsfile = $filename."-weekly.txt";
my $log = ""; #scalar to store existing contents of log file
	
unless ( open(LOGFILE, "<$statsfile") )   ## try to open existing file, if fail create new and open for output
       {
	   unless ( open(LOGFILE, ">$statsfile") )
       		{
        	print "opening new file $statsfile failed.\n";
        	exit;
       		}
       }

else    ## read from existing file, then open the same file for output
	{
	read (LOGFILE, $log, 1000000);	
	unless ( open(LOGFILE, ">$statsfile") )
       		{
        	print "opening $statsfile for output failed.\n";
        	exit;
       		}	
	}

## setup parser and specify input
my $parser = XML::LibXML->new();
my $dom = $parser->parse_file($utffile); 
unlink($utffile); #delete temp file

## define date range: last week
my $currenttime = time();
my $cutoff = $currenttime - '604800'; #define last week in epoch timestamp
my $startdate = localtime($cutoff);
my $enddate = localtime($currenttime);
print LOGFILE "Unanswered email for the week of $startdate - $enddate\n";
print LOGFILE "Topic\tAuthor\tDate\n";

## setup data structures and define staff members
my %binnedstats = ();

## start parsing tree
my $root = $dom->documentElement();  
my @topics = $root->getElementsByTagName('topic'); 

foreach my $topic (@topics) {
	
	my @title = $topic->getElementsByTagName('title');
	my $title = $title[0]->textContent;
	
	## get number of posts in topic
    my @postselement = $topic->getElementsByTagName('posts');
    my @posts = $postselement[0]->getElementsByTagName('post'); ## there is only one 'posts' element per topic. This is the parent of 'post' elements.
    my $numposts = scalar(@posts);
    
    ## get date for post
    my $firstpost = $posts[0];
 	#check for blank posts
 	if (!defined($firstpost)){
 		next;
 	}
	my @dateelement = $firstpost->getElementsByTagName('date');
	my $date = $dateelement[0]->textContent;
	$date =~ m/,.(\d{4})/;
	my $year = $1;
	my $month = (split(" ", $date))[0];
	
	my @author = $firstpost->getElementsByTagName('author');
	my $author = $author[0]->textContent;	
	
	## find and print unnswered posts in the last week
	my @timestamp = $firstpost->getElementsByTagName('timestamp');
	my $timestamp = $timestamp[0]->textContent;
	
	unless ($timestamp eq "" )
	{
		if ($timestamp > $cutoff)
	{
		#print "post from the last week!\n";
		if ($numposts == 1) 
			{
			my $time = localtime($timestamp);
			print LOGFILE "$title\t$author\t$time\n";
			}
	}	
	}
}

print LOGFILE "$log\n\n"; ## print old contents of logifle at the end of file
print "\n\nDone\n\n";
close LOGFILE;
