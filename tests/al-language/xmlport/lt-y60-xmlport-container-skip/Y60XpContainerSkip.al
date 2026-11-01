// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-skip-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93225, xmlports 93225-93229 and 93235, codeunits 93225-93226.
// Probe (gap cycle 6, G6-07): triggers of a container text element (a text element with children) on export, with currXMLport.Skip():
// a container below the root that fills its leaves and skips when they are empty (with and without leaf triggers that skip); two nested
// containers (MinOccurs = Zero, MaxOccurs = Once) that both skip; a container two levels below a table element whose leaves and text
// attributes skip when empty (the shape of e-invoice ports: Attachment > binary object with attributes, external reference > URI), on a
// real table and on an Integer table element; import of nested containers with OnAfterAssignVariable.
// The plain trigger order of a container below the root is pinned by xmlport/W7XmlPortTests.al:25-90 and below a table element by
// xmlport/lt-qr-xmlport-container-occurs (not repeated). Line breaks of the exported text are shown as |.
// BC versions: 27-29

table 93225 "LT Y60 CS Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Ref; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 93225 "LT Y60 CS Log"
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

xmlport 93225 "LT Y60 CS Period"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = cac = 'urn:lt-cac', cbc = 'urn:lt-cbc';

    schema
    {
        textelement(Doc)
        {
            textelement(Period)
            {
                NamespacePrefix = 'cac';
                textelement(StartDate)
                {
                    NamespacePrefix = 'cbc';
                }
                textelement(EndDate)
                {
                    NamespacePrefix = 'cbc';
                }

                trigger OnBeforePassVariable()
                begin
                    Log.Add('period');
                    case FillPeriod of
                        0:
                            begin
                                StartDate := '';
                                EndDate := '';
                            end;
                        1:
                            begin
                                StartDate := '2024-01-01';
                                EndDate := '2024-01-31';
                            end;
                        2:
                            begin
                                StartDate := '2024-01-01';
                                EndDate := '';
                            end;
                    end;
                    if (StartDate = '') and (EndDate = '') then
                        currXMLport.Skip();
                end;
            }
            textelement(After)
            {
                NamespacePrefix = 'cbc';

                trigger OnBeforePassVariable()
                begin
                    Log.Add('after');
                    After := 'x';
                end;
            }
        }
    }

    trigger OnPostXmlPort()
    begin
        Log.Add('post');
    end;

    procedure SetFill(NewFill: Integer)
    begin
        FillPeriod := NewFill;
    end;

    var
        Log: Codeunit "LT Y60 CS Log";
        FillPeriod: Integer;
}

xmlport 93226 "LT Y60 CS Period Leaf"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = cac = 'urn:lt-cac', cbc = 'urn:lt-cbc';

    schema
    {
        textelement(Doc)
        {
            textelement(Period)
            {
                NamespacePrefix = 'cac';
                textelement(StartDate)
                {
                    NamespacePrefix = 'cbc';

                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('start=' + StartDate);
                        if StartDate = '' then
                            currXMLport.Skip();
                    end;
                }
                textelement(EndDate)
                {
                    NamespacePrefix = 'cbc';

                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('end=' + EndDate);
                        if EndDate = '' then
                            currXMLport.Skip();
                    end;
                }

                trigger OnBeforePassVariable()
                begin
                    Log.Add('period');
                    case FillPeriod of
                        0:
                            begin
                                StartDate := '';
                                EndDate := '';
                            end;
                        1:
                            begin
                                StartDate := '2024-01-01';
                                EndDate := '2024-01-31';
                            end;
                        2:
                            begin
                                StartDate := '2024-01-01';
                                EndDate := '';
                            end;
                    end;
                    if (StartDate = '') and (EndDate = '') then
                        currXMLport.Skip();
                end;
            }
            textelement(After)
            {
                NamespacePrefix = 'cbc';

                trigger OnBeforePassVariable()
                begin
                    Log.Add('after');
                    After := 'x';
                end;
            }
        }
    }

    trigger OnPostXmlPort()
    begin
        Log.Add('post');
    end;

    procedure SetFill(NewFill: Integer)
    begin
        FillPeriod := NewFill;
    end;

    var
        Log: Codeunit "LT Y60 CS Log";
        FillPeriod: Integer;
}

xmlport 93227 "LT Y60 CS Billing"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = cac = 'urn:lt-cac', cbc = 'urn:lt-cbc';

    schema
    {
        textelement(Doc)
        {
            textelement(Billing)
            {
                NamespacePrefix = 'cac';
                MinOccurs = Zero;
                textelement(InvDoc)
                {
                    NamespacePrefix = 'cac';
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    textelement(RefId)
                    {
                        NamespacePrefix = 'cbc';
                        MaxOccurs = Once;
                    }
                    textelement(RefDate)
                    {
                        NamespacePrefix = 'cbc';
                        MinOccurs = Zero;
                    }

                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('invdoc');
                        RefId := InvRef;
                        if InvRef <> '' then
                            RefDate := '2024-02-01';
                        if InvRef = '' then
                            currXMLport.Skip();
                    end;
                }

                trigger OnBeforePassVariable()
                begin
                    Log.Add('billing');
                    if BillRef = '' then
                        currXMLport.Skip();
                end;
            }
            textelement(Tail)
            {
                NamespacePrefix = 'cbc';

                trigger OnBeforePassVariable()
                begin
                    Log.Add('tail');
                    Tail := 't';
                end;
            }
        }
    }

    trigger OnPostXmlPort()
    begin
        Log.Add('post');
    end;

    procedure SetRefs(NewBillRef: Text; NewInvRef: Text)
    begin
        BillRef := NewBillRef;
        InvRef := NewInvRef;
    end;

    var
        Log: Codeunit "LT Y60 CS Log";
        BillRef: Text;
        InvRef: Text;
}

xmlport 93228 "LT Y60 CS Attach"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = cac = 'urn:lt-cac', cbc = 'urn:lt-cbc';

    schema
    {
        textelement(Doc)
        {
            tableelement(Row; "LT Y60 CS Src")
            {
                NamespacePrefix = 'cac';
                XmlName = 'Line';
                textelement(Title)
                {
                    NamespacePrefix = 'cbc';
                }
                textelement(Attachment)
                {
                    NamespacePrefix = 'cac';
                    textelement(Blob)
                    {
                        NamespacePrefix = 'cbc';
                        MinOccurs = Zero;
                        textattribute(mime)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                Log.Add('mime=' + mime);
                                if mime = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        textattribute(fname)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                Log.Add('fname=' + fname);
                                if fname = '' then
                                    currXMLport.Skip();
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('blob=' + Blob);
                            if Blob = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(Ext)
                    {
                        NamespacePrefix = 'cac';
                        textelement(Uri)
                        {
                            NamespacePrefix = 'cbc';

                            trigger OnBeforePassVariable()
                            begin
                                Log.Add('uri=' + Uri);
                                if Uri = '' then
                                    currXMLport.Skip();
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('ext');
                            if UriValue = '' then
                                currXMLport.Skip();
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    Log.Add('row ' + Format(Row.Id));
                    Title := Row.Name;
                    case Mode of
                        1:
                            begin
                                Blob := 'b' + Format(Row.Id);
                                mime := 'text/plain';
                                fname := 'f' + Format(Row.Id) + '.txt';
                                UriValue := 'u' + Format(Row.Id);
                            end;
                        2:
                            begin
                                Blob := 'b' + Format(Row.Id);
                                mime := 'text/plain';
                                fname := Row.Ref;
                                UriValue := Row.Ref;
                            end;
                        3:
                            begin
                                if Row.Name = 'one' then
                                    currXMLport.Skip();
                                Blob := 'b' + Format(Row.Id);
                                mime := 'text/plain';
                                fname := 'f' + Format(Row.Id) + '.txt';
                                UriValue := 'u' + Format(Row.Id);
                            end;
                        4:
                            begin
                                Blob := '';
                                mime := 'text/plain';
                                fname := 'f' + Format(Row.Id) + '.txt';
                                UriValue := '';
                            end;
                    end;
                    Uri := UriValue;
                end;
            }
        }
    }

    trigger OnPostXmlPort()
    begin
        Log.Add('post');
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    var
        Log: Codeunit "LT Y60 CS Log";
        Mode: Integer;
        UriValue: Text;
}

xmlport 93229 "LT Y60 CS Attach Integer"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = cac = 'urn:lt-cac', cbc = 'urn:lt-cbc';

    schema
    {
        textelement(Doc)
        {
            tableelement(Ln; Integer)
            {
                NamespacePrefix = 'cac';
                XmlName = 'Line';
                SourceTableView = sorting(Number) where(Number = filter(1 ..));
                textelement(Title)
                {
                    NamespacePrefix = 'cbc';
                }
                textelement(Attachment)
                {
                    NamespacePrefix = 'cac';
                    textelement(Blob)
                    {
                        NamespacePrefix = 'cbc';
                        MinOccurs = Zero;
                        textattribute(fname)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                Log.Add('fname=' + fname);
                                if fname = '' then
                                    currXMLport.Skip();
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('blob=' + Blob);
                            if Blob = '' then
                                currXMLport.Skip();
                        end;
                    }
                    textelement(Ext)
                    {
                        NamespacePrefix = 'cac';
                        textelement(Uri)
                        {
                            NamespacePrefix = 'cbc';

                            trigger OnBeforePassVariable()
                            begin
                                Log.Add('uri=' + Uri);
                                if Uri = '' then
                                    currXMLport.Skip();
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('ext');
                            if Uri = '' then
                                currXMLport.Skip();
                        end;
                    }
                }

                trigger OnPreXmlItem()
                begin
                    Log.Add('pre');
                    Ln.SetRange(Number, 1, 2);
                end;

                trigger OnAfterGetRecord()
                var
                    Src: Record "LT Y60 CS Src";
                begin
                    Log.Add('ln ' + Format(Ln.Number));
                    Src.Get(Ln.Number);
                    Title := Src.Name;
                    Blob := 'b' + Format(Ln.Number);
                    fname := Src.Ref;
                    Uri := Src.Ref;
                end;
            }
        }
    }

    trigger OnPostXmlPort()
    begin
        Log.Add('post');
    end;

    var
        Log: Codeunit "LT Y60 CS Log";
}

xmlport 93235 "LT Y60 CS Billing Import"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Doc)
        {
            textelement(Billing)
            {
                MinOccurs = Zero;
                textelement(InvDoc)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    textelement(RefId)
                    {
                        MaxOccurs = Once;

                        trigger OnAfterAssignVariable()
                        begin
                            Log.Add('refid=' + RefId);
                        end;
                    }
                    textelement(RefDate)
                    {
                        MinOccurs = Zero;

                        trigger OnAfterAssignVariable()
                        begin
                            Log.Add('refdate=' + RefDate);
                        end;
                    }

                    trigger OnAfterAssignVariable()
                    begin
                        Log.Add('invdoc=[' + InvDoc + ']');
                    end;
                }

                trigger OnAfterAssignVariable()
                begin
                    Log.Add('billing=[' + Billing + ']');
                end;
            }
        }
    }

    trigger OnPostXmlPort()
    begin
        Log.Add('post');
    end;

    var
        Log: Codeunit "LT Y60 CS Log";
}

codeunit 93226 "LT Y60 CS Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y60 CS Log";

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

    local procedure Seed()
    var
        Src: Record "LT Y60 CS Src";
    begin
        Src.DeleteAll();
        Src.Id := 1;
        Src.Name := 'one';
        Src.Ref := 'r1';
        Src.Insert();
        Src.Id := 2;
        Src.Name := 'two';
        Src.Ref := '';
        Src.Insert();
    end;

    local procedure ExportPeriod(var Observer: Codeunit "Probe Observer"; Name: Text; Fill: Integer)
    var
        XP: XmlPort "LT Y60 CS Period";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        XP.SetFill(Fill);
        XP.SetDestination(OutS);
        XP.Export();
        Observer.Observe(Name + ' xml', ReadLines(TempBlob));
        Observer.Observe(Name + ' log', Log.Take());
    end;

    local procedure ExportPeriodLeaf(var Observer: Codeunit "Probe Observer"; Name: Text; Fill: Integer)
    var
        XP: XmlPort "LT Y60 CS Period Leaf";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        XP.SetFill(Fill);
        XP.SetDestination(OutS);
        XP.Export();
        Observer.Observe(Name + ' xml', ReadLines(TempBlob));
        Observer.Observe(Name + ' log', Log.Take());
    end;

    local procedure ExportBilling(var Observer: Codeunit "Probe Observer"; Name: Text; BillRef: Text; InvRef: Text)
    var
        XP: XmlPort "LT Y60 CS Billing";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        XP.SetRefs(BillRef, InvRef);
        XP.SetDestination(OutS);
        XP.Export();
        Observer.Observe(Name + ' xml', ReadLines(TempBlob));
        Observer.Observe(Name + ' log', Log.Take());
    end;

    local procedure ExportAttach(var Observer: Codeunit "Probe Observer"; Name: Text; Mode: Integer)
    var
        XP: XmlPort "LT Y60 CS Attach";
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

    [TryFunction]
    local procedure TryImportBilling(Content: Text)
    var
        XP: XmlPort "LT Y60 CS Billing Import";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        XP.SetSource(InS);
        XP.Import();
    end;

    local procedure ImportBilling(var Observer: Codeunit "Probe Observer"; Name: Text; Content: Text)
    begin
        Log.Take();
        ClearLastError();
        Observer.Observe(Name + ' ok', Format(TryImportBilling(Content)));
        if GetLastErrorText() <> '' then
            Observer.ObserveError(Name + ' error');
        Observer.Observe(Name + ' log', Log.Take());
    end;

    [Test]
    procedure Container_Skip_BelowRoot_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ExportPeriod(Observer, 'both empty', 0);
        ExportPeriod(Observer, 'both filled', 1);
        ExportPeriod(Observer, 'end empty', 2);
        Observer.Finish();
    end;

    [Test]
    procedure Container_Skip_LeafTriggers_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ExportPeriodLeaf(Observer, 'both empty', 0);
        ExportPeriodLeaf(Observer, 'both filled', 1);
        ExportPeriodLeaf(Observer, 'end empty', 2);
        Observer.Finish();
    end;

    [Test]
    procedure Container_Nested_BothTriggers_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ExportBilling(Observer, 'all empty', '', '');
        ExportBilling(Observer, 'bill only', 'B1', '');
        ExportBilling(Observer, 'all set', 'B1', 'I1');
        ExportBilling(Observer, 'inv only', '', 'I1');
        Observer.Finish();
    end;

    [Test]
    procedure Container_TwoLevelsBelowTable_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ExportAttach(Observer, 'all filled', 1);
        ExportAttach(Observer, 'uri empty on two', 2);
        Observer.Finish();
    end;

    [Test]
    procedure Container_TwoLevelsBelowTable_RowSkip_Export()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ExportAttach(Observer, 'row one skipped', 3);
        ExportAttach(Observer, 'blob empty', 4);
        Observer.Finish();
    end;

    [Test]
    procedure Container_Skip_IntegerTableElement_Export()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT Y60 CS Attach Integer", OutS);
        Observer.Observe('xml', ReadLines(TempBlob));
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Container_NestedTriggers_Import()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ImportBilling(Observer, 'full', '<Doc><Billing><InvDoc><RefId>x</RefId><RefDate>d</RefDate></InvDoc></Billing></Doc>');
        ImportBilling(Observer, 'refid only', '<Doc><Billing><InvDoc><RefId>x</RefId></InvDoc></Billing></Doc>');
        ImportBilling(Observer, 'empty billing', '<Doc><Billing/></Doc>');
        ImportBilling(Observer, 'no billing', '<Doc></Doc>');
        ImportBilling(Observer, 'invdoc without refid', '<Doc><Billing><InvDoc><RefDate>d</RefDate></InvDoc></Billing></Doc>');
        Observer.Finish();
    end;
}
