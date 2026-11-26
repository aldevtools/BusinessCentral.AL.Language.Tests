// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-passing-parameters
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 78765..78772 (BVE Row, BVE Log, BVE Describe, BVE Publisher,
//   BVE Subscriber, BVE Subscriber A, BVE Subscriber B, BVE Event View Tests)
// What this probe measures: a record passed by value to an event (integration event, codeunit and table publisher, one to three
//   parameters, two subscribers, a Variant that holds a record). In each case the subscriber sees a fresh view on the copy:
//   key Id, ascending, no filters in groups 0, 2 and 4, no marks, no mark-only mode. The caller keeps its own filters, sort
//   order, ascending flag and marks after the event returns. The copy still carries the current row and the row count.
//   Each case runs with a fresh record and after Find, FindSet/Next, FindLast, FindMinus, Get, SetAscending(false) or marking.
// Measured on: BC 27.5, 28.5, 29.0 (same result on all three, no version guard needed).
// Not measured: filter groups 1 and -1 in the event cells, a caller standing in filter group 2, SetLoadFields before the event,
//   a temporary record, a manually bound subscriber, report or page publishers, a record passed as var to an event.
//   GetAscending on a non-key field is not part of this probe: BC raises an error for it ("not part of the current sorting").

table 78765 "BVE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
        field(3; Status; Option) { OptionMembers = Open,Posted; }
        field(4; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByName; Name) { }
    }

    procedure RaiseFromTable(var Note: Text)
    begin
        OnTableThing(Note, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTableThing(var Note: Text; R: Record "BVE Row")
    begin
    end;
}

codeunit 78766 "BVE Log"
{
    SingleInstance = true;

    var
        Entries: Dictionary of [Text, Text];

    procedure Put(EntryKey: Text; Value: Text)
    begin
        Entries.Set(EntryKey, Value);
    end;

    procedure Take(EntryKey: Text): Text
    var
        Value: Text;
    begin
        if not Entries.Get(EntryKey, Value) then
            exit('<none>');
        Entries.Remove(EntryKey);
        exit(Value);
    end;

    procedure Reset()
    begin
        Clear(Entries);
    end;
}

codeunit 78767 "BVE Describe"
{
    // Takes the record by var, so describing it adds no by-value hop of its own. Reads in this order: the current row, the
    // filter group it stands in, the filters of groups 0, 2 and 4, the key and its order, GetView, Count, the mark of the row,
    // MarkedOnly and the number of marked rows, then Next straight from the handed position, then Find('=').
    procedure Describe(var R: Record "BVE Row"): Text
    var
        Groups: List of [Integer];
        G: Integer;
        StartGroup: Integer;
        WasMarkedOnly: Boolean;
        MarkedCount: Integer;
        NextResult: Integer;
        Res: Text;
    begin
        Res := 'row=' + Format(R.Id) + '/' + R.Name + '/' + Format(R.Status) + '/' + Format(R.Amount);
        StartGroup := R.FilterGroup();
        Res += ' grp=' + Format(StartGroup);
        Groups.Add(0);
        Groups.Add(2);
        Groups.Add(4);
        foreach G in Groups do begin
            R.FilterGroup(G);
            Res += ' f' + Format(G) + '={' + R.GetFilters() + '}';
        end;
        R.FilterGroup(StartGroup);
        Res += ' key=' + R.CurrentKey() + ' asc=' + Format(R.Ascending());
        Res += ' view=' + R.GetView();
        Res += ' n=' + Format(R.Count());
        Res += ' mark=' + Format(R.Mark()) + ' mo=' + Format(R.MarkedOnly());
        WasMarkedOnly := R.MarkedOnly();
        R.MarkedOnly(true);
        MarkedCount := R.Count();
        R.MarkedOnly(WasMarkedOnly);
        Res += ' marked=' + Format(MarkedCount);
        NextResult := R.Next();
        Res += ' next=' + Format(NextResult) + ':' + Format(R.Id);
        Res += ' find==' + Format(R.Find('=')) + ':' + Format(R.Id);
        exit(Res);
    end;

    procedure DescribeVariant(V: Variant): Text
    var
        RecRef: RecordRef;
        Res: Text;
    begin
        Res := 'isrec=' + Format(V.IsRecord());
        RecRef.GetTable(V);
        Res += ' id=' + Format(RecRef.Field(1).Value) + ' name=' + Format(RecRef.Field(2).Value);
        Res += ' grp=' + Format(RecRef.FilterGroup());
        Res += ' f={' + RecRef.GetFilters() + '} fr3={' + RecRef.Field(3).GetFilter() + '}';
        RecRef.FilterGroup(2);
        Res += ' f2={' + RecRef.GetFilters() + '}';
        RecRef.FilterGroup(0);
        Res += ' key=' + Format(RecRef.CurrentKeyIndex()) + ' asc=' + Format(RecRef.Ascending());
        Res += ' view=' + RecRef.GetView();
        Res += ' n=' + Format(RecRef.Count());
        Res += ' next=' + Format(RecRef.Next()) + ':' + Format(RecRef.Field(1).Value);
        exit(Res);
    end;
}

codeunit 78768 "BVE Publisher"
{
    procedure RaiseTwo(var R: Record "BVE Row"; var Note: Text)
    begin
        OnTwo(Note, R);
    end;

    procedure RaiseThree(var R: Record "BVE Row"; var Note: Text)
    begin
        OnThree(7, Note, R);
    end;

    procedure RaiseMulti(var R: Record "BVE Row"; var Note: Text)
    begin
        OnMulti(Note, R);
    end;

    procedure RaiseVariant(var R: Record "BVE Row"; var Note: Text)
    begin
        OnVariant(Note, R);
    end;

    // The record reaches the raising routine by value and is raised from there.
    procedure RaiseTwoFromValue(R: Record "BVE Row"; var Note: Text)
    begin
        OnTwo(Note, R);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTwo(var Note: Text; R: Record "BVE Row")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnThree(Tag: Integer; var Note: Text; R: Record "BVE Row")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMulti(var Note: Text; R: Record "BVE Row")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVariant(var Note: Text; R: Record "BVE Row")
    begin
    end;
}

codeunit 78769 "BVE Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVE Publisher", 'OnTwo', '', false, false)]
    local procedure HandleTwo(var Note: Text; R: Record "BVE Row")
    var
        Describer: Codeunit "BVE Describe";
        Log: Codeunit "BVE Log";
    begin
        Note += '+two';
        Log.Put('two', Describer.Describe(R));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVE Publisher", 'OnThree', '', false, false)]
    local procedure HandleThree(Tag: Integer; var Note: Text; R: Record "BVE Row")
    var
        Describer: Codeunit "BVE Describe";
        Log: Codeunit "BVE Log";
    begin
        Note += '+three' + Format(Tag);
        Log.Put('three', Describer.Describe(R));
    end;

    [EventSubscriber(ObjectType::Table, Database::"BVE Row", 'OnTableThing', '', false, false)]
    local procedure HandleTable(var Note: Text; R: Record "BVE Row")
    var
        Describer: Codeunit "BVE Describe";
        Log: Codeunit "BVE Log";
    begin
        Note += '+table';
        Log.Put('table', Describer.Describe(R));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVE Publisher", 'OnVariant', '', false, false)]
    local procedure HandleVariant(var Note: Text; R: Record "BVE Row")
    var
        Describer: Codeunit "BVE Describe";
        Log: Codeunit "BVE Log";
    begin
        Note += '+variant';
        Log.Put('variant', Describer.DescribeVariant(R));
        Log.Put('variant after', 'row=' + Format(R.Id) + ' f={' + R.GetFilters() + '}');
    end;
}

codeunit 78770 "BVE Subscriber A"
{
    // Describes its copy, then changes it (filter, row, mark), so the other subscriber shows whether it shares that copy.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVE Publisher", 'OnMulti', '', false, false)]
    local procedure HandleMulti(var Note: Text; R: Record "BVE Row")
    var
        Describer: Codeunit "BVE Describe";
        Log: Codeunit "BVE Log";
    begin
        Note += '+A';
        Log.Put('A', Describer.Describe(R));
        R.SetRange(Name, 'A-NAME');
        R.FindFirst();
        R.Mark(true);
    end;
}

codeunit 78771 "BVE Subscriber B"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVE Publisher", 'OnMulti', '', false, false)]
    local procedure HandleMulti(var Note: Text; R: Record "BVE Row")
    var
        Describer: Codeunit "BVE Describe";
        Log: Codeunit "BVE Log";
    begin
        Note += '+B';
        Log.Put('B', Describer.Describe(R));
        R.SetRange(Name, 'D-NAME');
        R.FindFirst();
        R.Mark(true);
    end;
}

codeunit 78772 "BVE Event View Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Publisher: Codeunit "BVE Publisher";
        Log: Codeunit "BVE Log";

    // Rows 1 (C-NAME, Open, 30), 2 (B-NAME, Posted, 20), 3 (A-NAME, Open, 10), 4 (D-NAME, Posted, 40).
    local procedure Seed()
    var
        Row: Record "BVE Row";
    begin
        Row.DeleteAll();
        AddRow(1, 'C-NAME', Row.Status::Open, 30);
        AddRow(2, 'B-NAME', Row.Status::Posted, 20);
        AddRow(3, 'A-NAME', Row.Status::Open, 10);
        AddRow(4, 'D-NAME', Row.Status::Posted, 40);
        Log.Reset();
    end;

    local procedure AddRow(Id: Integer; Name: Text[20]; Status: Option; Amount: Decimal)
    var
        Row: Record "BVE Row";
    begin
        Row.Id := Id;
        Row.Name := Name;
        Row.Status := Status;
        Row.Amount := Amount;
        Row.Insert();
    end;

    local procedure ObserveCaller(var Observer: Codeunit "Probe Observer"; var Row: Record "BVE Row"; Note: Text)
    begin
        Observer.Observe('note', Note);
        Observer.Observe('caller after', 'row=' + Format(Row.Id) + ' grp=' + Format(Row.FilterGroup()) + ' view=' + Row.GetView()
            + ' mark=' + Format(Row.Mark()) + ' mo=' + Format(Row.MarkedOnly()));
    end;

    [Test]
    procedure EventView_TwoParams_Fresh_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVE Row";
        Note: Text;
    begin
        Seed();
        Note := 'x';
        Row.SetRange(Status, Row.Status::Open);
        Publisher.RaiseTwo(Row, Note);
        Observer.Observe('subscriber', Log.Take('two'));
        ObserveCaller(Observer, Row, Note);
        Observer.Expect('subscriber', 'row=0//Open/0 grp=0 f0={} f2={} f4={} key=Id asc=Yes view=VERSION(1) SORTING(Id) n=4 mark=No mo=No marked=0 next=1:1 find==Yes:1');
        Observer.Expect('note', 'x+two');
        Observer.Expect('caller after', 'row=0 grp=0 view=VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open)) mark=No mo=No');
        Observer.Verify();
    end;

    [Test]
    procedure EventView_TwoParams_FindSetNext_Group2_SetAscendingFalse()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVE Row";
        Note: Text;
    begin
        Seed();
        Note := 'x';
        Row.FilterGroup(2);
        Row.SetRange(Status, Row.Status::Open);
        Row.FilterGroup(0);
        Row.SetCurrentKey(Name);
        Row.SetAscending(Name, false);
        Row.FindSet();
        Row.Next();
        Publisher.RaiseTwo(Row, Note);
        Observer.Observe('subscriber', Log.Take('two'));
        ObserveCaller(Observer, Row, Note);
        Observer.Expect('subscriber', 'row=3/A-NAME/Open/10 grp=0 f0={} f2={} f4={} key=Id asc=Yes view=VERSION(1) SORTING(Id) n=4 mark=No mo=No marked=0 next=1:4 find==Yes:4');
        Observer.Expect('note', 'x+two');
        Observer.Expect('caller after', 'row=3 grp=0 view=VERSION(1) SORTING(Name) ORDER(Descending) mark=No mo=No');
        Observer.Verify();
    end;

    [Test]
    procedure EventView_ThreeParams_Fresh_Group2()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVE Row";
        Note: Text;
    begin
        Seed();
        Note := 'x';
        Row.FilterGroup(2);
        Row.SetFilter(Amount, '>15');
        Row.FilterGroup(0);
        Publisher.RaiseThree(Row, Note);
        Observer.Observe('subscriber', Log.Take('three'));
        ObserveCaller(Observer, Row, Note);
        Observer.Expect('subscriber', 'row=0//Open/0 grp=0 f0={} f2={} f4={} key=Id asc=Yes view=VERSION(1) SORTING(Id) n=4 mark=No mo=No marked=0 next=1:1 find==Yes:1');
        Observer.Expect('note', 'x+three7');
        Observer.Expect('caller after', 'row=0 grp=0 view=VERSION(1) SORTING(Id) mark=No mo=No');
        Observer.Verify();
    end;

    [Test]
    procedure EventView_ThreeParams_Get_Group4_Marked()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVE Row";
        Note: Text;
    begin
        Seed();
        Note := 'x';
        Row.FilterGroup(4);
        Row.SetFilter(Amount, '>15');
        Row.FilterGroup(0);
        Row.Get(4);
        Row.Mark(true);
        Row.Get(2);
        Row.Mark(true);
        Row.MarkedOnly(true);
        Publisher.RaiseThree(Row, Note);
        Observer.Observe('subscriber', Log.Take('three'));
        ObserveCaller(Observer, Row, Note);
        Observer.Expect('subscriber', 'row=2/B-NAME/Posted/20 grp=0 f0={} f2={} f4={} key=Id asc=Yes view=VERSION(1) SORTING(Id) n=4 mark=No mo=No marked=0 next=1:3 find==Yes:3');
        Observer.Expect('note', 'x+three7');
        Observer.Expect('caller after', 'row=2 grp=0 view=VERSION(1) SORTING(Id) mark=Yes mo=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure EventView_ThreeParams_FindMinus_Group0_AscendingFalse()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVE Row";
        Note: Text;
    begin
        Seed();
        Note := 'x';
        Row.SetFilter(Name, '<>B*');
        Row.Ascending(false);
        Row.Find('-');
        Publisher.RaiseThree(Row, Note);
        Observer.Observe('subscriber', Log.Take('three'));
        ObserveCaller(Observer, Row, Note);
        Observer.Expect('subscriber', 'row=4/D-NAME/Posted/40 grp=0 f0={} f2={} f4={} key=Id asc=Yes view=VERSION(1) SORTING(Id) n=4 mark=No mo=No marked=0 next=0:4 find==Yes:4');
        Observer.Expect('note', 'x+three7');
        Observer.Expect('caller after', 'row=4 grp=0 view=VERSION(1) SORTING(Id) ORDER(Descending) WHERE(Name=FILTER(<>B*)) mark=No mo=No');
        Observer.Verify();
    end;

    [Test]
    procedure EventView_TwoSubscribers_FindFirst_Group0_Group4_SetAscendingFalse()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVE Row";
        Note: Text;
    begin
        Seed();
        Note := 'x';
        Row.SetRange(Status, Row.Status::Open);
        Row.FilterGroup(4);
        Row.SetFilter(Amount, '<25');
        Row.FilterGroup(0);
        Row.SetCurrentKey(Name);
        Row.SetAscending(Name, false);
        Row.FindFirst();
        Row.Mark(true);
        Publisher.RaiseMulti(Row, Note);
        Observer.Observe('subscriber A', Log.Take('A'));
        Observer.Observe('subscriber B', Log.Take('B'));
        ObserveCaller(Observer, Row, Note);
        Observer.Expect('subscriber A', 'row=3/A-NAME/Open/10 grp=0 f0={} f2={} f4={} key=Id asc=Yes view=VERSION(1) SORTING(Id) n=4 mark=No mo=No marked=0 next=1:4 find==Yes:4');
        Observer.Expect('subscriber B', 'row=3/A-NAME/Open/10 grp=0 f0={} f2={} f4={} key=Id asc=Yes view=VERSION(1) SORTING(Id) n=4 mark=No mo=No marked=0 next=1:4 find==Yes:4');
        Observer.Expect('note', 'x+A+B');
        Observer.Expect('caller after', 'row=3 grp=0 view=VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open)) mark=Yes mo=No');
        Observer.Verify();
    end;

    [Test]
    procedure EventView_TablePublisher_Fresh_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVE Row";
        Note: Text;
    begin
        Seed();
        Note := 'x';
        Row.SetRange(Status, Row.Status::Open);
        Row.RaiseFromTable(Note);
        Observer.Observe('subscriber', Log.Take('table'));
        ObserveCaller(Observer, Row, Note);
        Observer.Expect('subscriber', 'row=0//Open/0 grp=0 f0={} f2={} f4={} key=Id asc=Yes view=VERSION(1) SORTING(Id) n=4 mark=No mo=No marked=0 next=1:1 find==Yes:1');
        Observer.Expect('note', 'x+table');
        Observer.Expect('caller after', 'row=0 grp=0 view=VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open)) mark=No mo=No');
        Observer.Verify();
    end;

    [Test]
    procedure EventView_TablePublisher_FindLast_Group2_SetAscendingFalse()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVE Row";
        Note: Text;
    begin
        Seed();
        Note := 'x';
        Row.FilterGroup(2);
        Row.SetRange(Status, Row.Status::Posted);
        Row.FilterGroup(0);
        Row.SetCurrentKey(Name);
        Row.SetAscending(Name, false);
        Row.FindLast();
        Row.RaiseFromTable(Note);
        Observer.Observe('subscriber', Log.Take('table'));
        ObserveCaller(Observer, Row, Note);
        Observer.Expect('subscriber', 'row=2/B-NAME/Posted/20 grp=0 f0={} f2={} f4={} key=Id asc=Yes view=VERSION(1) SORTING(Id) n=4 mark=No mo=No marked=0 next=1:3 find==Yes:3');
        Observer.Expect('note', 'x+table');
        Observer.Expect('caller after', 'row=2 grp=0 view=VERSION(1) SORTING(Name) ORDER(Descending) mark=No mo=No');
        Observer.Verify();
    end;

    [Test]
    procedure EventView_RaisedFromValueParameter_FindSet_Group4_SetAscendingFalse_Marked()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVE Row";
        Note: Text;
    begin
        Seed();
        Note := 'x';
        Row.FilterGroup(4);
        Row.SetFilter(Amount, '>15');
        Row.FilterGroup(0);
        Row.SetCurrentKey(Name);
        Row.SetAscending(Name, false);
        Row.FindSet();
        Row.Mark(true);
        Publisher.RaiseTwoFromValue(Row, Note);
        Observer.Observe('subscriber', Log.Take('two'));
        ObserveCaller(Observer, Row, Note);
        Observer.Expect('subscriber', 'row=4/D-NAME/Posted/40 grp=0 f0={} f2={} f4={} key=Id asc=Yes view=VERSION(1) SORTING(Id) n=4 mark=No mo=No marked=0 next=0:4 find==Yes:4');
        Observer.Expect('note', 'x+two');
        Observer.Expect('caller after', 'row=4 grp=0 view=VERSION(1) SORTING(Name) ORDER(Descending) mark=Yes mo=No');
        Observer.Verify();
    end;

    [Test]
    procedure EventView_RaisedFromValueParameter_Fresh_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVE Row";
        Note: Text;
    begin
        Seed();
        Note := 'x';
        Row.SetRange(Status, Row.Status::Posted);
        Publisher.RaiseTwoFromValue(Row, Note);
        Observer.Observe('subscriber', Log.Take('two'));
        ObserveCaller(Observer, Row, Note);
        Observer.Expect('subscriber', 'row=0//Open/0 grp=0 f0={} f2={} f4={} key=Id asc=Yes view=VERSION(1) SORTING(Id) n=4 mark=No mo=No marked=0 next=1:1 find==Yes:1');
        Observer.Expect('note', 'x+two');
        Observer.Expect('caller after', 'row=0 grp=0 view=VERSION(1) SORTING(Id) WHERE(Status=FILTER(Posted)) mark=No mo=No');
        Observer.Verify();
    end;

    [Test]
    procedure EventView_VariantGetTable_FindSet_Group0_Group2()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVE Row";
        Note: Text;
    begin
        Seed();
        Note := 'x';
        Row.SetRange(Status, Row.Status::Open);
        Row.FilterGroup(2);
        Row.SetFilter(Amount, '>5');
        Row.FilterGroup(0);
        Row.FindSet();
        Publisher.RaiseVariant(Row, Note);
        Observer.Observe('subscriber', Log.Take('variant'));
        Observer.Observe('subscriber after', Log.Take('variant after'));
        ObserveCaller(Observer, Row, Note);
        Observer.Expect('subscriber', 'isrec=Yes id=1 name=C-NAME grp=0 f={} fr3={} f2={} key=1 asc=Yes view=VERSION(1) SORTING(Id) n=4 next=1:2');
        Observer.Expect('subscriber after', 'row=1 f={}');
        Observer.Expect('note', 'x+variant');
        Observer.Expect('caller after', 'row=1 grp=0 view=VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open)) mark=No mo=No');
        Observer.Verify();
    end;

    [Test]
    procedure EventView_VariantGetTable_Fresh_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVE Row";
        Note: Text;
    begin
        Seed();
        Note := 'x';
        Row.SetRange(Status, Row.Status::Open);
        Publisher.RaiseVariant(Row, Note);
        Observer.Observe('subscriber', Log.Take('variant'));
        Observer.Observe('subscriber after', Log.Take('variant after'));
        ObserveCaller(Observer, Row, Note);
        Observer.Expect('subscriber', 'isrec=Yes id=0 name= grp=0 f={} fr3={} f2={} key=1 asc=Yes view=VERSION(1) SORTING(Id) n=4 next=1:1');
        Observer.Expect('subscriber after', 'row=0 f={}');
        Observer.Expect('note', 'x+variant');
        Observer.Expect('caller after', 'row=0 grp=0 view=VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open)) mark=No mo=No');
        Observer.Verify();
    end;
}
