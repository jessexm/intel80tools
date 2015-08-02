asm80$47$57$85: do;
$IF OVL4
$include(asm47.ipx)
$ELSEIF OVL5
$include(asm57.ipx)
$ELSE
$include(asm85.ipx)
$ENDIF

$IF BASE
declare	CHKOVL$2 lit	'call ovlMgr(2)';
$ELSE
declare	CHKOVL$2 lit	' ';
$ENDIF

			/* 0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F */
declare isExprOrMacroMap(*) bool data(
			   0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,
			   0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0,   0,   0,   0,   0,   0,
			   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
			   0,   0,   0,   0,   0,   0,   0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh, 0,  0FFh,
			   0FFh,0FFh),
   isInstrMap(*) bool data(0,   0FFh,0FFh,0FFh,0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
		           0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0FFh,0FFh,0,   0,   0,   0,
			   0,   0,   0,   0,   0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0,
			   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
			   0FFh,0FFh);

declare pad byte;

declare	accum(4) byte at(.accum1);


sub$4AAA: procedure(seg) public;	/* seg = 0 => CSEG, seg = 1 => DSEG */
	declare seg byte;

	if segHasData(seg) then
	do;
		if haveTokens then
		do;
			accum1 = getNumVal;
			if alignTypes(seg) <> accum1$lb then
				call expressionError;
		end;
		else if alignTypes(seg) <> 3 then	/* no speficier - check byte algined */
			call expressionError;
	end;
	else
	do;
		segHasData(seg) = TRUE;
		if haveTokens then
		do;
			accum1 = getNumVal;
			if accum1 = 1 or accum1 = 2 then	/* only allow inPage and Page */
				alignTypes(seg) = low(accum1);
			else
				call expressionError;
		end;
	end;
end;


cond2Acc: procedure(cond) public;	/* convert conditional result to accum1 */
	declare cond byte;		/* 0 or 0ffffh */

	accum1 = cond;
	if accum1 then
		accum1 = 0FFFFh;
end;

updateHiLo: procedure(hilo) public;
	declare hilo byte;

	if (acc1Flags and (UF$EXTRN + UF$SEGMASK)) <> 0 then
		acc1Flags = acc1Flags and 0E7h or hilo;
end;

handleOp: procedure public;
	do case op;
/* 0 */		;
/* 1 */		call finishLine;		/* white space ? */
/* 2 */		goto case3;			/* ( */
/* 3 */ case3:	do;				/* ) */
			if not (op = T$LPAREN and opType = 3) then
				call balanceError;

			if tokenType(0) = O$DATA then
			do;
				tokenSize(0) = 1;
				tokenAttr(0) = 0;
				b6B36 = TRUE;
			end;

			inParen = inNestedParen;
			if opType = T$RPAREN then
				b6B2C = TRUE;
		end;
/* 4 */		accum1 = accum1 * accum2;	/* * */
/* 5 */		accum1 = accum1 + accum2;	/* + */
/* 6 */		do;				/* , */
			call syntaxError;
			call popToken;
		end;
/* 7 */		accum1 = accum1 - accum2;	/* - */
/* 8 */		;				/* unary + */
/* 9 */		do;				/* / */
			if accum2 = 0 then
				call valueError;

			accum1 = accum1 / accum2;
		end;
/* 10 */	accum1 = -accum1;			/* unary - */
/* 11 */	call cond2Acc(accum1 = accum2);		/* EQ */
/* 12 */	call cond2Acc(accum1 < accum2);		/* LT */
/* 13 */	call cond2Acc(accum1 <= accum2);	/* LE */
/* 14 */	call cond2Acc(accum1 > accum2);		/* GT */
/* 15 */	call cond2Acc(accum1 >= accum2);	/* GE */
/* 16 */	call cond2Acc(accum1 <> accum2);	/* NE */
/* 17 */	accum1 = not accum1;			/* NOT */
/* 18 */	accum1 = accum1 and accum2;		/* AND */
/* 19 */	accum1 = accum1 or accum2;		/* OR */
/* 20 */	accum1 = accum1 xor accum2;		/* XOR */
/* 21 */	do;					/* MOD */
			if accum2 = 0 then
				call valueError;
			accum1 = accum1 mod accum2;
		end;
/* 22 */	do;					/* SHL */
			if accum2$lb <> 0 then
				accum1 = shl(accum1, accum2);
		end;
/* 23 */	do;					/* SHR */
			if accum2$lb <> 0 then
				accum1 = shr(accum1, accum2);
		end;
/* 24 */	do;					/* HIGH */
			accum1 = high(accum1);
			call updateHiLo(UF$HIGH);
		end;
/* 25 */	do;					/* LOW */
			accum1 = low(accum1);
			call updateHiLo(UF$LOW);
		end;
/* 26 */	do;					/* DB ? */
			if tokenType(0) <> O$STRING then
			do;
				accum1 = getNumVal;
				if accum1$hb - 1 < 0FEh then	/* not 0 or FF */
					call valueError;
				b6B28 = 22h;
				if (acc1Flags and UF$BOTH) = UF$BOTH then
				do;
					call valueError;
					acc1Flags = acc1Flags and 0E7h or UF$LOW;
				end;
			end;
			else
			do;
				acc1Flags = 0;
				tokenType(0) = O$DATA;
			end;

			if isReg(acc1ValType) then
				call operandError;
			b6B2D = O$DATA;
			inDB = TRUE;
		end;
/* 27 */	do;					/* DW ? */
			b6B2D = O$DATA;
			inDW = TRUE;
		end;
/* 28 */	do;					/* DS ? */
			segSize(activeSeg) = segSize(activeSeg) + accum1;
			showAddr = TRUE;
		end;
/* 29 */ case29:					/* EQU ? */
		do;
			showAddr = TRUE;
			if (acc1Flags and UF$EXTRN) = UF$EXTRN then
			do;
				call expressionError;
				acc1Flags = 0;
			end;
			b6EC4$9C3A = 1;
			call sub5819$5CE8(accum1, 34 - op);	/* 4 for set, 5 for equ */
			expectingOperands = FALSE;
		end;
/* 30 */	goto case29;				/* SET ? */
/* 31 */	do;					/* ORG ? */
			showAddr = TRUE;
			if (acc1Flags and UF$EXTRN) <> UF$EXTRN then
			do;
				if (acc1Flags and UF$BOTH) <> 0 then
					if (acc1Flags and UF$SEGMASK) <> activeSeg
					    or (acc1Flags and UF$BOTH) <> UF$BOTH then
						call expressionError;
			end;
			else
				call expressionError;

			if ctlOBJECT then
				if segSize(activeSeg) > maxSegSize(activeSeg) then
					maxSegSize(activeSeg) = segSize(activeSeg);
			segSize(activeSeg) = accum1;
		end;
/* 32 */	do;					/* END ? */
			if tokenIdx > 0 then
			do;
				startOffset = getNumVal;
				startDefined = 1;
				startSeg = acc1Flags and 7;
				if (acc1Flags and UF$EXTRN) = UF$EXTRN then
					call expressionError;
				if isReg(acc1ValType) then
					call operandError;

				showAddr = TRUE;
			end;
$IF OVL4
			kk = b905E;
			b905E = 0;

			if macroCondSP > 0 or kk then
$ELSE
			if ifDepth > 0 then
$ENDIF
				call nestingError;
			if opType <> 1 then
				call syntaxError;
			if inParen then
				b6B33 = TRUE;
			else
				call syntaxError;

		end;
/* 33 */	do;					/* IF ? */
			if inParen then
			do;
				b6B32 = TRUE;
				call nestIF(2);
				b6881 = TRUE;
				if skipping(0) = FALSE then
					skipping(0) = not ((low(accum1) and 1) = 1);
				inElse(0) = FALSE;
			end;
		end;
/* 34 */	do;					/* ELSE ? */
			b6B32 = TRUE;
$IF OVL4
			if macroCondStk(0) <> 2 then
$ELSE
			if ifDepth = 0 then
$ENDIF
				call nestingError;
			else if not inElse(0) then
			do;
				if not skipping(0) then
					skipping(0) = TRUE;
				else
					skipping(0) = skipping(ifDepth);
				inElse(0) = TRUE;
			end;
			else
				call nestingError;
		end;
/* 35 */	do;					/* ENDIF ? */
			if inParen then
			do;
				b6B32 = TRUE;
				call unnestIF(2);
			end;
		end;
/* 36 */	do;					/* LXI ? */
			if nameLen = 1 then
				if name(0) = 'M' then
					call syntaxError;
			call mkCode(85h);
		end;
/* 37 */	do;				/* POP DAD PUSH INX DCX ? */
			if nameLen = 1 then
				if name(0) = 'M' then
					call syntaxError;
			call mkCode(5);
		end;
/* 38 */	call mkCode(7);		/* LDAX STAX ? */
/* 39 */	call mkCode(2);		/* ADC ADD SUB ORA SBB XRA ANA CMP ? */
/* 40 */	call mkCode(8);		/* ADI OUT SBI ORI IN CPI SUI XRI ANI ACI ? */
/* 41 */	call mkCode(46h);		/* MVI ? */
/* 42 */	call mkCode(6);		/* INR DCR ? */
/* 43 */	call mkCode(36h);		/* MOV */
/* 44 */	call mkCode(0);		/* CZ CNZ JZ STA JNZ JNC LHLD */
						/* CP JC SHLD CPE CPO CM LDA JP JM JPE */
						/* CALL JPO CC CNC JMP */
/* 45 */	call mkCode(0);		/* RNZ STC DAA DI SIM SPHL RLC */
						/* RP RAL HLT RM RAR RPE RET RIM */
						/* PCHL CMA CNC RPO EI XTHL NOP */
						/* RC RNX XCHG RZ RRC */
/* 46 */	call mkCode(6);		/* RST */
/* 47 */	activeSeg = 0;			/* ASEG ? */
/* 48 */	do;				/* CSEG ? */
			activeSeg = 1;
			call sub$4AAA(0);
		end;
/* 49 */	do;				/* DSEG ? */
			activeSeg = 2;
			call sub$4AAA(1);
		end;

/* 50 */	do;				/* PUBLIC */
			inPublic = TRUE;
			b6EC4$9C3A = 0;
			call sub5819$5CE8(0, 6);
		end;
/* 51 */	do;				/* EXTRN ? */
			inExtrn = TRUE;
			if externId = 0 and isPhase1 and ctlOBJECT then
			do;
				CHKOVL$2;
				call writeModhdr;
			end;
			b6EC4$9C3A = 0;
			call sub5819$5CE8(externId, 2);
			if isPhase1 and ctlOBJECT and not b6754 then
			do;
				CHKOVL$2;
				call writeExtName;
			end;
			if not b6754 then
				externId = externId + 1;
			b6754 = 0;
		end;
/* 52 */	do;				/* NAME */
			if tokenIdx <> 0 and b6743 then
			do;
				call move(6, .spaces6, .aModulePage);
				call move(moduleNameLen := nameLen, .name, .aModulePage);
			end;
			else
				call sourceError('R');

			call popToken;
		end;
/* 53 */	segSize(SEG$STACK) = accum1;	/* STKLN ? */
$IF OVL4
/* 54 */	call sub$7517;			/* MACRO ? */
/* 55 */	call sub$753E;
/* 56 */	call sub$75FF;			/* ENDM */
/* 57 */	call sub$76CE;			/* EXITM */
/* 58 */	do;
			tmac$mtype = 4;
			call sub$7327;
		end;
/* 59 */	call sub$72A4(1);		/* IRP ? */
/* 60 */	call sub$72A4(2);		/* IRPC */
/* 61 */	call sub$770B;
/* 62 */	call sub$7844;			/* REPT ? */
/* 63 */	call sub$787A;			/* LOCAL */
/* 64 */	call sub$78CE;
/* 65 */	do;				/* NUL */
			call cond2Acc(tokenType(0) = K$NUL);
			call popToken;
			acc1Flags = 0;
		end;
$ENDIF
	end;

	if op <> 1 then
		b6743 = FALSE;
end;

parseLine: procedure public;

	isExpressionOp: procedure byte;
		if effectiveToken > 3 then
			if effectiveToken <> T$COMMA then
				if effectiveToken < 1Ah then
					return TRUE;
		return FALSE;
	end;

	sub$53DF: procedure(arg1b) byte;
		declare arg1b byte;
		return arg1b = O$ID or arg1b = O$64;
	end;


	sub$53F8: procedure;
		if not isInstrMap(op) then
			b6B34 = FALSE;
	end;



	do while 1;
		if not (effectiveToken = T$CR or effectiveToken >= K$END and effectiveToken <= K$ENDIF) and skipping(0)
$IF OVL4
	           or (b4181(effectiveToken) < 128 or b9058) and b905E

$ENDIF
	        then
		do;
			b6885 = FALSE;
			call popToken;
			return;
		end;
		
		if phase <> 1 then
			if inExpression then
				if isExpressionOp then
					if getPrec(effectiveToken) <= getPrec(opStack(opSP)) then
						call expressionError;

		if getPrec(opType := effectiveToken) > getPrec(op := opStack(opSP)) or opType = T$LPAREN then
		do;
			if opSP >= 16 then
			do;
				opSP = 0;
				call stackError;
			end;
			else
				opStack(opSP := opSP + 1) = opType;
			if opType = T$LPAREN then
			do;
				inNestedParen = inParen;
				inParen = TRUE;
			end;
			if phase > 1 then
				inExpression = isExpressionOp;
			return;
		end;

		inExpression = 0;
		if not inParen and op > 3 then
			call syntaxError;

		if op = 0 then
			op = opType;
		else
			opSP = opSP - 1;
		

		if (b6B28 := b4181(op)) then
		do;
			accum2 = getNumVal;
			acc2Flags = acc1Flags;
			acc2NumVal = acc1NumVal;
			acc2ValType = acc1ValType;
		end;

		if (b6B28 := ror(b6B28, 1)) then
			accum1 = getNumVal;

		if not b6857 then
			b6857 = sub$53DF(acc1ValType) or sub$53DF(acc2ValType);

		b6B2D = O$NUMBER;
		if op > T$RPAREN and op < K$DB then	/* expression op */
			call sub$4291;
		else
		do;
			call sub$53F8;
			call sub$4274;
		end;

		call handleOp;
		if not isExprOrMacroMap(op) then
			inParen = FALSE;

		if b6B2C then
		do;
			b6B2C = FALSE;
			return;
		end;

		if op <> K$DS and showAddr then		/* DS */
			effectiveAddr = accum1;

		if (b6B28 and 1Eh) <> 0 then
			call pushToken(b6B2D);

		do ii = 0 to 3;
			if (b6B28 := ror(b6B28, 1)) then
				call collectByte(accum(ii));
		end;

		tokenAttr(0) = acc1Flags;
		tokenSymId(0) = acc1NumVal;
		if ror(b6B28, 1) then
			if opType = T$COMMA then
			do;
				effectiveToken = op;
				inParen = TRUE;
			end;
	end;
end;



doPass: procedure public;
	do while finished = FALSE;
		call tokeniseLine;
		call parseLine;
	end;
end;

end;
