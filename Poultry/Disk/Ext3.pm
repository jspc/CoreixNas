#!/usr/bin/env perl
#
# Poultry::Disk::Ext3
# James Condron 2011
# j.condron<at>coreix.net
#
# This module is to handle the idiosyncracies of
# ext3, in particular the various things needed for
# resizing a volume.

use strict;
use warnings;

package Poultry::Disk::Ext3;

use IPC::System::Simple qw(capturex systemx);
use File::Copy;
use Poultry::Disk::Helper qw(current_size current_usage current_fs_size extend_image);

sub new {
  # We're going to use our new subroutine to initialise paths

  return bless {};

}


sub grow {
  # Grows the filesystem to the specified size
  my $self = shift;
  my $image = shift;
  my $device = shift;
  my $new_size = shift;

  # Get the current size in MB and KB for future use
  # Then do $new_size - $old_size (in MB), to get additional space
  # Add one to the old_size to work out seek value and extend file

  my @umount_args = ( "-f", $device );
  systemx( "/bin/umount", @umount_args );

  my $cur_size = current_size( $device, $image );
  $new_size = $new_size - $cur_size;

  my $skip_size = $cur_size + 1;

  #$cur_size = extend_image( $image, $new_size, $skip_size );

  # Remove the Journaling, extend the filesystem and add it back

  my @tune_e2 = ("-O", "\^has_journal", "$device");
  systemx( "/sbin/tune2fs", @tune_e2 );

  my @fsck_args = ("-f", "$device");
  systemx( "/sbin/e2fsck", @fsck_args );

  $cur_size = extend_image( $image, $new_size, $skip_size );

  my @lo_down = ("-d", "$device");
  systemx( "/sbin/losetup", @lo_down );

  my @lo_up = ("$device", "$image");
  systemx( "/sbin/losetup", @lo_up );


  # Fix strange behaviour
  my $resize = $cur_size - 2;

  my @resize_args = ("$device", $resize . "M");
  systemx( "/sbin/resize2fs", @resize_args );

  my @tune_e3 = ("-j", "$device");
  systemx( "/sbin/tune2fs", @tune_e3 );

  return 1;
}

sub shrink {
  # Shrink the Filesystem
  # Very similar as abouve, though we use a secondary file. Might be a plan
  # To keep the original somewhere safe just in case

  my $self = shift;
  my $image = shift;
  my $device = shift;
  my $new_size = shift;
  my $mount_point = shift;

  # First we make sure the new size is greater than remaining space
  # On the image, or we run the risk of data loss.
  # 10MB spare is reccommended for FS data and such


  my $used = current_usage( $device );


  if ( ($used + 10) >= $new_size ){
    return 255;
  }

  # Now we can shrink out the fs

  my @umount_args = ("$device");
  systemx( "/bin/umount", @umount_args );

  my @tune_args = ("-O", "^has_journal", "$device");
  systemx( "/sbin/tune2fs", @tune_args );

  my @fsck_args = ("-f", "$device");
  systemx( "/sbin/e2fsck", @fsck_args );

  my @resize_args = ("$device", $new_size . "M");
  systemx( "/sbin/resize2fs", @resize_args );

  my @mount_args = ("$device", "$mount_point");
  systemx( "/bin/mount", @mount_args );


  # Get the right size of the FS for the resizing

  my $size = current_fs_size( $device );
  $size = $size + 1;         # Paranoia

  systemx( "/bin/umount", @umount_args );

  # Start resizing
  my $new_image = $image . "-new";
  my $old_image = $image . "-old";
  my @dd_args = ("if=$device", "of=$new_image", "bs=1M", "count=$size");
  systemx( "/bin/dd", @dd_args );

  my @lo_down = ("-d", "$device");
  my @lo_up = ("$device", "$image");
  
  systemx( "/sbin/losetup", @lo_down );

  move( $image, $old_image );
  move( $new_image, $image );

  systemx( "/sbin/losetup", @lo_up );

  my @tune_e3 = ("-j", "$device");
  systemx( "/sbin/tune2fs", @tune_e3 );

  return 1;

}

1;
