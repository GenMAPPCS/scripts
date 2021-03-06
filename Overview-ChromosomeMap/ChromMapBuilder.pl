 #!/usr/bin/perl

use HashSpeciesList;

## This script reads in a species-specific chromosome information file and produces an xgmml chromosome map
## Input file needs to be organized as follows:
##
## Column 1: Gene ID (Ensembl)
## Column 2: Gene symbol
## Column 3: Chromosome number (for example 'chr1')
## Column 4: Strand (+/-)
## Column 5: Start position
## Column 6: Stop position
## Column 7: Gene type
##
## The script is hard-coded to only read in information about protein-coding genes
## Dependencies: Needs HashSpeciesList module and SpeciesList text file. 
## NOTE: As of 6/28/11, HashSpeciesList is non-functional so the SpeciesList text file is necessary to run.

#####################
## get species from user

#Define an array for checking input species codes
my %speciesTable = getSpeciesTable();

my @codeArray = ();
for my $key (sort keys %speciesTable){
	unless ($speciesTable{$key}[3] =~ /^\s*$/){
		push(@codeArray, lc($speciesTable{$key}[3]));
	}
}

#Define and hash for ensemblnames
my %ensemblname = ();
for my $key (sort keys %speciesTable){
	$ensemblname{lc($speciesTable{$key}[3])} = $key;
}

#Ask user for species
my $refcode = "";
while (!(in_array(\@codeArray, $refcode)))
	{
	print "\nEnter the two-letter species code: ";
	$refcode = <STDIN>;
	chomp ($refcode);
    $refcode = lc($refcode);
	}

my $speciesname = $ensemblname{$refcode};
print "species is $ensemblname{$refcode}\n";	

my $systemcode = "En".ucfirst($refcode);
       
## define xgmml output file
my $xgmml = $refcode."-ChromMap.xgmml";	
unless ( open(OUTFILE, ">$xgmml") )
       {
         print "could not open file $xgmml\n";
         exit;
 	}

## define file to track exceptions
my $exceptions = $refcode."-ChromMap-EX.txt";	
unless ( open(EX, ">$exceptions") )
       {
         print "could not open file $exceptions\n";
         exit;
 	}

print EX "Gene ID\tOriginal symbol\tNew symbol\n";
 	
print OUTFILE "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n";
print OUTFILE "<graph label=\"$speciesname Chromosome Map\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:cy=\"http://www.cytoscape.org\" xmlns=\"http://www.cs.rpi.edu/XGMML\"  directed=\"1\">\n";
print OUTFILE "<att name=\"documentVersion\" value=\"1.1\"/>
  <att name=\"documentVersion\" value=\"1.1\"/>
  <att name=\"networkMetadata\">
    <rdf:RDF>
      <rdf:Description rdf:about=\"http://www.cytoscape.org/\">
        <dc:type>N/A</dc:type>
        <dc:description>N/A</dc:description>
        <dc:identifier>N/A</dc:identifier>
        <dc:date>2011-05-26 10:00:00</dc:date>
        <dc:title>$speciesname Chromosome Map</dc:title>
        <dc:source>http://www.cytoscape.org/</dc:source>
        <dc:format>Cytoscape-XGMML</dc:format>
      </rdf:Description>
    </rdf:RDF>
  </att>\n";
  
print OUTFILE "  <att type=\"string\" name=\"backgroundColor\" value=\"#ffffff\"/>
  <att type=\"string\" name=\"SystemCode\" value=\"$systemcode\"/>\n";
  
######################

#Define input file with 7 columns
my $input = $refcode."-chr_gene_locations.txt";

# define data structures to store chromosome location information
# read input file once to establish chromosome structure

my %chroms = ();
my $currentchrom = "";
my $chromcounter = 0;
my %chrominfo = ();
my $number = ();
my $symbol = ();
my $ensembl = ();
my $start = ();
my $stop = ();
my $strand = ();
my $annot = ();
my %sortedgenes = ();

## max coordinates for network dimensions
my $maxx = 0;
my $maxy = 0;

## read chromosome map input file w
unless ( open(INPUT, $input) )
        {
        print "could not open file $input\n";
        next;
    	}

while (my $line = <INPUT>)
      {
      chomp $line;
      my @line = split("\t", $line);
      $ensembl = $line[0];
      $symbol = $line[1];
      
      if ($symbol =~ /</) ## check for superimposed notation of gene names (mainly in rat)
      	{
      	my $symboltemp = (split("<", $symbol))[0];	
      	print "New symbol: $symboltemp\n";
      	print EX "$ensembl\t$symbol\t$symboltemp\n";
      	$symbol = $symboltemp;
      	}
      	
      $number = $line[2];
      $strand = $line[3];
      $start = $line[4];
      $stop = $line[5];
      $annot = $line[6];  
      
      ## record chromosome structure for printing
      if ($number ne $currentchrom)
      	{
      	$chromcounter ++;
      	my $temp = (split (/chr/, $number))[1];
		
		if (($temp =~ m/\d+/) && !($temp =~ m/\D/) )  ## handle purely numeric chromosome names
			{
			if ($refcode eq 'dm')  ## exception for drosophila which has one chromosome that is purely numeric
				{
				foreach my $n (keys %chroms)
      			{
      			if ($chroms{$n} eq $temp)
      				{
      				$chroms{$number} = $chromcounter;	
      				}
      			else
      				{
      				$chroms{$number} = int($temp);
      				}
      			}	
				}
			else 
				{
				$chroms{$number} = int($temp);	
				}
			}
      	
      	else
      		{
      		$chroms{$number} = $chromcounter;	## handle non-numeric chromosome names
      		}
      	
      	$currentchrom = $number;
      	}
      	  
      if (($annot eq 'protein_coding')) ##collect information for protein coding genes only
      	{
      	$chrominfo{$number}{$ensembl}{'symbol'} = $symbol;
      	$chrominfo{$number}{$ensembl}{'start'} = int($start); 
      	$chrominfo{$number}{$ensembl}{'stop'} = int($stop);
      	$chrominfo{$number}{$ensembl}{'strand'} = $strand;
      	$chrominfo{$number}{$ensembl}{'annotation'} = $annot;
      	$sortedgenes{$ensembl} = int($start);	   ## create another hash that can easily be sorted based on start position
      	}
      } 

######################
## Print xgmml

my $startx = 100;
my $starty = 100;
my $counter = 0;

## print single Chromosome label at the top
print OUTFILE "<node label=\"Chromosome\" id=\"Chromosome\">
    <att type=\"string\" name=\"canonicalName\" value=\"Chromosome\"/>
	<graphics type=\"RECTANGLE\" h=\"1.0\" w=\"1.0\" 
    x=\"$startx\" y=\"$starty\" fill=\"#FFFFFF\" 
    cy:nodeLabelFont=\"SansSerif.bold-0-500\" cy:nodeLabel=\"Chromosome\"/>
 </node>\n";

foreach my $key (sort keys %chrominfo)
	{	
	## Print label node for each chromosome
	my $labely = $starty + ($chroms{$key})*600; ## add offset to create vertical rows
	my $genex = 500; ## reset genex to chromosome start
	my $label = (split('chr',$key))[1];
	
	print OUTFILE "<node label=\"$label\" id=\"$key\">
    <att type=\"string\" name=\"canonicalName\" value=\"$label\"/>
    <att type=\"string\" name=\"Chromosome number\" value=\"$label\"/>
    <graphics type=\"RECTANGLE\" h=\"1.0\" w=\"1.0\" 
	x=\"$startx\" y=\"$labely\" fill=\"#FFFFFF\" 
     cy:nodeLabelFont=\"SansSerif.bold-0-500\" cy:nodeLabel=\"$label\"/>
  </node>\n";
  
	foreach my $gene (sort {$sortedgenes{$a} <=> $sortedgenes{$b}} keys %sortedgenes)
			{
		
		if (exists $chrominfo{$key}{$gene}{'start'})
		{
			
		
		$counter ++; ## keep track of all genes
		my $geney = ();
		
		## add offset for each strand
		if ($chrominfo{$key}{$gene}{'strand'} eq '+')
			{
			$geney = $labely - 100;
			}
		elsif ($chrominfo{$key}{$gene}{'strand'} eq '-')
			{
			$geney = $labely + 100;
			}

		my $startint = $chrominfo{$key}{$gene}{'start'};  ##convert from string to int for calculation
		my $stopint = $chrominfo{$key}{$gene}{'stop'};

		my $length = ($stopint-$startint);
		my $width  = 0.01*$length;
		if ($width > 50)
			{
			$width  = 50;
			}
				
		print OUTFILE "<node label=\"$gene\" id=\"$gene\">
			<att type=\"string\" name=\"canonicalName\" value=\"$chrominfo{$key}{$gene}{'symbol'}\"/>
			<att type=\"string\" name=\"Strand\" value=\"$chrominfo{$key}{$gene}{'strand'}\"/>
			<att type=\"integer\" name=\"Start position\" value=\"$startint\"/>
			<att type=\"integer\" name=\"Stop position\" value=\"$stopint\"/>
			<att type=\"integer\" name=\"Length\" value=\"$length\"/>
			<att type=\"string\" name=\"Type\" value=\"$chrominfo{$key}{$gene}{'annotation'}\"/>
			<att type=\"string\" name=\"Chromosome number\" value=\"$label\"/>
			<att type=\"list\" name=\"__Ensembl $speciesname\">
				<att type=\"string\" value=\"$gene\"/>
			</att>
  		    <graphics type=\"RECTANGLE\" h=\"200.0\" w=\"60\" x=\"$genex\" y=\"$geney\" 
			fill=\"#CCCCCC\" cy:nodeLabelFont=\"SansSerif.bold-0-12\" cy:nodeLabel=\"$chrominfo{$key}{$gene}{'symbol'}\"/>
  		</node>\n";
  			
  		$genex = $genex + 60; # add spacer
  		
  		## record network size for determining corrdinates for centering the network
		if ($genex > $maxx)
			{
			$maxx = $genex;
			}
		if ($geney > $maxy)
			{
			$maxy = $geney;
			}
		}
		} ## end foreach gene
	} ## end foreach chromosome

## center x and y dependent on network size
#my $centerx = $maxx/2;
#my $centery = $maxy/2;

## hard-code center x and y
my $centerx = 8100;
my $centery = 8400;
my $zoom = 0.0216;

print OUTFILE "<att type=\"real\" name=\"GRAPH_VIEW_ZOOM\" value=\"$zoom\"/>
  <att type=\"real\" name=\"GRAPH_VIEW_CENTER_X\" value=\"$centerx\"/>
  <att type=\"real\" name=\"GRAPH_VIEW_CENTER_Y\" value=\"$centery\"/>\n";
print OUTFILE "</graph>\n";
close OUTFILE;
close INPUT;

print "number of protein coding genes: $counter\n";
print "Done!\n\n";

sub in_array
 {
     my ($arr,$search_for) = @_;
     my %items = map {$_ => 1} @$arr; # create a hash out of the array values
     return (exists($items{$search_for}))?1:0;
 }