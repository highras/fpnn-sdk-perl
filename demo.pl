#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use FpnnClient;

my $client = FpnnClient->new("localhost", 13001);
$client->enableEncryptor("server-public.pem");

my $answer = $client->sendQuest("test_method", {"aaa" => "bbb", "bbb" => 1});
print Dumper($answer);

