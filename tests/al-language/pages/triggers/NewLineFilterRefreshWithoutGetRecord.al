// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own enum 91313, tables 91314 and 91315, log codeunit 91316 (SingleInstance, used by
//   test codeunit 91328 only), pages 91317 to 91327, test codeunit 91328
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a List page with DelayedInsert over an empty table, opened with OpenEdit. A filter control's OnValidate changes a filter on Rec,
//   then calls CurrPage.Update(false). What the new-row line shows afterwards (its key and non-key fields), which page triggers run
//   (OnNewRecord, OnAfterGetRecord, OnAfterGetCurrRecord, with how often and on which values) and whether a row is stored.
//   Shapes: an Enum key field with one single-value filter (Microsoft's Sales Prices page shape); two Option key filters, the key's first
//   field unchanged and the other changed (Microsoft's Sales Line Discounts page shape); with and without CurrPage.SaveRecord() first;
//   with and without OnAfterGetRecord / OnAfterGetCurrRecord / OnNewRecord declared; with and without a filter set in OnOpenPage;
//   filter groups 0, 2 and 4; TestPage.Filter.SetFilter instead of the OnValidate; a Code key field; a field outside the key with and
//   without PopulateAllFields; a range filter (B..C) and a two-value filter (B|C); two key filters that both change.
//   Also: a control whose source is a procedure that writes a page variable from Rec.GetFilter, in a Visible = false group (and in a
//   visible one), on a page without parts: the variable after TestPage.Filter.SetFilter and after the OnValidate refresh.
// al-runtime-rs: issues 9121 and 9124, assumption new-line-empty-refresh-without-get-record.
// BC versions: 27, 28, 29 (CI)

enum 91313 "NLF Kind"
{
    Extensible = false;
    value(0; A) { }
    value(1; B) { }
    value(2; C) { }
    value(3; D) { }
}

table 91314 "NLF Enum Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Item No."; Code[20]) { }
        field(2; Kind; Enum "NLF Kind") { }
        field(3; "Entry No."; Integer) { }
        field(4; Descr; Text[30]) { }
    }
    keys
    {
        key(PK; "Item No.", Kind, "Entry No.") { Clustered = true; }
    }
}

// As in Microsoft's Sales Line Discount table, the key's first field comes after the other key fields in field order.
table 91315 "NLF Two Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(13; "Sales Type"; Option) { OptionMembers = A,B,C,D; }
        field(21; Type; Option) { OptionMembers = Item,Group,None; }
        field(22; Descr; Text[30]) { }
    }
    keys
    {
        key(PK; Type, "Code", "Sales Type") { Clustered = true; }
    }
}

codeunit 91316 "NLF Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        WithOpenFilter: Boolean;

    procedure Clear()
    begin
        Entries := '';
    end;

    procedure Add(What: Text)
    begin
        Entries += What + ';';
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;

    procedure SetOpenFilter(Value: Boolean)
    begin
        WithOpenFilter := Value;
    end;

    procedure OpenFilter(): Boolean
    begin
        exit(WithOpenFilter);
    end;
}

page 91317 "NLF Enum None"
{
    PageType = List;
    SourceTable = "NLF Enum Row";
    DelayedInsert = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(KindFilter; KindFilter)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        SetRecFilters();
                    end;
                }
                field(Act; Act)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Apply(Act);
                    end;
                }
            }
            repeater(Lines)
            {
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('Open');
        if Log.OpenFilter() then
            SetRecFilters();
    end;

    local procedure SetRecFilters()
    begin
        Rec.SetRange(Kind, KindFilter);
        CurrPage.Update(false);
    end;

    local procedure Apply(Code: Integer)
    begin
        case Code of
            2:
                Rec.SetRange(Kind, Rec.Kind::C);
            3:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(2);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            4:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(4);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            5:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::B, Rec.Kind::C);
                end;
            6:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetFilter(Kind, '%1|%2', Rec.Kind::B, Rec.Kind::C);
                end;
            7:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Descr, 'X');
                end;
            8:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange("Item No.", 'X');
                end;
            9:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.SetRange("Item No.", 'X');
                end;
        end;
        CurrPage.Update(false);
    end;

    var
        Log: Codeunit "NLF Log";
        KindFilter: Enum "NLF Kind";
        Act: Integer;
}

page 91318 "NLF Enum Curr"
{
    PageType = List;
    SourceTable = "NLF Enum Row";
    DelayedInsert = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(KindFilter; KindFilter)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        SetRecFilters();
                    end;
                }
                field(Act; Act)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Apply(Act);
                    end;
                }
            }
            repeater(Lines)
            {
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('Open');
        if Log.OpenFilter() then
            SetRecFilters();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add(StrSubstNo('Curr %1/%2/%3', Rec.Kind, Rec."Item No.", Rec.Descr));
    end;

    local procedure SetRecFilters()
    begin
        Rec.SetRange(Kind, KindFilter);
        CurrPage.Update(false);
    end;

    local procedure Apply(Code: Integer)
    begin
        case Code of
            2:
                Rec.SetRange(Kind, Rec.Kind::C);
            3:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(2);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            4:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(4);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            5:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::B, Rec.Kind::C);
                end;
            6:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetFilter(Kind, '%1|%2', Rec.Kind::B, Rec.Kind::C);
                end;
            7:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Descr, 'X');
                end;
            8:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange("Item No.", 'X');
                end;
            9:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.SetRange("Item No.", 'X');
                end;
        end;
        CurrPage.Update(false);
    end;

    var
        Log: Codeunit "NLF Log";
        KindFilter: Enum "NLF Kind";
        Act: Integer;
}

page 91319 "NLF Enum Get"
{
    PageType = List;
    SourceTable = "NLF Enum Row";
    DelayedInsert = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(KindFilter; KindFilter)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        SetRecFilters();
                    end;
                }
                field(Act; Act)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Apply(Act);
                    end;
                }
            }
            repeater(Lines)
            {
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('Open');
        if Log.OpenFilter() then
            SetRecFilters();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add(StrSubstNo('Get %1/%2/%3', Rec.Kind, Rec."Item No.", Rec.Descr));
    end;

    local procedure SetRecFilters()
    begin
        Rec.SetRange(Kind, KindFilter);
        CurrPage.Update(false);
    end;

    local procedure Apply(Code: Integer)
    begin
        case Code of
            2:
                Rec.SetRange(Kind, Rec.Kind::C);
            3:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(2);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            4:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(4);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            5:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::B, Rec.Kind::C);
                end;
            6:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetFilter(Kind, '%1|%2', Rec.Kind::B, Rec.Kind::C);
                end;
            7:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Descr, 'X');
                end;
            8:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange("Item No.", 'X');
                end;
            9:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.SetRange("Item No.", 'X');
                end;
        end;
        CurrPage.Update(false);
    end;

    var
        Log: Codeunit "NLF Log";
        KindFilter: Enum "NLF Kind";
        Act: Integer;
}

page 91320 "NLF Enum New"
{
    PageType = List;
    SourceTable = "NLF Enum Row";
    DelayedInsert = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(KindFilter; KindFilter)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        SetRecFilters();
                    end;
                }
                field(Act; Act)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Apply(Act);
                    end;
                }
            }
            repeater(Lines)
            {
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('Open');
        if Log.OpenFilter() then
            SetRecFilters();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add(StrSubstNo('New %1/%2/%3/%4', Rec.Kind, Rec."Item No.", Rec.Descr, BelowxRec));
    end;

    local procedure SetRecFilters()
    begin
        Rec.SetRange(Kind, KindFilter);
        CurrPage.Update(false);
    end;

    local procedure Apply(Code: Integer)
    begin
        case Code of
            2:
                Rec.SetRange(Kind, Rec.Kind::C);
            3:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(2);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            4:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(4);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            5:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::B, Rec.Kind::C);
                end;
            6:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetFilter(Kind, '%1|%2', Rec.Kind::B, Rec.Kind::C);
                end;
            7:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Descr, 'X');
                end;
            8:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange("Item No.", 'X');
                end;
            9:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.SetRange("Item No.", 'X');
                end;
        end;
        CurrPage.Update(false);
    end;

    var
        Log: Codeunit "NLF Log";
        KindFilter: Enum "NLF Kind";
        Act: Integer;
}

page 91321 "NLF Enum All"
{
    PageType = List;
    SourceTable = "NLF Enum Row";
    DelayedInsert = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(KindFilter; KindFilter)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        SetRecFilters();
                    end;
                }
                field(Act; Act)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Apply(Act);
                    end;
                }
            }
            repeater(Lines)
            {
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('Open');
        if Log.OpenFilter() then
            SetRecFilters();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add(StrSubstNo('New %1/%2/%3/%4', Rec.Kind, Rec."Item No.", Rec.Descr, BelowxRec));
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add(StrSubstNo('Get %1/%2/%3', Rec.Kind, Rec."Item No.", Rec.Descr));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add(StrSubstNo('Curr %1/%2/%3', Rec.Kind, Rec."Item No.", Rec.Descr));
    end;

    local procedure SetRecFilters()
    begin
        Rec.SetRange(Kind, KindFilter);
        CurrPage.Update(false);
    end;

    local procedure Apply(Code: Integer)
    begin
        case Code of
            2:
                Rec.SetRange(Kind, Rec.Kind::C);
            3:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(2);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            4:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(4);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            5:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::B, Rec.Kind::C);
                end;
            6:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetFilter(Kind, '%1|%2', Rec.Kind::B, Rec.Kind::C);
                end;
            7:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Descr, 'X');
                end;
            8:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange("Item No.", 'X');
                end;
            9:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.SetRange("Item No.", 'X');
                end;
        end;
        CurrPage.Update(false);
    end;

    var
        Log: Codeunit "NLF Log";
        KindFilter: Enum "NLF Kind";
        Act: Integer;
}

page 91322 "NLF Enum Pop"
{
    PageType = List;
    SourceTable = "NLF Enum Row";
    DelayedInsert = true;
    ApplicationArea = All;
    PopulateAllFields = true;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(KindFilter; KindFilter)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        SetRecFilters();
                    end;
                }
                field(Act; Act)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Apply(Act);
                    end;
                }
            }
            repeater(Lines)
            {
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('Open');
        if Log.OpenFilter() then
            SetRecFilters();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add(StrSubstNo('Curr %1/%2/%3', Rec.Kind, Rec."Item No.", Rec.Descr));
    end;

    local procedure SetRecFilters()
    begin
        Rec.SetRange(Kind, KindFilter);
        CurrPage.Update(false);
    end;

    local procedure Apply(Code: Integer)
    begin
        case Code of
            2:
                Rec.SetRange(Kind, Rec.Kind::C);
            3:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(2);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            4:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(4);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            5:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::B, Rec.Kind::C);
                end;
            6:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetFilter(Kind, '%1|%2', Rec.Kind::B, Rec.Kind::C);
                end;
            7:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Descr, 'X');
                end;
            8:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange("Item No.", 'X');
                end;
            9:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.SetRange("Item No.", 'X');
                end;
        end;
        CurrPage.Update(false);
    end;

    var
        Log: Codeunit "NLF Log";
        KindFilter: Enum "NLF Kind";
        Act: Integer;
}

page 91323 "NLF Enum FnHidden"
{
    PageType = List;
    SourceTable = "NLF Enum Row";
    DelayedInsert = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(KindFilter; KindFilter)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        SetRecFilters();
                    end;
                }
                field(Act; Act)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Apply(Act);
                    end;
                }
                field(Seen; Seen) { ApplicationArea = All; Editable = false; }
            }
            group(Mobile)
            {
                Visible = false;
                field(FilterDescription; GetFilterDescription()) { ApplicationArea = All; Editable = false; }
            }
            repeater(Lines)
            {
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('Open');
        if Log.OpenFilter() then
            SetRecFilters();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add(StrSubstNo('Curr %1/%2/%3', Rec.Kind, Rec."Item No.", Rec.Descr));
    end;

    local procedure SetRecFilters()
    begin
        Rec.SetRange(Kind, KindFilter);
        CurrPage.Update(false);
    end;

    local procedure Apply(Code: Integer)
    begin
        case Code of
            2:
                Rec.SetRange(Kind, Rec.Kind::C);
            3:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(2);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            4:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(4);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            5:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::B, Rec.Kind::C);
                end;
            6:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetFilter(Kind, '%1|%2', Rec.Kind::B, Rec.Kind::C);
                end;
            7:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Descr, 'X');
                end;
            8:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange("Item No.", 'X');
                end;
            9:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.SetRange("Item No.", 'X');
                end;
        end;
        CurrPage.Update(false);
    end;

    local procedure GetFilterDescription(): Text
    begin
        Seen := Rec.GetFilter(Kind);
        Log.Add('Fn ' + Seen);
        exit(Seen);
    end;

    var
        Log: Codeunit "NLF Log";
        KindFilter: Enum "NLF Kind";
        Act: Integer;
        Seen: Text;
}

page 91324 "NLF Enum FnPlain"
{
    PageType = List;
    SourceTable = "NLF Enum Row";
    DelayedInsert = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(KindFilter; KindFilter)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        SetRecFilters();
                    end;
                }
                field(Act; Act)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Apply(Act);
                    end;
                }
                field(Seen; Seen) { ApplicationArea = All; Editable = false; }
            }
            group(Mobile)
            {
                Visible = false;
                field(FilterDescription; GetFilterDescription()) { ApplicationArea = All; Editable = false; }
            }
            repeater(Lines)
            {
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('Open');
        if Log.OpenFilter() then
            SetRecFilters();
    end;

    local procedure SetRecFilters()
    begin
        Rec.SetRange(Kind, KindFilter);
        CurrPage.Update(false);
    end;

    local procedure Apply(Code: Integer)
    begin
        case Code of
            2:
                Rec.SetRange(Kind, Rec.Kind::C);
            3:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(2);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            4:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(4);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            5:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::B, Rec.Kind::C);
                end;
            6:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetFilter(Kind, '%1|%2', Rec.Kind::B, Rec.Kind::C);
                end;
            7:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Descr, 'X');
                end;
            8:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange("Item No.", 'X');
                end;
            9:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.SetRange("Item No.", 'X');
                end;
        end;
        CurrPage.Update(false);
    end;

    local procedure GetFilterDescription(): Text
    begin
        Seen := Rec.GetFilter(Kind);
        Log.Add('Fn ' + Seen);
        exit(Seen);
    end;

    var
        Log: Codeunit "NLF Log";
        KindFilter: Enum "NLF Kind";
        Act: Integer;
        Seen: Text;
}

page 91325 "NLF Enum FnVisible"
{
    PageType = List;
    SourceTable = "NLF Enum Row";
    DelayedInsert = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(KindFilter; KindFilter)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        SetRecFilters();
                    end;
                }
                field(Act; Act)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Apply(Act);
                    end;
                }
                field(Seen; Seen) { ApplicationArea = All; Editable = false; }
            }
            group(Mobile)
            {
                Visible = true;
                field(FilterDescription; GetFilterDescription()) { ApplicationArea = All; Editable = false; }
            }
            repeater(Lines)
            {
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('Open');
        if Log.OpenFilter() then
            SetRecFilters();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add(StrSubstNo('Curr %1/%2/%3', Rec.Kind, Rec."Item No.", Rec.Descr));
    end;

    local procedure SetRecFilters()
    begin
        Rec.SetRange(Kind, KindFilter);
        CurrPage.Update(false);
    end;

    local procedure Apply(Code: Integer)
    begin
        case Code of
            2:
                Rec.SetRange(Kind, Rec.Kind::C);
            3:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(2);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            4:
                begin
                    CurrPage.SaveRecord();
                    Rec.FilterGroup(4);
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.FilterGroup(0);
                end;
            5:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::B, Rec.Kind::C);
                end;
            6:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetFilter(Kind, '%1|%2', Rec.Kind::B, Rec.Kind::C);
                end;
            7:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Descr, 'X');
                end;
            8:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange("Item No.", 'X');
                end;
            9:
                begin
                    CurrPage.SaveRecord();
                    Rec.SetRange(Kind, Rec.Kind::C);
                    Rec.SetRange("Item No.", 'X');
                end;
        end;
        CurrPage.Update(false);
    end;

    local procedure GetFilterDescription(): Text
    begin
        Seen := Rec.GetFilter(Kind);
        Log.Add('Fn ' + Seen);
        exit(Seen);
    end;

    var
        Log: Codeunit "NLF Log";
        KindFilter: Enum "NLF Kind";
        Act: Integer;
        Seen: Text;
}

page 91326 "NLF Two Curr"
{
    PageType = List;
    SourceTable = "NLF Two Row";
    DelayedInsert = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(SalesTypeFilter; SalesTypeFilter)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        SetRecFilters();
                    end;
                }
                field(Act; Act)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Apply(Act);
                    end;
                }
            }
            repeater(Lines)
            {
                field(Type; Rec.Type) { ApplicationArea = All; }
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field("Sales Type"; Rec."Sales Type") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('Open');
        if Log.OpenFilter() then
            SetRecFilters();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add(StrSubstNo('Curr %1/%2/%3', Rec.Type, Rec."Code", Rec."Sales Type"));
    end;

    local procedure SetRecFilters()
    begin
        Rec.SetRange("Sales Type", SalesTypeFilter);
        Rec.SetRange(Type, TypeFilter);
        CurrPage.Update(false);
    end;

    local procedure Apply(Code: Integer)
    begin
        case Code of
            2:
                begin
                    SalesTypeFilter := SalesTypeFilter::C;
                    SetRecFilters();
                end;
            3:
                begin
                    CurrPage.SaveRecord();
                    TypeFilter := TypeFilter::Group;
                    SalesTypeFilter := SalesTypeFilter::C;
                    SetRecFilters();
                end;
            4:
                begin
                    CurrPage.SaveRecord();
                    TypeFilter := TypeFilter::Group;
                    SetRecFilters();
                end;
        end;
    end;

    var
        Log: Codeunit "NLF Log";
        SalesTypeFilter: Option A,B,C,D;
        TypeFilter: Option Item,"Group","None";
        Act: Integer;
}

page 91327 "NLF Two None"
{
    PageType = List;
    SourceTable = "NLF Two Row";
    DelayedInsert = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(SalesTypeFilter; SalesTypeFilter)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        SetRecFilters();
                    end;
                }
                field(Act; Act)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Apply(Act);
                    end;
                }
            }
            repeater(Lines)
            {
                field(Type; Rec.Type) { ApplicationArea = All; }
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field("Sales Type"; Rec."Sales Type") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('Open');
        if Log.OpenFilter() then
            SetRecFilters();
    end;

    local procedure SetRecFilters()
    begin
        Rec.SetRange("Sales Type", SalesTypeFilter);
        Rec.SetRange(Type, TypeFilter);
        CurrPage.Update(false);
    end;

    local procedure Apply(Code: Integer)
    begin
        case Code of
            2:
                begin
                    SalesTypeFilter := SalesTypeFilter::C;
                    SetRecFilters();
                end;
            3:
                begin
                    CurrPage.SaveRecord();
                    TypeFilter := TypeFilter::Group;
                    SalesTypeFilter := SalesTypeFilter::C;
                    SetRecFilters();
                end;
            4:
                begin
                    CurrPage.SaveRecord();
                    TypeFilter := TypeFilter::Group;
                    SetRecFilters();
                end;
        end;
    end;

    var
        Log: Codeunit "NLF Log";
        SalesTypeFilter: Option A,B,C,D;
        TypeFilter: Option Item,"Group","None";
        Act: Integer;
}

codeunit 91328 "NLF New Line Filter Refresh"
{
    Subtype = Test;

    var
        Log: Codeunit "NLF Log";

    local procedure Setup(WithOpenFilter: Boolean)
    var
        EnumRow: Record "NLF Enum Row";
        TwoRow: Record "NLF Two Row";
    begin
        EnumRow.DeleteAll();
        TwoRow.DeleteAll();
        Log.Clear();
        Log.SetOpenFilter(WithOpenFilter);
    end;

    local procedure Rows(): Text
    var
        EnumRow: Record "NLF Enum Row";
        TwoRow: Record "NLF Two Row";
    begin
        exit(StrSubstNo('%1/%2', EnumRow.Count(), TwoRow.Count()));
    end;

    local procedure Stored(): Text
    var
        EnumRow: Record "NLF Enum Row";
        TwoRow: Record "NLF Two Row";
        Result: Text;
    begin
        if EnumRow.FindSet() then
            repeat
                Result += StrSubstNo('E %1/%2/%3/%4;', EnumRow."Item No.", EnumRow.Kind, EnumRow."Entry No.", EnumRow.Descr);
            until EnumRow.Next() = 0;
        if TwoRow.FindSet() then
            repeat
                Result += StrSubstNo('T %1/%2/%3/%4;', TwoRow.Type, TwoRow."Code", TwoRow."Sales Type", TwoRow.Descr);
            until TwoRow.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure EnumNone_OpenFilter_KindFilterWithSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum None";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.KindFilter.SetValue('C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumNone_NoOpenFilter_KindFilterWithSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum None";
    begin
        Setup(false);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.KindFilter.SetValue('C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumNone_OpenFilter_SetRangeWithoutSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum None";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(2);
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumNone_OpenFilter_TestPageFilterSetFilter()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum None";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Filter.SetFilter(Kind, 'C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumCurr_OpenFilter_KindFilterWithSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Curr";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.KindFilter.SetValue('C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumCurr_NoOpenFilter_KindFilterWithSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Curr";
    begin
        Setup(false);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.KindFilter.SetValue('C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumCurr_OpenFilter_SetRangeWithoutSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Curr";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(2);
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumCurr_OpenFilter_TestPageFilterSetFilter()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Curr";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Filter.SetFilter(Kind, 'C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumGet_OpenFilter_KindFilterWithSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Get";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.KindFilter.SetValue('C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumGet_NoOpenFilter_KindFilterWithSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Get";
    begin
        Setup(false);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.KindFilter.SetValue('C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumGet_OpenFilter_SetRangeWithoutSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Get";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(2);
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumGet_OpenFilter_TestPageFilterSetFilter()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Get";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Filter.SetFilter(Kind, 'C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumNew_OpenFilter_KindFilterWithSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum New";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.KindFilter.SetValue('C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumNew_NoOpenFilter_KindFilterWithSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum New";
    begin
        Setup(false);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.KindFilter.SetValue('C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumNew_OpenFilter_SetRangeWithoutSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum New";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(2);
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumNew_OpenFilter_TestPageFilterSetFilter()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum New";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Filter.SetFilter(Kind, 'C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumAll_OpenFilter_KindFilterWithSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum All";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.KindFilter.SetValue('C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumAll_NoOpenFilter_KindFilterWithSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum All";
    begin
        Setup(false);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.KindFilter.SetValue('C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumAll_OpenFilter_SetRangeWithoutSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum All";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(2);
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumAll_OpenFilter_TestPageFilterSetFilter()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum All";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Filter.SetFilter(Kind, 'C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumPop_OpenFilter_KindFilterWithSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Pop";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.KindFilter.SetValue('C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumPop_NoOpenFilter_KindFilterWithSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Pop";
    begin
        Setup(false);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.KindFilter.SetValue('C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumPop_OpenFilter_SetRangeWithoutSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Pop";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(2);
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumPop_OpenFilter_TestPageFilterSetFilter()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Pop";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Filter.SetFilter(Kind, 'C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumCurr_OpenFilter_FilterGroup2()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Curr";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(3);
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumCurr_OpenFilter_FilterGroup4()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Curr";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(4);
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumCurr_OpenFilter_RangeFilter()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Curr";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(5);
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumCurr_OpenFilter_TwoValueFilter()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Curr";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(6);
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumCurr_OpenFilter_NonKeyField()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Curr";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(7);
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumCurr_OpenFilter_CodeKeyField()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Curr";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(8);
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumCurr_OpenFilter_KindAndCodeKeyBothChange()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Curr";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(9);
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumNone_OpenFilter_NonKeyField()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum None";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(7);
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumPop_OpenFilter_NonKeyField()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Pop";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(7);
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumPop_OpenFilter_CodeKeyField()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Pop";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(8);
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumCurr_OpenFilter_KindFilter_ThenTypeDescrAndClose()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum Curr";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.KindFilter.SetValue('C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        P.Descr.SetValue('T');
        P.Close();
        Observer.Observe('logAfterTyping', Log.Get());
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure TwoCurr_OpenFilter_SalesTypeFilterWithSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Two Curr";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.SalesTypeFilter.SetValue('C');
        Observer.Observe('type', P.Type.Value);
        Observer.Observe('code', P."Code".Value);
        Observer.Observe('salesType', P."Sales Type".Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure TwoCurr_NoOpenFilter_SalesTypeFilterWithSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Two Curr";
    begin
        Setup(false);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.SalesTypeFilter.SetValue('C');
        Observer.Observe('type', P.Type.Value);
        Observer.Observe('code', P."Code".Value);
        Observer.Observe('salesType', P."Sales Type".Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure TwoCurr_OpenFilter_SalesTypeWithoutSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Two Curr";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(2);
        Observer.Observe('type', P.Type.Value);
        Observer.Observe('code', P."Code".Value);
        Observer.Observe('salesType', P."Sales Type".Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure TwoCurr_OpenFilter_BothKeyFiltersChange()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Two Curr";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(3);
        Observer.Observe('type', P.Type.Value);
        Observer.Observe('code', P."Code".Value);
        Observer.Observe('salesType', P."Sales Type".Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure TwoCurr_OpenFilter_FirstKeyFieldChanges()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Two Curr";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(4);
        Observer.Observe('type', P.Type.Value);
        Observer.Observe('code', P."Code".Value);
        Observer.Observe('salesType', P."Sales Type".Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure TwoCurr_OpenFilter_TestPageFilterSetFilter()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Two Curr";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Filter.SetFilter("Sales Type", 'C');
        Observer.Observe('type', P.Type.Value);
        Observer.Observe('code', P."Code".Value);
        Observer.Observe('salesType', P."Sales Type".Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure TwoNone_OpenFilter_SalesTypeFilterWithSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Two None";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.SalesTypeFilter.SetValue('C');
        Observer.Observe('type', P.Type.Value);
        Observer.Observe('code', P."Code".Value);
        Observer.Observe('salesType', P."Sales Type".Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure TwoNone_NoOpenFilter_SalesTypeFilterWithSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Two None";
    begin
        Setup(false);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.SalesTypeFilter.SetValue('C');
        Observer.Observe('type', P.Type.Value);
        Observer.Observe('code', P."Code".Value);
        Observer.Observe('salesType', P."Sales Type".Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure TwoNone_OpenFilter_SalesTypeWithoutSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Two None";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(2);
        Observer.Observe('type', P.Type.Value);
        Observer.Observe('code', P."Code".Value);
        Observer.Observe('salesType', P."Sales Type".Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure TwoNone_OpenFilter_BothKeyFiltersChange()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Two None";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(3);
        Observer.Observe('type', P.Type.Value);
        Observer.Observe('code', P."Code".Value);
        Observer.Observe('salesType', P."Sales Type".Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure TwoNone_OpenFilter_FirstKeyFieldChanges()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Two None";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Act.SetValue(4);
        Observer.Observe('type', P.Type.Value);
        Observer.Observe('code', P."Code".Value);
        Observer.Observe('salesType', P."Sales Type".Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure TwoNone_OpenFilter_TestPageFilterSetFilter()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Two None";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Filter.SetFilter("Sales Type", 'C');
        Observer.Observe('type', P.Type.Value);
        Observer.Observe('code', P."Code".Value);
        Observer.Observe('salesType', P."Sales Type".Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure TwoCurr_OpenFilter_SalesTypeFilter_ThenTypeDescrAndClose()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Two Curr";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.SalesTypeFilter.SetValue('C');
        Observer.Observe('type', P.Type.Value);
        Observer.Observe('code', P."Code".Value);
        Observer.Observe('salesType', P."Sales Type".Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        P.Descr.SetValue('T');
        P.Close();
        Observer.Observe('logAfterTyping', Log.Get());
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure EnumFnHidden_OpenFilter_TestPageFilterSetFilter_ReadsSeen()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum FnHidden";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Filter.SetFilter(Kind, 'C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('seen', P.Seen.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumFnHidden_OpenFilter_KindFilterWithSave_ReadsSeen()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum FnHidden";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.KindFilter.SetValue('C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('seen', P.Seen.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumFnPlain_OpenFilter_TestPageFilterSetFilter_ReadsSeen()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum FnPlain";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Filter.SetFilter(Kind, 'C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('seen', P.Seen.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumFnPlain_OpenFilter_KindFilterWithSave_ReadsSeen()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum FnPlain";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.KindFilter.SetValue('C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('seen', P.Seen.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumFnVisible_OpenFilter_TestPageFilterSetFilter_ReadsSeen()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum FnVisible";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.Filter.SetFilter(Kind, 'C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('seen', P.Seen.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure EnumFnVisible_OpenFilter_KindFilterWithSave_ReadsSeen()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "NLF Enum FnVisible";
    begin
        Setup(true);
        P.OpenEdit();
        Observer.Observe('open', Log.Get());
        Log.Clear();
        P.KindFilter.SetValue('C');
        Observer.Observe('item', P."Item No.".Value);
        Observer.Observe('kind', P.Kind.Value);
        Observer.Observe('descr', P.Descr.Value);
        Observer.Observe('seen', P.Seen.Value);
        Observer.Observe('log', Log.Get());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;
}
