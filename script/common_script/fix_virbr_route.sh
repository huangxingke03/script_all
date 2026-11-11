#!/usr/bin/env bash
# Keep libvirt VM subnet 192.168.122.0/24 on virbr0 (fight cnem hijack).
# Prefer a dedicated routing table + ip rule so cnem main-table routes lose.
# Standalone helper for sync-filetoubuntu; also usable by other tools.
set -euo pipefail
VM_NET="192.168.122.0/24"
VM_HOST="${FILETOUBUNTU_HOST:-192.168.122.100}"
VIRBR="virbr0"
TABLE="${VIRBR_ROUTE_TABLE:-122}"
RULE_PRIO="${VIRBR_RULE_PRIO:-50}"

while read -r line; do
  [[ -z "$line" ]] && continue
  # shellcheck disable=SC2086
  ip route del $line 2>/dev/null || true
done < <(ip route show | awk -v net="$VM_NET" -v host="$VM_HOST" '
  $1==net && $0 !~ /dev '"$VIRBR"'/ {print}
  $1==host && $0 !~ /dev '"$VIRBR"'/ {print}
')

if ! ip link show "$VIRBR" >/dev/null 2>&1; then
  exit 0
fi

ip route replace "$VM_NET" dev "$VIRBR" proto static scope link src 192.168.122.1 metric 5
ip route replace "$VM_HOST"/32 dev "$VIRBR" proto static metric 1

# Policy routing: force VM subnet via virbr0 even if cnem re-adds main routes.
ip route replace "$VM_NET" dev "$VIRBR" table "$TABLE"
ip route replace "$VM_HOST"/32 dev "$VIRBR" table "$TABLE"
if ! ip rule show | grep -q "lookup ${TABLE}"; then
  ip rule add to "$VM_NET" lookup "$TABLE" priority "$RULE_PRIO"
fi
