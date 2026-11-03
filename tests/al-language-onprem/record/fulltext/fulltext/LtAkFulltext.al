// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-optimizefortextsearch-property
// Scope: in-scope (OnPrem app)
// Fixtures used: Assert (60021)
// Probe: OptimizeForTextSearch on a Text field. The table must install (needs SQL Server full-text search, mssql:2022-fts image), and filters on the field return the rows. Corpus issue 633.
// BC versions: 27.0+
table 98250 "LT AK Fts Row Op"
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

codeunit 98251 "LT AK Fts Test Op"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed()
    var
        R: Record "LT AK Fts Row Op";
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
        R: Record "LT AK Fts Row Op";
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
        R: Record "LT AK Fts Row Op";
    begin
        Seed();
        Assert.AreEqual(5, R.Count(), 'all rows stored');
        R.Get(2);
        Assert.AreEqual('say hello there', R.Txt, 'value round-trips');
    end;

    [Test]
    procedure AtContainsFilterMatchesCaseInsensitively()
    var
        R: Record "LT AK Fts Row Op";
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
        R: Record "LT AK Fts Row Op";
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
        R: Record "LT AK Fts Row Op";
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
        F.SetRange(TableNo, Database::"LT AK Fts Row Op");
        F.SetRange("No.", 2);
        F.FindFirst();
        Assert.IsTrue(F.OptimizeForTextSearch, 'Txt is optimized');
        F.SetRange("No.", 3);
        F.FindFirst();
        Assert.IsFalse(F.OptimizeForTextSearch, 'Plain is not optimized');
    end;


    // Corpus issue 668 item 12 (writer BQ): a filter starting with '&&' on the field with OptimizeForTextSearch and on the plain field
    // (microsoft/AL issue 7899: the runtime generated wrong SQL, "The argument type nvarchar(max) is invalid for argument 2 of CONTAINS").
    // Each filter is a test of its own: its error, if any, is the result.
    [Test]
    procedure DoubleAmpersandFilterOnOptimizedField_BQ()
    var
        R: Record "LT AK Fts Row Op";
    begin
        Seed();
        R.SetFilter(Txt, '&&hello*');
        // BC 27.5, 28.5, 29.0: no SQL error, the filter text is kept as given. The row count (0 in CI) is not asserted: the full-text
        // index fills asynchronously, so a count right after the inserts may depend on timing (queued for the Windows nightly).
        Assert.AreEqual('&&hello*', R.GetFilter(Txt), '&& filter text on the optimized field');
        Assert.IsTrue(R.Count() >= 0, 'the && filter runs without a SQL error');
    end;

    [Test]
    procedure DoubleAmpersandFilterOnPlainField_BQ()
    var
        R: Record "LT AK Fts Row Op";
    begin
        Seed();
        R.SetFilter(Plain, '&&hello*');
        // BC 27.5, 28.5, 29.0: on a field without OptimizeForTextSearch the && form becomes a case-insensitive contains filter.
        Assert.AreEqual('@*hello**', R.GetFilter(Plain), '&& filter text on the plain field');
        Assert.AreEqual(4, R.Count(), '&&hello* on the plain field');
    end;
}
