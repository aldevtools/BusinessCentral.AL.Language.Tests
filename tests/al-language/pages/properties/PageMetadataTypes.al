// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-pagetype-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 73196 "LT P163 PM Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 73197 "LT P163 PM Card"
{
    PageType = Card;
    SourceTable = "LT P163 PM Row";
    layout
    {
        area(Content)
        {
            field(Txt; Rec.Txt) { ApplicationArea = All; }
        }
    }
}

page 73198 "LT P163 PM List"
{
    PageType = List;
    SourceTable = "LT P163 PM Row";
    layout
    {
        area(Content)
        {
            field(Txt; Rec.Txt) { ApplicationArea = All; }
        }
    }
}

page 73199 "LT P163 PM Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT P163 PM Row";
    layout
    {
        area(Content)
        {
            field(Txt; Rec.Txt) { ApplicationArea = All; }
        }
    }
}

page 73200 "LT P163 PM ListPlus"
{
    PageType = ListPlus;
    SourceTable = "LT P163 PM Row";
    layout
    {
        area(Content)
        {
            field(Txt; Rec.Txt) { ApplicationArea = All; }
        }
    }
}

page 73201 "LT P163 PM CardPart"
{
    PageType = CardPart;
    SourceTable = "LT P163 PM Row";
    layout
    {
        area(Content)
        {
            field(Txt; Rec.Txt) { ApplicationArea = All; }
        }
    }
}

page 73202 "LT P163 PM ListPart"
{
    PageType = ListPart;
    SourceTable = "LT P163 PM Row";
    layout
    {
        area(Content)
        {
            field(Txt; Rec.Txt) { ApplicationArea = All; }
        }
    }
}

page 73203 "LT P163 PM Document"
{
    PageType = Document;
    SourceTable = "LT P163 PM Row";
    layout
    {
        area(Content)
        {
            field(Txt; Rec.Txt) { ApplicationArea = All; }
        }
    }
}

page 73204 "LT P163 PM ConfirmationDialog"
{
    PageType = ConfirmationDialog;
}

page 73205 "LT P163 PM NavigatePage"
{
    PageType = NavigatePage;
}

page 73206 "LT P163 PM RoleCenter"
{
    PageType = RoleCenter;
}

page 73207 "LT P163 PM StandardDialog"
{
    PageType = StandardDialog;
}

page 73208 "LT P163 PM HeadlinePart"
{
    PageType = HeadlinePart;
}

codeunit 73209 "LT P163 PM Types"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TypeOf(PageId: Integer): Text
    var
        PageMetadata: Record "Page Metadata";
    begin
        if not PageMetadata.Get(PageId) then
            exit('<no row>');
        exit(Format(PageMetadata.PageType) + '/' + Format(PageMetadata.PageType, 0, 2) + '/src=' + Format(PageMetadata.SourceTable));
    end;

    [Test]
    procedure P163_PageMetadata_PageType_PerDeclaredType()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Card', TypeOf(Page::"LT P163 PM Card"));
        Observer.Observe('List', TypeOf(Page::"LT P163 PM List"));
        Observer.Observe('Worksheet', TypeOf(Page::"LT P163 PM Worksheet"));
        Observer.Observe('ListPlus', TypeOf(Page::"LT P163 PM ListPlus"));
        Observer.Observe('CardPart', TypeOf(Page::"LT P163 PM CardPart"));
        Observer.Observe('ListPart', TypeOf(Page::"LT P163 PM ListPart"));
        Observer.Observe('Document', TypeOf(Page::"LT P163 PM Document"));
        Observer.Observe('ConfirmationDialog', TypeOf(Page::"LT P163 PM ConfirmationDialog"));
        Observer.Observe('NavigatePage', TypeOf(Page::"LT P163 PM NavigatePage"));
        Observer.Observe('RoleCenter', TypeOf(Page::"LT P163 PM RoleCenter"));
        Observer.Observe('StandardDialog', TypeOf(Page::"LT P163 PM StandardDialog"));
        Observer.Observe('HeadlinePart', TypeOf(Page::"LT P163 PM HeadlinePart"));
        Observer.Observe('no_such_page', TypeOf(73998));
        Observer.Expect('Card', 'Card/0/src=73196');
        Observer.Expect('List', 'List/1/src=73196');
        Observer.Expect('Worksheet', 'Worksheet/6/src=73196');
        Observer.Expect('ListPlus', 'ListPlus/7/src=73196');
        Observer.Expect('CardPart', 'CardPart/3/src=73196');
        Observer.Expect('ListPart', 'ListPart/4/src=73196');
        Observer.Expect('Document', 'Document/5/src=73196');
        Observer.Expect('ConfirmationDialog', 'ConfirmationDialog/8/src=0');
        Observer.Expect('NavigatePage', 'NavigatePage/9/src=0');
        Observer.Expect('RoleCenter', 'RoleCenter/2/src=0');
        Observer.Expect('StandardDialog', 'StandardDialog/10/src=0');
        Observer.Expect('HeadlinePart', 'HeadlinePart/12/src=0');
        Observer.Expect('no_such_page', '<no row>');
        Observer.Verify();
    end;

    [Test]
    procedure P163_PageMetadata_PageType_ColumnOptionMembers()
    var
        PageMetadata: Record "Page Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Card', Format(PageMetadata.PageType::Card, 0, 2));
        Observer.Observe('List', Format(PageMetadata.PageType::List, 0, 2));
        Observer.Observe('RoleCenter', Format(PageMetadata.PageType::RoleCenter, 0, 2));
        Observer.Observe('CardPart', Format(PageMetadata.PageType::CardPart, 0, 2));
        Observer.Observe('ListPart', Format(PageMetadata.PageType::ListPart, 0, 2));
        Observer.Observe('Document', Format(PageMetadata.PageType::Document, 0, 2));
        Observer.Observe('Worksheet', Format(PageMetadata.PageType::Worksheet, 0, 2));
        Observer.Observe('ListPlus', Format(PageMetadata.PageType::ListPlus, 0, 2));
        Observer.Observe('ConfirmationDialog', Format(PageMetadata.PageType::ConfirmationDialog, 0, 2));
        Observer.Observe('NavigatePage', Format(PageMetadata.PageType::NavigatePage, 0, 2));
        Observer.Observe('StandardDialog', Format(PageMetadata.PageType::StandardDialog, 0, 2));
        Observer.Observe('HeadlinePart', Format(PageMetadata.PageType::HeadlinePart, 0, 2));
        Observer.Expect('Card', '0');
        Observer.Expect('List', '1');
        Observer.Expect('RoleCenter', '2');
        Observer.Expect('CardPart', '3');
        Observer.Expect('ListPart', '4');
        Observer.Expect('Document', '5');
        Observer.Expect('Worksheet', '6');
        Observer.Expect('ListPlus', '7');
        Observer.Expect('ConfirmationDialog', '8');
        Observer.Expect('NavigatePage', '9');
        Observer.Expect('StandardDialog', '10');
        Observer.Expect('HeadlinePart', '12');
        Observer.Verify();
    end;

    [Test]
    procedure P163_PageMetadata_FilterOnPageType()
    var
        PageMetadata: Record "Page Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        PageMetadata.SetRange(ID, Page::"LT P163 PM Card", Page::"LT P163 PM HeadlinePart");
        Observer.Observe('own_pages', Format(PageMetadata.Count()));
        PageMetadata.SetRange(PageType, PageMetadata.PageType::Card);
        Observer.Observe('own_cards', Format(PageMetadata.Count()));
        PageMetadata.SetRange(PageType, PageMetadata.PageType::List);
        Observer.Observe('own_lists', Format(PageMetadata.Count()));
        PageMetadata.SetFilter(PageType, '%1|%2', PageMetadata.PageType::CardPart, PageMetadata.PageType::ListPart);
        Observer.Observe('own_parts', Format(PageMetadata.Count()));
        PageMetadata.SetRange(PageType);
        PageMetadata.SetRange(SourceTable, Database::"LT P163 PM Row");
        Observer.Observe('own_with_source_table', Format(PageMetadata.Count()));
        PageMetadata.SetRange(SourceTable, 0);
        Observer.Observe('own_without_source_table', Format(PageMetadata.Count()));
        Observer.Expect('own_pages', '12');
        Observer.Expect('own_cards', '1');
        Observer.Expect('own_lists', '1');
        Observer.Expect('own_parts', '2');
        Observer.Expect('own_with_source_table', '7');
        Observer.Expect('own_without_source_table', '5');
        Observer.Verify();
    end;
}
