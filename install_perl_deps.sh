#!/bin/sh

cpan install Unicode::String
cpan install Algorithm::Diff
cpan install File::Which
cpan install File::HomeDir
cpan install JSON
# Depending on the platform the tests may give strange results
perl -MCPAN -e "CPAN::Shell->notest('install', 'HTTP::Server::Simple')"
