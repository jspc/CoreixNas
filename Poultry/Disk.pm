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
		 base  =>  $base,
		 imgs  =>  $imgs,
		 loops =>  "",
		};

  $self->{loops} = $self->_get_loops();

  return $self;

}

sub errors {
  # Return a list of error statuses
  return {
	  250 => "Cowardly refusing to overwrite image\n",
	  251 => "The mountpoint exists, probably worth checking\n",
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
  my $mount = "$self->{base}\/$customer";

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


  if ( -d $mount ) {
    # Mountpoint exists
    return 251;
  }
  mkdir $mount;

  
  # Mount the device.
  my @mount_args = ("-t", "$fs", "$device", "$mount");
  systemx( "/bin/mount", @mount_args );

  $self->_update_loops( $device, $image );

  return 1;
  
}


sub delete_volume {
  # Delete a volume for good; unmount, destroy the mountpoint
  # Remove from loops and so on. For now just unlink the image
  # At a later date I intend to add to a job list to shred the data

  my $self = shift;
  my $customer = shift;

  # Suss out image and mountpoint
  my $mount = "$self->{base}\/$customer";
  my $image = "$self->{base}\/$self->{imgs}\/$customer";
  my $loop = $self->{loops}->{$image};

  $self->_remove_loops( $image );

  my @umount_args = ( "-f", $loop );
  systemx( "/bin/umount", @umount_args );

  my @loop_args = ( "-d", $loop );
  systemx( "losetup", @loop_args );

  unlink $image;
  rmdir $mount;

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
  # Saved as per $path => $loop for ease when
  # Updating and creating; where we'd need to umount

  my $self = shift;
  my $loop = shift;
  my $path = shift;

  my $loops = $self->{loops};
  $loops->{$path} = $loop;

  store $loops, "$self->{base}/internal/.loops";
  
  $self->{loops} = $self->_get_loops();

  return 1;
}

sub _remove_loops {
    # Two subroutines; this one isn't called much so 
    # No point bogging down _update_loops. Named as per
    # This (for now) because I forgot I'd probably need this.
    # D'oh

    my $self = shift;
    my $path = shift;

    my $loops = $self->{loops};
    delete $loops->{$path};

    store $loops, "$self->{base}/internal/.loops";

    $self->{loops} = $self->_get_loops();

    return 1;
}



1;
