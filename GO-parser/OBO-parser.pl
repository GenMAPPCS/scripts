 #!/usr/bin/perl

## This script takes an obo file and creates a sif file.
## For each GO term, any "is_a" term is recorded as an interaction.
## Input file name is hard-coded.
## 
## Required input: GO obo file 

#####################
## define input and output
       
## define sif output file
my $sif = "gene-ontology.sif";	
#my $sif = "gene-ontology_slim.sif";	
unless ( open(OUTFILE, ">$sif") )
       {
         print "could not open file $sif\n";
         exit;
 	}

#Define input file
my $inputfile = "gene-ontology.obo";
#my $inputfile = "goslim_generic.obo";
my $input = "";
my @input = ();

## read chromosome map input file w
unless ( open(INPUT, $inputfile) )
        {
        print "could not open file $inputfile\n";
        next;
    	}

$input = join("", <INPUT>); ##read in as one line
my $intA = "";

@input = split(/\[Term\]/, $input);

foreach my $i (@input)
{ 
	my @lines = split(/\n/, $i);
	
	foreach my $line (@lines)
	{
		if ($line =~ /alt_id:\sGO:\d+/)  ## avoid lines starting with alt_id
			{
			next;
			}
		elsif ($line =~ /id:\sGO:\d+/)
			{
			$line =~ /id:\s(GO:\d+)/;
			$intA = $1;
			}
		elsif ($line =~ /is_a:\sGO:\d+/)
			{
			$line =~ /is_a:\s(GO:\d+)/;	
			my $intB = $1;
			print OUTFILE "$intA\tis a\t$intB\n";
			}
		
	}
}

close OUTFILE;
close INPUT;

print "Done!\n\n";