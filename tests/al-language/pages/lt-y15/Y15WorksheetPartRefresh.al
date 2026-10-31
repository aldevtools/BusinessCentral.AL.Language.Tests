// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 91700 - 91709 (writer Y15)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: al-runner issue 6465. A Worksheet page without a source table has a global Choice (an enum) and an unlinked ListPart whose
//   source table is temporary. OnOpenPage passes the choice to the part and fills the part's temporary table (row 1, 'A').
//   The part's OnAfterGetRecord computes the control Summary from Description: '(A)' when the choice is Changed, else 'A'.
//   Choice's OnValidate passes the new choice to the part and calls CurrPage.Update(false) (page 91703); page 91704 does the
//   same without CurrPage.Update. The part logs its OnAfterGetRecord and OnAfterGetCurrRecord calls.
// Source: al-runner issue 6465 (the reporter's repro passed on a real BC 29 container).
// BC versions: 27, 28, 29

enum 91700 "LT Y15 Choice"
{
    Extensible = false;
    value(0; Initial) { }
    value(1; Changed) { }
}

table 91701 "LT Y15 Part Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Description; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 91702 "LT Y15 Part Rows"
{
    PageType = ListPart;
    SourceTable = "LT Y15 Part Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Summary; Summary)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Summary := Rec.Description;
        if (Summary <> '') and (CurrentChoice = CurrentChoice::Changed) then
            Summary := '(' + Summary + ')';
        Log.Add('AGR' + Format(Rec."No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('AGCR' + Format(Rec."No."));
    end;

    procedure SetChoice(NewChoice: Enum "LT Y15 Choice")
    begin
        CurrentChoice := NewChoice;
    end;

    procedure SetRows()
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := 1;
        Rec.Description := 'A';
        Rec.Insert();
    end;

    procedure AddRow(No: Integer; Description: Text[30])
    begin
        Rec.Init();
        Rec."No." := No;
        Rec.Description := Description;
        Rec.Insert();
    end;

    var
        Log: Codeunit "LT Y15 Part Log";
        CurrentChoice: Enum "LT Y15 Choice";
        Summary: Text[100];
}

page 91703 "LT Y15 Part Worksheet"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(Choice; CurrentChoice)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CurrPage.Rows.Page.SetChoice(CurrentChoice);
                        CurrPage.Update(false);
                    end;
                }
            }
            part(Rows; "LT Y15 Part Rows")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Rows.Page.SetChoice(CurrentChoice);
        CurrPage.Rows.Page.SetRows();
        if WithSecondRow then
            CurrPage.Rows.Page.AddRow(2, 'B');
    end;

    procedure SetWithSecondRow(NewWithSecondRow: Boolean)
    begin
        WithSecondRow := NewWithSecondRow;
    end;

    var
        CurrentChoice: Enum "LT Y15 Choice";
        WithSecondRow: Boolean;
}

page 91704 "LT Y15 Part Worksheet NoUpd"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(Choice; CurrentChoice)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CurrPage.Rows.Page.SetChoice(CurrentChoice);
                    end;
                }
            }
            part(Rows; "LT Y15 Part Rows")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Rows.Page.SetChoice(CurrentChoice);
        CurrPage.Rows.Page.SetRows();
    end;

    var
        CurrentChoice: Enum "LT Y15 Choice";
}

codeunit 91708 "LT Y15 Part Log"
{
    SingleInstance = true;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    var
        Entries: Text;
}

codeunit 91709 "LT Y15 Part Refresh Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y15 Part Log";

    // The reporter's shape: RunModal and a ModalPageHandler; First on the part before and after Choice.SetValue.
    [Test]
    [HandlerFunctions('ReporterHandler')]
    procedure Y15_PartRefresh_ReporterShape()
    var
        Worksheet: Page "LT Y15 Part Worksheet";
    begin
        Log.Take();
        Worksheet.RunModal();
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure ReporterHandler(var Worksheet: TestPage "LT Y15 Part Worksheet")
    begin
        Observer.Observe('open log', Log.Take());
        Observer.Observe('first before', Format(Worksheet.Rows.First(), 0, 9) + '/' + Worksheet.Rows.Summary.Value());
        Observer.Observe('first before log', Log.Take());
        Worksheet.Choice.SetValue('Changed');
        Observer.Observe('setvalue log', Log.Take());
        Observer.Observe('summary after setvalue', Worksheet.Rows."No.".Value() + '/' + Worksheet.Rows.Summary.Value());
        Observer.Observe('first after', Format(Worksheet.Rows.First(), 0, 9) + '/' + Worksheet.Rows.Summary.Value());
        Observer.Observe('first after log', Log.Take());
        Observer.Observe('choice', Worksheet.Choice.Value());
        Worksheet.OK().Invoke();
    end;

    // The same through TestPage.OpenEdit, and back to Initial.
    [Test]
    procedure Y15_PartRefresh_OpenEdit()
    var
        Worksheet: TestPage "LT Y15 Part Worksheet";
    begin
        Log.Take();
        Worksheet.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('summary at open', Worksheet.Rows."No.".Value() + '/' + Worksheet.Rows.Summary.Value());
        Worksheet.Choice.SetValue('Changed');
        Observer.Observe('setvalue log', Log.Take());
        Observer.Observe('summary after setvalue', Worksheet.Rows."No.".Value() + '/' + Worksheet.Rows.Summary.Value());
        Worksheet.Choice.SetValue('Initial');
        Observer.Observe('setvalue initial log', Log.Take());
        Observer.Observe('summary after initial', Worksheet.Rows."No.".Value() + '/' + Worksheet.Rows.Summary.Value());
        Worksheet.Close();
        Observer.Finish();
    end;

    // Two part rows: at open the part stands on row 2 (the row inserted last); Previous moves it to row 1, then Choice is validated:
    // which row the part shows and what Summary each row shows.
    [Test]
    procedure Y15_PartRefresh_TwoRowsPartOnFirst()
    var
        Worksheet: TestPage "LT Y15 Part Worksheet";
        WorksheetPage: Page "LT Y15 Part Worksheet";
    begin
        Log.Take();
        Worksheet.Trap();
        WorksheetPage.SetWithSecondRow(true);
        WorksheetPage.Run();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('at open', Worksheet.Rows."No.".Value() + '/' + Worksheet.Rows.Summary.Value());
        Observer.Observe('previous', Format(Worksheet.Rows.Previous(), 0, 9) + '/' + Worksheet.Rows."No.".Value() + '/' + Worksheet.Rows.Summary.Value());
        Log.Take();
        Worksheet.Choice.SetValue('Changed');
        Observer.Observe('setvalue log', Log.Take());
        Observer.Observe('after setvalue', Worksheet.Rows."No.".Value() + '/' + Worksheet.Rows.Summary.Value());
        Observer.Observe('next', Format(Worksheet.Rows.Next(), 0, 9) + '/' + Worksheet.Rows."No.".Value() + '/' + Worksheet.Rows.Summary.Value());
        Observer.Observe('first', Format(Worksheet.Rows.First(), 0, 9) + '/' + Worksheet.Rows."No.".Value() + '/' + Worksheet.Rows.Summary.Value());
        Observer.Observe('last', Format(Worksheet.Rows.Last(), 0, 9) + '/' + Worksheet.Rows."No.".Value() + '/' + Worksheet.Rows.Summary.Value());
        Worksheet.Close();
        Observer.Finish();
    end;

    // Contrast: OnValidate passes the choice but does not call CurrPage.Update.
    [Test]
    procedure Y15_PartRefresh_NoUpdate()
    var
        Worksheet: TestPage "LT Y15 Part Worksheet NoUpd";
    begin
        Log.Take();
        Worksheet.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('summary at open', Worksheet.Rows."No.".Value() + '/' + Worksheet.Rows.Summary.Value());
        Worksheet.Choice.SetValue('Changed');
        Observer.Observe('setvalue log', Log.Take());
        Observer.Observe('summary after setvalue', Worksheet.Rows."No.".Value() + '/' + Worksheet.Rows.Summary.Value());
        Observer.Observe('first', Format(Worksheet.Rows.First(), 0, 9) + '/' + Worksheet.Rows.Summary.Value());
        Observer.Observe('first log', Log.Take());
        Worksheet.Close();
        Observer.Finish();
    end;
}
