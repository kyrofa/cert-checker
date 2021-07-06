#!/bin/sh -e
#
# This script tells you if the running system supports the following ISRC root
# certificates:
#
#   - ISRG root X1 (cross-signed by DST Root CA X3)
#   - ISRG root X1 (self-signed)
#   - ISRG root X2 (self-signed)
#
# Most systems trust DST Root CA X3, so the first should definitely be
# supported by your system. However, DST Root CA X3 expires on September 30,
# 2021, and thus your system should also trust the second. If it doesn't, add
# it as a new trusted cert to your deployed systems before September. The third
# is a newer ISRG cert not yet in wide circulation; not trusting it isn't a
# deal-breaker, it's mostly here for information purposes.
#
# Copyright 2021 Miriam Technologies, LLC
# Written by Kyle Fazzari <kyle@miriamtech.com>

# ISRG Root X1
cross_signed_root_x1_url="https://letsencrypt.org/certs/isrg-root-x1-cross-signed.pem"
root_x1_url="https://letsencrypt.org/certs/isrgrootx1.pem"

# ISRG Root X2
root_x2_url="https://letsencrypt.org/certs/isrg-root-x2.pem"

run()
{
	printf "%s... " "$1"
	shift

	if output="$("$@" 2>&1)"; then
		echo "done"
		return 0
	else
		echo "error"
		echo "$output"
		return 1
	fi
}

for command in wget openssl; do
	if ! command -v "$command" > /dev/null; then
		echo "Missing required command: '$command'" >&2
		exit 1
	fi
done

# Download certs and do work in a temporary dir. Make sure we clean up when
# we're done.
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

root_x1_cross_path="$work_dir/root_x1_cross.crt"
root_x1_path="$work_dir/root_x1.crt"
root_x2_path="$work_dir/root_x2.crt"

run "Downloading cross-signed ISRG root X1" wget -O "$root_x1_cross_path" "$cross_signed_root_x1_url"
run "Downloading self-signed ISRG root X1" wget -O "$root_x1_path" "$root_x1_url"
run "Downloading self-signed ISRG root X2" wget -O "$root_x2_path" "$root_x2_url"
echo ""

run "Validating cross-signed ISRG root X1" openssl verify "$root_x1_cross_path"
run "Validating self-signed ISRG root X1" openssl verify "$root_x1_path"
run "Validating self-signed ISRG root X2" openssl verify "$root_x2_path"