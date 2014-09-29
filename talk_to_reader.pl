#!/usr/bin/perl

## to use via TCP use socat: "socat  EXEC:./talk_to_reader.pl,sigquit TCP-LISTEN:4711,fork,reuseaddr"


use lib "/home/p2/Projects/Wormhole/simserver";

use strict;

use Chipcard::PCSC;

local $| = 1;

my $context = new Chipcard::PCSC();

die ("Context creation failed: $Chipcard::PCSC::errno\n")
	unless defined $context;

my @readers = $context->ListReaders();

die ("Need at least one reader\n")
	unless defined $readers[0];

my $card = new Chipcard::PCSC::Card($context, $readers[0]);

die ("No card: $Chipcard::PCSC::errno\n")
	unless defined $card;

print STDERR "-> Init complete.\n";

print STDERR "-> Going into read loop\n";

my @apdu; 
my $apdu_len;
my $num;
my $buf;

my $le = 0;

while (<>) {
        my $apdu_cmd = $_;
	$le = 0;
	chomp($apdu_cmd); 
        print STDERR "-> Got command apdu: ".$apdu_cmd."\n";
	my $cmd_apdu = my_ascii_to_array($apdu_cmd);
	$cmd_apdu = remove_resp_len($cmd_apdu);
	my $recv = $card->Transmit($cmd_apdu);
        print STDERR "-> Got resp apdu: ".Chipcard::PCSC::array_to_ascii($recv)."\n";
	my @temp = @$recv;
	my $sw1 = $temp[-1];
	my $sw0 = $temp[-2];
	print STDERR "sw1 = $sw1, sw0 = $sw0, le = $le\n";

	if ($sw0 == 0x61) {
		printf STDERR "->Getting response also...\n";
		my $grsp_base = "00 C0 00 00";
		my $grsp_cmd = Chipcard::PCSC::ascii_to_array($grsp_base);
		my $len;
		if ($le > 0 && $sw1 > $le) {
			$len = $le;
		} else {
			$len = $sw1;
		}
		push @$grsp_cmd, $len;
		print STDERR "-> GET RESPONSE: ".Chipcard::PCSC::array_to_ascii($recv)."\n";
		$recv = $card->Transmit($grsp_cmd);
	
	}
        print STDERR "-> Got FINAL resp apdu: ".Chipcard::PCSC::array_to_ascii($recv)."\n";

        print Chipcard::PCSC::array_to_ascii($recv)."\n";

}

sub remove_resp_len($) {
	my $apduref = shift;
	my @apdu = @$apduref;
	if ($apdu[1] == 0xA4) {
                my $len = $apdu[4];
		print STDERR "Len is: $len\n";
		if ($len + 5 < @apdu) {
			print STDERR "apdu too long, removing expected resp size!\n";
			$le = pop(@apdu);
		}
		
	}

	return \@apdu;
}

sub my_ascii_to_array($)
{
	my $ascii_string = shift;
	my @return_array;
	my $tmpVal;

	confess ('usage Chipcard::PCSC::ascii_to_array($string)') unless defined $ascii_string;

	foreach $tmpVal (split / /, $ascii_string) {
		die ("ascii_to_array: wrong value (".unpack("H*", $tmpVal).")") unless ($tmpVal =~ m/^[0-9a-f][0-9a-f]$/i);
		push @return_array, hex ($tmpVal);
	}

	# return a reference to the constructed array
	return \@return_array;
}
