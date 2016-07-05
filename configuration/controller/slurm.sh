#!/bin/bash

# set up slurmctld daemon

source "$POST_CONFIG"
source /etc/trinity.sh


echo "
${SLURMDBD_MYSQL_DB?"Variable SLURMDBD_MYSQL_DB was not set"}
${SLURMDBD_MYSQL_USER?"Variable SLURMDBD_MYSQL_USER  was not set"}
${SLURMDBD_MYSQL_PASS?"Variable SLURMDBD_MYSQL_PASS was not set"}
">/dev/null

echo_info "Creating ${TRIX_ROOT}/shared/etc"

mkdir -p ${TRIX_ROOT}/shared/etc


echo_info "Moving /etc/slurm to ${TRIX_ROOT}/shared/etc"

[ -d ${TRIX_ROOT}/shared/etc/slurm ] || ( mv /etc/slurm ${TRIX_ROOT}/shared/etc/ && ln -s ${TRIX_ROOT}/shared/etc/slurm /etc/slurm )

echo_info "Moving /etc/munge to ${TRIX_ROOT}/shared/etc"

[ -d ${TRIX_ROOT}/shared/etc/munge ] || mv /etc/munge ${TRIX_ROOT}/shared/etc/

echo_info "Create munge.key file."

[ -f ${TRIX_ROOT}/shared/etc/munge/munge.key ] || ( /usr/bin/dd if=/dev/urandom bs=1 count=1024 of=${TRIX_ROOT}/shared/etc/munge/munge.key && \
chmod 400 ${TRIX_ROOT}/shared/etc/munge/munge.key && chown munge:munge ${TRIX_ROOT}/shared/etc/munge/munge.key )

echo_info "Update munge unit files."

mkdir -p /etc/systemd/system/munge.service.d

if [ !  -d /etc/systemd/system/munge.service.d ]; then
    mkdir -p /etc/systemd/system/munge.service.d
    cat << EOF > /etc/systemd/system/munge.service.d/remote-fs.conf
[Unit]
After=remote-fs.target
Requires=remote-fs.target
EOF

    cat << EOF > /etc/systemd/system/munge.service.d/customexec.conf
[Service]
ExecStart=
ExecStart=/usr/sbin/munged  --key-file ${TRIX_ROOT}/shared/etc/munge/munge.key
EOF
    systemctl daemon-reload

fi

echo_info "Start munge."

systemctl start munge
systemctl enable munge


if [ ! -f ${TRIX_ROOT}/shared/etc/slurm/slurm.conf ]; then

    echo_info "Copy slurm config files"

    cp ${POST_FILEDIR}/slurm*.conf /etc/slurm/

    echo_info "Changing variable placeholders."

    sed -i -e "s/{{ HEADNODE }}/${SLURM_HEADNODE=$(hostname -s)}/" /etc/slurm/slurm.conf
    sed -i -e "s/{{ HEADNODE }}/${SLURM_HEADNODE=$(hostname -s)}/" /etc/slurm/slurmdbd.conf
    if [ ${SLURM_BACKUPNODE} ]; then
        sed -i -e '/BACKUPNODE/{s/^[# \t]\+//}' /etc/slurm/slurm.conf
        sed -i -e '/BACKUPNODE/{s/^[# \t]\+//}' /etc/slurm/slurmdbd.conf
        sed -i -e "s/{{ BACKUPNODE }}/${SLURM_BACKUPNODE}/" /etc/slurm/slurm.conf
        sed -i -e "s/{{ BACKUPNODE }}/${SLURM_BACKUPNODE}/" /etc/slurm/slurmdbd.conf
    fi
    sed -i -e "s/{{ SLURMDBD_MYSQL_DB }}/${SLURMDBD_MYSQL_DB}/" /etc/slurm/slurmdbd.conf
    sed -i -e "s/{{ SLURMDBD_MYSQL_USER }}/${SLURMDBD_MYSQL_USER}/" /etc/slurm/slurmdbd.conf
    sed -i -e "s|{{ SLURMDBD_MYSQL_PASS }}|${SLURMDBD_MYSQL_PASS}|" /etc/slurm/slurmdbd.conf
fi
    

echo_info "Start slurm accounting."

# for record, how to create db:
# CREATE DATABASE slurm_accounting;
# CREATE USER 'slurm_accounting'@'%' IDENTIFIED BY 'P@ssw0rd';
# GRANT ALL PRIVILEGES ON slurm_accounting.* TO 'slurm_accounting'@'%';
# FLUSH PRIVILEGES;

if [ !  -d /etc/systemd/system/slurmdbd.service.d ]; then

    mkdir -p /etc/systemd/system/slurmdbd.service.d
    cat << EOF > /etc/systemd/system/slurmdbd.service.d/customexec.conf
[Unit]
Requires=munge.service

[Service]
Restart=always
EOF
    systemctl daemon-reload

fi

systemctl start slurmdbd
systemctl enable slurmdbd


echo_info "Start slurm."

if [ !  -d /etc/systemd/system/slurm.service.d ]; then

    mkdir -p /etc/systemd/system/slurm.service.d
    cat << EOF > /etc/systemd/system/slurm.service.d/customexec.conf
[Unit]
Requires=munge.service

[Service]
Restart=always
EOF
    systemctl daemon-reload
fi 


systemctl start slurm
systemctl enable slurm
