// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Fixtures.al (own tables 73406-73409, helper 73430, DT runner 73450), XmlPortFixtures.al, QueryFixtures.al, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Query Open / Read / Close lifecycle: reading past the end, before Open, after Close, opening twice, re-opening.
// BC versions: 29 (27 and 28 by CI)

codeunit 73510 "LT XpT Query Basic"
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
    procedure Read_AllRows()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Q.Close();
        Observer.Expect('rows', '1|Alpha|10|1.5|A|true;2|Beta|20|2.5|A|false;3|Gamma|30|3.5|B|true;');
        Observer.Verify();
    end;

    [Test]
    procedure Read_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Q.Open();
        Observer.Observe('read', Format(Q.Read()));
        Observer.Observe('read2', Format(Q.Read()));
        Observer.Expect('read', 'No');
        Observer.Expect('read2', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Read_AfterEndKeepsReturningFalse()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Observer.Observe('rows', Dump(Q));
        Observer.Observe('r1', Format(Q.Read()));
        Observer.Observe('r2', Format(Q.Read()));
        Observer.Expect('rows', '1|Alpha|10|1.5|A|true;2|Beta|20|2.5|A|false;3|Gamma|30|3.5|B|true;');
        Observer.Expect('r1', 'No');
        Observer.Expect('r2', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Read_BeforeOpen()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        asserterror Q.Read();
        Observer.ObserveError('err');
        Observer.Expect('err|text', 'You have not yet retrieved a dataset for this query. The READ function can only be called after the dataset is retrieved with a call to the OPEN function.');
        Observer.Expect('err|code', 'QueryNoDataSet');
        Observer.Verify();
    end;

    [Test]
    procedure Read_AfterClose()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Q.Close();
        asserterror Q.Read();
        Observer.ObserveError('err');
        Observer.Expect('err|text', 'You have not yet retrieved a dataset for this query. The READ function can only be called after the dataset is retrieved with a call to the OPEN function.');
        Observer.Expect('err|code', 'QueryNoDataSet');
        Observer.Verify();
    end;

    [Test]
    procedure Read_AfterCloseMidway()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Q.Read();
        Observer.Observe('id', Format(Q.ItemNo));
        Q.Close();
        asserterror Q.Read();
        Observer.ObserveError('err');
        asserterror Observer.Observe('idAfter', Format(Q.ItemNo));
        Observer.ObserveError('af147');
        Observer.Expect('id', '1');
        Observer.Expect('err|text', 'You have not yet retrieved a dataset for this query. The READ function can only be called after the dataset is retrieved with a call to the OPEN function.');
        Observer.Expect('err|code', 'QueryNoDataSet');
        Observer.Expect('af147|text', 'You have not yet retrieved a data row for this query. The value for column ''ItemNo'' can only be accessed after a row is retrieved with a call to the READ function.');
        Observer.Expect('af147|code', 'QueryNoDataSet');
        Observer.Verify();
    end;

    [Test]
    procedure Open_Twice()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Q.Open();
        Observer.Observe('err', 'no error');
        Observer.Expect('err', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Open_TwiceAfterRead()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Q.Read();
        Q.Open();
        Observer.Observe('err', 'no error');
        Observer.Observe('next', Format(Q.Read()));
        Observer.Observe('id', Format(Q.ItemNo));
        Observer.Expect('err', 'no error');
        Observer.Expect('next', 'Yes');
        Observer.Expect('id', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Close_BeforeOpen()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Q.Close();
        Observer.Observe('done', 'no error');
        Observer.Expect('done', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Close_Twice()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Q.Open();
        Q.Close();
        Q.Close();
        Observer.Observe('done', 'no error');
        Observer.Expect('done', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Reopen_RestartsFromFirstRow()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Q.Read();
        Q.Read();
        Q.Close();
        Q.Open();
        Observer.Observe('first', Format(Q.Read()));
        Observer.Observe('id', Format(Q.ItemNo));
        Observer.Expect('first', 'Yes');
        Observer.Expect('id', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Reopen_SeesNewRows()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Observer.Observe('rows1', Dump(Q));
        Q.Close();
        Helper.AddItem(4, 'Delta', 40, 4.5, true, 'B', 0D);
        Q.Open();
        Observer.Observe('rows2', Dump(Q));
        Observer.Expect('rows1', '1|Alpha|10|1.5|A|true;2|Beta|20|2.5|A|false;3|Gamma|30|3.5|B|true;');
        Observer.Expect('rows2', '1|Alpha|10|1.5|A|true;2|Beta|20|2.5|A|false;3|Gamma|30|3.5|B|true;4|Delta|40|4.5|B|true;');
        Observer.Verify();
    end;

    [Test]
    procedure Read_RowsInsertedWhileOpen()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Q.Read();
        Helper.AddItem(4, 'Delta', 40, 4.5, true, 'B', 0D);
        Observer.Observe('rest', Dump(Q));
        Observer.Expect('rest', '2|Beta|20|2.5|A|false;3|Gamma|30|3.5|B|true;4|Delta|40|4.5|B|true;');
        Observer.Verify();
    end;

    [Test]
    procedure Read_RowsDeletedWhileOpen()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
        Item: Record "LT XpT Item";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Q.Read();
        Item.Get(3);
        Item.Delete();
        Observer.Observe('rest', Dump(Q));
        Observer.Expect('rest', '2|Beta|20|2.5|A|false;');
        Observer.Verify();
    end;

    [Test]
    procedure Read_TwoInstancesIndependent()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q1: Query "LT XpT Q Items";
        Q2: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q1.Open();
        Q2.Open();
        Q1.Read();
        Q1.Read();
        Q2.Read();
        Observer.Observe('q1', Format(Q1.ItemNo));
        Observer.Observe('q2', Format(Q2.ItemNo));
        Observer.Expect('q1', '2');
        Observer.Expect('q2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Read_ColumnValuesTypes()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.AddItem(7, 'Seven', -3, -0.5, true, 'ZZ', 20240229D);
        Q.Open();
        Q.Read();
        Observer.Observe('id', Format(Q.ItemNo));
        Observer.Observe('name', Q.ItemName);
        Observer.Observe('qty', Format(Q.QtyCol));
        Observer.Observe('amt', Format(Q.AmountCol));
        Observer.Observe('cat', Q.CategoryCol);
        Observer.Observe('act', Format(Q.ActiveCol));
        Observer.Expect('id', '7');
        Observer.Expect('name', 'Seven');
        Observer.Expect('qty', '-3');
        Observer.Expect('amt', '-0.5');
        Observer.Expect('cat', 'ZZ');
        Observer.Expect('act', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Read_ClearedVariableReopens()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Q.Read();
        Clear(Q);
        Q.Open();
        Observer.Observe('first', Format(Q.Read()));
        Observer.Observe('id', Format(Q.ItemNo));
        Observer.Expect('first', 'Yes');
        Observer.Expect('id', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SecurityFiltering_Default()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
    begin
        Helper.Wipe();
        Observer.Observe('sf', Format(Q.SecurityFiltering()));
        Observer.Expect('sf', 'Filtered');
        Observer.Verify();
    end;
}
