// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-passing-parameters
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 78740..78756 (BVS Row, BVS Line, BVS Rows Report, BVS Log, BVS Reader,
//   BVS Publisher, BVS Single Publisher, BVS Subscriber, BVS Second Subscriber, BVS Manual Subscriber, BVS Table Subscriber,
//   BVS By Value Subscriber Tests)
// local object: the view (filters of every group, FlowFilters, key, order, marks, company) that an event subscriber's Record parameter
//   holds is what is under test.
// Probe (al-runner pull request 8314, follow-up of ByValueRecordView.al, test ByValue_EventSubscriberParameter): what a subscriber's
//   Record parameter holds of the caller's view in the event shapes next to the one ByValueRecordView.al measured (a local
//   IntegrationEvent(false, false) of a plain codeunit with a by-value Record parameter, a by-value subscriber, a filter in group 0).
//   One fact changes per cell:
//   - the publisher's parameter is var (codeunit publisher, and a table publisher raised with Rec), the subscriber's is by value;
//   - two by-value subscribers on the same event (a var subscriber parameter on a by-value publisher parameter does not compile:
//     AL0288, must-not-compile case 'subscriber-var-on-byvalue-publisher');
//   - a report publisher with IncludeSender (and without), raised with the data item; a codeunit publisher with IncludeSender;
//   - the publisher codeunit is SingleInstance; the publisher has CommitBehavior(Ignore);
//   - a record of another company (ChangeCompany) handed to a by-value and to a var publisher parameter;
//   - platform table events with a by-value Rec (and xRec): OnBeforeModifyEvent, OnAfterModifyEvent (and a var Rec next to it),
//     OnAfterInsertEvent, OnAfterDeleteEvent, OnAfterValidateEvent, OnAfterRenameEvent;
//   - a business event, an internal event, a manual subscriber bound with BindSubscription;
//   - filters in filter group 2 and -1 only (by-value and var publisher);
//   - more neighbors: two parameters of which the subscriber takes one, a public publisher called from the test, a temporary record.
//   "Group0" tests set one filter in group 0 (Status = Posted). "RichView" tests set a secondary key, descending order, a filter and a
//   FlowFilter in group 0, a filter in group 2, the current row 1 and a mark on it; the caller's own reading of that view is observed first.
//   The reader (BVS Reader.Describe) gets the parameter by var, so it reads the subscriber's own record: temp, same company, filters of
//   group 0, 2 and -1, Count, key, order, MarkedOnly, marked count, GetFilter and CopyFilter of the FlowFilter, the current Id and Name, and
//   the FlowField Total after CalcFields; GetView is observed next to it.
// Facts (measured on BC 27.5 and 29.0, the same in every test): a by-value subscriber Record parameter holds the field values of the
//   caller's current row (Id, Name; FlowField Total recalculated without the caller's FlowFilter: 12, not 5) and nothing of the view:
//   no filters in group 0, 2 or -1, no FlowFilter, primary key ascending, MarkedOnly No, no marks, filter group 0, GetView
//   'VERSION(1) SORTING(Id)'. This holds for every cell: a var or a by-value publisher parameter (codeunit and table publishers),
//   two by-value subscribers, a report publisher with and without IncludeSender, a codeunit publisher with IncludeSender, a
//   SingleInstance publisher, CommitBehavior(Ignore), a business event, an internal event, a manual subscriber bound with
//   BindSubscription, filters in group 2, -1 and 4 only, a caller left in filter group 2, two parameters, a public publisher called
//   from the test, and the by-value Rec and xRec of OnBefore/OnAfterModifyEvent, OnAfterInsertEvent, OnAfterDeleteEvent,
//   OnAfterValidateEvent and OnAfterRenameEvent.
//   - A temporary caller record: the by-value subscriber's record is NOT temporary (it counts the 3 rows of the real table) and
//     holds the caller's current row values (Id 5, T-FIVE).
//   - A record of another company (ChangeCompany): the subscriber's record is in the session company (it counts the 3 session rows)
//     and holds the other company's row values (Id 12, O-TWO). Asserted only when the host has a second company.
//   - A var Rec subscriber of OnAfterModifyEvent (next to the by-value ones) keeps the caller's whole view.
//   - The caller's own view is unchanged after the event in every cell.
//   - A var subscriber parameter on a by-value publisher parameter does not compile (AL0288, must-not-compile case 3180).
// BC versions: 27.5, 28.5, 29.0

table 78740 "BVS Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
        field(3; Status; Option) { OptionMembers = Open,Posted; }
        field(4; Amount; Decimal) { }
        field(5; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("BVS Line".Amt where(RowId = field(Id), Day = field("Day Filter")));
        }
        field(6; "Day Filter"; Integer) { FieldClass = FlowFilter; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByName; Name) { }
    }

    procedure RaiseTableVar()
    begin
        OnTableVar(Rec);
    end;

    procedure RaiseTableByValue()
    begin
        OnTableByValue(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTableVar(var R: Record "BVS Row")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTableByValue(R: Record "BVS Row")
    begin
    end;
}

table 78741 "BVS Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; RowId; Integer) { }
        field(3; Day; Integer) { }
        field(4; Amt; Decimal) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

report 78742 "BVS Rows Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "BVS Row")
        {
            trigger OnPreDataItem()
            var
                Reader: Codeunit "BVS Reader";
            begin
                Reader.Record('report item', Row);
                OnPreRowsSender(Row);
                OnPreRows(Row);
                CurrReport.Break();
            end;
        }
    }

    [IntegrationEvent(true, false)]
    local procedure OnPreRowsSender(R: Record "BVS Row")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreRows(R: Record "BVS Row")
    begin
    end;
}

codeunit 78743 "BVS Log"
{
    SingleInstance = true;

    var
        Entries: Dictionary of [Text, Text];

    procedure Put(Slot: Text; Value: Text)
    var
        Old: Text;
    begin
        if Entries.Get(Slot, Old) then
            Entries.Set(Slot, Old + ' | ' + Value)
        else
            Entries.Add(Slot, Value);
    end;

    procedure Take(Slot: Text): Text
    var
        Value: Text;
    begin
        if not Entries.Get(Slot, Value) then
            exit('(not raised)');
        Entries.Remove(Slot);
        exit(Value);
    end;

    procedure Reset()
    begin
        Clear(Entries);
    end;
}

codeunit 78744 "BVS Reader"
{
    // Reads the record it is given by var, so it reads the caller's own record. Leaves MarkedOnly and the filter group as it found them.
    procedure Describe(var R: Record "BVS Row"): Text
    var
        Other: Record "BVS Row";
        Result: Text;
        Group: Integer;
        WasMarkedOnly: Boolean;
    begin
        Group := R.FilterGroup();
        WasMarkedOnly := R.MarkedOnly();
        Result := 'temp=' + Format(R.IsTemporary()) + ' same=' + Format(R.CurrentCompany() = CompanyName());
        R.FilterGroup(0);
        Result += ' f={' + R.GetFilters() + '}';
        R.FilterGroup(2);
        Result += ' g2={' + R.GetFilters() + '}';
        R.FilterGroup(-1);
        Result += ' gm1={' + R.GetFilters() + '}';
        R.FilterGroup(Group);
        Result += ' grp=' + Format(Group) + ' n=' + Format(R.Count()) + ' key=' + R.CurrentKey() + ' asc=' + Format(R.Ascending());
        Result += ' mo=' + Format(WasMarkedOnly);
        R.MarkedOnly(true);
        Result += ' m=' + Format(R.Count());
        R.MarkedOnly(WasMarkedOnly);
        R.CopyFilter("Day Filter", Other."Day Filter");
        Result += ' ff={' + R.GetFilter("Day Filter") + '} cf={' + Other.GetFilters() + '}';
        R.CalcFields(Total);
        exit(Result + ' id=' + Format(R.Id) + ' name=' + R.Name + ' total=' + Format(R.Total));
    end;

    procedure Record(Slot: Text; var R: Record "BVS Row")
    var
        Log: Codeunit "BVS Log";
    begin
        Log.Put(Slot, Describe(R));
        Log.Put(Slot + ' view', R.GetView());
    end;
}

codeunit 78745 "BVS Publisher"
{
    procedure RaiseByValue(var R: Record "BVS Row")
    begin
        OnByValue(R);
    end;

    procedure RaiseVarPublisher(var R: Record "BVS Row")
    begin
        OnVarPublisher(R);
    end;

    procedure RaiseTwoSubscribers(var R: Record "BVS Row")
    begin
        OnTwoSubscribers(R);
    end;

    procedure RaiseSender(var R: Record "BVS Row")
    begin
        OnSender(R);
    end;

    procedure RaiseCommitIgnore(var R: Record "BVS Row")
    begin
        OnCommitIgnore(R);
    end;

    procedure RaiseBusiness(var R: Record "BVS Row")
    begin
        OnBusiness(R);
    end;

    procedure RaiseInternal(var R: Record "BVS Row")
    begin
        OnInternal(R);
    end;

    procedure RaiseManual(var R: Record "BVS Row")
    begin
        OnManual(R);
    end;

    procedure RaiseTwoParameters(var R: Record "BVS Row")
    begin
        OnTwoParameters(7, R);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnByValue(R: Record "BVS Row")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVarPublisher(var R: Record "BVS Row")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTwoSubscribers(R: Record "BVS Row")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnSender(R: Record "BVS Row")
    begin
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    [IntegrationEvent(false, false)]
    local procedure OnCommitIgnore(R: Record "BVS Row")
    begin
    end;

    [BusinessEvent(false)]
    local procedure OnBusiness(R: Record "BVS Row")
    begin
    end;

    [InternalEvent(false)]
    local procedure OnInternal(R: Record "BVS Row")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnManual(R: Record "BVS Row")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTwoParameters(Code: Integer; R: Record "BVS Row")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPublic(R: Record "BVS Row")
    begin
    end;
}

codeunit 78746 "BVS Single Publisher"
{
    SingleInstance = true;

    procedure RaiseSingle(var R: Record "BVS Row")
    begin
        OnSingle(R);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSingle(R: Record "BVS Row")
    begin
    end;
}

codeunit 78747 "BVS Subscriber"
{
    var
        Reader: Codeunit "BVS Reader";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVS Publisher", 'OnByValue', '', false, false)]
    local procedure HandleByValue(R: Record "BVS Row")
    begin
        Reader.Record('by value', R);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVS Publisher", 'OnVarPublisher', '', false, false)]
    local procedure HandleVarPublisher(R: Record "BVS Row")
    begin
        Reader.Record('var publisher', R);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVS Publisher", 'OnTwoSubscribers', '', false, false)]
    local procedure HandleTwoSubscribersByValue(R: Record "BVS Row")
    begin
        Reader.Record('two by value', R);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVS Publisher", 'OnSender', '', false, false)]
    local procedure HandleSender(var Sender: Codeunit "BVS Publisher"; R: Record "BVS Row")
    begin
        Reader.Record('sender', R);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVS Publisher", 'OnCommitIgnore', '', false, false)]
    local procedure HandleCommitIgnore(R: Record "BVS Row")
    begin
        Reader.Record('commit ignore', R);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVS Publisher", 'OnBusiness', '', false, false)]
    local procedure HandleBusiness(R: Record "BVS Row")
    begin
        Reader.Record('business', R);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVS Publisher", 'OnInternal', '', false, false)]
    local procedure HandleInternal(R: Record "BVS Row")
    begin
        Reader.Record('internal', R);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVS Publisher", 'OnTwoParameters', '', false, false)]
    local procedure HandleTwoParameters(R: Record "BVS Row")
    begin
        Reader.Record('two parameters', R);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVS Publisher", 'OnPublic', '', false, false)]
    local procedure HandlePublic(R: Record "BVS Row")
    begin
        Reader.Record('public', R);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVS Single Publisher", 'OnSingle', '', false, false)]
    local procedure HandleSingle(R: Record "BVS Row")
    begin
        Reader.Record('single', R);
    end;

    [EventSubscriber(ObjectType::Table, Database::"BVS Row", 'OnTableVar', '', false, false)]
    local procedure HandleTableVar(R: Record "BVS Row")
    begin
        Reader.Record('table var', R);
    end;

    [EventSubscriber(ObjectType::Table, Database::"BVS Row", 'OnTableByValue', '', false, false)]
    local procedure HandleTableByValue(R: Record "BVS Row")
    begin
        Reader.Record('table by value', R);
    end;

    [EventSubscriber(ObjectType::Report, Report::"BVS Rows Report", 'OnPreRowsSender', '', false, false)]
    local procedure HandleReportSender(var Sender: Report "BVS Rows Report"; R: Record "BVS Row")
    begin
        Reader.Record('report sender', R);
    end;

    [EventSubscriber(ObjectType::Report, Report::"BVS Rows Report", 'OnPreRows', '', false, false)]
    local procedure HandleReport(R: Record "BVS Row")
    begin
        Reader.Record('report', R);
    end;
}

codeunit 78748 "BVS Second Subscriber"
{
    var
        Reader: Codeunit "BVS Reader";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVS Publisher", 'OnTwoSubscribers', '', false, false)]
    local procedure HandleTwoSubscribersSecond(R: Record "BVS Row")
    begin
        Reader.Record('two second', R);
    end;
}

codeunit 78749 "BVS Manual Subscriber"
{
    EventSubscriberInstance = Manual;

    var
        Reader: Codeunit "BVS Reader";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVS Publisher", 'OnManual', '', false, false)]
    local procedure HandleManual(R: Record "BVS Row")
    begin
        Reader.Record('manual', R);
    end;
}

codeunit 78750 "BVS Table Subscriber"
{
    var
        Reader: Codeunit "BVS Reader";

    [EventSubscriber(ObjectType::Table, Database::"BVS Row", 'OnBeforeModifyEvent', '', false, false)]
    local procedure HandleBeforeModify(Rec: Record "BVS Row"; xRec: Record "BVS Row"; RunTrigger: Boolean)
    begin
        Reader.Record('before modify', Rec);
        Reader.Record('before modify xrec', xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"BVS Row", 'OnAfterModifyEvent', '', false, false)]
    local procedure HandleAfterModify(Rec: Record "BVS Row"; xRec: Record "BVS Row"; RunTrigger: Boolean)
    begin
        Reader.Record('after modify', Rec);
        Reader.Record('after modify xrec', xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"BVS Row", 'OnAfterModifyEvent', '', false, false)]
    local procedure HandleAfterModifyVar(var Rec: Record "BVS Row"; var xRec: Record "BVS Row"; RunTrigger: Boolean)
    begin
        Reader.Record('after modify var', Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"BVS Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure HandleAfterInsert(Rec: Record "BVS Row"; RunTrigger: Boolean)
    begin
        Reader.Record('after insert', Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"BVS Row", 'OnAfterDeleteEvent', '', false, false)]
    local procedure HandleAfterDelete(Rec: Record "BVS Row"; RunTrigger: Boolean)
    begin
        Reader.Record('after delete', Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"BVS Row", 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure HandleAfterValidateName(Rec: Record "BVS Row"; xRec: Record "BVS Row"; CurrFieldNo: Integer)
    begin
        Reader.Record('after validate', Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"BVS Row", 'OnAfterRenameEvent', '', false, false)]
    local procedure HandleAfterRename(Rec: Record "BVS Row"; xRec: Record "BVS Row"; RunTrigger: Boolean)
    begin
        Reader.Record('after rename', Rec);
    end;
}

codeunit 78756 "BVS By Value Subscriber Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Publisher: Codeunit "BVS Publisher";
        Reader: Codeunit "BVS Reader";
        Log: Codeunit "BVS Log";

    // Rows 1 (C-NAME, Open, 30), 2 (B-NAME, Posted, 20), 3 (A-NAME, Open, 10); lines of row 1: day 1 amount 5, day 2 amount 7.
    local procedure Seed()
    var
        Row: Record "BVS Row";
        Line: Record "BVS Line";
    begin
        Row.DeleteAll();
        Line.DeleteAll();
        AddRow(Row, 1, 'C-NAME', Row.Status::Open, 30);
        AddRow(Row, 2, 'B-NAME', Row.Status::Posted, 20);
        AddRow(Row, 3, 'A-NAME', Row.Status::Open, 10);
        AddLine(1, 1, 1, 5);
        AddLine(2, 1, 2, 7);
        Log.Reset();
    end;

    local procedure AddRow(var Row: Record "BVS Row"; Id: Integer; Name: Text[20]; Status: Option; Amount: Decimal)
    begin
        Row.Init();
        Row.Id := Id;
        Row.Name := Name;
        Row.Status := Status;
        Row.Amount := Amount;
        Row.Insert();
    end;

    local procedure AddLine(Id: Integer; RowId: Integer; Day: Integer; Amt: Decimal)
    var
        Line: Record "BVS Line";
    begin
        Line.Id := Id;
        Line.RowId := RowId;
        Line.Day := Day;
        Line.Amt := Amt;
        Line.Insert();
    end;

    local procedure SetGroup0(var Row: Record "BVS Row")
    begin
        Row.SetRange(Status, Row.Status::Posted);
    end;

    // Key ByName descending, Status = Open and Day Filter = 1 in group 0, Amount > 15 in group 2, current row 1, row 1 marked.
    local procedure SetRichView(var Row: Record "BVS Row")
    begin
        Row.SetCurrentKey(Name);
        Row.Ascending(false);
        Row.SetRange(Status, Row.Status::Open);
        Row.SetFilter("Day Filter", '1');
        Row.FilterGroup(2);
        Row.SetFilter(Amount, '>15');
        Row.FilterGroup(0);
        Row.Get(1);
        Row.Mark(true);
    end;

    local procedure ObserveCaller(var Observer: Codeunit "Probe Observer"; var Row: Record "BVS Row")
    begin
        Observer.Observe('caller after', 'f={' + Row.GetFilters() + '} n=' + Format(Row.Count()) + ' grp=' + Format(Row.FilterGroup()));
    end;

    local procedure ObserveSlot(var Observer: Codeunit "Probe Observer"; Slot: Text)
    begin
        Observer.Observe(Slot, Log.Take(Slot));
        Observer.Observe(Slot + ' view', Log.Take(Slot + ' view'));
    end;

    [Test]
    procedure Measured_ByValue_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetGroup0(Row);
        Publisher.RaiseByValue(Row);
        ObserveSlot(Observer, 'by value');
        ObserveCaller(Observer, Row);
        Observer.Expect('by value', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('by value view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure Measured_ByValue_RichView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetRichView(Row);
        Observer.Observe('caller', Reader.Describe(Row));
        Observer.Observe('caller view', Row.GetView());
        Publisher.RaiseByValue(Row);
        ObserveSlot(Observer, 'by value');
        ObserveCaller(Observer, Row);
        Observer.Expect('caller', 'temp=No same=Yes f={Status: Open, Day Filter: 1} g2={Amount: >15} gm1={} grp=0 n=1 key=Name asc=No mo=No m=1 ff={1} cf={Day Filter: 1} id=1 name=C-NAME total=5');
        Observer.Expect('caller view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open),Day Filter=FILTER(1))');
        Observer.Expect('by value', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=1 name=C-NAME total=12');
        Observer.Expect('by value view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Open, Day Filter: 1} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure VarPublisher_ByValueSubscriber_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetGroup0(Row);
        Publisher.RaiseVarPublisher(Row);
        ObserveSlot(Observer, 'var publisher');
        ObserveCaller(Observer, Row);
        Observer.Expect('var publisher', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('var publisher view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure VarPublisher_ByValueSubscriber_RichView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetRichView(Row);
        Observer.Observe('caller', Reader.Describe(Row));
        Observer.Observe('caller view', Row.GetView());
        Publisher.RaiseVarPublisher(Row);
        ObserveSlot(Observer, 'var publisher');
        ObserveCaller(Observer, Row);
        Observer.Expect('caller', 'temp=No same=Yes f={Status: Open, Day Filter: 1} g2={Amount: >15} gm1={} grp=0 n=1 key=Name asc=No mo=No m=1 ff={1} cf={Day Filter: 1} id=1 name=C-NAME total=5');
        Observer.Expect('caller view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open),Day Filter=FILTER(1))');
        Observer.Expect('var publisher', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=1 name=C-NAME total=12');
        Observer.Expect('var publisher view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Open, Day Filter: 1} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableVarPublisher_ByValueSubscriber_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetGroup0(Row);
        Row.RaiseTableVar();
        ObserveSlot(Observer, 'table var');
        ObserveCaller(Observer, Row);
        Observer.Expect('table var', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('table var view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableVarPublisher_ByValueSubscriber_RichView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetRichView(Row);
        Observer.Observe('caller', Reader.Describe(Row));
        Observer.Observe('caller view', Row.GetView());
        Row.RaiseTableVar();
        ObserveSlot(Observer, 'table var');
        ObserveCaller(Observer, Row);
        Observer.Expect('caller', 'temp=No same=Yes f={Status: Open, Day Filter: 1} g2={Amount: >15} gm1={} grp=0 n=1 key=Name asc=No mo=No m=1 ff={1} cf={Day Filter: 1} id=1 name=C-NAME total=5');
        Observer.Expect('caller view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open),Day Filter=FILTER(1))');
        Observer.Expect('table var', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=1 name=C-NAME total=12');
        Observer.Expect('table var view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Open, Day Filter: 1} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableByValuePublisher_ByValueSubscriber_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetGroup0(Row);
        Row.RaiseTableByValue();
        ObserveSlot(Observer, 'table by value');
        ObserveCaller(Observer, Row);
        Observer.Expect('table by value', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('table by value view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableByValuePublisher_ByValueSubscriber_RichView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetRichView(Row);
        Observer.Observe('caller', Reader.Describe(Row));
        Observer.Observe('caller view', Row.GetView());
        Row.RaiseTableByValue();
        ObserveSlot(Observer, 'table by value');
        ObserveCaller(Observer, Row);
        Observer.Expect('caller', 'temp=No same=Yes f={Status: Open, Day Filter: 1} g2={Amount: >15} gm1={} grp=0 n=1 key=Name asc=No mo=No m=1 ff={1} cf={Day Filter: 1} id=1 name=C-NAME total=5');
        Observer.Expect('caller view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open),Day Filter=FILTER(1))');
        Observer.Expect('table by value', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=1 name=C-NAME total=12');
        Observer.Expect('table by value view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Open, Day Filter: 1} n=1 grp=0');
        Observer.Verify();
    end;



    [Test]
    procedure ByValuePublisher_TwoSubscribers_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetGroup0(Row);
        Publisher.RaiseTwoSubscribers(Row);
        ObserveSlot(Observer, 'two by value');
        ObserveSlot(Observer, 'two second');
        ObserveCaller(Observer, Row);
        Observer.Expect('two by value', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('two by value view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('two second', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('two second view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportPublisher_IncludeSender_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
        Rep: Report "BVS Rows Report";
    begin
        Seed();
        SetGroup0(Row);
        Rep.SetTableView(Row);
        Rep.UseRequestPage(false);
        Rep.Run();
        ObserveSlot(Observer, 'report item');
        ObserveSlot(Observer, 'report sender');
        ObserveCaller(Observer, Row);
        Observer.Expect('report item', 'temp=No same=Yes f={Status: Posted} g2={} gm1={} grp=0 n=1 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('report item view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Posted))');
        Observer.Expect('report sender', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('report sender view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportPublisher_IncludeSender_RichView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
        Rep: Report "BVS Rows Report";
    begin
        Seed();
        SetRichView(Row);
        Observer.Observe('caller', Reader.Describe(Row));
        Observer.Observe('caller view', Row.GetView());
        Rep.SetTableView(Row);
        Rep.UseRequestPage(false);
        Rep.Run();
        ObserveSlot(Observer, 'report item');
        ObserveSlot(Observer, 'report sender');
        ObserveCaller(Observer, Row);
        Observer.Expect('caller', 'temp=No same=Yes f={Status: Open, Day Filter: 1} g2={Amount: >15} gm1={} grp=0 n=1 key=Name asc=No mo=No m=1 ff={1} cf={Day Filter: 1} id=1 name=C-NAME total=5');
        Observer.Expect('caller view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open),Day Filter=FILTER(1))');
        Observer.Expect('report item', 'temp=No same=Yes f={Status: Open, Day Filter: 1} g2={Amount: >15} gm1={} grp=0 n=1 key=Name asc=No mo=No m=1 ff={1} cf={Day Filter: 1} id=0 name= total=0');
        Observer.Expect('report item view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open),Day Filter=FILTER(1))');
        Observer.Expect('report sender', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('report sender view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Open, Day Filter: 1} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ReportPublisher_NoSender_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
        Rep: Report "BVS Rows Report";
    begin
        Seed();
        SetGroup0(Row);
        Rep.SetTableView(Row);
        Rep.UseRequestPage(false);
        Rep.Run();
        ObserveSlot(Observer, 'report item');
        ObserveSlot(Observer, 'report');
        ObserveCaller(Observer, Row);
        Observer.Expect('report item', 'temp=No same=Yes f={Status: Posted} g2={} gm1={} grp=0 n=1 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('report item view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Posted))');
        Observer.Expect('report', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('report view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitPublisher_IncludeSender_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetGroup0(Row);
        Publisher.RaiseSender(Row);
        ObserveSlot(Observer, 'sender');
        ObserveCaller(Observer, Row);
        Observer.Expect('sender', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('sender view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure SingleInstancePublisher_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
        SinglePublisher: Codeunit "BVS Single Publisher";
    begin
        Seed();
        SetGroup0(Row);
        SinglePublisher.RaiseSingle(Row);
        ObserveSlot(Observer, 'single');
        ObserveCaller(Observer, Row);
        Observer.Expect('single', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('single view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure SingleInstancePublisher_RichView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
        SinglePublisher: Codeunit "BVS Single Publisher";
    begin
        Seed();
        SetRichView(Row);
        Observer.Observe('caller', Reader.Describe(Row));
        Observer.Observe('caller view', Row.GetView());
        SinglePublisher.RaiseSingle(Row);
        ObserveSlot(Observer, 'single');
        ObserveCaller(Observer, Row);
        Observer.Expect('caller', 'temp=No same=Yes f={Status: Open, Day Filter: 1} g2={Amount: >15} gm1={} grp=0 n=1 key=Name asc=No mo=No m=1 ff={1} cf={Day Filter: 1} id=1 name=C-NAME total=5');
        Observer.Expect('caller view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open),Day Filter=FILTER(1))');
        Observer.Expect('single', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=1 name=C-NAME total=12');
        Observer.Expect('single view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Open, Day Filter: 1} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure CommitIgnorePublisher_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetGroup0(Row);
        Publisher.RaiseCommitIgnore(Row);
        ObserveSlot(Observer, 'commit ignore');
        ObserveCaller(Observer, Row);
        Observer.Expect('commit ignore', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('commit ignore view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure CommitIgnorePublisher_RichView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetRichView(Row);
        Observer.Observe('caller', Reader.Describe(Row));
        Observer.Observe('caller view', Row.GetView());
        Publisher.RaiseCommitIgnore(Row);
        ObserveSlot(Observer, 'commit ignore');
        ObserveCaller(Observer, Row);
        Observer.Expect('caller', 'temp=No same=Yes f={Status: Open, Day Filter: 1} g2={Amount: >15} gm1={} grp=0 n=1 key=Name asc=No mo=No m=1 ff={1} cf={Day Filter: 1} id=1 name=C-NAME total=5');
        Observer.Expect('caller view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open),Day Filter=FILTER(1))');
        Observer.Expect('commit ignore', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=1 name=C-NAME total=12');
        Observer.Expect('commit ignore view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Open, Day Filter: 1} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure BusinessEvent_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetGroup0(Row);
        Publisher.RaiseBusiness(Row);
        ObserveSlot(Observer, 'business');
        ObserveCaller(Observer, Row);
        Observer.Expect('business', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('business view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure BusinessEvent_RichView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetRichView(Row);
        Observer.Observe('caller', Reader.Describe(Row));
        Observer.Observe('caller view', Row.GetView());
        Publisher.RaiseBusiness(Row);
        ObserveSlot(Observer, 'business');
        ObserveCaller(Observer, Row);
        Observer.Expect('caller', 'temp=No same=Yes f={Status: Open, Day Filter: 1} g2={Amount: >15} gm1={} grp=0 n=1 key=Name asc=No mo=No m=1 ff={1} cf={Day Filter: 1} id=1 name=C-NAME total=5');
        Observer.Expect('caller view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open),Day Filter=FILTER(1))');
        Observer.Expect('business', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=1 name=C-NAME total=12');
        Observer.Expect('business view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Open, Day Filter: 1} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure InternalEvent_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetGroup0(Row);
        Publisher.RaiseInternal(Row);
        ObserveSlot(Observer, 'internal');
        ObserveCaller(Observer, Row);
        Observer.Expect('internal', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('internal view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ManualSubscriber_Bound_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
        Manual: Codeunit "BVS Manual Subscriber";
    begin
        Seed();
        SetGroup0(Row);
        BindSubscription(Manual);
        Publisher.RaiseManual(Row);
        UnbindSubscription(Manual);
        ObserveSlot(Observer, 'manual');
        ObserveCaller(Observer, Row);
        Observer.Expect('manual', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('manual view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ManualSubscriber_Bound_RichView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
        Manual: Codeunit "BVS Manual Subscriber";
    begin
        Seed();
        SetRichView(Row);
        Observer.Observe('caller', Reader.Describe(Row));
        Observer.Observe('caller view', Row.GetView());
        BindSubscription(Manual);
        Publisher.RaiseManual(Row);
        UnbindSubscription(Manual);
        ObserveSlot(Observer, 'manual');
        ObserveCaller(Observer, Row);
        Observer.Expect('caller', 'temp=No same=Yes f={Status: Open, Day Filter: 1} g2={Amount: >15} gm1={} grp=0 n=1 key=Name asc=No mo=No m=1 ff={1} cf={Day Filter: 1} id=1 name=C-NAME total=5');
        Observer.Expect('caller view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open),Day Filter=FILTER(1))');
        Observer.Expect('manual', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=1 name=C-NAME total=12');
        Observer.Expect('manual view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Open, Day Filter: 1} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValuePublisher_Group2Filter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        Row.FilterGroup(2);
        Row.SetRange(Status, Row.Status::Posted);
        Row.FilterGroup(0);
        Publisher.RaiseByValue(Row);
        ObserveSlot(Observer, 'by value');
        ObserveCaller(Observer, Row);
        Observer.Expect('by value', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('by value view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValuePublisher_GroupMinus1Filter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        Row.FilterGroup(-1);
        Row.SetFilter(Amount, '>15');
        Row.FilterGroup(0);
        Publisher.RaiseByValue(Row);
        ObserveSlot(Observer, 'by value');
        ObserveCaller(Observer, Row);
        Observer.Expect('by value', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('by value view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={} n=2 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValuePublisher_Group4Filter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        Row.FilterGroup(4);
        Row.SetRange(Status, Row.Status::Posted);
        Row.FilterGroup(0);
        Publisher.RaiseByValue(Row);
        ObserveSlot(Observer, 'by value');
        ObserveCaller(Observer, Row);
        Observer.Expect('by value', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('by value view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure ByValuePublisher_CallerInGroup2()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        Row.FilterGroup(2);
        Row.SetRange(Status, Row.Status::Posted);
        Publisher.RaiseByValue(Row);
        ObserveSlot(Observer, 'by value');
        Row.FilterGroup(0);
        ObserveCaller(Observer, Row);
        Observer.Expect('by value', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('by value view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure VarPublisher_Group2Filter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        Row.FilterGroup(2);
        Row.SetRange(Status, Row.Status::Posted);
        Row.FilterGroup(0);
        Publisher.RaiseVarPublisher(Row);
        ObserveSlot(Observer, 'var publisher');
        ObserveCaller(Observer, Row);
        Observer.Expect('var publisher', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('var publisher view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure VarPublisher_GroupMinus1Filter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        Row.FilterGroup(-1);
        Row.SetFilter(Amount, '>15');
        Row.FilterGroup(0);
        Publisher.RaiseVarPublisher(Row);
        ObserveSlot(Observer, 'var publisher');
        ObserveCaller(Observer, Row);
        Observer.Expect('var publisher', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('var publisher view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={} n=2 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure TwoParameters_SubscriberTakesRecord_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetGroup0(Row);
        Publisher.RaiseTwoParameters(Row);
        ObserveSlot(Observer, 'two parameters');
        ObserveCaller(Observer, Row);
        Observer.Expect('two parameters', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('two parameters view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure PublicPublisher_CalledFromTest_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetGroup0(Row);
        Publisher.OnPublic(Row);
        ObserveSlot(Observer, 'public');
        ObserveCaller(Observer, Row);
        Observer.Expect('public', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=0 name= total=0');
        Observer.Expect('public view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure Temporary_ByValuePublisher_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
        TempRow: Record "BVS Row" temporary;
    begin
        Seed();
        TempRow.Id := 1;
        TempRow.Name := 'T-ONE';
        TempRow.Insert();
        TempRow.Id := 2;
        TempRow.Name := 'T-TWO';
        TempRow.Status := TempRow.Status::Posted;
        TempRow.Insert();
        TempRow.Id := 5;
        TempRow.Name := 'T-FIVE';
        TempRow.Status := TempRow.Status::Posted;
        TempRow.Insert();
        TempRow.SetRange(Status, TempRow.Status::Posted);
        Publisher.RaiseByValue(TempRow);
        ObserveSlot(Observer, 'by value');
        ObserveCaller(Observer, TempRow);
        Observer.Expect('by value', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=5 name=T-FIVE total=0');
        Observer.Expect('by value view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=2 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure Temporary_VarPublisher_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
        TempRow: Record "BVS Row" temporary;
    begin
        Seed();
        TempRow.Id := 1;
        TempRow.Name := 'T-ONE';
        TempRow.Insert();
        TempRow.Id := 2;
        TempRow.Name := 'T-TWO';
        TempRow.Status := TempRow.Status::Posted;
        TempRow.Insert();
        TempRow.Id := 5;
        TempRow.Name := 'T-FIVE';
        TempRow.Status := TempRow.Status::Posted;
        TempRow.Insert();
        TempRow.SetRange(Status, TempRow.Status::Posted);
        Publisher.RaiseVarPublisher(TempRow);
        ObserveSlot(Observer, 'var publisher');
        ObserveCaller(Observer, TempRow);
        Observer.Expect('var publisher', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=5 name=T-FIVE total=0');
        Observer.Expect('var publisher view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=2 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure OtherCompany_ByValuePublisher_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
        Other: Record "BVS Row";
        Found: Boolean;
    begin
        Seed();
        Company.SetFilter(Name, '<>%1', CompanyName());
        Found := Company.FindFirst();
        if Found then begin
            // Rows of the other company: 11 (Open) and 12 (Posted); the session company keeps rows 1, 2, 3.
            Other.ChangeCompany(Company.Name);
            Other.DeleteAll();
            AddRow(Other, 11, 'O-ONE', Other.Status::Open, 5);
            AddRow(Other, 12, 'O-TWO', Other.Status::Posted, 6);
            Log.Reset();
            Other.SetRange(Status, Other.Status::Posted);
            Other.FindFirst();
            Publisher.RaiseByValue(Other);
            ObserveSlot(Observer, 'by value');
            ObserveCaller(Observer, Other);
            Other.Reset();
            Other.DeleteAll();
        end;
        // A host with one company measures nothing here (the other-company cell needs a second company).
        if Found then begin
            Observer.Expect('by value', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=12 name=O-TWO total=0');
            Observer.Expect('by value view', 'VERSION(1) SORTING(Id)');
            Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        end;
        Observer.Verify();
    end;

    [Test]
    procedure OtherCompany_VarPublisher_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
        Other: Record "BVS Row";
        Found: Boolean;
    begin
        Seed();
        Company.SetFilter(Name, '<>%1', CompanyName());
        Found := Company.FindFirst();
        if Found then begin
            // Rows of the other company: 11 (Open) and 12 (Posted); the session company keeps rows 1, 2, 3.
            Other.ChangeCompany(Company.Name);
            Other.DeleteAll();
            AddRow(Other, 11, 'O-ONE', Other.Status::Open, 5);
            AddRow(Other, 12, 'O-TWO', Other.Status::Posted, 6);
            Log.Reset();
            Other.SetRange(Status, Other.Status::Posted);
            Other.FindFirst();
            Publisher.RaiseVarPublisher(Other);
            ObserveSlot(Observer, 'var publisher');
            ObserveCaller(Observer, Other);
            Other.Reset();
            Other.DeleteAll();
        end;
        // A host with one company measures nothing here (the other-company cell needs a second company).
        if Found then begin
            Observer.Expect('var publisher', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=12 name=O-TWO total=0');
            Observer.Expect('var publisher view', 'VERSION(1) SORTING(Id)');
            Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        end;
        Observer.Verify();
    end;

    [Test]
    procedure TableEvent_Modify_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Open);
        Row.FindLast();
        Row.Name := 'Z-NAME';
        Row.Modify(false);
        ObserveSlot(Observer, 'before modify');
        ObserveSlot(Observer, 'before modify xrec');
        ObserveSlot(Observer, 'after modify');
        ObserveSlot(Observer, 'after modify xrec');
        ObserveSlot(Observer, 'after modify var');
        ObserveCaller(Observer, Row);
        Observer.Expect('before modify', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=3 name=Z-NAME total=0');
        Observer.Expect('before modify view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('before modify xrec', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=3 name=Z-NAME total=0');
        Observer.Expect('before modify xrec view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('after modify', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=3 name=Z-NAME total=0');
        Observer.Expect('after modify view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('after modify xrec', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=3 name=Z-NAME total=0');
        Observer.Expect('after modify xrec view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('after modify var', 'temp=No same=Yes f={Status: Open} g2={} gm1={} grp=0 n=2 key=Id asc=Yes mo=No m=0 ff={} cf={} id=3 name=Z-NAME total=0');
        Observer.Expect('after modify var view', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Open))');
        Observer.Expect('caller after', 'f={Status: Open} n=2 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableEvent_Modify_RichView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetRichView(Row);
        Observer.Observe('caller', Reader.Describe(Row));
        Log.Reset();
        Row.Name := 'Z-NAME';
        Row.Modify(true);
        ObserveSlot(Observer, 'before modify');
        ObserveSlot(Observer, 'after modify');
        ObserveSlot(Observer, 'after modify var');
        ObserveCaller(Observer, Row);
        Observer.Expect('caller', 'temp=No same=Yes f={Status: Open, Day Filter: 1} g2={Amount: >15} gm1={} grp=0 n=1 key=Name asc=No mo=No m=1 ff={1} cf={Day Filter: 1} id=1 name=C-NAME total=5');
        Observer.Expect('before modify', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=1 name=Z-NAME total=12');
        Observer.Expect('before modify view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('after modify', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=1 name=Z-NAME total=12');
        Observer.Expect('after modify view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('after modify var', 'temp=No same=Yes f={Status: Open, Day Filter: 1} g2={Amount: >15} gm1={} grp=0 n=1 key=Name asc=No mo=No m=1 ff={1} cf={Day Filter: 1} id=1 name=Z-NAME total=5');
        Observer.Expect('after modify var view', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Status=FILTER(Open),Day Filter=FILTER(1))');
        Observer.Expect('caller after', 'f={Status: Open, Day Filter: 1} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableEvent_Insert_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetGroup0(Row);
        Row.Init();
        Row.Id := 4;
        Row.Name := 'D-NAME';
        Row.Insert(false);
        ObserveSlot(Observer, 'after insert');
        ObserveCaller(Observer, Row);
        Observer.Expect('after insert', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=4 key=Id asc=Yes mo=No m=0 ff={} cf={} id=4 name=D-NAME total=0');
        Observer.Expect('after insert view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=1 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableEvent_Delete_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        SetGroup0(Row);
        Row.FindFirst();
        Row.Delete(false);
        ObserveSlot(Observer, 'after delete');
        ObserveCaller(Observer, Row);
        Observer.Expect('after delete', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=2 key=Id asc=Yes mo=No m=0 ff={} cf={} id=2 name=B-NAME total=0');
        Observer.Expect('after delete view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Posted} n=0 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableEvent_Validate_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Open);
        Row.FindFirst();
        Row.Validate(Name, 'V-NAME');
        ObserveSlot(Observer, 'after validate');
        ObserveCaller(Observer, Row);
        Observer.Expect('after validate', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=1 name=V-NAME total=12');
        Observer.Expect('after validate view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Open} n=2 grp=0');
        Observer.Verify();
    end;

    [Test]
    procedure TableEvent_Rename_Group0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BVS Row";
    begin
        Seed();
        Row.SetRange(Status, Row.Status::Open);
        Row.FindLast();
        Row.Rename(9);
        ObserveSlot(Observer, 'after rename');
        ObserveCaller(Observer, Row);
        Observer.Expect('after rename', 'temp=No same=Yes f={} g2={} gm1={} grp=0 n=3 key=Id asc=Yes mo=No m=0 ff={} cf={} id=9 name=A-NAME total=0');
        Observer.Expect('after rename view', 'VERSION(1) SORTING(Id)');
        Observer.Expect('caller after', 'f={Status: Open} n=2 grp=0');
        Observer.Verify();
    end;
}
