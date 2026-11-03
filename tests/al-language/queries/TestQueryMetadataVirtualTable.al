// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: ALT QM Api Probe (query 60900), QJ Order Sum (query 60760), Assert (60021)
//
// Pins the built-in "Query Metadata" system virtual table (2000000142): one row per query
// object, computed from the query's own metadata rather than stored anywhere. Sibling of
// Page Metadata (2000000138) and Table Metadata (2000000136), both already pinned elsewhere
// in this corpus.
//
// Written for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4147, which records that
// the runner serves NO provider for this table -- a table with no provider falls through to
// an empty temp store and answers "no rows" to every read, silently. Nothing here predicts
// the runner's answer.
//
// WHY THE API FIXTURE EXISTS: every other query in this directory is QueryType = Normal, which
// leaves APIPublisher, APIGroup, APIVersion, EntityName and EntitySetName blank. A provider
// that never fills those five would satisfy a Normal-only test completely. Query 60900 is
// declared API precisely so those columns have something to be wrong about, and the arms below
// assert them in BOTH directions -- set on the API query, blank on the Normal one.

codeunit 60913 "Test Query Metadata VT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";

    local procedure ApiQuery(): Integer
    begin
        exit(Query::"ALT QM Api Probe");
    end;

    local procedure NormalQuery(): Integer
    begin
        exit(Query::"QJ Order Sum");
    end;

    [Test]
    procedure Record_QueryMetadata_ADeclaredQuery_HasARowUnderItsObjectId()
    var
        QueryMetadata: Record "Query Metadata";
    begin
        Assert.IsTrue(QueryMetadata.Get(ApiQuery()), 'The Query Metadata table has a row for a declared query, keyed by its object id.');
        Assert.AreEqual('ALT QM Api Probe', QueryMetadata.Name, 'The row carries the query''s object name.');
    end;

    [Test]
    procedure Record_QueryMetadata_UnknownId_HasNoRow()
    var
        QueryMetadata: Record "Query Metadata";
    begin
        // The control that separates "the provider works" from "the provider answers rows for
        // anything". 60899 is not a query in this app.
        Assert.IsFalse(QueryMetadata.Get(60899), 'An object id that is not a query has no Query Metadata row.');
    end;

    [Test]
    procedure Record_QueryMetadata_Caption_FallsBackToTheNameWhenNoneIsDeclared()
    var
        Captioned: Record "Query Metadata";
        Uncaptioned: Record "Query Metadata";
    begin
        // Both directions on one column: the declared caption is reported, and a query that
        // declares none reports its NAME rather than a blank.
        Assert.IsTrue(Captioned.Get(ApiQuery()), 'The API query has a row.');
        Assert.AreEqual('ALT QM Api Probe Caption', Captioned.Caption, 'A declared Caption is reported as itself.');

        Assert.IsTrue(Uncaptioned.Get(NormalQuery()), 'The Normal query has a row.');
        Assert.AreEqual(Uncaptioned.Name, Uncaptioned.Caption, 'A query declaring no Caption reports its Name as the Caption, not a blank.');
    end;

    [Test]
    procedure Record_QueryMetadata_ApiColumns_AreSetOnAnApiQueryAndBlankOnANormalOne()
    var
        ApiRow: Record "Query Metadata";
        NormalRow: Record "Query Metadata";
    begin
        Assert.IsTrue(ApiRow.Get(ApiQuery()), 'The API query has a row.');
        Assert.AreEqual('altpub', ApiRow.APIPublisher, 'APIPublisher is reported from the query''s own declaration.');
        Assert.AreEqual('altgrp', ApiRow.APIGroup, 'APIGroup is reported from the query''s own declaration.');
        Assert.AreEqual('altQmProbe', ApiRow.EntityName, 'EntityName is reported from the query''s own declaration.');
        Assert.AreEqual('altQmProbes', ApiRow.EntitySetName, 'EntitySetName is reported from the query''s own declaration.');

        // The other direction, which is what stops a provider copying one row's values across.
        Assert.IsTrue(NormalRow.Get(NormalQuery()), 'The Normal query has a row.');
        Assert.AreEqual('', NormalRow.APIPublisher, 'A QueryType = Normal query reports a blank APIPublisher.');
        Assert.AreEqual('', NormalRow.APIGroup, 'A QueryType = Normal query reports a blank APIGroup.');
        Assert.AreEqual('', NormalRow.EntitySetName, 'A QueryType = Normal query reports a blank EntitySetName.');
    end;

    [Test]
    procedure Record_QueryMetadata_ApiVersion_ReportsTheDeclaredVersion()
    var
        QueryMetadata: Record "Query Metadata";
    begin
        // The column is APIVersion (singular) and the fixture declares exactly one version,
        // so this arm pins the single-version case only. A query declaring several is a
        // separate claim this test does not make.
        Assert.IsTrue(QueryMetadata.Get(ApiQuery()), 'The API query has a row.');
        Assert.AreEqual('v2.0', QueryMetadata.APIVersion, 'The declared APIVersion is reported.');
    end;

    [Test]
    procedure Record_QueryMetadata_AppId_IsThisExtensionsOwnAppId()
    var
        QueryMetadata: Record "Query Metadata";
        ThisModule: ModuleInfo;
    begin
        // A row for a query THIS extension declares must carry this extension's app id --
        // not the empty GUID, which is what a provider that never resolves the owner reports.
        NavApp.GetCurrentModuleInfo(ThisModule);
        Assert.IsTrue(QueryMetadata.Get(ApiQuery()), 'The API query has a row.');
        Assert.AreEqual(ThisModule.Id(), QueryMetadata."App ID", 'The row carries the app id of the extension declaring the query.');
    end;
}
