// Objects of QcFindViewTests.al (writer QC): pages that combine OnFindRecord (and OnNextRecord) with a SourceTableView that has a
// WHERE part, in the shapes Base Application uses:
//   Sales Order Subform and the other document subforms (ListPart, SourceTableView = where("Document Type" = filter(Order)),
//     SubPageLink to the header, OnFindRecord = exit(Rec.Find(Which))),
//   Service Invoice (Document card, SourceTableView = where("Document Type" = filter(Invoice)), OnFindRecord tries Rec.Find(Which) and,
//     when that fails, clears the key filter and tries again),
//   Interaction Log Entries (List, SourceTableView = where(Postponed = const(false)), OnFindRecord = Rec.Find(Which)).
// Rows of "LT QC Find Row": Id 1..6, Kind A, B, A, B, A, B (Kind A = Id 1, 3, 5).
// The tables and pages come before the log codeunit: the SingleInstance log belongs to the one test codeunit in QcFindViewTests.al.

enum 86440 "LT QC Find Kind"
{
    Extensible = false;
    value(0; A) { }
    value(1; B) { }
}

table 86440 "LT QC Find Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT QC Find Kind") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 86441 "LT QC Find Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 86442 "LT QC Find Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc Kind"; Enum "LT QC Find Kind") { }
        field(2; "Doc No."; Code[20]) { }
        field(3; "Line No."; Integer) { }
    }

    keys
    {
        key(PK; "Doc Kind", "Doc No.", "Line No.") { Clustered = true; }
    }
}

// List, view filter only, OnFindRecord = Rec.Find(Which) (Interaction Log Entries shape).
page 86440 "LT QC Find View List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QC Find Row";
    SourceTableView = where(Kind = filter(A));
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT QC Find Log";
        Found: Boolean;
    begin
        Log.NoteFilters(Rec);
        Found := Rec.Find(Which);
        Log.Add('find(' + Which + ')=' + Format(Found) + ':' + Format(Rec.Id));
        exit(Found);
    end;
}

// List, view filter, OnFindRecord and OnNextRecord that pass through to Rec.
page 86441 "LT QC Find Next List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QC Find Row";
    SourceTableView = where(Kind = filter(A));
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT QC Find Log";
        Found: Boolean;
    begin
        Log.NoteFilters(Rec);
        Found := Rec.Find(Which);
        Log.Add('find(' + Which + ')=' + Format(Found) + ':' + Format(Rec.Id));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT QC Find Log";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('next(' + Format(Steps) + ')=' + Format(Moved) + ':' + Format(Rec.Id));
        exit(Moved);
    end;
}

// List, view with sorting, descending order and a filter, OnFindRecord = Rec.Find(Which).
page 86442 "LT QC Find Desc List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QC Find Row";
    SourceTableView = sorting(Id) order(descending) where(Kind = filter(A));
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT QC Find Log";
        Found: Boolean;
    begin
        Log.NoteFilters(Rec);
        Found := Rec.Find(Which);
        Log.Add('find(' + Which + ')=' + Format(Found) + ':' + Format(Rec.Id));
        exit(Found);
    end;
}

// List, view filter, triggers that serve rows from a second record variable WITHOUT the view's filter: does the client still apply
// the view to the rows the triggers return?
page 86443 "LT QC Find Free List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QC Find Row";
    SourceTableView = where(Kind = filter(A));
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT QC Find Log";
        All: Record "LT QC Find Row";
        Found: Boolean;
    begin
        All.SetPosition(Rec.GetPosition());
        Found := All.Find(Which);
        if Found then
            Rec := All;
        Log.Add('find(' + Which + ')=' + Format(Found) + ':' + Format(Rec.Id));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT QC Find Log";
        All: Record "LT QC Find Row";
        Moved: Integer;
    begin
        All.SetPosition(Rec.GetPosition());
        All.Find('=');
        Moved := All.Next(Steps);
        if Moved <> 0 then
            Rec := All;
        Log.Add('next(' + Format(Steps) + ')=' + Format(Moved) + ':' + Format(Rec.Id));
        exit(Moved);
    end;
}

// Card, view filter, OnFindRecord = Rec.Find(Which).
page 86444 "LT QC Find View Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QC Find Row";
    SourceTableView = where(Kind = const(A));
    Editable = false;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT QC Find Log";
        Found: Boolean;
    begin
        Log.NoteFilters(Rec);
        Found := Rec.Find(Which);
        Log.Add('find(' + Which + ')=' + Format(Found) + ':' + Format(Rec.Id));
        exit(Found);
    end;
}

// Document card, view filter, OnFindRecord as on Service Invoice: Rec.Find(Which), else clear the key filter and find again.
page 86445 "LT QC Find Fallback Card"
{
    PageType = Document;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QC Find Row";
    SourceTableView = where(Kind = filter(A));
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT QC Find Log";
    begin
        Log.NoteFilters(Rec);
        if Rec.Find(Which) then begin
            Log.Add('find(' + Which + ')=Yes:' + Format(Rec.Id));
            exit(true);
        end;
        Rec.SetRange(Id);
        if Rec.Find(Which) then begin
            Log.Add('find(' + Which + ')=No,again=Yes:' + Format(Rec.Id));
            exit(true);
        end;
        Log.Add('find(' + Which + ')=No,again=No');
        exit(false);
    end;
}

// List with the same view and no triggers (control arm).
page 86446 "LT QC Find Plain List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QC Find Row";
    SourceTableView = where(Kind = filter(A));
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }
}

// ListPart as Sales Order Subform: view filter on the document kind, SubPageLink from the header, OnFindRecord = Rec.Find(Which).
page 86447 "LT QC Find Lines Part"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QC Find Line";
    SourceTableView = where("Doc Kind" = filter(A));
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT QC Find Log";
        Found: Boolean;
    begin
        Log.NoteLineFilters(Rec);
        Found := Rec.Find(Which);
        Log.Add('find(' + Which + ')=' + Format(Found) + ':' + Format(Rec."Line No."));
        exit(Found);
    end;
}

page 86448 "LT QC Find Doc"
{
    PageType = Document;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT QC Find Head";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(LinesPart; "LT QC Find Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

codeunit 86440 "LT QC Find Log"
{
    SingleInstance = true;

    var
        Buf: Text;
        Filters: Text;

    procedure Add(Entry: Text)
    begin
        Buf += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Buf;
        Buf := '';
    end;

    // The filters of the page's Rec in groups 0 and 2 at the FIRST OnFindRecord call since the last TakeFilters.
    procedure NoteFilters(var Row: Record "LT QC Find Row")
    var
        Current: Integer;
        G0: Text;
        G2: Text;
    begin
        if Filters <> '' then
            exit;
        Current := Row.FilterGroup();
        Row.FilterGroup(0);
        G0 := Row.GetFilters();
        Row.FilterGroup(2);
        G2 := Row.GetFilters();
        Row.FilterGroup(Current);
        Filters := 'group=' + Format(Current) + ' g0=[' + G0 + '] g2=[' + G2 + '] key=' + Row.CurrentKey() + ' asc=' + Format(Row.Ascending());
    end;

    procedure NoteLineFilters(var Line: Record "LT QC Find Line")
    var
        Current: Integer;
        G0: Text;
        G2: Text;
        G4: Text;
    begin
        if Filters <> '' then
            exit;
        Current := Line.FilterGroup();
        Line.FilterGroup(0);
        G0 := Line.GetFilters();
        Line.FilterGroup(2);
        G2 := Line.GetFilters();
        Line.FilterGroup(4);
        G4 := Line.GetFilters();
        Line.FilterGroup(Current);
        Filters := 'group=' + Format(Current) + ' g0=[' + G0 + '] g2=[' + G2 + '] g4=[' + G4 + ']';
    end;

    procedure TakeFilters() Result: Text
    begin
        Result := Filters;
        Filters := '';
    end;
}
