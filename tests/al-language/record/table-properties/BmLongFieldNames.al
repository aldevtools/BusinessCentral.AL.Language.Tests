// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/diagnostics/diagnostic-al468
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Corpus #664 item 2: table field names of 30, 31 and 40 characters. The compiler gives warning AL0468 for 31 and 40 characters
// ("Longer field names are prone to cause SQL errors") and builds the app (AL 30 beta, runtime 16.1 to 18.0). This records what the
// tier does with such fields: insert, read, filter, sort, FieldRef name, CalcSums and ModifyAll.
// BC versions: 29 (27 and 28 by CI)
table 81953 "LT BM Long Field Names"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Abcdefghij Abcdefghij Abcdefgh"; Integer) { }
        field(3; "Abcdefghij Abcdefghij Abcdefghi"; Integer) { }
        field(4; "Abcdefghij Abcdefghij Abcdefghij Abcdefg"; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(Long; "Abcdefghij Abcdefghij Abcdefghij Abcdefg") { }
    }
}

codeunit 81956 "LT BM Long Field Names"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BM_LongFieldNames_ReadWriteFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BM Long Field Names";
        RecRef: RecordRef;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row."Abcdefghij Abcdefghij Abcdefgh" := 30;
        Row."Abcdefghij Abcdefghij Abcdefghi" := 31;
        Row."Abcdefghij Abcdefghij Abcdefghij Abcdefg" := 'forty';
        Row.Insert();
        Row.Id := 2;
        Row."Abcdefghij Abcdefghij Abcdefghi" := 62;
        Row."Abcdefghij Abcdefghij Abcdefghij Abcdefg" := 'another';
        Row.Insert();
        Clear(Row);
        Row.Get(1);
        Observer.Observe('read_30', Format(Row."Abcdefghij Abcdefghij Abcdefgh"));
        Observer.Observe('read_31', Format(Row."Abcdefghij Abcdefghij Abcdefghi"));
        Observer.Observe('read_40', Row."Abcdefghij Abcdefghij Abcdefghij Abcdefg");
        Row.Reset();
        Row.SetRange("Abcdefghij Abcdefghij Abcdefghi", 62);
        Observer.Observe('filter_31_count', Format(Row.Count()));
        Observer.Observe('filter_31_text', Row.GetFilters());
        Row.Reset();
        Row.SetCurrentKey("Abcdefghij Abcdefghij Abcdefghij Abcdefg");
        Row.FindFirst();
        Observer.Observe('sorted_by_40_first', Format(Row.Id));
        Row.Reset();
        Row.CalcSums("Abcdefghij Abcdefghij Abcdefghi");
        Observer.Observe('calcsums_31', Format(Row."Abcdefghij Abcdefghij Abcdefghi"));
        Row.ModifyAll("Abcdefghij Abcdefghij Abcdefghi", 5);
        Row.SetRange("Abcdefghij Abcdefghij Abcdefghi", 5);
        Observer.Observe('modifyall_31_count', Format(Row.Count()));
        Observer.Observe('fieldname_40', Row.FieldName("Abcdefghij Abcdefghij Abcdefghij Abcdefg"));
        Observer.Observe('fieldcaption_40', Row.FieldCaption("Abcdefghij Abcdefghij Abcdefghij Abcdefg"));
        RecRef.Open(Database::"LT BM Long Field Names");
        Observer.Observe('fieldref_name_31', RecRef.Field(3).Name());
        Observer.Observe('fieldref_length_name_40', Format(StrLen(RecRef.Field(4).Name())));
        RecRef.Close();
        Observer.Expect('read_30', '30');
        Observer.Expect('read_31', '31');
        Observer.Expect('read_40', 'forty');
        Observer.Expect('filter_31_count', '1');
        Observer.Expect('filter_31_text', 'Abcdefghij Abcdefghij Abcdefghi: 62');
        Observer.Expect('sorted_by_40_first', '2');
        Observer.Expect('calcsums_31', '93');
        Observer.Expect('modifyall_31_count', '2');
        Observer.Expect('fieldname_40', 'Abcdefghij Abcdefghij Abcdefghij Abcdefg');
        Observer.Expect('fieldcaption_40', 'Abcdefghij Abcdefghij Abcdefghij Abcdefg');
        Observer.Expect('fieldref_name_31', 'Abcdefghij Abcdefghij Abcdefghi');
        Observer.Expect('fieldref_length_name_40', '40');
        Observer.Verify();
    end;
}
