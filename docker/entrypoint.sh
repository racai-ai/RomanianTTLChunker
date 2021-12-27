#!/bin/sh

export PERL5VER=`perl -V:version | grep -Po "5\.[0-9]+(?:\.[0-9]+)?"`
export PERL5LIB=/root/perl/lib/x86_64-linux-gnu/perl/$PERL5VER:/root/perl/share/perl/$PERL5VER

cd /CHUNKER

perl TTLChunker.pl 9101
