{ HD61700 disassembler }

unit Dis;

interface

  function ScanMnemTab: word;
  function Mnemonic (index: word): string;
  function Arguments (index: word): string;


implementation

uses Def, SysUtils;

type

  kinds = (
    ILLOP,	{ illop }
    NONE,	{ nop }
    CC,		{ rtn z }
    JRCC,	{ jr z, relative_address }
    JPCC,	{ jp z, absolute_address }
    JR,		{ jr relative_address }
    JP,		{ jp absolute_address }
    REGREGJR,	{ ld reg, reg, optional_jr }
    REGDIRJR,	{ ld reg, (reg), optional_jr }
    REGJR,	{ stl reg, optional_jr }
    REGIRR,	{ st reg, (IX+/-reg) }
    REGIRRIM3,	{ stm reg, (IX+/-reg), IM3 }
    REG,	{ phs reg }
    DIR,	{ jp (reg) }
    IRRREG,	{ adc (IX+/-reg), reg }
    REGIM8JR,	{ adc reg, IM8, optional_jr }
    IM8,	{ stl IM8 }
    IM8A,	{ ppo IM8 }
    R8IM8,	{ pst PE,IM8 }
    REGIRI,	{ st reg, (IX+/-IM8) }
    IRIREG,	{ adc (IX+/-IM8), reg }
    R8REGJR,	{ gst reg_8bit, reg, optional_jr }
    R16REGJR,	{ pre reg_16bit, reg, optional_jr }
    R16IM16,	{ pre reg_16bit, IM16 }
    IM8IND,	{ st IM8,($sir) }
    IM16IND,	{ stw IM16,($sir) }
    RRIM3JR,	{ adbm reg, reg, IM3, optional_jr }
    RIM5IM3JR,	{ adbm reg, IM5, IM3, optional_jr }
    REGIM8,	{ ld reg,IM8 without optional jr }
    REGIM16,	{ ldw reg,IM16 }
    REGIM3,	{ stlm reg,IM3 }
    SIRREGJR,	{ psr sir, reg, optional_jr }
    SIRREGIM3,	{ psr sir, reg, IM3 }
    SIRIM5	{ psr sir, IM5 }
  );


  tab = record
    str: string[5];
    case boolean of
      True: (ext: word);
      False: (kind: kinds);
  end;


const

  mnem: array[0..255+22*4] of tab = (
    (	str:'adc';	kind:REGREGJR	),	{ code $00 }
    (	str:'sbc';	kind:REGREGJR	),	{ code $01 }
    (	str:'ld';	kind:REGREGJR	),	{ code $02 }
    (	str:'ldc';	kind:REGREGJR	),	{ code $03 }
    (	str:'anc';	kind:REGREGJR	),	{ code $04 }
    (	str:'nac';	kind:REGREGJR	),	{ code $05 }
    (	str:'orc';	kind:REGREGJR	),	{ code $06 }
    (	str:'xrc';	kind:REGREGJR	),	{ code $07 }
    (	str:'ad';	kind:REGREGJR	),	{ code $08 }
    (	str:'sb';	kind:REGREGJR	),	{ code $09 }
    (	str:'adb';	kind:REGREGJR	),	{ code $0A }
    (	str:'sbb';	kind:REGREGJR	),	{ code $0B }
    (	str:'an';	kind:REGREGJR	),	{ code $0C }
    (	str:'na';	kind:REGREGJR	),	{ code $0D }
    (	str:'or';	kind:REGREGJR	),	{ code $0E }
    (	str:'xr';	kind:REGREGJR	),	{ code $0F }
    (	str:'st';	kind:REGDIRJR	),	{ code $10 }
    (	str:'ld';	kind:REGDIRJR	),	{ code $11 }
    (	str:'0';	ext:256+0*4	),	{ code $12 }
    (	str:'0';	ext:256+18*4	),	{ code $13 }
    (	str:'0';	ext:256+1*4	),	{ code $14 }
    (	str:'psr';	kind:SIRREGJR	),	{ code $15 }
    (	str:'pst';	kind:R8REGJR	),	{ code $16 }
    (	str:'pst';	kind:R8REGJR	),	{ code $17 }
    (	str:'0';	ext:256+2*4	),	{ code $18 }
    (	str:'****';	kind:ILLOP	),	{ code $19 }
    (	str:'0';	ext:256+3*4	),	{ code $1A }
    (	str:'0';	ext:256+4*4	),	{ code $1B }
    (	str:'0';	ext:256+5*4	),	{ code $1C }
    (	str:'gsr';	kind:SIRREGJR	),	{ code $1D }
    (	str:'gst';	kind:R8REGJR	),	{ code $1E }
    (	str:'gst';	kind:R8REGJR	),	{ code $1F }
    (	str:'st';	kind:REGIRR	),	{ code $20 }
    (	str:'st';	kind:REGIRR	),	{ code $21 }
    (	str:'sti';	kind:REGIRR	),	{ code $22 }
    (	str:'sti';	kind:REGIRR	),	{ code $23 }
    (	str:'std';	kind:REGIRR	),	{ code $24 }
    (	str:'std';	kind:REGIRR	),	{ code $25 }
    (	str:'phs';	kind:REG	),	{ code $26 }
    (	str:'phu';	kind:REG	),	{ code $27 }
    (	str:'ld';	kind:REGIRR	),	{ code $28 }
    (	str:'ld';	kind:REGIRR	),	{ code $29 }
    (	str:'ldi';	kind:REGIRR	),	{ code $2A }
    (	str:'ldi';	kind:REGIRR	),	{ code $2B }
    (	str:'ldd';	kind:REGIRR	),	{ code $2C }
    (	str:'ldd';	kind:REGIRR	),	{ code $2D }
    (	str:'pps';	kind:REG	),	{ code $2E }
    (	str:'ppu';	kind:REG	),	{ code $2F }
    (	str:'jp';	kind:JPCC	),	{ code $30 }
    (	str:'jp';	kind:JPCC	),	{ code $31 }
    (	str:'jp';	kind:JPCC	),	{ code $32 }
    (	str:'jp';	kind:JPCC	),	{ code $33 }
    (	str:'jp';	kind:JPCC	),	{ code $34 }
    (	str:'jp';	kind:JPCC	),	{ code $35 }
    (	str:'jp';	kind:JPCC	),	{ code $36 }
    (	str:'jp';	kind:JP		),	{ code $37 }
    (	str:'adc';	kind:IRRREG	),	{ code $38 }
    (	str:'adc';	kind:IRRREG	),	{ code $39 }
    (	str:'sbc';	kind:IRRREG	),	{ code $3A }
    (	str:'sbc';	kind:IRRREG	),	{ code $3B }
    (	str:'ad';	kind:IRRREG	),	{ code $3C }
    (	str:'ad';	kind:IRRREG	),	{ code $3D }
    (	str:'sb';	kind:IRRREG	),	{ code $3E }
    (	str:'sb';	kind:IRRREG	),	{ code $3F }
    (	str:'adc';	kind:REGIM8JR	),	{ code $40 }
    (	str:'sbc';	kind:REGIM8JR	),	{ code $41 }
    (	str:'ld';	kind:REGIM8JR	),	{ code $42 }
    (	str:'ldc';	kind:REGIM8JR	),	{ code $43 }
    (	str:'anc';	kind:REGIM8JR	),	{ code $44 }
    (	str:'nac';	kind:REGIM8JR	),	{ code $45 }
    (	str:'orc';	kind:REGIM8JR	),	{ code $46 }
    (	str:'xrc';	kind:REGIM8JR	),	{ code $47 }
    (	str:'ad';	kind:REGIM8JR	),	{ code $48 }
    (	str:'sb';	kind:REGIM8JR	),	{ code $49 }
    (	str:'adb';	kind:REGIM8JR	),	{ code $4A }
    (	str:'sbb';	kind:REGIM8JR	),	{ code $4B }
    (	str:'an';	kind:REGIM8JR	),	{ code $4C }
    (	str:'na';	kind:REGIM8JR	),	{ code $4D }
    (	str:'or';	kind:REGIM8JR	),	{ code $4E }
    (	str:'xr';	kind:REGIM8JR	),	{ code $4F }
    (	str:'st';	kind:IM8IND	),	{ code $50 }
    (	str:'0';	ext:256+20*4	),	{ code $51 }
    (	str:'stl';	kind:IM8	),	{ code $52 }
    (	str:'****';	kind:ILLOP	),	{ code $53 }
    (	str:'0';	ext:256+6*4	),	{ code $54 }
    (	str:'psr';	kind:SIRIM5	),	{ code $55 }
    (	str:'pst';	kind:R8IM8	),	{ code $56 }
    (	str:'pst';	kind:R8IM8	),	{ code $57 }
    (	str:'bups';	kind:IM8	),	{ code $58 }
    (	str:'bdns';	kind:IM8	),	{ code $59 }
    (	str:'****';	kind:ILLOP	),	{ code $5A }
    (	str:'****';	kind:ILLOP	),	{ code $5B }
    (	str:'sup';	kind:IM8	),	{ code $5C }
    (	str:'sdn';	kind:IM8	),	{ code $5D }
    (	str:'****';	kind:ILLOP	),	{ code $5E }
    (	str:'****';	kind:ILLOP	),	{ code $5F }
    (	str:'st';	kind:REGIRI	),	{ code $60 }
    (	str:'st';	kind:REGIRI	),	{ code $61 }
    (	str:'sti';	kind:REGIRI	),	{ code $62 }
    (	str:'sti';	kind:REGIRI	),	{ code $63 }
    (	str:'std';	kind:REGIRI	),	{ code $64 }
    (	str:'std';	kind:REGIRI	),	{ code $65 }
    (	str:'****';	kind:ILLOP	),	{ code $66 }
    (	str:'****';	kind:ILLOP	),	{ code $67 }
    (	str:'ld';	kind:REGIRI	),	{ code $68 }
    (	str:'ld';	kind:REGIRI	),	{ code $69 }
    (	str:'ldi';	kind:REGIRI	),	{ code $6A }
    (	str:'ldi';	kind:REGIRI	),	{ code $6B }
    (	str:'ldd';	kind:REGIRI	),	{ code $6C }
    (	str:'ldd';	kind:REGIRI	),	{ code $6D }
    (	str:'****';	kind:ILLOP	),	{ code $6E }
    (	str:'****';	kind:ILLOP	),	{ code $6F }
    (	str:'cal';	kind:JPCC	),	{ code $70 }
    (	str:'cal';	kind:JPCC	),	{ code $71 }
    (	str:'cal';	kind:JPCC	),	{ code $72 }
    (	str:'cal';	kind:JPCC	),	{ code $73 }
    (	str:'cal';	kind:JPCC	),	{ code $74 }
    (	str:'cal';	kind:JPCC	),	{ code $75 }
    (	str:'cal';	kind:JPCC	),	{ code $76 }
    (	str:'cal';	kind:JP		),	{ code $77 }
    (	str:'adc';	kind:IRIREG	),	{ code $78 }
    (	str:'adc';	kind:IRIREG	),	{ code $79 }
    (	str:'sbc';	kind:IRIREG	),	{ code $7A }
    (	str:'sbc';	kind:IRIREG	),	{ code $7B }
    (	str:'ad';	kind:IRIREG	),	{ code $7C }
    (	str:'ad';	kind:IRIREG	),	{ code $7D }
    (	str:'sb';	kind:IRIREG	),	{ code $7E }
    (	str:'sb';	kind:IRIREG	),	{ code $7F }
    (	str:'adcw';	kind:REGREGJR	),	{ code $80 }
    (	str:'sbcw';	kind:REGREGJR	),	{ code $81 }
    (	str:'ldw';	kind:REGREGJR	),	{ code $82 }
    (	str:'ldcw';	kind:REGREGJR	),	{ code $83 }
    (	str:'ancw';	kind:REGREGJR	),	{ code $84 }
    (	str:'nacw';	kind:REGREGJR	),	{ code $85 }
    (	str:'orcw';	kind:REGREGJR	),	{ code $86 }
    (	str:'xrcw';	kind:REGREGJR	),	{ code $87 }
    (	str:'adw';	kind:REGREGJR	),	{ code $88 }
    (	str:'sbw';	kind:REGREGJR	),	{ code $89 }
    (	str:'adbw';	kind:REGREGJR	),	{ code $8A }
    (	str:'sbbw';	kind:REGREGJR	),	{ code $8B }
    (	str:'anw';	kind:REGREGJR	),	{ code $8C }
    (	str:'naw';	kind:REGREGJR	),	{ code $8D }
    (	str:'orw';	kind:REGREGJR	),	{ code $8E }
    (	str:'xrw';	kind:REGREGJR	),	{ code $8F }
    (	str:'stw';	kind:REGDIRJR	),	{ code $90 }
    (	str:'ldw';	kind:REGDIRJR	),	{ code $91 }
    (	str:'0';	ext:256+7*4	),	{ code $92 }
    (	str:'0';	ext:256+19*4	),	{ code $93 }
    (	str:'0';	ext:256+8*4	),	{ code $94 }
    (	str:'psrw';	kind:SIRREGJR	),	{ code $95 }
    (	str:'pre';	kind:R16REGJR	),	{ code $96 }
    (	str:'pre';	kind:R16REGJR	),	{ code $97 }
    (	str:'0';	ext:256+9*4	),	{ code $98 }
    (	str:'****';	kind:ILLOP	),	{ code $99 }
    (	str:'0';	ext:256+10*4	),	{ code $9A }
    (	str:'0';	ext:256+11*4	),	{ code $9B }
    (	str:'0';	ext:256+12*4	),	{ code $9C }
    (	str:'gsrw';	kind:SIRREGJR	),	{ code $9D }
    (	str:'gre';	kind:R16REGJR	),	{ code $9E }
    (	str:'gre';	kind:R16REGJR	),	{ code $9F }
    (	str:'stw';	kind:REGIRR	),	{ code $A0 }
    (	str:'stw';	kind:REGIRR	),	{ code $A1 }
    (	str:'stiw';	kind:REGIRR	),	{ code $A2 }
    (	str:'stiw';	kind:REGIRR	),	{ code $A3 }
    (	str:'stdw';	kind:REGIRR	),	{ code $A4 }
    (	str:'stdw';	kind:REGIRR	),	{ code $A5 }
    (	str:'phsw';	kind:REG	),	{ code $A6 }
    (	str:'phuw';	kind:REG	),	{ code $A7 }
    (	str:'ldw';	kind:REGIRR	),	{ code $A8 }
    (	str:'ldw';	kind:REGIRR	),	{ code $A9 }
    (	str:'ldiw';	kind:REGIRR	),	{ code $AA }
    (	str:'ldiw';	kind:REGIRR	),	{ code $AB }
    (	str:'lddw';	kind:REGIRR	),	{ code $AC }
    (	str:'lddw';	kind:REGIRR	),	{ code $AD }
    (	str:'ppsw';	kind:REG	),	{ code $AE }
    (	str:'ppuw';	kind:REG	),	{ code $AF }
    (	str:'jr';	kind:JRCC	),	{ code $B0 }
    (	str:'jr';	kind:JRCC	),	{ code $B1 }
    (	str:'jr';	kind:JRCC	),	{ code $B2 }
    (	str:'jr';	kind:JRCC	),	{ code $B3 }
    (	str:'jr';	kind:JRCC	),	{ code $B4 }
    (	str:'jr';	kind:JRCC	),	{ code $B5 }
    (	str:'jr';	kind:JRCC	),	{ code $B6 }
    (	str:'jr';	kind:JR		),	{ code $B7 }
    (	str:'adcw';	kind:IRRREG	),	{ code $B8 }
    (	str:'adcw';	kind:IRRREG	),	{ code $B9 }
    (	str:'sbcw';	kind:IRRREG	),	{ code $BA }
    (	str:'sbcw';	kind:IRRREG	),	{ code $BB }
    (	str:'adw';	kind:IRRREG	),	{ code $BC }
    (	str:'adw';	kind:IRRREG	),	{ code $BD }
    (	str:'sbw';	kind:IRRREG	),	{ code $BE }
    (	str:'sbw';	kind:IRRREG	),	{ code $BF }
    (	str:'adbcm';	kind:RRIM3JR	),	{ code $C0 }
    (	str:'sbbcm';	kind:RRIM3JR	),	{ code $C1 }
    (	str:'ldm';	kind:RRIM3JR	),	{ code $C2 }
    (	str:'ldcm';	kind:RRIM3JR	),	{ code $C3 }
    (	str:'ancm';	kind:RRIM3JR	),	{ code $C4 }
    (	str:'nacm';	kind:RRIM3JR	),	{ code $C5 }
    (	str:'orcm';	kind:RRIM3JR	),	{ code $C6 }
    (	str:'xrcm';	kind:RRIM3JR	),	{ code $C7 }
    (	str:'adbm';	kind:RRIM3JR	),	{ code $C8 }
    (	str:'sbbm';	kind:RRIM3JR	),	{ code $C9 }
    (	str:'0';	ext:256+13*4	),	{ code $CA }
    (	str:'0';	ext:256+14*4	),	{ code $CB }
    (	str:'anm';	kind:RRIM3JR	),	{ code $CC }
    (	str:'nam';	kind:RRIM3JR	),	{ code $CD }
    (	str:'orm';	kind:RRIM3JR	),	{ code $CE }
    (	str:'xrm';	kind:RRIM3JR	),	{ code $CF }
    (	str:'stw';	kind:IM16IND	),	{ code $D0 }
    (	str:'0';	ext:256+21*4	),	{ code $D1 }
    (	str:'stlm';	kind:REGIM3	),	{ code $D2 }
    (	str:'0';	ext:256+15*4	),	{ code $D3 }
    (	str:'ppom';	kind:REGIM3	),	{ code $D4 }
    (	str:'psrm';	kind:SIRREGIM3	),	{ code $D5 }
    (	str:'pre';	kind:R16IM16	),	{ code $D6 }
    (	str:'pre';	kind:R16IM16	),	{ code $D7 }
    (	str:'bup';	kind:NONE	),	{ code $D8 }
    (	str:'bdn';	kind:NONE	),	{ code $D9 }
    (	str:'0';	ext:256+16*4	),	{ code $DA }
    (	str:'0';	ext:256+17*4	),	{ code $DB }
    (	str:'sup';	kind:REG	),	{ code $DC }
    (	str:'sdn';	kind:REG	),	{ code $DD }
    (	str:'jp';	kind:REG	),	{ code $DE }
    (	str:'jp';	kind:DIR	),	{ code $DF }
    (	str:'stm';	kind:REGIRRIM3	),	{ code $E0 }
    (	str:'stm';	kind:REGIRRIM3	),	{ code $E1 }
    (	str:'stim';	kind:REGIRRIM3	),	{ code $E2 }
    (	str:'stim';	kind:REGIRRIM3	),	{ code $E3 }
    (	str:'stdm';	kind:REGIRRIM3	),	{ code $E4 }
    (	str:'stdm';	kind:REGIRRIM3	),	{ code $E5 }
    (	str:'phsm';	kind:REGIM3	),	{ code $E6 }
    (	str:'phum';	kind:REGIM3	),	{ code $E7 }
    (	str:'ldm';	kind:REGIRRIM3	),	{ code $E8 }
    (	str:'ldm';	kind:REGIRRIM3	),	{ code $E9 }
    (	str:'ldim';	kind:REGIRRIM3	),	{ code $EA }
    (	str:'ldim';	kind:REGIRRIM3	),	{ code $EB }
    (	str:'lddm';	kind:REGIRRIM3	),	{ code $EC }
    (	str:'lddm';	kind:REGIRRIM3	),	{ code $ED }
    (	str:'ppsm';	kind:REGIM3	),	{ code $EE }
    (	str:'ppum';	kind:REGIM3	),	{ code $EF }
    (	str:'rtn';	kind:CC		),	{ code $F0 }
    (	str:'rtn';	kind:CC		),	{ code $F1 }
    (	str:'rtn';	kind:CC		),	{ code $F2 }
    (	str:'rtn';	kind:CC		),	{ code $F3 }
    (	str:'rtn';	kind:CC		),	{ code $F4 }
    (	str:'rtn';	kind:CC		),	{ code $F5 }
    (	str:'rtn';	kind:CC		),	{ code $F6 }
    (	str:'rtn';	kind:NONE	),	{ code $F7 }
    (	str:'nop';	kind:NONE	),	{ code $F8 }
    (	str:'clt';	kind:NONE	),	{ code $F9 }
    (	str:'fst';	kind:NONE	),	{ code $FA }
    (	str:'slw';	kind:NONE	),	{ code $FB }
    (	str:'cani';	kind:NONE	),	{ code $FC }
    (	str:'rtni';	kind:NONE	),	{ code $FD }
    (	str:'off';	kind:NONE	),	{ code $FE }
    (	str:'trp';	kind:NONE	),	{ code $FF }
{ mnemonic variations selected by bits 6 and 5 of the second byte }
{ code $12, index 256+0*4 }
    (	str:'stl';	kind:REGJR	),	{ x00xxxxx }
    (	str:'****';	kind:ILLOP	),	{ x01xxxxx }
    (	str:'****';	kind:ILLOP	),	{ x10xxxxx }
    (	str:'****';	kind:ILLOP	),	{ x11xxxxx }
{ code $14, index 256+1*4 }
    (	str:'ppo';	kind:REGJR	),
    (	str:'****';	kind:ILLOP	),
    (	str:'pfl';	kind:REGJR	),
    (	str:'****';	kind:ILLOP	),
{ code $18, index 256+2*4 }
    (	str:'rod';	kind:REGJR	),
    (	str:'rou';	kind:REGJR	),
    (	str:'bid';	kind:REGJR	),
    (	str:'biu';	kind:REGJR	),
{ code $1A, index 256+3*4 }
    (	str:'did';	kind:REGJR	),
    (	str:'diu';	kind:REGJR	),
    (	str:'byd';	kind:REGJR	),
    (	str:'byu';	kind:REGJR	),
{ code $1B, index 256+4*4 }
    (	str:'cmp';	kind:REGJR	),
    (	str:'****';	kind:ILLOP	),
    (	str:'inv';	kind:REGJR	),
    (	str:'****';	kind:ILLOP	),
{ code $1C, index 256+5*4 }
    (	str:'gpo';	kind:REGJR	),
    (	str:'****';	kind:ILLOP	),
    (	str:'gfl';	kind:REGJR	),
    (	str:'****';	kind:ILLOP	),
{ code $54, index 256+6*4 }
    (	str:'ppo';	kind:IM8A	),
    (	str:'****';	kind:ILLOP	),
    (	str:'pfl';	kind:IM8A	),
    (	str:'****';	kind:ILLOP	),
{ code $92, index 256+7*4 }
    (	str:'stlw';	kind:REGJR	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	),
{ code $94, index 256+8*4 }
    (	str:'ppow';	kind:REGJR	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	),
{ code $98, index 256+9*4 }
    (	str:'rodw';	kind:REGJR	),
    (	str:'rouw';	kind:REGJR	),
    (	str:'bidw';	kind:REGJR	),
    (	str:'biuw';	kind:REGJR	),
{ code $9A, index 256+10*4 }
    (	str:'didw';	kind:REGJR	),
    (	str:'diuw';	kind:REGJR	),
    (	str:'bydw';	kind:REGJR	),
    (	str:'byuw';	kind:REGJR	),
{ code $9B, index 256+11*4 }
    (	str:'cmpw';	kind:REGJR	),
    (	str:'****';	kind:ILLOP	),
    (	str:'invw';	kind:REGJR	),
    (	str:'****';	kind:ILLOP	),
{ code $9C, index 256+12*4 }
    (	str:'gpow';	kind:REGJR	),
    (	str:'****';	kind:ILLOP	),
    (	str:'gflw';	kind:REGJR	),
    (	str:'****';	kind:ILLOP	),
{ code $CA, index 256+13*4 }
    (	str:'adbm';	kind:RIM5IM3JR	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	),
{ code $CB, index 256+14*4 }
    (	str:'sbbm';	kind:RIM5IM3JR	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	),
{ code $D3, index 256+15*4 }
    (	str:'ldlm';	kind:REGIM3	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	),
{ code $DA, index 256+16*4 }
    (	str:'didm';	kind:REGIM3	),
    (	str:'dium';	kind:REGIM3	),
    (	str:'bydm';	kind:REGIM3	),
    (	str:'byum';	kind:REGIM3	),
{ code $DB, index 256+17*4 }
    (	str:'cmpm';	kind:REGIM3	),
    (	str:'****';	kind:ILLOP	),
    (	str:'invm';	kind:REGIM3	),
    (	str:'****';	kind:ILLOP	),
{ code $13, index 256+18*4 }
    (	str:'ldl';	kind:REGJR	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	),
{ code $93, index 256+19*4 }
    (	str:'ldlw';	kind:REGJR	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	),
{ code $51, index 256+20*4 }
    (	str:'ld';	kind:REGIM8	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	),
{ code $D1, index 256+21*4 }
    (	str:'ldw';	kind:REGIM16	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	),
    (	str:'****';	kind:ILLOP	)
  );


{ condition codes }
  cctab: array[0..6] of string[3] =
    ( 'z', 'nc', 'lz', 'uz', 'nz', 'c', 'nlz' );


{ 8-bit register names }
  r8tab: array[0..1,0..3] of string[2] = (
    ( 'pe', 'pd', 'ib', 'ua' ),
    ( 'ia', 'ie', '??', 'tm' )
  );


{ 16-bit register names }
  r16tab: array[0..1,0..3] of string[2] = (
    ( 'ix', 'iy', 'iz', 'us' ),
    ( 'ss', 'ky', 'ky', 'ky' )
  );


{ specific register names }
  sirtab: array[0..3] of string[2] = ( 'sx', 'sy', 'sz', '??' );


{ returns the index to the 'mnem' table }
function ScanMnemTab: word;
var
  code: word;
begin
  code := FetchOpcode;
  if mnem[code].str[1] = '0' then
    ScanMnemTab := mnem[code].ext + ((opcode[1] shr 5) and 3)
  else
    ScanMnemTab := code;
end {ScanMnemTab};


{ returns the mnemonic }
function Mnemonic (index: word) : string;
begin
  Mnemonic := mnem[index].str;
end {Mnemonic};


function Imm3Arg (x: byte): string;
begin
  Imm3Arg := IntToStr(((x shr 5) and 7) + 1);
end {Imm3Arg};


function Imm5Arg (x: byte) : string;
begin
  Imm5Arg := '&H' + IntToHex(x and $1F, 2);
end {Imm5Arg};


function Imm7Arg: string;
var
  x, y: word;
begin
  y := pc;
  if (opforg > 0) and not Odd(opindex) then FetchByte;
  x := FetchByte;
  if (x and $80) <> 0 then x := $80 - x;
  x := x + y;
  Imm7Arg := '&H' + IntToHex(x, 4);
end {Imm7Arg};


function Imm8Arg: string;
begin
  Imm8Arg := '&H' + IntToHex(FetchByte, 2);
end {Imm8Arg};


function Imm16Arg: string;
var
  x: word;
begin
  x := FetchByte;
  Imm16Arg := '&H' + IntToHex(FetchByte, 2) + IntToHex(x, 2);
end {Imm16Arg};


function AbsArg: string;
var
  x: word;
begin
  x := FetchByte;
  if opforg > 0 then FetchByte;
  AbsArg := '&H' + IntToHex(FetchByte, 2) + IntToHex(x, 2);
end {AbsArg};


function RegArg (x: byte) : string;
begin
  RegArg := '$' + IntToStr(x and $1F);
end {RegArg};


function SirArg (x: byte) : string;
begin
  SirArg := sirtab[(x shr 5) and 3];
end {SirArg};


function ShortRegArg (x: byte) : string;
begin
  if (x and $60) = $60 then ShortRegArg := RegArg(FetchByte)
  else ShortRegArg := '$' + SirArg (x);
end {ShortRegArg};


function ShortRegAr1 (x, y: byte) : string;
begin
  if (x and $60) = $60 then ShortRegAr1 := RegArg(y)
  else ShortRegAr1 := '$' + SirArg (x);
end {ShortRegAr1};


function IrArg (x: word) : char;
begin
  if (x and 1) = 0 then IrArg := 'x' else IrArg := 'z';
end {IrArg};


function SignArg (x: byte) : char;
begin
  if (x and $80) <> 0 then SignArg := '-' else SignArg := '+';
end {SignArg};


function OptionalJr (x: byte) : string;
begin
  if (x and $80) <> 0 then
    OptionalJr := ',jr ' + Imm7Arg
  else
    OptionalJr := '';
end {OptionalJr};


{ returns the arguments }
function Arguments (index: word) : string;
var
  x, y: byte;
begin
  case mnem[index].kind of

    CC:
      Result := cctab[index and 7];

    JRCC:
      Result := cctab[index and 7] + ',' + Imm7Arg;

    JPCC:
      Result := cctab[index and 7] + ',' + AbsArg;

    JR:
      Result := Imm7Arg;

    JP:
      Result := AbsArg;

    REGREGJR:
      begin
        x := FetchByte;
        Result := RegArg(x) + ',' + ShortRegArg(x) + OptionalJr(x);
      end;

    REGDIRJR:
      begin
        x := FetchByte;
        Result := RegArg(x) + ',(' + ShortRegArg(x) + ')' + OptionalJr(x);
      end;

    REGJR:
      begin
        x := FetchByte;
        Result := RegArg(x) + OptionalJr(x);
      end;

    REGIRR:
      begin
        x := FetchByte;
        Result := RegArg(x) + ',(i' + IrArg(index) + SignArg(x) +
		ShortRegArg(x) + ')';
      end;

    REGIRRIM3:
      begin
        x := FetchByte;
        y := FetchByte;
        Result := RegArg(x) + ',(i' + IrArg(index) + SignArg(x) +
		ShortRegAr1(x,y) + '),' + Imm3Arg(y);
      end;

    REG:
      Result := RegArg(FetchByte);

    DIR:
      Result := '(' + RegArg(FetchByte) + ')';

    IRRREG:
      begin
        x := FetchByte;
        Result := '(i' + IrArg(index) + SignArg(x) + ShortRegArg(x) +
		'),' + RegArg(x);
      end;

    REGIM8JR:
      begin
        x := FetchByte;
        Result := RegArg(x) + ',' + Imm8Arg + OptionalJr(x);
      end;

    IM8:
      Result := Imm8Arg;

    IM8A:
      begin
        FetchByte;
        Result := Imm8Arg;
      end;

    R8IM8:
      begin
        x := FetchByte;
        Result := r8tab[index and 1, (x shr 5) and 3] + ',' + Imm8Arg;
      end;

    REGIRI:
      begin
        x := FetchByte;
        Result := RegArg(x) + ',(i' + IrArg(index) + SignArg(x);
        Result := Result + Imm8Arg + ')';
      end;

    IRIREG:
      begin
        x := FetchByte;
        Result := '(i' + IrArg(index) + SignArg(x);
        Result := Result + Imm8Arg + '),' + RegArg(x);
      end;

    R8REGJR:
      begin
        x := FetchByte;
        Result := r8tab[index and 1, (x shr 5) and 3] + ',' +
		RegArg(x) + OptionalJr(x);
      end;

    R16REGJR:
      begin
        x := FetchByte;
        Result := r16tab[index and 1, (x shr 5) and 3] + ',' +
		RegArg(x) + OptionalJr(x);
      end;

    R16IM16:
      begin
        x := FetchByte;
        Result := r16tab[index and 1, (x shr 5) and 3] + ',' + Imm16Arg;
      end;

    IM8IND:
      begin
        x := FetchByte;
        Result := Imm8Arg + ',($' + SirArg(x) + ')';
      end;

    IM16IND:
      begin
        x := FetchByte;
        Result := Imm16Arg + ',($' + SirArg(x) + ')';
      end;

    RRIM3JR:
      begin
        x := FetchByte;
        y := FetchByte;
        Result := RegArg(x) + ',' + ShortRegAr1(x,y) + ',' +
		Imm3Arg(y) + OptionalJr(x);
      end;

    RIM5IM3JR:
      begin
        x := FetchByte;
        y := FetchByte;
        Result := RegArg(x) + ',' + Imm5Arg(y) + ',' + Imm3Arg(y) +
		OptionalJr(x);
      end;

    REGIM8:
      begin
        x := FetchByte;
        Result := RegArg(x) + ',' + Imm8Arg;
      end;

    REGIM16:
      begin
        x := FetchByte;
        Result := RegArg(x) + ',' + Imm16Arg;
      end;

    REGIM3:
      begin
        x := FetchByte;
        y := FetchByte;
        Result := RegArg(x) + ',' + Imm3Arg(y);
      end;

    SIRREGJR:
      begin
        x := FetchByte;
        Result := SirArg(x) + ',' + RegArg(x) + OptionalJr(x);
      end;

    SIRREGIM3:
      begin
        x := FetchByte;
        y := FetchByte ();
        Result := SirArg(x) + ',' + RegArg(x) + ',' + Imm3Arg(y);
      end;

    SIRIM5:
      begin
        x := FetchByte;
        Result := SirArg(x) + ',' + IntToStr(x and $1F);
      end;

    else
      Result := '';

  end {case};
  if (opforg > 0) and Odd(opindex) then FetchByte;	{ align pc }
end {Arguments};

end.
