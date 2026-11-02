// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfilter/testfilter-getfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 94070 - 94074
// Probe (writer Y76, al-runtime-rs assumption test-filter-enum-range-ordinals): TestPage Filter.GetFilter of an Enum field (five members, ordinals
// 0..4, one with a gap in its ordinals: 7) filtered on the record handed to Page.Run or by a SourceTableView, as a range over three, four or all
// members, an open-ended range, a list, <> and & forms, a text range and a text list. Two-member ranges and lists are pinned by
// pages/lt-cd-testpage-leads/CdTestPageLeads.al SH_TestPageFilter_GetFilter_EnumRangeAndList.
// BC versions: 27, 28, 29

enum 94070 "LT Y76 TF Kind"
{
    Extensible = false;

    value(0; First) { }
    value(1; Second) { }
    value(2; Third) { }
    value(4; Fifth) { }
    value(7; Eighth) { }
}

table 94071 "LT Y76 TF Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Kind; Enum "LT Y76 TF Kind") { }
        field(2; No; Integer) { }
    }

    keys
    {
        key(PK; Kind, No) { Clustered = true; }
    }
}

page 94072 "LT Y76 TF List"
{
    PageType = List;
    SourceTable = "LT Y76 TF Line";
    ApplicationArea = All;
    Caption = 'Y76 TF List';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(KindCtl; Rec.Kind) { ApplicationArea = All; }
                field(NoCtl; Rec.No) { ApplicationArea = All; }
            }
        }
    }
}

page 94073 "LT Y76 TF View List"
{
    PageType = List;
    SourceTable = "LT Y76 TF Line";
    SourceTableView = where(Kind = filter(First..Fifth));
    ApplicationArea = All;
    Caption = 'Y76 TF View List';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(KindCtl; Rec.Kind) { ApplicationArea = All; }
                field(NoCtl; Rec.No) { ApplicationArea = All; }
            }
        }
    }
}

page 94075 "LT Y76 TF View Or List"
{
    PageType = List;
    SourceTable = "LT Y76 TF Line";
    SourceTableView = where(Kind = filter(First | Third | Fifth));
    ApplicationArea = All;
    Caption = 'Y76 TF View Or List';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(KindCtl; Rec.Kind) { ApplicationArea = All; }
                field(NoCtl; Rec.No) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 94074 "LT Y76 TF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure RunList(var Line: Record "LT Y76 TF Line"; Tag: Text)
    var
        List: TestPage "LT Y76 TF List";
    begin
        List.Trap();
        Page.Run(Page::"LT Y76 TF List", Line);
        Observer.Observe(Tag, List.Filter.GetFilter(Kind));
        List.Close();
    end;

    [Test]
    procedure Y76_SetRange_ThreeAndMoreMembers()
    var
        Line: Record "LT Y76 TF Line";
    begin
        Line.SetRange(Kind, Line.Kind::First, Line.Kind::Third);
        RunList(Line, 'First..Third');
        Line.SetRange(Kind, Line.Kind::First, Line.Kind::Fifth);
        RunList(Line, 'First..Fifth');
        Line.SetRange(Kind, Line.Kind::First, Line.Kind::Eighth);
        RunList(Line, 'First..Eighth');
        Line.SetRange(Kind, Line.Kind::Second, Line.Kind::Fifth);
        RunList(Line, 'Second..Fifth');
        Line.SetRange(Kind, Line.Kind::Third, Line.Kind::Eighth);
        RunList(Line, 'Third..Eighth');
        Line.SetRange(Kind, Line.Kind::Third, Line.Kind::Fifth);
        RunList(Line, 'Third..Fifth');
        Line.SetRange(Kind, Line.Kind::Fifth, Line.Kind::Eighth);
        RunList(Line, 'Fifth..Eighth');
        Observer.Finish();
    end;

    [Test]
    procedure Y76_SetFilter_TextAndOpenRanges()
    var
        Line: Record "LT Y76 TF Line";
    begin
        Line.SetFilter(Kind, 'First..Third');
        RunList(Line, 'text First..Third');
        Line.SetFilter(Kind, 'First..Eighth');
        RunList(Line, 'text First..Eighth');
        Line.SetFilter(Kind, '%1..', Line.Kind::Second);
        RunList(Line, 'Second..');
        Line.SetFilter(Kind, '..%1', Line.Kind::Fifth);
        RunList(Line, '..Fifth');
        Line.SetFilter(Kind, '>%1', Line.Kind::Second);
        RunList(Line, '>Second');
        Line.SetFilter(Kind, '>=%1', Line.Kind::Second);
        RunList(Line, '>=Second');
        Line.SetFilter(Kind, '<%1', Line.Kind::Fifth);
        RunList(Line, '<Fifth');
        Line.SetFilter(Kind, '<=%1', Line.Kind::Fifth);
        RunList(Line, '<=Fifth');
        Observer.Finish();
    end;

    [Test]
    procedure Y76_SetFilter_ListsAndNegations()
    var
        Line: Record "LT Y76 TF Line";
    begin
        Line.SetFilter(Kind, '%1|%2|%3', Line.Kind::First, Line.Kind::Third, Line.Kind::Fifth);
        RunList(Line, 'list of three');
        Line.SetFilter(Kind, '%1|%2|%3', Line.Kind::Second, Line.Kind::Third, Line.Kind::Fifth);
        RunList(Line, 'list Second Third Fifth');
        Line.SetFilter(Kind, '%1..%2|%3', Line.Kind::First, Line.Kind::Third, Line.Kind::Eighth);
        RunList(Line, 'range or single');
        Line.SetFilter(Kind, '%1|%2..%3', Line.Kind::First, Line.Kind::Third, Line.Kind::Fifth);
        RunList(Line, 'single or range');
        Line.SetFilter(Kind, '<>%1&<>%2&<>%3', Line.Kind::First, Line.Kind::Second, Line.Kind::Third);
        RunList(Line, 'three not-equal');
        Line.SetFilter(Kind, '<>%1&<>%2', Line.Kind::First, Line.Kind::Second);
        RunList(Line, 'two not-equal');
        Line.SetFilter(Kind, '<>%1', Line.Kind::First);
        RunList(Line, 'not First');
        Line.SetFilter(Kind, '%1|%2', Line.Kind::First, Line.Kind::Second);
        RunList(Line, 'list of two');
        Observer.Finish();
    end;

    [Test]
    procedure Y76_SourceTableView_Range()
    var
        List: TestPage "LT Y76 TF View List";
        OrList: TestPage "LT Y76 TF View Or List";
    begin
        List.OpenView();
        Observer.Observe('view First..Fifth', List.Filter.GetFilter(Kind));
        List.Close();
        OrList.OpenView();
        Observer.Observe('view First|Third|Fifth', OrList.Filter.GetFilter(Kind));
        OrList.Close();
        Observer.Finish();
    end;
}
