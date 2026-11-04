// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sublink-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: shared fixtures of the six-part host probes: tables, SingleInstance log, six distinct part pages, the host
// BC versions: 29 (27 and 28 by CI)

table 71255 "LT PartReads Head"
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

table 71256 "LT PartReads Line"
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

// SingleInstance log; entries are 'PartName.Kind(key)'. Used by the test codeunits of this topic only.
codeunit 71257 "LT PartReads Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];
        ShowHidden: Boolean;

    procedure Reset()
    begin
        Clear(Entries);
    end;

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure SetShowHidden(NewValue: Boolean)
    begin
        ShowHidden := NewValue;
    end;

    procedure GetShowHidden(): Boolean
    begin
        exit(ShowHidden);
    end;

    procedure Count(): Integer
    begin
        exit(Entries.Count());
    end;

    procedure CountOf(PartName: Text): Integer
    var
        Entry: Text;
        N: Integer;
    begin
        foreach Entry in Entries do
            if Entry.StartsWith(PartName + '.') then
                N += 1;
        exit(N);
    end;

    procedure CountOfKind(PartName: Text; Kind: Text): Integer
    var
        Entry: Text;
        N: Integer;
    begin
        foreach Entry in Entries do
            if Entry.StartsWith(PartName + '.' + Kind + '(') then
                N += 1;
        exit(N);
    end;

    procedure DumpOf(PartName: Text): Text
    var
        Entry: Text;
        Result: Text;
    begin
        foreach Entry in Entries do
            if Entry.StartsWith(PartName + '.') then begin
                if Result <> '' then
                    Result += ';';
                Result += Entry.Substring(StrLen(PartName) + 2);
            end;
        exit(Result);
    end;

    procedure DumpHost(): Text
    begin
        exit(DumpOf('Host'));
    end;
}

page 71258 "LT PartReads Plain"
{
    PageType = ListPart;
    SourceTable = "LT PartReads Line";
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
        Log: Codeunit "LT PartReads Log";
    begin
        Log.Add('Plain.OnOpenPage(' + Rec.GetFilter("Head Code") + '|' + Rec.GetFilter("Line No.") + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PartReads Log";
    begin
        Log.Add('Plain.AGR(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;
}

page 71259 "LT PartReads Linked"
{
    PageType = ListPart;
    SourceTable = "LT PartReads Line";
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
        Log: Codeunit "LT PartReads Log";
    begin
        Log.Add('Linked.OnOpenPage(' + Rec.GetFilter("Head Code") + '|' + Rec.GetFilter("Line No.") + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PartReads Log";
    begin
        Log.Add('Linked.AGR(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;
}

page 71260 "LT PartReads View"
{
    PageType = ListPart;
    SourceTable = "LT PartReads Line";
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
        Log: Codeunit "LT PartReads Log";
    begin
        Log.Add('View.OnOpenPage(' + Rec.GetFilter("Head Code") + '|' + Rec.GetFilter("Line No.") + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PartReads Log";
    begin
        Log.Add('View.AGR(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;
}

page 71261 "LT PartReads Same"
{
    PageType = ListPart;
    SourceTable = "LT PartReads Line";
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
        Log: Codeunit "LT PartReads Log";
    begin
        Log.Add('Same.OnOpenPage(' + Rec.GetFilter("Head Code") + '|' + Rec.GetFilter("Line No.") + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PartReads Log";
    begin
        Log.Add('Same.AGR(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;
}

page 71262 "LT PartReads Hidden"
{
    PageType = ListPart;
    SourceTable = "LT PartReads Line";
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
        Log: Codeunit "LT PartReads Log";
    begin
        Log.Add('Hidden.OnOpenPage(' + Rec.GetFilter("Head Code") + '|' + Rec.GetFilter("Line No.") + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PartReads Log";
    begin
        Log.Add('Hidden.AGR(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;
}

page 71263 "LT PartReads Filtered"
{
    PageType = ListPart;
    SourceTable = "LT PartReads Line";
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
        Log: Codeunit "LT PartReads Log";
    begin
        Log.Add('Filtered.OnOpenPage(' + Rec.GetFilter("Head Code") + '|' + Rec.GetFilter("Line No.") + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PartReads Log";
    begin
        Log.Add('Filtered.AGR(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;
}

page 71264 "LT PartReads Host"
{
    PageType = Document;
    SourceTable = "LT PartReads Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            part(PlainP; "LT PartReads Plain")
            {
                ApplicationArea = All;
            }
            part(LinkedP; "LT PartReads Linked")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field("Code");
            }
            part(ViewP; "LT PartReads View")
            {
                ApplicationArea = All;
                SubPageView = where("Line No." = const(20000));
            }
            part(SameP; "LT PartReads Same")
            {
                ApplicationArea = All;
                SubPageView = where("Head Code" = const('ZZZ'));
                SubPageLink = "Head Code" = field("Code");
            }
            part(HiddenP; "LT PartReads Hidden")
            {
                ApplicationArea = All;
                Visible = ShowHidden;
                SubPageLink = "Head Code" = field("Code");
            }
            part(FilteredP; "LT PartReads Filtered")
            {
                ApplicationArea = All;
                SubPageView = where("Line No." = filter('>10000'));
                SubPageLink = "Head Code" = field("Code");
            }
        }
    }

    var
        ShowHidden: Boolean;

    trigger OnInit()
    var
        Log: Codeunit "LT PartReads Log";
    begin
        ShowHidden := Log.GetShowHidden();
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PartReads Log";
    begin
        Log.Add('Host.AGR(' + Rec."Code" + ')');
    end;
}

