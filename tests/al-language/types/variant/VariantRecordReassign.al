// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 74882 and 74883, codeunit 74883
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: a Variant that holds a record of table A is assigned a record of table B (and of table A again, a temporary record, a RecordRef): the table number the Variant
//   reports through RecordRef.GetTable, the field values, IsRecord, and reading the Variant back into a record variable of table A and of table B (error text and code).
// BC versions: all (CI)

table 74882 "LT VRR Alpha"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; AlphaText; Text[20]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 74883 "LT VRR Beta"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; BetaText; Text[20]) { }
        field(3; BetaNumber; Integer) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 74883 "LT VRR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(var Observer: Codeunit "Probe Observer"; Tag: Text; V: Variant)
    var
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
        Fields: Text;
    begin
        Observer.Observe(Tag + '.isRecord', Format(V.IsRecord()));
        if not V.IsRecord() then
            exit;
        RR.GetTable(V);
        Observer.Observe(Tag + '.table', Format(RR.Number()) + ' ' + RR.Name());
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            Fields += FR.Name() + '=' + Format(FR.Value()) + ';';
        end;
        Observer.Observe(Tag + '.values', Fields);
    end;

    [TryFunction]
    local procedure TryReadAlpha(V: Variant; var A: Record "LT VRR Alpha")
    begin
        A := V;
    end;

    [TryFunction]
    local procedure TryReadBeta(V: Variant; var B: Record "LT VRR Beta")
    begin
        B := V;
    end;

    [Test]
    procedure Variant_RecordOfOtherTable_Replaces()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT VRR Alpha";
        B: Record "LT VRR Beta";
        V: Variant;
    begin
        A.Id := 7;
        A.AlphaText := 'alpha';
        B.Code := 'BCODE';
        B.BetaText := 'beta';
        B.BetaNumber := 3;
        V := A;
        Describe(Observer, 'first', V);
        V := B;
        Describe(Observer, 'second', V);
        V := A;
        Describe(Observer, 'third', V);
        Observer.Expect('first.isRecord', 'Yes');
        Observer.Expect('first.table', '74882 LT VRR Alpha');
        Observer.Expect('first.values', 'Id=7;AlphaText=alpha;');
        Observer.Expect('second.isRecord', 'Yes');
        Observer.Expect('second.table', '74883 LT VRR Beta');
        Observer.Expect('second.values', 'Code=BCODE;BetaText=beta;BetaNumber=3;');
        Observer.Expect('third.isRecord', 'Yes');
        Observer.Expect('third.table', '74882 LT VRR Alpha');
        Observer.Expect('third.values', 'Id=7;AlphaText=alpha;');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_SameTable_NewValues()
    var
        Observer: Codeunit "Probe Observer";
        A1: Record "LT VRR Alpha";
        A2: Record "LT VRR Alpha";
        V: Variant;
    begin
        A1.Id := 1;
        A1.AlphaText := 'one';
        A2.Id := 2;
        A2.AlphaText := 'two';
        V := A1;
        V := A2;
        Describe(Observer, 'same', V);
        A1.AlphaText := 'changedAfterAssign';
        Describe(Observer, 'copyNotShared', V);
        Observer.Expect('same.isRecord', 'Yes');
        Observer.Expect('same.table', '74882 LT VRR Alpha');
        Observer.Expect('same.values', 'Id=2;AlphaText=two;');
        Observer.Expect('copyNotShared.isRecord', 'Yes');
        Observer.Expect('copyNotShared.table', '74882 LT VRR Alpha');
        Observer.Expect('copyNotShared.values', 'Id=2;AlphaText=two;');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_Reassign_ReadBack()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT VRR Alpha";
        B: Record "LT VRR Beta";
        A2: Record "LT VRR Alpha";
        B2: Record "LT VRR Beta";
        V: Variant;
        Ok: Boolean;
    begin
        A.Id := 7;
        A.AlphaText := 'alpha';
        B.Code := 'BCODE';
        B.BetaText := 'beta';
        V := A;
        V := B;
        Ok := TryReadAlpha(V, A2);
        Observer.Observe('readAlpha', Format(Ok) + ' ' + Format(A2.Id));
        if not Ok then
            Observer.ObserveError('readAlphaErr');
        Ok := TryReadBeta(V, B2);
        Observer.Observe('readBeta', Format(Ok) + ' ' + B2.Code + ' ' + B2.BetaText);
        if not Ok then
            Observer.ObserveError('readBetaErr');
        Observer.Expect('readAlpha', 'No 0');
        Observer.Expect('readAlphaErr|text', 'The requested operation is not supported.');
        Observer.Expect('readAlphaErr|code', 'NotSupportedOperation');
        Observer.Expect('readBeta', 'Yes BCODE beta');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_Temporary_ThenPersistent()
    var
        Observer: Codeunit "Probe Observer";
        TempA: Record "LT VRR Alpha" temporary;
        B: Record "LT VRR Beta";
        RR: RecordRef;
        V: Variant;
    begin
        TempA.Id := 9;
        TempA.AlphaText := 'temp';
        V := TempA;
        RR.GetTable(V);
        Observer.Observe('tempIsTemporary', Format(RR.IsTemporary()));
        B.Code := 'P';
        V := B;
        RR.GetTable(V);
        Observer.Observe('afterBetaIsTemporary', Format(RR.IsTemporary()));
        Observer.Observe('afterBetaNumber', Format(RR.Number()));
        Observer.Expect('tempIsTemporary', 'Yes');
        Observer.Expect('afterBetaIsTemporary', 'No');
        Observer.Expect('afterBetaNumber', '74883');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_RecordRef_ThenRecord()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT VRR Alpha";
        B: Record "LT VRR Beta";
        RR: RecordRef;
        V: Variant;
    begin
        A.Id := 3;
        A.AlphaText := 'three';
        B.Code := 'BB';
        RR.GetTable(B);
        V := A;
        Describe(Observer, 'record', V);
        V := RR;
        Observer.Observe('recordRefIsRecord', Format(V.IsRecord()));
        Observer.Observe('recordRefIsRecordRef', Format(V.IsRecordRef()));
        V := A;
        Observer.Observe('backToRecordIsRecordRef', Format(V.IsRecordRef()));
        Observer.Observe('backToRecordIsRecord', Format(V.IsRecord()));
        Observer.Expect('record.isRecord', 'Yes');
        Observer.Expect('record.table', '74882 LT VRR Alpha');
        Observer.Expect('record.values', 'Id=3;AlphaText=three;');
        Observer.Expect('recordRefIsRecord', 'No');
        Observer.Expect('recordRefIsRecordRef', 'Yes');
        Observer.Expect('backToRecordIsRecordRef', 'No');
        Observer.Expect('backToRecordIsRecord', 'Yes');
        Observer.Verify();
    end;
}
