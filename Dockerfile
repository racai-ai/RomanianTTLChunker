# Intermediate image for compilation
FROM ubuntu:18.04 as intermediate
LABEL stage=intermediate
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y git wget curl make automake autoconf gcc g++ flex bison libconfig-yaml-perl makepatch gpg zip unzip perl

# Install Perl CPAN packages for NLPipe
# Install Perl5 only if it's not installed (it usually is)
RUN mkdir -p /root/.cpan/CPAN
RUN mkdir -p /root/perl
# Copy already configured (by Radu) CPAN .pm file
COPY docker/MyConfig.pm /root/.cpan/CPAN
RUN cpan install Canary::Stability Unicode::String Algorithm::Diff File::Which 
RUN perl -MCPAN -e "CPAN::Shell->notest('install', 'File::HomeDir')"
RUN perl -MCPAN -e "CPAN::Shell->notest('install', 'JSON')"
RUN perl -MCPAN -e "CPAN::Shell->notest('install', 'HTTP::Server::Simple')"


# Final image
FROM ubuntu:18.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y zip unzip locales curl perl
RUN locale-gen en_US.UTF-8
COPY --from=intermediate /root/perl/ /root/perl/
RUN mkdir /CHUNKER
COPY ./ttl/ /CHUNKER/ttl/
COPY ./res/ /CHUNKER/res/
COPY TTLChunker.pl /CHUNKER/TTLChunker.pl

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en

COPY docker/entrypoint.sh /
RUN chmod a+rx /entrypoint.sh

CMD ["/entrypoint.sh"]
