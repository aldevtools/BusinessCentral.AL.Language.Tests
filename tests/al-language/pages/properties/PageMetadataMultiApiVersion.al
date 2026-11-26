// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-apiversion-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: what the APIVersion column of Page Metadata and Query Metadata holds for an API object that declares several
//   versions (al-runner issue 7818). The expected literals are the reporter's reading of Microsoft's MCP module
//   (it splits the column on ','); the corpus CI matrix measures them on BC 27, 28 and 29.
// BC versions: 27, 28, 29
// RISKY: API pages and queries need a valid publisher, group, version and entity names; own file so a compile failure
//   drops only this file.

table 68081 "LT MAV Api Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 68082 "LT MAV Three Versions"
{
    PageType = API;
    SourceTable = "LT MAV Api Row";
    APIPublisher = 'ltprobe';
    APIGroup = 'ltmav';
    APIVersion = 'v1.0', 'v2.0', 'beta';
    EntityName = 'ltMavRow';
    EntitySetName = 'ltMavRows';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    layout
    {
        area(Content)
        {
            field(id; Rec.Id) { }
        }
    }
}

page 68083 "LT MAV Descending Versions"
{
    PageType = API;
    SourceTable = "LT MAV Api Row";
    APIPublisher = 'ltprobe';
    APIGroup = 'ltmav';
    APIVersion = 'v2.0', 'v1.0';
    EntityName = 'ltMavDescRow';
    EntitySetName = 'ltMavDescRows';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    layout
    {
        area(Content)
        {
            field(id; Rec.Id) { }
        }
    }
}

query 68084 "LT MAV Api Query"
{
    QueryType = API;
    APIPublisher = 'ltprobe';
    APIGroup = 'ltmav';
    APIVersion = 'v2.0', 'beta', 'v1.0';
    EntityName = 'ltMavQueryRow';
    EntitySetName = 'ltMavQueryRows';

    elements
    {
        dataitem(Row; "LT MAV Api Row")
        {
            column(id; Id) { }
        }
    }
}

codeunit 68085 "LT MAV Multi ApiVersion"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PageMetadata_ThreeVersions_InDeclaredOrder()
    var
        PageMetadata: Record "Page Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        PageMetadata.Get(Page::"LT MAV Three Versions");
        Observer.Observe('api_version', '[' + PageMetadata.APIVersion + ']');
        Observer.Observe('length', Format(StrLen(PageMetadata.APIVersion)));
        Observer.Expect('api_version', '[v1.0,v2.0,beta]');
        Observer.Expect('length', '14');
        Observer.Verify();
    end;

    [Test]
    procedure PageMetadata_DescendingVersions_InDeclaredOrder()
    var
        PageMetadata: Record "Page Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        PageMetadata.Get(Page::"LT MAV Descending Versions");
        Observer.Observe('api_version', '[' + PageMetadata.APIVersion + ']');
        Observer.Expect('api_version', '[v2.0,v1.0]');
        Observer.Verify();
    end;

    [Test]
    procedure PageMetadata_FilterOnFullList()
    var
        PageMetadata: Record "Page Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        PageMetadata.SetRange(ID, Page::"LT MAV Three Versions");
        PageMetadata.SetRange(APIVersion, 'v1.0,v2.0,beta');
        Observer.Observe('by_full_list', Format(PageMetadata.Count()));
        PageMetadata.SetRange(APIVersion, 'v1.0');
        Observer.Observe('by_first_version', Format(PageMetadata.Count()));
        Observer.Expect('by_full_list', '1');
        Observer.Expect('by_first_version', '0');
        Observer.Verify();
    end;

    [Test]
    procedure QueryMetadata_ThreeVersions_InDeclaredOrder()
    var
        QueryMetadata: Record "Query Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        QueryMetadata.Get(Query::"LT MAV Api Query");
        Observer.Observe('api_version', '[' + QueryMetadata.APIVersion + ']');
        Observer.Expect('api_version', '[v2.0,beta,v1.0]');
        Observer.Verify();
    end;
}

page 68086 "LT MAV Four Versions"
{
    PageType = API;
    SourceTable = "LT MAV Api Row";
    APIPublisher = 'ltprobe';
    APIGroup = 'ltmav';
    APIVersion = 'v1.0', 'v2.0', 'v3.0', 'beta';
    EntityName = 'ltMavFourRow';
    EntitySetName = 'ltMavFourRows';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    layout
    {
        area(Content)
        {
            field(id; Rec.Id) { }
        }
    }
}

query 68087 "LT MAV Two Version Query"
{
    QueryType = API;
    APIPublisher = 'ltprobe';
    APIGroup = 'ltmav';
    APIVersion = 'v2.0', 'v1.0';
    EntityName = 'ltMavQueryTwoRow';
    EntitySetName = 'ltMavQueryTwoRows';

    elements
    {
        dataitem(Row; "LT MAV Api Row")
        {
            column(id; Id) { }
        }
    }
}

query 68088 "LT MAV Four Version Query"
{
    QueryType = API;
    APIPublisher = 'ltprobe';
    APIGroup = 'ltmav';
    APIVersion = 'v1.0', 'v2.0', 'v3.0', 'beta';
    EntityName = 'ltMavQueryFourRow';
    EntitySetName = 'ltMavQueryFourRows';

    elements
    {
        dataitem(Row; "LT MAV Api Row")
        {
            column(id; Id) { }
        }
    }
}

codeunit 68089 "LT MAV Multi ApiVersion Obs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure QueryMetadata_TwoVersions()
    var
        QueryMetadata: Record "Query Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        QueryMetadata.Get(Query::"LT MAV Two Version Query");
        Observer.Observe('two_value', '[' + QueryMetadata.APIVersion + ']');
        Observer.Observe('two_format', '[' + Format(QueryMetadata.APIVersion) + ']');
        Observer.Observe('two_length', Format(StrLen(QueryMetadata.APIVersion)));
        Observer.Finish();
    end;

    [Test]
    procedure QueryMetadata_ThreeVersions_FormatAndLength()
    var
        QueryMetadata: Record "Query Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        QueryMetadata.Get(Query::"LT MAV Api Query");
        Observer.Observe('three_format', '[' + Format(QueryMetadata.APIVersion) + ']');
        Observer.Observe('three_length', Format(StrLen(QueryMetadata.APIVersion)));
        Observer.Finish();
    end;

    [Test]
    procedure QueryMetadata_ExactFilters()
    var
        QueryMetadata: Record "Query Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        QueryMetadata.SetRange(ID, Query::"LT MAV Api Query");
        QueryMetadata.SetRange(APIVersion, 'v2.0,beta,v1.0');
        Observer.Observe('q3_full_list', Format(QueryMetadata.Count()));
        QueryMetadata.SetRange(APIVersion, 'v2.0');
        Observer.Observe('q3_first_version', Format(QueryMetadata.Count()));
        QueryMetadata.SetRange(APIVersion, 'v1.0');
        Observer.Observe('q3_last_version', Format(QueryMetadata.Count()));
        QueryMetadata.SetRange(ID, Query::"LT MAV Two Version Query");
        QueryMetadata.SetRange(APIVersion, 'v2.0,v1.0');
        Observer.Observe('q2_full_list', Format(QueryMetadata.Count()));
        QueryMetadata.SetRange(APIVersion, 'v1.0');
        Observer.Observe('q2_one_version', Format(QueryMetadata.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure PageMetadata_WildcardFilters()
    var
        PageMetadata: Record "Page Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        PageMetadata.SetRange(ID, Page::"LT MAV Three Versions");
        PageMetadata.SetFilter(APIVersion, '*v2.0*');
        Observer.Observe('p3_contains_v2', Format(PageMetadata.Count()));
        PageMetadata.SetFilter(APIVersion, 'v1.0*');
        Observer.Observe('p3_starts_v1', Format(PageMetadata.Count()));
        PageMetadata.SetFilter(APIVersion, '*beta');
        Observer.Observe('p3_ends_beta', Format(PageMetadata.Count()));
        PageMetadata.SetFilter(APIVersion, 'v1.0|v1.0,v2.0,beta');
        Observer.Observe('p3_or_list', Format(PageMetadata.Count()));
        PageMetadata.SetRange(ID, Page::"LT MAV Descending Versions");
        PageMetadata.SetFilter(APIVersion, '*v1.0');
        Observer.Observe('p2_ends_v1', Format(PageMetadata.Count()));
        PageMetadata.SetFilter(APIVersion, 'v2.0*');
        Observer.Observe('p2_starts_v2', Format(PageMetadata.Count()));
        PageMetadata.SetFilter(APIVersion, 'v2.0|v2.0,v1.0');
        Observer.Observe('p2_or_list', Format(PageMetadata.Count()));
        PageMetadata.SetFilter(APIVersion, 'v1.0');
        Observer.Observe('p2_exact_one', Format(PageMetadata.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure QueryMetadata_WildcardFilters()
    var
        QueryMetadata: Record "Query Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        QueryMetadata.SetRange(ID, Query::"LT MAV Api Query");
        QueryMetadata.SetFilter(APIVersion, '*v2.0*');
        Observer.Observe('q3_contains_v2', Format(QueryMetadata.Count()));
        QueryMetadata.SetFilter(APIVersion, 'v2.0*');
        Observer.Observe('q3_starts_v2', Format(QueryMetadata.Count()));
        QueryMetadata.SetFilter(APIVersion, '*v1.0');
        Observer.Observe('q3_ends_v1', Format(QueryMetadata.Count()));
        QueryMetadata.SetFilter(APIVersion, '*beta');
        Observer.Observe('q3_ends_beta', Format(QueryMetadata.Count()));
        QueryMetadata.SetFilter(APIVersion, 'v1.0|v2.0,beta,v1.0');
        Observer.Observe('q3_or_list', Format(QueryMetadata.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure PageMetadata_RecordRefValueAndFormat()
    var
        PageMetadata: Record "Page Metadata";
        RecRef: RecordRef;
        FldRef: FieldRef;
        Observer: Codeunit "Probe Observer";
    begin
        PageMetadata.Get(Page::"LT MAV Three Versions");
        Observer.Observe('p3_format', '[' + Format(PageMetadata.APIVersion) + ']');
        RecRef.GetTable(PageMetadata);
        FldRef := RecRef.Field(PageMetadata.FieldNo(APIVersion));
        Observer.Observe('p3_fieldref_value', '[' + Format(FldRef.Value) + ']');
        Observer.Observe('p3_fieldref_length', Format(FldRef.Length));
        Observer.Finish();
    end;

    [Test]
    procedure PageMetadata_FourVersions()
    var
        PageMetadata: Record "Page Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        PageMetadata.Get(Page::"LT MAV Four Versions");
        Observer.Observe('p4_value', '[' + PageMetadata.APIVersion + ']');
        Observer.Observe('p4_length', Format(StrLen(PageMetadata.APIVersion)));
        PageMetadata.SetRange(ID, Page::"LT MAV Four Versions");
        PageMetadata.SetRange(APIVersion, 'v1.0,v2.0,v3.0,beta');
        Observer.Observe('p4_full_list', Format(PageMetadata.Count()));
        PageMetadata.SetRange(APIVersion, 'v1.0');
        Observer.Observe('p4_first_version', Format(PageMetadata.Count()));
        PageMetadata.SetFilter(APIVersion, '*v3.0*');
        Observer.Observe('p4_contains_v3', Format(PageMetadata.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure QueryMetadata_FourVersions()
    var
        QueryMetadata: Record "Query Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        QueryMetadata.Get(Query::"LT MAV Four Version Query");
        Observer.Observe('q4_value', '[' + QueryMetadata.APIVersion + ']');
        Observer.Observe('q4_length', Format(StrLen(QueryMetadata.APIVersion)));
        QueryMetadata.SetRange(ID, Query::"LT MAV Four Version Query");
        QueryMetadata.SetRange(APIVersion, 'v1.0,v2.0,v3.0,beta');
        Observer.Observe('q4_full_list', Format(QueryMetadata.Count()));
        QueryMetadata.SetRange(APIVersion, 'v1.0');
        Observer.Observe('q4_first_version', Format(QueryMetadata.Count()));
        Observer.Finish();
    end;
}
