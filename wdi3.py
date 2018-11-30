#!/usr/bin/env python3.7
#
# Requires 3 because of print() and subprocess.run()
# Requires 3.7 because of subprocess.run(..., capture_output=True)
#

import getopt, struct, sys
from subprocess import call, run

VSC_ENABLE = 0x45
VSC_DISABLE = 0x44

VSC_KEY_READ = 0x01
VSC_KEY_WRITE = 0x02

force = False
verbose_print = lambda *a, **k: None

def check_WDC_drive(dev):
    print('Checking if %s is a Western Digital drive...' % dev, end='')

    from os import getuid, path, stat
    from stat import S_ISCHR

    # Perform some extra sanity checks first...
    if not path.exists('/dev/%s' % dev):
        print(' nonexistent device')
        return False
    if not S_ISCHR(stat('/dev/%s' % dev).st_mode):
        print(' not a character device')
        return False

    p = run(['camcontrol', 'cmd', dev, '-v', '-a',
      'EC 00 00 00 00 00 00 00 00 00 01 00', '-i', '512', '-'],
      capture_output=True)
    if p.returncode != 0:
        print(' failed')
        # Hint: camcontrol(8) requires root to access /dev/xpt0
        if getuid() != 0: print('Are you running %s as root?' % sys.argv[0])
        return False

    # XXX: should probably check for "FX", "NEC", "Pioneer", or "SHARP"
    # because they don't require byteswap, but I haven't seen those in
    # usage for quite a while, so let's just waive the check for now :)

    model = struct.pack('<20H', *struct.unpack_from('>20H', p.stdout, 54))
    if model[:3] == b'WDC': print(' apparently so!'); return True

    print(' no :(')
    print('The drive says its model is %s' % model.strip().decode())

    if not force: return False
    verbose_print('Proceeding anyway because --force option was given')
    return True

def VSC_toggle(dev, feat):
    assert feat in (VSC_ENABLE, VSC_DISABLE), \
      'bad VSC enable/disable feature (subcommand) 0x%02X' % feat
    verbose_print('%sabling Vendor Specific ATA commands on %s' %
      ('En' if feat == VSC_ENABLE else 'Dis', dev))
    rc = call(['camcontrol', 'cmd', dev, '-v', '-a',
      '80 %02X 00 44 57 00 00 00 00 00 00 00' % feat])
    return rc == 0

def VSC_send_key(dev, rw):
    assert rw in (VSC_KEY_READ, VSC_KEY_WRITE), \
      'bogus key read/write specification 0x%02X' % rw
    key = struct.pack('<6H500x', 0x2A, rw, 0x02, 0x0D, 0x16, 0x01)
    verbose_print('Sending %s Key to %s' %
      ('Read' if rw == VSC_KEY_READ else 'Write', dev))
    # XXX: cannot use classic call() because we need to pass data on stdin
    p = run(['camcontrol', 'cmd', dev, '-v', '-a',
      'B0 D6 BE 4F C2 00 00 00 00 00 01 00', '-o', '512', '-'], input=key)
    return p.returncode == 0

def VSC_get_timer(dev):
    verbose_print('Reading current timer value on %s' % dev)
    p = run(['camcontrol', 'cmd', dev, '-v', '-a',
      'B0 D5 BF 4F C2 00 00 00 00 00 01 00', '-i', '512', '-'],
      capture_output=True)
    # Since timer is always >= 0, return negative value for error
    return p.stdout[0] if p.returncode == 0 else -p.returncode

def VSC_set_timer(dev, t):
    assert 0 <= t <= 255, 'bogus timer value %d (0x%02X)' % (t, t)
    req = struct.pack('<B511x', t)
    verbose_print('Setting Idle3 Timer to %d (0x%02X) on %s' % (t, t, dev))
    p = run(['camcontrol', 'cmd', dev, '-v', '-a',
      'B0 D6 BF 4F C2 00 00 00 00 00 01 00', '-o', '512', '-'], input=req)
    return p.returncode == 0

def pretty_print_timer(t, what):
    if t == 0: print('Idle3 Timer %s disabled' % what); return

    print('Idle3 Timer %s enabled and set to' % what, end='')

    t100 = t/10.0
    t105 = (t-128)*30

    if t < 129:
        print(' %.1f seconds (per WDIdle3 v1.00/1.03/1.05)' % t100)
    else:
        print(':\n  per WDIdle3 v1.00:      %.1f seconds'
               '\n  per WDIdle3 v1.03/1.05: %d seconds%s' % (t100,
          t105, ' (%.1f minutes)' % (t105/60) if t105 > 120 else ''))

def get_timer(dev):
    if not check_WDC_drive(dev): return 2
    if not VSC_toggle(dev, VSC_ENABLE): return 3
    if not VSC_send_key(dev, VSC_KEY_READ):
        VSC_toggle(dev, VSC_DISABLE)
        return 4

    timer = VSC_get_timer(dev)
    if timer < 0:
        print('Failed to get Idle3 Timer :(')
        VSC_toggle(dev, VSC_DISABLE)
        return 5
    verbose_print('Raw timer value is %d (0x%02X)' % (timer, timer))
    pretty_print_timer(timer, 'is')

    VSC_toggle(dev, VSC_DISABLE)
    return 0

def set_timer(dev, timer):
    if not check_WDC_drive(dev): return 2
    if not VSC_toggle(dev, VSC_ENABLE): return 3
    if not VSC_send_key(dev, VSC_KEY_WRITE):
        VSC_toggle(dev, VSC_DISABLE)
        return 4

    if not VSC_set_timer(dev, timer):
        print('Failed to set Idle3 Timer :(')
        rc = 5
    else:
        pretty_print_timer(timer, 'was')
        rc = 0

    VSC_toggle(dev, VSC_DISABLE)
    return rc

def usage():
    print("""Read, set, or disable the Idle3 Timer on Western Digital drives
Based on the information provided by Christophe Bothamy (the author
of the "idle3-tools"): http://idle3-tools.sourceforge.net/
This is camcontrol(8)-based implementation for FreeBSD by DAN|Fe

usage: %s [options] device
options:

  -h, --help : display help (usage)
  -v : verbose output
  --force : force even if the drive is not Western Digital
  -g : report current Idle3 Timer value (default operation)
  -d : disable Idle3 Timer
  -r : same as -g (for compatibility with WDIDLE3 for DOS)
  -s <0~255> : set Idle3 Timer raw value""" % sys.argv[0], file=sys.stderr)
    sys.exit(1)

def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], 'dghrs:v', ['help', 'force'])
    except getopt.GetoptError as e:
        print('>>> %s\n' % e, file=sys.stderr)
        usage()
    if not args: usage()

    timer = None
    global force, verbose_print

    for o, a in opts:
        if o == '-d':
            timer = 0
        elif o == '--force':
            force = True
        elif o in ('-g', '-r'):
            # Default operation, for compatibility with original utilities
            pass
        elif o in ('-h', '--help'):
            usage()
        elif o == '-s':
            try: timer = int(a, 16 if a[:2] == '0x' else 10)
            except ValueError as e:
                print('>>> %s\n' % e, file=sys.stderr); usage()
        elif o == '-v':
            verbose_print = print
        else:
            assert False, 'unhandled option'

    if timer is not None and not 0 <= timer <= 255:
        print('>>> requested value %d (0x%02X) out of range\n' %
          (timer, timer), file=sys.stderr); usage()

    return get_timer(args[0]) if timer is None else set_timer(args[0], timer)

if __name__ == '__main__':
    sys.exit(main())
