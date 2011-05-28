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
