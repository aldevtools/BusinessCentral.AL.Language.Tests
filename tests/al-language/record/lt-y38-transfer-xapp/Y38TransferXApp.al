// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-transferfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables of Y38TransferXAppObjects.al; table 61105 "LT Y38 XA Target" (tests/al-language-xapp-a).
// Writer Y38 (gap cycle 3, C3-16): TransferFields from a table of this app into a table of another app (61105) and into tables of this app,
// where field numbers have other types in source and target: Boolean into Decimal (the Subscription Billing contract into Sales Header shape:
// Target.TransferFields(Source, false) on an inserted target), Integer into Decimal, Code[10] into Text[5], Option into Integer, Text into Code,
// Date into DateTime, Decimal into Boolean. Neighbour of record/lt-record-write/RcBTransfer.al Transfer_From_Another_Apps_Table_Type_Mismatch_BQ.
// Mode 1 = TransferFields(Src, false), 2 = TransferFields(Src), 3 = TransferFields(Src, false, true).
// Each target dump lists every field as Format(value, 0, 9).

codeunit 92579 "LT Y38 TF XApp Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Source(var Src: Record "LT Y38 TF Source"; Flag: Boolean; CodValue: Code[10])
    begin
        Src.Init();
        Src."No." := 'S1';
        Src.CustNo := 'C1';
        Src.Name := 'Src name';
        Src.Flag := Flag;
        Src.Qty := 7;
        Src.Cod := CodValue;
        Src.Opt := Src.Opt::C;
        Src.Txt := 'abc';
        Src.Dt := 20260115D;
        Src.Amt := 3.25;
    end;

    local procedure Dump(RecVariant: Variant): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        i: Integer;
        Result: Text;
    begin
        RecRef.GetTable(RecVariant);
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            if FldRef.Number() < 2000000000 then
                Result += FldRef.Name() + '=' + Format(FldRef.Value(), 0, 9) + ';';
        end;
        exit(Result);
    end;

    local procedure Outcome(Ok: Boolean): Text
    var
        Result: Text;
    begin
        if Ok then
            exit('ok');
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    local procedure SeedRef(TableNo: Integer; Insert: Boolean)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo);
        RecRef.DeleteAll();
        RecRef.Init();
        RecRef.Field(1).Value := 'T1';
        RecRef.Field(2).Value := 'OLD';
        if RecRef.FieldExist(33) then
            RecRef.Field(33).Value := 1.5;
        if RecRef.FieldExist(40) then
            RecRef.Field(40).Value := 2.5;
        if RecRef.FieldExist(41) then
            RecRef.Field(41).Value := 'KEEP';
        if Insert then
            RecRef.Insert();
        RecRef.Close();
    end;

    [TryFunction]
    local procedure TryTfXa(var Dst: Record "LT Y38 XA Target"; var Src: Record "LT Y38 TF Source"; Mode: Integer)
    begin
        case Mode of
            1:
                Dst.TransferFields(Src, false);
            2:
                Dst.TransferFields(Src);
            3:
                Dst.TransferFields(Src, false, true);
        end;
    end;

    // Seeds row T1 (CustNo OLD, 1.5 in field 33 and 2.5 in field 40 where they are Decimal, KEEP in field 41 where it is Text[5]) inserted or only in memory, transfers, and
    // answers the outcome, the target in memory and (Inserted) the stored row read again.
    local procedure RunXa(Mode: Integer; Flag: Boolean; CodValue: Code[10]; Inserted: Boolean; ModifyAfter: Boolean): Text
    var
        Dst: Record "LT Y38 XA Target";
        Stored: Record "LT Y38 XA Target";
        Src: Record "LT Y38 TF Source";
        Result: Text;
    begin
        SeedRef(61105, Inserted);
        if Inserted then
            Dst.Get('T1')
        else begin
            Dst.Init();
            Dst."No." := 'T1';
            Dst.CustNo := 'OLD';
        end;
        Source(Src, Flag, CodValue);
        Result := Outcome(TryTfXa(Dst, Src, Mode)) + ' mem:' + Dump(Dst);
        if ModifyAfter then
            Result += ' modify:' + Outcome(Dst.Modify());
        if Inserted then begin
            Stored.Get('T1');
            Result += ' stored:' + Dump(Stored);
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryTfSame(var Dst: Record "LT Y38 TF Same Target"; var Src: Record "LT Y38 TF Source"; Mode: Integer)
    begin
        case Mode of
            1:
                Dst.TransferFields(Src, false);
            2:
                Dst.TransferFields(Src);
            3:
                Dst.TransferFields(Src, false, true);
        end;
    end;

    // Seeds row T1 (CustNo OLD, 1.5 in field 33 and 2.5 in field 40 where they are Decimal, KEEP in field 41 where it is Text[5]) inserted or only in memory, transfers, and
    // answers the outcome, the target in memory and (Inserted) the stored row read again.
    local procedure RunSame(Mode: Integer; Flag: Boolean; CodValue: Code[10]; Inserted: Boolean; ModifyAfter: Boolean): Text
    var
        Dst: Record "LT Y38 TF Same Target";
        Stored: Record "LT Y38 TF Same Target";
        Src: Record "LT Y38 TF Source";
        Result: Text;
    begin
        SeedRef(92571, Inserted);
        if Inserted then
            Dst.Get('T1')
        else begin
            Dst.Init();
            Dst."No." := 'T1';
            Dst.CustNo := 'OLD';
        end;
        Source(Src, Flag, CodValue);
        Result := Outcome(TryTfSame(Dst, Src, Mode)) + ' mem:' + Dump(Dst);
        if ModifyAfter then
            Result += ' modify:' + Outcome(Dst.Modify());
        if Inserted then begin
            Stored.Get('T1');
            Result += ' stored:' + Dump(Stored);
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryTfP33(var Dst: Record "LT Y38 TF Pair 33"; var Src: Record "LT Y38 TF Source"; Mode: Integer)
    begin
        case Mode of
            1:
                Dst.TransferFields(Src, false);
            2:
                Dst.TransferFields(Src);
            3:
                Dst.TransferFields(Src, false, true);
        end;
    end;

    // Seeds row T1 (CustNo OLD, 1.5 in field 33 and 2.5 in field 40 where they are Decimal, KEEP in field 41 where it is Text[5]) inserted or only in memory, transfers, and
    // answers the outcome, the target in memory and (Inserted) the stored row read again.
    local procedure RunP33(Mode: Integer; Flag: Boolean; CodValue: Code[10]; Inserted: Boolean; ModifyAfter: Boolean): Text
    var
        Dst: Record "LT Y38 TF Pair 33";
        Stored: Record "LT Y38 TF Pair 33";
        Src: Record "LT Y38 TF Source";
        Result: Text;
    begin
        SeedRef(92572, Inserted);
        if Inserted then
            Dst.Get('T1')
        else begin
            Dst.Init();
            Dst."No." := 'T1';
            Dst.CustNo := 'OLD';
        end;
        Source(Src, Flag, CodValue);
        Result := Outcome(TryTfP33(Dst, Src, Mode)) + ' mem:' + Dump(Dst);
        if ModifyAfter then
            Result += ' modify:' + Outcome(Dst.Modify());
        if Inserted then begin
            Stored.Get('T1');
            Result += ' stored:' + Dump(Stored);
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryTfP40(var Dst: Record "LT Y38 TF Pair 40"; var Src: Record "LT Y38 TF Source"; Mode: Integer)
    begin
        case Mode of
            1:
                Dst.TransferFields(Src, false);
            2:
                Dst.TransferFields(Src);
            3:
                Dst.TransferFields(Src, false, true);
        end;
    end;

    // Seeds row T1 (CustNo OLD, 1.5 in field 33 and 2.5 in field 40 where they are Decimal, KEEP in field 41 where it is Text[5]) inserted or only in memory, transfers, and
    // answers the outcome, the target in memory and (Inserted) the stored row read again.
    local procedure RunP40(Mode: Integer; Flag: Boolean; CodValue: Code[10]; Inserted: Boolean; ModifyAfter: Boolean): Text
    var
        Dst: Record "LT Y38 TF Pair 40";
        Stored: Record "LT Y38 TF Pair 40";
        Src: Record "LT Y38 TF Source";
        Result: Text;
    begin
        SeedRef(92573, Inserted);
        if Inserted then
            Dst.Get('T1')
        else begin
            Dst.Init();
            Dst."No." := 'T1';
            Dst.CustNo := 'OLD';
        end;
        Source(Src, Flag, CodValue);
        Result := Outcome(TryTfP40(Dst, Src, Mode)) + ' mem:' + Dump(Dst);
        if ModifyAfter then
            Result += ' modify:' + Outcome(Dst.Modify());
        if Inserted then begin
            Stored.Get('T1');
            Result += ' stored:' + Dump(Stored);
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryTfP41(var Dst: Record "LT Y38 TF Pair 41"; var Src: Record "LT Y38 TF Source"; Mode: Integer)
    begin
        case Mode of
            1:
                Dst.TransferFields(Src, false);
            2:
                Dst.TransferFields(Src);
            3:
                Dst.TransferFields(Src, false, true);
        end;
    end;

    // Seeds row T1 (CustNo OLD, 1.5 in field 33 and 2.5 in field 40 where they are Decimal, KEEP in field 41 where it is Text[5]) inserted or only in memory, transfers, and
    // answers the outcome, the target in memory and (Inserted) the stored row read again.
    local procedure RunP41(Mode: Integer; Flag: Boolean; CodValue: Code[10]; Inserted: Boolean; ModifyAfter: Boolean): Text
    var
        Dst: Record "LT Y38 TF Pair 41";
        Stored: Record "LT Y38 TF Pair 41";
        Src: Record "LT Y38 TF Source";
        Result: Text;
    begin
        SeedRef(92574, Inserted);
        if Inserted then
            Dst.Get('T1')
        else begin
            Dst.Init();
            Dst."No." := 'T1';
            Dst.CustNo := 'OLD';
        end;
        Source(Src, Flag, CodValue);
        Result := Outcome(TryTfP41(Dst, Src, Mode)) + ' mem:' + Dump(Dst);
        if ModifyAfter then
            Result += ' modify:' + Outcome(Dst.Modify());
        if Inserted then begin
            Stored.Get('T1');
            Result += ' stored:' + Dump(Stored);
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryTfP42(var Dst: Record "LT Y38 TF Pair 42"; var Src: Record "LT Y38 TF Source"; Mode: Integer)
    begin
        case Mode of
            1:
                Dst.TransferFields(Src, false);
            2:
                Dst.TransferFields(Src);
            3:
                Dst.TransferFields(Src, false, true);
        end;
    end;

    // Seeds row T1 (CustNo OLD, 1.5 in field 33 and 2.5 in field 40 where they are Decimal, KEEP in field 41 where it is Text[5]) inserted or only in memory, transfers, and
    // answers the outcome, the target in memory and (Inserted) the stored row read again.
    local procedure RunP42(Mode: Integer; Flag: Boolean; CodValue: Code[10]; Inserted: Boolean; ModifyAfter: Boolean): Text
    var
        Dst: Record "LT Y38 TF Pair 42";
        Stored: Record "LT Y38 TF Pair 42";
        Src: Record "LT Y38 TF Source";
        Result: Text;
    begin
        SeedRef(92575, Inserted);
        if Inserted then
            Dst.Get('T1')
        else begin
            Dst.Init();
            Dst."No." := 'T1';
            Dst.CustNo := 'OLD';
        end;
        Source(Src, Flag, CodValue);
        Result := Outcome(TryTfP42(Dst, Src, Mode)) + ' mem:' + Dump(Dst);
        if ModifyAfter then
            Result += ' modify:' + Outcome(Dst.Modify());
        if Inserted then begin
            Stored.Get('T1');
            Result += ' stored:' + Dump(Stored);
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryTfP43(var Dst: Record "LT Y38 TF Pair 43"; var Src: Record "LT Y38 TF Source"; Mode: Integer)
    begin
        case Mode of
            1:
                Dst.TransferFields(Src, false);
            2:
                Dst.TransferFields(Src);
            3:
                Dst.TransferFields(Src, false, true);
        end;
    end;

    // Seeds row T1 (CustNo OLD, 1.5 in field 33 and 2.5 in field 40 where they are Decimal, KEEP in field 41 where it is Text[5]) inserted or only in memory, transfers, and
    // answers the outcome, the target in memory and (Inserted) the stored row read again.
    local procedure RunP43(Mode: Integer; Flag: Boolean; CodValue: Code[10]; Inserted: Boolean; ModifyAfter: Boolean): Text
    var
        Dst: Record "LT Y38 TF Pair 43";
        Stored: Record "LT Y38 TF Pair 43";
        Src: Record "LT Y38 TF Source";
        Result: Text;
    begin
        SeedRef(92576, Inserted);
        if Inserted then
            Dst.Get('T1')
        else begin
            Dst.Init();
            Dst."No." := 'T1';
            Dst.CustNo := 'OLD';
        end;
        Source(Src, Flag, CodValue);
        Result := Outcome(TryTfP43(Dst, Src, Mode)) + ' mem:' + Dump(Dst);
        if ModifyAfter then
            Result += ' modify:' + Outcome(Dst.Modify());
        if Inserted then begin
            Stored.Get('T1');
            Result += ' stored:' + Dump(Stored);
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryTfP44(var Dst: Record "LT Y38 TF Pair 44"; var Src: Record "LT Y38 TF Source"; Mode: Integer)
    begin
        case Mode of
            1:
                Dst.TransferFields(Src, false);
            2:
                Dst.TransferFields(Src);
            3:
                Dst.TransferFields(Src, false, true);
        end;
    end;

    // Seeds row T1 (CustNo OLD, 1.5 in field 33 and 2.5 in field 40 where they are Decimal, KEEP in field 41 where it is Text[5]) inserted or only in memory, transfers, and
    // answers the outcome, the target in memory and (Inserted) the stored row read again.
    local procedure RunP44(Mode: Integer; Flag: Boolean; CodValue: Code[10]; Inserted: Boolean; ModifyAfter: Boolean): Text
    var
        Dst: Record "LT Y38 TF Pair 44";
        Stored: Record "LT Y38 TF Pair 44";
        Src: Record "LT Y38 TF Source";
        Result: Text;
    begin
        SeedRef(92577, Inserted);
        if Inserted then
            Dst.Get('T1')
        else begin
            Dst.Init();
            Dst."No." := 'T1';
            Dst.CustNo := 'OLD';
        end;
        Source(Src, Flag, CodValue);
        Result := Outcome(TryTfP44(Dst, Src, Mode)) + ' mem:' + Dump(Dst);
        if ModifyAfter then
            Result += ' modify:' + Outcome(Dst.Modify());
        if Inserted then begin
            Stored.Get('T1');
            Result += ' stored:' + Dump(Stored);
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryTfP45(var Dst: Record "LT Y38 TF Pair 45"; var Src: Record "LT Y38 TF Source"; Mode: Integer)
    begin
        case Mode of
            1:
                Dst.TransferFields(Src, false);
            2:
                Dst.TransferFields(Src);
            3:
                Dst.TransferFields(Src, false, true);
        end;
    end;

    // Seeds row T1 (CustNo OLD, 1.5 in field 33 and 2.5 in field 40 where they are Decimal, KEEP in field 41 where it is Text[5]) inserted or only in memory, transfers, and
    // answers the outcome, the target in memory and (Inserted) the stored row read again.
    local procedure RunP45(Mode: Integer; Flag: Boolean; CodValue: Code[10]; Inserted: Boolean; ModifyAfter: Boolean): Text
    var
        Dst: Record "LT Y38 TF Pair 45";
        Stored: Record "LT Y38 TF Pair 45";
        Src: Record "LT Y38 TF Source";
        Result: Text;
    begin
        SeedRef(92578, Inserted);
        if Inserted then
            Dst.Get('T1')
        else begin
            Dst.Init();
            Dst."No." := 'T1';
            Dst.CustNo := 'OLD';
        end;
        Source(Src, Flag, CodValue);
        Result := Outcome(TryTfP45(Dst, Src, Mode)) + ' mem:' + Dump(Dst);
        if ModifyAfter then
            Result += ' modify:' + Outcome(Dst.Modify());
        if Inserted then begin
            Stored.Get('T1');
            Result += ' stored:' + Dump(Stored);
        end;
        exit(Result);
    end;

    // X1: the blocked shape: inserted target of another app, TransferFields(Src, false), Boolean true into Decimal.
    [Test]
    procedure XA_TF_BoolToDecimal_NoKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('x1', RunXa(1, true, 'ABC', true, false));
        Observer.Expect('x1', 'ok mem:No.=T1;CustNo=C1;OtherName=Src name;Factor=1.5;Qty=2.5;Cod=ABC;Opt=0;Txt=ABC;Dt=;Amt=false; stored:No.=T1;CustNo=OLD;OtherName=;Factor=1.5;Qty=2.5;Cod=KEEP;Opt=0;Txt=;Dt=;Amt=false;');
        Observer.Verify();
    end;

    // X2: as X1 with a false Boolean (1.5 in the target tells "skipped" from "converted to 0").
    [Test]
    procedure XA_TF_BoolToDecimal_NoKey_FalseFlag()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('x2', RunXa(1, false, 'ABC', true, false));
        Observer.Expect('x2', 'ok mem:No.=T1;CustNo=C1;OtherName=Src name;Factor=1.5;Qty=2.5;Cod=ABC;Opt=0;Txt=ABC;Dt=;Amt=false; stored:No.=T1;CustNo=OLD;OtherName=;Factor=1.5;Qty=2.5;Cod=KEEP;Opt=0;Txt=;Dt=;Amt=false;');
        Observer.Verify();
    end;

    // X3: TransferFields(Src) (InitPrimaryKeyFields true) on a target of another app that is not inserted.
    [Test]
    procedure XA_TF_BoolToDecimal_WithKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('x3', RunXa(2, true, 'ABC', false, false));
        Observer.Expect('x3', 'ok mem:No.=S1;CustNo=C1;OtherName=Src name;Factor=0;Qty=0;Cod=ABC;Opt=0;Txt=ABC;Dt=;Amt=false;');
        Observer.Verify();
    end;

    // X4: TransferFields(Src, false, true) (SkipFieldsWithoutCheck) across apps.
    [Test]
    procedure XA_TF_Kinds_Skip()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('x4', RunXa(3, true, 'ABC', true, false));
        Observer.Expect('x4', 'ok mem:No.=T1;CustNo=C1;OtherName=Src name;Factor=1.5;Qty=2.5;Cod=ABC;Opt=0;Txt=ABC;Dt=;Amt=false; stored:No.=T1;CustNo=OLD;OtherName=;Factor=1.5;Qty=2.5;Cod=KEEP;Opt=0;Txt=;Dt=;Amt=false;');
        Observer.Verify();
    end;

    // X5: X1, then Modify of the target and the stored row.
    [Test]
    procedure XA_TF_Kinds_Modify()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('x5', RunXa(1, true, 'ABC', true, true));
        Observer.Expect('x5', 'ok mem:No.=T1;CustNo=C1;OtherName=Src name;Factor=1.5;Qty=2.5;Cod=ABC;Opt=0;Txt=ABC;Dt=;Amt=false; modify:ok stored:No.=T1;CustNo=C1;OtherName=Src name;Factor=1.5;Qty=2.5;Cod=ABC;Opt=0;Txt=ABC;Dt=;Amt=false;');
        Observer.Verify();
    end;

    // Across apps, a Code[10] value longer than the target Text[5], with and without SkipFieldsWithoutCheck.
    [Test]
    procedure XA_TF_LongCode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('long_noskip', RunXa(1, true, 'ABCDEFG', true, false));
        Observer.Observe('long_skip', RunXa(3, true, 'ABCDEFG', true, false));
        Observer.Expect('long_noskip', 'ok mem:No.=T1;CustNo=C1;OtherName=Src name;Factor=1.5;Qty=2.5;Cod=KEEP;Opt=0;Txt=ABC;Dt=;Amt=false; stored:No.=T1;CustNo=OLD;OtherName=;Factor=1.5;Qty=2.5;Cod=KEEP;Opt=0;Txt=;Dt=;Amt=false;');
        Observer.Expect('long_skip', 'ok mem:No.=T1;CustNo=C1;OtherName=Src name;Factor=1.5;Qty=2.5;Cod=KEEP;Opt=0;Txt=ABC;Dt=;Amt=false; stored:No.=T1;CustNo=OLD;OtherName=;Factor=1.5;Qty=2.5;Cod=KEEP;Opt=0;Txt=;Dt=;Amt=false;');
        Observer.Verify();
    end;

    // S1: the same shape within one app.
    [Test]
    procedure SA_TF_BoolToDecimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s1', RunSame(1, true, 'ABC', true, false));
        Observer.Expect('s1', 'error:The following fields must have the same type:\\Field: Factor <-- Flag\Table: LT Y38 TF Same Target <-- LT Y38 TF Source\Type: Decimal <-- Boolean|DB:TypeMisMatch mem:No.=T1;CustNo=C1;OtherName=Src name;Factor=1.5;Qty=2.5;Cod=KEEP;Opt=0;Txt=;Dt=;Amt=false; stored:No.=T1;CustNo=OLD;OtherName=;Factor=1.5;Qty=2.5;Cod=KEEP;Opt=0;Txt=;Dt=;Amt=false;');
        Observer.Verify();
    end;

    // S2: SkipFieldsWithoutCheck within one app.
    [Test]
    procedure SA_TF_Kinds_Skip()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s2', RunSame(3, true, 'ABC', true, false));
        Observer.Expect('s2', 'ok mem:No.=T1;CustNo=C1;OtherName=Src name;Factor=1.5;Qty=2.5;Cod=ABC;Opt=0;Txt=ABC;Dt=;Amt=false; stored:No.=T1;CustNo=OLD;OtherName=;Factor=1.5;Qty=2.5;Cod=KEEP;Opt=0;Txt=;Dt=;Amt=false;');
        Observer.Verify();
    end;

    // Within one app, one mismatched field per target table, TransferFields(Src, false).
    [Test]
    procedure SA_TF_Pairs_NoSkip()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('p33', RunP33(1, true, 'ABC', true, false));
        Observer.Observe('p40', RunP40(1, true, 'ABC', true, false));
        Observer.Observe('p41', RunP41(1, true, 'ABC', true, false));
        Observer.Observe('p42', RunP42(1, true, 'ABC', true, false));
        Observer.Expect('p33', 'error:The following fields must have the same type:\\Field: Factor <-- Flag\Table: LT Y38 TF Pair 33 <-- LT Y38 TF Source\Type: Decimal <-- Boolean|DB:TypeMisMatch mem:No.=T1;CustNo=C1;Factor=1.5; stored:No.=T1;CustNo=OLD;Factor=1.5;');
        Observer.Expect('p40', 'error:The following fields must have the same type:\\Field: Qty <-- Qty\Table: LT Y38 TF Pair 40 <-- LT Y38 TF Source\Type: Decimal <-- Integer|DB:TypeMisMatch mem:No.=T1;CustNo=C1;Qty=2.5; stored:No.=T1;CustNo=OLD;Qty=2.5;');
        Observer.Expect('p41', 'ok mem:No.=T1;CustNo=C1;Cod=ABC; stored:No.=T1;CustNo=OLD;Cod=KEEP;');
        Observer.Expect('p42', 'error:The following fields must have the same type:\\Field: Opt <-- Opt\Table: LT Y38 TF Pair 42 <-- LT Y38 TF Source\Type: Integer <-- Option|DB:TypeMisMatch mem:No.=T1;CustNo=C1;Opt=0; stored:No.=T1;CustNo=OLD;Opt=0;');
        Observer.Verify();
    end;

    // As SA_TF_Pairs_NoSkip, the other pairs.
    [Test]
    procedure SA_TF_Pairs_NoSkip_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('p43', RunP43(1, true, 'ABC', true, false));
        Observer.Observe('p44', RunP44(1, true, 'ABC', true, false));
        Observer.Observe('p45', RunP45(1, true, 'ABC', true, false));
        Observer.Observe('p33_false', RunP33(1, false, 'ABC', true, false));
        Observer.Observe('p41_long', RunP41(1, true, 'ABCDEFG', true, false));
        Observer.Expect('p43', 'ok mem:No.=T1;CustNo=C1;Txt=ABC; stored:No.=T1;CustNo=OLD;Txt=;');
        Observer.Expect('p44', 'error:The following fields must have the same type:\\Field: Dt <-- Dt\Table: LT Y38 TF Pair 44 <-- LT Y38 TF Source\Type: DateTime <-- Date|DB:TypeMisMatch mem:No.=T1;CustNo=C1;Dt=; stored:No.=T1;CustNo=OLD;Dt=;');
        Observer.Expect('p45', 'error:The following fields must have the same type:\\Field: Amt <-- Amt\Table: LT Y38 TF Pair 45 <-- LT Y38 TF Source\Type: Boolean <-- Decimal|DB:TypeMisMatch mem:No.=T1;CustNo=C1;Amt=false; stored:No.=T1;CustNo=OLD;Amt=false;');
        Observer.Expect('p33_false', 'error:The following fields must have the same type:\\Field: Factor <-- Flag\Table: LT Y38 TF Pair 33 <-- LT Y38 TF Source\Type: Decimal <-- Boolean|DB:TypeMisMatch mem:No.=T1;CustNo=C1;Factor=1.5; stored:No.=T1;CustNo=OLD;Factor=1.5;');
        Observer.Expect('p41_long', 'error:The contents of the Cod field cannot be copied to the Cod field because the size of the Cod field is too small.\\Type: Text5 <-- Code10\Field: Cod <-- Cod\Table: LT Y38 TF Pair 41 <-- LT Y38 TF Source|DB:TypeMisMatch mem:No.=T1;CustNo=C1;Cod=KEEP; stored:No.=T1;CustNo=OLD;Cod=KEEP;');
        Observer.Verify();
    end;

    // Within one app, one mismatched field per target table, TransferFields(Src, false, true).
    [Test]
    procedure SA_TF_Pairs_Skip()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('p33', RunP33(3, true, 'ABC', true, false));
        Observer.Observe('p40', RunP40(3, true, 'ABC', true, false));
        Observer.Observe('p41', RunP41(3, true, 'ABC', true, false));
        Observer.Observe('p42', RunP42(3, true, 'ABC', true, false));
        Observer.Observe('p43', RunP43(3, true, 'ABC', true, false));
        Observer.Observe('p44', RunP44(3, true, 'ABC', true, false));
        Observer.Observe('p45', RunP45(3, true, 'ABC', true, false));
        Observer.Observe('p41_long', RunP41(3, true, 'ABCDEFG', true, false));
        Observer.Expect('p33', 'ok mem:No.=T1;CustNo=C1;Factor=1.5; stored:No.=T1;CustNo=OLD;Factor=1.5;');
        Observer.Expect('p40', 'ok mem:No.=T1;CustNo=C1;Qty=2.5; stored:No.=T1;CustNo=OLD;Qty=2.5;');
        Observer.Expect('p41', 'ok mem:No.=T1;CustNo=C1;Cod=ABC; stored:No.=T1;CustNo=OLD;Cod=KEEP;');
        Observer.Expect('p42', 'ok mem:No.=T1;CustNo=C1;Opt=0; stored:No.=T1;CustNo=OLD;Opt=0;');
        Observer.Expect('p43', 'ok mem:No.=T1;CustNo=C1;Txt=ABC; stored:No.=T1;CustNo=OLD;Txt=;');
        Observer.Expect('p44', 'ok mem:No.=T1;CustNo=C1;Dt=; stored:No.=T1;CustNo=OLD;Dt=;');
        Observer.Expect('p45', 'ok mem:No.=T1;CustNo=C1;Amt=false; stored:No.=T1;CustNo=OLD;Amt=false;');
        Observer.Expect('p41_long', 'ok mem:No.=T1;CustNo=C1;Cod=KEEP; stored:No.=T1;CustNo=OLD;Cod=KEEP;');
        Observer.Verify();
    end;

    // Within one app, one mismatched field per target table, TransferFields(Src) on a target that is not inserted.
    [Test]
    procedure SA_TF_Pairs_WithKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('p33', RunP33(2, true, 'ABC', false, false));
        Observer.Observe('p40', RunP40(2, true, 'ABC', false, false));
        Observer.Observe('p41', RunP41(2, true, 'ABC', false, false));
        Observer.Observe('p42', RunP42(2, true, 'ABC', false, false));
        Observer.Observe('p43', RunP43(2, true, 'ABC', false, false));
        Observer.Observe('p44', RunP44(2, true, 'ABC', false, false));
        Observer.Observe('p45', RunP45(2, true, 'ABC', false, false));
        Observer.Expect('p33', 'error:The following fields must have the same type:\\Field: Factor <-- Flag\Table: LT Y38 TF Pair 33 <-- LT Y38 TF Source\Type: Decimal <-- Boolean|DB:TypeMisMatch mem:No.=S1;CustNo=C1;Factor=0;');
        Observer.Expect('p40', 'error:The following fields must have the same type:\\Field: Qty <-- Qty\Table: LT Y38 TF Pair 40 <-- LT Y38 TF Source\Type: Decimal <-- Integer|DB:TypeMisMatch mem:No.=S1;CustNo=C1;Qty=0;');
        Observer.Expect('p41', 'ok mem:No.=S1;CustNo=C1;Cod=ABC;');
        Observer.Expect('p42', 'error:The following fields must have the same type:\\Field: Opt <-- Opt\Table: LT Y38 TF Pair 42 <-- LT Y38 TF Source\Type: Integer <-- Option|DB:TypeMisMatch mem:No.=S1;CustNo=C1;Opt=0;');
        Observer.Expect('p43', 'ok mem:No.=S1;CustNo=C1;Txt=ABC;');
        Observer.Expect('p44', 'error:The following fields must have the same type:\\Field: Dt <-- Dt\Table: LT Y38 TF Pair 44 <-- LT Y38 TF Source\Type: DateTime <-- Date|DB:TypeMisMatch mem:No.=S1;CustNo=C1;Dt=;');
        Observer.Expect('p45', 'error:The following fields must have the same type:\\Field: Amt <-- Amt\Table: LT Y38 TF Pair 45 <-- LT Y38 TF Source\Type: Boolean <-- Decimal|DB:TypeMisMatch mem:No.=S1;CustNo=C1;Amt=false;');
        Observer.Verify();
    end;
}
