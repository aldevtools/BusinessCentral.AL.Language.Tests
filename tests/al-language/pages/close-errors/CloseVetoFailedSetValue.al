// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 75340 75341, pages 75342 75343 75344, log codeunit 75345, test codeunit 75346
// Probe (al-runner 7826 item 2): the cells next to CemDocumentTests.al DocumentStaticRunModal_HandlerTableRefusesReturns_NoError (handler
//   mode 8: the ModalPageHandler sets a Name that the table's OnModify refuses, through the field's OnValidate CurrPage.Update(), and
//   returns), with an OnQueryClosePage that vetoes (exit(false), logged). Cells: the Document page with a part opened by a static
//   Page.RunModal, and a List page opened with LookupMode(true) and RunModal; each with handler mode 8 and, for comparison, a handler that
//   only returns (mode 0).
// Observed (the CEM form): 'returned' only when RunModal came back (its result, the log and the rows); 'end' the error text and code
//   out of RunModal (CEM_NO_ERROR when it came back); 'log' the triggers in order (M-page = the page's OnModifyRecord, T-mod = the
//   table's OnModify, Q = OnQueryClosePage with its CloseAction, C = OnClosePage); 'rows' the stored rows afterwards.
// local object: the pages need their own vetoing OnQueryClosePage
// Facts: mode 8 raises the validation error out of RunModal before OnQueryClosePage runs (the veto never runs; Document: the text ends
//   with '(Select Refresh to discard errors)', lookup List: it does not); the rows are unchanged. A handler that returns: OnQueryClosePage
//   runs with LookupCancel, its veto is ignored, RunModal returns None and OnClosePage does not run. The lookup List is not editable.
// BC versions: 27, 28, 29

table 75340 "PG6 CV Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; Name; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnModify()
    var
        Log: Codeunit "PG6 CV Log";
    begin
        Log.Add('T-mod ' + Rec."Code" + ' ' + Rec.Name);
        if Rec.Name = 'FAILMOD' then
            Error('PG6 table modify refused');
    end;
}

table 75341 "PG6 CV Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; DocCode; Code[10]) { DataClassification = SystemMetadata; }
        field(2; LineNo; Integer) { DataClassification = SystemMetadata; }
        field(3; Qty; Decimal) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; DocCode, LineNo) { Clustered = true; }
    }
}

page 75342 "PG6 CV Lines Part"
{
    PageType = ListPart;
    SourceTable = "PG6 CV Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec.LineNo) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }
}

page 75343 "PG6 CV Doc"
{
    PageType = Document;
    SourceTable = "PG6 CV Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
            }
            part(Lines; "PG6 CV Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = DocCode = field("Code");
            }
        }
    }

    var
        Log: Codeunit "PG6 CV Log";

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M-doc ' + Rec.Name);
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('Q-doc ' + Format(CloseAction) + ' veto');
        exit(false);
    end;

    trigger OnClosePage()
    begin
        Log.Add('C-doc');
    end;
}

page 75344 "PG6 CV List"
{
    PageType = List;
    SourceTable = "PG6 CV Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "PG6 CV Log";

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M-list ' + Rec.Name);
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('Q-list ' + Format(CloseAction) + ' veto');
        exit(false);
    end;

    trigger OnClosePage()
    begin
        Log.Add('C-list');
    end;
}

codeunit 75345 "PG6 CV Log"
{
    SingleInstance = true;

    var
        Lines: Text;
        HandlerMode: Integer;

    procedure Reset(NewMode: Integer)
    begin
        Lines := '';
        HandlerMode := NewMode;
    end;

    procedure Mode(): Integer
    begin
        exit(HandlerMode);
    end;

    procedure Add(Line: Text)
    begin
        Lines += Line + '; ';
    end;

    procedure Peek(): Text
    begin
        exit(Lines);
    end;

    procedure Take() Result: Text
    begin
        Result := Lines;
        Lines := '';
    end;
}

codeunit 75346 "PG6 CV Close Veto"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "PG6 CV Log";

    local procedure Setup(Mode: Integer)
    var
        Row: Record "PG6 CV Row";
        Line: Record "PG6 CV Line";
    begin
        Row.DeleteAll();
        Line.DeleteAll();
        Row.Init();
        Row."Code" := 'R1';
        Row.Name := 'start';
        Row.Insert();
        Line.DocCode := 'R1';
        Line.LineNo := 1;
        Line.Qty := 1;
        Line.Insert();
        Commit();
        Log.Reset(Mode);
        ClearLastError();
    end;

    local procedure Names() Result: Text
    var
        Row: Record "PG6 CV Row";
    begin
        if Row.FindSet() then
            repeat
                Result += Row."Code" + '=' + Row.Name + ' ';
            until Row.Next() = 0;
        Result += '(' + Format(Row.Count()) + ' rows)';
    end;

    [Test]
    [HandlerFunctions('DocModal')]
    procedure Doc_VetoQueryClose_HandlerFailedSetValueReturns()
    var
        O: Codeunit "Probe Observer";
        Row: Record "PG6 CV Row";
        Res: Action;
    begin
        Setup(8);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"PG6 CV Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Log.Peek() + '| ' + Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Log.Take());
        O.Observe('rows', Names());
        O.Expect('end|text', 'Validation error for Field: Name,  Message = ''PG6 table modify refused (Select Refresh to discard errors)''');
        O.Expect('end|code', 'TestValidation');
        O.Expect('log', 'H-doc editable=Yes; M-doc FAILMOD; T-mod R1 FAILMOD; ');
        O.Expect('rows', 'R1=start (1 rows)');
        O.Verify();
    end;

    [Test]
    [HandlerFunctions('DocModal')]
    procedure Doc_VetoQueryClose_HandlerReturns()
    var
        O: Codeunit "Probe Observer";
        Row: Record "PG6 CV Row";
        Res: Action;
    begin
        Setup(0);
        Row.Get('R1');
        asserterror begin
            Res := Page.RunModal(Page::"PG6 CV Doc", Row);
            O.Observe('returned', Format(Res) + ' | ' + Log.Peek() + '| ' + Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Log.Take());
        O.Observe('rows', Names());
        O.Expect('returned', 'None | H-doc editable=Yes; Q-doc LookupCancel veto; | R1=start (1 rows)');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'H-doc editable=Yes; Q-doc LookupCancel veto; ');
        O.Expect('rows', 'R1=start (1 rows)');
        O.Verify();
    end;

    [Test]
    [HandlerFunctions('ListModal')]
    procedure LookupList_VetoQueryClose_HandlerFailedSetValueReturns()
    var
        O: Codeunit "Probe Observer";
        Row: Record "PG6 CV Row";
        L: Page "PG6 CV List";
        Res: Action;
    begin
        Setup(8);
        Row.Get('R1');
        asserterror begin
            L.LookupMode(true);
            L.SetRecord(Row);
            Res := L.RunModal();
            O.Observe('returned', Format(Res) + ' | ' + Log.Peek() + '| ' + Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Log.Take());
        O.Observe('rows', Names());
        O.Expect('end|text', 'Validation error for Field: Name,  Message = ''PG6 table modify refused''');
        O.Expect('end|code', 'TestValidation');
        O.Expect('log', 'H-list editable=No; M-list FAILMOD; T-mod R1 FAILMOD; ');
        O.Expect('rows', 'R1=start (1 rows)');
        O.Verify();
    end;

    [Test]
    [HandlerFunctions('ListModal')]
    procedure LookupList_VetoQueryClose_HandlerReturns()
    var
        O: Codeunit "Probe Observer";
        Row: Record "PG6 CV Row";
        L: Page "PG6 CV List";
        Res: Action;
    begin
        Setup(0);
        Row.Get('R1');
        asserterror begin
            L.LookupMode(true);
            L.SetRecord(Row);
            Res := L.RunModal();
            O.Observe('returned', Format(Res) + ' | ' + Log.Peek() + '| ' + Names());
            Error('CEM_NO_ERROR');
        end;
        O.ObserveError('end');
        O.Observe('log', Log.Take());
        O.Observe('rows', Names());
        O.Expect('returned', 'None | H-list editable=No; Q-list LookupCancel veto; | R1=start (1 rows)');
        O.Expect('end|text', 'CEM_NO_ERROR');
        O.Expect('end|code', 'Dialog');
        O.Expect('log', 'H-list editable=No; Q-list LookupCancel veto; ');
        O.Expect('rows', 'R1=start (1 rows)');
        O.Verify();
    end;

    [ModalPageHandler]
    procedure DocModal(var P: TestPage "PG6 CV Doc")
    begin
        Log.Add('H-doc editable=' + Format(P.Editable()));
        if Log.Mode() = 8 then
            P.Name.SetValue('FAILMOD');
    end;

    [ModalPageHandler]
    procedure ListModal(var P: TestPage "PG6 CV List")
    begin
        Log.Add('H-list editable=' + Format(P.Editable()));
        if Log.Mode() = 8 then
            P.Name.SetValue('FAILMOD');
    end;
}
