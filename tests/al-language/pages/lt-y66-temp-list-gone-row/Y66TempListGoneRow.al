// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetabletemporary-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93504, pages 93502 and 93503, codeunits 93509 (log, used by 93510 only) and 93510
// Probe (al-runner issue 6664, follow-up of 6180, writer Y66): a List with Editable = false over a temporary source (SourceTableView
// descending, the reporter's shape, and ascending) that OnOpenPage fills with one row (or two), then an action that deletes every row and
// inserts none (MyFilter0, also with CurrPage.Update(false)), one (MyFilter1) or two (MyFilter2). Opened with Page.RunModal (ModalPageHandler),
// Page.LookupMode(true) + RunModal, TestPage.OpenView and OpenEdit. Observed: First and the field value read after the action, Last, Next,
// Previous, the trigger log (R:<id> OnAfterGetRecord, C:<id> OnAfterGetCurrRecord, N:<id> OnNewRecord, Q OnQueryClosePage, X OnClosePage),
// and a second action that refills one row.
// Pinned elsewhere: Worksheets and InsertAllowed = false lists over stored or temporary rows (pages/lt-outside-worksheet/RmWorksheetGoneRow.al,
// RmTempRefill.al TD_RefillFewer_*To0).
// BC versions: 27, 28, 29

table 93504 "LT Y66 GR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 93509 "LT Y66 GR Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Rows: Integer;

    procedure Reset(NewOpenRows: Integer)
    begin
        Entries := '';
        Rows := NewOpenRows;
    end;

    procedure OpenRows(): Integer
    begin
        exit(Rows);
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

page 93502 "LT Y66 GR List Desc"
{
    PageType = List;
    Editable = false;
    SourceTable = "LT Y66 GR Row";
    SourceTableTemporary = true;
    SourceTableView = sorting(Id) order(descending);
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MyFilter0) { ApplicationArea = All; trigger OnAction() begin MyProc(0, false); end; }
            action(MyFilter1) { ApplicationArea = All; trigger OnAction() begin MyProc(1, false); end; }
            action(MyFilter2) { ApplicationArea = All; trigger OnAction() begin MyProc(2, false); end; }
            action(MyFilter0Update) { ApplicationArea = All; trigger OnAction() begin MyProc(0, true); end; }
        }
    }

    trigger OnOpenPage()
    begin
        MyProc(Log.OpenRows(), false);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec.Id));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Format(Rec.Id));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('Q');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('X');
    end;

    var
        Log: Codeunit "LT Y66 GR Log";

    local procedure MyProc(Rows: Integer; Update: Boolean)
    var
        I: Integer;
    begin
        Rec.DeleteAll();
        for I := 1 to Rows do begin
            Rec.Init();
            Rec.Id := I * 10;
            Rec.Name := 'N' + Format(I * 10);
            Rec.Insert();
        end;
        if Update then
            CurrPage.Update(false);
    end;
}

page 93503 "LT Y66 GR List Asc"
{
    PageType = List;
    Editable = false;
    SourceTable = "LT Y66 GR Row";
    SourceTableTemporary = true;
    SourceTableView = sorting(Id) order(ascending);
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MyFilter0) { ApplicationArea = All; trigger OnAction() begin MyProc(0, false); end; }
            action(MyFilter1) { ApplicationArea = All; trigger OnAction() begin MyProc(1, false); end; }
            action(MyFilter2) { ApplicationArea = All; trigger OnAction() begin MyProc(2, false); end; }
            action(MyFilter0Update) { ApplicationArea = All; trigger OnAction() begin MyProc(0, true); end; }
        }
    }

    trigger OnOpenPage()
    begin
        MyProc(Log.OpenRows(), false);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec.Id));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Format(Rec.Id));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('Q');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('X');
    end;

    var
        Log: Codeunit "LT Y66 GR Log";

    local procedure MyProc(Rows: Integer; Update: Boolean)
    var
        I: Integer;
    begin
        Rec.DeleteAll();
        for I := 1 to Rows do begin
            Rec.Init();
            Rec.Id := I * 10;
            Rec.Name := 'N' + Format(I * 10);
            Rec.Insert();
        end;
        if Update then
            CurrPage.Update(false);
    end;
}

codeunit 93510 "LT Y66 Temp List Gone Row"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y66 GR Log";
        Mode: Integer;

    [Test]
    [HandlerFunctions('DescHandler')]
    procedure Y66_Desc_RunModal_Filter0()
    begin
        Log.Reset(1);
        Mode := 0;
        Observer.Observe('runmodal', Format(Page.RunModal(Page::"LT Y66 GR List Desc")));
        Observer.Observe('after runmodal log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10;');
        Observer.Expect('open shown', '10|N10');
        Observer.Expect('action log', 'R:10;N:0;C:0;');
        Observer.Expect('shown after action', '|');
        Observer.Expect('first', 'No');
        Observer.Expect('value after first', '');
        Observer.Expect('last', 'No');
        Observer.Expect('next', 'No');
        Observer.Expect('previous', 'No');
        Observer.Expect('moves log', '');
        Observer.Expect('second action log', 'N:0;C:0;');
        Observer.Expect('refill log', 'R:10;R:10;R:10;C:10;');
        Observer.Expect('shown after refill', '10|N10');
        Observer.Expect('first after refill', 'Yes|N10');
        Observer.Expect('next after refill', 'No');
        Observer.Expect('runmodal', 'LookupCancel');
        Observer.Expect('after runmodal log', 'Q;X;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DescHandler')]
    procedure Y66_Desc_RunModal_Filter0Update()
    begin
        Log.Reset(1);
        Mode := 1;
        Observer.Observe('runmodal', Format(Page.RunModal(Page::"LT Y66 GR List Desc")));
        Observer.Observe('after runmodal log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10;');
        Observer.Expect('open shown', '10|N10');
        Observer.Expect('action log', 'R:10;N:0;C:0;');
        Observer.Expect('shown after action', '|');
        Observer.Expect('first', 'No');
        Observer.Expect('value after first', '');
        Observer.Expect('last', 'No');
        Observer.Expect('next', 'No');
        Observer.Expect('previous', 'No');
        Observer.Expect('moves log', '');
        Observer.Expect('second action log', 'N:0;C:0;');
        Observer.Expect('refill log', 'R:10;R:10;R:10;C:10;');
        Observer.Expect('shown after refill', '10|N10');
        Observer.Expect('first after refill', 'Yes|N10');
        Observer.Expect('next after refill', 'No');
        Observer.Expect('runmodal', 'LookupCancel');
        Observer.Expect('after runmodal log', 'Q;X;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DescHandler')]
    procedure Y66_Desc_RunModal_TwoRows_Filter0()
    begin
        Log.Reset(2);
        Mode := 0;
        Observer.Observe('runmodal', Format(Page.RunModal(Page::"LT Y66 GR List Desc")));
        Observer.Observe('after runmodal log', Log.Take());
        Observer.Expect('open log', 'R:20;R:10;R:20;R:20;C:20;');
        Observer.Expect('open shown', '20|N20');
        Observer.Expect('action log', 'R:20;N:0;C:0;');
        Observer.Expect('shown after action', '|');
        Observer.Expect('first', 'No');
        Observer.Expect('value after first', '');
        Observer.Expect('last', 'No');
        Observer.Expect('next', 'No');
        Observer.Expect('previous', 'No');
        Observer.Expect('moves log', '');
        Observer.Expect('second action log', 'N:0;C:0;');
        Observer.Expect('refill log', 'R:10;R:10;R:10;C:10;');
        Observer.Expect('shown after refill', '10|N10');
        Observer.Expect('first after refill', 'Yes|N10');
        Observer.Expect('next after refill', 'No');
        Observer.Expect('runmodal', 'LookupCancel');
        Observer.Expect('after runmodal log', 'Q;X;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DescHandler')]
    procedure Y66_Desc_LookupMode_Filter0()
    var
        MyList: Page "LT Y66 GR List Desc";
    begin
        Log.Reset(1);
        Mode := 0;
        MyList.LookupMode(true);
        Observer.Observe('runmodal', Format(MyList.RunModal()));
        Observer.Observe('after runmodal log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10;');
        Observer.Expect('open shown', '10|N10');
        Observer.Expect('action log', 'R:10;N:0;C:0;');
        Observer.Expect('shown after action', '|');
        Observer.Expect('first', 'No');
        Observer.Expect('value after first', '');
        Observer.Expect('last', 'No');
        Observer.Expect('next', 'No');
        Observer.Expect('previous', 'No');
        Observer.Expect('moves log', '');
        Observer.Expect('second action log', 'N:0;C:0;');
        Observer.Expect('refill log', 'R:10;R:10;R:10;C:10;');
        Observer.Expect('shown after refill', '10|N10');
        Observer.Expect('first after refill', 'Yes|N10');
        Observer.Expect('next after refill', 'No');
        Observer.Expect('runmodal', 'LookupCancel');
        Observer.Expect('after runmodal log', 'Q;X;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('AscHandler')]
    procedure Y66_Asc_RunModal_Filter0()
    begin
        Log.Reset(1);
        Mode := 0;
        Observer.Observe('runmodal', Format(Page.RunModal(Page::"LT Y66 GR List Asc")));
        Observer.Observe('after runmodal log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10;');
        Observer.Expect('open shown', '10|N10');
        Observer.Expect('action log', 'R:10;N:0;C:0;');
        Observer.Expect('first', 'No');
        Observer.Expect('value', '');
        Observer.Expect('last', 'No');
        Observer.Expect('moves log', '');
        Observer.Expect('refill log', 'R:10;R:10;R:10;C:10;');
        Observer.Expect('first after refill', 'Yes|N10');
        Observer.Expect('runmodal', 'LookupCancel');
        Observer.Expect('after runmodal log', 'Q;X;');
        Observer.Verify();
    end;

    [Test]
    procedure Y66_Desc_OpenView_Filter0()
    var
        MyList: TestPage "LT Y66 GR List Desc";
    begin
        Log.Reset(1);
        MyList.OpenView();
        WalkDesc(MyList, 0);
        MyList.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10;');
        Observer.Expect('open shown', '10|N10');
        Observer.Expect('action log', 'R:10;');
        Observer.Expect('shown after action', '|');
        Observer.Expect('first', 'No');
        Observer.Expect('value after first', '');
        Observer.Expect('last', 'No');
        Observer.Expect('next', 'No');
        Observer.Expect('previous', 'No');
        Observer.Expect('moves log', '');
        Observer.Expect('second action log', '');
        Observer.Expect('refill log', 'R:10;R:10;R:10;C:10;');
        Observer.Expect('shown after refill', '10|N10');
        Observer.Expect('first after refill', 'Yes|N10');
        Observer.Expect('next after refill', 'No');
        Observer.Expect('close log', 'Q;X;');
        Observer.Verify();
    end;

    [Test]
    procedure Y66_Desc_OpenEdit_Filter0()
    var
        MyList: TestPage "LT Y66 GR List Desc";
    begin
        Log.Reset(1);
        MyList.OpenEdit();
        WalkDesc(MyList, 0);
        MyList.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10;');
        Observer.Expect('open shown', '10|N10');
        Observer.Expect('action log', 'R:10;');
        Observer.Expect('shown after action', '|');
        Observer.Expect('first', 'No');
        Observer.Expect('value after first', '');
        Observer.Expect('last', 'No');
        Observer.Expect('next', 'No');
        Observer.Expect('previous', 'No');
        Observer.Expect('moves log', '');
        Observer.Expect('second action log', '');
        Observer.Expect('refill log', 'R:10;R:10;R:10;C:10;');
        Observer.Expect('shown after refill', '10|N10');
        Observer.Expect('first after refill', 'Yes|N10');
        Observer.Expect('next after refill', 'No');
        Observer.Expect('close log', 'Q;X;');
        Observer.Verify();
    end;

    [Test]
    procedure Y66_Asc_OpenView_Filter0Update()
    var
        MyList: TestPage "LT Y66 GR List Asc";
    begin
        Log.Reset(1);
        MyList.OpenView();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('open shown', MyList.Id.Value() + '|' + MyList.Name.Value());
        MyList.MyFilter0Update.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', MyList.Id.Value() + '|' + MyList.Name.Value());
        Observer.Observe('first', Format(MyList.First()));
        Observer.Observe('value after first', MyList.Name.Value());
        Observer.Observe('moves log', Log.Take());
        MyList.MyFilter2.Invoke();
        Observer.Observe('refill log', Log.Take());
        Observer.Observe('shown after refill', MyList.Id.Value() + '|' + MyList.Name.Value());
        Observer.Observe('first after refill', Format(MyList.First()) + '|' + MyList.Name.Value());
        Observer.Observe('next after refill', Format(MyList.Next()) + '|' + MyList.Name.Value());
        MyList.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10;');
        Observer.Expect('open shown', '10|N10');
        Observer.Expect('action log', 'R:10;');
        Observer.Expect('shown after action', '|');
        Observer.Expect('first', 'No');
        Observer.Expect('value after first', '');
        Observer.Expect('moves log', '');
        Observer.Expect('refill log', 'R:20;R:20;R:10;R:20;R:20;C:20;');
        Observer.Expect('shown after refill', '20|N20');
        Observer.Expect('first after refill', 'Yes|N10');
        Observer.Expect('next after refill', 'Yes|N20');
        Observer.Expect('close log', 'R:10;R:10;C:10;R:20;R:20;C:20;Q;X;');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure DescHandler(var MyList: TestPage "LT Y66 GR List Desc")
    begin
        WalkDesc(MyList, Mode);
    end;

    [ModalPageHandler]
    procedure AscHandler(var MyList: TestPage "LT Y66 GR List Asc")
    begin
        Observer.Observe('open log', Log.Take());
        Observer.Observe('open shown', MyList.Id.Value() + '|' + MyList.Name.Value());
        MyList.MyFilter0.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('first', Format(MyList.First()));
        Observer.Observe('value', MyList.Name.Value());
        Observer.Observe('last', Format(MyList.Last()));
        Observer.Observe('moves log', Log.Take());
        MyList.MyFilter1.Invoke();
        Observer.Observe('refill log', Log.Take());
        Observer.Observe('first after refill', Format(MyList.First()) + '|' + MyList.Name.Value());
    end;

    local procedure WalkDesc(var MyList: TestPage "LT Y66 GR List Desc"; ActionKind: Integer)
    var
        Value: Text;
    begin
        Observer.Observe('open log', Log.Take());
        Observer.Observe('open shown', MyList.Id.Value() + '|' + MyList.Name.Value());
        if ActionKind = 1 then
            MyList.MyFilter0Update.Invoke()
        else
            MyList.MyFilter0.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', MyList.Id.Value() + '|' + MyList.Name.Value());
        Observer.Observe('first', Format(MyList.First()));
        Value := MyList.Name.Value();
        Observer.Observe('value after first', Value);
        Observer.Observe('last', Format(MyList.Last()));
        Observer.Observe('next', Format(MyList.Next()));
        Observer.Observe('previous', Format(MyList.Previous()));
        Observer.Observe('moves log', Log.Take());
        MyList.MyFilter0.Invoke();
        Observer.Observe('second action log', Log.Take());
        MyList.MyFilter1.Invoke();
        Observer.Observe('refill log', Log.Take());
        Observer.Observe('shown after refill', MyList.Id.Value() + '|' + MyList.Name.Value());
        Observer.Observe('first after refill', Format(MyList.First()) + '|' + MyList.Name.Value());
        Observer.Observe('next after refill', Format(MyList.Next()));
    end;
}
