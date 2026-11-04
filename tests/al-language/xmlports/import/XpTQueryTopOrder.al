// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Fixtures.al (own tables 73406-73409, helper 73430, DT runner 73450), XmlPortFixtures.al, QueryFixtures.al, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Query TopNumberOfRows (object property and method) and OrderBy.
// BC versions: 29 (27 and 28 by CI)

codeunit 73514 "LT XpT Query Top Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Dump(var Q: Query "LT XpT Q Top Order"): Text
    var
        R: Text;
    begin
        while Q.Read() do
            R += StrSubstNo('%1|%2;', Q.ItemNo, Q.QtyCol);
        exit(R);
    end;
    local procedure DumpPlain(var Q: Query "LT XpT Q Items"): Text
    var
        R: Text;
    begin
        while Q.Read() do
            R += StrSubstNo('%1|%2|%3|%4|%5|%6;', Q.ItemNo, Q.ItemName, Q.QtyCol, Format(Q.AmountCol, 0, 9), Q.CategoryCol, Format(Q.ActiveCol, 0, 9));
        exit(R);
    end;

    [Test]
    procedure Top_ObjectDefault()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Top Order";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Observe('top', Format(Q.TopNumberOfRows()));
        Observer.Expect('rows', '3|30;2|20;');
        Observer.Expect('top', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Top_RuntimeOne()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Top Order";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.TopNumberOfRows(1);
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Observe('top', Format(Q.TopNumberOfRows()));
        Observer.Expect('rows', '3|30;');
        Observer.Expect('top', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Top_RuntimeMoreThanRows()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Top Order";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.TopNumberOfRows(100);
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '3|30;2|20;1|10;');
        Observer.Verify();
    end;

    [Test]
    procedure Top_RuntimeZero()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Top Order";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.TopNumberOfRows(0);
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Observe('top', Format(Q.TopNumberOfRows()));
        Observer.Expect('rows', '3|30;2|20;1|10;');
        Observer.Expect('top', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Top_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Top Order";
    begin
        Helper.Wipe();
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure Top_WithFilter()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Top Order";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetFilter(QtyCol, '<30');
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '2|20;1|10;');
        Observer.Verify();
    end;

    [Test]
    procedure Top_SetAfterOpen()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Top Order";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Q.TopNumberOfRows(1);
        Observer.Observe('err', 'no error');
        Observer.Expect('err', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Top_OnPlainQuery()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.TopNumberOfRows(2);
        Q.Open();
        Observer.Observe('rows', DumpPlain(Q));
        Observer.Observe('top', Format(Q.TopNumberOfRows()));
        Observer.Expect('rows', '1|Alpha|10|1.5|A|true;2|Beta|20|2.5|A|false;');
        Observer.Expect('top', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Top_PlainQueryDefaultValue()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Observer.Observe('top', Format(Q.TopNumberOfRows()));
        Observer.Expect('top', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Order_DescendingByObjectOrderBy()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Top Order";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.TopNumberOfRows(10);
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '3|30;2|20;1|10;');
        Observer.Verify();
    end;

    [Test]
    procedure Order_TiesKeepStableOrder()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Top Order";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a', 5, 1, true, 'A', 0D);
        Helper.AddItem(2, 'b', 5, 1, true, 'A', 0D);
        Helper.AddItem(3, 'c', 9, 1, true, 'A', 0D);
        Q.TopNumberOfRows(10);
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '3|9;1|5;2|5;');
        Observer.Verify();
    end;

    [Test]
    procedure Order_PlainQueryReturnsPrimaryKeyOrder()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.AddItem(3, 'c', 1, 1, true, 'A', 0D);
        Helper.AddItem(1, 'a', 3, 1, true, 'A', 0D);
        Helper.AddItem(2, 'b', 2, 1, true, 'A', 0D);
        Q.Open();
        Observer.Observe('rows', DumpPlain(Q));
        Observer.Expect('rows', '1|a|3|1|A|true;2|b|2|1|A|true;3|c|1|1|A|true;');
        Observer.Verify();
    end;
}
