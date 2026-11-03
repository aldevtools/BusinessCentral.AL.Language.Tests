// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-skip-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 93240 (Y61Log.al) where logs are read; own objects: table 93866; codeunit 93860,93861; xmlport 93850,93851,93852
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: XmlPort export shapes of e-invoice ports (namespaces with the empty default prefix and two prefixes, a root table element over
//   Integer with MaxOccurs = Once). Family A: a text element with a value and a text attribute whose OnBeforePassVariable skips when
//   empty, two or three container levels below the table element (EndpointID, ID, CompanyID with an attribute that has its own
//   trigger, a delivery location ID); also with the root table element over a real table and one or two rows. Family B: a container text
//   element directly below a table element that holds leaves, containers with triggers AND an inner Integer table element, with an
//   OnBeforePassVariable that fills the leaves of the container (TaxTotal > TaxSubtotal, InvoiceLine > Item with inner table elements,
//   InvoiceLine > Price): the trigger order of the container against the inner table element's OnPreXmlItem and OnAfterGetRecord, Break and
//   Skip in the inner table element, Skip of the container, an inner table element that yields no row. Line breaks of the exported text
//   are shown as |. Log: <element> = OnBeforePassVariable, pre <element> = OnPreXmlItem, agr <element> <n> = OnAfterGetRecord.
// Neighbours: xmlport/lt-y60-xmlport-container-skip/Y60XpContainerSkip.al, xmlport/lt-y60-xmlport-text-in-table/Y60XpTextInTable.al,
//   xmlport/lt-y17-xmlport-ns/Y17XmlPortNamespacesTests.al:60, xmlport/W7XmlPortTests.al:25-90.
// Measured (27.5, 28.5, 29.0 and SaaS 29 alike): see the Expect lines. Family A: an attributed leaf below containers in a table element
//   writes its element, with the attribute only when the attribute trigger does not skip; a Skip in the element trigger leaves out the
//   element with its attribute (the attribute trigger does not run); a container whose children are all skipped is written empty
//   (<cac:PartyLegalEntity> keeps a blank RegistrationName). On a real table root the triggers run once per row and a Skip in row 1
//   does not affect row 2. Family B: the container's OnBeforePassVariable runs before the inner table element's OnPreXmlItem, which runs
//   once; the inner OnAfterGetRecord runs for every row and for the row where Break is called; Break leaves out that row and ends the
//   inner element, Skip leaves out only that row (rows 1 and 3 written); the sibling after the container follows in both cases. With no
//   inner row the container is still written with its leaves. A Skip in the container's trigger leaves out the container and its inner table
//   elements do not run (no OnPreXmlItem, no OnAfterGetRecord); the next sibling is written.
// BC versions: all (CI)

table 93866 "LT Y72 XP Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 93860 "LT Y72 XP Log"
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

// Family A over an Integer root element.
xmlport 93850 "LT Y72 XP FamA"
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
            textelement(supplier)
            {
                XmlName = 'AccountingSupplierParty';
                NamespacePrefix = 'cac';
                textelement(party)
                {
                    XmlName = 'Party';
                    NamespacePrefix = 'cac';
                    textelement(endpointid)
                    {
                        XmlName = 'EndpointID';
                        NamespacePrefix = 'cbc';
                        textattribute(schemeid)
                        {
                            XmlName = 'schemeID';
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('endpoint[' + EndpointId + ',' + SchemeId + ']');
                            if EndpointId = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(partyident)
                    {
                        XmlName = 'PartyIdentification';
                        NamespacePrefix = 'cac';
                        textelement(partyidentid)
                        {
                            XmlName = 'ID';
                            NamespacePrefix = 'cbc';
                            textattribute(pidscheme)
                            {
                                XmlName = 'schemeID';
                            }
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('partyident');
                            if PartyIdentId = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(legal)
                    {
                        XmlName = 'PartyLegalEntity';
                        NamespacePrefix = 'cac';
                        textelement(regname)
                        {
                            XmlName = 'RegistrationName';
                            NamespacePrefix = 'cbc';
                        }
                        textelement(companyid)
                        {
                            XmlName = 'CompanyID';
                            NamespacePrefix = 'cbc';
                            textattribute(cidscheme)
                            {
                                XmlName = 'schemeID';

                                trigger OnBeforePassVariable()
                                begin
                                    Log.Add('cidscheme[' + CidScheme + ']');
                                    if CidScheme = '' then
                                        currXMLport.Skip();
                                end;
                            }

                            trigger OnBeforePassVariable()
                            begin
                                Log.Add('companyid[' + CompanyId + ']');
                                if CompanyId = '' then
                                    currXMLport.Skip();
                            end;
                        }
                    }
                }
            }
            textelement(delivery)
            {
                XmlName = 'Delivery';
                NamespacePrefix = 'cac';
                textelement(actualdate)
                {
                    XmlName = 'ActualDeliveryDate';
                    NamespacePrefix = 'cbc';

                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('actualdate[' + ActualDate + ']');
                        if ActualDate = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(deliveryloc)
                {
                    XmlName = 'DeliveryLocation';
                    NamespacePrefix = 'cac';
                    textelement(deliveryid)
                    {
                        XmlName = 'ID';
                        NamespacePrefix = 'cbc';
                        textattribute(dscheme)
                        {
                            XmlName = 'schemeID';
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('deliveryid[' + DeliveryId + ',' + DScheme + ']');
                            if DeliveryId = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(address)
                    {
                        XmlName = 'Address';
                        NamespacePrefix = 'cac';
                        textelement(street)
                        {
                            XmlName = 'StreetName';
                            NamespacePrefix = 'cbc';
                        }
                    }
                }
            }
            textelement(tail)
            {
                XmlName = 'After';
                NamespacePrefix = 'cbc';
            }

            trigger OnAfterGetRecord()
            begin
                Log.Add('agr hdr');
            end;
        }
    }

    var
        Log: Codeunit "LT Y72 XP Log";
        Mode: Integer;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    // 1 all filled, 2 EndpointID empty, 3 party identification empty, 4 CompanyID set and its attribute empty, 5 CompanyID empty and
    // its attribute set, 6 delivery date and delivery id empty, 7 everything inside Party empty
    trigger OnPreXmlPort()
    begin
        invid := 'INV1';
        EndpointId := 'EP1';
        SchemeId := '0088';
        PartyIdentId := 'PI1';
        PidScheme := 'PS';
        regname := 'Reg Name';
        CompanyId := 'CO1';
        CidScheme := 'CS';
        ActualDate := '2024-01-02';
        DeliveryId := 'DL1';
        DScheme := 'DS';
        street := 'Main St';
        tail := 't';
        case Mode of
            2:
                EndpointId := '';
            3:
                PartyIdentId := '';
            4:
                CidScheme := '';
            5:
                CompanyId := '';
            6:
                begin
                    ActualDate := '';
                    DeliveryId := '';
                end;
            7:
                begin
                    EndpointId := '';
                    PartyIdentId := '';
                    regname := '';
                    CompanyId := '';
                    CidScheme := '';
                end;
        end;
    end;
}

// Family A over a real table root element (more than one row).
xmlport 93851 "LT Y72 XP FamA Table"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = "" = 'urn:p:inv', cac = 'urn:p:cac', cbc = 'urn:p:cbc';

    schema
    {
        tableelement(hdr; "LT Y72 XP Src")
        {
            XmlName = 'Invoice';

            textelement(invid)
            {
                XmlName = 'ID';
                NamespacePrefix = 'cbc';
            }
            textelement(supplier)
            {
                XmlName = 'AccountingSupplierParty';
                NamespacePrefix = 'cac';
                textelement(party)
                {
                    XmlName = 'Party';
                    NamespacePrefix = 'cac';
                    textelement(endpointid)
                    {
                        XmlName = 'EndpointID';
                        NamespacePrefix = 'cbc';
                        textattribute(schemeid)
                        {
                            XmlName = 'schemeID';
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('endpoint[' + EndpointId + ']');
                            if EndpointId = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(legal)
                    {
                        XmlName = 'PartyLegalEntity';
                        NamespacePrefix = 'cac';
                        textelement(companyid)
                        {
                            XmlName = 'CompanyID';
                            NamespacePrefix = 'cbc';
                            textattribute(cidscheme)
                            {
                                XmlName = 'schemeID';

                                trigger OnBeforePassVariable()
                                begin
                                    Log.Add('cidscheme[' + CidScheme + ']');
                                    if CidScheme = '' then
                                        currXMLport.Skip();
                                end;
                            }

                            trigger OnBeforePassVariable()
                            begin
                                Log.Add('companyid[' + CompanyId + ']');
                                if CompanyId = '' then
                                    currXMLport.Skip();
                            end;
                        }
                    }
                }
            }

            trigger OnAfterGetRecord()
            begin
                Log.Add('agr ' + Format(hdr.Id));
                invid := 'INV' + Format(hdr.Id);
                SchemeId := '0088';
                EndpointId := 'EP' + Format(hdr.Id);
                CompanyId := 'CO' + Format(hdr.Id);
                CidScheme := 'CS' + Format(hdr.Id);
                if hdr.Id = 1 then begin
                    EndpointId := '';
                    CidScheme := '';
                end;
            end;
        }
    }

    var
        Log: Codeunit "LT Y72 XP Log";
}

// Family B.
xmlport 93852 "LT Y72 XP FamB"
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
            textelement(taxtotal)
            {
                XmlName = 'TaxTotal';
                NamespacePrefix = 'cac';
                textelement(taxamount)
                {
                    XmlName = 'TaxAmount';
                    NamespacePrefix = 'cbc';
                    textattribute(taxcur)
                    {
                        XmlName = 'currencyID';
                    }
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
                        textattribute(subcur)
                        {
                            XmlName = 'currencyID';
                        }
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
                        textelement(reason)
                        {
                            XmlName = 'TaxExemptionReason';
                            NamespacePrefix = 'cbc';

                            trigger OnBeforePassVariable()
                            begin
                                if reason = '' then
                                    currXMLport.Skip();
                            end;
                        }
                    }

                    trigger OnPreXmlItem()
                    begin
                        Log.Add('pre subloop');
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        Log.Add('agr subloop ' + Format(subloop.Number));
                        if subloop.Number > SubCount then
                            currXMLport.Break();
                        if subloop.Number = BreakAt then
                            currXMLport.Break();
                        if subloop.Number = SkipAt then
                            currXMLport.Skip();
                        taxable := '10' + Format(subloop.Number);
                        subcur := 'EUR';
                        catid := 'S' + Format(subloop.Number);
                        reason := ReasonText;
                    end;
                }

                trigger OnBeforePassVariable()
                begin
                    Log.Add('taxtotal');
                    taxamount := TaxText;
                    taxcur := 'EUR';
                end;
            }
            textelement(taxtotallcy)
            {
                XmlName = 'TaxTotal';
                NamespacePrefix = 'cac';
                textelement(lcyamount)
                {
                    XmlName = 'TaxAmount';
                    NamespacePrefix = 'cbc';
                }

                trigger OnBeforePassVariable()
                begin
                    Log.Add('taxtotallcy');
                    lcyamount := LcyText;
                    if lcyamount = '' then
                        currXMLport.Skip();
                end;
            }
            tableelement(line; Integer)
            {
                XmlName = 'InvoiceLine';
                NamespacePrefix = 'cac';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
                textelement(lineid)
                {
                    XmlName = 'ID';
                    NamespacePrefix = 'cbc';
                }
                textelement(item)
                {
                    XmlName = 'Item';
                    NamespacePrefix = 'cac';
                    textelement(descr)
                    {
                        XmlName = 'Description';
                        NamespacePrefix = 'cbc';

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('descr[' + descr + ']');
                            if descr = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(itemname)
                    {
                        XmlName = 'Name';
                        NamespacePrefix = 'cbc';
                    }
                    textelement(sellers)
                    {
                        XmlName = 'SellersItemIdentification';
                        NamespacePrefix = 'cac';
                        textelement(sid)
                        {
                            XmlName = 'ID';
                            NamespacePrefix = 'cbc';
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('sellers[' + sid + ']');
                            if sid = '' then
                                currXMLport.Skip();
                        end;
                    }
                    tableelement(commodity; Integer)
                    {
                        XmlName = 'CommodityClassification';
                        NamespacePrefix = 'cac';
                        SourceTableView = sorting(Number) where(Number = filter(1 ..));
                        textelement(commcode)
                        {
                            XmlName = 'ItemClassificationCode';
                            NamespacePrefix = 'cbc';
                            textattribute(listid)
                            {
                                XmlName = 'listID';
                            }

                            trigger OnBeforePassVariable()
                            begin
                                if commcode = '' then
                                    currXMLport.Skip();
                            end;
                        }

                        trigger OnPreXmlItem()
                        begin
                            commodity.SetRange(Number, 1, 1);
                            Log.Add('pre commodity');
                        end;

                        trigger OnAfterGetRecord()
                        begin
                            Log.Add('agr commodity [' + CommodityValue + ']');
                            commcode := CommodityValue;
                            listid := 'STI';
                            if commcode = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(taxcat)
                    {
                        XmlName = 'ClassifiedTaxCategory';
                        NamespacePrefix = 'cac';
                        textelement(ctid)
                        {
                            XmlName = 'ID';
                            NamespacePrefix = 'cbc';
                        }
                        textelement(pct)
                        {
                            XmlName = 'Percent';
                            NamespacePrefix = 'cbc';

                            trigger OnBeforePassVariable()
                            begin
                                if pct = '' then
                                    currXMLport.Skip();
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('taxcat');
                            ctid := 'S';
                            pct := PctValue;
                        end;
                    }
                    tableelement(prop; Integer)
                    {
                        XmlName = 'AdditionalItemProperty';
                        NamespacePrefix = 'cac';
                        SourceTableView = sorting(Number) where(Number = filter(1 ..));
                        textelement(pname)
                        {
                            XmlName = 'Name';
                            NamespacePrefix = 'cbc';
                        }

                        trigger OnPreXmlItem()
                        begin
                            prop.SetRange(Number, 1, 1);
                            Log.Add('pre prop');
                        end;

                        trigger OnAfterGetRecord()
                        begin
                            Log.Add('agr prop [' + PropValue + ']');
                            pname := PropValue;
                            if pname = '' then
                                currXMLport.Skip();
                        end;
                    }

                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('item line ' + Format(line.Number));
                        descr := DescrValue;
                        itemname := 'name' + Format(line.Number);
                        sid := SidValue;
                        if ItemSkip then
                            currXMLport.Skip();
                    end;
                }
                textelement(price)
                {
                    XmlName = 'Price';
                    NamespacePrefix = 'cac';
                    textelement(priceamount)
                    {
                        XmlName = 'PriceAmount';
                        NamespacePrefix = 'cbc';
                        textattribute(pcur)
                        {
                            XmlName = 'currencyID';
                        }
                    }
                    tableelement(charge; Integer)
                    {
                        XmlName = 'AllowanceCharge';
                        NamespacePrefix = 'cac';
                        SourceTableView = sorting(Number) where(Number = filter(1 ..));
                        textelement(indicator)
                        {
                            XmlName = 'ChargeIndicator';
                            NamespacePrefix = 'cbc';
                        }

                        trigger OnPreXmlItem()
                        begin
                            charge.SetRange(Number, 1, 1);
                            Log.Add('pre charge');
                        end;

                        trigger OnAfterGetRecord()
                        begin
                            Log.Add('agr charge [' + IndicatorValue + ']');
                            indicator := IndicatorValue;
                            if indicator = '' then
                                currXMLport.Skip();
                        end;
                    }

                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('price line ' + Format(line.Number));
                        priceamount := '5.0' + Format(line.Number);
                        pcur := 'EUR';
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('agr line ' + Format(line.Number));
                    if line.Number > LineCount then
                        currXMLport.Break();
                    lineid := Format(line.Number);
                    DescrValue := 'item ' + Format(line.Number);
                    SidValue := 'SID' + Format(line.Number);
                    CommodityValue := 'C' + Format(line.Number);
                    PropValue := 'prop' + Format(line.Number);
                    IndicatorValue := 'false';
                    PctValue := '25';
                    if EmptySecond and (line.Number = 2) then begin
                        DescrValue := '';
                        CommodityValue := '';
                        PropValue := '';
                        IndicatorValue := '';
                    end;
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y72 XP Log";
        SubCount: Integer;
        BreakAt: Integer;
        SkipAt: Integer;
        TaxText: Text;
        ReasonText: Text;
        LcyText: Text;
        LineCount: Integer;
        EmptySecond: Boolean;
        ItemSkip: Boolean;
        DescrValue: Text;
        SidValue: Text;
        CommodityValue: Text;
        PropValue: Text;
        IndicatorValue: Text;
        PctValue: Text;

    procedure SetTax(NewSubCount: Integer; NewTaxText: Text; NewLcyText: Text; NewReasonText: Text)
    begin
        SubCount := NewSubCount;
        TaxText := NewTaxText;
        LcyText := NewLcyText;
        ReasonText := NewReasonText;
    end;

    procedure SetSubStops(NewBreakAt: Integer; NewSkipAt: Integer)
    begin
        BreakAt := NewBreakAt;
        SkipAt := NewSkipAt;
    end;

    procedure SetLines(NewLineCount: Integer; NewEmptySecond: Boolean; NewItemSkip: Boolean)
    begin
        LineCount := NewLineCount;
        EmptySecond := NewEmptySecond;
        ItemSkip := NewItemSkip;
    end;

    trigger OnPreXmlPort()
    begin
        invid := 'INV1';
    end;
}

codeunit 93861 "LT Y72 XP EInvoice Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y72 XP Log";

    local procedure ReadLines(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure Start()
    begin
        ClearLastError();
        Observer.Discard();
        Log.Take();
    end;

    local procedure ExportA(Name: Text; Mode: Integer)
    var
        XP: XmlPort "LT Y72 XP FamA";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        XP.SetMode(Mode);
        XP.SetDestination(OutS);
        XP.Export();
        Observer.Observe(Name + ' xml', ReadLines(TempBlob));
        Observer.Observe(Name + ' log', Log.Take());
    end;

    local procedure ExportATable(Name: Text; Rows: Integer)
    var
        Src: Record "LT Y72 XP Src";
        XP: XmlPort "LT Y72 XP FamA Table";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        i: Integer;
    begin
        Log.Take();
        Src.DeleteAll();
        for i := 1 to Rows do begin
            Src.Id := i;
            Src.Name := 'row' + Format(i);
            Src.Insert();
        end;
        TempBlob.CreateOutStream(OutS);
        XP.SetDestination(OutS);
        XP.Export();
        Observer.Observe(Name + ' xml', ReadLines(TempBlob));
        Observer.Observe(Name + ' log', Log.Take());
    end;

    local procedure ExportB(Name: Text; SubCount: Integer; TaxText: Text; LcyText: Text; ReasonText: Text; BreakAt: Integer; SkipAt: Integer; LineCount: Integer; EmptySecond: Boolean; ItemSkip: Boolean)
    var
        XP: XmlPort "LT Y72 XP FamB";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        XP.SetTax(SubCount, TaxText, LcyText, ReasonText);
        XP.SetSubStops(BreakAt, SkipAt);
        XP.SetLines(LineCount, EmptySecond, ItemSkip);
        XP.SetDestination(OutS);
        XP.Export();
        Observer.Observe(Name + ' xml', ReadLines(TempBlob));
        Observer.Observe(Name + ' log', Log.Take());
    end;

    [Test]
    procedure DeepAttrLeaf_AllFilled()
    begin
        Start();
        ExportA('all filled', 1);
        Observer.Expect('all filled xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:AccountingSupplierParty>|    <cac:Party>|      <cbc:EndpointID schemeID="0088">EP1</cbc:EndpointID>|      <cac:PartyIdentification>|        <cbc:ID schemeID="PS">PI1</cbc:ID>|      </cac:PartyIdentification>|      <cac:PartyLegalEntity>|        <cbc:RegistrationName>Reg Name</cbc:RegistrationName>|        <cbc:CompanyID schemeID="CS">CO1</cbc:CompanyID>|      </cac:PartyLegalEntity>|    </cac:Party>|  </cac:AccountingSupplierParty>|  <cac:Delivery>|    <cbc:ActualDeliveryDate>2024-01-02</cbc:ActualDeliveryDate>|    <cac:DeliveryLocation>|      <cbc:ID schemeID="DS">DL1</cbc:ID>|      <cac:Address>|        <cbc:StreetName>Main St</cbc:StreetName>|      </cac:Address>|    </cac:DeliveryLocation>|  </cac:Delivery>|  <cbc:After>t</cbc:After>|</Invoice>|');
        Observer.Expect('all filled log', 'agr hdr;endpoint[EP1,0088];partyident;companyid[CO1];cidscheme[CS];actualdate[2024-01-02];deliveryid[DL1,DS];');
        Observer.Verify();
    end;




    [Test]
    procedure DeepAttrLeaf_SkipVariants_EndpointIdentLegal()
    begin
        Start();
        ExportA('a endpoint empty', 2);
        ExportA('b party identification empty', 3);
        ExportA('c company id set, attribute empty', 4);
        Observer.Expect('a endpoint empty xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:AccountingSupplierParty>|    <cac:Party>|      <cac:PartyIdentification>|        <cbc:ID schemeID="PS">PI1</cbc:ID>|      </cac:PartyIdentification>|      <cac:PartyLegalEntity>|        <cbc:RegistrationName>Reg Name</cbc:RegistrationName>|        <cbc:CompanyID schemeID="CS">CO1</cbc:CompanyID>|      </cac:PartyLegalEntity>|    </cac:Party>|  </cac:AccountingSupplierParty>|  <cac:Delivery>|    <cbc:ActualDeliveryDate>2024-01-02</cbc:ActualDeliveryDate>|    <cac:DeliveryLocation>|      <cbc:ID schemeID="DS">DL1</cbc:ID>|      <cac:Address>|        <cbc:StreetName>Main St</cbc:StreetName>|      </cac:Address>|    </cac:DeliveryLocation>|  </cac:Delivery>|  <cbc:After>t</cbc:After>|</Invoice>|');
        Observer.Expect('a endpoint empty log', 'agr hdr;endpoint[,0088];partyident;companyid[CO1];cidscheme[CS];actualdate[2024-01-02];deliveryid[DL1,DS];');
        Observer.Expect('b party identification empty xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:AccountingSupplierParty>|    <cac:Party>|      <cbc:EndpointID schemeID="0088">EP1</cbc:EndpointID>|      <cac:PartyLegalEntity>|        <cbc:RegistrationName>Reg Name</cbc:RegistrationName>|        <cbc:CompanyID schemeID="CS">CO1</cbc:CompanyID>|      </cac:PartyLegalEntity>|    </cac:Party>|  </cac:AccountingSupplierParty>|  <cac:Delivery>|    <cbc:ActualDeliveryDate>2024-01-02</cbc:ActualDeliveryDate>|    <cac:DeliveryLocation>|      <cbc:ID schemeID="DS">DL1</cbc:ID>|      <cac:Address>|        <cbc:StreetName>Main St</cbc:StreetName>|      </cac:Address>|    </cac:DeliveryLocation>|  </cac:Delivery>|  <cbc:After>t</cbc:After>|</Invoice>|');
        Observer.Expect('b party identification empty log', 'agr hdr;endpoint[EP1,0088];partyident;companyid[CO1];cidscheme[CS];actualdate[2024-01-02];deliveryid[DL1,DS];');
        Observer.Expect('c company id set, attribute empty xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:AccountingSupplierParty>|    <cac:Party>|      <cbc:EndpointID schemeID="0088">EP1</cbc:EndpointID>|      <cac:PartyIdentification>|        <cbc:ID schemeID="PS">PI1</cbc:ID>|      </cac:PartyIdentification>|      <cac:PartyLegalEntity>|        <cbc:RegistrationName>Reg Name</cbc:RegistrationName>|        <cbc:CompanyID>CO1</cbc:CompanyID>|      </cac:PartyLegalEntity>|    </cac:Party>|  </cac:AccountingSupplierParty>|  <cac:Delivery>|    <cbc:ActualDeliveryDate>2024-01-02</cbc:ActualDeliveryDate>|    <cac:DeliveryLocation>|      <cbc:ID schemeID="DS">DL1</cbc:ID>|      <cac:Address>|        <cbc:StreetName>Main St</cbc:StreetName>|      </cac:Address>|    </cac:DeliveryLocation>|  </cac:Delivery>|  <cbc:After>t</cbc:After>|</Invoice>|');
        Observer.Expect('c company id set, attribute empty log', 'agr hdr;endpoint[EP1,0088];partyident;companyid[CO1];cidscheme[];actualdate[2024-01-02];deliveryid[DL1,DS];');
        Observer.Verify();
    end;




    [Test]
    procedure DeepAttrLeaf_SkipVariants_CompanyDeliveryParty()
    begin
        Start();
        ExportA('d company id empty, attribute set', 5);
        ExportA('e delivery date and id empty', 6);
        ExportA('f everything in party empty', 7);
        Observer.Expect('d company id empty, attribute set xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:AccountingSupplierParty>|    <cac:Party>|      <cbc:EndpointID schemeID="0088">EP1</cbc:EndpointID>|      <cac:PartyIdentification>|        <cbc:ID schemeID="PS">PI1</cbc:ID>|      </cac:PartyIdentification>|      <cac:PartyLegalEntity>|        <cbc:RegistrationName>Reg Name</cbc:RegistrationName>|      </cac:PartyLegalEntity>|    </cac:Party>|  </cac:AccountingSupplierParty>|  <cac:Delivery>|    <cbc:ActualDeliveryDate>2024-01-02</cbc:ActualDeliveryDate>|    <cac:DeliveryLocation>|      <cbc:ID schemeID="DS">DL1</cbc:ID>|      <cac:Address>|        <cbc:StreetName>Main St</cbc:StreetName>|      </cac:Address>|    </cac:DeliveryLocation>|  </cac:Delivery>|  <cbc:After>t</cbc:After>|</Invoice>|');
        Observer.Expect('d company id empty, attribute set log', 'agr hdr;endpoint[EP1,0088];partyident;companyid[];actualdate[2024-01-02];deliveryid[DL1,DS];');
        Observer.Expect('e delivery date and id empty xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:AccountingSupplierParty>|    <cac:Party>|      <cbc:EndpointID schemeID="0088">EP1</cbc:EndpointID>|      <cac:PartyIdentification>|        <cbc:ID schemeID="PS">PI1</cbc:ID>|      </cac:PartyIdentification>|      <cac:PartyLegalEntity>|        <cbc:RegistrationName>Reg Name</cbc:RegistrationName>|        <cbc:CompanyID schemeID="CS">CO1</cbc:CompanyID>|      </cac:PartyLegalEntity>|    </cac:Party>|  </cac:AccountingSupplierParty>|  <cac:Delivery>|    <cac:DeliveryLocation>|      <cac:Address>|        <cbc:StreetName>Main St</cbc:StreetName>|      </cac:Address>|    </cac:DeliveryLocation>|  </cac:Delivery>|  <cbc:After>t</cbc:After>|</Invoice>|');
        Observer.Expect('e delivery date and id empty log', 'agr hdr;endpoint[EP1,0088];partyident;companyid[CO1];cidscheme[CS];actualdate[];deliveryid[,DS];');
        Observer.Expect('f everything in party empty xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:AccountingSupplierParty>|    <cac:Party>|      <cac:PartyLegalEntity>|        <cbc:RegistrationName />|      </cac:PartyLegalEntity>|    </cac:Party>|  </cac:AccountingSupplierParty>|  <cac:Delivery>|    <cbc:ActualDeliveryDate>2024-01-02</cbc:ActualDeliveryDate>|    <cac:DeliveryLocation>|      <cbc:ID schemeID="DS">DL1</cbc:ID>|      <cac:Address>|        <cbc:StreetName>Main St</cbc:StreetName>|      </cac:Address>|    </cac:DeliveryLocation>|  </cac:Delivery>|  <cbc:After>t</cbc:After>|</Invoice>|');
        Observer.Expect('f everything in party empty log', 'agr hdr;endpoint[,0088];partyident;companyid[];actualdate[2024-01-02];deliveryid[DL1,DS];');
        Observer.Verify();
    end;




    [Test]
    procedure DeepAttrLeaf_RealTableRoot_TwoRows()
    begin
        Start();
        ExportATable('one row', 1);
        ExportATable('two rows', 2);
        Observer.Expect('one row xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:AccountingSupplierParty>|    <cac:Party>|      <cac:PartyLegalEntity>|        <cbc:CompanyID>CO1</cbc:CompanyID>|      </cac:PartyLegalEntity>|    </cac:Party>|  </cac:AccountingSupplierParty>|</Invoice>|');
        Observer.Expect('one row log', 'agr 1;endpoint[];companyid[CO1];cidscheme[];');
        Observer.Expect('two rows xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:AccountingSupplierParty>|    <cac:Party>|      <cac:PartyLegalEntity>|        <cbc:CompanyID>CO1</cbc:CompanyID>|      </cac:PartyLegalEntity>|    </cac:Party>|  </cac:AccountingSupplierParty>|</Invoice>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV2</cbc:ID>|  <cac:AccountingSupplierParty>|    <cac:Party>|      <cbc:EndpointID schemeID="0088">EP2</cbc:EndpointID>|      <cac:PartyLegalEntity>|        <cbc:CompanyID schemeID="CS2">CO2</cbc:CompanyID>|      </cac:PartyLegalEntity>|    </cac:Party>|  </cac:AccountingSupplierParty>|</Invoice>|');
        Observer.Expect('two rows log', 'agr 1;endpoint[];companyid[CO1];cidscheme[];agr 2;endpoint[EP2];companyid[CO2];cidscheme[CS2];');
        Observer.Verify();
    end;




    [Test]
    procedure TableContainer_TaxTotal()
    begin
        Start();
        ExportB('sub 2', 2, '30', '31', '', 0, 0, 0, false, false);
        ExportB('sub 0', 0, '30', '31', '', 0, 0, 0, false, false);
        ExportB('tax empty sub 1', 1, '', '31', '', 0, 0, 0, false, false);
        ExportB('sub 1 reason', 1, '30', '', 'exempt', 0, 0, 0, false, false);
        Observer.Expect('sub 2 xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:TaxTotal>|    <cbc:TaxAmount currencyID="EUR">30</cbc:TaxAmount>|    <cac:TaxSubtotal>|      <cbc:TaxableAmount currencyID="EUR">101</cbc:TaxableAmount>|      <cac:TaxCategory>|        <cbc:ID>S1</cbc:ID>|      </cac:TaxCategory>|    </cac:TaxSubtotal>|    <cac:TaxSubtotal>|      <cbc:TaxableAmount currencyID="EUR">102</cbc:TaxableAmount>|      <cac:TaxCategory>|        <cbc:ID>S2</cbc:ID>|      </cac:TaxCategory>|    </cac:TaxSubtotal>|  </cac:TaxTotal>|  <cac:TaxTotal>|    <cbc:TaxAmount>31</cbc:TaxAmount>|  </cac:TaxTotal>|</Invoice>|');
        Observer.Expect('sub 2 log', 'taxtotal;pre subloop;agr subloop 1;agr subloop 2;agr subloop 3;taxtotallcy;agr line 1;');
        Observer.Expect('sub 0 xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:TaxTotal>|    <cbc:TaxAmount currencyID="EUR">30</cbc:TaxAmount>|  </cac:TaxTotal>|  <cac:TaxTotal>|    <cbc:TaxAmount>31</cbc:TaxAmount>|  </cac:TaxTotal>|</Invoice>|');
        Observer.Expect('sub 0 log', 'taxtotal;pre subloop;agr subloop 1;taxtotallcy;agr line 1;');
        Observer.Expect('tax empty sub 1 xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:TaxTotal>|    <cbc:TaxAmount currencyID="EUR" />|    <cac:TaxSubtotal>|      <cbc:TaxableAmount currencyID="EUR">101</cbc:TaxableAmount>|      <cac:TaxCategory>|        <cbc:ID>S1</cbc:ID>|      </cac:TaxCategory>|    </cac:TaxSubtotal>|  </cac:TaxTotal>|  <cac:TaxTotal>|    <cbc:TaxAmount>31</cbc:TaxAmount>|  </cac:TaxTotal>|</Invoice>|');
        Observer.Expect('tax empty sub 1 log', 'taxtotal;pre subloop;agr subloop 1;agr subloop 2;taxtotallcy;agr line 1;');
        Observer.Expect('sub 1 reason xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:TaxTotal>|    <cbc:TaxAmount currencyID="EUR">30</cbc:TaxAmount>|    <cac:TaxSubtotal>|      <cbc:TaxableAmount currencyID="EUR">101</cbc:TaxableAmount>|      <cac:TaxCategory>|        <cbc:ID>S1</cbc:ID>|        <cbc:TaxExemptionReason>exempt</cbc:TaxExemptionReason>|      </cac:TaxCategory>|    </cac:TaxSubtotal>|  </cac:TaxTotal>|</Invoice>|');
        Observer.Expect('sub 1 reason log', 'taxtotal;pre subloop;agr subloop 1;agr subloop 2;taxtotallcy;agr line 1;');
        Observer.Verify();
    end;




    [Test]
    procedure TableContainer_ItemAndPrice()
    begin
        Start();
        ExportB('two lines', 0, '30', '31', '', 0, 0, 2, true, false);
        ExportB('one line', 0, '30', '31', '', 0, 0, 1, false, false);
        Observer.Expect('two lines xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:TaxTotal>|    <cbc:TaxAmount currencyID="EUR">30</cbc:TaxAmount>|  </cac:TaxTotal>|  <cac:TaxTotal>|    <cbc:TaxAmount>31</cbc:TaxAmount>|  </cac:TaxTotal>|  <cac:InvoiceLine>|    <cbc:ID>1</cbc:ID>|    <cac:Item>|      <cbc:Description>item 1</cbc:Description>|      <cbc:Name>name1</cbc:Name>|      <cac:SellersItemIdentification>|        <cbc:ID>SID1</cbc:ID>|      </cac:SellersItemIdentification>|      <cac:CommodityClassification>|        <cbc:ItemClassificationCode listID="STI">C1</cbc:ItemClassificationCode>|      </cac:CommodityClassification>|      <cac:ClassifiedTaxCategory>|        <cbc:ID>S</cbc:ID>|        <cbc:Percent>25</cbc:Percent>|      </cac:ClassifiedTaxCategory>|      <cac:AdditionalItemProperty>|        <cbc:Name>prop1</cbc:Name>|      </cac:AdditionalItemProperty>|    </cac:Item>|    <cac:Price>|      <cbc:PriceAmount currencyID="EUR">5.01</cbc:PriceAmount>|      <cac:AllowanceCharge>|        <cbc:ChargeIndicator>false</cbc:ChargeIndicator>|      </cac:AllowanceCharge>|    </cac:Price>|  </cac:InvoiceLine>|  <cac:InvoiceLine>|    <cbc:ID>2</cbc:ID>|    <cac:Item>|      <cbc:Name>name2</cbc:Name>|      <cac:SellersItemIdentification>|        <cbc:ID>SID2</cbc:ID>|      </cac:SellersItemIdentification>|      <cac:ClassifiedTaxCategory>|        <cbc:ID>S</cbc:ID>|        <cbc:Percent>25</cbc:Percent>|      </cac:ClassifiedTaxCategory>|    </cac:Item>|    <cac:Price>|      <cbc:PriceAmount currencyID="EUR">5.02</cbc:PriceAmount>|    </cac:Price>|  </cac:InvoiceLine>|</Invoice>|');
        Observer.Expect('two lines log', 'taxtotal;pre subloop;agr subloop 1;taxtotallcy;agr line 1;item line 1;descr[item 1];sellers[SID1];pre commodity;agr commodity [C1];taxcat;pre prop;agr prop [prop1];price line 1;pre charge;agr charge [false];agr line 2;item line 2;descr[];sellers[SID2];pre commodity;agr commodity [];taxcat;pre prop;agr prop [];price line 2;pre charge;agr charge [];agr line 3;');
        Observer.Expect('one line xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:TaxTotal>|    <cbc:TaxAmount currencyID="EUR">30</cbc:TaxAmount>|  </cac:TaxTotal>|  <cac:TaxTotal>|    <cbc:TaxAmount>31</cbc:TaxAmount>|  </cac:TaxTotal>|  <cac:InvoiceLine>|    <cbc:ID>1</cbc:ID>|    <cac:Item>|      <cbc:Description>item 1</cbc:Description>|      <cbc:Name>name1</cbc:Name>|      <cac:SellersItemIdentification>|        <cbc:ID>SID1</cbc:ID>|      </cac:SellersItemIdentification>|      <cac:CommodityClassification>|        <cbc:ItemClassificationCode listID="STI">C1</cbc:ItemClassificationCode>|      </cac:CommodityClassification>|      <cac:ClassifiedTaxCategory>|        <cbc:ID>S</cbc:ID>|        <cbc:Percent>25</cbc:Percent>|      </cac:ClassifiedTaxCategory>|      <cac:AdditionalItemProperty>|        <cbc:Name>prop1</cbc:Name>|      </cac:AdditionalItemProperty>|    </cac:Item>|    <cac:Price>|      <cbc:PriceAmount currencyID="EUR">5.01</cbc:PriceAmount>|      <cac:AllowanceCharge>|        <cbc:ChargeIndicator>false</cbc:ChargeIndicator>|      </cac:AllowanceCharge>|    </cac:Price>|  </cac:InvoiceLine>|</Invoice>|');
        Observer.Expect('one line log', 'taxtotal;pre subloop;agr subloop 1;taxtotallcy;agr line 1;item line 1;descr[item 1];sellers[SID1];pre commodity;agr commodity [C1];taxcat;pre prop;agr prop [prop1];price line 1;pre charge;agr charge [false];agr line 2;');
        Observer.Verify();
    end;




    [Test]
    procedure TableContainer_SkipContainer()
    begin
        Start();
        ExportB('item skipped', 0, '30', '31', '', 0, 0, 2, false, true);
        Observer.Expect('item skipped xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:TaxTotal>|    <cbc:TaxAmount currencyID="EUR">30</cbc:TaxAmount>|  </cac:TaxTotal>|  <cac:TaxTotal>|    <cbc:TaxAmount>31</cbc:TaxAmount>|  </cac:TaxTotal>|  <cac:InvoiceLine>|    <cbc:ID>1</cbc:ID>|    <cac:Price>|      <cbc:PriceAmount currencyID="EUR">5.01</cbc:PriceAmount>|      <cac:AllowanceCharge>|        <cbc:ChargeIndicator>false</cbc:ChargeIndicator>|      </cac:AllowanceCharge>|    </cac:Price>|  </cac:InvoiceLine>|  <cac:InvoiceLine>|    <cbc:ID>2</cbc:ID>|    <cac:Price>|      <cbc:PriceAmount currencyID="EUR">5.02</cbc:PriceAmount>|      <cac:AllowanceCharge>|        <cbc:ChargeIndicator>false</cbc:ChargeIndicator>|      </cac:AllowanceCharge>|    </cac:Price>|  </cac:InvoiceLine>|</Invoice>|');
        Observer.Expect('item skipped log', 'taxtotal;pre subloop;agr subloop 1;taxtotallcy;agr line 1;item line 1;price line 1;pre charge;agr charge [false];agr line 2;item line 2;price line 2;pre charge;agr charge [false];agr line 3;');
        Observer.Verify();
    end;




    [Test]
    procedure TableContainer_BreakAndSkipInInnerTable()
    begin
        Start();
        ExportB('break at 2 of 3', 3, '30', '31', '', 2, 0, 0, false, false);
        ExportB('skip at 2 of 3', 3, '30', '31', '', 0, 2, 0, false, false);
        Observer.Expect('break at 2 of 3 xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:TaxTotal>|    <cbc:TaxAmount currencyID="EUR">30</cbc:TaxAmount>|    <cac:TaxSubtotal>|      <cbc:TaxableAmount currencyID="EUR">101</cbc:TaxableAmount>|      <cac:TaxCategory>|        <cbc:ID>S1</cbc:ID>|      </cac:TaxCategory>|    </cac:TaxSubtotal>|  </cac:TaxTotal>|  <cac:TaxTotal>|    <cbc:TaxAmount>31</cbc:TaxAmount>|  </cac:TaxTotal>|</Invoice>|');
        Observer.Expect('break at 2 of 3 log', 'taxtotal;pre subloop;agr subloop 1;agr subloop 2;taxtotallcy;agr line 1;');
        Observer.Expect('skip at 2 of 3 xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Invoice xmlns:cac="urn:p:cac" xmlns:cbc="urn:p:cbc" xmlns="urn:p:inv">|  <cbc:ID>INV1</cbc:ID>|  <cac:TaxTotal>|    <cbc:TaxAmount currencyID="EUR">30</cbc:TaxAmount>|    <cac:TaxSubtotal>|      <cbc:TaxableAmount currencyID="EUR">101</cbc:TaxableAmount>|      <cac:TaxCategory>|        <cbc:ID>S1</cbc:ID>|      </cac:TaxCategory>|    </cac:TaxSubtotal>|    <cac:TaxSubtotal>|      <cbc:TaxableAmount currencyID="EUR">103</cbc:TaxableAmount>|      <cac:TaxCategory>|        <cbc:ID>S3</cbc:ID>|      </cac:TaxCategory>|    </cac:TaxSubtotal>|  </cac:TaxTotal>|  <cac:TaxTotal>|    <cbc:TaxAmount>31</cbc:TaxAmount>|  </cac:TaxTotal>|</Invoice>|');
        Observer.Expect('skip at 2 of 3 log', 'taxtotal;pre subloop;agr subloop 1;agr subloop 2;agr subloop 3;agr subloop 4;taxtotallcy;agr line 1;');
        Observer.Verify();
    end;



}
