#!/usr/bin/env perl
#
# Test script for Poulty

use strict;
use warnings;

use Poultry::Disk;

my $disk = Poultry::Disk->new( "/data0", "images" );

print $disk->create_volume( "CN1001", "ext4", "2048" );

$disk->delete_volume( "CN1001" );
