// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpageview-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 94202 - 94214
// Probe (writer Y80, from the runtime lane rt-pages-1102c): a SubPageView condition on the field the SubPageLink also names, with a condition other
//   than const: filter('H1|H2'), filter('<>H1'), a range filter, field("Code"). pages/lt-part-reads/PartReadsOpen.al pins const('ZZZ') on the
//   linked field (part Same) and filter('>10000') on a field outside the link (part Filtered). Here every part has its own host (a Document page
//   with one ListPart) and one more host holds all four, so both the single-part and the several-part reads show. The parts log OnOpenPage (with
//   the filters), OnAfterGetRecord and OnAfterGetCurrRecord; the tests open the host with OpenView, OpenEdit and OpenNew, then move it with
//   Next, Last, Previous, First and GoToKey, and read the rows each part shows.
// BC versions: 27, 28, 29

table 94202 "LT Y80 SV Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 94203 "LT Y80 SV Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head Code"; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[50]) { }
    }
    keys { key(PK; "Head Code", "Line No.") { Clustered = true; } }
}

// SingleInstance log of this topic; used by the test codeunit 94214 only.
codeunit 94204 "LT Y80 SV Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Reset()
    begin
        Entries := '';
    end;

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
}

page 94205 "LT Y80 SV Part F1"
{
    PageType = ListPart;
    SourceTable = "LT Y80 SV Line";
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
        Log: Codeunit "LT Y80 SV Log";
    begin
        Log.Add('F1.open(' + Rec.GetFilter("Head Code") + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT Y80 SV Log";
    begin
        Log.Add('F1.agr(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT Y80 SV Log";
    begin
        Log.Add('F1.agcr(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;
}

page 94206 "LT Y80 SV Part F2"
{
    PageType = ListPart;
    SourceTable = "LT Y80 SV Line";
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
        Log: Codeunit "LT Y80 SV Log";
    begin
        Log.Add('F2.open(' + Rec.GetFilter("Head Code") + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT Y80 SV Log";
    begin
        Log.Add('F2.agr(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT Y80 SV Log";
    begin
        Log.Add('F2.agcr(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;
}

page 94207 "LT Y80 SV Part F3"
{
    PageType = ListPart;
    SourceTable = "LT Y80 SV Line";
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
        Log: Codeunit "LT Y80 SV Log";
    begin
        Log.Add('F3.open(' + Rec.GetFilter("Head Code") + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT Y80 SV Log";
    begin
        Log.Add('F3.agr(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT Y80 SV Log";
    begin
        Log.Add('F3.agcr(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;
}

page 94208 "LT Y80 SV Part F4"
{
    PageType = ListPart;
    SourceTable = "LT Y80 SV Line";
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
        Log: Codeunit "LT Y80 SV Log";
    begin
        Log.Add('F4.open(' + Rec.GetFilter("Head Code") + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT Y80 SV Log";
    begin
        Log.Add('F4.agr(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT Y80 SV Log";
    begin
        Log.Add('F4.agcr(' + Rec."Head Code" + '/' + Format(Rec."Line No.") + ')');
    end;
}

page 94209 "LT Y80 SV Host F1"
{
    PageType = Document;
    SourceTable = "LT Y80 SV Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            part(PartF1; "LT Y80 SV Part F1")
            {
                ApplicationArea = All;
                SubPageView = where("Head Code" = filter('H1|H2'));
                SubPageLink = "Head Code" = field("Code");
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT Y80 SV Log";
    begin
        Log.Add('host.agr(' + Rec."Code" + ')');
    end;
}

page 94210 "LT Y80 SV Host F2"
{
    PageType = Document;
    SourceTable = "LT Y80 SV Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            part(PartF2; "LT Y80 SV Part F2")
            {
                ApplicationArea = All;
                SubPageView = where("Head Code" = filter('<>H1'));
                SubPageLink = "Head Code" = field("Code");
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT Y80 SV Log";
    begin
        Log.Add('host.agr(' + Rec."Code" + ')');
    end;
}

page 94211 "LT Y80 SV Host F3"
{
    PageType = Document;
    SourceTable = "LT Y80 SV Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            part(PartF3; "LT Y80 SV Part F3")
            {
                ApplicationArea = All;
                SubPageView = where("Head Code" = field("Code"));
                SubPageLink = "Head Code" = field("Code");
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT Y80 SV Log";
    begin
        Log.Add('host.agr(' + Rec."Code" + ')');
    end;
}

page 94212 "LT Y80 SV Host F4"
{
    PageType = Document;
    SourceTable = "LT Y80 SV Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            part(PartF4; "LT Y80 SV Part F4")
            {
                ApplicationArea = All;
                SubPageView = where("Head Code" = filter('H2..H3'));
                SubPageLink = "Head Code" = field("Code");
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT Y80 SV Log";
    begin
        Log.Add('host.agr(' + Rec."Code" + ')');
    end;
}

page 94213 "LT Y80 SV Host All"
{
    PageType = Document;
    SourceTable = "LT Y80 SV Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            part(PartF1; "LT Y80 SV Part F1")
            {
                ApplicationArea = All;
                SubPageView = where("Head Code" = filter('H1|H2'));
                SubPageLink = "Head Code" = field("Code");
            }
            part(PartF2; "LT Y80 SV Part F2")
            {
                ApplicationArea = All;
                SubPageView = where("Head Code" = filter('<>H1'));
                SubPageLink = "Head Code" = field("Code");
            }
            part(PartF3; "LT Y80 SV Part F3")
            {
                ApplicationArea = All;
                SubPageView = where("Head Code" = field("Code"));
                SubPageLink = "Head Code" = field("Code");
            }
            part(PartF4; "LT Y80 SV Part F4")
            {
                ApplicationArea = All;
                SubPageView = where("Head Code" = filter('H2..H3'));
                SubPageLink = "Head Code" = field("Code");
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT Y80 SV Log";
    begin
        Log.Add('host.agr(' + Rec."Code" + ')');
    end;
}
