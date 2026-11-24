// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 88075, log 88086, pages 88105-88128, test codeunit 88092
// Probe: written against BC on the corpus CI matrix and local BC 27.5, 28.5 and 29.0; every literal asserted below is what that tier produced.
// Facts: a row edited with TestPage SetValue, then an action that reads the row from the table (runner issue 8342: the
//   reporter measured on a Worksheet with OnAfterGetCurrRecord that the action reads the new value). Each page type (Card, Document, ListPlus, List,
//   Worksheet) with no row trigger, OnAfterGetRecord, OnAfterGetCurrRecord or both; a Worksheet with a part (shown and hidden) and a Card with a part;
//   a Worksheet New() row. The log holds the table's OnModify / OnInsert and what the action read from the table (stored) and from Rec.
// BC versions: all (CI)

table 88075 "TPL Save Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }

    trigger OnInsert()
    begin
        Log.Add('OnInsert ' + Rec."Code" + ' ' + Rec.Name);
    end;

    trigger OnModify()
    begin
        Log.Add('OnModify ' + Rec."Code" + ' ' + Rec.Name);
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88105 "TPL Save Card None"
{
    PageType = Card;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    var
        Log: Codeunit "TPL Save Log";
}

page 88106 "TPL Save Card AGR"
{
    PageType = Card;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88107 "TPL Save Card AGCR"
{
    PageType = Card;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88108 "TPL Save Card Both"
{
    PageType = Card;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88109 "TPL Save Document None"
{
    PageType = Document;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    var
        Log: Codeunit "TPL Save Log";
}

page 88110 "TPL Save Document AGR"
{
    PageType = Document;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88111 "TPL Save Document AGCR"
{
    PageType = Document;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88112 "TPL Save Document Both"
{
    PageType = Document;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88113 "TPL Save ListPlus None"
{
    PageType = ListPlus;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    var
        Log: Codeunit "TPL Save Log";
}

page 88114 "TPL Save ListPlus AGR"
{
    PageType = ListPlus;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88115 "TPL Save ListPlus AGCR"
{
    PageType = ListPlus;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88116 "TPL Save ListPlus Both"
{
    PageType = ListPlus;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88117 "TPL Save List None"
{
    PageType = List;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    var
        Log: Codeunit "TPL Save Log";
}

page 88118 "TPL Save List AGR"
{
    PageType = List;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88119 "TPL Save List AGCR"
{
    PageType = List;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88120 "TPL Save List Both"
{
    PageType = List;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88121 "TPL Save Worksheet None"
{
    PageType = Worksheet;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    var
        Log: Codeunit "TPL Save Log";
}

page 88122 "TPL Save Worksheet AGR"
{
    PageType = Worksheet;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88123 "TPL Save Worksheet AGCR"
{
    PageType = Worksheet;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88124 "TPL Save Worksheet Both"
{
    PageType = Worksheet;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88125 "TPL Save Part"
{
    PageType = ListPart;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
            }
        }
    }
}

page 88126 "TPL Save Ws Part"
{
    PageType = Worksheet;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
            part(Lines; "TPL Save Part") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88127 "TPL Save Ws HiddenPart"
{
    PageType = Worksheet;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
            part(Lines; "TPL Save Part") { ApplicationArea = All; Visible = false; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

page 88128 "TPL Save Card Part"
{
    PageType = Card;
    SourceTable = "TPL Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeF; Rec."Code") { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
            part(Lines; "TPL Save Part") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadBack)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Stored: Record "TPL Save Row";
                begin
                    if Stored.Get(Rec."Code") then
                        Log.Add('action stored=' + Stored.Name + ' rec=' + Rec.Name)
                    else
                        Log.Add('action stored=missing rec=' + Rec.Name);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
    end;

    var
        Log: Codeunit "TPL Save Log";
}

codeunit 88086 "TPL Save Log"
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

codeunit 88092 "TPL Save Before Action"
{
    Subtype = Test;

    var
        Log: Codeunit "TPL Save Log";

    [Test]
    procedure Card_None_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save Card None";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Card_AGR_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save Card AGR";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Card_AGCR_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save Card AGCR";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Card_Both_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save Card Both";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Document_None_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save Document None";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Document_AGR_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save Document AGR";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Document_AGCR_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save Document AGCR";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Document_Both_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save Document Both";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure ListPlus_None_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save ListPlus None";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure ListPlus_AGR_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save ListPlus AGR";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure ListPlus_AGCR_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save ListPlus AGCR";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure ListPlus_Both_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save ListPlus Both";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure List_None_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save List None";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure List_AGR_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save List AGR";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure List_AGCR_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save List AGCR";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure List_Both_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save List Both";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_None_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save Worksheet None";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_AGR_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save Worksheet AGR";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_AGCR_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save Worksheet AGCR";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_Both_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save Worksheet Both";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_AGCR_PartShown_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save Ws Part";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_AGCR_PartHidden_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save Ws HiddenPart";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Card_AGCR_Part_EditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save Card Part";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.NameF.SetValue('New');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Row.Get('A');
        Observer.Observe('storedAfterClose', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Worksheet_AGCR_NewRowThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save Worksheet AGCR";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.New();
        P.CodeF.SetValue('C');
        P.NameF.SetValue('Fresh');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure List_AGCR_SecondRowEditThenAction()
    var
        Row: Record "TPL Save Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Save List AGCR";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Name := 'Old';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'Other';
        Row.Insert();
        Log.Reset();
        P.OpenEdit();
        P.First();
        P.Next();
        P.NameF.SetValue('Changed');
        Observer.Observe('logEdit', Log.Take());
        P.ReadBack.Invoke();
        Observer.Observe('logAction', Log.Take());
        P.Close();
        Observer.Observe('logClose', Log.Take());
        Observer.Finish();
    end;
}
