#!/usr/bin/perl
 
#######
## This script processes co-expression data from GeneMania into a tab-delimited file for import to GenMAPP-CS
## Input: Files must be in sub-directory "coexp"
## Output: Tab-delimited text network file and tab-delimited edge attribute file
#######

#define input and output files
my @inputfiles = <coexp/*.txt>;

my $output = "CoExpression-".$cutoff."txt";
unless ( open(OUT, ">$output") )
       {
         print "could not open file $output\n";
         exit;
 	}
 	
my $attributes = "CoExpression-attr.txt";
unless ( open(ATTR, ">$attributes") )
       {
         print "could not open file $attribues\n";
         exit;
 	}

print OUT "GeneA\tGeneB\tInteraction type\n";
print ATTR "ID\tNumber of datasets\n";

#data structures

my %coexpression = ();
my %attributes = ();
my $genea = ();
my $geneb = ();
my $weight = ();
my @datasets = ();
my $cutoff = 0.003;

#loop through input files 

foreach my $input (@inputfiles)
	{
	print "processing $input...\n";
	unless ( open(INPUT, $input) )
        {
        print "could not open file $input\n";
        next;
    	}
    
#    my $dataset = (split("\\.", $input))[1]; ## record dataset name
#    push (@datasets, $dataset);
    
    while (my $line = <INPUT>)
    	{
    	unless ($line =~ /gene_a/) ## ignore header line
    		{
    		chomp $line;
      		my @line = split("\t", $line);
      		$genea = $line[0];
      		$geneb = $line[1];
      		$weight = $line[2];

			my $weightdecimal = sprintf("%.10g", $weight);  ## transform from exp notation to float
			
			if ($weightdecimal < $cutoff) 
				{
				$counter ++;
				print OUT "$a\t$b\tco-expression\n";
				}
			      		
      		my $interaction = $genea." (co-expression) ".$geneb;
      	
      		if (exists($attributes{$interaction}))
      			{
      			my $temp = 	$attributes{$interaction};
      			$temp ++;
      			$attributes{$interaction} = $temp;
      			}
      		else
				{
				$attributes{$interaction} = 1;
				}
    		}
    	}
    close INPUT;
	}

## print attribute file	

foreach my $i (keys %attributes)
	{
	print ATTR "$i\t$attributes{$i}\n";
	}
	
print "$counter interactions written to $output. Done!\n";

close OUT;
close ATTR;
