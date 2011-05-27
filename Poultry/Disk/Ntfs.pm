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

sub new {
  return blesss {};
}


sub grow_fs {
  # Extends the NTFS partition, called as per:
  # grow_fs( image_file, device, new_size, mountpoint )
  # mountpoint can be ignored if not needed.


}



sub shrink_fs {
  # Runs exactly the same as above but with extra checking
  # that we're, say, not wiping disk space


}


