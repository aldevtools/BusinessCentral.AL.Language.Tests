// Fixture for query/TestQueryMetadataVirtualTable.al — an API query, so the Query Metadata
// virtual table has a row whose APIPublisher / APIGroup / APIVersion / EntityName /
// EntitySetName columns are non-blank. Every other query fixture in this directory is
// QueryType = Normal, which leaves all five blank and cannot distinguish a provider that
// fills them from one that does not.
query 60900 "ALT QM Api Probe"
{
    Access = Public;
    QueryType = API;
    APIPublisher = 'altpub';
    APIGroup = 'altgrp';
    APIVersion = 'v2.0';
    EntityName = 'altQmProbe';
    EntitySetName = 'altQmProbes';
    Caption = 'ALT QM Api Probe Caption';

    elements
    {
        dataitem(QjOrder; "QJ Order")
        {
            column(EntryNo; "Entry No.")
            {
            }
        }
    }
}
