// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setautocalcfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 67159 "LT TB Row"
// Probe: temporary records with a Blob field. (1) SetAutoCalcFields(Blob) on a temporary record, then Find, FindFirst, Get and FindSet: is the Blob loaded or empty,
// its Length and HasValue; (2) the Blob Length after a temporary Insert, after a Modify, and after Get without and with CalcFields; (3) the same on a real table
// row for comparison. Object ids 67159 - 67160.

table 67159 "LT TB Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
        field(3; Note; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67160 "LT TB Temporary Blob"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Put(var Row: Record "LT TB Row"; Value: Text)
    var
        OutS: OutStream;
    begin
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText(Value);
    end;

    local procedure Shown(var Row: Record "LT TB Row"): Text
    begin
        exit('len=' + Format(Row.Data.Length()) + '|has=' + Format(Row.Data.HasValue()));
    end;

    local procedure ShownAfterCalc(var Row: Record "LT TB Row"): Text
    begin
        Row.CalcFields(Data);
        exit('len=' + Format(Row.Data.Length()) + '|has=' + Format(Row.Data.HasValue()));
    end;

    [Test]
    procedure Temporary_SetAutoCalcFields_ThenFind()
    var
        Row: Record "LT TB Row" temporary;
        Fresh: Record "LT TB Row" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        Row.Init();
        Row.Id := 1;
        Put(Row, 'hello');
        Row.Insert();
        Observer.Observe('after_insert', Shown(Row));
        Fresh.Copy(Row, true);
        Fresh.SetAutoCalcFields(Data);
        Observer.Observe('find', Format(Fresh.Find('-')) + '|' + Shown(Fresh));
        Clear(Fresh);
        Fresh.Copy(Row, true);
        Fresh.SetAutoCalcFields(Data);
        Observer.Observe('findfirst', Format(Fresh.FindFirst()) + '|' + Shown(Fresh));
        Clear(Fresh);
        Fresh.Copy(Row, true);
        Fresh.SetAutoCalcFields(Data);
        Observer.Observe('get', Format(Fresh.Get(1)) + '|' + Shown(Fresh));
        Clear(Fresh);
        Fresh.Copy(Row, true);
        Fresh.SetAutoCalcFields(Data);
        Observer.Observe('findset', Format(Fresh.FindSet()) + '|' + Shown(Fresh));
        Observer.Observe('calcfields_after', ShownAfterCalc(Fresh));
        Observer.Expect('after_insert', 'len=5|has=Yes');
        Observer.Expect('find', 'Yes|len=5|has=Yes');
        Observer.Expect('findfirst', 'Yes|len=5|has=Yes');
        Observer.Expect('get', 'Yes|len=5|has=Yes');
        Observer.Expect('findset', 'Yes|len=5|has=Yes');
        Observer.Expect('calcfields_after', 'len=5|has=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Temporary_ModifyThenGet()
    var
        Row: Record "LT TB Row" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        Row.Init();
        Row.Id := 1;
        Put(Row, 'first');
        Row.Insert();
        Row.Get(1);
        Observer.Observe('get_without_calc', Shown(Row));
        Observer.Observe('get_with_calc', ShownAfterCalc(Row));
        Put(Row, 'second value');
        Row.Modify();
        Observer.Observe('after_modify', Shown(Row));
        Row.Get(1);
        Observer.Observe('modify_then_get', Shown(Row));
        Observer.Observe('modify_then_get_calc', ShownAfterCalc(Row));
        Row.Note := 'n';
        Row.Modify();
        Row.Get(1);
        Observer.Observe('plain_modify_then_get', Shown(Row));
        Observer.Observe('plain_modify_then_get_calc', ShownAfterCalc(Row));
        Observer.Expect('get_without_calc', 'len=5|has=Yes');
        Observer.Expect('get_with_calc', 'len=5|has=Yes');
        Observer.Expect('after_modify', 'len=12|has=Yes');
        Observer.Expect('modify_then_get', 'len=12|has=Yes');
        Observer.Expect('modify_then_get_calc', 'len=12|has=Yes');
        Observer.Expect('plain_modify_then_get', 'len=12|has=Yes');
        Observer.Expect('plain_modify_then_get_calc', 'len=12|has=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RealTable_ModifyThenGet()
    var
        Row: Record "LT TB Row";
        Fresh: Record "LT TB Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Put(Row, 'first');
        Row.Insert();
        Row.Get(1);
        Observer.Observe('get_without_calc', Shown(Row));
        Observer.Observe('get_with_calc', ShownAfterCalc(Row));
        Put(Row, 'second value');
        Row.Modify();
        Row.Get(1);
        Observer.Observe('modify_then_get', Shown(Row));
        Observer.Observe('modify_then_get_calc', ShownAfterCalc(Row));
        Fresh.SetAutoCalcFields(Data);
        Observer.Observe('autocalc_find', Format(Fresh.FindFirst()) + '|' + Shown(Fresh));
        Observer.Expect('get_without_calc', 'len=11|has=Yes');
        Observer.Expect('get_with_calc', 'len=5|has=Yes');
        Observer.Expect('modify_then_get', 'len=18|has=Yes');
        Observer.Expect('modify_then_get_calc', 'len=12|has=Yes');
        Observer.Expect('autocalc_find', 'Yes|len=12|has=Yes');
        Observer.Verify();
    end;

    // al-runner issue 6434 (writer Y12): Target.Data := Source.Data where Source is a temporary row that was inserted and read back.
    // What the copy holds: HasValue, Length and the text read from it.
    local procedure Copied(var Target: Record "LT TB Row" temporary): Text
    var
        InS: InStream;
        T: Text;
        Head: Text;
    begin
        // HasValue and Length first: creating the stream must not decide what they report.
        Head := 'has=' + Format(Target.Data.HasValue()) + '|len=' + Format(Target.Data.Length());
        Target.Data.CreateInStream(InS);
        InS.ReadText(T);
        exit(Head + '|text=' + T);
    end;

    local procedure InsertY12(var Row: Record "LT TB Row" temporary)
    begin
        Row.Init();
        Row.Id := 1;
        Put(Row, 'mdi test image');
        Row.Insert(false);
    end;

    [Test]
    procedure Y12_BlobCopy_AfterInsertFindFirst()
    var
        Row: Record "LT TB Row" temporary;
        Target: Record "LT TB Row" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        InsertY12(Row);
        Row.FindFirst();
        Observer.Observe('source', Shown(Row));
        Target.Data := Row.Data;
        Observer.Observe('copy', Copied(Target));
        Observer.Finish();
    end;

    [Test]
    procedure Y12_BlobCopy_AfterInsertFindFirstCalcFields()
    var
        Row: Record "LT TB Row" temporary;
        Target: Record "LT TB Row" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        InsertY12(Row);
        Row.FindFirst();
        Row.CalcFields(Data);
        Target.Data := Row.Data;
        Observer.Observe('copy', Copied(Target));
        Observer.Finish();
    end;

    [Test]
    procedure Y12_BlobCopy_InMemoryOnly()
    var
        Row: Record "LT TB Row" temporary;
        Target: Record "LT TB Row" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        Put(Row, 'mdi test image');
        Target.Data := Row.Data;
        Observer.Observe('copy', Copied(Target));
        Observer.Finish();
    end;

    [Test]
    procedure Y12_BlobCopy_AfterInsertOnly()
    var
        Row: Record "LT TB Row" temporary;
        Target: Record "LT TB Row" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        InsertY12(Row);
        Target.Data := Row.Data;
        Observer.Observe('copy', Copied(Target));
        Observer.Finish();
    end;

    [Test]
    procedure Y12_BlobCopy_AfterGetAndFindSet()
    var
        Row: Record "LT TB Row" temporary;
        Target: Record "LT TB Row" temporary;
        Target2: Record "LT TB Row" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        InsertY12(Row);
        Row.Get(1);
        Target.Data := Row.Data;
        Observer.Observe('get_copy', Copied(Target));
        Row.FindSet();
        Target2.Data := Row.Data;
        Observer.Observe('findset_copy', Copied(Target2));
        Observer.Finish();
    end;

    [Test]
    procedure Y12_BlobCopy_CopyThenInsertTarget()
    var
        Row: Record "LT TB Row" temporary;
        Target: Record "LT TB Row" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        InsertY12(Row);
        Row.FindFirst();
        Target.Id := 2;
        Target.Data := Row.Data;
        Target.Insert();
        Target.Get(2);
        Target.CalcFields(Data);
        Observer.Observe('target_read_back', Copied(Target));
        Observer.Finish();
    end;

    [Test]
    procedure Y12_BlobCopy_ViaRecordRefTempBlob()
    var
        Row: Record "LT TB Row" temporary;
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        InS: InStream;
        T: Text;
        Observer: Codeunit "Probe Observer";
    begin
        InsertY12(Row);
        Row.FindSet();
        RecRef.GetTable(Row);
        TempBlob.FromRecordRef(RecRef, Row.FieldNo(Data));
        Observer.Observe('tempblob_has', Format(TempBlob.HasValue()));
        Observer.Observe('tempblob_len', Format(TempBlob.Length()));
        TempBlob.CreateInStream(InS);
        InS.ReadText(T);
        Observer.Observe('tempblob_text', T);
        Observer.Finish();
    end;

    [Test]
    procedure Y12_BlobCopy_ViaFieldRefValue()
    var
        Row: Record "LT TB Row" temporary;
        Target: Record "LT TB Row" temporary;
        RecRef: RecordRef;
        FldRef: FieldRef;
        Observer: Codeunit "Probe Observer";
    begin
        InsertY12(Row);
        Row.FindFirst();
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(Row.FieldNo(Data));
        Target.Data := FldRef.Value();
        Observer.Observe('fieldref_copy', Copied(Target));
        Observer.Finish();
    end;
}
