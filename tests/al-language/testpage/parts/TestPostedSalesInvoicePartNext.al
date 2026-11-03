// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-next-method
// Scope: in-scope
// Fixtures used: Base Application page 132 "Posted Sales Invoice" and its part page 133
//                "Posted Sales Invoice Subform" (read-only ListPart); Assert (60021)
//
// "OKP Part Next Tests" (60229) pins that a part's first Next() after the host's GoToKey steps
// to the part's SECOND row, on an editable part. This codeunit asks the same question on a
// shipped read-only part, in the exact shape Microsoft's codeunit 135407
// "Prepayments Plan-based E2E" (VerifyPostedSalesInvoicePrepayment) uses:
//
//     PostedSalesInvoice.OpenEdit();
//     PostedSalesInvoice.GotoKey(PostedSalesInvoiceNo);
//     PostedSalesInvoice.SalesInvLines.Next();   // Microsoft expects the Item line here
//
// Here the invoice holds exactly two lines, Item (10000) then G/L Account (20000), inserted
// directly. If BC answers the Item line, page 132/133 behave differently from 60229's
// fixtures; if it answers the G/L line, the Microsoft test's posted invoice must hold another
// line ahead of the Item line on BC.
//
// Filed from AlRunner#4623.
codeunit 60233 "OKP Posted Inv Part Next Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        InvoiceNoTok: Label 'OKPNXT-0001', Locked = true;

    local procedure Initialize()
    var
        Header: Record "Sales Invoice Header";
        Line: Record "Sales Invoice Line";
    begin
        Line.SetRange("Document No.", InvoiceNoTok);
        Line.DeleteAll();
        if Header.Get(InvoiceNoTok) then
            Header.Delete();

        Header.Init();
        Header."No." := InvoiceNoTok;
        Header.Insert();

        AddLine(10000, Line.Type::Item, 'OKPNXT ITEM LINE');
        AddLine(20000, Line.Type::"G/L Account", 'OKPNXT GL LINE');
    end;

    local procedure AddLine(LineNo: Integer; LineType: Enum "Sales Line Type"; Descr: Text[100])
    var
        Line: Record "Sales Invoice Line";
    begin
        Line.Init();
        Line."Document No." := InvoiceNoTok;
        Line."Line No." := LineNo;
        Line.Type := LineType;
        Line.Description := Descr;
        Line.Insert();
    end;

    // CLAIM: before any Next(), the part reads the invoice's first line (Item).
    [Test]
    procedure AfterHostGotoKey_ReadsTheItemLineBeforeAnyNext()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize();
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoKey(InvoiceNoTok);
        Assert.AreEqual(Format(SalesInvoiceLine.Type::Item), PostedSalesInvoice.SalesInvLines.FilteredTypeField.Value(),
            'before any Next() the part must read the invoice''s first line');
        PostedSalesInvoice.Close();
    end;

    // CLAIM: the first Next() after the host's GotoKey steps to the SECOND line (G/L Account),
    // as on 60229's editable part.
    [Test]
    procedure AfterHostGotoKey_FirstNextLandsOnTheGLLine()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize();
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoKey(InvoiceNoTok);
        Assert.IsTrue(PostedSalesInvoice.SalesInvLines.Next(), 'the first Next() must answer true while a second line exists');
        Assert.AreEqual(Format(SalesInvoiceLine.Type::"G/L Account"), PostedSalesInvoice.SalesInvLines.FilteredTypeField.Value(),
            'the first Next() after the host''s GotoKey must land on the second line');
        Assert.AreEqual('OKPNXT GL LINE', PostedSalesInvoice.SalesInvLines.Description.Value(),
            'the first Next() after the host''s GotoKey must land on the second line');
        PostedSalesInvoice.Close();
    end;

    // CLAIM: on this read-only part there is no new-row line, so a second Next() answers false.
    [Test]
    procedure AfterHostGotoKey_SecondNextAnswersFalse()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize();
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoKey(InvoiceNoTok);
        PostedSalesInvoice.SalesInvLines.Next();
        Assert.IsFalse(PostedSalesInvoice.SalesInvLines.Next(), 'a second Next() on a two-line read-only part must answer false');
        PostedSalesInvoice.Close();
    end;
}
