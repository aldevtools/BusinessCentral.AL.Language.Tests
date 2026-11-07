// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-transferfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables 95830-95833 of cross-app fixture A and their extensions 95834-95836 (fixture B),
//   95837 (fixture C) and 95838 (fixture D): tests/al-language-xapp-a|b|c|d/Tfx*.al.
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TransferFields between two tables of one app (fixture A) whose fields of one number come from different apps: an extension
//   field of fixture B against an extension field of fixture D (no dependency either way) or of fixture C (depends on B), and against a
//   field of the target table itself (fixture A). Types: Boolean into Code[20], Code[20] into Boolean, Integer into Integer, Text[30]
//   into Code[20]. Mode 1 = TransferFields(Src), 2 = TransferFields(Src, false), 3 = TransferFields(Src, true, true); also the reverse
//   direction. Contrast: two fields of one app (fixture B) with field number 95830 as Boolean and Code[20] on two tables of fixture A.
//   Each case: whether it raises (text and code) and every target field as Format(value, 0, 9) (the target fields start with marker values).
//   Asked by al-runner issue 6982 (Contact.TransferFields(Customer) in Base Application's CustCont-Update, with a Boolean of one app and a
//   Code[20] of another app under the same field number).
// BC versions: 27, 28, 29 by CI

codeunit 95811 "REC TFX Field Apps Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SourceRef(var SrcRef: RecordRef; LongText: Boolean)
    begin
        SrcRef.Open(Database::"REC TFX Source");
        SrcRef.Init();
        SrcRef.Field(1).Value := 'S1';
        SrcRef.Field(95830).Value := true;
        SrcRef.Field(95831).Value := true;
        SrcRef.Field(95832).Value := 7;
        SrcRef.Field(95833).Value := 'SRCCODE';
        if LongText then
            SrcRef.Field(95834).Value := 'source text longer than twenty'
        else
            SrcRef.Field(95834).Value := 'src text';
        SrcRef.Field(95835).Value := true;
    end;

    local procedure TargetRef(var TgtRef: RecordRef)
    begin
        TgtRef.Open(Database::"REC TFX Target");
        TgtRef.Init();
        TgtRef.Field(1).Value := 'T1';
        TgtRef.Field(95830).Value := 'KEEPD';
        TgtRef.Field(95831).Value := 'KEEPC';
        TgtRef.Field(95832).Value := 5;
        TgtRef.Field(95833).Value := false;
        TgtRef.Field(95834).Value := 'KEEPD2';
        TgtRef.Field(95835).Value := 'KEEPA';
    end;

    local procedure Dump(RecVariant: Variant): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        i: Integer;
        No: Integer;
        Result: Text;
    begin
        // Fields by number (1, then 95830 to 95835), not by index: the order of the extension fields is not under test.
        RecRef.GetTable(RecVariant);
        for i := 95829 to 95835 do begin
            No := i;
            if i = 95829 then
                No := 1;
            if RecRef.FieldExist(No) then begin
                FldRef := RecRef.Field(No);
                Result += Format(No) + '=' + Format(FldRef.Value(), 0, 9) + ';';
            end;
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryForward(var Tgt: Record "REC TFX Target"; var Src: Record "REC TFX Source"; Mode: Integer)
    begin
        case Mode of
            1:
                Tgt.TransferFields(Src);
            2:
                Tgt.TransferFields(Src, false);
            3:
                Tgt.TransferFields(Src, true, true);
        end;
    end;

    [TryFunction]
    local procedure TryBackward(var Src: Record "REC TFX Source"; var Tgt: Record "REC TFX Target"; Mode: Integer)
    begin
        case Mode of
            1:
                Src.TransferFields(Tgt);
            2:
                Src.TransferFields(Tgt, false);
            3:
                Src.TransferFields(Tgt, true, true);
        end;
    end;

    local procedure Forward(Mode: Integer; LongText: Boolean): Text
    var
        Src: Record "REC TFX Source";
        Tgt: Record "REC TFX Target";
        SrcRef: RecordRef;
        TgtRef: RecordRef;
    begin
        SourceRef(SrcRef, LongText);
        SrcRef.SetTable(Src);
        TargetRef(TgtRef);
        TgtRef.SetTable(Tgt);
        ClearLastError();
        if TryForward(Tgt, Src, Mode) then
            exit('ok: ' + Dump(Tgt));
        exit('error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode() + ' | ' + Dump(Tgt));
    end;

    local procedure Backward(Mode: Integer): Text
    var
        Src: Record "REC TFX Source";
        Tgt: Record "REC TFX Target";
        SrcRef: RecordRef;
        TgtRef: RecordRef;
    begin
        SourceRef(SrcRef, false);
        SrcRef.SetTable(Src);
        TargetRef(TgtRef);
        TgtRef.SetTable(Tgt);
        ClearLastError();
        if TryBackward(Src, Tgt, Mode) then
            exit('ok: ' + Dump(Src));
        exit('error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode() + ' | ' + Dump(Src));
    end;

    [Test]
    procedure TransferFields_FieldsOfOtherApps_Forward()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('target before', Forward(0, false));
        Observer.Observe('mode 1', Forward(1, false));
        Observer.Observe('mode 2', Forward(2, false));
        Observer.Observe('mode 3', Forward(3, false));
        Observer.Observe('mode 1 long text', Forward(1, true));
        Observer.Observe('mode 3 long text', Forward(3, true));
        Observer.Expect('target before', 'ok: 1=T1;95830=KEEPD;95831=KEEPC;95832=5;95833=false;95834=KEEPD2;95835=KEEPA;');
        Observer.Expect('mode 1', 'ok: 1=S1;95830=KEEPD;95831=KEEPC;95832=7;95833=false;95834=SRC TEXT;95835=KEEPA;');
        Observer.Expect('mode 2', 'ok: 1=T1;95830=KEEPD;95831=KEEPC;95832=7;95833=false;95834=SRC TEXT;95835=KEEPA;');
        Observer.Expect('mode 3', 'ok: 1=S1;95830=KEEPD;95831=KEEPC;95832=7;95833=false;95834=SRC TEXT;95835=KEEPA;');
        Observer.Expect('mode 1 long text', 'ok: 1=S1;95830=KEEPD;95831=KEEPC;95832=7;95833=false;95834=KEEPD2;95835=KEEPA;');
        Observer.Expect('mode 3 long text', 'ok: 1=S1;95830=KEEPD;95831=KEEPC;95832=7;95833=false;95834=KEEPD2;95835=KEEPA;');
        Observer.Verify();
    end;

    [Test]
    procedure TransferFields_FieldsOfOtherApps_Backward()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('mode 1', Backward(1));
        Observer.Observe('mode 2', Backward(2));
        Observer.Observe('mode 3', Backward(3));
        Observer.Expect('mode 1', 'ok: 1=T1;95830=true;95831=true;95832=5;95833=SRCCODE;95834=KEEPD2;95835=true;');
        Observer.Expect('mode 2', 'ok: 1=S1;95830=true;95831=true;95832=5;95833=SRCCODE;95834=KEEPD2;95835=true;');
        Observer.Expect('mode 3', 'ok: 1=T1;95830=true;95831=true;95832=5;95833=SRCCODE;95834=KEEPD2;95835=true;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySameApp(var Tgt: Record "REC TFX Target 2"; var Src: Record "REC TFX Source 2"; Mode: Integer)
    begin
        case Mode of
            1:
                Tgt.TransferFields(Src);
            2:
                Tgt.TransferFields(Src, false);
            3:
                Tgt.TransferFields(Src, true, true);
        end;
    end;

    local procedure SameApp(Mode: Integer): Text
    var
        Src: Record "REC TFX Source 2";
        Tgt: Record "REC TFX Target 2";
    begin
        Src.Init();
        Src."No." := 'S2';
        Src."XB Same Flag" := true;
        Tgt.Init();
        Tgt."No." := 'T2';
        Tgt."XB Same Code" := 'KEEPB';
        ClearLastError();
        if TrySameApp(Tgt, Src, Mode) then
            exit('ok: ' + Dump(Tgt));
        exit('error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode() + ' | ' + Dump(Tgt));
    end;

    [Test]
    procedure TransferFields_TwoFieldsOfOneExtensionApp()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('mode 1', SameApp(1));
        Observer.Observe('mode 2', SameApp(2));
        Observer.Observe('mode 3', SameApp(3));
        Observer.Expect('mode 1', 'error: The following fields must have the same type:\\Field: XB Same Code <-- XB Same Flag\Table: REC TFX Target 2 <-- REC TFX Source 2\Type: Code <-- Boolean | DB:TypeMisMatch | 1=S2;95830=KEEPB;');
        Observer.Expect('mode 2', 'error: The following fields must have the same type:\\Field: XB Same Code <-- XB Same Flag\Table: REC TFX Target 2 <-- REC TFX Source 2\Type: Code <-- Boolean | DB:TypeMisMatch | 1=T2;95830=KEEPB;');
        Observer.Expect('mode 3', 'ok: 1=S2;95830=KEEPB;');
        Observer.Verify();
    end;
}
