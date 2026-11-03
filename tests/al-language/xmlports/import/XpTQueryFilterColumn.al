// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Fixtures.al (own tables 73406-73409, helper 73430, DT runner 73450), XmlPortFixtures.al, QueryFixtures.al, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Query filter() elements: a filter-only column narrows the aggregate without being selected.
// BC versions: 29 (27 and 28 by CI)

codeunit 73513 "LT XpT Query FilterColumn"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure FilterColumn_CountAll()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Count Filter";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Observer.Observe('read', Format(Q.Read()));
        Observer.Observe('cnt', Format(Q.Cnt));
        Observer.Expect('read', 'Yes');
        Observer.Expect('cnt', '3');
        Observer.Verify();
    end;

    [Test]
    procedure FilterColumn_SetFilter()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Count Filter";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetFilter(QtyFilter, '>=20');
        Q.Open();
        Observer.Observe('read', Format(Q.Read()));
        Observer.Observe('cnt', Format(Q.Cnt));
        Observer.Expect('read', 'Yes');
        Observer.Expect('cnt', '2');
        Observer.Verify();
    end;

    [Test]
    procedure FilterColumn_SetRangeNoMatch()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Count Filter";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(QtyFilter, 999);
        Q.Open();
        Observer.Observe('read', Format(Q.Read()));
        Observer.Observe('cnt', Format(Q.Cnt));
        Observer.Expect('read', 'Yes');
        Observer.Expect('cnt', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FilterColumn_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Count Filter";
    begin
        Helper.Wipe();
        Q.Open();
        Observer.Observe('read', Format(Q.Read()));
        Observer.Observe('cnt', Format(Q.Cnt));
        Observer.Expect('read', 'Yes');
        Observer.Expect('cnt', '0');
        Observer.Verify();
    end;
}
