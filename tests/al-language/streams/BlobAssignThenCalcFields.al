// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 97730, helper codeunit 97731; test codeunits 97732, 97733
// Probe: written against real BC (al-runner issue 7961).
// Facts: whether a Blob field filled by `Row.Content := Source.Content` counts as an unsaved write, so that a later
//   Row.CalcFields(Content) with no Modify in between keeps the assigned value, or loads the stored one.
//   FACTS-PLACEHOLDER
// BC versions: 27.5+

table 97730 "LT BACF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Key1; Integer) { DataClassification = SystemMetadata; }
        field(2; Content; Blob) { DataClassification = SystemMetadata; }
        field(3; Info; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Key1) { Clustered = true; }
    }
}

codeunit 97731 "LT BACF Lib"
{
    procedure HasValueText(HV: Boolean): Text
    begin
        if HV then
            exit('hv:');
        exit('nohv:');
    end;

    procedure W(var R: Record "LT BACF Row"; T: Text)
    var
        OS: OutStream;
    begin
        R.Content.CreateOutStream(OS);
        OS.WriteText(T);
    end;

    // HasValue of the Blob in hand, then the text read from it.
    procedure Rd(var R: Record "LT BACF Row"): Text
    var
        IS: InStream;
        T: Text;
        HV: Boolean;
    begin
        HV := R.Content.HasValue();
        R.Content.CreateInStream(IS);
        IS.ReadText(T);
        exit(HasValueText(HV) + T);
    end;

    // The stored row read through a fresh record: HasValue before CalcFields, a space, then the Blob after CalcFields.
    procedure Stored(K: Integer): Text
    var
        R: Record "LT BACF Row";
        HV: Boolean;
    begin
        if not R.Get(K) then
            exit('<no row>');
        HV := R.Content.HasValue();
        R.CalcFields(Content);
        exit(HasValueText(HV) + ' ' + Rd(R) + ' info=' + R.Info);
    end;

    // Re-Get on the same variable (also works for a temporary record): HasValue before CalcFields, then after.
    procedure ReGet(var R: Record "LT BACF Row"; K: Integer): Text
    var
        HV: Boolean;
    begin
        if not R.Get(K) then
            exit('<no row>');
        HV := R.Content.HasValue();
        R.CalcFields(Content);
        exit(HasValueText(HV) + ' ' + Rd(R));
    end;

    procedure Reset()
    var
        R: Record "LT BACF Row";
    begin
        R.DeleteAll();
    end;

    // Puts the target Row (key 1) into state S:
    // 1 ins     inserted with an empty Blob
    // 2 old     stored with 'old', read again with Get only
    // 3 oldcalc stored with 'old', read again with Get and CalcFields
    // 4 dirty   inserted with an empty Blob, then 'dirty' written through an OutStream, not saved
    // 5 noins   Init only, not inserted
    // 6 temp    temporary record, inserted with an empty Blob (the caller passes a temporary record)
    procedure PrepareTarget(var Row: Record "LT BACF Row"; S: Integer)
    var
        Other: Record "LT BACF Row";
    begin
        case S of
            1, 6:
                begin
                    Row.Init();
                    Row.Key1 := 1;
                    Row.Insert();
                end;
            2, 3:
                begin
                    Other.Init();
                    Other.Key1 := 1;
                    W(Other, 'old');
                    Other.Insert();
                    Row.Get(1);
                    if S = 3 then
                        Row.CalcFields(Content);
                end;
            4:
                begin
                    Row.Init();
                    Row.Key1 := 1;
                    Row.Insert();
                    W(Row, 'dirty');
                end;
            5:
                begin
                    Row.Init();
                    Row.Key1 := 1;
                end;
        end;
    end;

    // Assigns Row.Content := Source.Content, with the source (key 2) in state S:
    // 1 tins  temporary record, 'hello' written, then Insert
    // 2 tmem  temporary record, 'hello' written, not inserted
    // 3 calc  stored with 'hello', read again with Get and CalcFields
    // 4 get   stored with 'hello', read again with Get only (Blob not loaded)
    // 5 mem   record of the stored table, 'hello' written, not inserted
    // 6 empty record of the stored table, Init only
    procedure AssignFrom(var Row: Record "LT BACF Row"; S: Integer)
    var
        TmpSrc: Record "LT BACF Row" temporary;
        Src: Record "LT BACF Row";
        Src2: Record "LT BACF Row";
    begin
        case S of
            1, 2:
                begin
                    TmpSrc.Init();
                    TmpSrc.Key1 := 2;
                    W(TmpSrc, 'hello');
                    if S = 1 then
                        TmpSrc.Insert();
                    Row.Content := TmpSrc.Content;
                end;
            3, 4:
                begin
                    Src.Init();
                    Src.Key1 := 2;
                    W(Src, 'hello');
                    Src.Insert();
                    Src2.Get(2);
                    if S = 3 then
                        Src2.CalcFields(Content);
                    Row.Content := Src2.Content;
                end;
            5:
                begin
                    Src.Init();
                    Src.Key1 := 2;
                    W(Src, 'hello');
                    Row.Content := Src.Content;
                end;
            6:
                begin
                    Src.Init();
                    Src.Key1 := 2;
                    Row.Content := Src.Content;
                end;
        end;
    end;

    procedure TempSource(var TmpSrc: Record "LT BACF Row" temporary)
    begin
        TmpSrc.Init();
        TmpSrc.Key1 := 2;
        W(TmpSrc, 'hello');
        TmpSrc.Insert();
    end;
}

codeunit 97732 "LT BACF Matrix"
{
    // Target state x source state. Per cell: 'before' = HasValue right after the assignment (no CalcFields),
    // 'after' = HasValue and text after Row.CalcFields(Content), then Modify (Insert for noins) and
    // 'reget' (same variable Get again: HasValue, then text after CalcFields) and 'row' (fresh record).
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT BACF Lib";

    local procedure Cell(var Observer: Codeunit "Probe Observer"; var Row: Record "LT BACF Row"; TS: Integer; SS: Integer)
    begin
        L.Reset();
        L.PrepareTarget(Row, TS);
        L.AssignFrom(Row, SS);
        Observer.Observe('before', L.HasValueText(Row.Content.HasValue()));
        Row.CalcFields(Content);
        Observer.Observe('after', L.Rd(Row));
        if TS = 5 then
            Row.Insert()
        else
            Row.Modify();
        Observer.Observe('after save', L.Rd(Row));
        Observer.Observe('reget', L.ReGet(Row, 1));
        if TS <> 6 then
            Observer.Observe('row', L.Stored(1));
    end;

    [Test]
    procedure Assign_Ins_FromTmpIns()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 1, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Ins_FromTmpMem()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 1, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Ins_FromCalc()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 1, 3);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Ins_FromGet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 1, 4);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Ins_FromMem()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 1, 5);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Ins_FromEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 1, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Old_FromTmpIns()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 2, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Old_FromTmpMem()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 2, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Old_FromCalc()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 2, 3);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Old_FromGet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 2, 4);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Old_FromMem()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 2, 5);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Old_FromEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 2, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_OldCalc_FromTmpIns()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 3, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_OldCalc_FromTmpMem()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 3, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_OldCalc_FromCalc()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 3, 3);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_OldCalc_FromGet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 3, 4);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_OldCalc_FromMem()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 3, 5);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_OldCalc_FromEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 3, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Dirty_FromTmpIns()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 4, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Dirty_FromTmpMem()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 4, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Dirty_FromCalc()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 4, 3);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Dirty_FromGet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 4, 4);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Dirty_FromMem()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 4, 5);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Dirty_FromEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 4, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_NotIns_FromTmpIns()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 5, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_NotIns_FromTmpMem()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 5, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_NotIns_FromCalc()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 5, 3);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_NotIns_FromGet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 5, 4);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_NotIns_FromMem()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 5, 5);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_NotIns_FromEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        Cell(Observer, Row, 5, 6);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Temp_FromTmpIns()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row" temporary;
    begin
        Cell(Observer, Row, 6, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Temp_FromTmpMem()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row" temporary;
    begin
        Cell(Observer, Row, 6, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Temp_FromCalc()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row" temporary;
    begin
        Cell(Observer, Row, 6, 3);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Temp_FromGet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row" temporary;
    begin
        Cell(Observer, Row, 6, 4);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Temp_FromMem()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row" temporary;
    begin
        Cell(Observer, Row, 6, 5);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_Temp_FromEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row" temporary;
    begin
        Cell(Observer, Row, 6, 6);
        Observer.Finish();
    end;
}

codeunit 97733 "LT BACF Neighbors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT BACF Lib";

    [Test]
    procedure Control_OutStreamWrite_ThenCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        L.Reset();
        L.PrepareTarget(Row, 1);
        L.W(Row, 'hello');
        Observer.Observe('before', L.HasValueText(Row.Content.HasValue()));
        Row.CalcFields(Content);
        Observer.Observe('after', L.Rd(Row));
        Row.Modify();
        Observer.Observe('row', L.Stored(1));
        Observer.Finish();
    end;

    [Test]
    procedure Assign_CalcFieldsTwice()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        L.Reset();
        L.PrepareTarget(Row, 1);
        L.AssignFrom(Row, 1);
        Row.CalcFields(Content);
        Observer.Observe('after 1', L.Rd(Row));
        Row.CalcFields(Content);
        Observer.Observe('after 2', L.Rd(Row));
        Row.Modify();
        Observer.Observe('row', L.Stored(1));
        Observer.Finish();
    end;

    [Test]
    procedure Assign_CalcFieldsTwice_NoReadBetween()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        L.Reset();
        L.PrepareTarget(Row, 1);
        L.AssignFrom(Row, 1);
        Row.CalcFields(Content);
        Row.CalcFields(Content);
        Observer.Observe('after 2', L.Rd(Row));
        Observer.Finish();
    end;

    [Test]
    procedure Assign_NoCalcFields_Modify()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        L.Reset();
        L.PrepareTarget(Row, 1);
        L.AssignFrom(Row, 1);
        Observer.Observe('in hand', L.Rd(Row));
        Row.Modify();
        Observer.Observe('row', L.Stored(1));
        Observer.Finish();
    end;

    [Test]
    procedure Assign_ReadInStream_ThenCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        L.Reset();
        L.PrepareTarget(Row, 1);
        L.AssignFrom(Row, 1);
        Observer.Observe('read before', L.Rd(Row));
        Row.CalcFields(Content);
        Observer.Observe('after', L.Rd(Row));
        Observer.Finish();
    end;

    [Test]
    procedure Assign_OtherVarModifiesField_ThenCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
        Row2: Record "LT BACF Row";
    begin
        L.Reset();
        L.PrepareTarget(Row, 1);
        L.AssignFrom(Row, 1);
        Row2.Get(1);
        Row2.Info := 'other';
        Row2.Modify();
        Observer.Observe('before', L.HasValueText(Row.Content.HasValue()));
        Row.CalcFields(Content);
        Observer.Observe('after', L.Rd(Row));
        Observer.Observe('info in hand', Row.Info);
        Observer.Observe('row', L.Stored(1));
        Observer.Finish();
    end;

    [Test]
    procedure Assign_OtherVarWritesBlob_ThenCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
        Row2: Record "LT BACF Row";
    begin
        L.Reset();
        L.PrepareTarget(Row, 1);
        L.AssignFrom(Row, 1);
        Row2.Get(1);
        L.W(Row2, 'other');
        Row2.Modify();
        Observer.Observe('before', L.HasValueText(Row.Content.HasValue()));
        Row.CalcFields(Content);
        Observer.Observe('after', L.Rd(Row));
        Observer.Observe('row', L.Stored(1));
        Observer.Finish();
    end;

    [Test]
    procedure Assign_OtherVarModifies_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
        Row2: Record "LT BACF Row";
    begin
        L.Reset();
        L.PrepareTarget(Row, 1);
        L.AssignFrom(Row, 1);
        Row2.Get(1);
        Row2.Info := 'other';
        Row2.Modify();
        Row.CalcFields(Content);
        Row.Modify();
        Observer.Observe('row', L.Stored(1));
        Observer.Finish();
    end;

    [Test]
    procedure Assign_FromVariant_ThenCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
        TmpSrc: Record "LT BACF Row" temporary;
        V: Variant;
    begin
        L.Reset();
        L.PrepareTarget(Row, 1);
        L.TempSource(TmpSrc);
        V := TmpSrc.Content;
        Row.Content := V;
        Observer.Observe('before', L.HasValueText(Row.Content.HasValue()));
        Row.CalcFields(Content);
        Observer.Observe('after', L.Rd(Row));
        Row.Modify();
        Observer.Observe('row', L.Stored(1));
        Observer.Finish();
    end;

    [Test]
    procedure Assign_FromFieldRefValue_ThenCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
        TmpSrc: Record "LT BACF Row" temporary;
        RR: RecordRef;
    begin
        L.Reset();
        L.PrepareTarget(Row, 1);
        L.TempSource(TmpSrc);
        RR.GetTable(TmpSrc);
        Row.Content := RR.Field(2).Value;
        Observer.Observe('before', L.HasValueText(Row.Content.HasValue()));
        Row.CalcFields(Content);
        Observer.Observe('after', L.Rd(Row));
        Row.Modify();
        Observer.Observe('row', L.Stored(1));
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValueSet_ThenCalcField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
        Row3: Record "LT BACF Row" temporary;
        TmpSrc: Record "LT BACF Row" temporary;
        RR: RecordRef;
        FR: FieldRef;
    begin
        L.Reset();
        L.PrepareTarget(Row, 1);
        L.TempSource(TmpSrc);
        RR.Open(Database::"LT BACF Row");
        RR.Get(Row.RecordId);
        FR := RR.Field(2);
        FR.Value := TmpSrc.Content;
        FR.CalcField();
        RR.SetTable(Row3);
        Observer.Observe('after', L.Rd(Row3));
        RR.Modify();
        Observer.Observe('row', L.Stored(1));
        Observer.Finish();
    end;

    [Test]
    procedure Assign_ThenOutStreamWrite_ThenCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        L.Reset();
        L.PrepareTarget(Row, 1);
        L.AssignFrom(Row, 1);
        L.W(Row, 'zz');
        Row.CalcFields(Content);
        Observer.Observe('after', L.Rd(Row));
        Row.Modify();
        Observer.Observe('row', L.Stored(1));
        Observer.Finish();
    end;

    [Test]
    procedure Assign_StoredOld_FromEmpty_ThenCalcFieldsTwice()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BACF Row";
    begin
        L.Reset();
        L.PrepareTarget(Row, 3);
        L.AssignFrom(Row, 6);
        Row.CalcFields(Content);
        Observer.Observe('after 1', L.Rd(Row));
        Row.CalcFields(Content);
        Observer.Observe('after 2', L.Rd(Row));
        Observer.Finish();
    end;
}
