// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 72561, tables 72562-72564
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed rows: "RecordRef.FilterGroup, Option to Enum (issue 23) - `RecordRef.FilterGroup`";
// "RecordRef.Get(RecordId) on a RecordRef that is not open"; "FindFirst, FindLast, FindSet and Find on an empty set without using the result";
// "TestField of a Blob field"; "A for loop over a Boolean"; (Probe fixes) "Format(Record)" with a FlowFilter before and after a FlowField
// Facts: RecordRef.FilterGroup, Get(RecordId) on an unopened RecordRef, Find errors, TestField of Blob, for over Boolean, SetCurrentKey(FlowField), Format(Record)
// BC versions: 29 (27 and 28 by CI)

table 72562 "LT PnE Misc Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Pic; Blob) { }
        field(4; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT PnE Misc Line" where(OwnerId = field(Id)));
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72563 "LT PnE Misc Line"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; OwnerId; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 72564 "LT PnE Flow Fmt"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; FltA; Integer)
        {
            FieldClass = FlowFilter;
        }
        field(3; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT PnE Misc Line" where(OwnerId = field(Id)));
        }
        field(4; FltB; Integer)
        {
            FieldClass = FlowFilter;
        }
        field(5; Name; Text[10]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72561 "LT PnE Record Misc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean()
    var
        R: Record "LT PnE Misc Rec";
        L: Record "LT PnE Misc Line";
        F: Record "LT PnE Flow Fmt";
    begin
        R.DeleteAll();
        L.DeleteAll();
        F.DeleteAll();
    end;

    [Test]
    procedure RecordRef_FilterGroup()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Clean();
        RR.Open(Database::"LT PnE Misc Rec");
        Observer.Observe('initial', Format(RR.FilterGroup()));
        Observer.Observe('set2', Format(RR.FilterGroup(2)));
        FR := RR.Field(2);
        FR.SetRange('X');
        Observer.Observe('group2Filters', RR.GetFilters());
        Observer.Observe('set0', Format(RR.FilterGroup(0)));
        Observer.Observe('group0Filters', RR.GetFilters());
        Observer.Observe('current', Format(RR.FilterGroup()));
        RR.FilterGroup(2);
        Observer.Observe('backIn2', RR.GetFilters());
        Observer.Observe('count2', Format(RR.Count()));
        RR.FilterGroup(0);
        FR.SetRange('Y');
        Observer.Observe('group0Own', RR.GetFilters());
        RR.FilterGroup(2);
        Observer.Observe('group2Kept', RR.GetFilters());
        RR.Reset();
        Observer.Observe('afterReset', Format(RR.FilterGroup()));
        RR.FilterGroup(2);
        Observer.Observe('resetCleared2', RR.GetFilters());
        RR.Close();
        Observer.Expect('initial', '0');
        Observer.Expect('set2', '2');
        Observer.Expect('group2Filters', 'Name: X');
        Observer.Expect('set0', '0');
        Observer.Expect('group0Filters', '');
        Observer.Expect('current', '0');
        Observer.Expect('backIn2', 'Name: X');
        Observer.Expect('count2', '0');
        Observer.Expect('group0Own', 'Name: Y');
        Observer.Expect('group2Kept', 'Name: X');
        Observer.Expect('afterReset', '0');
        Observer.Expect('resetCleared2', '');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_FilterGroup_ThroughGetTableAndSetTable()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT PnE Misc Rec";
        Back: Record "LT PnE Misc Rec";
        RR: RecordRef;
    begin
        Clean();
        Rec.FilterGroup(2);
        Rec.SetRange(Name, 'Z');
        Rec.FilterGroup(0);
        RR.GetTable(Rec);
        Observer.Observe('groupAfterGetTable', Format(RR.FilterGroup()));
        Observer.Observe('filtersGroup0', RR.GetFilters());
        RR.FilterGroup(2);
        Observer.Observe('filtersGroup2', RR.GetFilters());
        RR.FilterGroup(0);
        RR.SetTable(Back);
        Observer.Observe('backGroup', Format(Back.FilterGroup()));
        Observer.Observe('backFilters0', Back.GetFilters());
        Back.FilterGroup(2);
        Observer.Observe('backFilters2', Back.GetFilters());
        Observer.Expect('groupAfterGetTable', '0');
        Observer.Expect('filtersGroup0', '');
        Observer.Expect('filtersGroup2', 'Name: Z');
        Observer.Expect('backGroup', '0');
        Observer.Expect('backFilters0', '');
        Observer.Expect('backFilters2', 'Name: Z');
        Observer.Verify();
    end;

    [Test]
    procedure Find_OnEmptySet_ErrorTexts()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnE Misc Rec";
    begin
        Clean();
        asserterror R.FindFirst();
        Observer.ObserveError('findFirst');
        asserterror R.FindLast();
        Observer.ObserveError('findLast');
        asserterror R.FindSet();
        Observer.ObserveError('findSet');
        asserterror R.Find('-');
        Observer.ObserveError('findMinus');
        asserterror R.Find('+');
        Observer.ObserveError('findPlus');
        asserterror R.Find('=');
        Observer.ObserveError('findEqual');
        R.SetRange(Name, 'nothing');
        asserterror R.FindFirst();
        Observer.ObserveError('findFirstFiltered');
        asserterror R.FindSet(true);
        Observer.ObserveError('findSetForUpdate');
        asserterror R.Get(5);
        Observer.ObserveError('get');
        Observer.Expect('findFirst|text', 'The LT PnE Misc Rec table is empty.');
        Observer.Expect('findFirst|code', 'DB:TableIsEmpty');
        Observer.Expect('findLast|text', 'The LT PnE Misc Rec table is empty.');
        Observer.Expect('findLast|code', 'DB:TableIsEmpty');
        Observer.Expect('findSet|text', 'The LT PnE Misc Rec table is empty.');
        Observer.Expect('findSet|code', 'DB:TableIsEmpty');
        Observer.Expect('findMinus|text', 'The LT PnE Misc Rec table is empty.');
        Observer.Expect('findMinus|code', 'DB:TableIsEmpty');
        Observer.Expect('findPlus|text', 'The LT PnE Misc Rec table is empty.');
        Observer.Expect('findPlus|code', 'DB:TableIsEmpty');
        Observer.Expect('findEqual|text', 'The LT PnE Misc Rec does not exist. Identification fields and values: Id=''0''');
        Observer.Expect('findEqual|code', 'DB:RecordNotFound');
        Observer.Expect('findFirstFiltered|text', 'There is no LT PnE Misc Rec within the filter.\\Filters: Name: nothing');
        Observer.Expect('findFirstFiltered|code', 'DB:NothingInsideFilter');
        Observer.Expect('findSetForUpdate|text', 'There is no LT PnE Misc Rec within the filter.\\Filters: Name: nothing');
        Observer.Expect('findSetForUpdate|code', 'DB:NothingInsideFilter');
        Observer.Expect('get|text', 'The LT PnE Misc Rec does not exist. Identification fields and values: Id=''5''');
        Observer.Expect('get|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure TestField_Blob()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnE Misc Rec";
        Out: OutStream;
    begin
        Clean();
        R.Id := 1;
        R.Insert();
        asserterror R.TestField(Pic);
        Observer.ObserveError('noDataNoCalc');
        R.CalcFields(Pic);
        asserterror R.TestField(Pic);
        Observer.ObserveError('noDataCalc');
        R.Pic.CreateOutStream(Out);
        Out.WriteText('x');
        asserterror R.Modify();
        Observer.ObserveError('af214');
        R.TestField(Pic);
        Observer.Observe('dataNoCalcPassed', 'passed');
        R.CalcFields(Pic);
        asserterror R.TestField(Pic);
        Observer.ObserveError('af219');
        Observer.Observe('dataCalcPassed', 'passed');
        Clean();
        Observer.Expect('noDataNoCalc|text', 'Pic must have a value in LT PnE Misc Rec: Id=1. It cannot be zero or empty.');
        Observer.Expect('noDataNoCalc|code', 'TestField');
        Observer.Expect('noDataCalc|text', 'Pic must have a value in LT PnE Misc Rec: Id=1. It cannot be zero or empty.');
        Observer.Expect('noDataCalc|code', 'TestField');
        Observer.Expect('af214|text', 'The LT PnE Misc Rec does not exist. Identification fields and values: Id=''1''');
        Observer.Expect('af214|code', 'DB:RecordNotFound');
        Observer.Expect('dataNoCalcPassed', 'passed');
        Observer.Expect('af219|text', 'Pic must have a value in LT PnE Misc Rec: Id=1. It cannot be zero or empty.');
        Observer.Expect('af219|code', 'TestField');
        Observer.Expect('dataCalcPassed', 'passed');
        Observer.Verify();
    end;

    [Test]
    procedure ForLoop_OverBoolean()
    var
        Observer: Codeunit "Probe Observer";
        B: Boolean;
        N: Integer;
        S: Text;
    begin
        for B := false to true do begin
            N += 1;
            S += Format(B) + ';';
        end;
        Observer.Observe('upPasses', Format(N));
        Observer.Observe('upValues', S);
        Observer.Observe('upAfter', Format(B));
        N := 0;
        S := '';
        for B := true downto false do begin
            N += 1;
            S += Format(B) + ';';
        end;
        Observer.Observe('downPasses', Format(N));
        Observer.Observe('downValues', S);
        Observer.Observe('downAfter', Format(B));
        N := 0;
        for B := true to false do
            N += 1;
        Observer.Observe('emptyUp', Format(N));
        for B := false to false do
            N += 1;
        Observer.Observe('singleFalse', Format(N));
        for B := true to true do
            N += 1;
        Observer.Observe('singleTrue', Format(N));
        Observer.Expect('upPasses', '2');
        Observer.Expect('upValues', 'No;Yes;');
        Observer.Expect('upAfter', 'Yes');
        Observer.Expect('downPasses', '2');
        Observer.Expect('downValues', 'Yes;No;');
        Observer.Expect('downAfter', 'No');
        Observer.Expect('emptyUp', '0');
        Observer.Expect('singleFalse', '1');
        Observer.Expect('singleTrue', '2');
        Observer.Verify();
    end;

    [Test]
    procedure FormatRecord_FlowFilterPlacement()
    var
        Observer: Codeunit "Probe Observer";
        F: Record "LT PnE Flow Fmt";
        L: Record "LT PnE Misc Line";
    begin
        Clean();
        F.Id := 1;
        F.Name := 'n';
        F.Insert();
        L.Id := 1;
        L.OwnerId := 1;
        L.Insert();
        F.Get(1);
        Observer.Observe('noFilters', Format(F));
        F.SetRange(FltA, 5);
        F.SetRange(FltB, 7);
        Observer.Observe('bothFilters', Format(F));
        F.SetRange(FltA);
        Observer.Observe('onlyB', Format(F));
        F.CalcFields(Cnt);
        Observer.Observe('afterCalc', Format(F));
        Clean();
        Observer.Expect('noFilters', '1\tn\t0\t0\t0');
        Observer.Expect('bothFilters', '1\tn\t0\t0\t0');
        Observer.Expect('onlyB', '1\tn\t0\t0\t0');
        Observer.Expect('afterCalc', '1\tn\t0\t0\t1');
        Observer.Verify();
    end;
}
