{ HD61700 instruction decoding }

unit Decoder;


interface

  procedure ExecInstr;


implementation

  uses Def, Exec;

  type

    Proc1 = procedure;


  procedure Ext_18;
  const
    dtab: array[0..3] of pointer = (@Rod_18, @Rou_18, @Bid_18, @Biu_18);
  begin
    Proc1(dtab[(opcode[1] shr 5) and 3]);
  end {Ext_18};


  procedure Ext_1A;
  const
    dtab: array[0..3] of pointer = (@Did_1A, @Diu_1A, @BydByu_1A, @BydByu_1A);
  begin
    Proc1(dtab[(opcode[1] shr 5) and 3]);
  end {Ext_1A};


  procedure Ext_98;
  const
    dtab: array[0..3] of pointer = (@Rodw_98, @Rouw_98, @Bidw_98, @Biuw_98);
  begin
    Proc1(dtab[(opcode[1] shr 5) and 3]);
  end {Ext_98};


  procedure Ext_9A;
  const
    dtab: array[0..3] of pointer = (@Didw_9A, @Diuw_9A, @Bydw_9A, @Byuw_9A);
  begin
    Proc1(dtab[(opcode[1] shr 5) and 3]);
  end {Ext_9A};


  procedure Ext_DA;
  const
    dtab: array[0..3] of pointer = (@Didm_DA, @Dium_DA, @Bydm_DA, @Byum_DA);
  begin
    Proc1(dtab[(opcode[1] shr 5) and 3]);
  end {Ext_DA};


{ execute a single instruction }
  procedure ExecInstr;
  const
    dtab: array[0..255] of pointer = (
	@AdSb_08,	{ code $00, ADC }
	@AdSb_08,	{ code $01, SBC }
	@Ld_02,		{ code $02 }
	@IllComm,	{ code $03 }
	@Logic_0C,	{ code $04, ANC }
	@Logic_0C,	{ code $05, NAC }
	@Logic_0C,	{ code $06, ORC }
	@Logic_0C,	{ code $07, XRC }
	@AdSb_08,	{ code $08, AD }
	@AdSb_08,	{ code $09, SB }
	@AdbSbb_0A,	{ code $0A, ADB }
	@AdbSbb_0A,	{ code $0B, SBB }
	@Logic_0C,	{ code $0C, AN }
	@Logic_0C,	{ code $0D, NA }
	@Logic_0C,	{ code $0E, OR }
	@Logic_0C,	{ code $0F, XR }
	@St_10,		{ code $10 }
	@Ld_11,		{ code $11 }
	@Stl_12,	{ code $12 }
	@Ldl_13,	{ code $13 }
	@PpoPfl_14,	{ code $14 }
	@Psr_15,	{ code $15 }
	@Pst_16,	{ code $16 }
	@Pst_16,	{ code $17 }
	@Ext_18,	{ code $18 }
	@IllComm,	{ code $19 }
	@Ext_1A,	{ code $1A }
	@CmpInv_1B,	{ code $1B }
	@GpoGfl_1C,	{ code $1C }
	@Gsr_1D,	{ code $1D }
	@Gst_1E,	{ code $1E }
	@Gst_1E,	{ code $1F }
	@StSti_20,	{ code $20, ST }
	@StSti_20,	{ code $21, ST }
	@StSti_20,	{ code $22, STI }
	@StSti_20,	{ code $23, STI }
	@Std_24,	{ code $24 }
	@Std_24,	{ code $25 }
	@PhsPhu_26,	{ code $26, PHS }
	@PhsPhu_26,	{ code $27, PHU }
	@LdLdi_28,	{ code $28, LD }
	@LdLdi_28,	{ code $29, LD }
	@LdLdi_28,	{ code $2A, LDI }
	@LdLdi_28,	{ code $2B, LDI }
	@Ldd_2C,	{ code $2C }
	@Ldd_2C,	{ code $2D }
	@PpsPpu_2E,	{ code $2E, PPS }
	@PpsPpu_2E,	{ code $2F, PPU }
	@Jp_3x,		{ code $30 }
	@Jp_3x,		{ code $31 }
	@Jp_3x,		{ code $32 }
	@Jp_3x,		{ code $33 }
	@Jp_3x,		{ code $34 }
	@Jp_3x,		{ code $35 }
	@Jp_3x,		{ code $36 }
	@Jp_3x,		{ code $37 }
	@AdSb_38,	{ code $38, ADC }
	@AdSb_38,	{ code $39, ADC }
	@AdSb_38,	{ code $3A, SBC }
	@AdSb_38,	{ code $3B, SBC }
	@AdSb_38,	{ code $3C, AD }
	@AdSb_38,	{ code $3D, AD }
	@AdSb_38,	{ code $3E, SB }
	@AdSb_38,	{ code $3F, SB }
	@AdSb_08,	{ code $40, ADC }
	@AdSb_08,	{ code $41, SBC }
	@Ld_42,		{ code $42 }
	@IllComm,	{ code $43 }
	@Logic_0C,	{ code $44, ANC }
	@Logic_0C,	{ code $45, NAC }
	@Logic_0C,	{ code $46, ORC }
	@Logic_0C,	{ code $47, XRC }
	@AdSb_08,	{ code $48, AD }
	@AdSb_08,	{ code $49, SB }
	@AdbSbb_0A,	{ code $4A, ADB }
	@AdbSbb_0A,	{ code $4B, SBB }
	@Logic_0C,	{ code $4C, AN }
	@Logic_0C,	{ code $4D, NA }
	@Logic_0C,	{ code $4E, OR }
	@Logic_0C,	{ code $4F, XR }
	@St_50,		{ code $50 }
	@Ld_51,		{ code $51 }
	@Stl_52,	{ code $52 }
	@IllComm,	{ code $53 }
	@PpoPfl_14,	{ code $54 }
	@Psr_15,	{ code $55 }
	@Pst_16,	{ code $56 }
	@Pst_16,	{ code $57 }
	@BupsBdns_58,	{ code $58, BUPS }
	@BupsBdns_58,	{ code $59, BDNS }
	@IllComm,	{ code $5A }
	@IllComm,	{ code $5B }
	@SupSdn_5C,	{ code $5C, SUP }
	@SupSdn_5C,	{ code $5D, SDN }
	@IllComm,	{ code $5E }
	@IllComm,	{ code $5F }
	@StSti_20,	{ code $60, ST }
	@StSti_20,	{ code $61, ST }
	@StSti_20,	{ code $62, STI }
	@StSti_20,	{ code $63, STI }
	@Std_24,	{ code $64 }
	@Std_24,	{ code $65 }
	@IllComm,	{ code $66 }
	@IllComm,	{ code $67 }
	@LdLdi_28,	{ code $68, LD }
	@LdLdi_28,	{ code $69, LD }
	@LdLdi_28,	{ code $6A, LDI }
	@LdLdi_28,	{ code $6B, LDI }
	@Ldd_2C,	{ code $6C }
	@Ldd_2C,	{ code $6D }
	@IllComm,	{ code $6E }
	@IllComm,	{ code $6F }
	@Cal_7x,	{ code $70 }
	@Cal_7x,	{ code $71 }
	@Cal_7x,	{ code $72 }
	@Cal_7x,	{ code $73 }
	@Cal_7x,	{ code $74 }
	@Cal_7x,	{ code $75 }
	@Cal_7x,	{ code $76 }
	@Cal_7x,	{ code $77 }
	@AdSb_38,	{ code $78, ADC }
	@AdSb_38,	{ code $79, ADC }
	@AdSb_38,	{ code $7A, SBC }
	@AdSb_38,	{ code $7B, SBC }
	@AdSb_38,	{ code $7C, AD }
	@AdSb_38,	{ code $7D, AD }
	@AdSb_38,	{ code $7E, SB }
	@AdSb_38,	{ code $7F, SB }
	@AdwSbw_88,	{ code $80, ADCW }
	@AdwSbw_88,	{ code $81, SBCW }
	@Ldw_82,	{ code $82 }
	@IllComm,	{ code $83 }
	@LogicW_8C,	{ code $84, ANCW }
	@LogicW_8C,	{ code $85, NACW }
	@LogicW_8C,	{ code $86, ORCW }
	@LogicW_8C,	{ code $87, XRCW }
	@AdwSbw_88,	{ code $88, ADW }
	@AdwSbw_88,	{ code $89, SBW }
	@AdbwSbbw_8A,	{ code $8A, ADBW }
	@AdbwSbbw_8A,	{ code $8B, SBBW }
	@LogicW_8C,	{ code $8C, ANW }
	@LogicW_8C,	{ code $8D, NAW }
	@LogicW_8C,	{ code $8E, ORW }
	@LogicW_8C,	{ code $8F, XRW }
	@Stw_90,	{ code $90 }
	@Ldw_91,	{ code $91 }
	@Stlw_92,	{ code $92 }
	@Ldlw_93,	{ code $93 }
	@IllComm,	{ code $94 }
	@IllComm,	{ code $95 }
	@Pre_96,	{ code $96 }
	@Pre_96,	{ code $97 }
	@Ext_98,	{ code $98 }
	@IllComm,	{ code $99 }
	@Ext_9A,	{ code $9A }
	@CmpwInvw_9B,	{ code $9B }
	@GpowGflw_9C,	{ code $9C }
	@IllComm,	{ code $9D }
	@Gre_9E,	{ code $9E }
	@Gre_9E,	{ code $9F }
	@StwStiw_A0,	{ code $A0, STW }
	@StwStiw_A0,	{ code $A1, STW }
	@StwStiw_A0,	{ code $A2, STIW }
	@StwStiw_A0,	{ code $A3, STIW }
	@Stdw_A4,	{ code $A4 }
	@Stdw_A4,	{ code $A5 }
	@PhswPhuw_A6,	{ code $A6, PHSW }
	@PhswPhuw_A6,	{ code $A7, PHUW }
	@LdwLdiw_A8,	{ code $A8, LDW }
	@LdwLdiw_A8,	{ code $A9, LDW }
	@LdwLdiw_A8,	{ code $AA, LDIW }
	@LdwLdiw_A8,	{ code $AB, LDIW }
	@Lddw_AC,	{ code $AC }
	@Lddw_AC,	{ code $AD }
	@PpswPpuw_AE,	{ code $AE, PPSW }
	@PpswPpuw_AE,	{ code $AF, PPUW }
	@Jr_Bx,		{ code $B0 }
	@Jr_Bx,		{ code $B1 }
	@Jr_Bx,		{ code $B2 }
	@Jr_Bx,		{ code $B3 }
	@Jr_Bx,		{ code $B4 }
	@Jr_Bx,		{ code $B5 }
	@Jr_Bx,		{ code $B6 }
	@Jr_Bx,		{ code $B7 }
	@AdwSbw_B8,	{ code $B8 }
	@AdwSbw_B8,	{ code $B9 }
	@AdwSbw_B8,	{ code $BA }
	@AdwSbw_B8,	{ code $BB }
	@AdwSbw_B8,	{ code $BC }
	@AdwSbw_B8,	{ code $BD }
	@AdwSbw_B8,	{ code $BE }
	@AdwSbw_B8,	{ code $BF }
	@AdbmSbbm_C8,	{ code $C0, ADBCM }
	@AdbmSbbm_C8,	{ code $C1, SBBCM }
	@Ldm_C2,	{ code $C2 }
	@IllComm,	{ code $C3 }
	@LogicM_CC,	{ code $C4, ANCM }
	@LogicM_CC,	{ code $C5, NACM }
	@LogicM_CC,	{ code $C6, ORCM }
	@LogicM_CC,	{ code $C7, XRCM }
	@AdbmSbbm_C8,	{ code $C8, ADBM }
	@AdbmSbbm_C8,	{ code $C9, SBBM }
	@AdbmSbbm_CA,	{ code $CA, ADBM }
	@AdbmSbbm_CA,	{ code $CB, SBBM }
	@LogicM_CC,	{ code $CC, ANM }
	@LogicM_CC,	{ code $CD, NAM }
	@LogicM_CC,	{ code $CE, ORM }
	@LogicM_CC,	{ code $CF, XRM }
	@Stw_D0,	{ code $D0 }
	@Ldw_D1,	{ code $D1 }
	@Stlm_D2,	{ code $D2 }
	@Ldlm_D3,	{ code $D3 }
	@IllComm,	{ code $D4 }
	@IllComm,	{ code $D5 }
	@Pre_D6,	{ code $D6 }
	@Pre_D6,	{ code $D7 }
	@BupBdn_D8,	{ code $D8, BUP }
	@BupBdn_D8,	{ code $D9, BDN }
	@Ext_DA,	{ code $DA }
	@CmpmInvm_DB,	{ code $DB }
	@SupSdn_5C,	{ code $DC, SUP }
	@SupSdn_5C,	{ code $DD, SDN }
	@Jp_DE,		{ code $DE }
	@Jp_DF,		{ code $DF }
	@StmStim_E0,	{ code $E0, STM }
	@StmStim_E0,	{ code $E1, STM }
	@StmStim_E0,	{ code $E2, STIM }
	@StmStim_E0,	{ code $E3, STIM }
	@Stdm_E4,	{ code $E4 }
	@Stdm_E4,	{ code $E5 }
	@PhsmPhum_E6,	{ code $E6, PHSM }
	@PhsmPhum_E6,	{ code $E7, PHUM }
	@LdmLdim_E8,	{ code $E8, LDM }
	@LdmLdim_E8,	{ code $E9, LDM }
	@LdmLdim_E8,	{ code $EA, LDIM }
	@LdmLdim_E8,	{ code $EB, LDIM }
	@Lddm_EC,	{ code $EC }
	@Lddm_EC,	{ code $ED }
	@PpsmPpum_EE,	{ code $EE, PPSM }
	@PpsmPpum_EE,	{ code $EF, PPUM }
	@Rtn_Fx,	{ code $F0 }
	@Rtn_Fx,	{ code $F1 }
	@Rtn_Fx,	{ code $F2 }
	@Rtn_Fx,	{ code $F3 }
	@Rtn_Fx,	{ code $F4 }
	@Rtn_Fx,	{ code $F5 }
	@Rtn_Fx,	{ code $F6 }
	@Rtn_Fx,	{ code $F7 }
	@Nop_F8,	{ code $F8 }
	@Clt_F9,	{ code $F9 }
	@Fst_FA,	{ code $FA }
	@Slw_FB,	{ code $FB }
	@Cani_FC,	{ code $FC }
	@Rtni_FD,	{ code $FD }
	@Off_FE,	{ code $FE }
	@Trp_FF );	{ code $FF }
  begin
    Proc1(dtab[FetchOpcode]);
    if (opforg > 0) and Odd(opindex) then FetchByte;	{ align pc }
  end {ExecInstr};

end.
