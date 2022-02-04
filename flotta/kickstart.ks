# set locale defaults for the Install
lang en_US.UTF-8
keyboard us
timezone UTC

# initialize any invalid partition tables and destroy all of their contents
zerombr

# erase all disk partitions and create a default label
clearpart --all --initlabel

# automatically create xfs partitions with no LVM and no /home partition
autopart --type=plain --fstype=xfs --nohome

# reboot after installation is successfully completed
reboot

# installation will run in text mode
text

# activate network devices and configure with DHCP
network --bootproto=dhcp

# set up the OSTree-based install
ostreesetup --nogpg --url={{ ostree_repo_url }} --osname={{ os_name }} --remote=edge --ref=rhel/8/x86_64/edge
%post

#################################################
## Additional scripts run on the installed system
#################################################

# workaround for pause container multi-arch support https://bugzilla.redhat.com/show_bug.cgi?id=2011249
cat <<EOF > /etc/containers/containers.conf
[engine]
infra_image = "k8s.gcr.io/pause:3.4.1"
EOF

# configuration for yggdrasil
cat <<EOF > /etc/yggdrasil/config.toml
log-level = "error"
cert-file = "/etc/pki/consumer/cert.pem"
key-file = "/etc/pki/consumer/key.pem"
transport = "http"
client-id-source = "machine-id"
http-server = "{{ yggdrasil_http_api_url }}"
EOF
mkdir -p /etc/pki/consumer
openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out /etc/pki/consumer/cert.pem -keyout /etc/pki/consumer/key.pem -subj /CN=k4e-agent
systemctl disable --now firewalld.service
systemctl enable --now nftables.service
systemctl enable --now podman.service
systemctl enable --now podman.socket
systemctl enable --now yggdrasild.service

# FIXME: enable root password for debug purposes, should be removed in production
echo root | passwd --stdin root
