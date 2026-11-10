// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-part-control
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 99650-99653
// Probe: observe-only. al-runner issue 6924 (a customer extension on Sales Credit Memo). A factbox part raises an IntegrationEvent(true, false) with the
//   sender from OnAfterGetCurrRecord. The subscriber, a SingleInstance codeunit, calls a procedure of a global Page variable of its own, and that procedure
//   reads CurrPage.<part>.Page. The global holds the host page that another subscriber took from `sender` of the host's own event, or it was never assigned.
// Facts: what a procedure of a held host page reads and calls through CurrPage.<part>.Page (the part's Rec, a part procedure that only counts, the part's
//   own variables) while the TestPage that opened the host is open, in the same test after TestPage.Close, in the next test of the codeunit (the held
//   page is still the first instance), and from the factbox's OnAfterGetCurrRecord event while a second TestPage of the same host opens. Also the shape
//   where the variable was never assigned (pinned by NeverRanReadRec.al, observed again here as the control).
// BC versions: 27, 28, 29

table 99650 "LT HS Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 99650 "LT HS Holder"
{
    SingleInstance = true;

    var
        Held: Page "LT HS Host";
        Assign: Boolean;
        Reach: Boolean;
        Log: Text;

    procedure Setup(AssignSender: Boolean; ReachFromFactbox: Boolean)
    begin
        Assign := AssignSender;
        Reach := ReachFromFactbox;
        Log := '';
    end;

    procedure TakeLog(): Text
    var
        R: Text;
    begin
        R := Log;
        Log := '';
        exit(R);
    end;

    procedure Add(T: Text)
    begin
        Log += T + ';';
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT HS Host", 'OnOpened', '', false, false)]
    local procedure HostOpened(var sender: Page "LT HS Host")
    begin
        if Assign then
            Held := sender;
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT HS Fact", 'OnFactRow', '', false, false)]
    local procedure FactRow(var sender: Page "LT HS Fact"; RowId: Integer)
    var
        Touched: Integer;
        Seen: Text;
    begin
        Add('fact(' + Format(RowId) + ')');
        if not Reach then
            exit;
        if TryTouch(Touched) then
            Add('touch=' + Format(Touched))
        else
            Add('touch-error=' + GetLastErrorCode() + '|' + GetLastErrorText());
        if TryRead(Seen) then
            Add('read=' + Seen)
        else
            Add('read-error=' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    [TryFunction]
    procedure TryTouch(var Result: Integer)
    begin
        Result := Held.PartTouch();
    end;

    [TryFunction]
    procedure TryRead(var Result: Text)
    begin
        Result := Held.PartRead();
    end;

    [TryFunction]
    procedure TryMark(var Result: Text)
    begin
        Held.PartSetMark('m');
        Result := Held.PartGetMark();
    end;

    [TryFunction]
    procedure TryHostRead(var Result: Text)
    begin
        Result := Held.HostRead();
    end;
}

page 99651 "LT HS Part"
{
    PageType = ListPart;
    SourceTable = "LT HS Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        Touches: Integer;
        Mark: Text;

    procedure ReadRec(): Text
    begin
        exit('id=' + Format(Rec.Id) + ' name=' + Rec.Name + ' count=' + Format(Rec.Count()));
    end;

    procedure Touch(): Integer
    begin
        Touches += 1;
        exit(Touches);
    end;

    procedure SetMark(NewMark: Text)
    begin
        Mark := NewMark;
    end;

    procedure GetMark(): Text
    begin
        exit(Mark);
    end;
}

page 99652 "LT HS Fact"
{
    PageType = CardPart;
    SourceTable = "LT HS Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(IdF; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        OnFactRow(Rec.Id);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFactRow(RowId: Integer)
    begin
    end;
}

page 99653 "LT HS Host"
{
    PageType = Card;
    SourceTable = "LT HS Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdF; Rec.Id) { ApplicationArea = All; }
            part(Lines; "LT HS Part")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
        area(FactBoxes)
        {
            part(Fact; "LT HS Fact")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }

    trigger OnOpenPage()
    begin
        OnOpened();
    end;

    procedure PartRead(): Text
    begin
        exit(CurrPage.Lines.Page.ReadRec());
    end;

    procedure PartTouch(): Integer
    begin
        exit(CurrPage.Lines.Page.Touch());
    end;

    procedure PartSetMark(NewMark: Text)
    begin
        CurrPage.Lines.Page.SetMark(NewMark);
    end;

    procedure PartGetMark(): Text
    begin
        exit(CurrPage.Lines.Page.GetMark());
    end;

    procedure HostRead(): Text
    begin
        exit('id=' + Format(Rec.Id) + ' name=' + Rec.Name);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnOpened()
    begin
    end;
}

codeunit 99651 "LT HS Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT HS Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
    end;

    local procedure ObserveReach(Prefix: Text)
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT HS Holder";
        Touched: Integer;
        Text1: Text;
    begin
        if Holder.TryTouch(Touched) then
            Observer.Observe(Prefix + '.touch', Format(Touched))
        else
            Observer.ObserveError(Prefix + '.touch');
        if Holder.TryRead(Text1) then
            Observer.Observe(Prefix + '.read', Text1)
        else
            Observer.ObserveError(Prefix + '.read');
        if Holder.TryMark(Text1) then
            Observer.Observe(Prefix + '.mark', Text1)
        else
            Observer.ObserveError(Prefix + '.mark');
        if Holder.TryHostRead(Text1) then
            Observer.Observe(Prefix + '.host', Text1)
        else
            Observer.ObserveError(Prefix + '.host');
    end;

    // The held host reached from the test body while its TestPage is open, then after TestPage.Close, in one test.
    [Test]
    procedure HS01_HeldSender_WhileOpenAndAfterClose()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT HS Holder";
        Host: TestPage "LT HS Host";
    begin
        Seed();
        Holder.Setup(true, false);
        Host.OpenView();
        ObserveReach('open');
        Host.Close();
        ObserveReach('closed');
        Observer.Finish();
    end;

    // The next test of the codeunit: the held page is still the instance of the previous test's TestPage (not open, no new open yet).
    [Test]
    procedure HS02_HeldSender_NextTest_BeforeAnyOpen()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveReach('next-test');
        Observer.Finish();
    end;

    // A second TestPage of the same host opens while the variable holds the first one (not assigned again): the factbox's
    // OnAfterGetCurrRecord event reaches the held page's part (the customer's shape).
    [Test]
    procedure HS03_HeldFirstInstance_SecondOpen_FactboxEventReaches()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT HS Holder";
        Host: TestPage "LT HS Host";
        Log: Text;
    begin
        Seed();
        Holder.Setup(true, false);
        Host.OpenView();
        Host.Close();
        Holder.Setup(false, true);
        Host.OpenView();
        Log := Holder.TakeLog();
        Host.Close();
        Observer.Observe('second-open.log', Log);
        Observer.Finish();
    end;

    // The same second open when the variable was assigned from the sender of the second open's own event (the page is the open one).
    [Test]
    procedure HS04_HeldSecondInstance_SecondOpen_FactboxEventReaches()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT HS Holder";
        Host: TestPage "LT HS Host";
        Log: Text;
    begin
        Seed();
        Holder.Setup(true, true);
        Host.OpenView();
        Log := Holder.TakeLog();
        Host.Close();
        Observer.Observe('assigned-open.log', Log);
        Observer.Finish();
    end;
}

// Own codeunit: the SingleInstance holder starts empty here, so the variable never ran.
codeunit 99652 "LT HS Tests Never"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT HS Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
    end;

    // Control: the held host is a Page variable that never ran (pinned by NeverRanReadRec.al): the factbox event reaches its part.
    [Test]
    procedure HS05_NeverAssigned_FactboxEventReaches()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT HS Holder";
        Host: TestPage "LT HS Host";
        Log: Text;
    begin
        Seed();
        Holder.Setup(false, true);
        Host.OpenView();
        Log := Holder.TakeLog();
        Host.Close();
        Observer.Observe('never-assigned.log', Log);
        Observer.Finish();
    end;
}
