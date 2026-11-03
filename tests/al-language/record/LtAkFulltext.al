// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-optimizefortextsearch-property
// Scope: in-scope (Cloud app)
// Fixtures used: Assert (60021)
// Probe: OptimizeForTextSearch on a Text field. The table must install (needs SQL Server full-text search, mssql:2022-fts image), and filters on the field return the rows. Corpus issue 633.
// BC versions: 27.0+
table 79200 "LT AK Fts Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[100]) { OptimizeForTextSearch = true; }
        field(3; Plain; Text[100]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 79201 "LT AK Fts Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed()
    var
        R: Record "LT AK Fts Row";
    begin
        R.DeleteAll();
        Add(1, 'Hello World');
        Add(2, 'say hello there');
        Add(3, 'HELLO');
        Add(4, 'helloworld');
        Add(5, 'goodbye');
    end;

    local procedure Add(Id: Integer; Value: Text[100])
    var
        R: Record "LT AK Fts Row";
    begin
        R.Init();
        R.Id := Id;
        R.Txt := Value;
        R.Plain := Value;
        R.Insert();
    end;

    [Test]
    procedure TableWithOptimizedFieldInstallsAndStores()
    var
        R: Record "LT AK Fts Row";
    begin
        Seed();
        Assert.AreEqual(5, R.Count(), 'all rows stored');
        R.Get(2);
        Assert.AreEqual('say hello there', R.Txt, 'value round-trips');
    end;

    [Test]
    procedure AtContainsFilterMatchesCaseInsensitively()
    var
        R: Record "LT AK Fts Row";
    begin
        Seed();
        R.SetFilter(Txt, '@*hello*');
        Assert.AreEqual(4, R.Count(), '@*hello* on optimized field');
        R.Reset();
        R.SetFilter(Plain, '@*hello*');
        Assert.AreEqual(4, R.Count(), '@*hello* on plain field');
    end;

    [Test]
    procedure ContainsFilterWithoutAt()
    var
        R: Record "LT AK Fts Row";
    begin
        Seed();
        R.SetFilter(Txt, '*hello*');
        Assert.AreEqual(2, R.Count(), '*hello* on optimized field is case-sensitive');
        R.SetFilter(Txt, '*Hello*');
        Assert.AreEqual(1, R.Count(), '*Hello*');
        R.SetFilter(Txt, '*HELLO*');
        Assert.AreEqual(1, R.Count(), '*HELLO*');
        R.Reset();
        R.SetFilter(Plain, '*hello*');
        Assert.AreEqual(2, R.Count(), '*hello* on plain field is case-sensitive');
    end;

    [Test]
    procedure PrefixAndSuffixFilters()
    var
        R: Record "LT AK Fts Row";
    begin
        Seed();
        R.SetFilter(Txt, '@hello*');
        Assert.AreEqual(3, R.Count(), '@hello*');
        R.SetFilter(Txt, '@*hello');
        Assert.AreEqual(1, R.Count(), '@*hello');
        R.SetFilter(Txt, '@*hello there');
        Assert.AreEqual(1, R.Count(), '@*hello there');
        R.SetFilter(Txt, '@*world*');
        Assert.AreEqual(2, R.Count(), '@*world*');
        R.SetFilter(Txt, '@*nomatch*');
        Assert.AreEqual(0, R.Count(), 'no match');
    end;

    [Test]
    procedure FieldTableReportsOptimizeForTextSearch()
    var
        F: Record Field;
    begin
        F.SetRange(TableNo, Database::"LT AK Fts Row");
        F.SetRange("No.", 2);
        F.FindFirst();
        Assert.IsTrue(F.OptimizeForTextSearch, 'Txt is optimized');
        F.SetRange("No.", 3);
        F.FindFirst();
        Assert.IsFalse(F.OptimizeForTextSearch, 'Plain is not optimized');
    end;

    // Corpus issue 668 item 63 (writer br): FieldRef.IsOptimizedForTextSearch of a field with OptimizeForTextSearch = true and of one without.
    // OptimizeForTextSearch on a FlowField or FlowFilter field does not compile (AL0223): must-not-compile cases 1471 and 1472.
    [Test]
    procedure FieldRefIsOptimizedForTextSearch()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LT AK Fts Row");
        Assert.IsTrue(RecRef.Field(2).IsOptimizedForTextSearch(), 'Txt is optimized');
        Assert.IsFalse(RecRef.Field(3).IsOptimizedForTextSearch(), 'Plain is not optimized');
        Assert.IsFalse(RecRef.Field(1).IsOptimizedForTextSearch(), 'Id is not optimized');
    end;

    // Writer PX (probes-needed "Platform tables and session facts": Field.OptimizeForTextSearch declared on a field that is not Text):
    // a Code field with OptimizeForTextSearch = true (table 86162): the Field row, FieldRef.IsOptimizedForTextSearch and the rows a filter keeps.
    [Test]
    procedure PX_OptimizeForTextSearch_OnACodeField()
    var
        Observer: Codeunit "Probe Observer";
        F: Record Field;
        R: Record "LT PX Fts Code Row";
        RecRef: RecordRef;
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Cd := 'HELLO WORLD';
        R.Insert();
        R.Id := 2;
        R.Cd := 'SAY HELLO';
        R.Insert();
        R.Id := 3;
        R.Cd := 'GOODBYE';
        R.Insert();
        F.Get(Database::"LT PX Fts Code Row", 2);
        Observer.Observe('field_row_code', Format(F.OptimizeForTextSearch));
        F.Get(Database::"LT PX Fts Code Row", 3);
        Observer.Observe('field_row_plain_code', Format(F.OptimizeForTextSearch));
        RecRef.Open(Database::"LT PX Fts Code Row");
        Observer.Observe('fieldref_code', Format(RecRef.Field(2).IsOptimizedForTextSearch()));
        Observer.Observe('fieldref_plain_code', Format(RecRef.Field(3).IsOptimizedForTextSearch()));
        R.SetFilter(Cd, '@*hello*');
        Observer.Observe('at_contains_count', Format(R.Count()));
        R.SetFilter(Cd, '*HELLO*');
        Observer.Observe('contains_count', Format(R.Count()));
        R.DeleteAll();
        Observer.Expect('field_row_code', 'Yes');
        Observer.Expect('field_row_plain_code', 'No');
        Observer.Expect('fieldref_code', 'Yes');
        Observer.Expect('fieldref_plain_code', 'No');
        Observer.Expect('at_contains_count', '2');
        Observer.Expect('contains_count', '2');
        Observer.Verify();
    end;
}

table 86162 "LT PX Fts Code Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Cd; Code[50]) { OptimizeForTextSearch = true; }
        field(3; PlainCd; Code[50]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
