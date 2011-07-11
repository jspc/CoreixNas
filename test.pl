#!/usr/bin/env perl
#
# Test script for Poulty

use strict;
use warnings;

use Poultry::Disk;

my $disk = Poultry::Disk->new( "/data0", "images" );



# Create some test volumes

my %customers = (
    CN1001  =>  1000,
    CN1002  =>  4000,
    );


foreach my $cn (keys %customers){
    my $size = $customers{ $cn };
    print $disk->create_volume( $cn, "ntfs", $size );
}


my %customers = (
    CN1003  =>  1000,
    CN1004  =>  4000,
    );


foreach my $cn (keys %customers){
    my $size = $customers{ $cn };
    print $disk->create_volume( $cn, "ext3", $size );
}


# Resize some test volumes

$disk->resize_volume( "CN1001", "2300" );
$disk->resize_volume( "CN1002", "3000" );

# Delete a volume

$disk->delete_volume( "CN1002" );