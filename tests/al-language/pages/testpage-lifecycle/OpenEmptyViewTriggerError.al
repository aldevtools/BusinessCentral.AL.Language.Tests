// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 88074, log 88085, pages 88100-88104, test codeunit 88091
// Probe: written against BC on the corpus CI matrix and local BC 27.5, 28.5 and 29.0; every literal asserted below is what that tier produced.
// Facts: a page of each type (Card, Document, ListPlus, List, Worksheet) over a table without rows, whose OnNewRecord or
//   OnAfterGetCurrRecord raises an error (runner issue 8340: the reporter measured that TestPage.OpenEdit of a Card whose OnNewRecord raises does not fail).
//   Each test opens with OpenEdit, OpenView or OpenNew (or Trap + Page.Run, Page.RunModal) inside a TryFunction and records whether the open raised and
//   with which text, the triggers that ran (log), the last error text after the open, the control value and whether Close raises. Neighbors: a failing
//   Get and a Message in OnNewRecord, a filter that empties the view after the open, an edit after the open.
// BC versions: all (CI)

table 88074 "TPL Open Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[50]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

page 88100 "TPL Open Card"
{
    PageType = Card;
    SourceTable = "TPL Open Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(DescF; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('OnAfterGetRecord ' + Rec."No.");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Other: Record "TPL Open Row";
    begin
        Log.Add('OnNewRecord');
        case Log.Mode() of
            'NewError':
                Error('OnNewRecord failed');
            'NewGet':
                Other.Get('MISSING');
            'NewMessage':
                Message('OnNewRecord message');
        end;
        Log.Add('OnNewRecord end');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('OnAfterGetCurrRecord ' + Rec."No.");
        if Log.Mode() = 'CurrError' then
            Error('OnAfterGetCurrRecord failed');
    end;

    var
        Log: Codeunit "TPL Open Log";
}

page 88101 "TPL Open Document"
{
    PageType = Document;
    SourceTable = "TPL Open Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(DescF; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('OnAfterGetRecord ' + Rec."No.");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Other: Record "TPL Open Row";
    begin
        Log.Add('OnNewRecord');
        case Log.Mode() of
            'NewError':
                Error('OnNewRecord failed');
            'NewGet':
                Other.Get('MISSING');
            'NewMessage':
                Message('OnNewRecord message');
        end;
        Log.Add('OnNewRecord end');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('OnAfterGetCurrRecord ' + Rec."No.");
        if Log.Mode() = 'CurrError' then
            Error('OnAfterGetCurrRecord failed');
    end;

    var
        Log: Codeunit "TPL Open Log";
}

page 88102 "TPL Open ListPlus"
{
    PageType = ListPlus;
    SourceTable = "TPL Open Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(DescF; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('OnAfterGetRecord ' + Rec."No.");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Other: Record "TPL Open Row";
    begin
        Log.Add('OnNewRecord');
        case Log.Mode() of
            'NewError':
                Error('OnNewRecord failed');
            'NewGet':
                Other.Get('MISSING');
            'NewMessage':
                Message('OnNewRecord message');
        end;
        Log.Add('OnNewRecord end');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('OnAfterGetCurrRecord ' + Rec."No.");
        if Log.Mode() = 'CurrError' then
            Error('OnAfterGetCurrRecord failed');
    end;

    var
        Log: Codeunit "TPL Open Log";
}

page 88103 "TPL Open List"
{
    PageType = List;
    SourceTable = "TPL Open Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(DescF; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('OnAfterGetRecord ' + Rec."No.");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Other: Record "TPL Open Row";
    begin
        Log.Add('OnNewRecord');
        case Log.Mode() of
            'NewError':
                Error('OnNewRecord failed');
            'NewGet':
                Other.Get('MISSING');
            'NewMessage':
                Message('OnNewRecord message');
        end;
        Log.Add('OnNewRecord end');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('OnAfterGetCurrRecord ' + Rec."No.");
        if Log.Mode() = 'CurrError' then
            Error('OnAfterGetCurrRecord failed');
    end;

    var
        Log: Codeunit "TPL Open Log";
}

page 88104 "TPL Open Worksheet"
{
    PageType = Worksheet;
    SourceTable = "TPL Open Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoF; Rec."No.") { ApplicationArea = All; }
                field(DescF; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('OnAfterGetRecord ' + Rec."No.");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Other: Record "TPL Open Row";
    begin
        Log.Add('OnNewRecord');
        case Log.Mode() of
            'NewError':
                Error('OnNewRecord failed');
            'NewGet':
                Other.Get('MISSING');
            'NewMessage':
                Message('OnNewRecord message');
        end;
        Log.Add('OnNewRecord end');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('OnAfterGetCurrRecord ' + Rec."No.");
        if Log.Mode() = 'CurrError' then
            Error('OnAfterGetCurrRecord failed');
    end;

    var
        Log: Codeunit "TPL Open Log";
}

codeunit 88085 "TPL Open Log"
{
    SingleInstance = true;

    var
        Buffer: Text;
        CurrentMode: Text;

    procedure Reset()
    begin
        Buffer := '';
        CurrentMode := '';
    end;

    procedure Add(Entry: Text)
    begin
        Buffer += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Buffer;
        Buffer := '';
        exit(Result);
    end;

    procedure SetMode(NewMode: Text)
    begin
        CurrentMode := NewMode;
    end;

    procedure Mode(): Text
    begin
        exit(CurrentMode);
    end;
}

codeunit 88091 "TPL Open Empty View"
{
    Subtype = Test;

    var
        Log: Codeunit "TPL Open Log";

    [Test]
    procedure Card_OpenEdit_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Card";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        if TryOpenEdit_Card(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Card(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Card(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Card_OpenView_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Card";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        if TryOpenView_Card(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Card(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Card(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Card_OpenNew_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Card";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        if TryOpenNew_Card(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Card(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Card(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Card_OpenEdit_CurrRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Card";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('CurrError');
        if TryOpenEdit_Card(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Card(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Card(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Document_OpenEdit_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Document";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        if TryOpenEdit_Document(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Document(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Document(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Document_OpenView_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Document";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        if TryOpenView_Document(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Document(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Document(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Document_OpenNew_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Document";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        if TryOpenNew_Document(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Document(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Document(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Document_OpenEdit_CurrRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Document";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('CurrError');
        if TryOpenEdit_Document(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Document(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Document(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure ListPlus_OpenEdit_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open ListPlus";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        if TryOpenEdit_ListPlus(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_ListPlus(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_ListPlus(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure ListPlus_OpenView_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open ListPlus";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        if TryOpenView_ListPlus(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_ListPlus(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_ListPlus(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure ListPlus_OpenNew_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open ListPlus";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        if TryOpenNew_ListPlus(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_ListPlus(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_ListPlus(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure ListPlus_OpenEdit_CurrRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open ListPlus";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('CurrError');
        if TryOpenEdit_ListPlus(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_ListPlus(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_ListPlus(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure List_OpenEdit_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open List";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        if TryOpenEdit_List(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_List(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_List(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure List_OpenView_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open List";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        if TryOpenView_List(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_List(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_List(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure List_OpenNew_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open List";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        if TryOpenNew_List(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_List(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_List(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure List_OpenEdit_CurrRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open List";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('CurrError');
        if TryOpenEdit_List(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_List(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_List(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_OpenEdit_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Worksheet";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        if TryOpenEdit_Worksheet(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Worksheet(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Worksheet(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_OpenView_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Worksheet";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        if TryOpenView_Worksheet(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Worksheet(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Worksheet(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_OpenNew_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Worksheet";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        if TryOpenNew_Worksheet(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Worksheet(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Worksheet(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_OpenEdit_CurrRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Worksheet";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('CurrError');
        if TryOpenEdit_Worksheet(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Worksheet(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Worksheet(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Card_OpenEdit_NewRecordGetFails()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Card";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewGet');
        if TryOpenEdit_Card(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Card(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Card(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageLogger')]
    procedure Card_OpenEdit_NewRecordMessage_Handler()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Card";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewMessage');
        if TryOpenEdit_Card(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Card(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Card(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Message('end');
        Observer.Finish();
    end;

    [Test]
    procedure Card_OpenEdit_NewRecordMessage_NoHandler()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Card";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewMessage');
        if TryOpenEdit_Card(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Card(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Card(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Card_FilterEmptiesView_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Card";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Row."No." := 'R1';
        Row.Insert();
        Log.SetMode('NewError');
        if TryOpenEdit_Card(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('logOpen', Log.Take());
        if TryFilterEmpty_Card(P) then
            Observer.Observe('filter', 'ok')
        else
            Observer.ObserveError('filter');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Card(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Card(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure List_FilterEmptiesView_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open List";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Row."No." := 'R1';
        Row.Insert();
        Log.SetMode('NewError');
        if TryOpenEdit_List(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('logOpen', Log.Take());
        if TryFilterEmpty_List(P) then
            Observer.Observe('filter', 'ok')
        else
            Observer.ObserveError('filter');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_List(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_List(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_FilterEmptiesView_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Worksheet";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Row."No." := 'R1';
        Row.Insert();
        Log.SetMode('NewError');
        if TryOpenEdit_Worksheet(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('logOpen', Log.Take());
        if TryFilterEmpty_Worksheet(P) then
            Observer.Observe('filter', 'ok')
        else
            Observer.ObserveError('filter');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Worksheet(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Worksheet(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Card_TrapPageRun_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Card";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        P.Trap();
        if TryRun_Card() then
            Observer.Observe('run', 'ok')
        else
            Observer.ObserveError('run');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_Card(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_Card(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure List_TrapPageRun_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open List";
        Value: Text;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        P.Trap();
        if TryRun_List() then
            Observer.Observe('run', 'ok')
        else
            Observer.ObserveError('run');
        Observer.Observe('log', Log.Take());
        Observer.Observe('lastError', GetLastErrorText());
        ClearLastError();
        if TryValue_List(P, Value) then
            Observer.Observe('no', Value)
        else
            Observer.ObserveError('no');
        if TryClose_List(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardModalHandler')]
    procedure Card_RunModal_NewRecordError()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Commit();
        Log.SetMode('NewError');
        if TryRunModal_Card() then
            Observer.Observe('runModal', 'ok')
        else
            Observer.ObserveError('runModal');
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Card_OpenEdit_NewRecordError_ThenEdit()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open Card";
        RowCount: Integer;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        if TryOpenEdit_Card(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        ClearLastError();
        P.NoF.SetValue('N1');
        P.DescF.SetValue('typed');
        Observer.Observe('logEdit', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        RowCount := Row.Count();
        Observer.Observe('rows', Format(RowCount));
        Observer.Finish();
    end;

    [Test]
    procedure List_OpenEdit_NewRecordError_ThenEdit()
    var
        Row: Record "TPL Open Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Open List";
        RowCount: Integer;
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Log.SetMode('NewError');
        if TryOpenEdit_List(P) then
            Observer.Observe('open', 'ok')
        else
            Observer.ObserveError('open');
        Observer.Observe('log', Log.Take());
        ClearLastError();
        P.NoF.SetValue('N1');
        P.DescF.SetValue('typed');
        Observer.Observe('logEdit', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        RowCount := Row.Count();
        Observer.Observe('rows', Format(RowCount));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryOpenEdit_Card(var P: TestPage "TPL Open Card")
    begin
        P.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenView_Card(var P: TestPage "TPL Open Card")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryOpenNew_Card(var P: TestPage "TPL Open Card")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryClose_Card(var P: TestPage "TPL Open Card")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryValue_Card(var P: TestPage "TPL Open Card"; var Value: Text)
    begin
        Value := P.NoF.Value();
    end;

    [TryFunction]
    local procedure TryFilterEmpty_Card(var P: TestPage "TPL Open Card")
    begin
        P.Filter.SetFilter("No.", 'NOPE');
    end;

    [TryFunction]
    local procedure TryOpenEdit_Document(var P: TestPage "TPL Open Document")
    begin
        P.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenView_Document(var P: TestPage "TPL Open Document")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryOpenNew_Document(var P: TestPage "TPL Open Document")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryClose_Document(var P: TestPage "TPL Open Document")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryValue_Document(var P: TestPage "TPL Open Document"; var Value: Text)
    begin
        Value := P.NoF.Value();
    end;

    [TryFunction]
    local procedure TryFilterEmpty_Document(var P: TestPage "TPL Open Document")
    begin
        P.Filter.SetFilter("No.", 'NOPE');
    end;

    [TryFunction]
    local procedure TryOpenEdit_ListPlus(var P: TestPage "TPL Open ListPlus")
    begin
        P.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenView_ListPlus(var P: TestPage "TPL Open ListPlus")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryOpenNew_ListPlus(var P: TestPage "TPL Open ListPlus")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryClose_ListPlus(var P: TestPage "TPL Open ListPlus")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryValue_ListPlus(var P: TestPage "TPL Open ListPlus"; var Value: Text)
    begin
        Value := P.NoF.Value();
    end;

    [TryFunction]
    local procedure TryFilterEmpty_ListPlus(var P: TestPage "TPL Open ListPlus")
    begin
        P.Filter.SetFilter("No.", 'NOPE');
    end;

    [TryFunction]
    local procedure TryOpenEdit_List(var P: TestPage "TPL Open List")
    begin
        P.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenView_List(var P: TestPage "TPL Open List")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryOpenNew_List(var P: TestPage "TPL Open List")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryClose_List(var P: TestPage "TPL Open List")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryValue_List(var P: TestPage "TPL Open List"; var Value: Text)
    begin
        Value := P.NoF.Value();
    end;

    [TryFunction]
    local procedure TryFilterEmpty_List(var P: TestPage "TPL Open List")
    begin
        P.Filter.SetFilter("No.", 'NOPE');
    end;

    [TryFunction]
    local procedure TryOpenEdit_Worksheet(var P: TestPage "TPL Open Worksheet")
    begin
        P.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenView_Worksheet(var P: TestPage "TPL Open Worksheet")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryOpenNew_Worksheet(var P: TestPage "TPL Open Worksheet")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryClose_Worksheet(var P: TestPage "TPL Open Worksheet")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryValue_Worksheet(var P: TestPage "TPL Open Worksheet"; var Value: Text)
    begin
        Value := P.NoF.Value();
    end;

    [TryFunction]
    local procedure TryFilterEmpty_Worksheet(var P: TestPage "TPL Open Worksheet")
    begin
        P.Filter.SetFilter("No.", 'NOPE');
    end;

    [TryFunction]
    local procedure TryRun_Card()
    begin
        Page.Run(Page::"TPL Open Card");
    end;

    [TryFunction]
    local procedure TryRun_List()
    begin
        Page.Run(Page::"TPL Open List");
    end;

    [TryFunction]
    local procedure TryRunModal_Card()
    begin
        Page.RunModal(Page::"TPL Open Card");
    end;

    [MessageHandler]
    procedure MessageLogger(Msg: Text[1024])
    begin
        Log.Add('message ' + Msg);
    end;

    [ModalPageHandler]
    procedure CardModalHandler(var P: TestPage "TPL Open Card")
    begin
        Log.Add('handler no=[' + P.NoF.Value() + ']');
    end;
}
