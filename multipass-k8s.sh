#!/usr/bin/env bash
# When VMs are deleted, IPs remain allocated in dhcpdb
# IP reclaim: https://discourse.ubuntu.com/t/is-it-possible-to-either-specify-an-ip-address-on-launch-or-reset-the-next-ip-address-to-be-used/30316

ARG=$1

set -euo pipefail

MEM_GB=$(( $(sysctl hw.memsize | cut -d ' ' -f 2) / 1073741824 ))
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

CPMEM="2048M"
WNMEM="2048M"

if ! command -v multipass > /dev/null; then
    echo "Cannot find multipass. Did you install it as per the instructions?"
    exit 1
fi

if ! command -v jq > /dev/null; then
    echo "Cannot find jq. Did you install it as per the instructions?"
    exit 1
fi

if [ $MEM_GB -lt 15 ]; then
    CPMEM="768M"
    WNMEM="512M"
    echo "System RAM is ${MEM_GB}GB. VM size is reduced. It will not be possible for you to run E2E tests (final step)."
fi

specs=/tmp/vm-specs
cat <<EOF > $specs
controlplane01,2,${CPMEM},10G
controlplane02,2,${CPMEM},5G
loadbalancer,1,512M,5G
node01,2,${WNMEM},5G
node02,2,${WNMEM},5G
EOF

echo "System OK!"

for spec in $(cat $specs); do
    node=$(cut -d ',' -f 1 <<< $spec)
    if multipass list --format json | jq -r '.list[].name' | grep $node > /dev/null; then
        read -p "VMs are running. Delete and rebuild them (y/n)? " ans
        [ "$ans" != 'y' ] && exit 1
        break
    fi
done

for spec in $(cat $specs); do
    node=$(cut -d ',' -f 1 <<< $spec)
    cpus=$(cut -d ',' -f 2 <<< $spec)
    ram=$(cut -d ',' -f 3 <<< $spec)
    disk=$(cut -d ',' -f 4 <<< $spec)
    if multipass list --format json | jq -r '.list[].name' | grep $node > /dev/null; then
        multipass delete $node
        multipass purge
    fi
    multipass launch --disk $disk --memory $ram --cpus $cpus --name $node jammy
done

hostentries=/tmp/hostentries
[ -f $hostentries ] && rm -f $hostentries

for spec in $(cat $specs); do
    node=$(cut -d ',' -f 1 <<< $spec)
    ip=$(multipass info $node --format json | jq -r 'first( .info[] | .ipv4[0] )')
    echo "$ip $node" >> $hostentries
done

for spec in $(cat $specs); do
    node=$(cut -d ',' -f 1 <<< $spec)
    multipass transfer $hostentries $node:/tmp/
    multipass transfer $SCRIPT_DIR/setup-hosts.sh $node:/tmp/
    multipass transfer $SCRIPT_DIR/verify-cert.sh $node:/home/ubuntu/
    multipass exec $node -- /tmp/setup-hosts.sh
done

multipass transfer $SCRIPT_DIR/approve-csr.sh controlplane01:/home/ubuntu/

echo "Done!"