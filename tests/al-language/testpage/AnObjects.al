// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures for the probes of corpus issue 640 (TestPage behavior, part 1): tables 79400-79403, log codeunit 79404 (used by test codeunit 79450 only),
// pages 79410-79419. The tests are in AnTestPageTests.al (79450) and AnAreaTests.al (79451).

table 79400 "LT AN Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Rel; Code[20]) { TableRelation = "LT AN Related"; }
        field(4; NoPg; Code[20]) { TableRelation = "LT AN Pageless"; }
        field(5; Cap; Text[30]) { Caption = 'Cap Field Caption'; CaptionClass = 'X,Y'; }
        field(6; Basic; Text[30]) { }
        field(7; Suite; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 79401 "LT AN Related"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT AN Related List";

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 79402 "LT AN Pageless"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 79403 "LT AN Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Doc; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Name; Text[50]) { }
    }

    keys
    {
        key(PK; Doc, "Line No.") { Clustered = true; }
    }
}

codeunit 79404 "LT AN Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 79410 "LT AN Related List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AN Related";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 79411 "LT AN Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AN Row";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Rel; Rec.Rel) { ApplicationArea = All; }
                field(NoPg; Rec.NoPg) { ApplicationArea = All; }
                field(Cap; Rec.Cap) { ApplicationArea = All; }
                field(DecVar; DecVar)
                {
                    ApplicationArea = All;
                    MinValue = 2;
                    MaxValue = 5;
                }
                field(DateVar; DateVar) { ApplicationArea = All; }
                field(DurVar; DurVar) { ApplicationArea = All; }
            }
        }
    }

    var
        DecVar: Decimal;
        DateVar: Date;
        DurVar: Duration;
}

page 79412 "LT AN Part"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AN Line";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT AN Log";
    begin
        Log.Add('P.Open');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AN Log";
    begin
        Log.Add('P.R' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT AN Log";
    begin
        Log.Add('P.C' + Format(Rec."Line No."));
    end;
}

page 79413 "LT AN Host Const One"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AN Row";

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            part(Lines; "LT AN Part")
            {
                ApplicationArea = All;
                SubPageLink = Doc = const('ONE');
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AN Log";
    begin
        Log.Add('H.R' + Rec."Code");
    end;
}

page 79414 "LT AN Host Const Five"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AN Row";

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            part(Lines; "LT AN Part")
            {
                ApplicationArea = All;
                SubPageLink = Doc = const('FIVE');
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AN Log";
    begin
        Log.Add('H.R' + Rec."Code");
    end;
}

page 79415 "LT AN Host Field"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AN Row";

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            part(Lines; "LT AN Part")
            {
                ApplicationArea = All;
                SubPageLink = Doc = field("Code");
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AN Log";
    begin
        Log.Add('H.R' + Rec."Code");
    end;
}

page 79416 "LT AN Find List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AN Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteCurrent)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT AN Log";
                begin
                    Log.Add('Del' + Rec."Code");
                    Rec.Delete();
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT AN Log";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        if Found then
            Log.Add('F' + Which + '>' + Rec."Code")
        else
            Log.Add('F' + Which + '>none');
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT AN Log";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('N' + Format(Steps) + '>' + Format(Moved) + Rec."Code");
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AN Log";
    begin
        Log.Add('R' + Rec."Code");
    end;
}

page 79417 "LT AN Area Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AN Row";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(BasicCtl; Rec.Basic) { ApplicationArea = Basic; }
                field(SuiteCtl; Rec.Suite) { ApplicationArea = Suite; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActSuite)
            {
                ApplicationArea = Suite;

                trigger OnAction()
                begin
                end;
            }
        }
    }
}
