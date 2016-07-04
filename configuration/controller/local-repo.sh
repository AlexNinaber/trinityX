#!/bin/bash

# Post-installation script to set up a local RPM repository with all the
# packages required for installation.

# This is used for sites where there is no internet access, in which case all
# packages dependencies are needed, as well as for custom-built packages.

# NOTE: the local repository is enabled by default, which will cause problems if
#       you don't use it and the directory is empty. In that case, simply
#       disable the whole post script.

source /etc/trinity.sh


echo_info "Copying packages and setting up the local repository:"

if ls "${POST_TOPDIR}"/packages/repodata/*primary.sqlite.* >/dev/null 2>&1 ; then

	cp -rv "${POST_TOPDIR}/packages" "${TRIX_ROOT}"

	cat > /etc/yum.repos.d/trix-local.repo << EOF
[trix-local]
name=trinityX - local repository
baseurl=file://${TRIX_ROOT}/packages/
enabled=1
gpgcheck=0
EOF

else
	echo_warn 'The "packages" directory on the install media does not contain an RPM repo.'
	exit 1
fi

