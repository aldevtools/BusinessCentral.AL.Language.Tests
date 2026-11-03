// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-part-control
// Scope: in-scope
// Fixtures used: own table, part page, host page
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a host card whose procedures reach its part through CurrPage.Lines.Page; the part has procedures that read Rec, call CurrPage.Update, SetRecord, GetRecord and read CurrPage.Editable.
// BC versions: 29 (27 and 28 by CI)

table 71480 "LT NeverRan Line"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 71481 "LT NeverRan Part"
{
    PageType = ListPart;
    SourceTable = "LT NeverRan Line";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    procedure ReadRec(): Text
    begin
        exit('id=' + Format(Rec.Id) + ' name=' + Rec.Name);
    end;

    procedure ReadCount(): Integer
    begin
        exit(Rec.Count());
    end;

    procedure ReadFilters(): Text
    begin
        exit(Rec.GetFilters());
    end;

    procedure DoUpdate(Save: Boolean)
    begin
        CurrPage.Update(Save);
    end;

    procedure DoSetRecord(LineId: Integer)
    var
        Line: Record "LT NeverRan Line";
    begin
        Line.Get(LineId);
        CurrPage.SetRecord(Line);
    end;

    procedure DoGetRecord(): Text
    var
        Line: Record "LT NeverRan Line";
    begin
        CurrPage.GetRecord(Line);
        exit('id=' + Format(Line.Id) + ' name=' + Line.Name);
    end;

    procedure ReadEditable(): Boolean
    begin
        exit(CurrPage.Editable);
    end;
}

page 71482 "LT NeverRan Host"
{
    PageType = Card;
    SourceTable = "LT NeverRan Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdF; Rec.Id) { ApplicationArea = All; }
            part(Lines; "LT NeverRan Part")
            {
                ApplicationArea = All;
            }
        }
    }

    procedure HostReadRec(): Text
    begin
        exit('id=' + Format(Rec.Id) + ' name=' + Rec.Name);
    end;

    procedure PartReadRec(): Text
    begin
        exit(CurrPage.Lines.Page.ReadRec());
    end;

    procedure PartReadCount(): Integer
    begin
        exit(CurrPage.Lines.Page.ReadCount());
    end;

    procedure PartReadFilters(): Text
    begin
        exit(CurrPage.Lines.Page.ReadFilters());
    end;

    procedure PartUpdate(Save: Boolean)
    begin
        CurrPage.Lines.Page.DoUpdate(Save);
    end;

    procedure PartSetRecord(LineId: Integer)
    begin
        CurrPage.Lines.Page.DoSetRecord(LineId);
    end;

    procedure PartGetRecord(): Text
    begin
        exit(CurrPage.Lines.Page.DoGetRecord());
    end;

    procedure PartEditable(): Boolean
    begin
        exit(CurrPage.Lines.Page.ReadEditable());
    end;
}
