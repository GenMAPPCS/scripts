 #!/usr/bin/perl
 
use File::ReadBackwards; 

#####################
## This script parses a tab-delimited export of the GSoC Alumni list, available as Google doc (spreadsheet)
## The output is a formatted definition list in html, with sublists for each year
## The final list goes into alumni.html in the gsoc directory of the NRNB website. The file is marked with a comment where the list should be pasted.
## NOTE: Stats for each year have to be manually added to each yearly sublist after the list is copied into alumni.html.
## Stats are:
## 2007  4/4 passing students, 100%
## 2008  8/9 passing students, 89%
## 2009  9/10 passing students, 90%
## 2010  10/10 passing students, 100%
## 2011  9/10 passing students, 90%

#Open input file
my $in = File::ReadBackwards->new("GSoCAlumni.txt") or die; 
                        
#Define output file
my $out = "GSoCAlumni-html.txt";	
unless ( open(HTML, ">$out") )
       {
         print "could not open file $out\n";
         exit;
 	}

my %years = ();

my $line;
while (defined($line = $in->readline))  ##Using ReadBackwards to read in file line-by-line from the end
	{
		chomp $line;
    	my @line = split("\t", $line);
    	my $year = $line[0];
    	if ($year =~ /Year/) {next;} ##Skip header row
   		
       	unless (exists $years{$year}){
    		print "new year: $year\n";
    	
    		$years{$year} = $year;  ##Assign it to years
    		if (scalar(keys %years) == 1) ##For the first sublist (year), don't add the closing </dt> tag at the top.
    			{
    			print HTML "<div id=\"subtitletext\" class=\"red\">".$year."</div>\n";
		   		print HTML "<div id=\"alumni-list\">\n<dl>\n";	
    			}
    		else ##For each new sublist (year), add the closing </dt> tag at the top.
    			{
    			print HTML "</dl>\n</div>";
    			print HTML "<div id=\"subtitletext\" class=\"red\">".$year."</div>\n";
    			print HTML "<div id=\"alumni-list\">\n<dl>\n";	
    			}
    		
    		}  
    	my $student = $line[1];
    	my $university = $line[6];
    	my $city = $line[4];
    	my $country = $line[5];
    	my $project = $line[2];	
    	print HTML "<dt><b class=\"blue\">".$student."</b> - ".$university.", ".$city.", ".$country."</dt>\n";
    	print HTML "<dd>".$project."</dd>\n";
		
	}

$in->close();
print HTML "</dl>\n</div>";
close HTML;

print "Done!\n\n";