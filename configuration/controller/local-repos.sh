#!/bin/bash

# Post-installation script to set up a local RPM repository with all the
# packages required for installation.

# This is used for sites where there is no internet access, in which case all
# packages dependencies are needed, as well as for custom-built packages.


echo_info 'Copying packages and setting up the local repositories'


# On a node, those are made available via bind mount at installation time, and
# NFS later.

if  flag_is_unset CHROOT_INSTALL ; then
    # Copy the whole tree with all local repos
    mkdir -p "${TRIX_ROOT}/shared"
    cp -r "${POST_TOPDIR}/packages" "${TRIX_ROOT}/shared"
fi


# For each repo file present, check that there is actually a matching repo...

for repo in "${POST_FILEDIR}"/*.repo ; do
    
    bname="$(basename "$repo" .repo)"
    
    cp "${repo}" /etc/yum.repos.d/
    sed -i 's#TRIX_ROOT#'"$TRIX_ROOT"'#g' "/etc/yum.repos.d/${bname}.repo"
    
    if ! ls "${POST_TOPDIR}/packages/${bname}/repodata/"*primary.sqlite.* >/dev/null 2>&1 ; then
        echo_warn "Repository \"${bname}\" is empty, disabling the repo file."
        sed -i 's/^\(enabled=\).*/\10/g' "/etc/yum.repos.d/${bname}.repo"
    fi
done


# Disable remote repositories if requested

flag_is_set REPOS_DISABLE_REMOTE && disable_remote_repos || true

