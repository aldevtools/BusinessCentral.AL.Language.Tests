// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70318; reads the platform table Feature Key and only through a Modify that must fail
// Probe: written against BC 29 (tag P81, GitHub issue 81); every literal asserted later is what a local BC 29 tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the exact error text and code of Modify on a read-only column of the Feature Key table (Description, Learn More Link, Mandatory By, Can Try, Is One Way, Data Update Required)
// BC versions: 29 (27 and 28 by CI)

codeunit 70318 "LT P81 Feature Key Modify"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure FeatureKey_Modify_ReadOnlyColumns()
    var
        Observer: Codeunit "Probe Observer";
        FeatureKey: Record "Feature Key";
    begin
        Observer.Observe('has_rows', Format(FeatureKey.FindFirst()));

        FeatureKey.FindFirst();
        FeatureKey.Description := 'changed by a probe';
        asserterror FeatureKey.Modify();
        Observer.ObserveError('description');

        FeatureKey.FindFirst();
        FeatureKey."Learn More Link" := 'https://example.invalid';
        asserterror FeatureKey.Modify();
        Observer.ObserveError('learn_more_link');

        FeatureKey.FindFirst();
        FeatureKey."Mandatory By" := 'changed';
        asserterror FeatureKey.Modify();
        Observer.ObserveError('mandatory_by');

        FeatureKey.FindFirst();
        FeatureKey."Can Try" := not FeatureKey."Can Try";
        asserterror FeatureKey.Modify();
        Observer.ObserveError('can_try');

        FeatureKey.FindFirst();
        FeatureKey."Is One Way" := not FeatureKey."Is One Way";
        asserterror FeatureKey.Modify();
        Observer.ObserveError('is_one_way');

        FeatureKey.FindFirst();
        FeatureKey."Data Update Required" := not FeatureKey."Data Update Required";
        asserterror FeatureKey.Modify();
        Observer.ObserveError('data_update_required');

        Observer.Expect('has_rows', 'Yes');
        Observer.Expect('description|text', 'Sorry, but the task couldn''t be completed because it tried to change the "Description" field of the feature key, which cannot be changed. Contact your administrator or application developer.');
        Observer.Expect('description|code', 'DB:Ok');
        Observer.Expect('learn_more_link|text', 'Sorry, but the task couldn''t be completed because it tried to change the "Learn more" field of the feature key, which cannot be changed. Contact your administrator or application developer.');
        Observer.Expect('learn_more_link|code', 'DB:Ok');
        Observer.Expect('mandatory_by|text', 'Sorry, but the task couldn''t be completed because it tried to change the "Approximate mandatory date" field of the feature key, which cannot be changed. Contact your administrator or application developer.');
        Observer.Expect('mandatory_by|code', 'DB:Ok');
        Observer.Expect('can_try|text', 'Sorry, but the task couldn''t be completed because it tried to change the "Get started" field of the feature key, which cannot be changed. Contact your administrator or application developer.');
        Observer.Expect('can_try|code', 'DB:Ok');
        Observer.Expect('is_one_way|text', 'Sorry, but the task couldn''t be completed because it tried to change the "Is One Way" field of the feature key, which cannot be changed. Contact your administrator or application developer.');
        Observer.Expect('is_one_way|code', 'DB:Ok');
        Observer.Expect('data_update_required|text', 'Sorry, but the task couldn''t be completed because it tried to change the "Data Update Required" field of the feature key, which cannot be changed. Contact your administrator or application developer.');
        Observer.Expect('data_update_required|code', 'DB:Ok');
        Observer.Verify();
    end;
}
