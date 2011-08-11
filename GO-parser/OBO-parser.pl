 #!/usr/bin/perl

## This script takes an obo file and creates two files:
## 1. sif file. For each GO term, any "is_a" term is recorded as an interaction.
## Input file name is hard-coded.
## 2. text file listing GO term ID and GO term name
## 
## Required input: GO obo file, either from full or slim GO
##
## NOTE: input file names are hard-coded. Slim version is commneted out.
## 

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

## define go structure outfile
my $out = "gene-ontology.txt";
#my $out = "gene-ontology_slim.txt";
unless ( open(OUTFILE2, ">$out") )
       {
         print "could not open file $out\n";
         exit;
       }

print OUTFILE2 "ID\tName";

#Define input file
my $inputfile = "gene_ontology_ext.obo";
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
my $ID = "";
my $name = "";
my %go = ();

@input = split(/\[Term\]/, $input);

foreach my $i (@input)
{ 
	my $term = (split(/\[Typedef\]/,$i))[0];   ## remove extra info at the end of file
	my @lines = split(/\n/, $term);
	
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
			$ID = $1;
			}
		elsif ($line =~ /name:\s.+/) 
			{
			$line =~ /name:\s(.+)/;
			$name = $1;	
			}
		elsif ($line =~ /is_a:\sGO:\d+/)
			{
			$line =~ /is_a:\s(GO:\d+)/;	
			my $intB = $1;
			print OUTFILE "$intA\tis a\t$intB\n";  ## print sif file
			}
		$go{$ID} = $name;
	}
}

foreach my $k (sort keys %go)
	{
	print OUTFILE2 "$k\t$go{$k}\n";	  ## print text file
	}
close OUTFILE;
close OUTFILE2;
close INPUT;

print "Done!\n\n";