#!/usr/bin/env python
# script to dump HP48 fonts (any grob, actually)

import struct, sys

HP48_OBJECT_HEADER	= 'HPHP48-E'


def read_nibble_string(data, offset, length):
    bytelen = length / 2
    if offset % 2 or length % 2:
        bytelen += 1
    byteoff = offset / 2
    bytes = struct.unpack_from('%dB' % bytelen, data, byteoff)[::-1]
    #print map(hex, bytes)

    value = start = 0
    end = len(bytes)
    if (offset + length) % 2:
        value <<= 4
        value |= bytes[0] & 0xf
        start = 1
    if offset % 2:
        end = -1
    for b in bytes[start:end]:
        value <<= 4
        value |= (b & 0xf0) >> 4
        value <<= 4
        value |= b & 0xf
    if offset % 2:
        value <<= 4
        value |= (bytes[-1] & 0xf0) >> 4
    return value
    #print '%d (%X)' % (value, value)


def read_grob(data):
    if not data.startswith(HP48_OBJECT_HEADER):
        return 1

    print >> sys.stderr, 'prologue: %Xh' % read_nibble_string(data, 16, 5)
    l = read_nibble_string(data, 21, 5)
    print >> sys.stderr, 'length:', l
    h = read_nibble_string(data, 26, 5)
    print >> sys.stderr, 'height:', h
    w = read_nibble_string(data, 31, 5)
    print >> sys.stderr, 'width:', w

    nibs = w / 4
    if nibs % 2:
        nibs += 1
    print >> sys.stderr, "nibs per line:", nibs

    # ensure that we're read everything correctly
    assert l == nibs * h + 15

    # symbol we start emitting a font with
    startchar = ord(' ')

    offset = 16 + 20 + startchar * nibs * 8

    print '#include <inttypes.h>\n\nconst unsigned char font_5x7[][8] = {'
    for i in xrange(8 * (128 - startchar)):
#        value = 0
        char = read_nibble_string(data, offset, nibs)

        if not i % 8:
            print "/* %c (0x%X) */" % (startchar + i / 8,
              startchar + i / 8)
            print '\t{',
#        for b in xrange(8):
#            value <<= 4
#            if (char >> b) & 1:
#                value |= 0xf
#            else:
#                pass
        #print '0x%04X%04X,' % (value & 0xffff, value >> 16),
        print '0x%02X,' % char,
#        if i % 8 == 3:
#            print '\n\t ',
        if i % 8 == 7:
            print '},'
        offset += nibs
    print '};'


def main(argv=[__name__]):
    if len(argv) == 2:
        with open(argv[1]) as f:
            filedata = f.read()
        assert filedata, 'failed to get data from %s' % arvg[1]
        return read_grob(filedata)
    else:
        print >> sys.stderr, "usage: %s some_hp_font.grob" % argv[0]


if __name__ == '__main__':
    sys.exit(main(sys.argv))
