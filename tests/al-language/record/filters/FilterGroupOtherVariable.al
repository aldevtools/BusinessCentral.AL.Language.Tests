// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-filtergroup-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 97445-97452 (REC FG1 Row 1 to 7, REC FG1 Other Variable)
// Probe: from al-runner issue 7586 item 3 (DeleteAll on a record while another variable of the same table holds a filter in filter
//   group 1; met in Microsoft's test apps).
// Area: a filter that one variable sets in a filter group, seen from ANOTHER variable of the same table that never set a filter.
//   - groups 0, 2, 3, 4, 5, 6, 7 and -1 (the other variable's Count), then group 1;
//   - group 1 from a Record variable: the other variable's Count, IsEmpty, Get of a row outside the filter, the filter text it reads in
//     its own group 1, Count after Reset and after Clear, DeleteAll, and what is left once the first variable takes its filter back;
//   - group 1 set by a variable that then goes out of scope: FindSet, Get, Insert of a row outside the filter, Modify of a row so that
//     it leaves the filter, ModifyAll, and every row once the filter is taken back by a third variable;
//   - whether the filter is still there in the next test of the codeunit;
//   - group 1 set on a temporary record (database variable and second temporary variable), set through a RecordRef (Record variable and
//     second RecordRef), and set on a Record variable (RecordRef and temporary variable).
//   Every test reads the table through a fresh variable first ('base'), so a filter left by an earlier step shows.
// Already pinned elsewhere, not repeated: after Page.Run(Page, Rec) with a filter in group 1 of Rec, a later DeleteAll and Count of a
//   fresh variable see only the rows in that filter (types/text-code-char/P145PageRunView.al, SfSeed, seed_before); the filter groups
//   of one variable (P68F_FilterGroup.al, GetRangeFilterGroups.al).
// local object: a filter in group 1 can stay on the table for the session (P145PageRunView.al), so each question has its own table and
//   no shared fixture table is changed for other test codeunits.
// Observation form: every test ends in Finish(); the values are what BC produced.
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)

table 97445 "REC FG1 Row 1"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tag; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 97446 "REC FG1 Row 2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tag; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 97447 "REC FG1 Row 3"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tag; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 97448 "REC FG1 Row 4"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tag; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 97449 "REC FG1 Row 5"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tag; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 97450 "REC FG1 Row 6"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tag; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 97451 "REC FG1 Row 7"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tag; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 97452 "REC FG1 Other Variable"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed1()
    var
        Row: Record "REC FG1 Row 1";
    begin
        Row.DeleteAll();
        Add1(1, 1);
        Add1(2, 2);
        Add1(3, 1);
        Add1(4, 2);
    end;

    local procedure Add1(NewId: Integer; NewTag: Integer)
    var
        Row: Record "REC FG1 Row 1";
    begin
        Row.Init();
        Row.Id := NewId;
        Row.Tag := NewTag;
        if Row.Insert() then;
    end;

    // Count and rows (id:tag) read through a variable that never set a filter.
    local procedure Fresh1(): Text
    var
        Row: Record "REC FG1 Row 1";
        Result: Text;
    begin
        Result := Format(Row.Count()) + ' [';
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Format(Row.Tag) + ' ';
            until Row.Next() = 0;
        exit(Result + ']');
    end;

    // The filter text a variable that never set a filter reads in its own group 1.
    local procedure FreshGroup1Filter1(): Text
    var
        Row: Record "REC FG1 Row 1";
        Result: Text;
    begin
        Row.FilterGroup(1);
        Result := Row.GetFilters();
        Row.FilterGroup(0);
        exit(Result);
    end;

    local procedure SetGroup1In1(TagValue: Integer)
    var
        Row: Record "REC FG1 Row 1";
    begin
        Row.FilterGroup(1);
        Row.SetRange(Tag, TagValue);
        Row.FilterGroup(0);
    end;

    local procedure ClearGroup1In1()
    var
        Row: Record "REC FG1 Row 1";
    begin
        Row.FilterGroup(1);
        Row.SetRange(Tag);
        Row.FilterGroup(0);
    end;

    local procedure Seed2()
    var
        Row: Record "REC FG1 Row 2";
    begin
        Row.DeleteAll();
        Add2(1, 1);
        Add2(2, 2);
        Add2(3, 1);
        Add2(4, 2);
    end;

    local procedure Add2(NewId: Integer; NewTag: Integer)
    var
        Row: Record "REC FG1 Row 2";
    begin
        Row.Init();
        Row.Id := NewId;
        Row.Tag := NewTag;
        if Row.Insert() then;
    end;

    // Count and rows (id:tag) read through a variable that never set a filter.
    local procedure Fresh2(): Text
    var
        Row: Record "REC FG1 Row 2";
        Result: Text;
    begin
        Result := Format(Row.Count()) + ' [';
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Format(Row.Tag) + ' ';
            until Row.Next() = 0;
        exit(Result + ']');
    end;

    // The filter text a variable that never set a filter reads in its own group 1.
    local procedure FreshGroup1Filter2(): Text
    var
        Row: Record "REC FG1 Row 2";
        Result: Text;
    begin
        Row.FilterGroup(1);
        Result := Row.GetFilters();
        Row.FilterGroup(0);
        exit(Result);
    end;

    local procedure SetGroup1In2(TagValue: Integer)
    var
        Row: Record "REC FG1 Row 2";
    begin
        Row.FilterGroup(1);
        Row.SetRange(Tag, TagValue);
        Row.FilterGroup(0);
    end;

    local procedure ClearGroup1In2()
    var
        Row: Record "REC FG1 Row 2";
    begin
        Row.FilterGroup(1);
        Row.SetRange(Tag);
        Row.FilterGroup(0);
    end;

    local procedure Seed3()
    var
        Row: Record "REC FG1 Row 3";
    begin
        Row.DeleteAll();
        Add3(1, 1);
        Add3(2, 2);
        Add3(3, 1);
        Add3(4, 2);
    end;

    local procedure Add3(NewId: Integer; NewTag: Integer)
    var
        Row: Record "REC FG1 Row 3";
    begin
        Row.Init();
        Row.Id := NewId;
        Row.Tag := NewTag;
        if Row.Insert() then;
    end;

    // Count and rows (id:tag) read through a variable that never set a filter.
    local procedure Fresh3(): Text
    var
        Row: Record "REC FG1 Row 3";
        Result: Text;
    begin
        Result := Format(Row.Count()) + ' [';
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Format(Row.Tag) + ' ';
            until Row.Next() = 0;
        exit(Result + ']');
    end;

    // The filter text a variable that never set a filter reads in its own group 1.
    local procedure FreshGroup1Filter3(): Text
    var
        Row: Record "REC FG1 Row 3";
        Result: Text;
    begin
        Row.FilterGroup(1);
        Result := Row.GetFilters();
        Row.FilterGroup(0);
        exit(Result);
    end;

    local procedure SetGroup1In3(TagValue: Integer)
    var
        Row: Record "REC FG1 Row 3";
    begin
        Row.FilterGroup(1);
        Row.SetRange(Tag, TagValue);
        Row.FilterGroup(0);
    end;

    local procedure ClearGroup1In3()
    var
        Row: Record "REC FG1 Row 3";
    begin
        Row.FilterGroup(1);
        Row.SetRange(Tag);
        Row.FilterGroup(0);
    end;

    local procedure Seed4()
    var
        Row: Record "REC FG1 Row 4";
    begin
        Row.DeleteAll();
        Add4(1, 1);
        Add4(2, 2);
        Add4(3, 1);
        Add4(4, 2);
    end;

    local procedure Add4(NewId: Integer; NewTag: Integer)
    var
        Row: Record "REC FG1 Row 4";
    begin
        Row.Init();
        Row.Id := NewId;
        Row.Tag := NewTag;
        if Row.Insert() then;
    end;

    // Count and rows (id:tag) read through a variable that never set a filter.
    local procedure Fresh4(): Text
    var
        Row: Record "REC FG1 Row 4";
        Result: Text;
    begin
        Result := Format(Row.Count()) + ' [';
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Format(Row.Tag) + ' ';
            until Row.Next() = 0;
        exit(Result + ']');
    end;

    // The filter text a variable that never set a filter reads in its own group 1.
    local procedure FreshGroup1Filter4(): Text
    var
        Row: Record "REC FG1 Row 4";
        Result: Text;
    begin
        Row.FilterGroup(1);
        Result := Row.GetFilters();
        Row.FilterGroup(0);
        exit(Result);
    end;

    local procedure SetGroup1In4(TagValue: Integer)
    var
        Row: Record "REC FG1 Row 4";
    begin
        Row.FilterGroup(1);
        Row.SetRange(Tag, TagValue);
        Row.FilterGroup(0);
    end;

    local procedure ClearGroup1In4()
    var
        Row: Record "REC FG1 Row 4";
    begin
        Row.FilterGroup(1);
        Row.SetRange(Tag);
        Row.FilterGroup(0);
    end;

    local procedure Seed5()
    var
        Row: Record "REC FG1 Row 5";
    begin
        Row.DeleteAll();
        Add5(1, 1);
        Add5(2, 2);
        Add5(3, 1);
        Add5(4, 2);
    end;

    local procedure Add5(NewId: Integer; NewTag: Integer)
    var
        Row: Record "REC FG1 Row 5";
    begin
        Row.Init();
        Row.Id := NewId;
        Row.Tag := NewTag;
        if Row.Insert() then;
    end;

    // Count and rows (id:tag) read through a variable that never set a filter.
    local procedure Fresh5(): Text
    var
        Row: Record "REC FG1 Row 5";
        Result: Text;
    begin
        Result := Format(Row.Count()) + ' [';
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Format(Row.Tag) + ' ';
            until Row.Next() = 0;
        exit(Result + ']');
    end;

    // The filter text a variable that never set a filter reads in its own group 1.
    local procedure FreshGroup1Filter5(): Text
    var
        Row: Record "REC FG1 Row 5";
        Result: Text;
    begin
        Row.FilterGroup(1);
        Result := Row.GetFilters();
        Row.FilterGroup(0);
        exit(Result);
    end;

    local procedure SetGroup1In5(TagValue: Integer)
    var
        Row: Record "REC FG1 Row 5";
    begin
        Row.FilterGroup(1);
        Row.SetRange(Tag, TagValue);
        Row.FilterGroup(0);
    end;

    local procedure ClearGroup1In5()
    var
        Row: Record "REC FG1 Row 5";
    begin
        Row.FilterGroup(1);
        Row.SetRange(Tag);
        Row.FilterGroup(0);
    end;

    local procedure Seed6()
    var
        Row: Record "REC FG1 Row 6";
    begin
        Row.DeleteAll();
        Add6(1, 1);
        Add6(2, 2);
        Add6(3, 1);
        Add6(4, 2);
    end;

    local procedure Add6(NewId: Integer; NewTag: Integer)
    var
        Row: Record "REC FG1 Row 6";
    begin
        Row.Init();
        Row.Id := NewId;
        Row.Tag := NewTag;
        if Row.Insert() then;
    end;

    // Count and rows (id:tag) read through a variable that never set a filter.
    local procedure Fresh6(): Text
    var
        Row: Record "REC FG1 Row 6";
        Result: Text;
    begin
        Result := Format(Row.Count()) + ' [';
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Format(Row.Tag) + ' ';
            until Row.Next() = 0;
        exit(Result + ']');
    end;

    // The filter text a variable that never set a filter reads in its own group 1.
    local procedure FreshGroup1Filter6(): Text
    var
        Row: Record "REC FG1 Row 6";
        Result: Text;
    begin
        Row.FilterGroup(1);
        Result := Row.GetFilters();
        Row.FilterGroup(0);
        exit(Result);
    end;

    local procedure SetGroup1In6(TagValue: Integer)
    var
        Row: Record "REC FG1 Row 6";
    begin
        Row.FilterGroup(1);
        Row.SetRange(Tag, TagValue);
        Row.FilterGroup(0);
    end;

    local procedure ClearGroup1In6()
    var
        Row: Record "REC FG1 Row 6";
    begin
        Row.FilterGroup(1);
        Row.SetRange(Tag);
        Row.FilterGroup(0);
    end;

    local procedure Seed7()
    var
        Row: Record "REC FG1 Row 7";
    begin
        Row.DeleteAll();
        Add7(1, 1);
        Add7(2, 2);
        Add7(3, 1);
        Add7(4, 2);
    end;

    local procedure Add7(NewId: Integer; NewTag: Integer)
    var
        Row: Record "REC FG1 Row 7";
    begin
        Row.Init();
        Row.Id := NewId;
        Row.Tag := NewTag;
        if Row.Insert() then;
    end;

    // Count and rows (id:tag) read through a variable that never set a filter.
    local procedure Fresh7(): Text
    var
        Row: Record "REC FG1 Row 7";
        Result: Text;
    begin
        Result := Format(Row.Count()) + ' [';
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Format(Row.Tag) + ' ';
            until Row.Next() = 0;
        exit(Result + ']');
    end;

    // The filter text a variable that never set a filter reads in its own group 1.
    local procedure FreshGroup1Filter7(): Text
    var
        Row: Record "REC FG1 Row 7";
        Result: Text;
    begin
        Row.FilterGroup(1);
        Result := Row.GetFilters();
        Row.FilterGroup(0);
        exit(Result);
    end;

    local procedure SetGroup1In7(TagValue: Integer)
    var
        Row: Record "REC FG1 Row 7";
    begin
        Row.FilterGroup(1);
        Row.SetRange(Tag, TagValue);
        Row.FilterGroup(0);
    end;

    local procedure ClearGroup1In7()
    var
        Row: Record "REC FG1 Row 7";
    begin
        Row.FilterGroup(1);
        Row.SetRange(Tag);
        Row.FilterGroup(0);
    end;

    [Test]
    procedure Group1_OtherVariable_CountGetDeleteAll()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "REC FG1 Row 1";
        B: Record "REC FG1 Row 1";
    begin
        // The reported shape: A sets Tag = 1 in group 1 and goes back to group 0, then B, which never set a filter, runs DeleteAll.
        Seed1();
        Observer.Observe('base', Fresh1());
        A.FilterGroup(1);
        A.SetRange(Tag, 1);
        A.FilterGroup(0);
        Observer.Observe('a filters in group 0', A.GetFilters());
        Observer.Observe('a count', Format(A.Count()));
        Observer.Observe('b count', Format(B.Count()));
        Observer.Observe('b isempty', Format(B.IsEmpty()));
        Observer.Observe('b filters in group 0', B.GetFilters());
        Observer.Observe('fresh group 1 filter', FreshGroup1Filter1());
        Observer.Observe('b get 2', Format(B.Get(2)));
        Observer.Observe('b get 1', Format(B.Get(1)));
        B.Reset();
        Observer.Observe('b count after reset', Format(B.Count()));
        Clear(B);
        Observer.Observe('b count after clear', Format(B.Count()));
        B.DeleteAll();
        Observer.Observe('b count after deleteall', Format(B.Count()));
        Observer.Observe('a count after deleteall', Format(A.Count()));
        A.FilterGroup(1);
        A.SetRange(Tag);
        A.FilterGroup(0);
        Observer.Observe('a count after a took the filter back', Format(A.Count()));
        Observer.Observe('fresh after a took the filter back', Fresh1());
        Observer.Observe('fresh group 1 filter at the end', FreshGroup1Filter1());
        Observer.Finish();
    end;

    local procedure OtherGroup(GroupNo: Integer): Text
    var
        A: Record "REC FG1 Row 2";
        Result: Text;
    begin
        A.FilterGroup(GroupNo);
        A.SetRange(Tag, 1);
        A.FilterGroup(0);
        Result := 'setter ' + Format(A.Count()) + ' | other ' + Fresh2();
        A.FilterGroup(GroupNo);
        A.SetRange(Tag);
        A.FilterGroup(0);
        exit(Result + ' | after ' + Fresh2());
    end;

    [Test]
    procedure OtherGroups_OtherVariable_Count()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed2();
        Observer.Observe('base', Fresh2());
        Observer.Observe('group 0', OtherGroup(0));
        Observer.Observe('group 2', OtherGroup(2));
        Observer.Observe('group 3', OtherGroup(3));
        Observer.Observe('group 4', OtherGroup(4));
        Observer.Observe('group 5', OtherGroup(5));
        Observer.Observe('group 6', OtherGroup(6));
        Observer.Observe('group 7', OtherGroup(7));
        Observer.Observe('group -1', OtherGroup(-1));
        Observer.Observe('group 1', OtherGroup(1));
        Observer.Finish();
    end;

    [Test]
    procedure OtherGroups_OtherVariable_DeleteAll()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "REC FG1 Row 2";
        B: Record "REC FG1 Row 2";
    begin
        // The control of the reported shape: the same steps with the filter in group 2.
        Seed2();
        Observer.Observe('base', Fresh2());
        A.FilterGroup(2);
        A.SetRange(Tag, 1);
        A.FilterGroup(0);
        Observer.Observe('b count', Format(B.Count()));
        B.DeleteAll();
        Observer.Observe('a count after deleteall', Format(A.Count()));
        A.FilterGroup(2);
        A.SetRange(Tag);
        A.FilterGroup(0);
        Observer.Observe('fresh after', Fresh2());
        Observer.Finish();
    end;

    [Test]
    procedure Group1_SetterOutOfScope_ReadsAndWrites()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "REC FG1 Row 3";
    begin
        Seed3();
        Observer.Observe('base', Fresh3());
        SetGroup1In3(1);
        Observer.Observe('fresh', Fresh3());
        Observer.Observe('fresh group 1 filter', FreshGroup1Filter3());
        Observer.Observe('get 2', Format(R.Get(2)));
        Observer.Observe('get 1', Format(R.Get(1)));
        R.Init();
        R.Id := 5;
        R.Tag := 2;
        Observer.Observe('insert 5 with tag 2', Format(R.Insert()));
        Observer.Observe('get 5', Format(R.Get(5)));
        Observer.Observe('fresh after insert', Fresh3());
        if R.Get(1) then begin
            R.Tag := 2;
            Observer.Observe('modify 1 to tag 2', Format(R.Modify()));
        end else
            Observer.Observe('modify 1 to tag 2', 'no get');
        Observer.Observe('fresh after modify', Fresh3());
        R.Reset();
        R.ModifyAll(Tag, 7);
        Observer.Observe('fresh after modifyall', Fresh3());
        ClearGroup1In3();
        Observer.Observe('fresh after a third variable took the filter back', Fresh3());
        Observer.Observe('fresh group 1 filter at the end', FreshGroup1Filter3());
        Observer.Finish();
    end;

    [Test]
    procedure Group1_NextTest_Part1_SetAndLeave()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Sets the filter and ends without taking it back; the next test reads what is left.
        Seed4();
        Observer.Observe('base', Fresh4());
        SetGroup1In4(1);
        Observer.Observe('fresh', Fresh4());
        Observer.Finish();
    end;

    [Test]
    procedure Group1_NextTest_Part2_Read()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('fresh group 1 filter at start', FreshGroup1Filter4());
        Add4(1, 1);
        Add4(2, 2);
        Add4(3, 1);
        Add4(4, 2);
        Observer.Observe('fresh after the four rows were added again', Fresh4());
        ClearGroup1In4();
        Observer.Observe('fresh after the filter was taken back', Fresh4());
        Observer.Finish();
    end;

    [Test]
    procedure Group1_OnTemporaryRecord_OtherVariables()
    var
        Observer: Codeunit "Probe Observer";
        T1: Record "REC FG1 Row 5" temporary;
        T2: Record "REC FG1 Row 5" temporary;
    begin
        Seed5();
        Observer.Observe('base', Fresh5());
        T1.Id := 1;
        T1.Tag := 1;
        T1.Insert();
        T1.Id := 2;
        T1.Tag := 2;
        T1.Insert();
        T2.Id := 1;
        T2.Tag := 1;
        T2.Insert();
        T2.Id := 2;
        T2.Tag := 2;
        T2.Insert();
        T1.FilterGroup(1);
        T1.SetRange(Tag, 1);
        T1.FilterGroup(0);
        Observer.Observe('setter temporary count', Format(T1.Count()));
        Observer.Observe('other temporary count', Format(T2.Count()));
        Observer.Observe('database', Fresh5());
        Observer.Observe('database group 1 filter', FreshGroup1Filter5());
        T1.FilterGroup(1);
        T1.SetRange(Tag);
        T1.FilterGroup(0);
        Observer.Observe('database after', Fresh5());
        Observer.Finish();
    end;

    [Test]
    procedure Group1_ThroughRecordRef_OtherVariables()
    var
        Observer: Codeunit "Probe Observer";
        Setter: RecordRef;
        Other: RecordRef;
        TagRef: FieldRef;
    begin
        Seed6();
        Observer.Observe('base', Fresh6());
        Setter.Open(Database::"REC FG1 Row 6");
        Setter.FilterGroup(1);
        TagRef := Setter.Field(2);
        TagRef.SetRange(1);
        Setter.FilterGroup(0);
        Observer.Observe('setter recordref count', Format(Setter.Count()));
        Other.Open(Database::"REC FG1 Row 6");
        Observer.Observe('other recordref count', Format(Other.Count()));
        Observer.Observe('record variable', Fresh6());
        Observer.Observe('record variable group 1 filter', FreshGroup1Filter6());
        Setter.FilterGroup(1);
        TagRef := Setter.Field(2);
        TagRef.SetRange();
        Setter.FilterGroup(0);
        Observer.Observe('record variable after', Fresh6());
        Observer.Finish();
    end;

    [Test]
    procedure Group1_OnRecordVariable_RecordRefAndTemporary()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "REC FG1 Row 7";
        T: Record "REC FG1 Row 7" temporary;
        Other: RecordRef;
    begin
        Seed7();
        Observer.Observe('base', Fresh7());
        T.Id := 1;
        T.Tag := 1;
        T.Insert();
        T.Id := 2;
        T.Tag := 2;
        T.Insert();
        A.FilterGroup(1);
        A.SetRange(Tag, 1);
        A.FilterGroup(0);
        Other.Open(Database::"REC FG1 Row 7");
        Observer.Observe('recordref count', Format(Other.Count()));
        Other.FilterGroup(1);
        Observer.Observe('recordref group 1 filter', Other.GetFilters());
        Other.FilterGroup(0);
        Observer.Observe('temporary count', Format(T.Count()));
        A.FilterGroup(1);
        A.SetRange(Tag);
        A.FilterGroup(0);
        Observer.Observe('record variable after', Fresh7());
        Observer.Finish();
    end;
}
