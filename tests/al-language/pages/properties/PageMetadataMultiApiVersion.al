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
