// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-setview-method
// Fixtures used: ALT Universal (60000)

codeunit 60069 "Test RecordRef Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure RecordRef_SetView_FiltersRecords()
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
        i: Integer;
    begin
        Initialize();
        for i := 1 to 5 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        RecRef.Open(60000);
        RecRef.SetView('SORTING(Entry No.) WHERE(Entry No.=FILTER(1..3))');
        Assert.AreEqual(3, RecRef.Count(), 'Count() after SetView with WHERE filter(1..3) must return 3');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_GetView_NonEmpty_ReturnsString()
    var
        RecRef: RecordRef;
        ViewStr: Text;
    begin
        Initialize();
        RecRef.Open(60000);
        RecRef.SetView('SORTING(Entry No.)');
        ViewStr := RecRef.GetView();
        Assert.IsTrue(ViewStr <> '', 'GetView() must not return empty string after SetView()');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_Reset_ClearsFilters()
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
        i: Integer;
    begin
        Initialize();
        for i := 1 to 5 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        RecRef.Open(60000);
        RecRef.SetView('SORTING(Entry No.) WHERE(Entry No.=FILTER(1..2))');
        RecRef.Reset();
        Assert.AreEqual(5, RecRef.Count(), 'Count() after Reset() must return all 5 records');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_Field_SetRange_FiltersCorrectly()
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
        FldRef: FieldRef;
        IterCount: Integer;
        i: Integer;
    begin
        Initialize();
        for i := 1 to 5 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        RecRef.Open(60000);
        FldRef := RecRef.Field(1);
        FldRef.SetRange(2, 4);
        if RecRef.FindSet() then begin
            IterCount := 0;
            repeat
                IterCount := IterCount + 1;
            until RecRef.Next() = 0;
            Assert.AreEqual(3, IterCount, 'FindSet with SetRange(2,4) must iterate 3 times (Entry No. 2,3,4)');
        end else
            Assert.Fail('FindSet() after SetRange(2,4) must return true');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_GetFilters_AfterSetView_ReturnsFilter()
    var
        RecRef: RecordRef;
        FilterStr: Text;
    begin
        Initialize();
        RecRef.Open(60000);
        RecRef.SetView('WHERE(Entry No.=FILTER(5))');
        FilterStr := RecRef.GetFilters();
        Assert.IsTrue(FilterStr <> '', 'GetFilters() must not be empty after SetView with WHERE clause');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_HasFilter_AfterSetView_ReturnsTrue()
    var
        RecRef: RecordRef;
    begin
        Initialize();
        RecRef.Open(60000);
        RecRef.SetView('WHERE(Entry No.=FILTER(5))');
        Assert.IsTrue(RecRef.HasFilter(), 'HasFilter() must return true after SetView with filter');
        RecRef.Close();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
