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

  my @du_m_args = ("-B", "1M", "$image");
  my $old_size = capturex( "/usr/bin/du", @du_m_args );
  
  my @old_size_arr = split / */, $old_size;
  my $skip_size = $old_size_arr[0] + 1;
  my $new_size = $new_size - $old_size_arr[0];

  my @dd_args = ("if=/dev/zero", "of=$image", "bs=1M", "count=$new_size", "seek=$skip_size");
  systemx( "/bin/dd", @dd_args );

  # Remove the Journaling, extend the filesystem and add it back

  my $current_size = capturex( "du", $image );
  my @current_size_arr = split / */, $current_size;
  $current_size = $current_size_arr[0];

  my @tune_e2 = ("-O", "^has_journal", "$device");
  systemx( "/sbin/tune2fs", @tune_e2 );

  my @lo_down = ("-d", "$device");
  systemx( "/sbin/losetup", @lo_down );

  my @lo_up = ("$device", "$image");
  systemx( "/sbin/losetup", @lo_up );

  my @fsck_args = ("-f", "$device");
  systemx( "/sbin/e2fsck", @fsck_args );

  my @resize_args = ("$device", "$current_size");
  systemx( "/sbin/resize2fs", @resize_args );

  my @tune_e3 = ("-j", "$device");
  systemx( "/sbin/tune2fs", @tune_e3 );

  return 1;
}

sub shrink {
  # Shrink the Filesystem

  return 0;
}

1;
