# This is a small server application for the TTL Romanian Chunker (extracted from the TTL package).
# It implements a simple JSON REST API: http://localhost:PORT/chunker?text=<MSD>\n<MSD>\n....
# Based on the provided MSD tags, the chunks will be returned in a JSON object:
#
# {
#    "status":"OK",
#    "chunks":"Vp#1\nNp#1\nNP#1\n......",
#    "message":""
# }
#
# TTL and all included Perl modules is (C) Radu Ion (radu@racai.ro) and ICIA 2005-2018.
# Permission is granted for research and personal use ONLY.
#
use strict;
use warnings;
use utf8;
use File::HomeDir;
use IO::Socket;
use IO::Handle;
use Cwd;
use Try::Tiny;

use lib 'ttl/perlpak';
use pdk::ttl;


{
package TTLChunkerServer;
 
use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);
use JSON;

my $ttlResourceDir = "./res/ro";
 
my %dispatch = (
    '/chunker' => \&func_chunker,
    # ...
);

my $ttlo = pdk::ttl->new();
 
sub handle_request {
    my $self = shift;
    my $cgi  = shift;
   
    my $path = $cgi->path_info();
    my $handler = $dispatch{$path};
 
    if (ref($handler) eq "CODE") {
        print "HTTP/1.0 200 OK\r\n";
        $handler->($cgi);
         
    } else {
        print "HTTP/1.0 404 Not found\r\n";
        print $cgi->header,
              $cgi->start_html('Not found'),
              $cgi->h1('Not found'),
              $cgi->end_html;
    }
}

sub ttlText( $ ) {
	my $tagsent = $_[0];
	my @taggedtext = ();
	
	my( $chksent ) = $ttlo->chunker( $tagsent );
	my( @sent ) = ();
			
	for ( my $i = 0; $i < scalar( @{ $tagsent } ); $i++ ) {
		my $chk = $chksent->[$i];
			
		if ( ! defined( $chk ) || $chk eq "" ) {
			$chk = "_";
		}
				
		my( $anntoken ) = $chk;
				
		push( @sent, $anntoken );
	}
			
	push( @taggedtext, join( "\n", @sent ) . "\n" );
	return join( "\n", @taggedtext );
}


 
sub func_chunker {
    my $cgi  = shift;   # CGI.pm object
    return if !ref $cgi;
     
    my $request = $cgi->param('text');
    print($cgi->header);

    my $message="";

    $request=~ s/^\s+|\s+$//g;
    if ( $request eq "" ) {
        print('{"status":"ERROR","message":"Empty request"}');
        return("");
    }


    my @reqArr = split("\n",$request);
    my @reqArrCtag=();
    my( $msdtotagmap ) = $ttlo->{"CONFCHUNK"}->{"MSDTOTAG"};
    foreach my $msd (@reqArr) 
    {

        $msd=~ s/^\s+|\s+$//g;
        if ( ! exists( $msdtotagmap->{$msd} ) ) {
            $message.="msd [$msd] is not in mapping !\n";
            push( @reqArrCtag, $msd );
            next;
        }

        my($ctag) = $msdtotagmap->{$msd};
        push(@reqArrCtag,$ctag);
        #print("$msd => $ctag\n");
    }

    my $procText = ttlText( \@reqArrCtag );


    my %result=();
    $result{status}="OK";
    $result{chunks}=$procText;
    $result{message}=$message;
    #print('{"status":"OK","chunks":"'.$procText.'","message":"'.$message.'"}');
    print(to_json(\%result,{utf8=>1,pretty=>1}));
}

sub loadROResources() {
	print( STDERR "TTLChunker::loadROResources: configuring Romanian TTL Chunker...\n" );
	$ttlo->confchunker( {
		"MSDTOTAG" => "$ttlResourceDir/msdtag.ro.map",
		"CHUNKS" => [ "Pp", "Np", "Vp", "Ap" ],
		"GRAMFILE" => "$ttlResourceDir/rogrm.rxg",
		"MAXLINELEN" => 100
	} );
	
	print( STDERR "TTLChunker::loadROResources: done configuring.\n" );
}

 
} 


if ( scalar( @ARGV ) != 1 ) {
	die( "TTLChunker.pl <TCP port>\n" );
}
elsif ( $ARGV[0] !~ /^[0-9]+$/ || $ARGV[0] >= 65536 ) {
	die( "TTLChunker.pl <TCP port>\n" );
}

my $serverPort = shift( @ARGV );

STDERR->autoflush( 1 );

print( STDERR "TTLChunker::main: running on " . $^O . "\n" );
print( STDERR "TTLChunker::main: working directory is " . cwd() . "\n" );

print( STDERR "TTLChunker::main: loading Unicode entities...\n" );

# Loading resources as we start...
print( STDERR "TTLChunker::main: loading Romanian TTL resources...\n" );
TTLChunkerServer->loadROResources();
print( STDERR "TTLChunker::main: done loading.\n" );

print( STDERR "TTLChunker::main: starting TCP server on port $serverPort...\n" );

#my $pid = TTLChunkerServer->new($serverPort)->background();
#print "Use 'kill $pid' to stop server.\n";

my $pid = TTLChunkerServer->new($serverPort)->run();

