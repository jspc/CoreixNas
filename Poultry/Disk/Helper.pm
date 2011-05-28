#!/usr/bin/env perl
#
# Poultry::Disk::Helper
# James Condron 2011
# j.condron<at>coreix.net
#
# Take out some of the sting when it comes to common
# tasks such as getting sizes for dd args and so on

=head1 NAME

Poultry::Disk::Helper - Make resizing images a tad simpler in Poultry::Disk::<fs> handlers

=head1 SYNOPSIS
    use Poultry::Disk::Helper qw(current_size current_usage extend_image);

    my $size = current_size( "/path/to/image" );
    my $usage = current_usage( "/dev/loop0" );
    my $new_size = extend_image( "/path/to/image", $space_to_add, $skip_space );


=head1 DESCRIPTION

B<Poultry> is the module for the Coreix NAS backend which handles all the images and devices.
B<Poultry::Disk::Helper> is the module which is called for the handlers in B<Poultry::Disk::*>

=cut

use Poultry::Disk::Helper

use Exporter;
use @ISA = qw(Exporter);
our $version = "1.00";

our @EXPORT = qw(current_size current_usage extend_image);


sub current_size {
    # Take the device and return the current size

    my $image = shift;

    my @du_m_args = ("-B", "1M", "$image");
    my $old_size = capturex( "/usr/bin/du", @du_m_args );
  
    my @old_size_arr = split ' ', $old_size;
    
    return $old_size_arr[0];
}


sub current_usage {
    # Get the current usage of the filesystem
    
    my $device = shift;
	
    my @df_args = ("-B", "1M", "$device");
    my $df = capturex( "/bin/df", @df_args );
    my @df_arr = split ' ', $df;

    return $df_arr[9];

}


sub extend_image {
    # Extend an image with dd

    my $image = shift;
    my $additional = shift;
    my $skip = shift;

    my @dd_args = ("if=/dev/zero", "of=$image", "bs=1M", "count=$additional", "seek=$skip");
    systemx( "/bin/dd", @dd_args );
    
    return current_size( $image );

}

=head1 AUTHOR
jspc - James Condron
E<lt>j.condron@coreix.netE<gt>
L<http://zero-internet.org.uk>
=cut


1;
