// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpageview-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 67083 - 67087, 67089, 67090, 67128
// Probe: shared fixtures of the part probes: header and line tables, one list part that logs every read and every cursor trigger, and four host cards whose part differs only in its SubPageView
// BC versions: 27.0+

table 67083 "LT F3 Head"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 67084 "LT F3 Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Head Code"; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "Head Code", "Line No.") { Clustered = true; }
    }
}

// Table backed log (not SingleInstance): both test codeunits of this folder reach it through the part pages.
codeunit 67085 "LT F3 Part Log"
{
    procedure Reset()
    var
        Log: Record "LT F3 Log";
    begin
        Log.DeleteAll();
    end;

    procedure Add(Entry: Text)
    var
        Log: Record "LT F3 Log";
        NextId: Integer;
    begin
        if Log.FindLast() then
            NextId := Log.Id;
        Log.Init();
        Log.Id := NextId + 1;
        Log.Txt := CopyStr(Entry, 1, MaxStrLen(Log.Txt));
        Log.Insert();
    end;

    procedure Dump(): Text
    var
        Log: Record "LT F3 Log";
        Result: Text;
    begin
        if Log.FindSet() then
            repeat
                if Result <> '' then
                    Result += ';';
                Result += Log.Txt;
            until Log.Next() = 0;
        exit(Result);
    end;
}

codeunit 67128 "LT F3 Part Data"
{
    procedure Seed(Heads: Integer)
    var
        PartLog: Codeunit "LT F3 Part Log";
        Head: Record "LT F3 Head";
        Line: Record "LT F3 Line";
        i: Integer;
        j: Integer;
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        PartLog.Reset();
        for i := 1 to Heads do begin
            Head.Init();
            Head."Code" := 'H' + Format(i);
            Head.Insert();
            for j := 1 to 3 do begin
                Line.Init();
                Line."Head Code" := Head."Code";
                Line."Line No." := j * 10000;
                Line.Descr := Head."Code" + ' line ' + Format(j * 10000);
                Line.Insert();
            end;
        end;
    end;
}

page 67086 "LT F3 Part"
{
    PageType = ListPart;
    SourceTable = "LT F3 Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(HeadCtl; Rec."Head Code") { ApplicationArea = All; }
                field(LineNoCtl; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT F3 Part Log";
    begin
        Log.Add('Open(' + Rec.GetFilter("Head Code") + '|' + Rec.GetFilter("Line No.") + ')');
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT F3 Part Log";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('Find(' + Which + ')=' + Format(Found));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT F3 Part Log";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('Next(' + Format(Steps) + ')=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT F3 Part Log";
    begin
        Log.Add('AGR(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;

    procedure CurrentLine(): Text
    begin
        exit(Rec."Head Code" + '/' + Format(Rec."Line No."));
    end;
}

// The part of the host reads its link from the host record; the view differs per host.
page 67087 "LT F3 Host Filter"
{
    PageType = Card;
    SourceTable = "LT F3 Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            part(Lines; "LT F3 Part")
            {
                ApplicationArea = All;
                SubPageView = where("Head Code" = filter('H1|H2'));
                SubPageLink = "Head Code" = field("Code");
            }
        }
    }

    procedure ReadPart(): Text
    begin
        exit(CurrPage.Lines.Page.CurrentLine());
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT F3 Part Log";
    begin
        Log.Add('Host.AGR(' + Rec."Code" + ')');
    end;
}

page 67089 "LT F3 Host NotEqual"
{
    PageType = Card;
    SourceTable = "LT F3 Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            part(Lines; "LT F3 Part")
            {
                ApplicationArea = All;
                SubPageView = where("Head Code" = filter(<> 'H3'));
                SubPageLink = "Head Code" = field("Code");
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT F3 Part Log";
    begin
        Log.Add('Host.AGR(' + Rec."Code" + ')');
    end;
}

page 67090 "LT F3 Host Same"
{
    PageType = Card;
    SourceTable = "LT F3 Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            part(Lines; "LT F3 Part")
            {
                ApplicationArea = All;
                SubPageView = where("Head Code" = const('ZZZ'));
                SubPageLink = "Head Code" = field("Code");
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT F3 Part Log";
    begin
        Log.Add('Host.AGR(' + Rec."Code" + ')');
    end;
}
