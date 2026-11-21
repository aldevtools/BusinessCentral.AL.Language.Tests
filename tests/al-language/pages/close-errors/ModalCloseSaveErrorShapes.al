// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 76700..76706
// local object: the pages need switchable failing OnModifyRecord and OnInsertRecord triggers and no OnQueryClosePage
// Probe (al-runner issue 7400): a ModalPageHandler edits the row and returns; the platform closes the page and saves the row, and the
//   save raises. CemModalHandlerTests.al pins this for a Card and a List that have OnQueryClosePage and an Error() in OnModifyRecord
//   (RunModal fails with the error's text and the code TestWrapped). This file reads the shapes it leaves open: pages without
//   OnQueryClosePage, a TestField error raised through Codeunit.Run of a TableNo codeunit (the report) and directly, a Worksheet, a
//   new row whose OnInsertRecord raises, and a Page variable in LookupMode. Each cell records how RunModal ended (text and code),
//   the trigger log and the stored row.
// Measured by the corpus CI matrix (BC 27.5, 28.5, 29.0, run 43078862011); the values are the same on all three.
// BC versions: 27, 28, 29

table 76700 "MCS Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Canceled; Boolean) { }
        field(3; "Pay Code"; Code[10]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 76701 "MCS Entry Edit"
{
    TableNo = "MCS Entry";

    trigger OnRun()
    begin
        Rec.TestField(Canceled, false);
        Rec.Modify();
    end;
}

codeunit 76702 "MCS Cfg"
{
    SingleInstance = true;

    var
        Mode: Text;
        Log: Text;

    procedure Set(NewMode: Text)
    begin
        Mode := NewMode;
        Log := '';
    end;

    procedure Add(Value: Text)
    begin
        Log += Value + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;

    procedure ModRec(Where: Text; var Entry: Record "MCS Entry")
    begin
        Add('M-' + Where + ' ' + Entry."Pay Code");
        case Mode of
            'cu':
                Codeunit.Run(Codeunit::"MCS Entry Edit", Entry);
            'testfield':
                Entry.TestField(Canceled, false);
            'error':
                Error('MCS page modify error');
        end;
    end;

    procedure InsRec(Where: Text; var Entry: Record "MCS Entry")
    begin
        Add('I-' + Where + ' ' + Entry."Code");
        if Mode = 'insert' then
            Error('MCS page insert error');
    end;
}

page 76703 "MCS List"
{
    PageType = List;
    SourceTable = "MCS Entry";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Canceled; Rec.Canceled) { ApplicationArea = All; }
                field("Pay Code"; Rec."Pay Code") { ApplicationArea = All; }
            }
        }
    }

    var
        Cfg: Codeunit "MCS Cfg";

    trigger OnModifyRecord(): Boolean
    begin
        Cfg.ModRec('list', Rec);
        exit(false);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Cfg.InsRec('list', Rec);
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Cfg.Add('C-list');
    end;
}

page 76704 "MCS Card"
{
    PageType = Card;
    SourceTable = "MCS Entry";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Canceled; Rec.Canceled) { ApplicationArea = All; }
            field("Pay Code"; Rec."Pay Code") { ApplicationArea = All; }
        }
    }

    var
        Cfg: Codeunit "MCS Cfg";

    trigger OnModifyRecord(): Boolean
    begin
        Cfg.ModRec('card', Rec);
        exit(false);
    end;

    trigger OnClosePage()
    begin
        Cfg.Add('C-card');
    end;
}

page 76705 "MCS Worksheet"
{
    PageType = Worksheet;
    SourceTable = "MCS Entry";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Canceled; Rec.Canceled) { ApplicationArea = All; }
                field("Pay Code"; Rec."Pay Code") { ApplicationArea = All; }
            }
        }
    }

    var
        Cfg: Codeunit "MCS Cfg";

    trigger OnModifyRecord(): Boolean
    begin
        Cfg.ModRec('ws', Rec);
        exit(false);
    end;

    trigger OnClosePage()
    begin
        Cfg.Add('C-ws');
    end;
}

codeunit 76706 "MCS Modal Close Save Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Cfg: Codeunit "MCS Cfg";

    local procedure Seed(Mode: Text; var Entry: Record "MCS Entry")
    var
        Old: Record "MCS Entry";
    begin
        Old.DeleteAll();
        Entry.Init();
        Entry."Code" := 'E1';
        Entry.Canceled := true;
        Entry."Pay Code" := 'OLD';
        Entry.Insert();
        Commit();
        Cfg.Set(Mode);
    end;

    local procedure Rows(): Text
    var
        Entry: Record "MCS Entry";
        Result: Text;
    begin
        if Entry.FindSet() then
            repeat
                Result += Entry."Code" + '=' + Format(Entry.Canceled) + '/' + Entry."Pay Code" + ' ';
            until Entry.Next() = 0;
        exit(Result + '(' + Format(Entry.Count()) + ' rows)');
    end;

    local procedure CleanUp()
    var
        Old: Record "MCS Entry";
    begin
        Old.DeleteAll();
        Commit();
        Cfg.Set('');
    end;

    local procedure Wrap(var Observer: Codeunit "Probe Observer")
    begin
        Observer.ObserveError('end');
        Observer.Observe('log', Cfg.Take());
        Observer.Observe('rows', Rows());
        CleanUp();
    end;

    // The report: a List without OnQueryClosePage whose OnModifyRecord runs a TableNo codeunit that calls TestField.
    [Test]
    [HandlerFunctions('ListEditReturns')]
    procedure List_CodeunitTestField_HandlerEditReturns()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "MCS Entry";
    begin
        Seed('cu', Entry);
        Entry.SetRange("Code", 'E1');
        asserterror begin
            Observer.Observe('returned', Format(Page.RunModal(Page::"MCS List", Entry)) + ' | ' + Cfg.Take());
            Error('MCS_NO_ERROR');
        end;
        Wrap(Observer);
        Observer.Expect('end|text', 'Canceled must be equal to ''No''  in MCS Entry: Code=E1. Current value is ''Yes''.');
        Observer.Expect('end|code', 'TestField');
        Observer.Expect('log', 'M-list NEW;M-list NEW;');
        Observer.Expect('rows', 'E1=Yes/OLD (1 rows)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListEditReturns')]
    procedure List_TestField_HandlerEditReturns()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "MCS Entry";
    begin
        Seed('testfield', Entry);
        Entry.SetRange("Code", 'E1');
        asserterror begin
            Observer.Observe('returned', Format(Page.RunModal(Page::"MCS List", Entry)) + ' | ' + Cfg.Take());
            Error('MCS_NO_ERROR');
        end;
        Wrap(Observer);
        Observer.Expect('end|text', 'Canceled must be equal to ''No''  in MCS Entry: Code=E1. Current value is ''Yes''.');
        Observer.Expect('end|code', 'TestField');
        Observer.Expect('log', 'M-list NEW;M-list NEW;');
        Observer.Expect('rows', 'E1=Yes/OLD (1 rows)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListEditReturns')]
    procedure List_Error_HandlerEditReturns()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "MCS Entry";
    begin
        Seed('error', Entry);
        Entry.SetRange("Code", 'E1');
        asserterror begin
            Observer.Observe('returned', Format(Page.RunModal(Page::"MCS List", Entry)) + ' | ' + Cfg.Take());
            Error('MCS_NO_ERROR');
        end;
        Wrap(Observer);
        Observer.Expect('end|text', 'MCS page modify error');
        Observer.Expect('end|code', 'TestWrapped');
        Observer.Expect('log', 'M-list NEW;');
        Observer.Expect('rows', 'E1=Yes/OLD (1 rows)');
        Observer.Verify();
    end;

    // The same error reaching the test without asserterror around RunModal is not observable here; GetLastErrorCode after it is.
    [Test]
    [HandlerFunctions('ListEditReturns')]
    procedure List_CodeunitTestField_LastErrorCode()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "MCS Entry";
    begin
        Seed('cu', Entry);
        Entry.SetRange("Code", 'E1');
        asserterror Page.RunModal(Page::"MCS List", Entry);
        Observer.Observe('last|text', GetLastErrorText());
        Observer.Observe('last|code', GetLastErrorCode());
        Wrap(Observer);
        Observer.Expect('last|text', 'Canceled must be equal to ''No''  in MCS Entry: Code=E1. Current value is ''Yes''.');
        Observer.Expect('last|code', 'TestField');
        Observer.Expect('end|text', 'Canceled must be equal to ''No''  in MCS Entry: Code=E1. Current value is ''Yes''.');
        Observer.Expect('end|code', 'TestField');
        Observer.Expect('log', 'M-list NEW;M-list NEW;');
        Observer.Expect('rows', 'E1=Yes/OLD (1 rows)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardEditReturns')]
    procedure Card_CodeunitTestField_HandlerEditReturns()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "MCS Entry";
    begin
        Seed('cu', Entry);
        asserterror begin
            Observer.Observe('returned', Format(Page.RunModal(Page::"MCS Card", Entry)) + ' | ' + Cfg.Take());
            Error('MCS_NO_ERROR');
        end;
        Wrap(Observer);
        Observer.Expect('end|text', 'Canceled must be equal to ''No''  in MCS Entry: Code=E1. Current value is ''Yes''.');
        Observer.Expect('end|code', 'TestField');
        Observer.Expect('log', 'M-card NEW;M-card NEW;');
        Observer.Expect('rows', 'E1=Yes/OLD (1 rows)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardEditReturns')]
    procedure Card_Error_HandlerEditReturns()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "MCS Entry";
    begin
        Seed('error', Entry);
        asserterror begin
            Observer.Observe('returned', Format(Page.RunModal(Page::"MCS Card", Entry)) + ' | ' + Cfg.Take());
            Error('MCS_NO_ERROR');
        end;
        Wrap(Observer);
        Observer.Expect('end|text', 'MCS page modify error');
        Observer.Expect('end|code', 'TestWrapped');
        Observer.Expect('log', 'M-card NEW;');
        Observer.Expect('rows', 'E1=Yes/OLD (1 rows)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WorksheetEditReturns')]
    procedure Worksheet_Error_HandlerEditReturns()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "MCS Entry";
    begin
        Seed('error', Entry);
        Entry.SetRange("Code", 'E1');
        asserterror begin
            Observer.Observe('returned', Format(Page.RunModal(Page::"MCS Worksheet", Entry)) + ' | ' + Cfg.Take());
            Error('MCS_NO_ERROR');
        end;
        Wrap(Observer);
        Observer.Expect('end|text', 'MCS page modify error');
        Observer.Expect('end|code', 'TestWrapped');
        Observer.Expect('log', 'M-ws NEW;');
        Observer.Expect('rows', 'E1=Yes/OLD (1 rows)');
        Observer.Verify();
    end;

    // A new row typed in the handler, whose OnInsertRecord raises when the platform saves it at close.
    [Test]
    [HandlerFunctions('ListNewReturns')]
    procedure List_InsertRecordError_HandlerNewReturns()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "MCS Entry";
    begin
        Seed('insert', Entry);
        asserterror begin
            Observer.Observe('returned', Format(Page.RunModal(Page::"MCS List", Entry)) + ' | ' + Cfg.Take());
            Error('MCS_NO_ERROR');
        end;
        Wrap(Observer);
        Observer.Expect('end|text', 'MCS page insert error');
        Observer.Expect('end|code', 'TestWrapped');
        Observer.Expect('log', 'I-list N1;');
        Observer.Expect('rows', 'E1=Yes/OLD (1 rows)');
        Observer.Verify();
    end;

    // A Page variable in LookupMode, the handler edits and returns, OnModifyRecord raises.
    [Test]
    [HandlerFunctions('ListEditReturns')]
    procedure ListVariableLookupMode_Error_HandlerEditReturns()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "MCS Entry";
        ListPage: Page "MCS List";
    begin
        Seed('error', Entry);
        Entry.SetRange("Code", 'E1');
        ListPage.SetTableView(Entry);
        ListPage.LookupMode(true);
        asserterror begin
            Observer.Observe('returned', Format(ListPage.RunModal()) + ' | ' + Cfg.Take());
            Error('MCS_NO_ERROR');
        end;
        Wrap(Observer);
        Observer.Expect('end|text', 'MCS page modify error');
        Observer.Expect('end|code', 'TestWrapped');
        Observer.Expect('log', 'M-list NEW;');
        Observer.Expect('rows', 'E1=Yes/OLD (1 rows)');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure ListEditReturns(var P: TestPage "MCS List")
    begin
        P.First();
        P."Pay Code".SetValue('NEW');
    end;

    [ModalPageHandler]
    procedure CardEditReturns(var P: TestPage "MCS Card")
    begin
        P."Pay Code".SetValue('NEW');
    end;

    [ModalPageHandler]
    procedure WorksheetEditReturns(var P: TestPage "MCS Worksheet")
    begin
        P.First();
        P."Pay Code".SetValue('NEW');
    end;

    [ModalPageHandler]
    procedure ListNewReturns(var P: TestPage "MCS List")
    begin
        P.New();
        P."Code".SetValue('N1');
        P."Pay Code".SetValue('NEW');
    end;
}
