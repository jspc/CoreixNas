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

  my @du_m_args = ("-B", "1M", "$image");
  my $old_size = capturex( "/usr/bin/du", @du_m_args );
  
  my @old_size_arr = split ' ', $old_size;
  my $skip_size = $old_size_arr[0] + 1;
  $new_size = $new_size - $old_size_arr[0];

  my @dd_args = ("if=/dev/zero", "of=$image", "bs=1M", "count=$new_size", "seek=$skip_size");
  systemx( "/bin/dd", @dd_args );

  # Remove the Journaling, extend the filesystem and add it back

  my @current_args = ("-B", "1M", "$image"); 
  my $current_size = capturex( "du", @current_args );
  my @current_size_arr = split ' ', $current_size;
  $current_size = $current_size_arr[0];

  my @tune_e2 = ("-O", "^has_journal", "$device");
  systemx( "/sbin/tune2fs", @tune_e2 );

  my @lo_down = ("-d", "$device");
  systemx( "/sbin/losetup", @lo_down );

  my @lo_up = ("$device", "$image");
  systemx( "/sbin/losetup", @lo_up );

  my @fsck_args = ("-f", "$device");
  systemx( "/sbin/e2fsck", @fsck_args );

  # Fix strange behaviour
  my $resize = $current_size - 2;

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

  my @df_args = ("-B", "1M", "$device");
  my $df = capturex( "/bin/df", @df_args );
  my @df_arr = split /\/n/, $df;
  @df_arr = split ' ', $df_arr[1];
  my $used = $df_arr[2];

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

  my @resize_args = ("$device", $size . "M");
  systemx( "/sbin/resize2fs", @resize_args );

  my @mount_args = ("$device", "$mount_point");
  systemx( "/bin/mount", @mount_args );


  # Get the right size of the FS for the resizing

  $df = capturex( "/bin/df", @df_args );
  @df_arr = split /\/n/, $df;
  @df_arr = split ' ', $df_arr[1];
  my $size = $df_arr[1];
  $size = $size + 1;         # Paranoia

  systemx( "/bin/umount", @umount_args );

  # Start resizing
  my $new_image = $image . "-new";
  my $old_image = $image . "-old";
  my @dd_args = ("if=$device", "of=$tmp_image", "bs=1M", "count=$size");
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
