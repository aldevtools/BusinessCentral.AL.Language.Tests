// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-api-pagetype
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// RISKY: an API page needs a valid publisher, group, version, entity names and ODataKeyFields; own file so a compile failure drops only this file.

table 73211 "LT P163 Api Row"
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

page 73210 "LT P163 Api Page"
{
    PageType = API;
    SourceTable = "LT P163 Api Row";
    APIPublisher = 'ltprobe';
    APIGroup = 'ltprobe';
    APIVersion = 'v1.0';
    EntityName = 'ltProbeRow';
    EntitySetName = 'ltProbeRows';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    layout
    {
        area(Content)
        {
            field(id; Rec.SystemId) { }
            field(txt; Rec.Txt) { }
        }
    }
}

codeunit 73212 "LT P163 PM Api"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P163_PageMetadata_ApiPage_Row()
    var
        PageMetadata: Record "Page Metadata";
        RecRef: RecordRef;
        FldRef: FieldRef;
        i: Integer;
        Named: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('found', Format(PageMetadata.Get(Page::"LT P163 Api Page")));
        Observer.Observe('name', PageMetadata.Name);
        Observer.Observe('page_type', Format(PageMetadata.PageType) + '/' + Format(PageMetadata.PageType, 0, 2));
        Observer.Observe('source_table_is_own', Format(PageMetadata.SourceTable = Database::"LT P163 Api Row"));
        RecRef.GetTable(PageMetadata);
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            if (StrPos(UpperCase(FldRef.Name), 'API') > 0) or (StrPos(UpperCase(FldRef.Name), 'ENTITY') > 0) or (StrPos(UpperCase(FldRef.Name), 'ODATA') > 0) then
                Named += FldRef.Name + '=[' + Format(FldRef.Value) + '];';
        end;
        Observer.Observe('columns_naming_the_api', Named);
        Observer.Expect('found', 'Yes');
        Observer.Expect('name', 'LT P163 Api Page');
        Observer.Expect('page_type', 'API/11');
        Observer.Expect('source_table_is_own', 'Yes');
        Observer.Expect('columns_naming_the_api', 'APIPublisher=[ltprobe];APIGroup=[ltprobe];APIVersion=[v1.0];EntitySetName=[ltProbeRows];EntityName=[ltProbeRow];');
        Observer.Verify();
    end;

    [Test]
    procedure P163_PageMetadata_ApiPage_FilterOnType()
    var
        PageMetadata: Record "Page Metadata";
        Observer: Codeunit "Probe Observer";
    begin
        PageMetadata.SetRange(ID, Page::"LT P163 Api Page");
        PageMetadata.SetRange(PageType, PageMetadata.PageType::API);
        Observer.Observe('by_api_member', Format(PageMetadata.Count()));
        Observer.Observe('api_member_ordinal', Format(PageMetadata.PageType::API, 0, 2));
        PageMetadata.SetRange(PageType, PageMetadata.PageType::Card);
        Observer.Observe('by_card_member', Format(PageMetadata.Count()));
        Observer.Expect('by_api_member', '1');
        Observer.Expect('api_member_ordinal', '11');
        Observer.Expect('by_card_member', '0');
        Observer.Verify();
    end;
}
