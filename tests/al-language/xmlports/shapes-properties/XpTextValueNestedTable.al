// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT Y83 Helper (Y83XpFixtures.al); own objects: tables 97940-97942, xmlports 97943-97949, test codeunit 97950
// Probe: al-runner issue 7263 (follow-up to 7130 and 7131, XpTableRootNestedText.al). Export (Format = Xml) of
//   A: a root table element (MaxOccurs = Once, XmlName Envelope) > text element L1 > text element L0 > a table element (orders, field element
//      No) and a text element with a value (username, set in OnBeforePassVariable), the text element after and before the table element, and
//      with Namespaces and UseDefaultNamespace = true; with 0, 1 and 2 rows of the table element;
//   B: a table element (MaxOccurs = Once) whose row holds a text element TI with a text element with a value (T1) and a table element (rf),
//      with 0, 1 and 2 rows of the inner table element; the value element before the table element, empty, after it, and with a field
//      element before the value element.
//   Each observation is the exact exported text.
// Facts: filled in after the run.
// BC versions: 27, 28, 29

table 97940 "LT X63 Comm"
{
    DataClassification = SystemMetadata;

    fields { field(1; Id; Code[10]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

table 97941 "LT X63 Order"
{
    DataClassification = SystemMetadata;

    fields { field(1; "No."; Code[10]) { } }
    keys { key(PK; "No.") { Clustered = true; } }
}

table 97942 "LT X63 Ref"
{
    DataClassification = SystemMetadata;

    fields { field(1; "Ref"; Code[10]) { } }
    keys { key(PK; "Ref") { Clustered = true; } }
}

// A: root table element, two text levels, a table element and a text element with a value; the text element after the table element.
xmlport 97943 "LT X63 A After"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        tableelement(comm; "LT X63 Comm")
        {
            MaxOccurs = Once;
            XmlName = 'Envelope';

            textelement(L1)
            {
                textelement(L0)
                {
                    tableelement(orders; "LT X63 Order")
                    {
                        XmlName = 'order';
                        fieldelement(No; orders."No.") { }
                    }
                    textelement(username)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            username := 'x';
                        end;
                    }
                }
            }
        }
    }
}

// A: the same, the text element with a value before the table element.
xmlport 97944 "LT X63 A Before"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        tableelement(comm; "LT X63 Comm")
        {
            MaxOccurs = Once;
            XmlName = 'Envelope';

            textelement(L1)
            {
                textelement(L0)
                {
                    textelement(username)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            username := 'x';
                        end;
                    }
                    tableelement(orders; "LT X63 Order")
                    {
                        XmlName = 'order';
                        fieldelement(No; orders."No.") { }
                    }
                }
            }
        }
    }
}

// A: the same as the first with Namespaces and UseDefaultNamespace = true.
xmlport 97945 "LT X63 A Ns"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;
    Namespaces = soap = 'http://schemas.xmlsoap.org/soap/envelope/', tem = 'http://tempuri.org/';
    UseDefaultNamespace = true;

    schema
    {
        tableelement(comm; "LT X63 Comm")
        {
            MaxOccurs = Once;
            XmlName = 'Envelope';
            NamespacePrefix = 'soap';

            textelement(L1)
            {
                NamespacePrefix = 'tem';
                textelement(L0)
                {
                    NamespacePrefix = 'tem';
                    tableelement(orders; "LT X63 Order")
                    {
                        XmlName = 'order';
                        fieldelement(No; orders."No.") { }
                    }
                    textelement(username)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            username := 'x';
                        end;
                    }
                }
            }
        }
    }
}

// B: a table element whose row holds a text element with a value element and a table element; the value element first.
xmlport 97946 "LT X63 B Before"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Envelope)
        {
            tableelement(orders; "LT X63 Order")
            {
                MaxOccurs = Once;
                textelement(TI)
                {
                    textelement(T1)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            T1 := 'x';
                        end;
                    }
                    tableelement(rf; "LT X63 Ref")
                    {
                        XmlName = 'r';
                        fieldelement(Ref; rf."Ref") { }
                    }
                }
            }
        }
    }
}

// B: the same with a value element that stays empty.
xmlport 97947 "LT X63 B Empty"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Envelope)
        {
            tableelement(orders; "LT X63 Order")
            {
                MaxOccurs = Once;
                textelement(TI)
                {
                    textelement(T1) { }
                    tableelement(rf; "LT X63 Ref")
                    {
                        XmlName = 'r';
                        fieldelement(Ref; rf."Ref") { }
                    }
                }
            }
        }
    }
}

// B: the same with the value element after the table element.
xmlport 97948 "LT X63 B After"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Envelope)
        {
            tableelement(orders; "LT X63 Order")
            {
                MaxOccurs = Once;
                textelement(TI)
                {
                    tableelement(rf; "LT X63 Ref")
                    {
                        XmlName = 'r';
                        fieldelement(Ref; rf."Ref") { }
                    }
                    textelement(T1)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            T1 := 'x';
                        end;
                    }
                }
            }
        }
    }
}

// B: a field element and a value element, then the table element.
xmlport 97949 "LT X63 B Field"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Envelope)
        {
            tableelement(orders; "LT X63 Order")
            {
                MaxOccurs = Once;
                textelement(TI)
                {
                    fieldelement(No; orders."No.") { }
                    textelement(T1)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            T1 := 'x';
                        end;
                    }
                    tableelement(rf; "LT X63 Ref")
                    {
                        XmlName = 'r';
                        fieldelement(Ref; rf."Ref") { }
                    }
                }
            }
        }
    }
}

codeunit 97950 "LT X63 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y83 Helper";

    // A: one root row, Orders rows O1, O2 (as many as given), no rows of Ref.
    local procedure SeedA(Orders: Integer)
    var
        Comm: Record "LT X63 Comm";
        Order: Record "LT X63 Order";
        i: Integer;
    begin
        Comm.DeleteAll();
        Order.DeleteAll();
        Comm.Id := 'C1';
        Comm.Insert();
        for i := 1 to Orders do begin
            Order."No." := 'O' + Format(i);
            Order.Insert();
        end;
        Commit();
    end;

    // B: one Order row O1, as many Ref rows R1, R2 as given.
    local procedure SeedB(Refs: Integer)
    var
        Order: Record "LT X63 Order";
        Ref: Record "LT X63 Ref";
        i: Integer;
    begin
        Order.DeleteAll();
        Ref.DeleteAll();
        Order."No." := 'O1';
        Order.Insert();
        for i := 1 to Refs do begin
            Ref."Ref" := 'R' + Format(i);
            Ref.Insert();
        end;
        Commit();
    end;

    [Test]
    procedure XTV_RootTextsTableThenValue_Export()
    begin
        SeedA(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97943, TextEncoding::UTF8));
        SeedA(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97943, TextEncoding::UTF8));
        SeedA(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97943, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XTV_RootTextsValueThenTable_Export()
    begin
        SeedA(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97944, TextEncoding::UTF8));
        SeedA(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97944, TextEncoding::UTF8));
        SeedA(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97944, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XTV_RootTextsNamespaces_Export()
    begin
        SeedA(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97945, TextEncoding::UTF8));
        SeedA(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97945, TextEncoding::UTF8));
        SeedA(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97945, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XTV_RowTextValueThenTable_Export()
    begin
        SeedB(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97946, TextEncoding::UTF8));
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97946, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97946, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XTV_RowTextEmptyValueThenTable_Export()
    begin
        SeedB(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97947, TextEncoding::UTF8));
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97947, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97947, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XTV_RowTextTableThenValue_Export()
    begin
        SeedB(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97948, TextEncoding::UTF8));
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97948, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97948, TextEncoding::UTF8));
        Observer.Finish();
    end;

    [Test]
    procedure XTV_RowTextFieldValueThenTable_Export()
    begin
        SeedB(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97949, TextEncoding::UTF8));
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97949, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97949, TextEncoding::UTF8));
        Observer.Finish();
    end;
}
