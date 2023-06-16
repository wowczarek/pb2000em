# Casio PB-2000C Emulator for Windows

## Version 26-wo

This is the source for an enhanced version of Piotr Piątek's PB-2000C emulator written in / for Borland Delphi 5 and this branch corresponds to Piotr's V26 of the PB-2000C emulator.

The PB-2000C is my platform of choice and while some items may or may not end up in either the original PB-2000C emulator or any of the other emulators for related platforms by Piotr, I am  not porting any of this to other Piotr's emulators - you can do this yourself easily enough if you wish.

**Note:** *This repository does NOT contain any of the Casio ROM images required for the emulator to function.*

The compiled pb2000c.exe or the contents of the .zip file from the Releases section (including - or not - the .ini file) can be copied into the location where the extracted Piotr's emulator resides, or the required `rom0.bin`, `rom1.bin` and an optional card image `rom2.bin` can be copied in from, erm, somewhere.

Author's official website is at: http://www.pisi.com.pl/piotr433/pb2000ee.htm

The original sources reside in branch v26-piotr443.

## Main changes

### Serial port emulation

Working RS-232C serial port emulation where data is exchanged via a TCP socket which can be accessed on the host locally (default) or from the outside. The state of INT1 masking / unmasking is tracked, so no data is forwarded to the PB-2000C until it opens its serial port. Baud rate is ignored, XOFF/XON is supported and will pause and resume sending data to the PB-2000C. The serial port monitor window is mapped to the F4 key.

Serial data can be peeked in both ASCII and hex, recorded to files (TODO), and files can be buffered for transmission by dragging a file onto the serial port window. Supported both when emulating the presence of an FA-7 and an MD-100 (OptionCode setting or the new Interface setting). The serial port module operates a 64-kilobyte buffer that passes data to a 256-byte queue (size corresponding to PB's 256-byte RS232 buffer), which is gradually emptied as PB-2000C reads the data. Data can be transferred in blocks with a configurable per-block delay, which makes it possible to transfer data without XOFF/XON without buffer overruns - as long as you don't exceed a backlog of 64k that is.

The host side obviously isn't a serial port in the sense of a serial port. This is a TCP socket where the emulator listens, passing input to the emulated PB-2000C's serial port and passing output to the TCP client. This can be set up as a serial port in your Windows system using any of the available "Virtual COM port" type drivers, if you really need this to be a serial port, although no baud rate negotiation or anything similar will be done unless the virtual serial port does that - it's a straight up TCP pipe. This was developed mostly to assist with the development of the PBNET project: https://github.com/wowczarek/pbnet - but can of course be used by any application you may want to develop, or can be used with the likes of netcat / socat to send files.

### pb2000c.ini with all supported settings

https://github.com/wowczarek/pb2000em/blob/5cec33b42d2d4356e42b9ea02c64a62ef78f7ebb/pb2000c.ini


### Remote control protocol

A TCP-based remote control protocol was added with a simple but extensive command parser. It is part-ASCII, part-binary, where command entry is exclusively ASCII which makes it possible to comfortably use it via e.g. a raw telnet or netcat 
session. Characters are accepted as is, while keys and commands take the form of `<name [arg1] ... [argN] [?|!]>`. Arguments are unnamed, and an optional request identifier before the closing `>` that can be a `?` for *requests* (send me some data) or `!` for *commands* (do something and optionally send me some data). Key names and request names are case-insensitive, and the `<` character needs to be escaped with another `<`.

#### Functionality:

- direct character entry, including ANSI escape sequences for cursor keys as well as del, esc, tab, bs, meaning that text can be entered without issues
- named key entry in the form of `<key>` where the keys mostly match what's on the key face of the PB-2000C, such as `<menu>`, `<s>`, `<cls>` - supported for most function keys. The silver keys under the LCD are `<m1> ... <m4>` and `<etc>`. Currently not supported are the `[memo]` and `[in/out/calc]` keys. This sends keyboard shortcuts to the emulator rather than Casio key codes to the CPU - this will be changed so it's independent from keyboard shortcut mappings (TODO)
- requests, where we ask the emulator for some data or for state: `<version?>`,`<power?>`,`<pause?>`, also reading the LCD controller memory through `<vmem?>`, reading the current breakpoint with `<bkpt?>` (TODO) and reading registers via `<regs?>` (TODO)
- commands with optional parameters, such as `<power off!>`, `<power on!>` `<power!>` (toggle), `<pause on!>`, `<pause off!>`, `<pause!>` (toggle), `<getmem [bank, decimal] [start, hex] [len, decimal]!>` (TODO), `<savemem!>` to save memory to disk without exiting the emulator, `<bkpt [hex addr]!>` (TODO), `<bkpt off!>` and `<bkpt on!>` (TODO).
- key entry is buffered and executed in configurable intervals (max queue: 2048 keys), where commands and requests are executed immediately
- multiple concurrent sessions (up to 8, but this is an arbitrary choice), so multiple clients can execute commands simultaneously, such as one remote LCD viewer and one remote keyboard
- a startup macro which is a key sequence executed on first power on, configured using the `[Remote]` → `Autorun` setting in the .ini file - this can be used to do, well, anything you want, on startup, especially with ROMs lacking an `auto.exe` type functionality

This allows e.g. remote scripted demos, or creating alternative keyboard and LCD presentations, let's say a web viewer for the LCD, or if you so wish, a physical LCD or lights in a tower building (hint! someone do this please!). I've written a simple LCD viewer for Linux to demo this, which displays PB2000C's LCD in a console window using Unicode block elements at configurable frame rate - source to be published on GitHub. This protocol will also be the basis for the operation of a headless PB-2000C emulator I am planning to write, which will be (of course) based on Piotr's work, but running in a GUI-free setting.

#### Response format:

A new connection is greeted by sending a string `EMHELLO` to the client. Simple responses to requests such as `<power?>` etc, are an ASCII string in the form of `KEY=VALUE`. Responses with binary data are prepended with the command name that requested it, such as `VMEM` with 1536 nibble-occupied bytes following. Reading of registers will likely take two forms, one ASCII and one binary, such as `<regs?>` and `<regs bin?>`.

### Usability (keyboard)

- Automatic prepending of keys requiring `[s]` key with an `[s]`, meaning you can enter `?!#{}$@` etc. without issues. This triggers the `[s]` key to be held while the requested key is held, and sends the relevant combination key on key release. This was by far the most frustrating aspect of using both the PB-2000C itself and the emulator while trying to enter a program.
- Extensive list of keyboard shortcuts. Full list:

| Key | Function / key mapping |
| ---- | ---- |
| F2 | Toggle keyboard overlay |
| F3 | Halt CPU and open debug window |
| F4 | Toggle serial port monitor window |
| F5 | Toggle remote control status window |
| F12\* | `<cls>` |
| Menu / Apps ("right click") key | `<menu>` |
| Shift + Menu | `<cal>` |
| Shift-F1 | `<m1>` = first key under LCD |
| Shift-F2 | `<m2>` = second key under LCD |
| Shift-F3 | `<m3>` = third key under LCD |
| Shift-F4 | `<m4>` = fourth key under LCD |
| Shift-F5 | `<etc>` |
| Shift-F9 | Toggle power on/off |
| PgDn | `<caps>` |
| PgUp | `<s>`, the red Shift key. See also https://en.wikipedia.org/wiki/Redshift for some physics fun |
| Alt | `<ans>` |
| Esc | `<brk>`, also power on if PB-2000C sleeping |
| Backspace\* | `<bs>` |
| Ins\* | `<ins>` |
| Del\* | `<del>` |
| Return | `<exe>` |
| Tab | `<tab>` |
| Up / Dn / Left / Right \*| ditto |

\* - Keys which can be combined with `[s]` such as arrows, CLS etc., will also have `[s]` automatically prepended when pressed with Shift. If CLS = F12 then Shift-F12 executes `[s]` followed shortly by `[cls]`.

## Any Other Business / notes

For now this is being developed in Borland Delphi 5 just like the original, but ideally I want this to eventually be ported to Lazarus, to make this easier for people to build, even though Delphi 5 can easily be had from archive.org or similar these days, but it may require you to run it in a VM because it doesn't play particularly well with Windows 10 and up. Porting to Lazarus is still undecided as after some discussions with Piotr, this has some extra consequences for some emulated platforms and otherwise platforms people run the emulator on.
