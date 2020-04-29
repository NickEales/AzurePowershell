#!/bin/sh
#
#  only doing all the sudos as cloud-init doesn't run as root, likely better to use Azure VM Extensions
#
#  $1 is the vnet IP range, $2 is the forwarder $3 is the DNS zone
#

touch /tmp/forwarderSetup_start
echo "$@" > /tmp/forwarderSetup_params

#  Install Bind9
sudo apt-get update -y
sudo apt-get install bind9 -y

# configure Bind9 for forwarding
sudo cat > named.conf.options << EndOFNamedConfOptions
acl goodclients {
    $1;
    localhost;
    localnets;
};

options {
        directory "/var/cache/bind";

        recursion yes;

        allow-query { goodclients; };

        forwarders {
            168.63.129.16;
        };
        forward only;

        dnssec-validation auto;

        auth-nxdomain no;    # conform to RFC1035
        listen-on { any; };
};

zone "blob.core.windows.net" {
    type forward;
    forward only;
    forwarders { 168.63.129.16; };
};

zone "$3" {
    type forward;
    forward only;
    forwarders { $2; };
};

EndOFNamedConfOptions

sudo cp named.conf.options /etc/bind
sudo service bind9 restart

touch /tmp/forwarderSetup_end