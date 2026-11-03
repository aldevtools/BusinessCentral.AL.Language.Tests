// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-dataitemlink-property
//   dev-itpro/developer/methods-auto/query/query-data-type
// Scope: in-scope
// Fixtures used: QDTF Header (60498), QDTF Line (60499), QDTF Composite Link (60502);
//   shared Assert (60021)
//
// A query dataitem's DataItemLink property may name MORE THAN ONE field equality, separated by
// commas. Every equality constrains the join; they are not alternatives and the first is not
// privileged. TestQueryJoin.al and its siblings all use single-field links, so this pins the
// multi-field form.
//
// The fixture is built so that the two possible wrong answers are distinguishable from the
// right one and from each other. Parent key is ("No.", "Variant Code"), and two headers share
// "No." = 'H1'. One line exists, for the RED variant:
//
//   both equalities honoured  -> 1 row  (the line joins to H1/RED only)
//   only "Header No."         -> 2 rows (the line joins to H1/RED and H1/BLUE)
//   only "Variant Code"       -> 2 rows, but pairing H2/RED as well
codeunit 60504 "QDTF Multi Link Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Hdr: Record "QDTF Header";
        Ln: Record "QDTF Line";
    begin
        Hdr.DeleteAll();
        Ln.DeleteAll();
    end;

    local procedure InsertHeader(No: Code[20]; VariantCode: Code[20]; Descr: Text[50])
    var
        Hdr: Record "QDTF Header";
    begin
        Hdr.Init();
        Hdr."No." := No;
        Hdr."Variant Code" := VariantCode;
        Hdr.Descr := Descr;
        Hdr.Insert();
    end;

    local procedure InsertLine(HeaderNo: Code[20]; VariantCode: Code[20]; LineNo: Integer; Tag: Text[50])
    var
        Ln: Record "QDTF Line";
    begin
        Ln.Init();
        Ln."Header No." := HeaderNo;
        Ln."Variant Code" := VariantCode;
        Ln."Line No." := LineNo;
        Ln.Tag := Tag;
        Ln.Insert();
    end;

    [Test]
    procedure MultiFieldDataItemLinkConstrainsOnEveryEquality()
    var
        Q: Query "QDTF Composite Link";
        Seen: Integer;
        OnlyDescr: Text[50];
        OnlyTag: Text[50];
    begin
        // [SCENARIO] Two headers share "No." and differ only in "Variant Code"; one line exists,
        // for H1/RED. Both equalities of the DataItemLink must hold, so exactly one joined row
        // is produced and it names the RED header.
        Initialize();
        InsertHeader('H1', 'BLUE', 'H1-BLUE');
        InsertHeader('H1', 'RED', 'H1-RED');
        InsertLine('H1', 'RED', 10000, 'RED-LINE');

        Q.Open();
        while Q.Read() do begin
            Seen += 1;
            OnlyDescr := Q.HdrDescr;
            OnlyTag := Q.LineTag;
        end;
        Q.Close();

        Assert.AreEqual(1, Seen, 'joined rows when the link names both "Header No." and "Variant Code"');
        Assert.AreEqual('H1-RED', OnlyDescr, 'the header the line joined to');
        Assert.AreEqual('RED-LINE', OnlyTag, 'the line that joined');
    end;

    [Test]
    procedure MultiFieldDataItemLinkDropsARowMatchingOnlyTheFirstField()
    var
        Q: Query "QDTF Composite Link";
        Seen: Integer;
    begin
        // [SCENARIO] Negative direction, isolating the SECOND equality. The only line shares
        // "Header No." with the only header but not "Variant Code", so an InnerJoin honouring
        // both fields produces nothing. A join honouring only the first would return 1 row.
        Initialize();
        InsertHeader('H1', 'RED', 'H1-RED');
        InsertLine('H1', 'BLUE', 10000, 'BLUE-LINE');

        Q.Open();
        while Q.Read() do
            Seen += 1;
        Q.Close();

        Assert.AreEqual(0, Seen, 'joined rows when only the first of the two link fields matches');
    end;

    [Test]
    procedure MultiFieldDataItemLinkDropsARowMatchingOnlyTheSecondField()
    var
        Q: Query "QDTF Composite Link";
        Seen: Integer;
    begin
        // [SCENARIO] The mirror of the previous test, isolating the FIRST equality: the line
        // shares "Variant Code" with the header but not "Header No.".
        Initialize();
        InsertHeader('H1', 'RED', 'H1-RED');
        InsertLine('H2', 'RED', 10000, 'RED-LINE');

        Q.Open();
        while Q.Read() do
            Seen += 1;
        Q.Close();

        Assert.AreEqual(0, Seen, 'joined rows when only the second of the two link fields matches');
    end;

    [Test]
    procedure MultiFieldDataItemLinkJoinsEachParentToItsOwnChild()
    var
        Q: Query "QDTF Composite Link";
        Seen: Integer;
        Pairs: Text;
    begin
        // [SCENARIO] With a line for EACH of the two same-"No." headers, both join, and each
        // pairs with its own variant's line rather than the other's. A link honouring only
        // "Header No." would produce four rows here, not two.
        Initialize();
        InsertHeader('H1', 'BLUE', 'H1-BLUE');
        InsertHeader('H1', 'RED', 'H1-RED');
        InsertLine('H1', 'BLUE', 10000, 'BLUE-LINE');
        InsertLine('H1', 'RED', 10000, 'RED-LINE');

        Q.Open();
        while Q.Read() do begin
            Seen += 1;
            Pairs += Q.HdrDescr + '=' + Q.LineTag + ';';
        end;
        Q.Close();

        Assert.AreEqual(2, Seen, 'joined rows for two same-"No." headers each having one line');
        // OrderBy ascending(HdrDescr) fixes the order, so the exact pairing is assertable.
        Assert.AreEqual('H1-BLUE=BLUE-LINE;H1-RED=RED-LINE;', Pairs, 'each header paired with its own variant''s line');
    end;
}
