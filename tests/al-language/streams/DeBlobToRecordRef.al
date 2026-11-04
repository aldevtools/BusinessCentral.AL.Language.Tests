// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.utilities.temp-blob
// Scope: in-scope
// Fixtures used: codeunit 69160 "Probe Observer", table 85900 "LT DE Blob Row" (this file), System Application codeunit "Temp Blob"
// Probe: written against a local BC 29.0 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Lead: corpus issue 671, item "TempBlob.ToRecordRef into a Blob field" (microsoft/AL#7397: the field had no value after Modify on BC 22).
// Pins, after TempBlob.ToRecordRef(RecRef, FieldNo) and RecRef.Modify(), what a fresh Get of the row sees (HasValue before and after
// CalcFields, Length, the text), and what it sees when Modify is left out.

table 85900 "LT DE Blob Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 85902 "LT DE Blob ToRecordRef"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Fresh()
    var
        Row: Record "LT DE Blob Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Insert();
    end;

    local procedure ObserveRow(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Row: Record "LT DE Blob Row";
        InS: InStream;
        T: Text;
    begin
        Row.Get(1);
        Observer.Observe(Prefix + ' hasvalue before calcfields', Format(Row.Data.HasValue()));
        Observer.Observe(Prefix + ' length before calcfields', Format(Row.Data.Length()));
        Row.CalcFields(Data);
        Observer.Observe(Prefix + ' hasvalue', Format(Row.Data.HasValue()));
        Observer.Observe(Prefix + ' length', Format(Row.Data.Length()));
        Row.Data.CreateInStream(InS);
        InS.ReadText(T);
        Observer.Observe(Prefix + ' text', T);
    end;

    [Test]
    procedure ToRecordRef_Modify_FreshGet()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutS: OutStream;
    begin
        Fresh();
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('into field');
        RecRef.Open(Database::"LT DE Blob Row");
        RecRef.FindFirst();
        TempBlob.ToRecordRef(RecRef, 2);
        Observer.Observe('modify', Format(RecRef.Modify()));
        ObserveRow(Observer, 'modified');
        Observer.Expect('modify', 'Yes');
        Observer.Expect('modified hasvalue before calcfields', 'Yes');
        Observer.Expect('modified length before calcfields', '16');
        Observer.Expect('modified hasvalue', 'Yes');
        Observer.Expect('modified length', '10');
        Observer.Expect('modified text', 'into field');
        Observer.Verify();
    end;

    [Test]
    procedure ToRecordRef_WithoutModify_FreshGet()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutS: OutStream;
    begin
        Fresh();
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('into field');
        RecRef.Open(Database::"LT DE Blob Row");
        RecRef.FindFirst();
        TempBlob.ToRecordRef(RecRef, 2);
        ObserveRow(Observer, 'not modified');
        Observer.Expect('not modified hasvalue before calcfields', 'No');
        Observer.Expect('not modified length before calcfields', '0');
        Observer.Expect('not modified hasvalue', 'No');
        Observer.Expect('not modified length', '0');
        Observer.Expect('not modified text', '');
        Observer.Verify();
    end;
}
