// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-skip-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects: codeunit 95340 (log), xmlport 95341, test codeunit 95342.
// Probe: al-runner issue 6924 (Microsoft's PEPPOL 3.0 export ports). Export of a container text element right below a table element
//   that has no trigger of its own and no trigger on the container below it, whose leaves have triggers: the TaxCategory of a
//   TaxSubtotal (ID, Percent, TaxExemptionReason that skips when empty, TaxScheme > ID) below an Integer table element inside a
//   TaxTotal container, and the TaxCategory of an AllowanceCharge (Percent skips when empty) right below a table element under the
//   root. Also: an empty leaf of the inner TaxScheme, and the container's own text set by a trigger. Exported lines are trimmed and
//   joined with |. Log: agr <element> <n> = OnAfterGetRecord, <leaf>[value] = the leaf's OnBeforePassVariable.
// Facts (BC 29.0 on the corpus CI, then checked on the matrix): the container is written as any container, its leaves in schema order;
//   each leaf's OnBeforePassVariable runs before the leaf, after the row's OnAfterGetRecord; Skip there leaves out only that leaf; an
//   empty leaf of the inner TaxScheme is written as <cbc:ID />; the container's own text, set by OnAfterGetRecord, is written after its
//   last child element, before its end tag (</cac:TaxScheme>own</cac:TaxCategory>).
// Neighbours: streams/Y72XpEInvoiceShapes.al (TaxCategory of leaves only, containers with triggers),
//   xmlports/shapes-properties/Y60XpContainerSkip.al (a container two levels below a table element).
// BC versions: all (CI)

codeunit 95340 "LT R6924e Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

xmlport 95341 "LT R6924e Tax Tree"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = "" = 'urn:p:inv', cac = 'urn:p:cac', cbc = 'urn:p:cbc';

    schema
    {
        tableelement(hdr; Integer)
        {
            MaxOccurs = Once;
            SourceTableView = sorting(Number) where(Number = filter(1 ..));
            XmlName = 'Invoice';

            textelement(invid)
            {
                XmlName = 'ID';
                NamespacePrefix = 'cbc';
            }
            tableelement(charge; Integer)
            {
                XmlName = 'AllowanceCharge';
                NamespacePrefix = 'cac';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
                textelement(chargeamount)
                {
                    XmlName = 'Amount';
                    NamespacePrefix = 'cbc';
                }
                textelement(chargecat)
                {
                    XmlName = 'TaxCategory';
                    NamespacePrefix = 'cac';
                    textelement(chargecatid)
                    {
                        XmlName = 'ID';
                        NamespacePrefix = 'cbc';
                    }
                    textelement(chargepct)
                    {
                        XmlName = 'Percent';
                        NamespacePrefix = 'cbc';

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('chargepct[' + chargepct + ']');
                            if chargepct = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(chargescheme)
                    {
                        XmlName = 'TaxScheme';
                        NamespacePrefix = 'cac';
                        textelement(chargeschemeid)
                        {
                            XmlName = 'ID';
                            NamespacePrefix = 'cbc';
                        }
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr charge ' + Format(charge.Number));
                    if charge.Number > 1 then
                        currXMLport.Break();
                    chargeamount := '5';
                    chargecatid := 'S';
                    chargepct := PctText;
                    chargeschemeid := SchemeText;
                    if Mode = 4 then
                        chargecat := 'own';
                end;
            }
            textelement(taxtotal)
            {
                XmlName = 'TaxTotal';
                NamespacePrefix = 'cac';
                textelement(taxamount)
                {
                    XmlName = 'TaxAmount';
                    NamespacePrefix = 'cbc';
                }
                tableelement(subloop; Integer)
                {
                    XmlName = 'TaxSubtotal';
                    NamespacePrefix = 'cac';
                    SourceTableView = sorting(Number) where(Number = filter(1 ..));
                    textelement(taxable)
                    {
                        XmlName = 'TaxableAmount';
                        NamespacePrefix = 'cbc';
                    }
                    textelement(taxcategory)
                    {
                        XmlName = 'TaxCategory';
                        NamespacePrefix = 'cac';
                        textelement(catid)
                        {
                            XmlName = 'ID';
                            NamespacePrefix = 'cbc';
                        }
                        textelement(catpct)
                        {
                            XmlName = 'Percent';
                            NamespacePrefix = 'cbc';
                        }
                        textelement(reason)
                        {
                            XmlName = 'TaxExemptionReason';
                            NamespacePrefix = 'cbc';

                            trigger OnBeforePassVariable()
                            begin
                                Log.Add('reason[' + reason + ']');
                                if reason = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textelement(subscheme)
                        {
                            XmlName = 'TaxScheme';
                            NamespacePrefix = 'cac';
                            textelement(subschemeid)
                            {
                                XmlName = 'ID';
                                NamespacePrefix = 'cbc';
                            }
                        }
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Log.Add('agr subloop ' + Format(subloop.Number));
                        if subloop.Number > SubCount then
                            currXMLport.Break();
                        taxable := '10' + Format(subloop.Number);
                        catid := 'S' + Format(subloop.Number);
                        catpct := '25';
                        reason := '';
                        if subloop.Number = 2 then
                            reason := ReasonText;
                        subschemeid := SchemeText;
                        if Mode = 4 then
                            taxcategory := 'own';
                    end;
                }

                trigger OnBeforePassVariable()
                begin
                    Log.Add('taxtotal');
                    taxamount := '30';
                end;
            }
            textelement(after)
            {
                XmlName = 'After';
                NamespacePrefix = 'cbc';
            }

            trigger OnAfterGetRecord()
            begin
                Log.Add('agr hdr');
                after := 't';
            end;
        }
    }

    var
        Log: Codeunit "LT R6924e Log";
        Mode: Integer;
        SubCount: Integer;
        PctText: Text;
        ReasonText: Text;
        SchemeText: Text;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
        SubCount := 2;
        PctText := '21';
        ReasonText := 'exempt';
        SchemeText := 'VAT';
        case Mode of
            2:
                begin
                    SubCount := 1;
                    PctText := '';
                end;
            3:
                SchemeText := '';
        end;
    end;

    trigger OnPreXmlPort()
    begin
        invid := 'INV1';
    end;
}

codeunit 95342 "LT R6924e Tree In Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT R6924e Log";

    local procedure ReadLines(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line.Trim() + '|';
        end;
        exit(Result);
    end;

    local procedure Export(Name: Text; Mode: Integer)
    var
        XP: XmlPort "LT R6924e Tax Tree";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        ClearLastError();
        Observer.Discard();
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        XP.SetMode(Mode);
        XP.SetDestination(OutS);
        XP.Export();
        Observer.Observe(Name + ' xml', ReadLines(TempBlob));
        Observer.Observe(Name + ' log', Log.Take());
    end;

    [Test]
    procedure TreeInTable_AllFilled()
    begin
        Export('all filled', 1);
        Observer.Expect('all filled xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|<cbc:ID>INV1</cbc:ID>|<cac:AllowanceCharge>|<cbc:Amount>5</cbc:Amount>|<cac:TaxCategory>|<cbc:ID>S</cbc:ID>|<cbc:Percent>21</cbc:Percent>|<cac:TaxScheme>|<cbc:ID>VAT</cbc:ID>|</cac:TaxScheme>|</cac:TaxCategory>|</cac:AllowanceCharge>|<cac:TaxTotal>|<cbc:TaxAmount>30</cbc:TaxAmount>|<cac:TaxSubtotal>|<cbc:TaxableAmount>101</cbc:TaxableAmount>|<cac:TaxCategory>|<cbc:ID>S1</cbc:ID>|<cbc:Percent>25</cbc:Percent>|<cac:TaxScheme>|<cbc:ID>VAT</cbc:ID>|</cac:TaxScheme>|</cac:TaxCategory>|</cac:TaxSubtotal>|<cac:TaxSubtotal>|<cbc:TaxableAmount>102</cbc:TaxableAmount>|<cac:TaxCategory>|<cbc:ID>S2</cbc:ID>|<cbc:Percent>25</cbc:Percent>|<cbc:TaxExemptionReason>exempt</cbc:TaxExemptionReason>|<cac:TaxScheme>|<cbc:ID>VAT</cbc:ID>|</cac:TaxScheme>|</cac:TaxCategory>|</cac:TaxSubtotal>|</cac:TaxTotal>|<cbc:After>t</cbc:After>|</Invoice>|');
        Observer.Expect('all filled log', 'agr hdr;agr charge 1;chargepct[21];agr charge 2;taxtotal;agr subloop 1;reason[];agr subloop 2;reason[exempt];agr subloop 3;');
        Observer.Verify();
    end;

    [Test]
    procedure TreeInTable_LeavesSkipped()
    begin
        Export('leaves skipped', 2);
        Observer.Expect('leaves skipped xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|<cbc:ID>INV1</cbc:ID>|<cac:AllowanceCharge>|<cbc:Amount>5</cbc:Amount>|<cac:TaxCategory>|<cbc:ID>S</cbc:ID>|<cac:TaxScheme>|<cbc:ID>VAT</cbc:ID>|</cac:TaxScheme>|</cac:TaxCategory>|</cac:AllowanceCharge>|<cac:TaxTotal>|<cbc:TaxAmount>30</cbc:TaxAmount>|<cac:TaxSubtotal>|<cbc:TaxableAmount>101</cbc:TaxableAmount>|<cac:TaxCategory>|<cbc:ID>S1</cbc:ID>|<cbc:Percent>25</cbc:Percent>|<cac:TaxScheme>|<cbc:ID>VAT</cbc:ID>|</cac:TaxScheme>|</cac:TaxCategory>|</cac:TaxSubtotal>|</cac:TaxTotal>|<cbc:After>t</cbc:After>|</Invoice>|');
        Observer.Expect('leaves skipped log', 'agr hdr;agr charge 1;chargepct[];agr charge 2;taxtotal;agr subloop 1;reason[];agr subloop 2;');
        Observer.Verify();
    end;

    [Test]
    procedure TreeInTable_InnerLeafEmpty()
    begin
        Export('inner leaf empty', 3);
        Observer.Expect('inner leaf empty xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|<cbc:ID>INV1</cbc:ID>|<cac:AllowanceCharge>|<cbc:Amount>5</cbc:Amount>|<cac:TaxCategory>|<cbc:ID>S</cbc:ID>|<cbc:Percent>21</cbc:Percent>|<cac:TaxScheme>|<cbc:ID />|</cac:TaxScheme>|</cac:TaxCategory>|</cac:AllowanceCharge>|<cac:TaxTotal>|<cbc:TaxAmount>30</cbc:TaxAmount>|<cac:TaxSubtotal>|<cbc:TaxableAmount>101</cbc:TaxableAmount>|<cac:TaxCategory>|<cbc:ID>S1</cbc:ID>|<cbc:Percent>25</cbc:Percent>|<cac:TaxScheme>|<cbc:ID />|</cac:TaxScheme>|</cac:TaxCategory>|</cac:TaxSubtotal>|<cac:TaxSubtotal>|<cbc:TaxableAmount>102</cbc:TaxableAmount>|<cac:TaxCategory>|<cbc:ID>S2</cbc:ID>|<cbc:Percent>25</cbc:Percent>|<cbc:TaxExemptionReason>exempt</cbc:TaxExemptionReason>|<cac:TaxScheme>|<cbc:ID />|</cac:TaxScheme>|</cac:TaxCategory>|</cac:TaxSubtotal>|</cac:TaxTotal>|<cbc:After>t</cbc:After>|</Invoice>|');
        Observer.Expect('inner leaf empty log', 'agr hdr;agr charge 1;chargepct[21];agr charge 2;taxtotal;agr subloop 1;reason[];agr subloop 2;reason[exempt];agr subloop 3;');
        Observer.Verify();
    end;

    [Test]
    procedure TreeInTable_ContainerOwnText()
    begin
        Export('own text', 4);
        Observer.Expect('own text xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|<cbc:ID>INV1</cbc:ID>|<cac:AllowanceCharge>|<cbc:Amount>5</cbc:Amount>|<cac:TaxCategory>|<cbc:ID>S</cbc:ID>|<cbc:Percent>21</cbc:Percent>|<cac:TaxScheme>|<cbc:ID>VAT</cbc:ID>|</cac:TaxScheme>own</cac:TaxCategory>|</cac:AllowanceCharge>|<cac:TaxTotal>|<cbc:TaxAmount>30</cbc:TaxAmount>|<cac:TaxSubtotal>|<cbc:TaxableAmount>101</cbc:TaxableAmount>|<cac:TaxCategory>|<cbc:ID>S1</cbc:ID>|<cbc:Percent>25</cbc:Percent>|<cac:TaxScheme>|<cbc:ID>VAT</cbc:ID>|</cac:TaxScheme>own</cac:TaxCategory>|</cac:TaxSubtotal>|<cac:TaxSubtotal>|<cbc:TaxableAmount>102</cbc:TaxableAmount>|<cac:TaxCategory>|<cbc:ID>S2</cbc:ID>|<cbc:Percent>25</cbc:Percent>|<cbc:TaxExemptionReason>exempt</cbc:TaxExemptionReason>|<cac:TaxScheme>|<cbc:ID>VAT</cbc:ID>|</cac:TaxScheme>own</cac:TaxCategory>|</cac:TaxSubtotal>|</cac:TaxTotal>|<cbc:After>t</cbc:After>|</Invoice>|');
        Observer.Expect('own text log', 'agr hdr;agr charge 1;chargepct[21];agr charge 2;taxtotal;agr subloop 1;reason[];agr subloop 2;reason[exempt];agr subloop 3;');
        Observer.Verify();
    end;
}
