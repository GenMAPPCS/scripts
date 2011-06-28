#!/usr/bin/perl

#######
## This script processes shared domain data from GeneMania into a tab-delimited file for import to GenMAPP-CS
## Input: flat files, for PFAM and INTERPRO data (and for some species additional files). Files need to be in the same directory as the script
## Input files are available here: http://genemania.org/data/
## Output: Tab-delimited text network file
#######

# Ask user for species name for file naming
print "\nEnter the two-letter species code: ";
$refcode = <STDIN>;
chomp ($refcode);
$refcode = lc($refcode);
    
#define input and output files
my $interpro = $refcode."-Shared_protein_domains.INTERPRO.txt";
my $pfam = $refcode."-Shared_protein_domains.PFAM.txt";
my @inputfiles = ($interpro, $pfam);


if ($refcode eq 'at')
	{
	my $extra = $refcode."-Shared_protein_domains.Lee-Rhee-2010_Shared_protein_domains.txt";  ## file exists for At only
	push(@inputfiles, $extra);
	}

my $lowercutoff = 0.002;
my $cutoff = 0.007;

my $output = $refcode."-SharedDomains-".$cutoff."txt";
unless ( open(OUT, ">$output") )
       {
         print "could not open file $output\n";
         exit;
 	}

#data structures

my %shareddomains = ();
my $genea = ();
my $geneb = ();
my $weight = ();

#loop through input files 

foreach my $input (@inputfiles)
	{
	print "Processing $input\n";
	unless ( open(INPUT, $input) )
        {
        print "could not open file $input\n";
        next;
    	}
    	
    while (my $line = <INPUT>)
    	{
    	chomp $line;
      	my @line = split("\t", $line);
      	$genea = $line[0];
      	$geneb = $line[1];
      	$weight = $line[2];
      	
      	if ($input =~ /INTERPRO/)
      		{
      		$shareddomains{$genea}{$geneb}{'interpro'} = $weight;	
      		}
      	elsif ($input =~ /PFAM/)
      		{
      		$shareddomains{$genea}{$geneb}{'pfam'} = $weight;	
      		}
      	elsif ($input =~ /Lee-Rhee-2010_Shared_protein_domains/)
      		{
      		$shareddomains{$genea}{$geneb}{'Lee-Rhee-2010'} = $weight;	
      		}
    	}
	}
	
#### print to table

my $counter = ();

if ($refcode eq 'at')
	{
	print OUT "GeneA\tGeneB\tPFAM\tINTERPRO\tLee-Rhee-2010\tInteraction type\n";	
	}
	
else 
	{
	print OUT "GeneA\tGeneB\tPFAM\tINTERPRO\tInteraction type\n";
	}
	
	
foreach my $genea (keys %shareddomains)
	{
	foreach my $geneb (keys %{$shareddomains{$genea}})
		{
		my $interprodecimal = sprintf("%.10g", $shareddomains{$genea}{$geneb}{'interpro'});
		my $pfamdecimal = sprintf("%.10g", $shareddomains{$genea}{$geneb}{'pfam'});
		
		if ($refcode eq 'at')
			{
			my $extradecimal = sprintf("%.10g", $shareddomains{$genea}{$geneb}{'Lee-Rhee-2010'});	
			
			if (($interprodecimal < $cutoff) && ($pfamdecimal < $cutoff) && ($extradecimal < $cutoff)) 
				{
				$counter ++;
				print OUT "$genea\t$geneb\t$pfamdecimal\t$interprodecimal\t$extradecimal\tShared domains\n";
				}
			}
		
		elsif ($refcode eq 'mm')
			{
			if (($interprodecimal < $cutoff) && ($interprodecimal > $lowercutoff) && ($pfamdecimal < $cutoff) && ($pfamdecimal > $lowercutoff)) 
				{
				$counter ++;
				print OUT "$genea\t$geneb\t$pfamdecimal\t$interprodecimal\tShared domains\n";
				}	
			}
		else 
			{
			if (($interprodecimal < $cutoff) && ($pfamdecimal < $cutoff)) 
				{
				$counter ++;
				print OUT "$genea\t$geneb\t$pfamdecimal\t$interprodecimal\tShared domains\n";
				}	
			}
		
		}
	}

print "$counter interactions written to $output. Done!\n";
