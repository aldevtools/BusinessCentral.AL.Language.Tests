// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Fixtures.al (own tables 73406-73409, helper 73430, DT runner 73450), XmlPortFixtures.al, QueryFixtures.al, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Query DataItemLink joins (inner, left outer), filters on joined columns, DataItemTableFilter and ColumnFilter.
// BC versions: 29 (27 and 28 by CI)

codeunit 73515 "LT XpT Query Joins"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure DumpIn(var Q: Query "LT XpT Q Inner"): Text
    var
        R: Text;
    begin
        while Q.Read() do
            R += StrSubstNo('%1|%2|%3|%4|%5;', Q.ItemNo, Q.ItemName, Q.LineId, Q.Descr, Q.LineQty);
        exit(R);
    end;

    local procedure DumpLeft(var Q: Query "LT XpT Q Left"): Text
    var
        R: Text;
    begin
        while Q.Read() do
            R += StrSubstNo('%1|%2|%3|%4|%5;', Q.ItemNo, Q.ItemName, Q.LineId, Q.Descr, Q.LineQty);
        exit(R);
    end;

    local procedure DumpCF(var Q: Query "LT XpT Q ColFilter"): Text
    var
        R: Text;
    begin
        while Q.Read() do
            R += StrSubstNo('%1|%2;', Q.ItemNo, Q.QtyCol);
        exit(R);
    end;

    [Test]
    procedure Inner_Seeded()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Inner";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Observer.Observe('rows', DumpIn(Q));
        Observer.Expect('rows', '1|Alpha|1|L1a|1;1|Alpha|2|L1b|2;2|Beta|3|L2a|5;');
        Observer.Verify();
    end;

    [Test]
    procedure Inner_NoLines()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Inner";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a', 1, 1, true, 'A', 0D);
        Q.Open();
        Observer.Observe('rows', DumpIn(Q));
        Observer.Expect('rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure Inner_NoItemsOrphanLine()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Inner";
    begin
        Helper.Wipe();
        Helper.AddLine(1, 77, 'orphan', 1);
        Q.Open();
        Observer.Observe('rows', DumpIn(Q));
        Observer.Expect('rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure Inner_FilterOnJoinedColumn()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Inner";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(LineQty, 2, 5);
        Q.Open();
        Observer.Observe('rows', DumpIn(Q));
        Observer.Expect('rows', '1|Alpha|2|L1b|2;2|Beta|3|L2a|5;');
        Observer.Verify();
    end;

    [Test]
    procedure Inner_FilterOnParentColumn()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Inner";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(ItemNo, 2);
        Q.Open();
        Observer.Observe('rows', DumpIn(Q));
        Observer.Expect('rows', '2|Beta|3|L2a|5;');
        Observer.Verify();
    end;

    [Test]
    procedure Left_Seeded()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Left";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Observer.Observe('rows', DumpLeft(Q));
        Observer.Expect('rows', '1|Alpha|1|L1a|1;1|Alpha|2|L1b|2;2|Beta|3|L2a|5;3|Gamma|0||0;');
        Observer.Verify();
    end;

    [Test]
    procedure Left_NoLines()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Left";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a', 1, 1, true, 'A', 0D);
        Q.Open();
        Observer.Observe('rows', DumpLeft(Q));
        Observer.Expect('rows', '1|a|0||0;');
        Observer.Verify();
    end;

    [Test]
    procedure Left_EmptyTables()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Left";
    begin
        Helper.Wipe();
        Q.Open();
        Observer.Observe('rows', DumpLeft(Q));
        Observer.Expect('rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure Left_NoItemsOrphanLine()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Left";
    begin
        Helper.Wipe();
        Helper.AddLine(1, 77, 'orphan', 1);
        Q.Open();
        Observer.Observe('rows', DumpLeft(Q));
        Observer.Expect('rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure Left_FilterOnJoinedColumn()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Left";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(LineQty, 2, 5);
        Q.Open();
        Observer.Observe('rows', DumpLeft(Q));
        Observer.Expect('rows', '1|Alpha|2|L1b|2;2|Beta|3|L2a|5;');
        Observer.Verify();
    end;

    [Test]
    procedure Left_FilterJoinedColumnEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Left";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetFilter(Descr, '''''');
        Q.Open();
        Observer.Observe('rows', DumpLeft(Q));
        Observer.Expect('rows', '3|Gamma|0||0;');
        Observer.Verify();
    end;

    [Test]
    procedure Left_FilterOnParentColumn()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Left";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(ItemNo, 3);
        Q.Open();
        Observer.Observe('rows', DumpLeft(Q));
        Observer.Expect('rows', '3|Gamma|0||0;');
        Observer.Verify();
    end;

    [Test]
    procedure Left_ColumnValuesOfUnmatchedRow()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Left";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a', 1, 1, true, 'A', 0D);
        Q.Open();
        Q.Read();
        Observer.Observe('lineId', Format(Q.LineId));
        Observer.Observe('descr', Q.Descr);
        Observer.Observe('qty', Format(Q.LineQty));
        Observer.Expect('lineId', '0');
        Observer.Expect('descr', '');
        Observer.Expect('qty', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ColumnFilter_ActiveAndQtyAtLeast20()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q ColFilter";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.Open();
        Observer.Observe('rows', DumpCF(Q));
        Observer.Expect('rows', '3|30;');
        Observer.Verify();
    end;

    [Test]
    procedure ColumnFilter_ExtraSetFilterNarrows()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q ColFilter";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetFilter(QtyCol, '<30');
        Q.Open();
        Observer.Observe('rows', DumpCF(Q));
        Observer.Expect('rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure ColumnFilter_ExtraSetFilterWiderDoesNotWiden()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q ColFilter";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetFilter(QtyCol, '>0');
        Q.Open();
        Observer.Observe('rows', DumpCF(Q));
        Observer.Expect('rows', '3|30;');
        Observer.Verify();
    end;

    [Test]
    procedure ColumnFilter_SetRangeClearedReveals()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q ColFilter";
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(QtyCol);
        Q.Open();
        Observer.Observe('rows', DumpCF(Q));
        Observer.Expect('rows', '3|30;');
        Observer.Verify();
    end;
}
