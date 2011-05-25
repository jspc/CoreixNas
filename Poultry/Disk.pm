#!/usr/bin/env perl
#
# Poultry::Disk
# James Condron 2011
# j.condron<at>coreix.net
#
#
# This module is going to handle all the creation,
# Updating and Deletion of customer volumes.
#
# We will handle everything transparently


use strict;
use warnings;

package Poultry::Disk;

use IPC::System::Simple qw(capturex systemx);
use Storable;

sub new {
  # Constructor

  my $self = shift;
  my $base = shift;
  my $imgs = shift;

  $self = bless {
		 base => $base,
		 imgs => $imgs,
		 loop => "",
		};

  $self->{loop} = $self->_get_loops();

  return $self;

}

sub errors {
  # Return a list of error statuses
  return {
	  250 => "Cowardly refusing to overwrite image\n",
	 };
}


sub create_volume {
  # Create a new volume, as per:
  # &create_volume $customer, $fs_type, $size

  my $self = shift;
  my $customer = shift;
  my $fs = shift;
  my $size = shift;

  
  # Find an available loopback device
  # For the sake of ease, read the last line, append the value
  # At some point we'll need garbage checking

  my $loop_command = capturex( "losetup", "-a" );
  my @loops = split /\n/, $loop_command;

  my $device;

  if ( scalar @loops == 0 ){
    # No loopback devices yet
    $device = "/dev/loop0";

  } else {
    # We have devices, lets get the next one

    my @last_line = split /:/, $loops[-1];
    my $last_loop = $last_line[0];

    # Now, we're going to cheat a little... Unless the universe breaks
    # The loopback device will always start with /dev/loop. This is 9chars.
    # So lets assume char10 - end is the value of the last, increment it and whack on
    # The end of '/dev/loop'

    my $last_val = substr $last_loop, 9;
    my $new_val = $last_val + 1;
    $device = "/dev/loop" . $new_val;

  }


  # Create the image, create the mountpoint and create the FS

  my $image = "$self->{base}\/$self->{imgs}\/$customer";


  my @dd_args = ("if=/dev/zero", "of=$image", "bs=1M", "count=$size");
  
  if ( -f $image ) {
    # Refuse to overwrite
    return 250;
  }
  systemx( "/bin/dd", @dd_args );
  

  my @lo_args = ("$device", "$image");
  systemx( "/sbin/losetup", @lo_args );
  

  my @fs_args = ("-t", "$fs", "$device");
  systemx( "/sbin/mkfs", @fs_args );

  
  # Add the image to fstab and update our list of loopback devices
  # This means when we start the service we can keep the same devices
  # Which will be perfect for fstab and so on

  $self->_update_loops( $device, $image );
  
  open(FSTAB, ">>/etc/fstab");
  print FSTAB "$device\t$image\t$fs\tdefaults\t0\t0";
  close FSTAB;

  systemx( "/bin/mount", $device );
  
}


sub _get_loops {
  # Return a hashref of loopback devices and the image on each
  
  my $self = shift;
  my $loops;
  
  if ( -f "$self->{base}/internal/.loops" ){
    $loops = retrieve( "$self->{base}/internal/.loops" );
  } else {
    mkdir "$self->{base}/internal";
    $loops = {};
  }

  return $loops;
}


sub _update_loops {
  # Update the loopback device file
  # &_update_loops /dev/loop0 /path/to/image

  my $self = shift;
  my $loop = shift;
  my $path = shift;

  my $loops = $self->{loops};
  $loops->{$loop} = $path;

  store $loops, "$self->{base}/internal/.loops";
  
  $self->{loops} = $self->_get_loops();

  return 1;
}



1;
