// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: the Page Metadata system table when pages declare a SourceTableView with filter() on an Option, a Code and an Enum field,
// and a filtered read (SetRange on Page Type / Source Table, FindFirst) while those pages exist.
// Facts: the SourceTableView text BC stores for filter(Quote), filter(A|B) and filter(<>X); that a filtered read answers the page
// asked for whatever the other pages declare.
// BC versions: 27-29

table 99800 "LT SS Doc"
{
    fields
    {
        field(1; "Document Type"; Option) { OptionMembers = Quote,"Order",Invoice; }
        field(2; "No."; Code[20]) { }
        field(3; Kind; Enum "LT SS Kind") { }
    }
    keys { key(PK; "Document Type", "No.") { Clustered = true; } }
}

enum 99800 "LT SS Kind"
{
    Extensible = true;
    value(0; Alpha) { }
    value(1; Beta) { }
}

page 99800 "LT SS Quotes"
{
    PageType = List;
    SourceTable = "LT SS Doc";
    SourceTableView = where("Document Type" = filter(Quote));
    layout { area(Content) { repeater(R) { field("No."; Rec."No.") { } } } }
}

page 99801 "LT SS Either"
{
    PageType = List;
    SourceTable = "LT SS Doc";
    SourceTableView = where("Document Type" = filter(Quote | Invoice));
    layout { area(Content) { repeater(R) { field("No."; Rec."No.") { } } } }
}

page 99802 "LT SS Not Order"
{
    PageType = List;
    SourceTable = "LT SS Doc";
    SourceTableView = where("Document Type" = filter(<> "Order"));
    layout { area(Content) { repeater(R) { field("No."; Rec."No.") { } } } }
}

page 99803 "LT SS Code Filter"
{
    PageType = List;
    SourceTable = "LT SS Doc";
    SourceTableView = where("No." = filter('A|B'));
    layout { area(Content) { repeater(R) { field("No."; Rec."No.") { } } } }
}

page 99804 "LT SS Enum Filter"
{
    PageType = List;
    SourceTable = "LT SS Doc";
    SourceTableView = where(Kind = filter(Beta));
    layout { area(Content) { repeater(R) { field("No."; Rec."No.") { } } } }
}

page 99805 "LT SS Doc API"
{
    PageType = API;
    APIPublisher = 'ltss';
    APIGroup = 'ltss';
    APIVersion = 'v1.0';
    EntityName = 'ltssDocument';
    EntitySetName = 'ltssDocuments';
    SourceTable = "LT SS Doc";
    DelayedInsert = true;
    ODataKeyFields = "No.";
    layout { area(Content) { repeater(R) { field(no; Rec."No.") { } } } }
}

codeunit 99800 "LT SS Page Meta Filter View"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ViewOf(PageId: Integer): Text
    var
        Meta: Record "Page Metadata";
    begin
        if not Meta.Get(PageId) then
            exit('<no row>');
        exit(Meta.SourceTableView);
    end;

    [Test]
    procedure PageMetadata_SourceTableView_FilterShapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('quote', ViewOf(Page::"LT SS Quotes"));
        Observer.Observe('either', ViewOf(Page::"LT SS Either"));
        Observer.Observe('not_order', ViewOf(Page::"LT SS Not Order"));
        Observer.Observe('code_or', ViewOf(Page::"LT SS Code Filter"));
        Observer.Observe('enum', ViewOf(Page::"LT SS Enum Filter"));
        // The view is stored with field numbers, option and enum values as their integers.
        Observer.Expect('quote', 'WHERE(Field1=FILTER(0))');
        Observer.Expect('either', 'WHERE(Field1=FILTER(0|2))');
        Observer.Expect('not_order', 'WHERE(Field1=FILTER(<>1))');
        Observer.Expect('code_or', 'WHERE(Field2=FILTER(A|B))');
        Observer.Expect('enum', 'WHERE(Field3=FILTER(1))');
        Observer.Verify();
    end;

    [Test]
    procedure PageMetadata_FilteredRead_ApiPageOfTable()
    var
        Observer: Codeunit "Probe Observer";
        Meta: Record "Page Metadata";
    begin
        Meta.SetRange(PageType, Meta.PageType::API);
        Meta.SetRange(SourceTable, Database::"LT SS Doc");
        Observer.Observe('find_first', Format(Meta.FindFirst()));
        Observer.Observe('id', Format(Meta.ID));
        Observer.Observe('is_api_page', Format(Meta.ID = Page::"LT SS Doc API"));
        Observer.Observe('count', Format(Meta.Count()));
        Observer.Observe('view_of_api', Meta.SourceTableView);
        Meta.Reset();
        Meta.SetRange(SourceTable, Database::"LT SS Doc");
        Observer.Observe('count_all_pages_of_table', Format(Meta.Count()));
        Meta.SetRange(PageType, Meta.PageType::List);
        Observer.Observe('count_list_pages_of_table', Format(Meta.Count()));
        Meta.FindFirst();
        Observer.Observe('first_list_page_view', Meta.SourceTableView);
        Observer.Expect('find_first', 'Yes');
        Observer.Expect('id', '99805');
        Observer.Expect('is_api_page', 'Yes');
        Observer.Expect('count', '1');
        Observer.Expect('view_of_api', '');
        Observer.Expect('count_all_pages_of_table', '6');
        Observer.Expect('count_list_pages_of_table', '5');
        Observer.Expect('first_list_page_view', 'WHERE(Field1=FILTER(0))');
        Observer.Verify();
    end;
}
