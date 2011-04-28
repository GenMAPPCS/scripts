#!/usr/bin/perl 

use warnings;
use strict;
use XML::LibXML;
use Encode;

## Script processes output from GoogleGroupsScraper (http://saturnboy.com/2010/03/scraping-google-groups)
##
## Input: one or more xml files directly from scraper. One file per google group. The input file name is provided as an argument at runtime.
##
## Output: File with list of unanswered posts in the last week. Topic, author name and date is recorded.
## The output is written to an existing file, with the existing contents preserved (adds at the top of the file)
## This report file can be posted on a website or emailed.
##
## This parser requires the XML::LibXML perl module. Install this from CPAN with the following commands:
## perl -MCPAN -e shell
## at cpan prompt: install XML::LibXML 


## setup logfile and read in contents. 
## rather than appending, this method (reading / overwriting) allows for adding new content at the beginning of file.
my $statsfile = "/var/www/meta/trunk/nrnb/helpdesk.html";
#my $log = ""; #scalar to store existing contents of log file
	
unless ( open(LOGFILE, ">$statsfile") )   ## open existing file, if fail create new and open for output
       {
#	   unless ( open(LOGFILE, ">$statsfile") )
#       		{
        	print "opening new file $statsfile failed.\n";
        	exit;
#       		}
	  
       }

#else    ## read from existing file, then open the same file for output
#	{
	## store old log contents (excluding header)
#	while (<LOGFILE>) {
#		$log .= $_ unless 1 .. /^<hr>/;
#	}
#	unless ( open(LOGFILE, ">$statsfile") )
#      		{
#        	print "opening $statsfile for output failed.\n";
#        	exit;
#       		}	
#	}

## print header
print LOGFILE "<html><head><title>Mailing List Triage</title></head><body><b><font size='+2'>Mailing List Triage</font></b>\n";

## define date range: last week
my $currenttime = time(); 		
my $cutoff = $currenttime - 4*604800; #define last 4 weeks in epoch timestamp, 604800 is number of seconds in epoch format
my $new = $currenttime - 604800; #define last week to distinguish new from old reports (highlighted in red)
my $startdate = localtime($cutoff);  ## switch format for readability
my $enddate = localtime($currenttime);
print LOGFILE "<hr>\n";
print LOGFILE "<b>Updated $enddate</b><br>\n";
print LOGFILE "<font style=\"color:blue;\"><u>blue</u> = new unanswered email</font><br>\n";
print LOGFILE "<font style=\"color:red;\"><u>red</u> = previously assigned, but still unanswered</font><br>\n";
print LOGFILE "<br><table cellspacing='10'>\n";
print LOGFILE '<thead><tr><th>Topic</th><th>Author</th><th>Date</th></tr>'."\n";

## loop through files
foreach my $inputxml (@ARGV) {

if (!($inputxml =~ /\.xml/))
	{
        print "Incorrect argument for input filename. Try again.\n";
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

## print out mailing list subheader
print LOGFILE '<tr><td><a href="http://groups.google.com/group/'.$filename.'?hl=en_US\" style="color:black;">'.$filename.'</a></td><td></td><td></td></tr>'."\n";


## setup parser and specify input
my $parser = XML::LibXML->new();
my $dom = $parser->parse_file($utffile);
unlink($utffile); #delete temp file

## start parsing tree
my $root = $dom->documentElement();  
my @topics = $root->getElementsByTagName('topic'); 

foreach my $topic (@topics) {
	
	## get topic title
	my @title = $topic->getElementsByTagName('title');
	my $title = $title[0]->textContent;

        ## get link
        my @link = $topic->getElementsByTagName('link');
        my $link = $link[0]->textContent;
	
	## get number of posts in topic
    my @postselement = $topic->getElementsByTagName('posts');
    my @posts = $postselement[0]->getElementsByTagName('post'); ## there is only one 'posts' element per topic. This is the parent of 'post' elements.
    my $numposts = scalar(@posts);
    my $firstpost = $posts[0];
 	#check for blank posts
 	if (!defined($firstpost)){
 		next;
 	}
	
	## get author information
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
			my $color = 'blue';
			if ($timestamp < $new ) {$color = 'red';}
			my $time = localtime($timestamp);
			print LOGFILE '<tr><td><a href="'.$link.'" style="color:'.$color.';">'.$title.'</a></td><td>'.$author.'</td><td>'.$time.'</td></tr>'."\n";
			}
	}	
	}
} #end foreach topic
} #end foreach input file

print LOGFILE "</table></body></html>\n";
#print LOGFILE "<hr>\n$log\n"; ## print old contents of logifle at the end of file
print "Done\n";
close LOGFILE;
