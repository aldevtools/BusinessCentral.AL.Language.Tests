// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-testfield-method
// Scope: in-scope
// Fixtures used: TestFieldTypedFixture.al (table 70955 "LT TFT Rec", enum 70954 "LT TFT Kind")
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: FieldRef.TestField(Value) where the variable type differs from the field type (runtime check): result, error text and code; type pairs on a Text, Integer, Date, DateTime, Boolean, Guid, Enum, Decimal and BigInteger field.
// BC versions: 29 (27 and 28 by CI)

codeunit 70974 "LT TFT FRef Mismatch"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryBig(var Fld: FieldRef; V: BigInteger)
    begin
        Fld.TestField(V);
    end;

    [TryFunction]
    local procedure TryInfoBig(var Fld: FieldRef; V: BigInteger; Info: ErrorInfo)
    begin
        Fld.TestField(V, Info);
    end;

    [TryFunction]
    local procedure TryDec(var Fld: FieldRef; V: Decimal)
    begin
        Fld.TestField(V);
    end;

    [TryFunction]
    local procedure TryInfoDec(var Fld: FieldRef; V: Decimal; Info: ErrorInfo)
    begin
        Fld.TestField(V, Info);
    end;

    [TryFunction]
    local procedure TryGd(var Fld: FieldRef; V: Guid)
    begin
        Fld.TestField(V);
    end;

    [TryFunction]
    local procedure TryInfoGd(var Fld: FieldRef; V: Guid; Info: ErrorInfo)
    begin
        Fld.TestField(V, Info);
    end;

    [TryFunction]
    local procedure TryBool(var Fld: FieldRef; V: Boolean)
    begin
        Fld.TestField(V);
    end;

    [TryFunction]
    local procedure TryInfoBool(var Fld: FieldRef; V: Boolean; Info: ErrorInfo)
    begin
        Fld.TestField(V, Info);
    end;

    [TryFunction]
    local procedure TryDt(var Fld: FieldRef; V: Date)
    begin
        Fld.TestField(V);
    end;

    [TryFunction]
    local procedure TryInfoDt(var Fld: FieldRef; V: Date; Info: ErrorInfo)
    begin
        Fld.TestField(V, Info);
    end;

    [TryFunction]
    local procedure TryKnd(var Fld: FieldRef; V: Enum "LT TFT Kind")
    begin
        Fld.TestField(V);
    end;

    [TryFunction]
    local procedure TryInfoKnd(var Fld: FieldRef; V: Enum "LT TFT Kind"; Info: ErrorInfo)
    begin
        Fld.TestField(V, Info);
    end;

    [TryFunction]
    local procedure TryCode(var Fld: FieldRef; V: Code[20])
    begin
        Fld.TestField(V);
    end;

    [TryFunction]
    local procedure TryInfoCode(var Fld: FieldRef; V: Code[20]; Info: ErrorInfo)
    begin
        Fld.TestField(V, Info);
    end;

    [TryFunction]
    local procedure TryTxt(var Fld: FieldRef; V: Text)
    begin
        Fld.TestField(V);
    end;

    [TryFunction]
    local procedure TryInfoTxt(var Fld: FieldRef; V: Text; Info: ErrorInfo)
    begin
        Fld.TestField(V, Info);
    end;

    [TryFunction]
    local procedure TryInt(var Fld: FieldRef; V: Integer)
    begin
        Fld.TestField(V);
    end;

    [TryFunction]
    local procedure TryInfoInt(var Fld: FieldRef; V: Integer; Info: ErrorInfo)
    begin
        Fld.TestField(V, Info);
    end;

    [TryFunction]
    local procedure TryDtTm(var Fld: FieldRef; V: DateTime)
    begin
        Fld.TestField(V);
    end;

    [TryFunction]
    local procedure TryInfoDtTm(var Fld: FieldRef; V: DateTime; Info: ErrorInfo)
    begin
        Fld.TestField(V, Info);
    end;

    [TryFunction]
    local procedure TryByt(var Fld: FieldRef; V: Byte)
    begin
        Fld.TestField(V);
    end;

    [TryFunction]
    local procedure TryInfoByt(var Fld: FieldRef; V: Byte; Info: ErrorInfo)
    begin
        Fld.TestField(V, Info);
    end;

    [TryFunction]
    local procedure TryChr(var Fld: FieldRef; V: Char)
    begin
        Fld.TestField(V);
    end;

    [TryFunction]
    local procedure TryInfoChr(var Fld: FieldRef; V: Char; Info: ErrorInfo)
    begin
        Fld.TestField(V, Info);
    end;

    [Test]
    procedure P189_FldRefMismatch_OnTextField()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
        VBig: BigInteger;
        VDec: Decimal;
        VGd: Guid;
        VBool: Boolean;
        VDt: Date;
        VKnd: Enum "LT TFT Kind";
        VInt: Integer;
        VDtTm: DateTime;
    begin
        ClearLastError();
        Rec.DeleteAll();
        Rec.Txt := '5';
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Txt));
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        VBig := 5;
        Observer.Observe('Big_result', Format(TryBig(Fld, VBig)));
        Observer.ObserveError('Big');
        VDec := 5;
        Observer.Observe('Dec_result', Format(TryDec(Fld, VDec)));
        Observer.ObserveError('Dec');
        Evaluate(VGd, '{11111111-2222-3333-4444-555555555555}');
        Observer.Observe('Gd_result', Format(TryGd(Fld, VGd)));
        Observer.ObserveError('Gd');
        VBool := true;
        Observer.Observe('Bool_result', Format(TryBool(Fld, VBool)));
        Observer.ObserveError('Bool');
        VDt := 20240315D;
        Observer.Observe('Dt_result', Format(TryDt(Fld, VDt)));
        Observer.ObserveError('Dt');
        VKnd := VKnd::Two;
        Observer.Observe('Knd_result', Format(TryKnd(Fld, VKnd)));
        Observer.ObserveError('Knd');
        VInt := 5;
        Observer.Observe('Int_result', Format(TryInt(Fld, VInt)));
        Observer.ObserveError('Int');
        VDtTm := CreateDateTime(20240315D, 120000T);
        Observer.Observe('DtTm_result', Format(TryDtTm(Fld, VDtTm)));
        Observer.ObserveError('DtTm');
        Observer.Expect('Big_result', 'Yes');
        Observer.Expect('Big|text', '');
        Observer.Expect('Big|code', '');
        Observer.Expect('Dec_result', 'Yes');
        Observer.Expect('Dec|text', '');
        Observer.Expect('Dec|code', '');
        Observer.Expect('Gd_result', 'No');
#if BC28PLUS
        Observer.Expect('Gd|text', 'Txt must be equal to ''{11111111-2222-3333-4444-555555555555}''  in LT TFT Rec: Id=0. Current value is ''5''.');
#else
        Observer.Expect('Gd|text', 'Txt must be equal to ''11111111-2222-3333-4444-555555555555''  in LT TFT Rec: Id=0. Current value is ''5''.');
#endif
        Observer.Expect('Gd|code', 'TestField');
        Observer.Expect('Bool_result', 'Yes');
        Observer.Expect('Bool|text', '');
        Observer.Expect('Bool|code', '');
        Observer.Expect('Dt_result', 'No');
        Observer.Expect('Dt|text', 'Txt must be equal to ''03/15/24''  in LT TFT Rec: Id=0. Current value is ''5''.');
        Observer.Expect('Dt|code', 'TestField');
        Observer.Expect('Knd_result', 'No');
        Observer.Expect('Knd|text', 'Txt must be equal to ''Two''  in LT TFT Rec: Id=0. Current value is ''5''.');
        Observer.Expect('Knd|code', 'TestField');
        Observer.Expect('Int_result', 'Yes');
        Observer.Expect('Int|text', '');
        Observer.Expect('Int|code', '');
        Observer.Expect('DtTm_result', 'No');
        Observer.Expect('DtTm|text', 'Txt must be equal to ''03/15/24 12:00 PM''  in LT TFT Rec: Id=0. Current value is ''5''.');
        Observer.Expect('DtTm|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_FldRefMismatch_OnIntegerField()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
        VBool: Boolean;
        VCode: Code[20];
        VTxt: Text;
        VKnd: Enum "LT TFT Kind";
        VDt: Date;
        VGd: Guid;
        VByt: Byte;
        VChr: Char;
    begin
        ClearLastError();
        Rec.DeleteAll();
        Rec.Int := 1;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Int));
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        VBool := true;
        Observer.Observe('Bool_result', Format(TryBool(Fld, VBool)));
        Observer.ObserveError('Bool');
        VCode := '1';
        Observer.Observe('Code_result', Format(TryCode(Fld, VCode)));
        Observer.ObserveError('Code');
        VTxt := '1';
        Observer.Observe('Txt_result', Format(TryTxt(Fld, VTxt)));
        Observer.ObserveError('Txt');
        VKnd := VKnd::One;
        Observer.Observe('Knd_result', Format(TryKnd(Fld, VKnd)));
        Observer.ObserveError('Knd');
        VDt := 20240315D;
        Observer.Observe('Dt_result', Format(TryDt(Fld, VDt)));
        Observer.ObserveError('Dt');
        Evaluate(VGd, '{11111111-2222-3333-4444-555555555555}');
        Observer.Observe('Gd_result', Format(TryGd(Fld, VGd)));
        Observer.ObserveError('Gd');
        VByt := 1;
        Observer.Observe('Byt_result', Format(TryByt(Fld, VByt)));
        Observer.ObserveError('Byt');
        VChr := 1;
        Observer.Observe('Chr_result', Format(TryChr(Fld, VChr)));
        Observer.ObserveError('Chr');
        Observer.Expect('Bool_result', 'Yes');
        Observer.Expect('Bool|text', '');
        Observer.Expect('Bool|code', '');
        Observer.Expect('Code_result', 'Yes');
        Observer.Expect('Code|text', '');
        Observer.Expect('Code|code', '');
        Observer.Expect('Txt_result', 'Yes');
        Observer.Expect('Txt|text', '');
        Observer.Expect('Txt|code', '');
        Observer.Expect('Knd_result', 'Yes');
        Observer.Expect('Knd|text', '');
        Observer.Expect('Knd|code', '');
        Observer.Expect('Dt_result', 'No');
        Observer.Expect('Dt|text', 'Int must be equal to ''03/15/24''  in LT TFT Rec: Id=0. Current value is ''1''.');
        Observer.Expect('Dt|code', 'TestField');
        Observer.Expect('Gd_result', 'No');
#if BC28PLUS
        Observer.Expect('Gd|text', 'Int must be equal to ''{11111111-2222-3333-4444-555555555555}''  in LT TFT Rec: Id=0. Current value is ''1''.');
#else
        Observer.Expect('Gd|text', 'Int must be equal to ''11111111-2222-3333-4444-555555555555''  in LT TFT Rec: Id=0. Current value is ''1''.');
#endif
        Observer.Expect('Gd|code', 'TestField');
        Observer.Expect('Byt_result', 'Yes');
        Observer.Expect('Byt|text', '');
        Observer.Expect('Byt|code', '');
        Observer.Expect('Chr_result', 'Yes');
        Observer.Expect('Chr|text', '');
        Observer.Expect('Chr|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure P189_FldRefMismatch_OnTemporalAndBool()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
        VDtTm: DateTime;
        VDec: Decimal;
        VInt: Integer;
        VTxt: Text;
    begin
        ClearLastError();
        Rec.DeleteAll();
        Rec.Dt := 20240315D;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Dt));
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        VDtTm := CreateDateTime(20240315D, 0T);
        Observer.Observe('DtTm_result', Format(TryDtTm(Fld, VDtTm)));
        Observer.ObserveError('DtTm');
        VDec := 20240315;
        Observer.Observe('Dec_result', Format(TryDec(Fld, VDec)));
        Observer.ObserveError('Dec');
        VInt := 20240315;
        Observer.Observe('Int_result', Format(TryInt(Fld, VInt)));
        Observer.ObserveError('Int');
        VTxt := '20240315D';
        Observer.Observe('Txt_result', Format(TryTxt(Fld, VTxt)));
        Observer.ObserveError('Txt');
        Observer.Expect('DtTm_result', 'Yes');
        Observer.Expect('DtTm|text', '');
        Observer.Expect('DtTm|code', '');
        Observer.Expect('Dec_result', 'No');
#if BC28PLUS
        Observer.Expect('Dec|text', 'Dt must be equal to ''20,240,315''  in LT TFT Rec: Id=0. Current value is ''03/15/24''.');
#else
        Observer.Expect('Dec|text', 'Dt must be equal to ''20240315''  in LT TFT Rec: Id=0. Current value is ''03/15/24''.');
#endif
        Observer.Expect('Dec|code', 'TestField');
        Observer.Expect('Int_result', 'No');
        Observer.Expect('Int|text', 'Dt must be equal to ''20240315''  in LT TFT Rec: Id=0. Current value is ''03/15/24''.');
        Observer.Expect('Int|code', 'TestField');
        Observer.Expect('Txt_result', 'No');
        Observer.Expect('Txt|text', 'Dt must be equal to ''20240315D''  in LT TFT Rec: Id=0. Current value is ''03/15/24''.');
        Observer.Expect('Txt|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_FldRefMismatch_OnDateTimeField()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
        VDt: Date;
        VBig: BigInteger;
        VTxt: Text;
    begin
        ClearLastError();
        Rec.DeleteAll();
        Rec.DtTm := CreateDateTime(20240315D, 0T);
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(DtTm));
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        VDt := 20240315D;
        Observer.Observe('Dt_result', Format(TryDt(Fld, VDt)));
        Observer.ObserveError('Dt');
        VBig := 1;
        Observer.Observe('Big_result', Format(TryBig(Fld, VBig)));
        Observer.ObserveError('Big');
        VTxt := '1';
        Observer.Observe('Txt_result', Format(TryTxt(Fld, VTxt)));
        Observer.ObserveError('Txt');
        Observer.Expect('Dt_result', 'Yes');
        Observer.Expect('Dt|text', '');
        Observer.Expect('Dt|code', '');
        Observer.Expect('Big_result', 'No');
        Observer.Expect('Big|text', 'DtTm must be equal to ''1''  in LT TFT Rec: Id=0. Current value is ''03/15/24 12:00 AM''.');
        Observer.Expect('Big|code', 'TestField');
        Observer.Expect('Txt_result', 'No');
        Observer.Expect('Txt|text', 'DtTm must be equal to ''1''  in LT TFT Rec: Id=0. Current value is ''03/15/24 12:00 AM''.');
        Observer.Expect('Txt|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_FldRefMismatch_OnBooleanField()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
        VInt: Integer;
        VDec: Decimal;
        VTxt: Text;
        VByt: Byte;
    begin
        ClearLastError();
        Rec.DeleteAll();
        Rec.Bool := true;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Bool));
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        VInt := 1;
        Observer.Observe('Int_result', Format(TryInt(Fld, VInt)));
        Observer.ObserveError('Int');
        VDec := 1;
        Observer.Observe('Dec_result', Format(TryDec(Fld, VDec)));
        Observer.ObserveError('Dec');
        VTxt := 'true';
        Observer.Observe('Txt_result', Format(TryTxt(Fld, VTxt)));
        Observer.ObserveError('Txt');
        VByt := 1;
        Observer.Observe('Byt_result', Format(TryByt(Fld, VByt)));
        Observer.ObserveError('Byt');
        Observer.Expect('Int_result', 'Yes');
        Observer.Expect('Int|text', '');
        Observer.Expect('Int|code', '');
        Observer.Expect('Dec_result', 'Yes');
        Observer.Expect('Dec|text', '');
        Observer.Expect('Dec|code', '');
        Observer.Expect('Txt_result', 'No');
        Observer.Expect('Txt|text', 'The input string ''true'' was not in a correct format.');
        Observer.Expect('Txt|code', 'AL:Format');
        Observer.Expect('Byt_result', 'Yes');
        Observer.Expect('Byt|text', '');
        Observer.Expect('Byt|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure P189_FldRefMismatch_OnGuidField()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
        VTxt: Text;
        VCode: Code[20];
        VInt: Integer;
    begin
        ClearLastError();
        Rec.DeleteAll();
        Evaluate(Rec.Gd, '{11111111-2222-3333-4444-555555555555}');
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Gd));
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        VTxt := '{11111111-2222-3333-4444-555555555555}';
        Observer.Observe('Txt_result', Format(TryTxt(Fld, VTxt)));
        Observer.ObserveError('Txt');
        asserterror VCode := '{11111111-2222-3333-4444-555555555555}';
        Observer.ObserveError('af377');
        Observer.Observe('Code_result', Format(TryCode(Fld, VCode)));
        Observer.ObserveError('Code');
        VInt := 1;
        Observer.Observe('Int_result', Format(TryInt(Fld, VInt)));
        Observer.ObserveError('Int');
        Observer.Expect('Txt_result', 'No');
        Observer.Expect('Txt|text', 'Gd must be equal to ''{11111111-2222-3333-4444-555555555555}''  in LT TFT Rec: Id=0. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
        Observer.Expect('Txt|code', 'TestField');
        Observer.Expect('af377|text', 'The length of the string is 38, but it must be less than or equal to 20 characters. Value: {11111111-2222-3333-4444-555555555555}');
        Observer.Expect('af377|code', 'StringLengthExceeded');
        Observer.Expect('Code_result', 'No');
        Observer.Expect('Code|text', 'Gd must be equal to ''''  in LT TFT Rec: Id=0. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
        Observer.Expect('Code|code', 'TestField');
        Observer.Expect('Int_result', 'No');
        Observer.Expect('Int|text', 'Gd must be equal to ''1''  in LT TFT Rec: Id=0. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
        Observer.Expect('Int|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_FldRefMismatch_OnEnumField()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
        VInt: Integer;
        VTxt: Text;
        VDec: Decimal;
        VByt: Byte;
    begin
        ClearLastError();
        Rec.DeleteAll();
        Rec.Knd := Rec.Knd::Two;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Knd));
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        VInt := 2;
        Observer.Observe('Int_result', Format(TryInt(Fld, VInt)));
        Observer.ObserveError('Int');
        VTxt := 'Two';
        Observer.Observe('Txt_result', Format(TryTxt(Fld, VTxt)));
        Observer.ObserveError('Txt');
        VDec := 2;
        Observer.Observe('Dec_result', Format(TryDec(Fld, VDec)));
        Observer.ObserveError('Dec');
        VByt := 2;
        Observer.Observe('Byt_result', Format(TryByt(Fld, VByt)));
        Observer.ObserveError('Byt');
        Observer.Expect('Int_result', 'Yes');
        Observer.Expect('Int|text', '');
        Observer.Expect('Int|code', '');
        Observer.Expect('Txt_result', 'No');
        Observer.Expect('Txt|text', 'Knd must be equal to ''Two''  in LT TFT Rec: Id=0. Current value is ''Two''.');
        Observer.Expect('Txt|code', 'TestField');
        Observer.Expect('Dec_result', 'Yes');
        Observer.Expect('Dec|text', '');
        Observer.Expect('Dec|code', '');
        Observer.Expect('Byt_result', 'Yes');
        Observer.Expect('Byt|text', '');
        Observer.Expect('Byt|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure P189_FldRefMismatch_OnDecimalField()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
        VInt: Integer;
        VBig: BigInteger;
        VByt: Byte;
        VChr: Char;
        VTxt: Text;
    begin
        ClearLastError();
        Rec.DeleteAll();
        Rec.Dec := 5;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Dec));
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        VInt := 5;
        Observer.Observe('Int_result', Format(TryInt(Fld, VInt)));
        Observer.ObserveError('Int');
        VBig := 5;
        Observer.Observe('Big_result', Format(TryBig(Fld, VBig)));
        Observer.ObserveError('Big');
        VByt := 5;
        Observer.Observe('Byt_result', Format(TryByt(Fld, VByt)));
        Observer.ObserveError('Byt');
        VChr := 5;
        Observer.Observe('Chr_result', Format(TryChr(Fld, VChr)));
        Observer.ObserveError('Chr');
        VTxt := '5';
        Observer.Observe('Txt_result', Format(TryTxt(Fld, VTxt)));
        Observer.ObserveError('Txt');
        Observer.Expect('Int_result', 'Yes');
        Observer.Expect('Int|text', '');
        Observer.Expect('Int|code', '');
        Observer.Expect('Big_result', 'Yes');
        Observer.Expect('Big|text', '');
        Observer.Expect('Big|code', '');
        Observer.Expect('Byt_result', 'Yes');
        Observer.Expect('Byt|text', '');
        Observer.Expect('Byt|code', '');
        Observer.Expect('Chr_result', 'Yes');
        Observer.Expect('Chr|text', '');
        Observer.Expect('Chr|code', '');
        Observer.Expect('Txt_result', 'Yes');
        Observer.Expect('Txt|text', '');
        Observer.Expect('Txt|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure P189_FldRefMismatch_OnBigIntegerField()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
        VInt: Integer;
        VDec: Decimal;
        VByt: Byte;
        VTxt: Text;
    begin
        ClearLastError();
        Rec.DeleteAll();
        Rec.Big := 5;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Big));
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        VInt := 5;
        Observer.Observe('Int_result', Format(TryInt(Fld, VInt)));
        Observer.ObserveError('Int');
        VDec := 5;
        Observer.Observe('Dec_result', Format(TryDec(Fld, VDec)));
        Observer.ObserveError('Dec');
        VByt := 5;
        Observer.Observe('Byt_result', Format(TryByt(Fld, VByt)));
        Observer.ObserveError('Byt');
        VTxt := '5';
        Observer.Observe('Txt_result', Format(TryTxt(Fld, VTxt)));
        Observer.ObserveError('Txt');
        Observer.Expect('Int_result', 'Yes');
        Observer.Expect('Int|text', '');
        Observer.Expect('Int|code', '');
        Observer.Expect('Dec_result', 'Yes');
        Observer.Expect('Dec|text', '');
        Observer.Expect('Dec|code', '');
        Observer.Expect('Byt_result', 'Yes');
        Observer.Expect('Byt|text', '');
        Observer.Expect('Byt|code', '');
        Observer.Expect('Txt_result', 'Yes');
        Observer.Expect('Txt|text', '');
        Observer.Expect('Txt|code', '');
        Observer.Verify();
    end;
}
