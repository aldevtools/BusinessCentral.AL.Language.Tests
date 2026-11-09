// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT Y83 Helper (Y83XpFixtures.al); own objects: tables 97940-97942, xmlports 97943-97949 and 97951-97974, test codeunit 97950
// Probe: al-runner issue 7263 (follow-up to 7130 and 7131, XpTableRootNestedText.al). Export (Format = Xml) of
//   A: a root table element (MaxOccurs = Once, XmlName Envelope) > text element L1 > text element L0 > a table element (orders, field element
//      No) and a text element with a value (username, set in OnBeforePassVariable), the text element after and before the table element, and
//      with Namespaces and UseDefaultNamespace = true; with 0, 1 and 2 rows of the table element;
//   B: a table element (MaxOccurs = Once) whose row holds a text element TI with a text element with a value (T1) and a table element (rf),
//      with 0, 1 and 2 rows of the inner table element; the value element before the table element, empty, after it, and with a field
//      element before the value element.
//   Each observation is the exact exported text.
// Probe: al-runner issue 7309 (follow-up to 7263). Export of
//   A: the shape of A with three text levels (L2 > L1 > L0) and four (L3 > L2 > L1 > L0) below the root table element, the value
//      element after and before the table element, with Namespaces and UseDefaultNamespace = true; two value elements (username,
//      password) around the table element on the third level and before it on the second;
//   B: the row text element TI with two value elements (T1, T2) before, around and after the table element, three value elements
//      before it, a value element and an empty one, a field element and two value elements; TI > TJ with two value elements and
//      TI > TJ > TK with one, before the table element.
// Facts (BC 27.5, 28.5 and 29.0; the 29.0 run measured first, then the matrix): BC writes the plain tree in schema order; the elements are the
//   ones of the schema, one text element wraps the next. A: below the root table element the table element writes one `order` per row, and the text element
//   with a value writes once, `<username>x</username>`, after the last row (text element after the table element) or before the first (text element
//   first). With no row the table element writes one `order` with the record as it stands (`<No />`). With Namespaces and UseDefaultNamespace = true
//   the prefixed L1 and L0 keep tem:, the root keeps soap: and declares the three namespaces, order and username have no prefix and declare
//   urn:microsoft-dynamics-nav/xmlports/x<id> of the port. B: the text element TI below the row of the table element writes its value element
//   (`<T1>x</T1>`, or `<T1 />` when empty) and one `r` per row of the inner table element, in schema order (value element after the table
//   element: after the last `r`); a field element of the outer row first writes `<No>O1</No>`. With no inner row one `r` is written with the
//   record as it stands (`<Ref />`).
//   Issue 7309 (BC 29.0 measured first): the same at every depth and with several value elements: BC writes the plain tree in
//   schema order, each text element once around the next, each value element once where the schema has it (before the first row,
//   between the rows and the next element, or after the last row), and with namespaces L2, L1 and L0 keep tem: as in A.
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

// A, issue 7309: three text levels below the root table element, the table element, then the text element with a value.
xmlport 97951 "LT X63 A3 After"
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

            textelement(L2)
            {
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
}

// A: three text levels, the text element with a value, then the table element.
xmlport 97952 "LT X63 A3 Before"
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

            textelement(L2)
            {
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
}

// A: three text levels with Namespaces and UseDefaultNamespace = true.
xmlport 97953 "LT X63 A3 Ns"
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

            textelement(L2)
            {
                NamespacePrefix = 'tem';
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
}

// A: four text levels, the table element, then the text element with a value.
xmlport 97954 "LT X63 A4 After"
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

            textelement(L3)
            {
                textelement(L2)
                {
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
    }
}

// A: three text levels, a value element, the table element, a second value element.
xmlport 97955 "LT X63 A3 Two"
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

            textelement(L2)
            {
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
                        textelement(password)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                password := 'y';
                            end;
                        }
                    }
                }
            }
        }
    }
}

// A: two text levels, two value elements, then the table element.
xmlport 97956 "LT X63 A2 Two"
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
                    textelement(password)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            password := 'y';
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

// B, issue 7309: a row text element with two value elements, then the table element.
xmlport 97957 "LT X63 B Two"
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
                    textelement(T2)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            T2 := 'y';
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

// B: a value element, the table element, a value element.
xmlport 97958 "LT X63 B Two Mid"
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
                    textelement(T2)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            T2 := 'y';
                        end;
                    }
                }
            }
        }
    }
}

// B: the table element, then two value elements.
xmlport 97959 "LT X63 B Two Last"
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
                    textelement(T2)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            T2 := 'y';
                        end;
                    }
                }
            }
        }
    }
}

// B: three value elements, then the table element.
xmlport 97960 "LT X63 B Three"
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
                    textelement(T2)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            T2 := 'y';
                        end;
                    }
                    textelement(T3)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            T3 := 'z';
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

// B: a value element, a value element that stays empty, then the table element.
xmlport 97961 "LT X63 B Two Empty"
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
                    textelement(T2) { }
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

// B: two text levels in the row, two value elements, then the table element.
xmlport 97962 "LT X63 B Deep Two"
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
                    textelement(TJ)
                    {
                        textelement(T1)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                T1 := 'x';
                            end;
                        }
                        textelement(T2)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                T2 := 'y';
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
}

// B: three text levels in the row, one value element, then the table element.
xmlport 97963 "LT X63 B Deep One"
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
                    textelement(TJ)
                    {
                        textelement(TK)
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
    }
}

// B: a field element, two value elements, then the table element.
xmlport 97964 "LT X63 B Field Two"
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
                    textelement(T2)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            T2 := 'y';
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
        Observer.Expect('0 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <L1>\r\n    <L0>\r\n      <order>\r\n        <No />\r\n      </order>\r\n      <username>x</username>\r\n    </L0>\r\n  </L1>\r\n</Envelope>');
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <L1>\r\n    <L0>\r\n      <order>\r\n        <No>O1</No>\r\n      </order>\r\n      <username>x</username>\r\n    </L0>\r\n  </L1>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <L1>\r\n    <L0>\r\n      <order>\r\n        <No>O1</No>\r\n      </order>\r\n      <order>\r\n        <No>O2</No>\r\n      </order>\r\n      <username>x</username>\r\n    </L0>\r\n  </L1>\r\n</Envelope>');
        Observer.Verify();
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
        Observer.Expect('0 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <L1>\r\n    <L0>\r\n      <username>x</username>\r\n      <order>\r\n        <No />\r\n      </order>\r\n    </L0>\r\n  </L1>\r\n</Envelope>');
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <L1>\r\n    <L0>\r\n      <username>x</username>\r\n      <order>\r\n        <No>O1</No>\r\n      </order>\r\n    </L0>\r\n  </L1>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <L1>\r\n    <L0>\r\n      <username>x</username>\r\n      <order>\r\n        <No>O1</No>\r\n      </order>\r\n      <order>\r\n        <No>O2</No>\r\n      </order>\r\n    </L0>\r\n  </L1>\r\n</Envelope>');
        Observer.Verify();
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
        Observer.Expect('0 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/">\r\n  <tem:L1>\r\n    <tem:L0>\r\n      <order xmlns="urn:microsoft-dynamics-nav/xmlports/x97945">\r\n        <No />\r\n      </order>\r\n      <username xmlns="urn:microsoft-dynamics-nav/xmlports/x97945">x</username>\r\n    </tem:L0>\r\n  </tem:L1>\r\n</Envelope>');
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/">\r\n  <tem:L1>\r\n    <tem:L0>\r\n      <order xmlns="urn:microsoft-dynamics-nav/xmlports/x97945">\r\n        <No>O1</No>\r\n      </order>\r\n      <username xmlns="urn:microsoft-dynamics-nav/xmlports/x97945">x</username>\r\n    </tem:L0>\r\n  </tem:L1>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/">\r\n  <tem:L1>\r\n    <tem:L0>\r\n      <order xmlns="urn:microsoft-dynamics-nav/xmlports/x97945">\r\n        <No>O1</No>\r\n      </order>\r\n      <order xmlns="urn:microsoft-dynamics-nav/xmlports/x97945">\r\n        <No>O2</No>\r\n      </order>\r\n      <username xmlns="urn:microsoft-dynamics-nav/xmlports/x97945">x</username>\r\n    </tem:L0>\r\n  </tem:L1>\r\n</Envelope>');
        Observer.Verify();
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
        Observer.Expect('0 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <T1>x</T1>\r\n      <r>\r\n        <Ref />\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <T1>x</T1>\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <T1>x</T1>\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n      <r>\r\n        <Ref>R2</Ref>\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Verify();
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
        Observer.Expect('0 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <T1 />\r\n      <r>\r\n        <Ref />\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <T1 />\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <T1 />\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n      <r>\r\n        <Ref>R2</Ref>\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Verify();
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
        Observer.Expect('0 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <r>\r\n        <Ref />\r\n      </r>\r\n      <T1>x</T1>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n      <T1>x</T1>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n      <r>\r\n        <Ref>R2</Ref>\r\n      </r>\r\n      <T1>x</T1>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Verify();
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
        Observer.Expect('0 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <No>O1</No>\r\n      <T1>x</T1>\r\n      <r>\r\n        <Ref />\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <No>O1</No>\r\n      <T1>x</T1>\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <No>O1</No>\r\n      <T1>x</T1>\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n      <r>\r\n        <Ref>R2</Ref>\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Verify();
    end;

    // Issue 7309: three text levels, table element then value.
    [Test]
    procedure XTV_Root3TextsTableThenValue_Export()
    begin
        SeedA(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97951, TextEncoding::UTF8));
        SeedA(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97951, TextEncoding::UTF8));
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <L2>\r\n    <L1>\r\n      <L0>\r\n        <order>\r\n          <No>O1</No>\r\n        </order>\r\n        <username>x</username>\r\n      </L0>\r\n    </L1>\r\n  </L2>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <L2>\r\n    <L1>\r\n      <L0>\r\n        <order>\r\n          <No>O1</No>\r\n        </order>\r\n        <order>\r\n          <No>O2</No>\r\n        </order>\r\n        <username>x</username>\r\n      </L0>\r\n    </L1>\r\n  </L2>\r\n</Envelope>');
        Observer.Verify();
    end;

    // Three text levels, value then table element.
    [Test]
    procedure XTV_Root3TextsValueThenTable_Export()
    begin
        SeedA(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97952, TextEncoding::UTF8));
        SeedA(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97952, TextEncoding::UTF8));
        SeedA(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97952, TextEncoding::UTF8));
        Observer.Expect('0 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <L2>\r\n    <L1>\r\n      <L0>\r\n        <username>x</username>\r\n        <order>\r\n          <No />\r\n        </order>\r\n      </L0>\r\n    </L1>\r\n  </L2>\r\n</Envelope>');
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <L2>\r\n    <L1>\r\n      <L0>\r\n        <username>x</username>\r\n        <order>\r\n          <No>O1</No>\r\n        </order>\r\n      </L0>\r\n    </L1>\r\n  </L2>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <L2>\r\n    <L1>\r\n      <L0>\r\n        <username>x</username>\r\n        <order>\r\n          <No>O1</No>\r\n        </order>\r\n        <order>\r\n          <No>O2</No>\r\n        </order>\r\n      </L0>\r\n    </L1>\r\n  </L2>\r\n</Envelope>');
        Observer.Verify();
    end;

    // Three text levels with namespaces, one row.
    [Test]
    procedure XTV_Root3TextsNamespaces_Export()
    begin
        SeedA(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97953, TextEncoding::UTF8));
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/">\r\n  <tem:L2>\r\n    <tem:L1>\r\n      <tem:L0>\r\n        <order xmlns="urn:microsoft-dynamics-nav/xmlports/x97953">\r\n          <No>O1</No>\r\n        </order>\r\n        <username xmlns="urn:microsoft-dynamics-nav/xmlports/x97953">x</username>\r\n      </tem:L0>\r\n    </tem:L1>\r\n  </tem:L2>\r\n</Envelope>');
        Observer.Verify();
    end;

    // Three text levels with namespaces, two rows.
    [Test]
    procedure XTV_Root3TextsNamespaces2_Export()
    begin
        SeedA(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97953, TextEncoding::UTF8));
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns="http://schemas.xmlsoap.org/soap/envelope/">\r\n  <tem:L2>\r\n    <tem:L1>\r\n      <tem:L0>\r\n        <order xmlns="urn:microsoft-dynamics-nav/xmlports/x97953">\r\n          <No>O1</No>\r\n        </order>\r\n        <order xmlns="urn:microsoft-dynamics-nav/xmlports/x97953">\r\n          <No>O2</No>\r\n        </order>\r\n        <username xmlns="urn:microsoft-dynamics-nav/xmlports/x97953">x</username>\r\n      </tem:L0>\r\n    </tem:L1>\r\n  </tem:L2>\r\n</Envelope>');
        Observer.Verify();
    end;

    // Four text levels, table element then value.
    [Test]
    procedure XTV_Root4TextsTableThenValue_Export()
    begin
        SeedA(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97954, TextEncoding::UTF8));
        SeedA(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97954, TextEncoding::UTF8));
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <L3>\r\n    <L2>\r\n      <L1>\r\n        <L0>\r\n          <order>\r\n            <No>O1</No>\r\n          </order>\r\n          <username>x</username>\r\n        </L0>\r\n      </L1>\r\n    </L2>\r\n  </L3>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <L3>\r\n    <L2>\r\n      <L1>\r\n        <L0>\r\n          <order>\r\n            <No>O1</No>\r\n          </order>\r\n          <order>\r\n            <No>O2</No>\r\n          </order>\r\n          <username>x</username>\r\n        </L0>\r\n      </L1>\r\n    </L2>\r\n  </L3>\r\n</Envelope>');
        Observer.Verify();
    end;

    // Three text levels, value, table element, value.
    [Test]
    procedure XTV_Root3TextsTwoValues_Export()
    begin
        SeedA(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97955, TextEncoding::UTF8));
        SeedA(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97955, TextEncoding::UTF8));
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <L2>\r\n    <L1>\r\n      <L0>\r\n        <username>x</username>\r\n        <order>\r\n          <No>O1</No>\r\n        </order>\r\n        <password>y</password>\r\n      </L0>\r\n    </L1>\r\n  </L2>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <L2>\r\n    <L1>\r\n      <L0>\r\n        <username>x</username>\r\n        <order>\r\n          <No>O1</No>\r\n        </order>\r\n        <order>\r\n          <No>O2</No>\r\n        </order>\r\n        <password>y</password>\r\n      </L0>\r\n    </L1>\r\n  </L2>\r\n</Envelope>');
        Observer.Verify();
    end;

    // Two text levels, value, value, table element.
    [Test]
    procedure XTV_Root2TextsTwoValues_Export()
    begin
        SeedA(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97956, TextEncoding::UTF8));
        SeedA(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97956, TextEncoding::UTF8));
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <L1>\r\n    <L0>\r\n      <username>x</username>\r\n      <password>y</password>\r\n      <order>\r\n        <No>O1</No>\r\n      </order>\r\n    </L0>\r\n  </L1>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <L1>\r\n    <L0>\r\n      <username>x</username>\r\n      <password>y</password>\r\n      <order>\r\n        <No>O1</No>\r\n      </order>\r\n      <order>\r\n        <No>O2</No>\r\n      </order>\r\n    </L0>\r\n  </L1>\r\n</Envelope>');
        Observer.Verify();
    end;

    // Issue 7309: row text element with value, value, table element.
    [Test]
    procedure XTV_RowTextTwoValuesThenTable_Export()
    begin
        SeedB(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97957, TextEncoding::UTF8));
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97957, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97957, TextEncoding::UTF8));
        Observer.Expect('0 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <T1>x</T1>\r\n      <T2>y</T2>\r\n      <r>\r\n        <Ref />\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <T1>x</T1>\r\n      <T2>y</T2>\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <T1>x</T1>\r\n      <T2>y</T2>\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n      <r>\r\n        <Ref>R2</Ref>\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Verify();
    end;

    // Row text element with value, table element, value.
    [Test]
    procedure XTV_RowTextValueTableValue_Export()
    begin
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97958, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97958, TextEncoding::UTF8));
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <T1>x</T1>\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n      <T2>y</T2>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <T1>x</T1>\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n      <r>\r\n        <Ref>R2</Ref>\r\n      </r>\r\n      <T2>y</T2>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Verify();
    end;

    // Row text element with table element, value, value.
    [Test]
    procedure XTV_RowTextTableThenTwoValues_Export()
    begin
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97959, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97959, TextEncoding::UTF8));
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n      <T1>x</T1>\r\n      <T2>y</T2>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n      <r>\r\n        <Ref>R2</Ref>\r\n      </r>\r\n      <T1>x</T1>\r\n      <T2>y</T2>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Verify();
    end;

    // Row text element with three values, table element.
    [Test]
    procedure XTV_RowTextThreeValuesThenTable_Export()
    begin
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97960, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97960, TextEncoding::UTF8));
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <T1>x</T1>\r\n      <T2>y</T2>\r\n      <T3>z</T3>\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <T1>x</T1>\r\n      <T2>y</T2>\r\n      <T3>z</T3>\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n      <r>\r\n        <Ref>R2</Ref>\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Verify();
    end;

    // Row text element with value, empty value, table element.
    [Test]
    procedure XTV_RowTextValueEmptyThenTable_Export()
    begin
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97961, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97961, TextEncoding::UTF8));
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <T1>x</T1>\r\n      <T2 />\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <T1>x</T1>\r\n      <T2 />\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n      <r>\r\n        <Ref>R2</Ref>\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Verify();
    end;

    // Two text levels in the row, value, value, table element.
    [Test]
    procedure XTV_RowDeepTwoValuesThenTable_Export()
    begin
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97962, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97962, TextEncoding::UTF8));
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <TJ>\r\n        <T1>x</T1>\r\n        <T2>y</T2>\r\n        <r>\r\n          <Ref>R1</Ref>\r\n        </r>\r\n      </TJ>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <TJ>\r\n        <T1>x</T1>\r\n        <T2>y</T2>\r\n        <r>\r\n          <Ref>R1</Ref>\r\n        </r>\r\n        <r>\r\n          <Ref>R2</Ref>\r\n        </r>\r\n      </TJ>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Verify();
    end;

    // Three text levels in the row, value, table element.
    [Test]
    procedure XTV_RowDeep3OneValueThenTable_Export()
    begin
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97963, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97963, TextEncoding::UTF8));
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <TJ>\r\n        <TK>\r\n          <T1>x</T1>\r\n          <r>\r\n            <Ref>R1</Ref>\r\n          </r>\r\n        </TK>\r\n      </TJ>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <TJ>\r\n        <TK>\r\n          <T1>x</T1>\r\n          <r>\r\n            <Ref>R1</Ref>\r\n          </r>\r\n          <r>\r\n            <Ref>R2</Ref>\r\n          </r>\r\n        </TK>\r\n      </TJ>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Verify();
    end;

    // Field element, value, value, table element.
    [Test]
    procedure XTV_RowFieldTwoValuesThenTable_Export()
    begin
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97964, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97964, TextEncoding::UTF8));
        Observer.Expect('1 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <No>O1</No>\r\n      <T1>x</T1>\r\n      <T2>y</T2>\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Expect('2 rows', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope>\r\n  <orders>\r\n    <TI>\r\n      <No>O1</No>\r\n      <T1>x</T1>\r\n      <T2>y</T2>\r\n      <r>\r\n        <Ref>R1</Ref>\r\n      </r>\r\n      <r>\r\n        <Ref>R2</Ref>\r\n      </r>\r\n    </TI>\r\n  </orders>\r\n</Envelope>');
        Observer.Verify();
    end;

    // Issue 7349: TI > [RD > [value], table element] (issue 7349 R1).
    [Test]
    procedure XTN_R1_Export()
    begin
        SeedB(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97965, TextEncoding::UTF8));
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97965, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97965, TextEncoding::UTF8));
        Observer.Finish();
    end;

    // Issue 7349: TI > [table element, RD > [value]] (R2).
    [Test]
    procedure XTN_R2_Export()
    begin
        SeedB(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97966, TextEncoding::UTF8));
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97966, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97966, TextEncoding::UTF8));
        Observer.Finish();
    end;

    // Issue 7349: TI > [RD > [field element, value], table element] (R3).
    [Test]
    procedure XTN_R3_Export()
    begin
        SeedB(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97967, TextEncoding::UTF8));
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97967, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97967, TextEncoding::UTF8));
        Observer.Finish();
    end;

    // Issue 7349: TI > [RD > [value], table element, RE > [value]].
    [Test]
    procedure XTN_Around_Export()
    begin
        SeedB(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97968, TextEncoding::UTF8));
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97968, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97968, TextEncoding::UTF8));
        Observer.Finish();
    end;

    // Issue 7349: TI > [RD > [value], RE > [value], table element].
    [Test]
    procedure XTN_TwoTexts_Export()
    begin
        SeedB(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97969, TextEncoding::UTF8));
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97969, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97969, TextEncoding::UTF8));
        Observer.Finish();
    end;

    // Issue 7349: TI > [RD > [field element, value], table element r, table element q].
    [Test]
    procedure XTN_TwoTables_Export()
    begin
        SeedB(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97970, TextEncoding::UTF8));
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97970, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97970, TextEncoding::UTF8));
        Observer.Finish();
    end;

    // Issue 7349: TI > [value, RD > [value], table element, value].
    [Test]
    procedure XTN_Mixed_Export()
    begin
        SeedB(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97971, TextEncoding::UTF8));
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97971, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97971, TextEncoding::UTF8));
        Observer.Finish();
    end;

    // Issue 7349: TI > TJ > [RD > [value], table element].
    [Test]
    procedure XTN_DeepTable_Export()
    begin
        SeedB(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97972, TextEncoding::UTF8));
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97972, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97972, TextEncoding::UTF8));
        Observer.Finish();
    end;

    // Issue 7349: TI > [RD > RC > [value], table element].
    [Test]
    procedure XTN_DeepValue_Export()
    begin
        SeedB(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97973, TextEncoding::UTF8));
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97973, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97973, TextEncoding::UTF8));
        Observer.Finish();
    end;

    // Issue 7349: TI > [field element, value, RD > [field element, value], table element, RE > [field element, value]].
    [Test]
    procedure XTN_FieldValueAround_Export()
    begin
        SeedB(0);
        Observer.Observe('0 rows', Helper.TryExportRaw(97974, TextEncoding::UTF8));
        SeedB(1);
        Observer.Observe('1 rows', Helper.TryExportRaw(97974, TextEncoding::UTF8));
        SeedB(2);
        Observer.Observe('2 rows', Helper.TryExportRaw(97974, TextEncoding::UTF8));
        Observer.Finish();
    end;
}

// Probe: al-runner issue 7349 (follow-up to 7309). Export of a row text element TI that holds a text element with content (a value
//   element, or a field element and a value element) and a table element, in several orders, with 0, 1 and 2 rows of the inner table
//   element. Objects xmlport 97965-97974; the tests are XTN_*.

// TI > [RD > [value], table element] (issue 7349 R1)
xmlport 97965 "LT X63 Y R1"
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
                    textelement(RD)
                    {
                        textelement(TT)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                TT := 'x';
                            end;
                        }
                    }
                    tableelement(r; "LT X63 Ref")
                    {
                        XmlName = 'r';
                        fieldelement(Ref; r."Ref") { }
                    }
                }
            }
        }
    }
}

// TI > [table element, RD > [value]] (R2)
xmlport 97966 "LT X63 Y R2"
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
                    tableelement(r; "LT X63 Ref")
                    {
                        XmlName = 'r';
                        fieldelement(Ref; r."Ref") { }
                    }
                    textelement(RD)
                    {
                        textelement(TT)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                TT := 'x';
                            end;
                        }
                    }
                }
            }
        }
    }
}

// TI > [RD > [field element, value], table element] (R3)
xmlport 97967 "LT X63 Y R3"
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
                    textelement(RD)
                    {
                        fieldelement(D; orders."No.") { }
                        textelement(TT)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                TT := 'x';
                            end;
                        }
                    }
                    tableelement(r; "LT X63 Ref")
                    {
                        XmlName = 'r';
                        fieldelement(Ref; r."Ref") { }
                    }
                }
            }
        }
    }
}

// TI > [RD > [value], table element, RE > [value]]
xmlport 97968 "LT X63 Y Around"
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
                    textelement(RD)
                    {
                        textelement(TT)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                TT := 'x';
                            end;
                        }
                    }
                    tableelement(r; "LT X63 Ref")
                    {
                        XmlName = 'r';
                        fieldelement(Ref; r."Ref") { }
                    }
                    textelement(RE)
                    {
                        textelement(TU)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                TU := 'y';
                            end;
                        }
                    }
                }
            }
        }
    }
}

// TI > [RD > [value], RE > [value], table element]
xmlport 97969 "LT X63 Y Two Texts"
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
                    textelement(RD)
                    {
                        textelement(TT)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                TT := 'x';
                            end;
                        }
                    }
                    textelement(RE)
                    {
                        textelement(TU)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                TU := 'y';
                            end;
                        }
                    }
                    tableelement(r; "LT X63 Ref")
                    {
                        XmlName = 'r';
                        fieldelement(Ref; r."Ref") { }
                    }
                }
            }
        }
    }
}

// TI > [RD > [field element, value], table element r, table element q]
xmlport 97970 "LT X63 Y Two Tables"
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
                    textelement(RD)
                    {
                        fieldelement(D; orders."No.") { }
                        textelement(TT)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                TT := 'x';
                            end;
                        }
                    }
                    tableelement(r; "LT X63 Ref")
                    {
                        XmlName = 'r';
                        fieldelement(Ref; r."Ref") { }
                    }
                    tableelement(q; "LT X63 Ref")
                    {
                        XmlName = 'q';
                        fieldelement(Ref; q."Ref") { }
                    }
                }
            }
        }
    }
}

// TI > [value, RD > [value], table element, value]
xmlport 97971 "LT X63 Y Mixed"
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
                            T1 := 'a';
                        end;
                    }
                    textelement(RD)
                    {
                        textelement(TT)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                TT := 'x';
                            end;
                        }
                    }
                    tableelement(r; "LT X63 Ref")
                    {
                        XmlName = 'r';
                        fieldelement(Ref; r."Ref") { }
                    }
                    textelement(T2)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            T2 := 'b';
                        end;
                    }
                }
            }
        }
    }
}

// TI > TJ > [RD > [value], table element]
xmlport 97972 "LT X63 Y Deep Table"
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
                    textelement(TJ)
                    {
                        textelement(RD)
                        {
                            textelement(TT)
                            {
                                trigger OnBeforePassVariable()
                                begin
                                    TT := 'x';
                                end;
                            }
                        }
                        tableelement(r; "LT X63 Ref")
                        {
                            XmlName = 'r';
                            fieldelement(Ref; r."Ref") { }
                        }
                    }
                }
            }
        }
    }
}

// TI > [RD > RC > [value], table element]
xmlport 97973 "LT X63 Y Deep Value"
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
                    textelement(RD)
                    {
                        textelement(RC)
                        {
                            textelement(TT)
                            {
                                trigger OnBeforePassVariable()
                                begin
                                    TT := 'x';
                                end;
                            }
                        }
                    }
                    tableelement(r; "LT X63 Ref")
                    {
                        XmlName = 'r';
                        fieldelement(Ref; r."Ref") { }
                    }
                }
            }
        }
    }
}

// TI > [field element, value, RD > [field element, value], table element, RE > [field element, value]]
xmlport 97974 "LT X63 Y Field Value Around"
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
                    fieldelement(D1; orders."No.") { }
                    textelement(T1)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            T1 := 'a';
                        end;
                    }
                    textelement(RD)
                    {
                        fieldelement(D2; orders."No.") { }
                        textelement(TT)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                TT := 'x';
                            end;
                        }
                    }
                    tableelement(r; "LT X63 Ref")
                    {
                        XmlName = 'r';
                        fieldelement(Ref; r."Ref") { }
                    }
                    textelement(RE)
                    {
                        fieldelement(D3; orders."No.") { }
                        textelement(TU)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                TU := 'y';
                            end;
                        }
                    }
                }
            }
        }
    }
}
