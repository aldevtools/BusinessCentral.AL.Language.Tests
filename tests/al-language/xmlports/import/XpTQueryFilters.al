// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Fixtures.al (own tables 73406-73409, helper 73430, DT runner 73450), XmlPortFixtures.al, QueryFixtures.al, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Query.SetRange / SetFilter on columns: operators, wildcards, clearing, replacing, invalid filters, setting filters after Open.
// BC versions: 29 (27 and 28 by CI)

codeunit 73512 "LT XpT Query Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Dump(var Q: Query "LT XpT Q Items"): Text
    var
        R: Text;
    begin
        while Q.Read() do
            R += StrSubstNo('%1|%2|%3|%4|%5|%6;', Q.ItemNo, Q.ItemName, Q.QtyCol, Format(Q.AmountCol, 0, 9), Q.CategoryCol, Format(Q.ActiveCol, 0, 9));
        exit(R);
    end;

    [Test]
    procedure SetRange_Single()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(QtyCol, 20);
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '2|Beta|20|2.5|A|false;');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_FromTo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(QtyCol, 15, 30);
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '2|Beta|20|2.5|A|false;3|Gamma|30|3.5|B|true;');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_Text()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(ItemName, 'Beta');
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '2|Beta|20|2.5|A|false;');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_TextCaseInsensitive()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(ItemName, 'beta');
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_Boolean()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(ActiveCol, true);
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '1|Alpha|10|1.5|A|true;3|Gamma|30|3.5|B|true;');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(AmountCol, 2.5);
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '2|Beta|20|2.5|A|false;');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_NoArgsClears()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(QtyCol, 20);
        Q.SetRange(QtyCol);
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '1|Alpha|10|1.5|A|true;2|Beta|20|2.5|A|false;3|Gamma|30|3.5|B|true;');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_FromGreaterThanTo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(QtyCol, 30, 10);
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_ReplacesPreviousOnSameColumn()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(QtyCol, 10);
        Q.SetRange(QtyCol, 30);
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '3|Gamma|30|3.5|B|true;');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_TwoColumnsAnd()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(CategoryCol, 'A');
        Q.SetRange(QtyCol, 20, 40);
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '2|Beta|20|2.5|A|false;');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Expression()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetFilter(QtyCol, '>10&<30');
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '2|Beta|20|2.5|A|false;');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Or()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetFilter(QtyCol, '10|30');
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '1|Alpha|10|1.5|A|true;3|Gamma|30|3.5|B|true;');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Args()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetFilter(QtyCol, '<%1|>%2', 15, 25);
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '1|Alpha|10|1.5|A|true;3|Gamma|30|3.5|B|true;');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_TextWildcard()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetFilter(ItemName, '*a');
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '1|Alpha|10|1.5|A|true;2|Beta|20|2.5|A|false;3|Gamma|30|3.5|B|true;');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_TextWildcardLeading()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetFilter(ItemName, 'A*|G*');
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '1|Alpha|10|1.5|A|true;3|Gamma|30|3.5|B|true;');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_TextEqualsEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Helper.AddItem(4, '', 4, 0, true, 'A', 0D);
        Q.SetFilter(ItemName, '''''');
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '4||4|0|A|true;');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_EmptyStringClears()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetFilter(QtyCol, '>10');
        Q.SetFilter(QtyCol, '');
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '1|Alpha|10|1.5|A|true;2|Beta|20|2.5|A|false;3|Gamma|30|3.5|B|true;');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_NotEqual()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetFilter(CategoryCol, '<>A');
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '3|Gamma|30|3.5|B|true;');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Boolean()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetFilter(ActiveCol, 'No');
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '2|Beta|20|2.5|A|false;');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_NoMatches()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetFilter(QtyCol, '>1000');
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Expect('rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_AfterOpen()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Q.SetFilter(QtyCol, '>10');
        Observer.Observe('err', 'no error');
        Observer.Expect('err', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_AfterOpen()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Q.SetRange(QtyCol, 10);
        Observer.Observe('err', 'no error');
        Observer.Expect('err', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_PersistsAcrossCloseOpen()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(QtyCol, 20);
        Q.Open();
        Observer.Observe('rows1', Dump(Q));
        Q.Close();
        Q.Open();
        Observer.Observe('rows2', Dump(Q));
        Observer.Expect('rows1', '2|Beta|20|2.5|A|false;');
        Observer.Expect('rows2', '2|Beta|20|2.5|A|false;');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_ChangedBetweenOpens()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(QtyCol, 20);
        Q.Open();
        Observer.Observe('rows1', Dump(Q));
        Q.Close();
        Q.SetRange(QtyCol, 30);
        Q.Open();
        Observer.Observe('rows2', Dump(Q));
        Observer.Expect('rows1', '2|Beta|20|2.5|A|false;');
        Observer.Expect('rows2', '3|Gamma|30|3.5|B|true;');
        Observer.Verify();
    end;

}
