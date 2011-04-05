#!/usr/bin/perl 

#use warnings;
use strict;
use XML::LibXML;

## Script processes output from GoogleGroupsScraper (http://saturnboy.com/2010/03/scraping-google-groups)
##
## Input: xml file directly from scraper. One file per google group. The input file name is provided as an argument at runtime.
##
## Output: File with yearly statistics on number of threads of specific lengths, number of posts by NRNB staff members
## number of posts per month.
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

## setup logfile
my $statsfile = $filename."-stats.txt";	
unless ( open(LOGFILE, ">$statsfile") )
       {
         print "could not open file $statsfile\n";
         exit;
 	}

## setup parser and specify input
my $parser = XML::LibXML->new();
my $dom = $parser->parse_file($inputxml);

## setup data structures and define staff members
my %stats = ();
my %binnedstats = ();
my %staffstats = ();
my %monthlystats = ();
my %yearlystats = ();
my %staff = ('Mike Smoot'=>'msmoot@ucsd.edu', 'Alexander Pico'=>'apico@gladstone.ucsf.edu', 
	'Peng-Liang Wang'=>'penwang2007@gmail.com', 'Kei Ono'=>'keiono@gmail.com', 'Keiichiro Ono'=>'kono@ucsd.edu', 
	'Scooter Morris'=>'scooter@cgl.ucsf.edu', 'Kristina Hanspers'=>'khanspers@gladstone.ucsf.edu', 'Trey Ideker'=>'trey@bioeng.ucsd.edu');
my %years = ("2007"=>1, "2008"=>2, "2009"=>3, "2010"=>4, "2011"=>5);
my %months = ("January"=>1, "February"=>2, "March"=>3, "April"=>4, "May"=>5, "June"=>6, "July"=>7, "August"=>8, "September"=>9, 
"October"=>10, "November"=>11, "December"=>12);

## start parsing tree
my $root = $dom->documentElement();  
my @topics = $root->getElementsByTagName('topic'); 

foreach my $topic (@topics) {
	
	## get number of posts in topic
    my @postselement = $topic->getElementsByTagName('posts');
    my @posts = $postselement[0]->getElementsByTagName('post'); ## there is only one 'posts' element per topic. This is the parent of 'post' elements.
    my $numposts = scalar(@posts);
    
    ## get date for post
    my $firstpost = $posts[0];
	my @dateelement = $firstpost->getElementsByTagName('date');
	my $date = $dateelement[0]->textContent;
	$date =~ m/,.(\d{4})/;
	my $year = $1;
	my $month = (split(" ", $date))[0];
	
	$yearlystats{$year}++;
	## record number of threads per month per year
	$monthlystats{$year}{$month}++;
	
	## record number of threads for each threadlength per year
	$stats{$year}{$numposts}++;
	if ($numposts == 1) {
		$binnedstats{$year}{'unanswered'}++;
	} elsif ($numposts > 1) {
		$binnedstats{$year}{'answered'}++;
	}	

	## get author information and record author information for each year
	my @authors = ();
	foreach my $p (@posts)
		{
		my @authorlist = $p->getElementsByTagName('author');
		foreach my $a (@authorlist)
			{
			my $author = $a->textContent;
			if (exists $staff{$author})
				{
				$staffstats{$year}{$author}++;
				}	
			}	
		}
}
## print results on screen and to file
print LOGFILE "Google groups stats\nYearly stats\n\n";
print LOGFILE "Year\tNumber of threads\n";


foreach my $k (sort {$years{$a} <=> $years{$b}} keys %yearlystats)
{
	print "year: $k, number of threads: $yearlystats{$k}\n";
	print LOGFILE "$k\t$yearlystats{$k}\n";
}

print LOGFILE "\n\nMonthly stats\n\n";
print LOGFILE "Year-Month\tNumber of threads\n";

foreach my $key (sort keys %monthlystats)
	{
	foreach my $month (sort {$months{$a} <=> $months{$b}} keys %{$monthlystats{$key} }) 
		{
		print "year: $key, month: $month, number of threads: $monthlystats{$key}{$month}\n";
		print LOGFILE "$key-$month\t$monthlystats{$key}{$month}\n";
		}
	}
print LOGFILE "\n\nYear\tUnanswered threads\tAnswered threads\n";

foreach my $year (sort keys %binnedstats)
	{
	print "year: $year, unanswered: $binnedstats{$year}{'unanswered'}, answered: $binnedstats{$year}{'answered'}\n";
	print LOGFILE "$year\t$binnedstats{$year}{'unanswered'}\t$binnedstats{$year}{'answered'}\n";
	}

print LOGFILE "\n\nYear\tThreadlength\tNumber of threads\n";

foreach my $key (sort keys %stats)
	{
	foreach my $threadlength (sort {$a <=> $b} keys %{$stats{$key}})
		{
		print "year: $key, threadlength: $threadlength, number of threads: $stats{$key}{$threadlength}\n";
		print LOGFILE "$key\t$threadlength\t$stats{$key}{$threadlength}\n";
		}
	}

print LOGFILE "\n\nStaff stats\n\n";
print LOGFILE "Year-Staff Member\tNumber of threads\n";

foreach my $key (sort keys %staffstats)
	{
	foreach my $staff (sort keys %{ $staffstats{$key} })
		{
		print "$key\t$staff\t$staffstats{$key}{$staff}\n";	
		print LOGFILE "$key-$staff\t$staffstats{$key}{$staff}\n";
		}
	}

print "\n\nDone\n\n";
close LOGFILE;
