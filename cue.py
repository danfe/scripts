#!/usr/bin/env python
#
# small script to fixup broken cue sheets since EAC cannot work with chinese
# characters correctly
#

import re
import sys


def usage(prog):
    print >> sys.stderr, \
    """usage: %(prog)s track_list_file cue_file_to_fix""" % { 'prog' : prog }


def read_track_names(file):
    info = {}
    cd_rec = re.compile(r'^CD: (.+) - (.+)$')
    tr_rec = re.compile(r'^(\d+)\. (.*\S) +\[[0-9:.]+\]$')

    with open(file, 'r') as f: lines = f.readlines()
    for line in lines:
        match = cd_rec.search(line)
        if match:
            info['artist'], info['title'] = match.group(1, 2)
        else:
            match = tr_rec.search(line)
            if match: info[match.group(1)] = match.group(2)
    return info


def fixup_cue_sheet(file, info):
    artist_rec = re.compile(r'PERFORMER')
    title_rec = re.compile(r'TITLE')
    track_rec = re.compile(r'^  TRACK (\d+) AUDIO$')
    file_rec = re.compile(r'^FILE')
    cur_track = 0

    with open(file, 'r') as f: lines = f.readlines()
    for line in lines:
        match = track_rec.search(line)
        if match: cur_track = match.group(1)

        if artist_rec.search(line):
            if cur_track: print '    PERFORMER "%s"' % info['artist']
            else: print 'PERFORMER "%s"' % info['artist']
        elif title_rec.search(line):
            if cur_track: print '    TITLE "%s"' % info[cur_track]
            else: print 'TITLE "%s"' % info['title']
        elif file_rec.search(line):
            print 'FILE "%s - %s.wav"' % (info['artist'], info['title'])
        else: print line,


def main(argv=[__name__]):
    if len(argv) != 3:
        usage(argv[0])
    fixup_cue_sheet(argv[2], read_track_names(argv[1]))


if __name__ == '__main__':
    sys.exit(main(sys.argv))
