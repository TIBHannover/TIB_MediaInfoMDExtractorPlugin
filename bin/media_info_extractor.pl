#!/usr/bin/env perl

use warnings;
use strict;


# is to be built
my $xml_body='';

# substitute the newlines in the output of the version string
# g flag in regex is global, i.e. multiline
# r flag in regex copies the value and returns the result for oneliners
my $agent = `mediainfo --version` =~ s/\n//gr;

# long list of lines of "key : value" pairs
# section name without a value
my $all_info = `mediainfo --Language=raw --Full $ARGV[0]`;
my @sections = split("\n\n", $all_info);

# hash of names of keys of values
# e.g. General -> Format -> JPEG
my %all_info;

# build the hash 
foreach my $section (@sections) {
	
	my @lines = split("\n", $section);
	
	# mediainfo prints out two trailing linebrakes, skip them
	next if not @lines;
	
	# first line of a section is name, e.g. "General"
	my $section_name = shift @lines;
	
	# the infos of a section follow the pattern "key : value"
	foreach my $line (@lines) {
		
		# split at a single colon surrounded by whitespaces
		my ($key, $value) = split (/\s+:\s+/, $line);
		
		# populate the hash
		$all_info{$section_name}->{$key} = $value;
	}
}

# Format_version is not set for all formats
$all_info{'General'}->{'Format_version'} = '' if not defined $all_info{'General'}->{'Format_version'};

# the tag <imageCount /> is hardcoded empty in the xslt from exlibris
# likewise <isValid>true</isValid> and <isWellFormed>true</isWellFormed>
my $xmlhead=<<"HERE";
<?xml version="1.0"?>
<mdExtractor>
  <profile />
  <format_name>$all_info{'General'}->{'Format'}</format_name>
  <formatVersion>$all_info{'General'}->{'Format_version'}</formatVersion>
  <imageCount />
  <isValid>true</isValid>
  <isWellFormed>true</isWellFormed>
  <attributes>
HERE

my $xmltail=<<"HERE";
  </attributes>
  <agent>$agent</agent>
  <mimeType>$all_info{'General'}->{'InternetMediaType'}</mimeType>
</mdExtractor>
HERE


foreach my $section_name (keys %all_info) {
	foreach my $key (keys %{$all_info{$section_name}}) {
		$xml_body .= qq[    <key id="mediainfo.track.${section_name}.$key">$all_info{$section_name}->{$key}</key>\n]
	}
}



print $xmlhead . $xml_body . $xmltail;
