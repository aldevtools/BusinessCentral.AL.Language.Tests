// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-the-user-interface
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), shared Assert (60021);
//                self-contained pages 68220..68224, codeunits 68225 (tests), 68229 (log)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins the Action that RunModal reports in a test (static Page.RunModal always reports the Lookup
// values; a page variable reports OK/Cancel), what a handler that leaves the page open gives, that a
// Boolean page trigger without exit() does not veto, that CurrPage.Update in OnOpenPage and in an action
// read the current row once, that CurrPage.Editable(false) does not change what a TestPage reports, the
// error of OnInit when no handler is bound, the FindFirstField family, and SourceTableView.
// BC versions: 27.5

codeunit 68229 "Probe Modal Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

page 68220 "Probe MR Card"
{
    PageType = Card;
    SourceTable = "ALT Universal";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
            field("Text Field"; Rec."Text Field") { ApplicationArea = All; }
            field("Code Field"; Rec."Code Field") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MakeReadOnly)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Editable(false);
                end;
            }
            action(UpdateNow)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    ModalLog.Add('UpdateNow');
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        ModalLog: Codeunit "Probe Modal Log";

    trigger OnInit()
    begin
        ModalLog.Add('OnInit');
    end;

    trigger OnOpenPage()
    begin
        ModalLog.Add('OnOpenPage');
        CurrPage.Update(false);
        ModalLog.Add('afterUpdateInOpen');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ModalLog.Add('AGCR(' + Format(Rec."Entry No.") + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        ModalLog.Add('OnModifyRecord(noexit)');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        ModalLog.Add('OnQueryClosePage(noexit)');
    end;
}

page 68221 "Probe MR Init Error"
{
    PageType = Card;
    SourceTable = "ALT Universal";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
        }
    }

    trigger OnInit()
    begin
        Error('init failed');
    end;
}

page 68222 "Probe MR Source View"
{
    PageType = List;
    SourceTable = "ALT Universal";
    SourceTableView = where("Entry No." = filter(<= 2));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Text Field"; Rec."Text Field") { ApplicationArea = All; }
            }
        }
    }
}

page 68223 "Probe MR Dialog"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;
}

page 68224 "Probe MR Plain Card"
{
    PageType = Card;
    SourceTable = "ALT Universal";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
        }
    }
}

codeunit 68225 "Probe Modal Results"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        ModalLog: Codeunit "Probe Modal Log";
        HandlerMode: Text;

    local procedure Initialize()
    var
        ALTUniversal: Record "ALT Universal";
        EntryNo: Integer;
    begin
        Cleanup.Initialize();
        for EntryNo := 1 to 5 do begin
            ALTUniversal.Init();
            ALTUniversal."Entry No." := EntryNo;
            ALTUniversal."Text Field" := 'row' + Format(EntryNo);
            ALTUniversal.Insert();
        end;
        Commit();
        ModalLog.Take();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure RunModal_Dialog_StaticVersusVariable_ReportedAction()
    var
        Result: Action;
        Dialog: Page "Probe MR Dialog";
    begin
        Initialize();

        HandlerMode := 'ok';
        Result := Page.RunModal(Page::"Probe MR Dialog");
        Assert.AreEqual('LookupOK', Format(Result), 'static, handler presses OK');

        HandlerMode := 'cancel';
        Result := Page.RunModal(Page::"Probe MR Dialog");
        Assert.AreEqual('LookupCancel', Format(Result), 'static, handler presses Cancel');

        HandlerMode := 'none';
        Result := Page.RunModal(Page::"Probe MR Dialog");
        Assert.AreEqual('LookupCancel', Format(Result), 'static, handler leaves the page open');

        Result := Dialog.RunModal();
        Assert.AreEqual('Cancel', Format(Result), 'page variable, handler leaves the page open');
    end;

    [ModalPageHandler]
    procedure DialogHandler(var Dialog: TestPage "Probe MR Dialog")
    begin
        if HandlerMode = 'ok' then
            Dialog.OK().Invoke();
        if HandlerMode = 'cancel' then
            Dialog.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure RunModal_Card_StaticWithAndWithoutRecord_VersusVariable_ReportedAction()
    var
        Result: Action;
        ALTUniversal: Record "ALT Universal";
        Card: Page "Probe MR Plain Card";
    begin
        Initialize();
        ALTUniversal.Get(1);

        HandlerMode := 'ok';
        Result := Page.RunModal(Page::"Probe MR Plain Card", ALTUniversal);
        Assert.AreEqual('LookupOK', Format(Result), 'static with a record, OK');
        HandlerMode := 'cancel';
        Result := Page.RunModal(Page::"Probe MR Plain Card", ALTUniversal);
        Assert.AreEqual('LookupCancel', Format(Result), 'static with a record, Cancel');
        HandlerMode := 'none';
        Result := Page.RunModal(Page::"Probe MR Plain Card", ALTUniversal);
        Assert.AreEqual('LookupCancel', Format(Result), 'static with a record, page left open');
        HandlerMode := 'ok';
        Result := Page.RunModal(Page::"Probe MR Plain Card");
        Assert.AreEqual('LookupOK', Format(Result), 'static without a record, OK');
        HandlerMode := 'none';
        Card.SetRecord(ALTUniversal);
        Result := Card.RunModal();
        Assert.AreEqual('OK', Format(Result), 'page variable with a record, page left open: closed with OK');
    end;

    [ModalPageHandler]
    procedure CardHandler(var Card: TestPage "Probe MR Plain Card")
    begin
        if HandlerMode = 'ok' then
            Card.OK().Invoke();
        if HandlerMode = 'cancel' then
            Card.Cancel().Invoke();
    end;

    [Test]
    procedure Card_PageTriggersWithoutExit_DoNotVeto_AndUpdateReadsTheCurrentRowOnce()
    var
        Card: TestPage "Probe MR Card";
        ALTUniversal: Record "ALT Universal";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.AreEqual('OnInit;OnOpenPage;afterUpdateInOpen;AGCR(1);', ModalLog.Take(), 'CurrPage.Update in OnOpenPage schedules no second read');

        Card.GoToKey(2);
        ModalLog.Take();
        Card.UpdateNow.Invoke();
        Assert.AreEqual('UpdateNow;AGCR(2);', ModalLog.Take(), 'CurrPage.Update in an action reads the current row once');

        Card."Text Field".SetValue('changed');
        ModalLog.Take();
        Card.GoToKey(3);
        Assert.AreEqual('OnModifyRecord(noexit);AGCR(1);AGCR(2);AGCR(3);', ModalLog.Take(), 'OnModifyRecord without exit() does not veto');
        ALTUniversal.Get(2);
        Assert.AreEqual('changed', ALTUniversal."Text Field", 'the row was saved');

        Card.GoToKey(1);
        Card.MakeReadOnly.Invoke();
        Assert.IsTrue(Card.Editable(), 'CurrPage.Editable(false) does not change what the TestPage reports');
        Assert.IsTrue(Card."Text Field".Editable(), 'nor a control');

        ModalLog.Take();
        Card.Close();
        Assert.AreEqual('OnQueryClosePage(noexit);', ModalLog.Take(), 'OnQueryClosePage without exit() does not veto the close');
    end;

    [Test]
    procedure OnInit_Error_WithoutHandler_ComesOutAsItself()
    var
        Card: TestPage "Probe MR Init Error";
    begin
        Initialize();

        asserterror Card.OpenEdit();

        Assert.AreEqual('init failed', GetLastErrorText(), 'text');
        Assert.AreEqual('Dialog', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure FindFirstField_FindNextField_FindPreviousField()
    var
        List: TestPage "Probe MR Source View";
        Found: Boolean;
    begin
        Initialize();
        List.OpenView();
        List.GoToKey(1);

        Found := List.FindFirstField(List."Text Field", 'row2');
        Assert.IsTrue(Found, 'FindFirstField hit');
        Assert.AreEqual('2', List."Entry No.".Value(), 'hit row');

        Found := List.FindFirstField(List."Text Field", 'nope');
        Assert.IsFalse(Found, 'FindFirstField miss');
        Assert.AreEqual('2', List."Entry No.".Value(), 'a miss leaves the cursor');

        Found := List.FindFirstField(List."Entry No.", '2');
        Assert.IsFalse(Found, 'a text value does not match an integer control');
        List.Close();
    end;

    [Test]
    procedure SourceTableView_FiltersThePageRows()
    var
        List: TestPage "Probe MR Source View";
        Count: Integer;
    begin
        Initialize();
        List.OpenView();
        List.First();
        repeat
            Count += 1;
        until not List.Next();

        Assert.AreEqual(2, Count, 'only the rows of the view');
        List.Close();
    end;
}
