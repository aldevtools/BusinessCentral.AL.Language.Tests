// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 89094, pages 89095 and 89096, log codeunit 89097 (SingleInstance, used only by test
//   codeunit 89098)
// Probe: writer SG, al-runtime-rs assumption list-other-key-other-moves. Observed on a BC service tier; every literal asserted below is what it produced.
// Facts: a plain list (OnAfterGetRecord and OnAfterGetCurrRecord, no OnFindRecord or OnNextRecord) whose SourceTableView is sorting(Name)
//   next to the same list in the primary key: the trigger log of the open, First, Last, GoToKey, GoToRecord, an action that calls
//   CurrPage.Update(false), Next and Previous, over 4 rows, 1 row and 30 rows (more than a window of rows). Rows: No. 'A'..'D' with
//   Name 'delta', 'charlie', 'bravo', 'alpha' (Name order D, C, B, A); 30 rows R01..R30 whose Name order is the reverse of No.
//   Log: R:<no> = OnAfterGetRecord, C:<no> = OnAfterGetCurrRecord, U = the action starts.
// Results (BC 27.5, 28.5, 29.0 on CI): in the Name key every row the client reads is read once more than in the primary key, also at
//   First, Last, GoToKey, GoToRecord, after CurrPage.Update, with one row and with 30 rows; GoToKey and GoToRecord step through the rows
//   from the current row in the page's order.
// BC versions: 27, 28, 29

table 89094 "LT SG Key Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(ByName; Name) { }
    }
}

page 89095 "LT SG Key List"
{
    PageType = List;
    SourceTable = "LT SG Key Row";
    SourceTableView = sorting(Name);
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('U');
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."No.");
    end;

    var
        Log: Codeunit "LT SG Key Log";
}

page 89096 "LT SG Pk List"
{
    PageType = List;
    SourceTable = "LT SG Key Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('U');
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."No.");
    end;

    var
        Log: Codeunit "LT SG Key Log";
}

codeunit 89097 "LT SG Key Log"
{
    SingleInstance = true;

    var
        Entries: Text;

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
