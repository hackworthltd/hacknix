#!/usr/bin/env python
#
# TrimPCAP 1.1
#
# Trims capture files (PCAP and PCAP-NG) by truncating flows to a
# desired max size
#
# Created by: Erik Hjelmvik, NETRESEC
# Modifications by Drew Hess <src@drewhess.com>
# Open Source License: GPLv2
#
# Usage: trimpcap.py somefile1.pcap somefile2.pcap
# Usage: trimpcap.py --flowsize 100000 --replace *.pcap
#
# ==DEPENDENCIES==
# python 2.6 or 2.7
# pip install dpkt
# pip install repoze.lru
#
# On Debian/Ubuntu you can also do:
# apt-get install python-dpkt python-repoze.lru
#
#
# ==CHANGE LOG==
# TrimPCAP 1.1
# * Added a strategy to handle fragmented IP packets.
#   Thanks to Mark Eldridge for notifying us about this bug!
#

import argparse
import dpkt
import socket
import sys
import os
from repoze.lru import LRUCache

__version__ = '1.1.1'


def inet_to_str(ip_addr):
    try:
        return socket.inet_ntop(socket.AF_INET, ip_addr)
    except ValueError:
        return socket.inet_ntop(socket.AF_INET6, ip_addr)


def get_fivetuple_from_ip(ip):
    try:
        src = inet_to_str(ip.src) + ":"
        dst = inet_to_str(ip.dst) + ":"
        proto = 0
        if ip is not None:
            proto = ip.p
            if ip.offset == 0 and (ip.p == dpkt.ip.IP_PROTO_TCP or ip.p == dpkt.ip.IP_PROTO_UDP):
                src += str(ip.data.sport)
                dst += str(ip.data.dport)
    except dpkt.dpkt.NeedData:
        pass
    except AttributeError:
        pass
    if src < dst:
        return str(proto) + "_" + src + "-" + dst
    else:
        return str(proto) + "_" + dst + "-" + src


def get_fivetuple(buf, pcap, pcap_file):
    if pcap.datalink() == dpkt.pcap.DLT_LINUX_SLL:
        sll = dpkt.sll.SLL(buf)
        return get_fivetuple_from_ip(sll.data)
    elif pcap.datalink() == dpkt.pcap.DLT_IEEE802 or pcap.datalink() == dpkt.pcap.DLT_EN10MB:
        try:
            ethernet = dpkt.ethernet.Ethernet(buf)
            if ethernet.type == dpkt.ethernet.ETH_TYPE_IP:
                return get_fivetuple_from_ip(ethernet.data)
            else:
                return None
        except dpkt.UnpackError as e:
            return None
    elif pcap.datalink() == dpkt.pcap.DLT_RAW or pcap.datalink() == dpkt.pcap.DLT_LOOP:
        # Raw IP only supported for ETH_TYPE 0x0c. Type 0x65 is not supported by DPKT
        return get_fivetuple_from_ip(dpkt.ip.IP(buf))
    elif pcap.datalink() == dpkt.pcap.DLT_NULL:
        frame = dpkt.loopback.Loopback(buf)
        return get_fivetuple_from_ip(frame.data)
    else:
        print >> sys.stderr, "unknown datalink in " + pcap_file
        exit


def trim(flist, flowmaxbytes, trimmed_extension, preserve_times, post_process):
    cache = LRUCache(10000)
    trimmed_bytes = 0
    for pcap_file in flist:
        trimmed_file = pcap_file + trimmed_extension
        with open(pcap_file, "rb") as f:
            try:
                if pcap_file.endswith("pcapng"):
                    pcap = dpkt.pcapng.Reader(f)
                else:
                    pcap = dpkt.pcap.Reader(f)
                with open(trimmed_file, "wb") as trimmed:
                    if pcap_file.endswith("pcapng"):
                        pcap_out = dpkt.pcapng.Writer(trimmed)
                    else:
                        pcap_out = dpkt.pcap.Writer(trimmed)
                    for ts, buf in pcap:
                        fivetuple = get_fivetuple(buf, pcap, pcap_file)
                        bytes = len(buf)
                        if not cache.get(fivetuple) is None:
                            bytes += cache.get(fivetuple)
                        cache.put(fivetuple, bytes)
                        if bytes < flowmaxbytes:
                            pcap_out.writepkt(buf, ts)
                        else:
                            trimmed_bytes += len(buf)
            except dpkt.dpkt.NeedData: pass
            except ValueError: pass
        if os.path.exists(trimmed_file):
            if preserve_times:
                stat = os.stat(pcap_file)
                os.utime(trimmed_file, (stat.st_atime, stat.st_mtime))
            if post_process:
                post_process(pcap_file, trimmed_file)
    return trimmed_bytes


def post_replace(orig, trimmed):
    os.rename(trimmed, orig)


def post_delete(orig, _):
    os.remove(orig)


def nonempty_string(string):
    if string is None or string == "":
        raise argparse.ArgumentTypeError("cannot be the empty string")
    return string


def main():
    parser = argparse.ArgumentParser(
        prog='trimpcap',
        description='Trim pcap files by truncating flows to a desired max size')
    parser.add_argument('files', metavar='FILE', nargs='+', help='A pcap file')
    parser.add_argument('--extension', '-x', metavar='EXT', type=nonempty_string,
                        default='.trimmed',
                        help='Filename extension used while writing trimmed file')
    parser.add_argument('--flowsize', '-s', metavar='BYTES', type=int,
                        default=8192, help='Trim flows to this size (in bytes)')
    parser.add_argument('--preserve-file-times', '-p', action='store_true',
                        help="Preserve the original file's mtime, atime, etc.")
    parser.add_argument('--version', action='version',
                        version='%(prog)s {}'.format(__version__))
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--replace', '-r', action='store_true',
                       help='Replace the original file with the trimmed one')
    group.add_argument('--delete', '-D', action='store_true',
                       help='Delete the original file')
    args = parser.parse_args()

    flist = list()
    print "Trimming capture files to max {} bytes per flow with extension {}.".format(args.flowsize, args.extension)
    source_bytes = 0
    postproc = None
    if args.delete:
        postproc = post_delete
    elif args.replace:
        postproc = post_replace
    for file in args.files:
        if not os.path.exists(file):
            print "ERROR: File " + file + " does not exist!"
        else:
            flist.append(file)
            source_bytes += os.path.getsize(file)
    trimmed_bytes = trim(flist, args.flowsize, args.extension, args.preserve_file_times, postproc)
    if source_bytes > 0 and trimmed_bytes > 0:
        print "Dataset reduced by {0:.2f}% = {1} bytes".format(trimmed_bytes * 100.0 / source_bytes, trimmed_bytes)
    else:
        print "No files were trimmed"


if __name__ == "__main__":
    main()
