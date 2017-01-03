$IF OVL4
asm45: do;
$include(:f3:asm45.ipx)
$ELSEIF OVL5
asm55: do;
$include(:f3:asm55.ipx)
$ELSE
asm851: do;
$include(:f3:asm851.ipx)
$ENDIF

$IF BASE
declare CHKOVL$1 lit    'call OvlMgr(1)',
    CHKOVL$2 lit    'call OvlMgr(2)';
$ELSE
declare CHKOVL$1 lit    ' ',
    CHKOVL$2 lit    ' ';
$ENDIF

declare pad1 address data(40h),
    pad2 address;


StrUcEqu: procedure(s, t) bool public;
    declare (s, t) pointer;
    declare sCh based s byte,
        tCh based t byte;

    do while sCh <> 0;
        if sCh <> tCh and sCh <> (tCh and 5Fh) then
            return FALSE;
        s = s + 1;
        t = t + 1;
    end;
    return TRUE;
end;


IsSkipping: procedure byte public;
    return 
$IF OVL4
        b905E or
$ENDIF
        skipping(0);
end;

Sub546F: procedure public;
    spIdx = NxtTokI;
    if expectingOperands then
        call SyntaxError;
    if HaveTokens then
        if not(tokenType(spIdx) = O$DATA or lineNumberEmitted) then
            call SyntaxError;
    if inDB or inDW then
    do;
        if tokenIdx = 1 and not BlankAsmErrCode and tokenSize(0) <> 1 then
            tokenSize(0) = 2;
    end;
    else if not BlankAsmErrCode and HaveTokens then
        if tokenSize(spIdx) > 3 then
            tokenSize(spIdx) = 3;
end;


FinishLine: procedure public;
    declare lineno$p pointer,
        updating byte,
        ch based lineno$p byte;

    call Sub546F;
    if IsPhase2Print then
    do;    /* update the ascii line number */
        lineno$p = .asciiLineNo(3);    /* point to last digit */
        updating = TRUE;

        do while updating;        /* adjust the line number */
            if ch = '9' then    /* if 9 then roll over to 0 */
                ch = '0';
            else
            do;
                if ch = ' ' then    /* new digit */
                    ch = '1';
                else            /* just increment */
                    ch = ch + 1;
                updating = FALSE;
            end;
            lineno$p = lineno$p - 1;
        end;

        if ShowLine or not BlankAsmErrCode then
        do;
            CHKOVL$1;
            call PrintLine;
        end;
    end;

    if b6BD9 then
    do;
        out$p = out$p + 1;
        call Flushout;
        call Exit;
    end;

    if not isControlLine then
    do;
        ii = 2;
        if tokenIdx < 2 or inDB or inDW then
            ii = 0;

        w6BCE = tokStart(ii) + tokenSize(ii);
        if IsSkipping or not isInstr then
            w6BCE = .lineBuf;

        if ChkGenObj then
        do;
            CHKOVL$2;
            call Ovl8;
        end;
        b6B2C = TRUE;
        segSize(activeSeg), effectiveAddr = segSize(activeSeg) + (w6BCE - .lineBuf);
    end;

    if ctlXREF and rhsUserSymbol then
        if phase = 1 then
            call EmitXref(XREF$REF, .name);

$IF OVL4
    call FlushM;
$ENDIF

    do while tokenIdx > 0;
        call PopToken;
    end;

    call InitLine;
    if b6B33 then
    do;
        finished = TRUE;
        if IsPhase2Print and ctlSYMBOLS then
        do;
            CHKOVL$1;
            call Sub7041$8447;
        end;

        call EmitXref(XREF$FIN, .name);    /* finalise xref file */
        if ChkGenObj then
        do;
            CHKOVL$2;
            call ReinitFixupRecs;
        end;
    end;
end;

end;
