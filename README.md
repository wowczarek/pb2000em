# Casio PB-2000C Emulator for Windows, version 26-WO

This is the source for the enhanced version of Piotr Piątek's PB-2000C emulator written in / for Borland Delphi 5 and this branch corresponds to Piotr's V26 of the PB-2000C emulator.

PB-2000C is my platform of choice. While some items may or may not end up in either the original PB-2000C emulator or any of the other emulators of related platforms by Piotr, I am  not porting any of this to other Piotr's emulators - you can do this yourself easily enough if you wish.

This repository does NOT contain any of the Casio ROM images required for the emulator to function.

The compiled pb2000c.exe or the contents of the .zip file from the Releases section (including - or not - the .ini file) can be copied into the location where the extracted Piotr's emulator resides.

Author's official website is at: http://www.pisi.com.pl/piotr433/pb2000ee.htm

The original sources reside in the branch: v26-piotr443

## Main changes

### Usability (keyboard)

- Extensive list of keyboard shortcuts for various keys - keys to be finalised
- Automatic prepending of keys requiring [s] key with [s], meaning you can enter ?!#{}$@ etc. without issues.
- Keys which can be combined with [s] such as arrows, CLS etc., will also have [s] automatically prepended when pressed with Shift. If CLS = F12 then Shift-F12 executes [s] followed shortly by [cls].

### Serial port emulation

Working RS-232C serial port emulation where data is exchanged via a TCP socket which can be accessed on the host locally (default) or from the outside. The state of INT1 masking / unmasking is tracked, so no data is forwarded to the PB-2000C until it opens its serial port. Baud rate is ignored and so is flow control, in favour of controlled RX queue management.

Serial data can be peeked in both ASCII and hex, recorded to files (TODO), and files can be transmitted to the serial port (TODO). Supported both when emulating the presence of an FA-7 and an MD-100 (OptionCode setting or the new Interface setting). The serial port module operates a 1024-byte queue which is gradually emptied as PB-2000C reads the data. The plan is to implement a 64-kilobyte buffer in combination with the queue, with queue level monitoring that can maintain the queue at configurable certain maximum depth and move data from the buffer to the queue only once the queue is emptied or drops below the maximum fill level. This will guarantee overrun-free operation at maximum speed, as long as you don't exceed a backlog of 64 kilobytes.

The host side obviously isn't a serial port in the sense of a serial port. This is a TCP socket where the emulator listens, passing input to the emulated PB-2000C's serial port and passing output to the TCP client. This can be set up as a serial port in your Windows system using any of the available "Virtual COM port" type drivers, if you really need this to be a serial port, although no baud rate negotiation or anything similar will be done unless the virtual serial port does that - it's a straight up TCP pipe. This was developed mostly to assist with the development of the PBNET project: https://github.com/wowczarek/pbnet - but can of course be used by any application you may want to develop, or can be used with the likes of netcat / socat to send files.

### pb2000c.ini with all supported settings


### Remote control protocol

A TCP-based remote control protocol was added with a simple but extensive command parser. It is part-ASCII, part-binary, where command entry is exclusively ASCII which makes it possible to comfortably use it via e.g. a raw telnet or netcat session.

Supports:

- direct character entry, including ANSI escape sequences for cursor keys as well as del, esc, tab, bs, meaning that text can be entered without issues
- named key entry in the form of <key> where the keys mostly match what's on the key face of the PB-2000C, such as <menu>, <s>, <cls> - supported for most function keys. The silver keys under the LCD are <m1> ... <m4> and <etc>. Currently not supported are the [memo] and [in/out/calc] keys. This sends keyboard shortcuts to the emulator rather than Casio key codes to the CPU - this will be changed so it's independent from keyboard shortcut mappings (TODO)
- requests, where we ask the emulator for some data or for state, such as <version?>,<power?>,<pause?>, also reading the LCD controller memory through <vmem?>, reading current breakpoint via <bkpt?> (TODO), reading registers via <regs?> (TODO)
- commands with optional parameters, such as <power off!>, <power on!> <power!> (toggle), <pause on!>, <pause off!>, <pause!> (toggle), <getmem [bank, decimal] [start, hex] [len, decimal]!> (TODO), <savemem!> to save memory to disk without exiting the emulator, <bkpt [hex addr]!> <bkpt off!> <bkpt on!> (TODO)
- key entry is buffered and executed in configurable intervals (max queue: 2048 keys), where commands and requests are executed immediately.
- multiple concurrent sessions (up to 8, but this is an arbitrary choice), so multiple clients can execute commands simultaneously, such as one remote LCD viewer and one remote keyboard

This allows e.g. remote scripted demos, or creating alternative keyboard and LCD presentations, let's say a web viewer for the LCD, or if you so wish, a physical LCD or lights in a tower building (hint! someone do this please!). I've written a simple LCD viewer for Linux to demo this, which displays PB2000C's LCD in a console window using Unicode block elements at configurable frame rate - source to be published on GitHub. This protocol will also be the basis for the operation of a headless PB-2000C emulator I am planning to write, which will be (of course) based on Piotr's work, but running in a GUI-free setting.

For now this is being developed in Borland Delphi 5 just like the original, but ideally I want this to eventually be ported to Lazarus, to make this easier for people to build, even though Delphi 5 can easily be had from archive.org or similar these days, but it may require you to run it in a VM because it doesn't play particularly well with Windows 10 and up. Porting to Lazarus is still undecided as after some discussions with Piotr, this has some extra consequences for some emulated platforms and otherwise platforms people run the emulator on.
