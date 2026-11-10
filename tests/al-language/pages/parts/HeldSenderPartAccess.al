// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-part-control
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 99620-99632
// Probe: observe-only. al-runner issue 6924 (a customer extension on Sales Credit Memo). A factbox part raises an IntegrationEvent(true, false) with the
//   sender from OnAfterGetCurrRecord. The subscriber, a SingleInstance codeunit, calls a procedure of a global Page variable of its own, and that procedure
//   reads CurrPage.<part>.Page. The global holds the host page that another subscriber took from `sender` of the host's own event, or it was never assigned.
// Facts: what a procedure of a held host page reads and calls through CurrPage.<part>.Page (the part's Rec, a part procedure that only counts, the part's
//   own variables) while the TestPage that opened the host is open, in the same test after TestPage.Close, in the next test of the codeunit (the held
//   page is still the first instance), and from the factbox's OnAfterGetCurrRecord event while a second TestPage of the same host opens. Also the shape
//   where the variable was never assigned (pinned by NeverRanReadRec.al, observed again here as the control).
// BC versions: 27, 28, 29
// singleinstance-shared-on-purpose: "LT HS Shape Log" (99628) and "LT HS Shape Subs" (99627) serve the four shape test codeunits 99629-99632;
//   the first test of each calls Subs.Reset() and ShapeLog.Setup(), which clear every global of both, so nothing carries from one of them to
//   the next (measured on 27.5, 28.5 and 29.0: each starts again at h1). The held page within one codeunit is the measurement.

table 99620 "LT HS Row"
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

codeunit 99620 "LT HS Holder"
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

page 99621 "LT HS Part"
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
        MarkText: Text;

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
        MarkText := NewMark;
    end;

    procedure GetMark(): Text
    begin
        exit(MarkText);
    end;
}

page 99622 "LT HS Fact"
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

page 99623 "LT HS Host"
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

codeunit 99621 "LT HS Tests"
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

    local procedure ObserveReach(Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
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
        ObserveReach('open', Observer);
        Host.Close();
        ObserveReach('closed', Observer);
        Observer.Expect('open.touch', '1');
        Observer.Expect('open.read', 'id=1 name=one count=1');
        Observer.Expect('open.mark', 'm');
        Observer.Expect('open.host', 'id=1 name=one');
        Observer.Expect('closed.touch', '2');
        Observer.Expect('closed.read', 'id=1 name=one count=1');
        Observer.Expect('closed.mark', 'm');
        Observer.Expect('closed.host', 'id=1 name=one');
        Observer.Verify();
    end;

    // The next test of the codeunit: the held page is still the instance of the previous test's TestPage (not open, no new open yet).
    [Test]
    procedure HS02_HeldSender_NextTest_BeforeAnyOpen()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveReach('next-test', Observer);
        Observer.Expect('next-test.touch', '3');
        Observer.Expect('next-test.read', 'id=1 name=one count=0');
        Observer.Expect('next-test.mark', 'm');
        Observer.Expect('next-test.host', 'id=1 name=one');
        Observer.Verify();
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
        Observer.Expect('second-open.log', 'fact(1);touch=1;read=id=1 name=one count=1;');
        Observer.Verify();
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
        Observer.Expect('assigned-open.log', 'fact(1);touch=1;read=id=1 name=one count=1;');
        Observer.Verify();
    end;
}

// Own codeunit: the SingleInstance holder starts empty here, so the variable never ran.
codeunit 99622 "LT HS Tests Never"
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
        Observer.Expect('never-assigned.log', 'fact(1);touch=2;read=id=1 name=one count=1;');
        Observer.Verify();
    end;
}

// ---------------------------------------------------------------------------------------------------------------------------------
// The exact shape of al-runner issue 6924 (objects 99624-99632).
//   - The host is a card page. A page extension adds a factbox part with Visible = <extension variable set in the extension's
//     OnOpenPage> and SubPageLink = SystemId = field(SystemId). The extension's OnAfterGetRecord raises an IntegrationEvent(true, false).
//   - The factbox's OnAfterGetCurrRecord raises an IntegrationEvent(true, false) with the row and ForceRefresh = false.
//   - A SingleInstance codeunit subscribes to both. The host event's subscriber stores `sender` in a global Page variable. The factbox
//     event's subscriber leaves when its Enabled global is false (set true by the host's OnOpenPageEvent and OnAfterGetCurrRecordEvent,
//     false by OnQueryClosePageEvent), else it calls a page extension procedure on the held host, which does
//     CurrPage.<part>.Page.<a procedure of the factbox page>().
//   - Test 1 of a codeunit opens the host with OpenEdit and closes it. Test 2 opens it with OpenNew, sets the key with SetValue and
//     invokes an action. No host OnAfterGetRecord has to run in test 2 before the factbox event, so the held page can be test 1's.
// Matrix: part hidden or visible (the extension variable false or true) x the call on the held page made directly (raw: an error fails
//   the test with BC's message) or in a TryFunction (try: the log gets the error code and text, or the returned value).
// Log tokens, in the order BC ran them: h<N> is a host instance and f<N> a factbox instance (numbered when its code first runs, so an
//   instance whose OnOpenPage never ran still gets a number but logs no `open`); sub.* are the subscribers; T:* are the test's own steps.
// local object: the page extension, the part's Visible and SubPageLink, the triggers and the event publishers are what the probe checks.

codeunit 99628 "LT HS Shape Log"
{
    SingleInstance = true;

    var
        Log: Text;
        Counter: Integer;
        PartVisible: Boolean;
        UseTry: Boolean;

    procedure Setup(NewPartVisible: Boolean; NewUseTry: Boolean)
    begin
        PartVisible := NewPartVisible;
        UseTry := NewUseTry;
        Counter := 0;
        Log := '';
    end;

    procedure IsPartVisible(): Boolean
    begin
        exit(PartVisible);
    end;

    procedure IsTry(): Boolean
    begin
        exit(UseTry);
    end;

    procedure NextNo(): Integer
    begin
        Counter += 1;
        exit(Counter);
    end;

    procedure Add(T: Text)
    begin
        Log += T + ';';
    end;

    procedure TakeLog(): Text
    var
        R: Text;
    begin
        R := Log;
        Log := '';
        exit(R);
    end;

    procedure Bool(B: Boolean): Text
    begin
        if B then
            exit('true');
        exit('false');
    end;
}

page 99624 "LT HS Shape Fact"
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

    var
        ShapeLog: Codeunit "LT HS Shape Log";
        MyNo: Integer;
        Refreshes: Integer;

    trigger OnOpenPage()
    begin
        ShapeLog.Add(Me() + '.open');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ShapeLog.Add(Me() + '.curr(' + Format(Rec.Id) + ')');
        OnAfterGetRecordEventWithSender(Rec, false);
    end;

    procedure RefreshPageData(): Integer
    begin
        Refreshes += 1;
        ShapeLog.Add(Me() + '.refresh(id=' + Format(Rec.Id) + ',n=' + Format(Refreshes) + ')');
        exit(Refreshes);
    end;

    local procedure Me(): Text
    begin
        if MyNo = 0 then
            MyNo := ShapeLog.NextNo();
        exit('f' + Format(MyNo));
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetRecordEventWithSender(Row: Record "LT HS Row"; ForceRefresh: Boolean)
    begin
    end;
}

page 99625 "LT HS Shape Host"
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
            field(NameF; Rec.Name) { ApplicationArea = All; }
        }
        area(FactBoxes)
        {
        }
    }

    actions
    {
        area(Processing)
        {
            action(Touch)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    ShapeLog: Codeunit "LT HS Shape Log";
                begin
                    ShapeLog.Add('action(' + Format(Rec.Id) + ')');
                end;
            }
        }
    }
}

pageextension 99626 "LT HS Shape Host Ext" extends "LT HS Shape Host"
{
    layout
    {
        addfirst(FactBoxes)
        {
            part(ShapeFact; "LT HS Shape Fact")
            {
                ApplicationArea = All;
                Caption = 'Shape';
                Visible = FactVisible;
                SubPageLink = SystemId = field(SystemId);
            }
        }
    }

    var
        ShapeLog: Codeunit "LT HS Shape Log";
        FactVisible: Boolean;
        MyNo: Integer;

    trigger OnOpenPage()
    begin
        FactVisible := ShapeLog.IsPartVisible();
        ShapeLog.Add(Me() + '.open(vis=' + ShapeLog.Bool(FactVisible) + ')');
    end;

    trigger OnAfterGetRecord()
    begin
        ShapeLog.Add(Me() + '.getrec(' + Format(Rec.Id) + ')');
        OnAfterGetRecordShape(Rec);
    end;

    procedure UpdateShapeFactbox()
    begin
        ShapeLog.Add(Me() + '.upd');
        CurrPage.ShapeFact.Page.RefreshPageData();
    end;

    procedure UpdateShapeFactboxValue(): Integer
    begin
        ShapeLog.Add(Me() + '.updv');
        exit(CurrPage.ShapeFact.Page.RefreshPageData());
    end;

    local procedure Me(): Text
    begin
        if MyNo = 0 then
            MyNo := ShapeLog.NextNo();
        exit('h' + Format(MyNo));
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetRecordShape(Row: Record "LT HS Row")
    begin
    end;
}

codeunit 99627 "LT HS Shape Subs"
{
    SingleInstance = true;

    var
        ShapeLog: Codeunit "LT HS Shape Log";
        GlobalFact: Page "LT HS Shape Fact";
        GlobalHost: Page "LT HS Shape Host";
        Enabled: Boolean;
        Initialized: Boolean;

    // The start of a pair of tests: nothing held, not enabled.
    procedure Reset()
    begin
        Clear(GlobalFact);
        Clear(GlobalHost);
        Enabled := false;
        Initialized := false;
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT HS Shape Host", OnOpenPageEvent, '', false, false)]
    local procedure HostOnOpenPage()
    begin
        ShapeLog.Add('sub.open');
        Enabled := true;
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT HS Shape Host", OnAfterGetCurrRecordEvent, '', false, false)]
    local procedure HostOnAfterGetCurrRecord()
    begin
        ShapeLog.Add('sub.curr');
        Enabled := true;
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT HS Shape Host", OnQueryClosePageEvent, '', false, false)]
    local procedure HostOnQueryClosePage()
    begin
        ShapeLog.Add('sub.qclose');
        Enabled := false;
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT HS Shape Host", OnAfterGetRecordShape, '', false, false)]
    local procedure HostOnAfterGetRecordShape(sender: Page "LT HS Shape Host")
    begin
        ShapeLog.Add('sub.hold');
        GlobalHost := sender;
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT HS Shape Fact", OnAfterGetRecordEventWithSender, '', false, false)]
    local procedure FactOnAfterGetRecordEventWithSender(var sender: Page "LT HS Shape Fact"; Row: Record "LT HS Row"; ForceRefresh: Boolean)
    begin
        ShapeLog.Add('sub.fact(enabled=' + ShapeLog.Bool(Enabled) + ',init=' + ShapeLog.Bool(Initialized) + ')');
        if not Enabled and not ForceRefresh then
            exit;
        GlobalFact := sender;
        Check();
    end;

    local procedure Check()
    var
        Returned: Integer;
    begin
        if ShapeLog.IsTry() then begin
            if TryUpdate(Returned) then
                ShapeLog.Add('ret=' + Format(Returned))
            else
                ShapeLog.Add('err=' + GetLastErrorCode() + '|' + GetLastErrorText());
        end else
            GlobalHost.UpdateShapeFactbox();
        Initialized := true;
    end;

    [TryFunction]
    procedure TryUpdate(var Returned: Integer)
    begin
        Returned := GlobalHost.UpdateShapeFactboxValue();
    end;
}

codeunit 99629 "LT HS Shape Hidden Raw"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The customer's first test: the host opens on an existing row through TestPage.OpenEdit and closes. Part hidden, direct call.
    [Test]
    procedure HS06_ShapeHiddenRaw_OpenEditThenClose()
    var
        Observer: Codeunit "Probe Observer";
        ShapeLog: Codeunit "LT HS Shape Log";
        Subs: Codeunit "LT HS Shape Subs";
        Row: Record "LT HS Row";
        Host: TestPage "LT HS Shape Host";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Subs.Reset();
        ShapeLog.Setup(false, false);
        Host.OpenEdit();
        ShapeLog.Add('T:opened');
        Host.Close();
        ShapeLog.Add('T:closed');
        Observer.Observe('log', ShapeLog.TakeLog());
        Observer.Expect('log', 'h1.open(vis=false);sub.open;f2.open;h1.getrec(1);sub.hold;sub.curr;f2.curr(1);sub.fact(enabled=true,init=false);h1.upd;f2.refresh(id=1,n=1);T:opened;sub.qclose;T:closed;');
        Observer.Verify();
    end;

    // The customer's second test, in the same codeunit: OpenNew, the key set with SetValue, an action invoked. Part hidden, direct call.
    [Test]
    procedure HS07_ShapeHiddenRaw_OpenNewSetKeyInvokeAction()
    var
        Observer: Codeunit "Probe Observer";
        ShapeLog: Codeunit "LT HS Shape Log";
        Host: TestPage "LT HS Shape Host";
    begin
        ShapeLog.TakeLog();
        Host.OpenNew();
        ShapeLog.Add('T:opened');
        Host.IdF.SetValue(2);
        ShapeLog.Add('T:set');
        Host.Touch.Invoke();
        ShapeLog.Add('T:acted');
        Host.Close();
        ShapeLog.Add('T:closed');
        Observer.Observe('log', ShapeLog.TakeLog());
        Observer.Expect('log', 'h3.open(vis=false);sub.open;f4.open;sub.curr;f4.curr(0);sub.fact(enabled=true,init=true);h1.upd;f2.refresh(id=1,n=2);T:opened;T:set;h3.getrec(2);sub.hold;action(2);h3.getrec(2);sub.hold;h3.getrec(2);sub.hold;sub.curr;f4.curr(2);sub.fact(enabled=true,init=true);h3.upd;f4.refresh(id=2,n=1);T:acted;sub.qclose;T:closed;');
        Observer.Verify();
    end;
}

codeunit 99630 "LT HS Shape Hidden Try"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // As HS06 with the call on the held page in a TryFunction, and one more call from the test body after the close.
    [Test]
    procedure HS08_ShapeHiddenTry_OpenEditThenClose()
    var
        Observer: Codeunit "Probe Observer";
        ShapeLog: Codeunit "LT HS Shape Log";
        Subs: Codeunit "LT HS Shape Subs";
        Row: Record "LT HS Row";
        Host: TestPage "LT HS Shape Host";
        Returned: Integer;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Subs.Reset();
        ShapeLog.Setup(false, true);
        Host.OpenEdit();
        ShapeLog.Add('T:opened');
        Host.Close();
        ShapeLog.Add('T:closed');
        if Subs.TryUpdate(Returned) then
            Observer.Observe('closed.direct', Format(Returned))
        else
            Observer.ObserveError('closed.direct');
        Observer.Observe('log', ShapeLog.TakeLog());
        Observer.Expect('closed.direct', '2');
        Observer.Expect('log', 'h1.open(vis=false);sub.open;f2.open;h1.getrec(1);sub.hold;sub.curr;f2.curr(1);sub.fact(enabled=true,init=false);h1.updv;f2.refresh(id=1,n=1);ret=1;T:opened;sub.qclose;T:closed;h1.updv;f2.refresh(id=1,n=2);');
        Observer.Verify();
    end;

    // As HS07 with the call on the held page in a TryFunction, and one more call from the test body after the close.
    [Test]
    procedure HS09_ShapeHiddenTry_OpenNewSetKeyInvokeAction()
    var
        Observer: Codeunit "Probe Observer";
        ShapeLog: Codeunit "LT HS Shape Log";
        Subs: Codeunit "LT HS Shape Subs";
        Host: TestPage "LT HS Shape Host";
        Returned: Integer;
    begin
        ShapeLog.TakeLog();
        Host.OpenNew();
        ShapeLog.Add('T:opened');
        Host.IdF.SetValue(2);
        ShapeLog.Add('T:set');
        Host.Touch.Invoke();
        ShapeLog.Add('T:acted');
        Host.Close();
        ShapeLog.Add('T:closed');
        if Subs.TryUpdate(Returned) then
            Observer.Observe('closed.direct', Format(Returned))
        else
            Observer.ObserveError('closed.direct');
        Observer.Observe('log', ShapeLog.TakeLog());
        Observer.Expect('closed.direct', '2');
        Observer.Expect('log', 'h3.open(vis=false);sub.open;f4.open;sub.curr;f4.curr(0);sub.fact(enabled=true,init=true);h1.updv;f2.refresh(id=1,n=3);ret=3;T:opened;T:set;h3.getrec(2);sub.hold;action(2);h3.getrec(2);sub.hold;h3.getrec(2);sub.hold;sub.curr;f4.curr(2);sub.fact(enabled=true,init=true);h3.updv;f4.refresh(id=2,n=1);ret=1;T:acted;sub.qclose;T:closed;h3.updv;f4.refresh(id=2,n=2);');
        Observer.Verify();
    end;
}

codeunit 99631 "LT HS Shape Visible Raw"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // As HS06 with the part visible (the extension variable is true).
    [Test]
    procedure HS10_ShapeVisibleRaw_OpenEditThenClose()
    var
        Observer: Codeunit "Probe Observer";
        ShapeLog: Codeunit "LT HS Shape Log";
        Subs: Codeunit "LT HS Shape Subs";
        Row: Record "LT HS Row";
        Host: TestPage "LT HS Shape Host";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Subs.Reset();
        ShapeLog.Setup(true, false);
        Host.OpenEdit();
        ShapeLog.Add('T:opened');
        Host.Close();
        ShapeLog.Add('T:closed');
        Observer.Observe('log', ShapeLog.TakeLog());
        Observer.Expect('log', 'h1.open(vis=true);sub.open;f2.open;h1.getrec(1);sub.hold;sub.curr;f2.curr(1);sub.fact(enabled=true,init=false);h1.upd;f2.refresh(id=1,n=1);T:opened;sub.qclose;T:closed;');
        Observer.Verify();
    end;

    // As HS07 with the part visible.
    [Test]
    procedure HS11_ShapeVisibleRaw_OpenNewSetKeyInvokeAction()
    var
        Observer: Codeunit "Probe Observer";
        ShapeLog: Codeunit "LT HS Shape Log";
        Host: TestPage "LT HS Shape Host";
    begin
        ShapeLog.TakeLog();
        Host.OpenNew();
        ShapeLog.Add('T:opened');
        Host.IdF.SetValue(2);
        ShapeLog.Add('T:set');
        Host.Touch.Invoke();
        ShapeLog.Add('T:acted');
        Host.Close();
        ShapeLog.Add('T:closed');
        Observer.Observe('log', ShapeLog.TakeLog());
        Observer.Expect('log', 'h3.open(vis=true);sub.open;f4.open;sub.curr;f4.curr(0);sub.fact(enabled=true,init=true);h1.upd;f2.refresh(id=1,n=2);T:opened;T:set;h3.getrec(2);sub.hold;action(2);h3.getrec(2);sub.hold;h3.getrec(2);sub.hold;sub.curr;f4.curr(2);sub.fact(enabled=true,init=true);h3.upd;f4.refresh(id=2,n=1);T:acted;sub.qclose;T:closed;');
        Observer.Verify();
    end;
}

codeunit 99632 "LT HS Shape Visible Try"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // As HS08 with the part visible.
    [Test]
    procedure HS12_ShapeVisibleTry_OpenEditThenClose()
    var
        Observer: Codeunit "Probe Observer";
        ShapeLog: Codeunit "LT HS Shape Log";
        Subs: Codeunit "LT HS Shape Subs";
        Row: Record "LT HS Row";
        Host: TestPage "LT HS Shape Host";
        Returned: Integer;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Subs.Reset();
        ShapeLog.Setup(true, true);
        Host.OpenEdit();
        ShapeLog.Add('T:opened');
        Host.Close();
        ShapeLog.Add('T:closed');
        if Subs.TryUpdate(Returned) then
            Observer.Observe('closed.direct', Format(Returned))
        else
            Observer.ObserveError('closed.direct');
        Observer.Observe('log', ShapeLog.TakeLog());
        Observer.Expect('closed.direct', '2');
        Observer.Expect('log', 'h1.open(vis=true);sub.open;f2.open;h1.getrec(1);sub.hold;sub.curr;f2.curr(1);sub.fact(enabled=true,init=false);h1.updv;f2.refresh(id=1,n=1);ret=1;T:opened;sub.qclose;T:closed;h1.updv;f2.refresh(id=1,n=2);');
        Observer.Verify();
    end;

    // As HS09 with the part visible.
    [Test]
    procedure HS13_ShapeVisibleTry_OpenNewSetKeyInvokeAction()
    var
        Observer: Codeunit "Probe Observer";
        ShapeLog: Codeunit "LT HS Shape Log";
        Subs: Codeunit "LT HS Shape Subs";
        Host: TestPage "LT HS Shape Host";
        Returned: Integer;
    begin
        ShapeLog.TakeLog();
        Host.OpenNew();
        ShapeLog.Add('T:opened');
        Host.IdF.SetValue(2);
        ShapeLog.Add('T:set');
        Host.Touch.Invoke();
        ShapeLog.Add('T:acted');
        Host.Close();
        ShapeLog.Add('T:closed');
        if Subs.TryUpdate(Returned) then
            Observer.Observe('closed.direct', Format(Returned))
        else
            Observer.ObserveError('closed.direct');
        Observer.Observe('log', ShapeLog.TakeLog());
        Observer.Expect('closed.direct', '2');
        Observer.Expect('log', 'h3.open(vis=true);sub.open;f4.open;sub.curr;f4.curr(0);sub.fact(enabled=true,init=true);h1.updv;f2.refresh(id=1,n=3);ret=3;T:opened;T:set;h3.getrec(2);sub.hold;action(2);h3.getrec(2);sub.hold;h3.getrec(2);sub.hold;sub.curr;f4.curr(2);sub.fact(enabled=true,init=true);h3.updv;f4.refresh(id=2,n=1);ret=1;T:acted;sub.qclose;T:closed;h3.updv;f4.refresh(id=2,n=2);');
        Observer.Verify();
    end;
}
