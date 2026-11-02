// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-skip-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 93866-93867, xmlports 93850-93853, codeunits 93860 (log), 93861 (test)
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
        Observer.Finish();
    end;

    [Test]
    procedure DeepAttrLeaf_AllFilled_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure DeepAttrLeaf_AllFilled_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure DeepAttrLeaf_AllFilled_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure DeepAttrLeaf_SkipVariants_EndpointIdentLegal()
    begin
        Start();
        ExportA('a endpoint empty', 2);
        ExportA('b party identification empty', 3);
        ExportA('c company id set, attribute empty', 4);
        Observer.Finish();
    end;

    [Test]
    procedure DeepAttrLeaf_SkipVariants_EndpointIdentLegal_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure DeepAttrLeaf_SkipVariants_EndpointIdentLegal_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure DeepAttrLeaf_SkipVariants_EndpointIdentLegal_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure DeepAttrLeaf_SkipVariants_CompanyDeliveryParty()
    begin
        Start();
        ExportA('d company id empty, attribute set', 5);
        ExportA('e delivery date and id empty', 6);
        ExportA('f everything in party empty', 7);
        Observer.Finish();
    end;

    [Test]
    procedure DeepAttrLeaf_SkipVariants_CompanyDeliveryParty_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure DeepAttrLeaf_SkipVariants_CompanyDeliveryParty_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure DeepAttrLeaf_SkipVariants_CompanyDeliveryParty_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure DeepAttrLeaf_RealTableRoot_TwoRows()
    begin
        Start();
        ExportATable('one row', 1);
        ExportATable('two rows', 2);
        Observer.Finish();
    end;

    [Test]
    procedure DeepAttrLeaf_RealTableRoot_TwoRows_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure DeepAttrLeaf_RealTableRoot_TwoRows_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure DeepAttrLeaf_RealTableRoot_TwoRows_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TableContainer_TaxTotal()
    begin
        Start();
        ExportB('sub 2', 2, '30', '31', '', 0, 0, 0, false, false);
        ExportB('sub 0', 0, '30', '31', '', 0, 0, 0, false, false);
        ExportB('tax empty sub 1', 1, '', '31', '', 0, 0, 0, false, false);
        ExportB('sub 1 reason', 1, '30', '', 'exempt', 0, 0, 0, false, false);
        Observer.Finish();
    end;

    [Test]
    procedure TableContainer_TaxTotal_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TableContainer_TaxTotal_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TableContainer_TaxTotal_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TableContainer_ItemAndPrice()
    begin
        Start();
        ExportB('two lines', 0, '30', '31', '', 0, 0, 2, true, false);
        ExportB('one line', 0, '30', '31', '', 0, 0, 1, false, false);
        Observer.Finish();
    end;

    [Test]
    procedure TableContainer_ItemAndPrice_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TableContainer_ItemAndPrice_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TableContainer_ItemAndPrice_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TableContainer_SkipContainer()
    begin
        Start();
        ExportB('item skipped', 0, '30', '31', '', 0, 0, 2, false, true);
        Observer.Finish();
    end;

    [Test]
    procedure TableContainer_SkipContainer_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TableContainer_SkipContainer_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TableContainer_SkipContainer_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure TableContainer_BreakAndSkipInInnerTable()
    begin
        Start();
        ExportB('break at 2 of 3', 3, '30', '31', '', 2, 0, 0, false, false);
        ExportB('skip at 2 of 3', 3, '30', '31', '', 0, 2, 0, false, false);
        Observer.Finish();
    end;

    [Test]
    procedure TableContainer_BreakAndSkipInInnerTable_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TableContainer_BreakAndSkipInInnerTable_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TableContainer_BreakAndSkipInInnerTable_More3()
    begin
        Observer.More();
    end;
}
