#!/usr/bin/env perl
#
# Poultry::Disk::Ntfs
# James Condron 2011
# j.condron<at>coreix.net
#
# Handler for growing/ shrinking ntfs volumes
# ntfsresize

use strict;
use warnings;

package Poultry::Disk::Ntfs;

use Poultry::Disk::Helper qw(current_size current_usage extend_image);
use File::Copy;

sub new {
  return bless {};
}


sub grow {
    # Extends the NTFS partition, called as per:
    # grow_fs( image_file, device, new_size, mountpoint )
    # mountpoint can be ignored if not needed.

    my $self = shift;
    my $image = shift;
    my $device = shift;
    my $new_size = shift;

    my @umount_args = ("$device");
    systemx( "/bin/umount", @umount_args );

    # Get the current size and extend

    my $size = current_size( $device, $image );
    my $additional_size = $size - $new_size;
    my $skip = $size + 1;

    extend_image( $image, $additional_size, $skip );
    
    # Expand image

    $self->resize( $device, $new_size );

    return 1;
}



sub shrink {
    # Runs exactly the same as above but with extra checking
    # that we're, say, not wiping disk space

    my $self = shift;
    my $image = shift;
    my $device = shift;
    my $new_size = shift;

    # Resize image, create new image of $new_size and dd from one to other

    my $used = current_usage( $device );

    if ( ($used + 10) >= $new_size ){
      return 255;
    }

    my @umount_args = ("$device");
    systemx( "/bin/umount", @umount_args );

    $self->resize( $device, $new_size );

    my $image_new = $image . "-new";
    my $image_old = $image . "-old";

    my @dd_args = ("if=$device", "of=$image_new", "bs=1M", "count=$new_size");
    systemx( "/bin/dd", @dd_args );

    my @lo_down = ("-d", "$device");
    systemx( "/sbin/losetup", @lo_down );

    move( $image, $image_old );
    move( $image_new, $image );

    my @lo_up = ("$device", "$image");
    systemx( "/sbin/losetup", @lo_up );

    return 1;

}


sub resize {
    # ntfsresize, the program we'll invoke for now,
    # Has one simple method for this. Makes sense to do
    # All this here, as opposed to ext3 where we had to
    # Do journalling and tests and all kinds of cracky stuff

    my $self = shift;
    my $device = shift;
    my $new_size = shift;

    my @ntfs_args = ("$new_size" . "M", "$device");
    systemx( "ntfsresize", @ntfs_args );

    return 1;
}


1;
