#!/usr/bin/env perl

$|++; # turn on autoflush

use strict;
use warnings;
use WWW::Curl::Easy;

my @books = @ARGV;
my @booktitles;
my %booksellers;

for my $book (@books) {
    # Setting the options
    my $curl = new WWW::Curl::Easy;
    my @sellers;

    print "scanning $book ";
    for(my $index=0; ; $index+=25) {
        print ".";
        $curl->setopt(CURLOPT_HEADER,1);
        $curl->setopt(CURLOPT_URL, "http://www.amazon.co.uk/gp/offer-listing/$book/?sort=price&startIndex=$index");
        my $response_body;

        open (my $fileb, ">", \$response_body);
        $curl->setopt(CURLOPT_WRITEDATA,$fileb);

        my $retcode = $curl->perform;
        die("fetching error: ".$curl->strerror($retcode)." ($retcode)\n") unless(!$retcode);

        my $lastpage = 1;
        for my $response_body_line (split /\n/, $response_body) {
            for($response_body_line =~ /class="sellerHeader".*<b>([^<]*)/i) {
                my $toadd = 1;
                for my $b (@{$booksellers{$1}}) {
                    if($b eq $book) {
                        $toadd = 0; # don't add double entries
                        last;
                    }
                }

                push @{$booksellers{$1}}, $book if($toadd);
                $lastpage=0;
            }
        }

        last if($lastpage);
    }

    print "\n";
}

# sort sellers by number of common books
my @sellerrank = sort { @{$booksellers{$b}} <=> @{$booksellers{$a}} } keys %booksellers;

print "Total books input: ".@books."\n";
print "----------\n";

for my $seller (@sellerrank) {
    last unless(@{$booksellers{$seller}}>1); # last because it is ordered
    print "$seller: ".@{$booksellers{$seller}};
    for my $book (@{$booksellers{$seller}}) {
        print " | $book";
    }

    print "\n";
}

exit 0;
