// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 92908, page 92908, codeunit 92910 (log, used by this test codeunit only), test codeunit 92911
// Probe (al-runner issue 6587): a local TestPage variable opened with OpenEdit/OpenView and left open when the test procedure ends (no Close()).
//   Does OnQueryClosePage run then, with which CloseAction, does a Confirm in it go to the test's ConfirmHandler (reply Yes, reply No so the
//   trigger answers false), does OnClosePage follow, is an unsaved SetValue written (OnModifyRecord). Each "left open" test is followed by a
//   test that reads the SingleInstance log the first one left behind (tests of one codeunit run in declaration order in one session). Also a
//   TestPage held in a global variable left open into the next test, and the explicit Close() for comparison.
//   Rows: 'EN' (Enabled Yes: OnQueryClosePage asks nothing) and 'DIS' (Enabled No: OnQueryClosePage asks Confirm).
// BC versions: 27, 28, 29

table 92908 "LT Y47 QC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Enabled; Boolean) { }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 92910 "LT Y47 QC Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
    end;
}

page 92908 "LT Y47 QC Card"
{
    PageType = Card;
    SourceTable = "LT Y47 QC Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Enabled; Rec.Enabled) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y47 QC Log";
    begin
        Log.Add('open');
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "LT Y47 QC Log";
    begin
        Log.Add('modify ' + Rec."Code" + ' name=' + Rec.Name);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT Y47 QC Log";
        Answer: Boolean;
    begin
        Log.Add('queryclose ' + Format(CloseAction) + ' ' + Rec."Code");
        if not Rec.Enabled then begin
            Answer := Confirm('The card is not enabled. Are you sure you want to exit?', true);
            Log.Add('confirm=' + Format(Answer));
            if not Answer then
                exit(false);
        end;
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT Y47 QC Log";
    begin
        Log.Add('close ' + Rec."Code");
    end;
}

codeunit 92911 "LT Y47 QC Left Open"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GlobalCard: TestPage "LT Y47 QC Card";
        LastCode: Text;

    local procedure Seed()
    var
        Row: Record "LT Y47 QC Row";
    begin
        Row.DeleteAll();
        Row."Code" := 'EN';
        Row.Enabled := true;
        Row.Insert();
        Row."Code" := 'DIS';
        Row.Enabled := false;
        Row.Insert();
    end;

    [Test]
    procedure Y47_T01_LeftOpen_Enabled_NoHandler()
    var
        Row: Record "LT Y47 QC Row";
        Log: Codeunit "LT Y47 QC Log";
        Card: TestPage "LT Y47 QC Card";
    begin
        Log.Take();
        Seed();
        Row.Get('EN');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Log.Add('test body end');
        // no Close(): the page is left open when the test ends
    end;

    [Test]
    procedure Y47_T02_Read()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y47 QC Log";
    begin
        // What happened after the end of Y47_T01_LeftOpen_Enabled_NoHandler (the previous test of this codeunit).
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    procedure Y47_T03_LeftOpen_NotEnabled_ConfirmYes()
    var
        Row: Record "LT Y47 QC Row";
        Log: Codeunit "LT Y47 QC Log";
        Card: TestPage "LT Y47 QC Card";
    begin
        Log.Take();
        Seed();
        Row.Get('DIS');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Log.Add('test body end');
        // no Close(): the page is left open when the test ends
    end;

    [Test]
    procedure Y47_T04_Read()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y47 QC Log";
    begin
        // What happened after the end of Y47_T03_LeftOpen_NotEnabled_ConfirmYes (the previous test of this codeunit).
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ConfirmNo')]
    procedure Y47_T05_LeftOpen_NotEnabled_ConfirmNo()
    var
        Row: Record "LT Y47 QC Row";
        Log: Codeunit "LT Y47 QC Log";
        Card: TestPage "LT Y47 QC Card";
    begin
        Log.Take();
        Seed();
        Row.Get('DIS');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Log.Add('test body end');
        // no Close(): the page is left open when the test ends
    end;

    [Test]
    procedure Y47_T06_Read()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y47 QC Log";
    begin
        // What happened after the end of Y47_T05_LeftOpen_NotEnabled_ConfirmNo (the previous test of this codeunit).
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y47_T07_LeftOpen_Edited_NoHandler()
    var
        Row: Record "LT Y47 QC Row";
        Log: Codeunit "LT Y47 QC Log";
        Card: TestPage "LT Y47 QC Card";
    begin
        Log.Take();
        Seed();
        Row.Get('EN');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('edited');
        Log.Add('test body end');
        // no Close(): the page is left open when the test ends
    end;

    [Test]
    procedure Y47_T08_Read()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y47 QC Log";
    begin
        // What happened after the end of Y47_T07_LeftOpen_Edited_NoHandler (the previous test of this codeunit).
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y47_T09_LeftOpen_OpenView_NoHandler()
    var
        Row: Record "LT Y47 QC Row";
        Log: Codeunit "LT Y47 QC Log";
        Card: TestPage "LT Y47 QC Card";
    begin
        Log.Take();
        Seed();
        Row.Get('EN');
        Card.OpenView();
        Card.GoToRecord(Row);
        Log.Add('test body end');
    end;

    [Test]
    procedure Y47_T10_Read()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y47 QC Log";
    begin
        // What happened after the end of Y47_T09_LeftOpen_OpenView_NoHandler (the previous test of this codeunit).
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y47_T11_GlobalVariable_LeftOpen()
    var
        Row: Record "LT Y47 QC Row";
        Log: Codeunit "LT Y47 QC Log";
    begin
        Log.Take();
        Seed();
        Row.Get('EN');
        GlobalCard.OpenEdit();
        GlobalCard.GoToRecord(Row);
        Log.Add('test body end');
    end;

    [Test]
    procedure Y47_T12_GlobalVariable_NextTest()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y47 QC Log";
    begin
        Observer.Observe('log', Log.Take());
        ClearLastError();
        if TryReadGlobal() then
            Observer.Observe('stillOpen', 'Yes ' + LastCode)
        else
            Observer.Observe('stillOpen', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryCloseGlobal() then
            Observer.Observe('close', 'ok')
        else
            Observer.Observe('close', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe('logAfterClose', Log.Take());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryReadGlobal()
    begin
        LastCode := GlobalCard."Code".Value();
    end;

    [TryFunction]
    local procedure TryCloseGlobal()
    begin
        GlobalCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    procedure Y47_T13_ExplicitClose_NotEnabled_ConfirmYes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y47 QC Row";
        Log: Codeunit "LT Y47 QC Log";
        Card: TestPage "LT Y47 QC Card";
    begin
        Log.Take();
        Seed();
        Row.Get('DIS');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Close();
        Log.Add('after close');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [ConfirmHandler]
    procedure ConfirmYes(Question: Text; var Reply: Boolean)
    var
        Log: Codeunit "LT Y47 QC Log";
    begin
        Log.Add('handler yes: ' + Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmNo(Question: Text; var Reply: Boolean)
    var
        Log: Codeunit "LT Y47 QC Log";
    begin
        Log.Add('handler no: ' + Question);
        Reply := false;
    end;
}
