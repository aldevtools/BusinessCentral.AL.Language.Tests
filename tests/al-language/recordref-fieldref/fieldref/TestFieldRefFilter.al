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

    // FieldRef.SetFilter with the text 0 and related texts on a Duration field (al-runner issue 7388), next to Integer, BigInteger and Decimal.
    // Rows: Duration 0, 1000 and 60000 (Integer, BigInteger and Decimal the same numbers).
    [TryFunction]
    local procedure TrySetFilter(var FldRef: FieldRef; Txt: Text)
    begin
        FldRef.SetFilter(Txt);
    end;

    local procedure SeedNumbers()
    var
        Rec: Record "ALT Universal";
    begin
        Rec."Entry No." := 1;
        Rec."Integer Field" := 0;
        Rec."BigInteger Field" := 0;
        Rec."Decimal Field" := 0;
        Rec."Duration Field" := 0;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec."Integer Field" := 1000;
        Rec."BigInteger Field" := 1000;
        Rec."Decimal Field" := 1000;
        Rec."Duration Field" := 1000;
        Rec.Insert();
        Rec."Entry No." := 3;
        Rec."Integer Field" := 60000;
        Rec."BigInteger Field" := 60000;
        Rec."Decimal Field" := 60000;
        Rec."Duration Field" := 60000;
        Rec.Insert();
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; Txt: Text)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Ids: Text;
    begin
        RecRef.Open(Database::"ALT Universal");
        FldRef := RecRef.Field(FieldNo);
        ClearLastError();
        if TrySetFilter(FldRef, Txt) then begin
            if RecRef.FindSet() then
                repeat
                    Ids += Format(RecRef.Field(1).Value) + ',';
                until RecRef.Next() = 0;
            Observer.Observe(Name, 'ok|' + FldRef.GetFilter() + '|' + Ids);
        end else
            Observer.ObserveError(Name);
        RecRef.Close();
    end;

    [Test]
    procedure FieldRef_SetFilter_Zero_Duration()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        SeedNumbers();
        Probe(Observer, 'dur_0', 11, '0');
        Probe(Observer, 'dur_ne0', 11, '<>0');
        Probe(Observer, 'dur_empty', 11, '');
        Probe(Observer, 'dur_ne_empty', 11, '<>''''');
        Probe(Observer, 'dur_1000', 11, '1000');
        Probe(Observer, 'dur_gt0', 11, '>0');
        Probe(Observer, 'dur_range', 11, '0..1000');
        Probe(Observer, 'dur_1s', 11, '1S');
        Observer.Expect('dur_0', 'ok|''''|1,');
        Observer.Expect('dur_ne0', 'ok|<>''''|2,3,');
        Observer.Expect('dur_empty', 'ok||1,2,3,');
        Observer.Expect('dur_ne_empty', 'ok|<>''''|2,3,');
        Observer.Expect('dur_1000', 'ok|41 days 16 hours|');
        Observer.Expect('dur_gt0', 'ok|>''''|2,3,');
        Observer.Expect('dur_range', 'ok|''''..41 days 16 hours|1,2,3,');
        Observer.Expect('dur_1s', 'ok|1 second|2,');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRef_SetFilter_Zero_DurationTexts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        SeedNumbers();
        Probe(Observer, 'dur_1m', 11, '1M');
        Probe(Observer, 'dur_1min', 11, '1 minute');
        Probe(Observer, 'dur_zero_s', 11, '0S');
        Probe(Observer, 'dur_text', 11, 'abc');
        Probe(Observer, 'dur_0_blank', 11, ' 0 ');
        Probe(Observer, 'dur_minus1', 11, '-1');
        Probe(Observer, 'dur_0_0', 11, '0|1000');
        Observer.Expect('dur_1m', 'ok|1 minute|3,');
        Observer.Expect('dur_1min', 'ok|1 minute|3,');
        Observer.Expect('dur_zero_s', 'ok|''''|1,');
        Observer.Expect('dur_text|text', 'The filter "abc" is not valid for the Duration Field field on the ALT Universal table. The value "abc" can''t be evaluated into type Duration.');
        Observer.Expect('dur_text|code', 'Filter:CSide');
        Observer.Expect('dur_0_blank', 'ok|''''|1,');
        Observer.Expect('dur_minus1', 'ok|-1 hour|');
        Observer.Expect('dur_0_0', 'ok|''''|41 days 16 hours|1,');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRef_SetFilter_Zero_OtherNumberFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        SeedNumbers();
        Probe(Observer, 'int_0', 3, '0');
        Probe(Observer, 'int_ne0', 3, '<>0');
        Probe(Observer, 'big_0', 4, '0');
        Probe(Observer, 'big_ne0', 4, '<>0');
        Probe(Observer, 'dec_0', 5, '0');
        Probe(Observer, 'dec_ne0', 5, '<>0');
        Observer.Expect('int_0', 'ok|0|1,');
        Observer.Expect('int_ne0', 'ok|<>0|2,3,');
        Observer.Expect('big_0', 'ok|0|1,');
        Observer.Expect('big_ne0', 'ok|<>0|2,3,');
        Observer.Expect('dec_0', 'ok|0|1,');
        Observer.Expect('dec_ne0', 'ok|<>0|2,3,');
        Observer.Verify();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
