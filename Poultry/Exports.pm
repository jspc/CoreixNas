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

    open EXP, "<<$self->{nfs}";
    print EXP "$directory\t$ip(rw,no_root_squash)";

    return 1;

}


sub add_smb {
    # Add a directory as a SMB share

}


sub del_nfs {
    # Remove an NFS share

}


sub del_smb {
    # Remove a SMB share
}


1;
