#!/bin/sh
#
# This script is used to test that the module system is working as expected.
# By default it test the version of nixpkgs which is defined in the NIX_PATH.

cd ./modules

echo $NIX_PATH

pass=0
fail=0

evalConfig() {
    local attr=$1
    shift;
    local script="import ./default.nix { modules = [ $@ ];}"
    nix-instantiate --timeout 1 -E "$script" -A "$attr" --eval-only --show-trace
}

reportFailure() {
    local attr=$1
    shift;
    local script="import ./default.nix { modules = [ $@ ];}"
    echo 2>&1 "$ nix-instantiate -E '$script' -A '$attr' --eval-only"
    evalConfig "$attr" "$@"
    fail=$((fail + 1))
}

checkConfigOutput() {
    local outputContains=$1
    shift;
    if evalConfig "$@" 2>/dev/null | grep --silent "$outputContains" ; then
        pass=$((pass + 1))
        return 0;
    else
        echo 2>&1 "error: Expected result matching '$outputContains', while evaluating"
        reportFailure "$@"
        return 1
    fi
}

checkConfigError() {
    local errorContains=$1
    local err=""
    shift;
    if err==$(evalConfig "$@" 2>&1 >/dev/null); then
        echo 2>&1 "error: Expected error code, got exit code 0, while evaluating"
        reportFailure "$@"
        return 1
    else
        if echo "$err" | grep --silent "$errorContains" ; then
            pass=$((pass + 1))
            return 0;
        else
            echo 2>&1 "error: Expected error matching '$errorContains', while evaluating"
            reportFailure "$@"
            return 1
        fi
    fi
}

## String types.

checkConfigOutput "foo" config.value ./declare-non-empty-string.nix ./define-value-string.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: non-empty)'." config.value ./declare-non-empty-string.nix ./define-value-empty-string.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: non-empty)'." config.value ./declare-non-empty-string.nix ./define-value-empty-string-2.nix


## IPv4 addrs (any format)

checkConfigOutput "0.0.0.0" config.value ./declare-ipv4.nix ./define-value-ipv4-0.0.0.0.nix
checkConfigOutput "0.0.0.0/0" config.value ./declare-ipv4.nix ./define-value-ipv4-0.0.0.0-slash-0.nix
checkConfigOutput "255.255.255.255" config.value ./declare-ipv4.nix ./define-value-ipv4-255.255.255.255.nix
checkConfigOutput "255.255.255.255/32" config.value ./declare-ipv4.nix ./define-value-ipv4-255.255.255.255-slash-32.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address)'." config.value ./declare-ipv4.nix ./define-value-invalid-ipv4-1.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address)'." config.value ./declare-ipv4.nix ./define-value-invalid-ipv4-2.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address)'." config.value ./declare-ipv4.nix ./define-value-invalid-ipv4-3.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address)'." config.value ./declare-ipv4.nix ./define-value-invalid-ipv4-4.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address)'." config.value ./declare-ipv4.nix ./define-value-invalid-ipv4-5.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address)'." config.value ./declare-ipv4.nix ./define-value-invalid-ipv4-6.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address)'." config.value ./declare-ipv4.nix ./define-value-invalid-ipv4-7.nix


## IPv4 addrs (CIDR notation)

checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address with CIDR suffix)'." config.value ./declare-ipv4Cidr.nix ./define-value-ipv4-0.0.0.0.nix
checkConfigOutput "0.0.0.0/0" config.value ./declare-ipv4Cidr.nix ./define-value-ipv4-0.0.0.0-slash-0.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address with CIDR suffix)'." config.value ./declare-ipv4Cidr.nix ./define-value-ipv4-255.255.255.255.nix
checkConfigOutput "255.255.255.255/32" config.value ./declare-ipv4Cidr.nix ./define-value-ipv4-255.255.255.255-slash-32.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address with CIDR suffix)'." config.value ./declare-ipv4Cidr.nix ./define-value-invalid-ipv4-1.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address with CIDR suffix)'." config.value ./declare-ipv4Cidr.nix ./define-value-invalid-ipv4-2.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address with CIDR suffix)'." config.value ./declare-ipv4Cidr.nix ./define-value-invalid-ipv4-3.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address with CIDR suffix)'." config.value ./declare-ipv4Cidr.nix ./define-value-invalid-ipv4-4.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address with CIDR suffix)'." config.value ./declare-ipv4Cidr.nix ./define-value-invalid-ipv4-5.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address with CIDR suffix)'." config.value ./declare-ipv4Cidr.nix ./define-value-invalid-ipv4-6.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address with CIDR suffix)'." config.value ./declare-ipv4Cidr.nix ./define-value-invalid-ipv4-7.nix


## IPv4 addrs (non-CIDR)

checkConfigOutput "0.0.0.0" config.value ./declare-ipv4NoCidr.nix ./define-value-ipv4-0.0.0.0.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address, no CIDR suffix)'." config.value ./declare-ipv4NoCidr.nix ./define-value-ipv4-0.0.0.0-slash-0.nix
checkConfigOutput "255.255.255.255" config.value ./declare-ipv4NoCidr.nix ./define-value-ipv4-255.255.255.255.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address, no CIDR suffix)'." config.value ./declare-ipv4NoCidr.nix ./define-value-ipv4-255.255.255.255-slash-32.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address, no CIDR suffix)'." config.value ./declare-ipv4NoCidr.nix ./define-value-invalid-ipv4-1.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address, no CIDR suffix)'." config.value ./declare-ipv4NoCidr.nix ./define-value-invalid-ipv4-2.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address, no CIDR suffix)'." config.value ./declare-ipv4NoCidr.nix ./define-value-invalid-ipv4-3.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address, no CIDR suffix)'." config.value ./declare-ipv4NoCidr.nix ./define-value-invalid-ipv4-4.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address, no CIDR suffix)'." config.value ./declare-ipv4NoCidr.nix ./define-value-invalid-ipv4-5.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address, no CIDR suffix)'." config.value ./declare-ipv4NoCidr.nix ./define-value-invalid-ipv4-6.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv4 address, no CIDR suffix)'." config.value ./declare-ipv4NoCidr.nix ./define-value-invalid-ipv4-7.nix


## RFC 1918 IPv4 addrs (any format)

checkConfigOutput "10.0.0.0" config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-10.0.0.0.nix
checkConfigOutput "10.0.0.0/8" config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-10.0.0.0-slash-8.nix
checkConfigOutput "172.16.0.0" config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-172.16.0.0.nix
checkConfigOutput "172.16.0.0/12" config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-172.16.0.0-slash-12.nix
checkConfigOutput "172.31.255.255" config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-172.31.255.255.nix
checkConfigOutput "172.31.255.255/12" config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-172.31.255.255-slash-12.nix
checkConfigOutput "192.168.0.0" config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-192.168.0.0.nix
checkConfigOutput "192.168.0.0/16" config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-192.168.0.0-slash-16.nix
checkConfigOutput "192.168.255.255" config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-192.168.255.255.nix
checkConfigOutput "192.168.255.255/16" config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-192.168.255.255-slash-16.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-10.0.0.0-slash-7.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-172.16.0.0-slash-11.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-172.31.255.255-slash-11.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-172.32.0.0.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-172.32.0.0-slash-12.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-172.15.255.255.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-172.15.255.255-slash-12.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-192.168.0.0-slash-15.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-192.167.255.255-slash-16.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-192.169.0.0.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-192.169.0.0-slash-16.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-192.167.255.255.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-192.167.255.255-slash-16.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-0.0.0.0.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-0.0.0.0-slash-0.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-255.255.255.255.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-ipv4-255.255.255.255-slash-32.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-invalid-ipv4-1.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-invalid-ipv4-2.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-invalid-ipv4-3.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-invalid-ipv4-4.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-invalid-ipv4-5.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-invalid-ipv4-6.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid RFC 1918 IPv4 address)'." config.value ./declare-ipv4rfc1918.nix ./define-value-invalid-ipv4-7.nix


## IPv6 addrs (any format)

checkConfigOutput "1:2:3:4:5:6::7" config.value ./declare-ipv6.nix ./define-value-ipv6-1-2-3-4-5-6--7.nix
checkConfigOutput "fe80::%eth0" config.value ./declare-ipv6.nix ./define-value-ipv6-ll-scoped.nix
checkConfigOutput "1:2:3:4:5:6::7/64" config.value ./declare-ipv6.nix ./define-value-ipv6-1-2-3-4-5-6--7-slash-64.nix
checkConfigOutput "fe80::%eth0/64" config.value ./declare-ipv6.nix ./define-value-ipv6-ll-scoped-slash-64.nix
checkConfigOutput "::ffff:1.2.3.4" config.value ./declare-ipv6.nix ./define-value-ipv4-in-ipv6-ffff-1-2-3-4.nix
checkConfigOutput "::ffff:1.2.3.4/96" config.value ./declare-ipv6.nix ./define-value-ipv4-in-ipv6-ffff-1-2-3-4-slash-96.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address)'." config.value ./declare-ipv6.nix ./define-value-invalid-ipv6-1.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address)'." config.value ./declare-ipv6.nix ./define-value-invalid-ipv6-2.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address)'." config.value ./declare-ipv6.nix ./define-value-invalid-ipv6-3.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address)'." config.value ./declare-ipv6.nix ./define-value-invalid-ipv6-4.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address)'." config.value ./declare-ipv6.nix ./define-value-invalid-ipv6-5.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address)'." config.value ./declare-ipv6.nix ./define-value-invalid-ipv6-6.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address)'." config.value ./declare-ipv6.nix ./define-value-invalid-ipv6-7.nix


## IPv6 addrs (CIDR notation)

checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address with CIDR suffix)'." config.value ./declare-ipv6Cidr.nix ./define-value-ipv6-1-2-3-4-5-6--7.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address with CIDR suffix)'." config.value ./declare-ipv6Cidr.nix ./define-value-ipv6-ll-scoped.nix
checkConfigOutput "1:2:3:4:5:6::7/64" config.value ./declare-ipv6Cidr.nix ./define-value-ipv6-1-2-3-4-5-6--7-slash-64.nix
checkConfigOutput "fe80::%eth0/64" config.value ./declare-ipv6Cidr.nix ./define-value-ipv6-ll-scoped-slash-64.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address with CIDR suffix)'." config.value ./declare-ipv6Cidr.nix ./define-value-ipv4-in-ipv6-ffff-1-2-3-4.nix
checkConfigOutput "::ffff:1.2.3.4/96" config.value ./declare-ipv6Cidr.nix ./define-value-ipv4-in-ipv6-ffff-1-2-3-4-slash-96.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address with CIDR suffix)'." config.value ./declare-ipv6Cidr.nix ./define-value-invalid-ipv6-1.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address with CIDR suffix)'." config.value ./declare-ipv6Cidr.nix ./define-value-invalid-ipv6-2.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address with CIDR suffix)'." config.value ./declare-ipv6Cidr.nix ./define-value-invalid-ipv6-3.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address with CIDR suffix)'." config.value ./declare-ipv6Cidr.nix ./define-value-invalid-ipv6-4.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address with CIDR suffix)'." config.value ./declare-ipv6Cidr.nix ./define-value-invalid-ipv6-5.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address with CIDR suffix)'." config.value ./declare-ipv6Cidr.nix ./define-value-invalid-ipv6-6.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address with CIDR suffix)'." config.value ./declare-ipv6Cidr.nix ./define-value-invalid-ipv6-7.nix


## IPv6 addrs (non-CIDR)

checkConfigOutput "1:2:3:4:5:6::7" config.value ./declare-ipv6NoCidr.nix ./define-value-ipv6-1-2-3-4-5-6--7.nix
checkConfigOutput "fe80::%eth0" config.value ./declare-ipv6NoCidr.nix ./define-value-ipv6-ll-scoped.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address, no CIDR suffix)'." config.value ./declare-ipv6NoCidr.nix ./define-value-ipv6-1-2-3-4-5-6--7-slash-64.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address, no CIDR suffix)'." config.value ./declare-ipv6NoCidr.nix ./define-value-ipv6-ll-scoped-slash-64.nix
checkConfigOutput "::ffff:1.2.3.4" config.value ./declare-ipv6NoCidr.nix ./define-value-ipv4-in-ipv6-ffff-1-2-3-4.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address, no CIDR suffix)'." config.value ./declare-ipv6NoCidr.nix ./define-value-ipv4-in-ipv6-ffff-1-2-3-4-slash-96.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address, no CIDR suffix)'." config.value ./declare-ipv6NoCidr.nix ./define-value-invalid-ipv6-1.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address, no CIDR suffix)'." config.value ./declare-ipv6NoCidr.nix ./define-value-invalid-ipv6-2.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address, no CIDR suffix)'." config.value ./declare-ipv6NoCidr.nix ./define-value-invalid-ipv6-3.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address, no CIDR suffix)'." config.value ./declare-ipv6NoCidr.nix ./define-value-invalid-ipv6-4.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address, no CIDR suffix)'." config.value ./declare-ipv6NoCidr.nix ./define-value-invalid-ipv6-5.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address, no CIDR suffix)'." config.value ./declare-ipv6NoCidr.nix ./define-value-invalid-ipv6-6.nix
checkConfigError "A definition for option \`value' is not of type \`string (with check: valid IPv6 address, no CIDR suffix)'." config.value ./declare-ipv6NoCidr.nix ./define-value-invalid-ipv6-7.nix


## addrOptsV4

checkConfigOutput "1.2.3.4" config.value.address ./declare-addrOptsV4.nix ./define-value-addrOptsV4-1-2-3-4-slash-16.nix
checkConfigOutput "16" config.value.prefixLength ./declare-addrOptsV4.nix ./define-value-addrOptsV4-1-2-3-4-slash-16.nix
checkConfigError "A definition for option \`value.address' is not of type \`string (with check: valid IPv4 address, no CIDR suffix)'." config.value.address ./declare-addrOptsV4.nix ./define-value-invalid-addrOptsV4-1-2-3-4-slash-16.nix
checkConfigError "A definition for option \`value.prefixLength' is not of type \`integer between 1 and 32 (both inclusive)'." config.value.prefixLength ./declare-addrOptsV4.nix ./define-value-invalid-addrOptsV4-1-2-3-4-slash-33.nix
checkConfigError "A definition for option \`value.prefixLength' is not of type \`integer between 1 and 32 (both inclusive)'." config.value.prefixLength ./declare-addrOptsV4.nix ./define-value-invalid-addrOptsV4-1-2-3-4-slash-0.nix


## addrOptsV6

checkConfigOutput "1:2:3:4:5:6::7" config.value.address ./declare-addrOptsV6.nix ./define-value-addrOptsV6-1-2-3-4-5-6--7-slash-56.nix
checkConfigOutput "56" config.value.prefixLength ./declare-addrOptsV6.nix ./define-value-addrOptsV6-1-2-3-4-5-6--7-slash-56.nix
checkConfigError "A definition for option \`value.address' is not of type \`string (with check: valid IPv6 address, no CIDR suffix)'." config.value.address ./declare-addrOptsV6.nix ./define-value-invalid-addrOptsV6-1-2-3-4-5-6--7-slash-56.nix
checkConfigError "A definition for option \`value.prefixLength' is not of type \`integer between 1 and 128 (both inclusive)'." config.value.prefixLength ./declare-addrOptsV6.nix ./define-value-invalid-addrOptsV6-1-2-3-4-5-6--7-slash-0.nix
checkConfigError "A definition for option \`value.prefixLength' is not of type \`integer between 1 and 128 (both inclusive)'." config.value.prefixLength ./declare-addrOptsV6.nix ./define-value-invalid-addrOptsV6-1-2-3-4-5-6--7-slash-129.nix


## Ports.

checkConfigOutput "8000" config.value ./declare-port.nix ./define-value-port-8000.nix
checkConfigOutput "0" config.value ./declare-port.nix ./define-value-port-0.nix
checkConfigError "A definition for option \`value' is not of type \`integer between 0 and 65535 (both inclusive)'." config.value ./declare-port.nix ./define-value-negative-int.nix
checkConfigError "A definition for option \`value' is not of type \`integer between 0 and 65535 (both inclusive)'." config.value ./declare-port.nix ./define-value-int-65536.nix


# ## Store paths.

checkConfigOutput "" config.value ./declare-store-path.nix ./define-value-store-path-1.nix
checkConfigOutput "" config.value ./declare-store-path.nix ./define-value-store-path-2.nix
checkConfigOutput "" config.value ./declare-store-path.nix ./define-value-store-path-3.nix
checkConfigError "A definition for option \`value' is not of type \`path (with check: in the Nix store)'." config.value ./declare-store-path.nix ./define-value-non-store-path-1.nix
checkConfigError "A definition for option \`value' is not of type \`path (with check: in the Nix store)'." config.value ./declare-store-path.nix ./define-value-non-store-path-2.nix
checkConfigError "A definition for option \`value' is not of type \`path (with check: in the Nix store)'." config.value ./declare-store-path.nix ./define-value-not-a-path-1.nix
checkConfigError "A definition for option \`value' is not of type \`path (with check: in the Nix store)'." config.value ./declare-store-path.nix ./define-value-not-a-path-2.nix
checkConfigError "A definition for option \`value' is not of type \`path (with check: in the Nix store)'." config.value ./declare-store-path.nix ./define-value-not-a-path-3.nix


# ## Non-store paths.

checkConfigError "A definition for option \`value' is not of type \`path (with check: not in the Nix store)'." config.value ./declare-non-store-path.nix ./define-value-store-path-1.nix
checkConfigError "A definition for option \`value' is not of type \`path (with check: not in the Nix store)'." config.value ./declare-non-store-path.nix ./define-value-store-path-2.nix
checkConfigError "A definition for option \`value' is not of type \`path (with check: not in the Nix store)'." config.value ./declare-non-store-path.nix ./define-value-store-path-3.nix
checkConfigOutput "" config.value ./declare-non-store-path.nix ./define-value-non-store-path-1.nix
checkConfigOutput "" config.value ./declare-non-store-path.nix ./define-value-non-store-path-2.nix
checkConfigError "A definition for option \`value' is not of type \`path (with check: not in the Nix store)'." config.value ./declare-non-store-path.nix ./define-value-not-a-path-1.nix
checkConfigError "A definition for option \`value' is not of type \`path (with check: not in the Nix store)'." config.value ./declare-non-store-path.nix ./define-value-not-a-path-2.nix
checkConfigError "A definition for option \`value' is not of type \`path (with check: not in the Nix store)'." config.value ./declare-non-store-path.nix ./define-value-not-a-path-3.nix


cat <<EOF
====== module tests ======
$pass Pass
$fail Fail
EOF

if test $fail -ne 0; then
    exit 1
fi
exit 0
