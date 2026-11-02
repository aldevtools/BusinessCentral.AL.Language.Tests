// Probe: comparing two FieldRef values of a Blob field (and of Media / MediaSet fields) with <>, = and <.
// Shapes: a record copied into a variable and compared field by field through RecordRef.FieldIndex(..).Value (a "has the record changed"
// loop), a temporary copy compared with the stored row, rows with the same, other and no content, with and without CalcFields.
// Gap cycle 5, spec G5-07 (writer Y49). Object ids: table 92940, codeunit 92940.
// Fixtures used: Probe Observer (codeunit 69160).
// Does not compile (so not run here): two Variants compared (tests/must-not-compile/cases/0502-variant-comparison-operators.al), '<' and '>'
// between two FieldRef values (case 2556), Blob fields of two Record variables compared directly (case 2555).

table 92940 "LT Y49 Blob Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Bin; Blob) { }
        field(3; Txt; Text[20]) { }
        field(4; Pic; Media) { }
        field(5; Pics; MediaSet) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 92940 "LT Y49 Blob Compare"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT Y49 Blob Row";
    begin
        Row.DeleteAll();
        AddRow(1, 'abc');
        AddRow(2, 'abc');
        AddRow(3, 'xyz');
        AddRow(4, '');
    end;

    local procedure AddRow(Id: Integer; Content: Text)
    var
        Row: Record "LT Y49 Blob Row";
        OutS: OutStream;
    begin
        Row.Init();
        Row.Id := Id;
        Row.Txt := 'T' + Format(Id);
        if Content <> '' then begin
            Row.Bin.CreateOutStream(OutS);
            OutS.WriteText(Content);
        end;
        Row.Insert();
    end;

    local procedure WriteBin(var Row: Record "LT Y49 Blob Row"; Content: Text)
    var
        OutS: OutStream;
    begin
        Row.Bin.CreateOutStream(OutS);
        OutS.WriteText(Content);
    end;

    // Observes '<>|=' of the two FieldRef values, or the error when the comparison raises.
    local procedure ObsCmp(Name: Text; var A: Record "LT Y49 Blob Row"; var B: Record "LT Y49 Blob Row"; FieldNo: Integer)
    var
        Res: Text;
    begin
        ClearLastError();
        if TryCmp(A, B, FieldNo, Res) then
            Observer.Observe(Name, Res)
        else begin
            Observer.Observe(Name, 'raised');
            Observer.ObserveError(Name);
        end;
    end;

    [TryFunction]
    local procedure TryCmp(var A: Record "LT Y49 Blob Row"; var B: Record "LT Y49 Blob Row"; FieldNo: Integer; var Res: Text)
    var
        RA: RecordRef;
        RB: RecordRef;
    begin
        RA.GetTable(A);
        RB.GetTable(B);
        Res := Format(RA.Field(FieldNo).Value <> RB.Field(FieldNo).Value) + '|' + Format(RA.Field(FieldNo).Value = RB.Field(FieldNo).Value);
    end;

    // The loop over every field by index, as a "has the record changed" check does.
    local procedure ObsHasDiff(Name: Text; var A: Record "LT Y49 Blob Row"; var B: Record "LT Y49 Blob Row")
    var
        Res: Text;
    begin
        ClearLastError();
        if TryHasDiff(A, B, Res) then
            Observer.Observe(Name, Res)
        else begin
            Observer.Observe(Name, 'raised');
            Observer.ObserveError(Name);
        end;
    end;

    [TryFunction]
    local procedure TryHasDiff(var A: Record "LT Y49 Blob Row"; var B: Record "LT Y49 Blob Row"; var Res: Text)
    var
        RA: RecordRef;
        RB: RecordRef;
        Index: Integer;
    begin
        RA.GetTable(A);
        RB.GetTable(B);
        Res := '';
        for Index := 1 to RA.FieldCount do
            if RA.FieldIndex(Index).Value <> RB.FieldIndex(Index).Value then
                Res += Format(RA.FieldIndex(Index).Number) + ';';
    end;

    [Test]
    procedure BlobCmp_FieldRef_CopyInVariable()
    var
        Rec: Record "LT Y49 Blob Row";
        X: Record "LT Y49 Blob Row";
    begin
        Seed();
        Rec.Get(1);
        X := Rec;
        ObsCmp('copy', Rec, X, 2);
        ObsHasDiff('copy loop', Rec, X);
        Rec.CalcFields(Bin);
        ObsCmp('copy calc rec only', Rec, X, 2);
        X.CalcFields(Bin);
        ObsCmp('copy calc both', Rec, X, 2);
        WriteBin(Rec, 'new');
        ObsCmp('copy rec written', Rec, X, 2);
        ObsHasDiff('copy rec written loop', Rec, X);
        Rec.Get(1);
        X := Rec;
        WriteBin(Rec, 'abc');
        ObsCmp('copy rec written same text', Rec, X, 2);
        Observer.Expect('copy', 'No|Yes');
        Observer.Expect('copy loop', '');
        Observer.Expect('copy calc rec only', 'Yes|No');
        Observer.Expect('copy calc both', 'No|Yes');
        Observer.Expect('copy rec written', 'Yes|No');
        Observer.Expect('copy rec written loop', '2;');
        Observer.Expect('copy rec written same text', 'Yes|No');
        Observer.Verify();
    end;

    [Test]
    procedure BlobCmp_FieldRef_TempAgainstStored()
    var
        Stored: Record "LT Y49 Blob Row";
        Temp: Record "LT Y49 Blob Row" temporary;
    begin
        Seed();
        Stored.Get(1);
        Stored.CalcFields(Bin);
        Temp := Stored;
        Temp.Insert();
        Clear(Stored);
        Stored.Get(1);
        ObsCmp('temp vs stored', Temp, Stored, 2);
        ObsHasDiff('temp vs stored loop', Temp, Stored);
        Temp.Get(1);
        ObsCmp('temp got vs stored', Temp, Stored, 2);
        Temp.CalcFields(Bin);
        ObsCmp('temp calc only', Temp, Stored, 2);
        Stored.CalcFields(Bin);
        ObsCmp('both calc', Temp, Stored, 2);
        Clear(Temp);
        Temp.Reset();
        Temp.DeleteAll();
        Stored.Get(1);
        Temp.TransferFields(Stored);
        Temp.Insert();
        ObsCmp('transfer vs stored', Temp, Stored, 2);
        Observer.Expect('temp vs stored', 'No|Yes');
        Observer.Expect('temp vs stored loop', '');
        Observer.Expect('temp got vs stored', 'No|Yes');
        Observer.Expect('temp calc only', 'Yes|No');
        Observer.Expect('both calc', 'No|Yes');
        Observer.Expect('transfer vs stored', 'Yes|No');
        Observer.Verify();
    end;

    [Test]
    procedure BlobCmp_FieldRef_DifferentRows()
    var
        A: Record "LT Y49 Blob Row";
        B: Record "LT Y49 Blob Row";
    begin
        Seed();
        A.Get(1);
        B.Get(3);
        ObsCmp('1-3', A, B, 2);
        B.Get(2);
        ObsCmp('1-2', A, B, 2);
        B.Get(4);
        ObsCmp('1-4', A, B, 2);
        A.Get(4);
        ObsCmp('4-4', A, B, 2);
        A.Get(1);
        A.CalcFields(Bin);
        B.Get(3);
        B.CalcFields(Bin);
        ObsCmp('1-3 calc', A, B, 2);
        B.Get(2);
        B.CalcFields(Bin);
        ObsCmp('1-2 calc', A, B, 2);
        B.Get(4);
        B.CalcFields(Bin);
        ObsCmp('1-4 calc', A, B, 2);
        A.Get(4);
        A.CalcFields(Bin);
        ObsCmp('4-4 calc', A, B, 2);
        A.Get(1);
        A.CalcFields(Bin);
        B.Get(3);
        ObsCmp('1 calc-3', A, B, 2);
        Observer.Expect('1-3', 'No|Yes');
        Observer.Expect('1-2', 'No|Yes');
        Observer.Expect('1-4', 'Yes|No');
        Observer.Expect('4-4', 'No|Yes');
        Observer.Expect('1-3 calc', 'Yes|No');
        Observer.Expect('1-2 calc', 'No|Yes');
        Observer.Expect('1-4 calc', 'Yes|No');
        Observer.Expect('4-4 calc', 'No|Yes');
        Observer.Expect('1 calc-3', 'Yes|No');
        Observer.Verify();
    end;

    [Test]
    procedure BlobCmp_FieldRef_BothEmpty()
    var
        A: Record "LT Y49 Blob Row";
        B: Record "LT Y49 Blob Row";
    begin
        A.Init();
        B.Init();
        ObsCmp('init', A, B, 2);
        WriteBin(A, 'abc');
        ObsCmp('init a written', A, B, 2);
        WriteBin(B, 'abc');
        ObsCmp('init both written same', A, B, 2);
        WriteBin(B, 'xyz');
        ObsCmp('init both written other', A, B, 2);
        Observer.Expect('init', 'No|Yes');
        Observer.Expect('init a written', 'Yes|No');
        Observer.Expect('init both written same', 'No|Yes');
        Observer.Expect('init both written other', 'Yes|No');
        Observer.Verify();
    end;

    [Test]
    procedure MediaCmp_FieldRef()
    var
        A: Record "LT Y49 Blob Row";
        B: Record "LT Y49 Blob Row";
    begin
        A.Init();
        B.Init();
        ObsCmp('media init', A, B, 4);
        ObsCmp('mediaset init', A, B, 5);
        ObsCmp('text init', A, B, 3);
        Seed();
        A.Get(1);
        B.Get(3);
        ObsCmp('media 1-3', A, B, 4);
        ObsCmp('mediaset 1-3', A, B, 5);
        ObsCmp('text 1-3', A, B, 3);
        ObsHasDiff('loop 1-3', A, B);
        B.Get(1);
        ObsHasDiff('loop 1-1', A, B);
        Observer.Expect('media init', 'No|Yes');
        Observer.Expect('mediaset init', 'No|Yes');
        Observer.Expect('text init', 'No|Yes');
        Observer.Expect('media 1-3', 'No|Yes');
        Observer.Expect('mediaset 1-3', 'No|Yes');
        Observer.Expect('text 1-3', 'Yes|No');
        Observer.Expect('loop 1-3', '1;3;');
        Observer.Expect('loop 1-1', '');
        Observer.Verify();
    end;
}
