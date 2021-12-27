# Romanian chunker extracted from TTL.
#
# TTL and all included Perl modules is (C) Radu Ion (radu@racai.ro) and ICIA 2005-2018.
# Permission is granted for research and personal use ONLY.
#
# Tokenizing, Tagging and Lemmatizing free running text: TTL
#
# For the full TTL see the TEPROLIN repo: https://github.com/racai-ai/TEPROLIN
# And directly the TTL sub-folder: https://github.com/racai-ai/TEPROLIN/tree/master/ttl
#
package pdk::ttl;

use warnings;
use strict;
# ver 9.1: removed use lib as it is already given
# from the main calling script.
use rxgram;

my( $UTF8HEAD ) = "\x{ef}\x{bb}\x{bf}";

#5.0
sub readNERGrammar( $$ );
sub readNERFilter( $$ );
#end 5.0
sub endProcessing( $ );

#ver 7.0 chunker
#Input: object and a $tagsent for tagger
sub getBlocks( $$ );
#Input: object and the output from getBlocks()
sub arrangeBlocks( $$ );
sub confchunker( $$ );
#Input: object and a $tagsent for tagger
sub chunker( $$ );


#5.0
sub readNERGrammar( $$ ) {
	my( $this ) = shift( @_ );
	my( $grmFile ) = $_[0];
	my( $nterm, $grmm ) = rxgram::parseGrammar( $grmFile );

	return { "NTERM" => $nterm, "GRAMMAR" => $grmm };
}

sub readNERFilter( $$ ) {
	my( $this ) = shift( @_ );
	my( $filterFile ) = $_[0];
	my( $lcnt ) = 0;
	my( %rxfilter ) = ();

	open( RXFLT, "< " . $filterFile ) or die( "ttl::readNERFilter : cannot open \'$filterFile\' !\n" );
	
	while ( my $line = <RXFLT> ) {
		$lcnt++;
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;

		next if ( $line =~ /^$/ || $line =~ /^#/ );

		if ( $line =~ /^apply\s+([^\s]+)\s+priority\s+([^\s]+)\s+ctag\s+([^\s]+)\s+msd\s+([^\s]+)\s+emsd\s+([^\s]+)$/ ) {
			my( $ssymb, $nice, $ctagval, $msdval, $emsdval ) = ( $1, $2, $3, $4, $5 );

			if ( exists( $rxfilter{$ssymb} ) ) {
				die( "ttl::readNERFilter : the start symbol \'$ssymb\' is duplicated @ line $lcnt !\n" );
			}
			else {
				$rxfilter{$ssymb} = { "CTAG" => $ctagval, "NICE" => $nice, "MSD" => $msdval, "EMSD" => $emsdval };
			}
		}
		elsif ( $line =~ /^skip\s+([^\s]+)\s+priority\s+([^\s]+)\s+ctag\s+([^\s]+)\s+msd\s+([^\s]+)\s+emsd\s+([^\s]+)$/ ) {
			#Nothing ... :)
		}
		else {
			die( "ttl::readNERFilter : syntax error @ line $lcnt !\n" );
		}
	}

	close( RXFLT );

	return \%rxfilter;
}
#end 5.0

#end 5.5


########################### Revise 7.0 #############################################
sub getBlocks( $$ ) {
	my( $this ) = shift( @_ );
	my( $CONFCHUNK ) = $this->{"CONFCHUNK"};
	my( $grammar ) = $CONFCHUNK->{"GRAMMAR"};
	my( @ssyms ) = @{ $CONFCHUNK->{"CHUNKS"} };
	my( $MAXLINELEN ) = $CONFCHUNK->{"MAXLINELEN"};
	my( $DEBUG ) = $CONFCHUNK->{"DEBUG"};
	my( @sent ) = @{ $_[0] };
	my( @chunks ) = ();
	#8.5
	my( @reclines ) = ();
	my( @crtrecline ) = ();

        my( %phashrev ) = (
        "EURO" => 1,
        "BULLET" => 1,
        "LCURL" => 1,
        "RCURL" => 1,
        "UNDERSC" => 1,
        "POUND" => 1,
        "HYPHEN" => 1,
        "EXCL" => 1,
        "EXCLHELLIP" => 1,
        "COMMA" => 1,
        "DASH" => 1,
        "PERIOD" => 1,
        "HELLIP" => 1,
        "COLON" => 1,
        "SCOLON" => 1,
        "QUEST" => 1,
        "QUESTHELLIP" => 1,
        "SLASH" => 1,
        "BSLASH" => 1,
        "LPAR" => 1,
        "RPAR" => 1,
        "LSQR" => 1,
        "RSQR" => 1,
        "AMPER" => 1,
        "DBLQ" => 1,
        "EQUAL" => 1,
        "PLUS" => 1,
        "QUOT" => 1,
        "STAR" => 1,
        "STAR2" => 1,
        "STAR3" => 1,
        "TILDA" => 1,
        "BQUOT" => 1,
        "GE" => 1,
        "LE" => 1,
        "GT" => 1,
        "LT" => 1,
        "DOLLAR" => 1,
        "PERCENT" => 1,
        "CAP" => 1,
        "OR" => 1,
        #French punctuation
        "PUN" => 1,
        "SENT" => 1,
        "SYM" => 1,
        #End.
        "_PUNCT" => 1
        );

	foreach my $t ( @sent ) {
		#8.5
		#If it's punctuation, split the sequence of CTAGS to match against regex.
		if ( exists( $phashrev{$t} ) ) {
			push( @crtrecline, "<" . $t . ">" );
			push( @reclines, join( "", @crtrecline ) );
			@crtrecline = ();
		}
		else {
			push( @crtrecline, "<" . $t . ">" );
		}
	}
	
	#8.5
	if ( scalar( @crtrecline ) > 0 ) {
		push( @reclines, join( "", @crtrecline ) );
		@crtrecline = ();
	}

	foreach my $ss ( @ssyms ) {
		die ( "ttl::getBlocks: $ss is not a production !\n" ) if ( ! exists( $grammar->{$ss} ) );
		
		my( @ssrules ) = @{ $grammar->{$ss} };

		die ( "ttl::getBlocks: $ss has more than one regular expression associated !\n" ) if ( scalar( @ssrules ) > 1 );

		my( $r ) = $ssrules[0];
		#8.5
		my( @block ) = ();
		
		#8.5
		foreach my $recline ( @reclines ) {
			#Acount for < and >
			if ( length( $recline ) > 3 * $MAXLINELEN ) {
				warn( "ttl::getBlocks: recline length is '" . length( $recline ) . "'! Skipping...\n" )
					if ( $DEBUG );
				next;
			}
			
			while ( $recline =~ /($r)/g ) {
				push( @block, $1 );
			}
		}
		
		my( $cnt ) = 1;

		foreach my $e ( @block ) {
			my( $te ) = $e;

			$te =~ s/^<//;
			$te =~ s/>$//;

			my( @tags ) = split( /></, $te );
			my( @rtags ) = ();
			my( $at ) = -1;
			my( $len ) = scalar( @tags );

			for ( my $i = 0; $i < scalar( @sent ); $i++ ) {
				#Le sarim pe alea adnotate.
				next if ( exists( $chunks[$i] ) && exists( ( $chunks[$i] )->{$ss} ) );

				if ( $sent[$i] eq $tags[0] ) {
					if ( scalar( @rtags ) == 0 ) {
						$at = $i;
					}
					
					push( @rtags, shift( @tags ) );
					last if ( scalar( @tags ) == 0 );
				}
				else {
					if ( scalar( @tags ) < $len ) {
						unshift( @tags, @rtags );
						@rtags = ();
						$at = -1;
					}
				}
			}
			
			if ( $at >= 0 ) {
				for ( my $i = $at; $i < $at + $len; $i++ ) {
					if ( exists( $chunks[$i] ) ) {
						( $chunks[$i] )->{$ss} = $cnt;
					}
					else {
						my( %cathash ) = ();

						$cathash{$ss} = $cnt;
						$chunks[$i] = \%cathash;
					}
				}
			}
			else {
				#warn( "xceschunk::getBlocks() : NF RX $e!!\n" );
			}

			$cnt++;
		}
	}

	my( $temprecline ) = "";

	for ( my $i = 0; $i < scalar( @sent ); $i++ ) {
		my( $c ) = $chunks[$i];
		
		if ( defined( $c ) && ref( $c ) ) {
			$temprecline .= "_";
		}
		else {
			$temprecline .= "<" . $sent[$i] . ">";
		}
	}

	return ( \@chunks, $temprecline );
}

sub arrangeBlocks( $$ ) {
	my( $this ) = shift( @_ );
	my( $CONFCHUNK ) = $this->{"CONFCHUNK"};

	my( $chunks ) = $_[0];
	my( %lengths ) = ();
	my( $pos ) = 0;

	foreach my $c ( @{ $chunks } ) {
		my( %cat );

		if ( defined( $c ) ) {
			%cat = %{ $c };
		}
		else {
			%cat = ();
		}

		foreach my $c ( keys( %cat ) ) {
			my( $key ) = $c . "#" . $cat{$c};

			if ( exists( $lengths{$key} ) ) {
				$lengths{$key}++;
			}
			else {
				$lengths{$key} = 1;
			}
		}

		$pos++;
	}

	foreach my $c ( @{ $chunks } ) {
		if ( defined( $c ) && scalar( keys( %{ $c } ) ) == 0 ) {
			$c = undef();
		}

		if ( defined( $c ) ) {
			my( @chunkys ) = ();

			foreach my $k ( keys( %{ $c } ) ) {
				my( $lkey ) = $k . "#" . $c->{$k};

				push( @chunkys, $lkey . "/" . $lengths{$lkey} );
			}

			my( @schunkys ) = sort {
				my( $k1 ) = ( split( /\//, $a ) )[1];
				my( $k2 ) = ( split( /\//, $b ) )[1];

				return $k2 <=> $k1;
			} @chunkys;

			my( @finalchunks ) = ();

			foreach my $c ( @schunkys ) {
				my( $cc ) = ( split( /\//, $c ) )[0];

				push( @finalchunks, $cc );
			}

			$c = join( ",", @finalchunks );
		} #end defined chunk ...
	}

	return $chunks;
}

sub confchunker( $$ ) {
	my( $this ) = shift( @_ );
	my( $CONFCHUNK ) = $this->{"CONFCHUNK"};
	my( %conf ) = %{ $_[0] };

	foreach my $k ( keys( %conf ) ) {
		if ( exists( $CONFCHUNK->{$k} ) ) {
			SWCHUNK: {
				$k eq "GRAMFILE" and do {
					my( $grammar ) = $this->readNERGrammar( $conf{$k} );
					
					$CONFCHUNK->{"GRAMMAR"} = $grammar->{"GRAMMAR"};
					$CONFCHUNK->{"NONTERM"} = $grammar->{"NTERM"};
			                $CONFCHUNK->{$k} = $conf{$k};
					
					last;
				};

                                $k eq "MSDTOTAG" and do {
                                        $CONFCHUNK->{$k} = $this->readMSDtoTAGMapping( $conf{$k} );
                                        last;
                                };

			        $CONFCHUNK->{$k} = $conf{$k};
			}
			
		}
	}
	
	if ( ! exists( $CONFCHUNK->{"CHUNKS"} ) || ! ref( $CONFCHUNK->{"CHUNKS"} ) || scalar( @{ $CONFCHUNK->{"CHUNKS"} } ) == 0 ) {
		die( "ttl::confchunker : config key CHUNKS is not properly defined !\n" );
	}

	foreach my $k ( keys( %{ $CONFCHUNK } ) ) {
                #print($k." ".$CONFCHUNK->{$k}."\n");
		if ( ! defined( $CONFCHUNK->{$k} ) ) {
			die( "ttl::confchunker : config key $k has no value !\n" );
		}
	}
}

sub chunker( $$ ) {
	my( $this ) = shift( @_ );
	my( $CONFCHUNK ) = $this->{"CONFCHUNK"};
	my( $tagsent ) = $_[0];
	my( $chunks, $recline ) = $this->getBlocks( $tagsent );
	
	return $this->arrangeBlocks( $chunks );
}
########################### End Revise 7.0 #########################################


#Input CTAG to MSD map table ...
#Ncns	NN  for instance ...
sub readTAGtoMSDMapping( $$ ) {
	my( $this ) = shift( @_ );
	my( $CONFTAG ) = $this->{"CONFTAG"};
	my( %TAGMSD ) = ();

	print( STDERR "ttl::readTAGtoMSDMapping : reading file $_[0] ...\n" ) if ( $CONFTAG->{"DEBUG"} );
	open( MAP, "< $_[0]" ) or die( "ttl::readTAGtoMSDMapping : could not open file ...\n" );
	
	while ( my $line = <MAP> ) {
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;

		next if ( $line =~ /^$/ );
		
		my( @toks ) = split( /\s+/, $line );
		
		if ( ! exists( $TAGMSD{$toks[1]} ) ) {
			$TAGMSD{$toks[1]} = [ $toks[0] ];
		}
		else {
			push( @{ $TAGMSD{$toks[1]} }, $toks[0] );
		}
	}

	close( MAP );

	return \%TAGMSD;
}

#Same file as inpus as to the reverse function ...
#Ncns	NN  for instance ...
sub readMSDtoTAGMapping( $$ ) {
	my( $this ) = shift( @_ );
	my( $CONFTAG ) = $this->{"CONFTAG"};
	my( %MSDTAG ) = ();

	print( STDERR "ttl::readMSDtoTAGMapping : reading file $_[0] ...\n" ) if ( $CONFTAG->{"DEBUG"} );
	open( MAP, "< $_[0]" ) or die( "ttl::readMSDtoTAGMapping : could not open file ...\n" );
	
	while ( my $line = <MAP> ) {
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;

		next if ( $line =~ /^$/ );
		
		my( @toks ) = split( /\s+/, $line );
		
		if ( ! exists( $MSDTAG{$toks[0]} ) ) {
			$MSDTAG{$toks[0]} = $toks[1];
		}
		else {
			warn( "ttl::readMSDtoTAGMapping : duplicate mapping for $toks[0] !\n" );
		}
	}

	close( MAP );

	return \%MSDTAG;
}


############################################################## End original TTL code ################################################################

############################################################## Web Services code begins here ########################################################

#Input: default, Class Name as 'pdk::ttl'; Constructs the object.
sub new( $ );


#7.62
my( $OBJNO ) = 1;

sub new( $ ) {
	my( $classname ) = $_[0];
	my( $this ) = {};

	
	#ver 7.0
	my( %CONFCHUNK ) = (
		#what chunks to output
		#these must be start symbols in the GRAMFILE ...
		"CHUNKS" => [ "Pp", "Np", "Vp", "Ap" ],
		#in file of the grammar for chunks
		"GRAMFILE" => undef(),
		#produced by reading file at GRAMFILE
		"GRAMMAR" => undef(),
		#produced by reading file at GRAMFILE
		"NONTERM" => undef(),
		#MSD to CTAG mapping, IN
		"MSDTOTAG" => undef(),
		#8.5
		#This line length is meant to protect a huge regex max against a big line.
		#We obtain 'Out of memory' errors.
		#In tokens.
		"MAXLINELEN" => 50,
		"DEBUG" => 1
	);

	#ver 7.0
	$this->{"CONFCHUNK"} = \%CONFCHUNK;
	#7.62
	$this->{"OBJNO"} = $OBJNO;
	
	$OBJNO++;
	
	bless( $this, $classname );
	return $this;
}


sub DESTROY {
	my( $this ) = shift( @_ );
	
	print( STDERR "pdk::ttl : the object " . $this->{"OBJNO"} . " is going out of scope ... cleaning up.\n" );
	$this->endProcessing();
}

############################################################## WebServices code ends here ################################################################

1;
