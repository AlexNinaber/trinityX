#!/bin/bash

# Enable RDMA on interfaces that support it, with the default package included
# in the CentOS distribution.

# You will want to disable this post script if you're using a HW-specific RDMA
# configuration.

echo_info 'Enabling and starting the RDMA service'

systemctl enable rdma
# The restart fails but the start behaves like a restart, so...
flag_is_unset POST_CHROOT && systemctl start rdma || true

