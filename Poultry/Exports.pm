#!/usr/bin/env perl
#
# Poultry::Exports
# James Condron 2011
# j.condron<at>coreix.net
#
# Handle exporting file systems via
# nfs and smb through relevant config files

use strict;
use warnings;

package Poultry::Exports;



sub new {
  # Init the module
  
  my $self = {
	      smb   =>   "/etc/samba/smb.conf",
	      nfs   =>   "/etc/exports",
	     };
  
  return bless $self;
  
}

sub add_nfs {
  # Add a directory as an NFS share
  
  my $self = shift;
  my $directory = shift;
  my $ip = shift;
  
  # A note...
  # nfs is a little... crap. You either map U/GIDs and hope they're identical across the board
  # Or you use root squashing/ assume all connections are root. Of course they will be, but this
  # presents a problem- you'd have to give eveybody access to everything else.
  #
  # SMB, SCP and FTP wont have this problem, but NFS will

  open EXP, ">>$self->{nfs}";
  print EXP "$directory\t$ip(rw,no_root_squash)\n\n";
  close EXP;
  
  return 1;
  
}


sub add_smb {
  # Add a directory as a SMB share
  # We're adding an smb.conf stanza with a leading and closing comment
  # This is kinda a cheat for removing it at a later date

  my $self = shift;
  my $directory = shift;
  my $user = shift;
  
  open EXP, ">>$self->{smb}";
  print EXP "#BEGIN $user\n";
  print EXP "[$user]\n";
  print EXP "path=$directory\n";
  print EXP "writeable=yes\n";
  print EXP "valid users=$user\n";
  print EXP "#END $user\n\n\n";
  close EXP;

  return 1;
  
}


sub del_nfs {
  # Remove an NFS share
  # Search nfs config file $ip and then skip that line
  # And add back to file

  my $self = shift;
  my $ip = shift;

  my @nfs;

  open EXP, "<<$self->{nfs}";
  while (<EXP>) {
    if ( $_ !~ /$ip/ ){
      push @nfs, $_;
    }
  }
  close EXP;

  # Write it back

  open EXP, ">$self->{nfs}";
  foreach ( @nfs ){
    print EXP "$_\n";
  }
  close EXP;

  return 1;
  
}


sub del_smb {
  # Remove a SMB share
  # Slightly more complex. What we're going to do is find the 'BEGIN'
  # Line to identify the stanza and then ignore everything until we
  # Hit the 'END' line. Outside of that, much the same as with nfs shares

  my $self = shift;
  my $user = shift;

  my @smb;
  my $lock = 0;

  open EXP, "<<$self->{smb}";

  #FIXME: Inefficient loop

  while ( <EXP> ){
    if ( $_ ne "BEGIN: $user\n" or $lock = 0 ){
      push @smb, $_;
    } elsif ( $_ eq "END: $user\n" ){
      $lock = 0;
    } else {
      $lock = 1;
    }
  }

  close EXP;

  # Write it back

  open EXP, ">$self->{smb}";
  foreach ( @smb ){
    print EXP "$_\n";
  }
  close EXP;

  return 1;

}


sub reload {
  # We're going to want to reload config files
  # After we've added/ removed an export

  `/etc/init.d/nfs-kernel-server reload`;
  `/etc/init.d/smb reload`;

  return 1;
  
  
}


1;
