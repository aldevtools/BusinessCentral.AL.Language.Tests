codeunit 60075 "Test FieldRef Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure FieldRef_SetRange_SingleValue_FiltersCorrectly()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 10;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec."Integer Field" := 20;
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec."Integer Field" := 30;
        Rec.Insert();

        RecRef.Open(60000);
        FldRef := RecRef.Field(1);  // Entry No.
        FldRef.SetRange(2);

        Count := 0;
        if RecRef.FindSet() then
            repeat
                Count += 1;
            until RecRef.Next() = 0;

        Assert.AreEqual(1, Count, 'SetRange(2) must return exactly 1 record');
    end;

    [Test]
    procedure FieldRef_SetRange_FromTo_IncludesBounds()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec.Insert();
        Rec."Entry No." := 4;
        Rec.Insert();
        Rec."Entry No." := 5;
        Rec.Insert();

        RecRef.Open(60000);
        FldRef := RecRef.Field(1);
        FldRef.SetRange(2, 4);

        Count := 0;
        if RecRef.FindSet() then
            repeat
                Count += 1;
            until RecRef.Next() = 0;

        Assert.AreEqual(3, Count, 'SetRange(2,4) must return 3 records (2, 3, 4)');
    end;

    [Test]
    procedure FieldRef_SetFilter_WildcardFilter_Matches()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Code Field" := 'ABC';
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec."Code Field" := 'ABD';
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec."Code Field" := 'XYZ';
        Rec.Insert();

        RecRef.Open(60000);
        FldRef := RecRef.Field(7);  // Code Field
        FldRef.SetFilter('AB*');

        Count := 0;
        if RecRef.FindSet() then
            repeat
                Count += 1;
            until RecRef.Next() = 0;

        Assert.AreEqual(2, Count, 'SetFilter(AB*) must return 2 records');
    end;

    [Test]
    procedure FieldRef_GetFilter_AfterSetRange_ReturnsString()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        FilterStr: Text;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();

        RecRef.Open(60000);
        FldRef := RecRef.Field(1);
        FldRef.SetRange(1, 3);

        FilterStr := FldRef.GetFilter();
        Assert.IsTrue(FilterStr <> '', 'GetFilter must return non-empty string after SetRange');
    end;

    [Test]
    procedure FieldRef_SetRange_NoArgs_ClearsFilter()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec.Insert();

        RecRef.Open(60000);
        FldRef := RecRef.Field(1);
        FldRef.SetRange(2);  // Filter to Entry No. = 2
        FldRef.SetRange();   // Clear the filter

        Count := 0;
        if RecRef.FindSet() then
            repeat
                Count += 1;
            until RecRef.Next() = 0;

        Assert.AreEqual(3, Count, 'SetRange() with no args must clear filter and return all records');
    end;

    [Test]
    procedure FieldRef_SetFilter_Comparison_FiltersCorrectly()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Universal";
        Count: Integer;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 5;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec."Integer Field" := 10;
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec."Integer Field" := 15;
        Rec.Insert();

        RecRef.Open(60000);
        FldRef := RecRef.Field(3);  // Integer Field
        FldRef.SetFilter('>%1', 7);

        Count := 0;
        if RecRef.FindSet() then
            repeat
                Count += 1;
            until RecRef.Next() = 0;

        Assert.AreEqual(2, Count, 'SetFilter(>7) must return 2 records (10 and 15)');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
