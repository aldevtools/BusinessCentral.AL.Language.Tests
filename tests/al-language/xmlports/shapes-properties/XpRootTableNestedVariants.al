// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minoccurs-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-filename-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 50000 "ALT Shape 00" (root table element), table 50001 "ALT Shape 01" (the
//   Filename port), table 60008 "ALT Blob" (temporary, the source stream); tables 75120 "XP Root Table Header" and 75121 "XP Root Table
//   Line" from XpRootTableNested.al; own table 75126, xmlports 75127-75133, test codeunit 75134.
// local object: the schemas of the ports are what is under test; table 75126 has Code, Text, Decimal and Date fields that take empty
//   elements, and no fixture table has that shape.
// Probe (observe only): al-runner issue 6924 (outside reporter's port) and 7714. XpRootTableNested.al measured an Xml import whose root
//   is a table element (MinOccurs = Once, MaxOccurs = Once) holding a header table element; there the line table element declares no
//   MinOccurs or MaxOccurs, the text element that wraps the lines is the last child of the header, and only missing elements of Code
//   fields were tried. The reporter's port differs; each port below changes one of these:
//     Wrap Last     the reporter's port as written: every element declares MinOccurs and MaxOccurs, the line table element MinOccurs =
//                   Once and MaxOccurs = Unbounded, the wrapper text element Body last
//     Undeclared    no MinOccurs or MaxOccurs on the root, the header and the wrapper (only MinOccurs = Zero where the document may
//                   leave an element out); the line table element declares MinOccurs = Once and MaxOccurs = Unbounded
//     Line Min Zero Wrap Last with MinOccurs = Zero on the line table element (a Body without lines)
//     Wrap First    the wrapper is the first child of the header
//     Wrap Middle   the wrapper sits after CustomerID, before ShipToCode
//     Empty         field elements of type Code, Text, Decimal and Date (MinOccurs = Once and Zero) and text elements, each sent as an
//                   empty element, as a self-closing element and left out; OnAfterInitRecord first sets every field and text element
//                   to a marker value, so a value that stays shows the element was not assigned
//     Filename      `currXMLport.Filename := ...` in OnPreXmlPort of an Xml import and export (al-runner 7714; the VariableText export is
//                   pinned in codeunits/procedures/AssignIsCallRule.al U16 and U17)
//   The documents follow the reporter's: declaration ISO-8859-1 written with TextEncoding::Windows and the port's TextEncoding set to
//   Windows, LF and two spaces between the elements, empty ShipToCode and Location, `if not Port.Import() then`.
// BC versions: 27, 28, 29 (corpus CI)

table 75126 "XP RTV Empty Header"
{
    // local object: Code, Text, Decimal and Date fields next to an Integer key, each once required and once optional in the port.
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Cust; Code[20]) { }
        field(3; Note; Text[50]) { }
        field(4; Amount; Decimal) { }
        field(5; DocDate; Date) { }
        field(6; OptCode; Code[10]) { }
        field(7; OptAmount; Decimal) { }
        field(8; OptDate; Date) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

xmlport 75127 "XP RTV Wrap Last"
{
    // local object: the reporter's schema (every element declares MinOccurs and MaxOccurs, Body last) is under test.
    Format = Xml;
    FormatEvaluate = Xml;

    schema
    {
        tableelement(Envelop; "ALT Shape 00")
        {
            UseTemporary = true;
            MinOccurs = Once;
            MaxOccurs = Once;

            tableelement(Head; "XP Root Table Header")
            {
                UseTemporary = true;
                MinOccurs = Once;
                MaxOccurs = Unbounded;

                textelement(DocType)
                {
                    XmlName = 'Type';
                    MinOccurs = Once;
                    MaxOccurs = Once;
                }
                fieldelement(CustomerID; Head.Customer)
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;
                }
                fieldelement(ShipToCode; Head."Ship-to Code")
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                textelement(OrderDate)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                textelement(DeliveryDate)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                fieldelement(Reference; Head.Reference)
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;
                }
                fieldelement(Location; Head."Location Code")
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                textelement(Body)
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;

                    tableelement(Line; "XP Root Table Line")
                    {
                        UseTemporary = true;
                        MinOccurs = Once;
                        MaxOccurs = Unbounded;

                        fieldelement(ItemID; Line.Item)
                        {
                            MinOccurs = Once;
                            MaxOccurs = Once;
                        }
                        fieldelement(Qty; Line.Quantity)
                        {
                            MinOccurs = Once;
                            MaxOccurs = Once;
                        }
                        fieldelement(Description; Line.Description)
                        {
                            MinOccurs = Zero;
                            MaxOccurs = Once;
                        }
                        fieldelement(Price; Line."Unit Price")
                        {
                            MinOccurs = Zero;
                            MaxOccurs = Once;
                        }
                        fieldelement(DiscountPercentage; Line."Discount Pct")
                        {
                            MinOccurs = Zero;
                            MaxOccurs = Once;
                        }

                        trigger OnBeforeInsertRecord()
                        begin
                            LineNo += 1;
                            Line."Entry No." := LineNo;
                            Line."Header No." := Head."Entry No.";
                            Add('L.bins:' + Line.Item + '/hdr=' + Format(Head."Entry No.") + '/kind=[' + DocType + ']/cust=[' + Head.Customer + ']/ref=[' + Head.Reference + ']/od=[' + OrderDate + ']');
                        end;
                    }
                }

                trigger OnAfterInitRecord()
                begin
                    HeaderNo += 1;
                    Head."Entry No." := HeaderNo;
                    Add('H.init:' + Format(HeaderNo) + '/kind=[' + DocType + ']/od=[' + OrderDate + ']/dd=[' + DeliveryDate + ']/body=[' + Body + ']');
                end;

                trigger OnAfterInsertRecord()
                begin
                    Add('H.ains:' + Format(Head."Entry No.") + '/kind=[' + DocType + ']/od=[' + OrderDate + ']/dd=[' + DeliveryDate + ']/body=[' + Body + ']');
                end;
            }
        }
    }

    trigger OnInitXmlPort()
    begin
        ClearLastError();
        Add('init');
    end;

    trigger OnPreXmlPort()
    begin
        ClearLastError();
        Add('pre');
    end;

    trigger OnPostXmlPort()
    begin
        Add('post');
    end;

    var
        Log: Text;
        HeaderNo: Integer;
        LineNo: Integer;

    local procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;

    procedure Roots(): Text
    var
        Result: Text;
    begin
        Envelop.Reset();
        if Envelop.FindSet() then
            repeat
                Result += Format(Envelop.Id) + ';';
            until Envelop.Next() = 0;
        exit(Format(Envelop.Count()) + ':' + Result);
    end;

    procedure Headers(): Text
    var
        Result: Text;
    begin
        Head.Reset();
        if Head.FindSet() then
            repeat
                Result += Format(Head."Entry No.") + '/' + Head.Customer + '/[' + Head."Ship-to Code" + ']/' + Head.Reference + '/[' + Head."Location Code" + '];';
            until Head.Next() = 0;
        exit(Format(Head.Count()) + ':' + Result);
    end;

    procedure LinesDump(): Text
    var
        Result: Text;
    begin
        Line.Reset();
        if Line.FindSet() then
            repeat
                Result += Format(Line."Entry No.") + '/' + Format(Line."Header No.") + '/' + Line.Item + '/' + Format(Line.Quantity, 0, 9) + '/' + Line.Description + '/' +
                  Format(Line."Unit Price", 0, 9) + '/' + Format(Line."Discount Pct", 0, 9) + ';';
            until Line.Next() = 0;
        exit(Format(Line.Count()) + ':' + Result);
    end;
}

xmlport 75128 "XP RTV Undeclared"
{
    // local object: its schema (no MinOccurs or MaxOccurs on root, header and wrapper; explicit on the line) is under test.
    Format = Xml;
    FormatEvaluate = Xml;

    schema
    {
        tableelement(Envelop; "ALT Shape 00")
        {
            UseTemporary = true;

            tableelement(Head; "XP Root Table Header")
            {
                UseTemporary = true;

                textelement(DocType)
                {
                    XmlName = 'Type';
                }
                fieldelement(CustomerID; Head.Customer) { }
                fieldelement(ShipToCode; Head."Ship-to Code")
                {
                    MinOccurs = Zero;
                }
                textelement(OrderDate)
                {
                    MinOccurs = Zero;
                }
                textelement(DeliveryDate)
                {
                    MinOccurs = Zero;
                }
                fieldelement(Reference; Head.Reference) { }
                fieldelement(Location; Head."Location Code")
                {
                    MinOccurs = Zero;
                }
                textelement(Body)
                {
                    tableelement(Line; "XP Root Table Line")
                    {
                        UseTemporary = true;
                        MinOccurs = Once;
                        MaxOccurs = Unbounded;

                        fieldelement(ItemID; Line.Item) { }
                        fieldelement(Qty; Line.Quantity) { }
                        fieldelement(Description; Line.Description)
                        {
                            MinOccurs = Zero;
                        }
                        fieldelement(Price; Line."Unit Price")
                        {
                            MinOccurs = Zero;
                        }
                        fieldelement(DiscountPercentage; Line."Discount Pct")
                        {
                            MinOccurs = Zero;
                        }

                        trigger OnBeforeInsertRecord()
                        begin
                            LineNo += 1;
                            Line."Entry No." := LineNo;
                            Line."Header No." := Head."Entry No.";
                            Add('L.bins:' + Line.Item + '/hdr=' + Format(Head."Entry No.") + '/kind=[' + DocType + ']/cust=[' + Head.Customer + ']/ref=[' + Head.Reference + ']/od=[' + OrderDate + ']');
                        end;
                    }
                }

                trigger OnAfterInitRecord()
                begin
                    HeaderNo += 1;
                    Head."Entry No." := HeaderNo;
                    Add('H.init:' + Format(HeaderNo) + '/kind=[' + DocType + ']/od=[' + OrderDate + ']/dd=[' + DeliveryDate + ']/body=[' + Body + ']');
                end;

                trigger OnAfterInsertRecord()
                begin
                    Add('H.ains:' + Format(Head."Entry No.") + '/kind=[' + DocType + ']/od=[' + OrderDate + ']/dd=[' + DeliveryDate + ']/body=[' + Body + ']');
                end;
            }
        }
    }

    trigger OnInitXmlPort()
    begin
        ClearLastError();
        Add('init');
    end;

    trigger OnPreXmlPort()
    begin
        ClearLastError();
        Add('pre');
    end;

    trigger OnPostXmlPort()
    begin
        Add('post');
    end;

    var
        Log: Text;
        HeaderNo: Integer;
        LineNo: Integer;

    local procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;

    procedure Roots(): Text
    var
        Result: Text;
    begin
        Envelop.Reset();
        if Envelop.FindSet() then
            repeat
                Result += Format(Envelop.Id) + ';';
            until Envelop.Next() = 0;
        exit(Format(Envelop.Count()) + ':' + Result);
    end;

    procedure Headers(): Text
    var
        Result: Text;
    begin
        Head.Reset();
        if Head.FindSet() then
            repeat
                Result += Format(Head."Entry No.") + '/' + Head.Customer + '/[' + Head."Ship-to Code" + ']/' + Head.Reference + '/[' + Head."Location Code" + '];';
            until Head.Next() = 0;
        exit(Format(Head.Count()) + ':' + Result);
    end;

    procedure LinesDump(): Text
    var
        Result: Text;
    begin
        Line.Reset();
        if Line.FindSet() then
            repeat
                Result += Format(Line."Entry No.") + '/' + Format(Line."Header No.") + '/' + Line.Item + '/' + Format(Line.Quantity, 0, 9) + '/' + Line.Description + '/' +
                  Format(Line."Unit Price", 0, 9) + '/' + Format(Line."Discount Pct", 0, 9) + ';';
            until Line.Next() = 0;
        exit(Format(Line.Count()) + ':' + Result);
    end;
}

xmlport 75129 "XP RTV Line Min Zero"
{
    // local object: its schema (the line table element with MinOccurs = Zero) is under test.
    Format = Xml;
    FormatEvaluate = Xml;

    schema
    {
        tableelement(Envelop; "ALT Shape 00")
        {
            UseTemporary = true;
            MinOccurs = Once;
            MaxOccurs = Once;

            tableelement(Head; "XP Root Table Header")
            {
                UseTemporary = true;
                MinOccurs = Once;
                MaxOccurs = Unbounded;

                textelement(DocType)
                {
                    XmlName = 'Type';
                    MinOccurs = Once;
                    MaxOccurs = Once;
                }
                fieldelement(CustomerID; Head.Customer)
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;
                }
                fieldelement(ShipToCode; Head."Ship-to Code")
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                textelement(OrderDate)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                textelement(DeliveryDate)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                fieldelement(Reference; Head.Reference)
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;
                }
                fieldelement(Location; Head."Location Code")
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                textelement(Body)
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;

                    tableelement(Line; "XP Root Table Line")
                    {
                        UseTemporary = true;
                        MinOccurs = Zero;
                        MaxOccurs = Unbounded;

                        fieldelement(ItemID; Line.Item)
                        {
                            MinOccurs = Once;
                            MaxOccurs = Once;
                        }
                        fieldelement(Qty; Line.Quantity)
                        {
                            MinOccurs = Once;
                            MaxOccurs = Once;
                        }
                        fieldelement(Description; Line.Description)
                        {
                            MinOccurs = Zero;
                            MaxOccurs = Once;
                        }
                        fieldelement(Price; Line."Unit Price")
                        {
                            MinOccurs = Zero;
                            MaxOccurs = Once;
                        }
                        fieldelement(DiscountPercentage; Line."Discount Pct")
                        {
                            MinOccurs = Zero;
                            MaxOccurs = Once;
                        }

                        trigger OnBeforeInsertRecord()
                        begin
                            LineNo += 1;
                            Line."Entry No." := LineNo;
                            Line."Header No." := Head."Entry No.";
                            Add('L.bins:' + Line.Item + '/hdr=' + Format(Head."Entry No.") + '/kind=[' + DocType + ']/cust=[' + Head.Customer + ']/ref=[' + Head.Reference + ']/od=[' + OrderDate + ']');
                        end;
                    }
                }

                trigger OnAfterInitRecord()
                begin
                    HeaderNo += 1;
                    Head."Entry No." := HeaderNo;
                    Add('H.init:' + Format(HeaderNo) + '/kind=[' + DocType + ']/od=[' + OrderDate + ']/dd=[' + DeliveryDate + ']/body=[' + Body + ']');
                end;

                trigger OnAfterInsertRecord()
                begin
                    Add('H.ains:' + Format(Head."Entry No.") + '/kind=[' + DocType + ']/od=[' + OrderDate + ']/dd=[' + DeliveryDate + ']/body=[' + Body + ']');
                end;
            }
        }
    }

    trigger OnInitXmlPort()
    begin
        ClearLastError();
        Add('init');
    end;

    trigger OnPreXmlPort()
    begin
        ClearLastError();
        Add('pre');
    end;

    trigger OnPostXmlPort()
    begin
        Add('post');
    end;

    var
        Log: Text;
        HeaderNo: Integer;
        LineNo: Integer;

    local procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;

    procedure Roots(): Text
    var
        Result: Text;
    begin
        Envelop.Reset();
        if Envelop.FindSet() then
            repeat
                Result += Format(Envelop.Id) + ';';
            until Envelop.Next() = 0;
        exit(Format(Envelop.Count()) + ':' + Result);
    end;

    procedure Headers(): Text
    var
        Result: Text;
    begin
        Head.Reset();
        if Head.FindSet() then
            repeat
                Result += Format(Head."Entry No.") + '/' + Head.Customer + '/[' + Head."Ship-to Code" + ']/' + Head.Reference + '/[' + Head."Location Code" + '];';
            until Head.Next() = 0;
        exit(Format(Head.Count()) + ':' + Result);
    end;

    procedure LinesDump(): Text
    var
        Result: Text;
    begin
        Line.Reset();
        if Line.FindSet() then
            repeat
                Result += Format(Line."Entry No.") + '/' + Format(Line."Header No.") + '/' + Line.Item + '/' + Format(Line.Quantity, 0, 9) + '/' + Line.Description + '/' +
                  Format(Line."Unit Price", 0, 9) + '/' + Format(Line."Discount Pct", 0, 9) + ';';
            until Line.Next() = 0;
        exit(Format(Line.Count()) + ':' + Result);
    end;
}

xmlport 75130 "XP RTV Wrap First"
{
    // local object: its schema (the wrapper text element first under the header) is under test.
    Format = Xml;
    FormatEvaluate = Xml;

    schema
    {
        tableelement(Envelop; "ALT Shape 00")
        {
            UseTemporary = true;
            MinOccurs = Once;
            MaxOccurs = Once;

            tableelement(Head; "XP Root Table Header")
            {
                UseTemporary = true;
                MinOccurs = Once;
                MaxOccurs = Unbounded;

                textelement(Body)
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;

                    tableelement(Line; "XP Root Table Line")
                    {
                        UseTemporary = true;
                        MinOccurs = Once;
                        MaxOccurs = Unbounded;

                        fieldelement(ItemID; Line.Item)
                        {
                            MinOccurs = Once;
                            MaxOccurs = Once;
                        }
                        fieldelement(Qty; Line.Quantity)
                        {
                            MinOccurs = Once;
                            MaxOccurs = Once;
                        }
                        fieldelement(Description; Line.Description)
                        {
                            MinOccurs = Zero;
                            MaxOccurs = Once;
                        }
                        fieldelement(Price; Line."Unit Price")
                        {
                            MinOccurs = Zero;
                            MaxOccurs = Once;
                        }
                        fieldelement(DiscountPercentage; Line."Discount Pct")
                        {
                            MinOccurs = Zero;
                            MaxOccurs = Once;
                        }

                        trigger OnBeforeInsertRecord()
                        begin
                            LineNo += 1;
                            Line."Entry No." := LineNo;
                            Line."Header No." := Head."Entry No.";
                            Add('L.bins:' + Line.Item + '/hdr=' + Format(Head."Entry No.") + '/kind=[' + DocType + ']/cust=[' + Head.Customer + ']/ref=[' + Head.Reference + ']/od=[' + OrderDate + ']');
                        end;
                    }
                }
                textelement(DocType)
                {
                    XmlName = 'Type';
                    MinOccurs = Once;
                    MaxOccurs = Once;
                }
                fieldelement(CustomerID; Head.Customer)
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;
                }
                fieldelement(ShipToCode; Head."Ship-to Code")
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                textelement(OrderDate)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                textelement(DeliveryDate)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                fieldelement(Reference; Head.Reference)
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;
                }
                fieldelement(Location; Head."Location Code")
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }

                trigger OnAfterInitRecord()
                begin
                    HeaderNo += 1;
                    Head."Entry No." := HeaderNo;
                    Add('H.init:' + Format(HeaderNo) + '/kind=[' + DocType + ']/od=[' + OrderDate + ']/dd=[' + DeliveryDate + ']/body=[' + Body + ']');
                end;

                trigger OnAfterInsertRecord()
                begin
                    Add('H.ains:' + Format(Head."Entry No.") + '/kind=[' + DocType + ']/od=[' + OrderDate + ']/dd=[' + DeliveryDate + ']/body=[' + Body + ']');
                end;
            }
        }
    }

    trigger OnInitXmlPort()
    begin
        ClearLastError();
        Add('init');
    end;

    trigger OnPreXmlPort()
    begin
        ClearLastError();
        Add('pre');
    end;

    trigger OnPostXmlPort()
    begin
        Add('post');
    end;

    var
        Log: Text;
        HeaderNo: Integer;
        LineNo: Integer;

    local procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;

    procedure Roots(): Text
    var
        Result: Text;
    begin
        Envelop.Reset();
        if Envelop.FindSet() then
            repeat
                Result += Format(Envelop.Id) + ';';
            until Envelop.Next() = 0;
        exit(Format(Envelop.Count()) + ':' + Result);
    end;

    procedure Headers(): Text
    var
        Result: Text;
    begin
        Head.Reset();
        if Head.FindSet() then
            repeat
                Result += Format(Head."Entry No.") + '/' + Head.Customer + '/[' + Head."Ship-to Code" + ']/' + Head.Reference + '/[' + Head."Location Code" + '];';
            until Head.Next() = 0;
        exit(Format(Head.Count()) + ':' + Result);
    end;

    procedure LinesDump(): Text
    var
        Result: Text;
    begin
        Line.Reset();
        if Line.FindSet() then
            repeat
                Result += Format(Line."Entry No.") + '/' + Format(Line."Header No.") + '/' + Line.Item + '/' + Format(Line.Quantity, 0, 9) + '/' + Line.Description + '/' +
                  Format(Line."Unit Price", 0, 9) + '/' + Format(Line."Discount Pct", 0, 9) + ';';
            until Line.Next() = 0;
        exit(Format(Line.Count()) + ':' + Result);
    end;
}

xmlport 75131 "XP RTV Wrap Middle"
{
    // local object: its schema (the wrapper text element between the header's leaf elements) is under test.
    Format = Xml;
    FormatEvaluate = Xml;

    schema
    {
        tableelement(Envelop; "ALT Shape 00")
        {
            UseTemporary = true;
            MinOccurs = Once;
            MaxOccurs = Once;

            tableelement(Head; "XP Root Table Header")
            {
                UseTemporary = true;
                MinOccurs = Once;
                MaxOccurs = Unbounded;

                textelement(DocType)
                {
                    XmlName = 'Type';
                    MinOccurs = Once;
                    MaxOccurs = Once;
                }
                fieldelement(CustomerID; Head.Customer)
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;
                }
                textelement(Body)
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;

                    tableelement(Line; "XP Root Table Line")
                    {
                        UseTemporary = true;
                        MinOccurs = Once;
                        MaxOccurs = Unbounded;

                        fieldelement(ItemID; Line.Item)
                        {
                            MinOccurs = Once;
                            MaxOccurs = Once;
                        }
                        fieldelement(Qty; Line.Quantity)
                        {
                            MinOccurs = Once;
                            MaxOccurs = Once;
                        }
                        fieldelement(Description; Line.Description)
                        {
                            MinOccurs = Zero;
                            MaxOccurs = Once;
                        }
                        fieldelement(Price; Line."Unit Price")
                        {
                            MinOccurs = Zero;
                            MaxOccurs = Once;
                        }
                        fieldelement(DiscountPercentage; Line."Discount Pct")
                        {
                            MinOccurs = Zero;
                            MaxOccurs = Once;
                        }

                        trigger OnBeforeInsertRecord()
                        begin
                            LineNo += 1;
                            Line."Entry No." := LineNo;
                            Line."Header No." := Head."Entry No.";
                            Add('L.bins:' + Line.Item + '/hdr=' + Format(Head."Entry No.") + '/kind=[' + DocType + ']/cust=[' + Head.Customer + ']/ref=[' + Head.Reference + ']/od=[' + OrderDate + ']');
                        end;
                    }
                }
                fieldelement(ShipToCode; Head."Ship-to Code")
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                textelement(OrderDate)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                textelement(DeliveryDate)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                fieldelement(Reference; Head.Reference)
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;
                }
                fieldelement(Location; Head."Location Code")
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }

                trigger OnAfterInitRecord()
                begin
                    HeaderNo += 1;
                    Head."Entry No." := HeaderNo;
                    Add('H.init:' + Format(HeaderNo) + '/kind=[' + DocType + ']/od=[' + OrderDate + ']/dd=[' + DeliveryDate + ']/body=[' + Body + ']');
                end;

                trigger OnAfterInsertRecord()
                begin
                    Add('H.ains:' + Format(Head."Entry No.") + '/kind=[' + DocType + ']/od=[' + OrderDate + ']/dd=[' + DeliveryDate + ']/body=[' + Body + ']');
                end;
            }
        }
    }

    trigger OnInitXmlPort()
    begin
        ClearLastError();
        Add('init');
    end;

    trigger OnPreXmlPort()
    begin
        ClearLastError();
        Add('pre');
    end;

    trigger OnPostXmlPort()
    begin
        Add('post');
    end;

    var
        Log: Text;
        HeaderNo: Integer;
        LineNo: Integer;

    local procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;

    procedure Roots(): Text
    var
        Result: Text;
    begin
        Envelop.Reset();
        if Envelop.FindSet() then
            repeat
                Result += Format(Envelop.Id) + ';';
            until Envelop.Next() = 0;
        exit(Format(Envelop.Count()) + ':' + Result);
    end;

    procedure Headers(): Text
    var
        Result: Text;
    begin
        Head.Reset();
        if Head.FindSet() then
            repeat
                Result += Format(Head."Entry No.") + '/' + Head.Customer + '/[' + Head."Ship-to Code" + ']/' + Head.Reference + '/[' + Head."Location Code" + '];';
            until Head.Next() = 0;
        exit(Format(Head.Count()) + ':' + Result);
    end;

    procedure LinesDump(): Text
    var
        Result: Text;
    begin
        Line.Reset();
        if Line.FindSet() then
            repeat
                Result += Format(Line."Entry No.") + '/' + Format(Line."Header No.") + '/' + Line.Item + '/' + Format(Line.Quantity, 0, 9) + '/' + Line.Description + '/' +
                  Format(Line."Unit Price", 0, 9) + '/' + Format(Line."Discount Pct", 0, 9) + ';';
            until Line.Next() = 0;
        exit(Format(Line.Count()) + ':' + Result);
    end;
}

xmlport 75132 "XP RTV Empty"
{
    // local object: its schema (field elements of four types and text elements, required and optional, that receive empty elements) is under test.
    Format = Xml;
    FormatEvaluate = Xml;

    schema
    {
        tableelement(Envelop; "ALT Shape 00")
        {
            UseTemporary = true;
            MinOccurs = Once;
            MaxOccurs = Once;

            tableelement(Head; "XP RTV Empty Header")
            {
                UseTemporary = true;
                MinOccurs = Once;
                MaxOccurs = Unbounded;

                fieldelement(Cust; Head.Cust) { MinOccurs = Once; MaxOccurs = Once; }
                fieldelement(Note; Head.Note) { MinOccurs = Once; MaxOccurs = Once; }
                fieldelement(Amount; Head.Amount) { MinOccurs = Once; MaxOccurs = Once; }
                fieldelement(DocDate; Head.DocDate) { MinOccurs = Once; MaxOccurs = Once; }
                textelement(Tag) { MinOccurs = Once; MaxOccurs = Once; }
                fieldelement(OptCode; Head.OptCode) { MinOccurs = Zero; MaxOccurs = Once; }
                fieldelement(OptAmount; Head.OptAmount) { MinOccurs = Zero; MaxOccurs = Once; }
                fieldelement(OptDate; Head.OptDate) { MinOccurs = Zero; MaxOccurs = Once; }
                textelement(OptTag) { MinOccurs = Zero; MaxOccurs = Once; }
                textelement(Body)
                {
                    MinOccurs = Once;
                    MaxOccurs = Once;

                    tableelement(Line; "XP Root Table Line")
                    {
                        UseTemporary = true;
                        MinOccurs = Once;
                        MaxOccurs = Unbounded;

                        fieldelement(ItemID; Line.Item) { MinOccurs = Once; MaxOccurs = Once; }
                        fieldelement(Description; Line.Description) { MinOccurs = Zero; MaxOccurs = Once; }

                        trigger OnBeforeInsertRecord()
                        begin
                            LineNo += 1;
                            Line."Entry No." := LineNo;
                            Line."Header No." := Head."Entry No.";
                        end;
                    }
                }

                trigger OnAfterInitRecord()
                begin
                    HeaderNo += 1;
                    Head."Entry No." := HeaderNo;
                    Head.Cust := 'INIT';
                    Head.Note := 'init note';
                    Head.Amount := 7;
                    Head.DocDate := 20000101D;
                    Head.OptCode := 'INITOPT';
                    Head.OptAmount := 8;
                    Head.OptDate := 20000102D;
                    Tag := 'init tag';
                    OptTag := 'init opt tag';
                    Add('H.init:' + Format(HeaderNo));
                end;

                trigger OnAfterInsertRecord()
                begin
                    Add('H.ains:' + Format(Head."Entry No.") + '/tag=[' + Tag + ']/opttag=[' + OptTag + ']');
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        Add('pre');
    end;

    trigger OnPostXmlPort()
    begin
        Add('post');
    end;

    var
        Log: Text;
        HeaderNo: Integer;
        LineNo: Integer;

    local procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;

    procedure Headers(): Text
    var
        Result: Text;
    begin
        Head.Reset();
        if Head.FindSet() then
            repeat
                Result += Format(Head."Entry No.") + '/cust=[' + Head.Cust + ']/note=[' + Head.Note + ']/amount=[' + Format(Head.Amount, 0, 9) +
                  ']/date=[' + Format(Head.DocDate, 0, 9) + ']/optcode=[' + Head.OptCode + ']/optamount=[' + Format(Head.OptAmount, 0, 9) +
                  ']/optdate=[' + Format(Head.OptDate, 0, 9) + '];';
            until Head.Next() = 0;
        exit(Format(Head.Count()) + ':' + Result);
    end;

    procedure LineCount(): Integer
    begin
        Line.Reset();
        exit(Line.Count());
    end;
}

xmlport 75133 "XP RTV Filename"
{
    // local object: an Xml port whose OnPreXmlPort assigns currXMLport.Filename is under test (al-runner 7714).
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Shape 01")
            {
                UseTemporary = true;

                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        Add('pre: ' + currXMLport.Filename());
        currXMLport.Filename := 'probe.xml';
        Add('pre, after assign: ' + currXMLport.Filename());
    end;

    trigger OnPostXmlPort()
    begin
        Add('post: ' + currXMLport.Filename());
    end;

    var
        Log: Text;

    local procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure GetLog(): Text
    begin
        exit(Log);
    end;

    procedure Fill()
    begin
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
    end;

    procedure Rows(): Text
    var
        Result: Text;
    begin
        Row.Reset();
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + '/' + Row.Name + ';';
            until Row.Next() = 0;
        exit(Format(Row.Count()) + ':' + Result);
    end;
}

codeunit 75134 "XP RTV Tests"
{
    Subtype = Test;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Initialize()
    var
        Cleanup: Codeunit ALTFixtureCleanup;
    begin
        Cleanup.Initialize();
        Commit();
    end;

    local procedure Lf(): Text
    var
        C: Char;
    begin
        C := 10;
        exit(Format(C));
    end;

    local procedure Sp(Depth: Integer): Text
    begin
        exit(PadStr('', Depth * 2));
    end;

    local procedure WriteSource(var Src: Record "ALT Blob" temporary; Doc: Text; Enc: TextEncoding; var InS: InStream)
    var
        OutS: OutStream;
    begin
        Src.Init();
        Src.Code := 'SRC';
        Src.Data.CreateOutStream(OutS, Enc);
        OutS.WriteText(Doc);
        Src.Insert();
        Src.Data.CreateInStream(InS);
    end;

    local procedure ReadAll(var InS: InStream): Text
    var
        Part: Text;
        Result: Text;
    begin
        while not InS.EOS() do begin
            InS.ReadText(Part);
            if Result <> '' then
                Result += '|';
            Result += Part;
        end;
        exit(Result);
    end;

    local procedure LineXml(Item: Text; Qty: Text; Descr: Text; Price: Text; Disc: Text): Text
    begin
        exit(Sp(3) + '<Line><ItemID>' + Item + '</ItemID><Qty>' + Qty + '</Qty><Description>' + Descr + '</Description><Price>' + Price +
          '</Price><DiscountPercentage>' + Disc + '</DiscountPercentage></Line>' + Lf());
    end;

    local procedure TwoLines(): Text
    begin
        exit(LineXml('ITEM001', '2', 'first line', '6.32', '100') + LineXml('ITEM002', '10', 'second line', '1.5', '0'));
    end;

    // One Head element. Pos: 1 Body first, 2 Body after CustomerID, 3 Body last. Full: with ShipToCode (empty), OrderDate and DeliveryDate
    // and an empty Location; otherwise without those three and with Location BLUE. LinesXml '' gives <Body></Body>, '<sc>' gives <Body/>.
    local procedure HeadXml(Pos: Integer; Kind: Text; Customer: Text; Reference: Text; Full: Boolean; LinesXml: Text): Text
    var
        First: Text;
        Rest: Text;
        Body: Text;
    begin
        First := Sp(2) + '<Type>' + Kind + '</Type>' + Lf() + Sp(2) + '<CustomerID>' + Customer + '</CustomerID>' + Lf();
        if Full then
            Rest := Sp(2) + '<ShipToCode></ShipToCode>' + Lf() + Sp(2) + '<OrderDate>20200326</OrderDate>' + Lf() +
              Sp(2) + '<DeliveryDate>20200327</DeliveryDate>' + Lf() + Sp(2) + '<Reference>' + Reference + '</Reference>' + Lf() +
              Sp(2) + '<Location></Location>' + Lf()
        else
            Rest := Sp(2) + '<Reference>' + Reference + '</Reference>' + Lf() + Sp(2) + '<Location>BLUE</Location>' + Lf();
        case LinesXml of
            '':
                Body := Sp(2) + '<Body></Body>' + Lf();
            '<sc>':
                Body := Sp(2) + '<Body/>' + Lf();
            else
                Body := Sp(2) + '<Body>' + Lf() + LinesXml + Sp(2) + '</Body>' + Lf();
        end;
        case Pos of
            1:
                exit(Sp(1) + '<Head>' + Lf() + Body + First + Rest + Sp(1) + '</Head>' + Lf());
            2:
                exit(Sp(1) + '<Head>' + Lf() + First + Body + Rest + Sp(1) + '</Head>' + Lf());
        end;
        exit(Sp(1) + '<Head>' + Lf() + First + Rest + Body + Sp(1) + '</Head>' + Lf());
    end;

    local procedure EnvelopDoc(Heads: Text): Text
    begin
        exit('<?xml version=''1.0'' encoding=''ISO-8859-1''?>' + Lf() + '<Envelop>' + Lf() + Heads + '</Envelop>' + Lf());
    end;

    local procedure IssueDoc(Pos: Integer): Text
    begin
        exit(EnvelopDoc(HeadXml(Pos, 'Order', 'K10000', 'TR_ORDER_04', true, TwoLines())));
    end;

    local procedure TwoHeaderDoc(Pos: Integer): Text
    begin
        exit(EnvelopDoc(HeadXml(Pos, 'Order', 'K10000', 'TR_ORDER_04', true, TwoLines()) +
          HeadXml(Pos, 'Return', 'K20000', 'TR_ORDER_05', false, LineXml('ITEM003', '3', 'third line', '2', '5'))));
    end;
    // Imports Doc through variant port Which (1 Wrap Last, 2 Undeclared, 3 Line Min Zero, 4 Wrap First, 5 Wrap Middle) with the
    // reporter's call: TextEncoding Windows, SetSource over a Blob, `if not Import() then`. Every observation gets the prefix P.
    local procedure ImportVariant(Which: Integer; P: Text; Doc: Text)
    var
        Src: Record "ALT Blob" temporary;
        Port1: XmlPort "XP RTV Wrap Last";
        Port2: XmlPort "XP RTV Undeclared";
        Port3: XmlPort "XP RTV Line Min Zero";
        Port4: XmlPort "XP RTV Wrap First";
        Port5: XmlPort "XP RTV Wrap Middle";
        InS: InStream;
        Ok: Boolean;
        ErrText: Text;
        ErrCode: Text;
        LogText: Text;
        RootsText: Text;
        HeadersText: Text;
        LinesText: Text;
    begin
        WriteSource(Src, Doc, TextEncoding::Windows, InS);
        case Which of
            1:
                begin
                    Port1.TextEncoding := TextEncoding::Windows;
                    Port1.SetSource(InS);
                    if not Port1.Import() then begin
                        ErrText := GetLastErrorText();
                        ErrCode := GetLastErrorCode();
                    end else
                        Ok := true;
                    LogText := Port1.GetLog();
                    RootsText := Port1.Roots();
                    HeadersText := Port1.Headers();
                    LinesText := Port1.LinesDump();
                end;
            2:
                begin
                    Port2.TextEncoding := TextEncoding::Windows;
                    Port2.SetSource(InS);
                    if not Port2.Import() then begin
                        ErrText := GetLastErrorText();
                        ErrCode := GetLastErrorCode();
                    end else
                        Ok := true;
                    LogText := Port2.GetLog();
                    RootsText := Port2.Roots();
                    HeadersText := Port2.Headers();
                    LinesText := Port2.LinesDump();
                end;
            3:
                begin
                    Port3.TextEncoding := TextEncoding::Windows;
                    Port3.SetSource(InS);
                    if not Port3.Import() then begin
                        ErrText := GetLastErrorText();
                        ErrCode := GetLastErrorCode();
                    end else
                        Ok := true;
                    LogText := Port3.GetLog();
                    RootsText := Port3.Roots();
                    HeadersText := Port3.Headers();
                    LinesText := Port3.LinesDump();
                end;
            4:
                begin
                    Port4.TextEncoding := TextEncoding::Windows;
                    Port4.SetSource(InS);
                    if not Port4.Import() then begin
                        ErrText := GetLastErrorText();
                        ErrCode := GetLastErrorCode();
                    end else
                        Ok := true;
                    LogText := Port4.GetLog();
                    RootsText := Port4.Roots();
                    HeadersText := Port4.Headers();
                    LinesText := Port4.LinesDump();
                end;
            5:
                begin
                    Port5.TextEncoding := TextEncoding::Windows;
                    Port5.SetSource(InS);
                    if not Port5.Import() then begin
                        ErrText := GetLastErrorText();
                        ErrCode := GetLastErrorCode();
                    end else
                        Ok := true;
                    LogText := Port5.GetLog();
                    RootsText := Port5.Roots();
                    HeadersText := Port5.Headers();
                    LinesText := Port5.LinesDump();
                end;
        end;
        Observer.Observe(P + 'import', Format(Ok));
        if not Ok then begin
            Observer.Observe(P + 'error|text', ErrText);
            Observer.Observe(P + 'error|code', ErrCode);
        end;
        Observer.Observe(P + 'log', LogText);
        Observer.Observe(P + 'roots', RootsText);
        Observer.Observe(P + 'headers', HeadersText);
        Observer.Observe(P + 'lines', LinesText);
    end;

    // One element of the Empty port: its value, or empty when its name is in Empty, self-closing when 'sc:' + its name is, or left out
    // when Empty is 'missing' and the element is optional.
    local procedure El(Name: Text; Value: Text; Optional: Boolean; Empty: Text): Text
    begin
        if Optional and (Empty = 'missing') then
            exit('');
        if ('sc:' + Name) = Empty then
            exit(Sp(2) + '<' + Name + '/>' + Lf());
        if StrPos(',' + Empty + ',', ',' + Name + ',') > 0 then
            exit(Sp(2) + '<' + Name + '></' + Name + '>' + Lf());
        exit(Sp(2) + '<' + Name + '>' + Value + '</' + Name + '>' + Lf());
    end;

    local procedure ImportEmpty(Empty: Text)
    var
        Src: Record "ALT Blob" temporary;
        Port: XmlPort "XP RTV Empty";
        InS: InStream;
        Doc: Text;
    begin
        Doc := '<?xml version=''1.0'' encoding=''ISO-8859-1''?>' + Lf() + '<Envelop>' + Lf() + Sp(1) + '<Head>' + Lf() +
          El('Cust', 'C1', false, Empty) + El('Note', 'a note', false, Empty) + El('Amount', '12.5', false, Empty) +
          El('DocDate', '2024-03-15', false, Empty) + El('Tag', 'T1', false, Empty) + El('OptCode', 'BLUE', true, Empty) +
          El('OptAmount', '3.25', true, Empty) + El('OptDate', '2024-03-16', true, Empty) + El('OptTag', 'T2', true, Empty) +
          Sp(2) + '<Body>' + Lf() + Sp(3) + '<Line><ItemID>ITEM001</ItemID><Description>d</Description></Line>' + Lf() + Sp(2) + '</Body>' + Lf() +
          Sp(1) + '</Head>' + Lf() + '</Envelop>' + Lf();
        WriteSource(Src, Doc, TextEncoding::Windows, InS);
        Port.TextEncoding := TextEncoding::Windows;
        Port.SetSource(InS);
        if not Port.Import() then begin
            Observer.Observe('import', 'false');
            Observer.ObserveError('error');
        end else
            Observer.Observe('import', 'true');
        Observer.Observe('log', Port.GetLog());
        Observer.Observe('headers', Port.Headers());
        Observer.Observe('lines', Format(Port.LineCount()));
    end;

    // Port WrapLast: the reporter's document (one header, two lines, empty ShipToCode and Location).
    [Test]
    procedure RTV_WrapLast_IssueDoc_Import()
    begin
        Initialize();
        ImportVariant(1, '', IssueDoc(3));
        Observer.Finish();
    end;

    // Port WrapLast: a second header without ShipToCode, OrderDate and DeliveryDate, with a Location and one line.
    [Test]
    procedure RTV_WrapLast_TwoHeaders_Import()
    begin
        Initialize();
        ImportVariant(1, '', TwoHeaderDoc(3));
        Observer.Finish();
    end;

    // Port Undeclared: the reporter's document (one header, two lines, empty ShipToCode and Location).
    [Test]
    procedure RTV_Undeclared_IssueDoc_Import()
    begin
        Initialize();
        ImportVariant(2, '', IssueDoc(3));
        Observer.Finish();
    end;

    // Port Undeclared: a second header without ShipToCode, OrderDate and DeliveryDate, with a Location and one line.
    [Test]
    procedure RTV_Undeclared_TwoHeaders_Import()
    begin
        Initialize();
        ImportVariant(2, '', TwoHeaderDoc(3));
        Observer.Finish();
    end;

    // Port LineMinZero: the reporter's document (one header, two lines, empty ShipToCode and Location).
    [Test]
    procedure RTV_LineMinZero_IssueDoc_Import()
    begin
        Initialize();
        ImportVariant(3, '', IssueDoc(3));
        Observer.Finish();
    end;

    // Port LineMinZero: a second header without ShipToCode, OrderDate and DeliveryDate, with a Location and one line.
    [Test]
    procedure RTV_LineMinZero_TwoHeaders_Import()
    begin
        Initialize();
        ImportVariant(3, '', TwoHeaderDoc(3));
        Observer.Finish();
    end;

    // Port WrapFirst: the reporter's document (one header, two lines, empty ShipToCode and Location).
    [Test]
    procedure RTV_WrapFirst_IssueDoc_Import()
    begin
        Initialize();
        ImportVariant(4, '', IssueDoc(1));
        Observer.Finish();
    end;

    // Port WrapFirst: a second header without ShipToCode, OrderDate and DeliveryDate, with a Location and one line.
    [Test]
    procedure RTV_WrapFirst_TwoHeaders_Import()
    begin
        Initialize();
        ImportVariant(4, '', TwoHeaderDoc(1));
        Observer.Finish();
    end;

    // Port WrapMiddle: the reporter's document (one header, two lines, empty ShipToCode and Location).
    [Test]
    procedure RTV_WrapMiddle_IssueDoc_Import()
    begin
        Initialize();
        ImportVariant(5, '', IssueDoc(2));
        Observer.Finish();
    end;

    // Port WrapMiddle: a second header without ShipToCode, OrderDate and DeliveryDate, with a Location and one line.
    [Test]
    procedure RTV_WrapMiddle_TwoHeaders_Import()
    begin
        Initialize();
        ImportVariant(5, '', TwoHeaderDoc(2));
        Observer.Finish();
    end;

    // Port WrapLast: a header whose Body element is empty (no Line).
    [Test]
    procedure RTV_WrapLast_EmptyBody_Import()
    begin
        Initialize();
        ImportVariant(1, '', EnvelopDoc(HeadXml(3, 'Order', 'K10000', 'TR_ORDER_04', true, '')));
        Observer.Finish();
    end;

    // Port Undeclared: a header whose Body element is empty (no Line).
    [Test]
    procedure RTV_Undeclared_EmptyBody_Import()
    begin
        Initialize();
        ImportVariant(2, '', EnvelopDoc(HeadXml(3, 'Order', 'K10000', 'TR_ORDER_04', true, '')));
        Observer.Finish();
    end;

    // Port LineMinZero: a header whose Body element is empty (no Line).
    [Test]
    procedure RTV_LineMinZero_EmptyBody_Import()
    begin
        Initialize();
        ImportVariant(3, '', EnvelopDoc(HeadXml(3, 'Order', 'K10000', 'TR_ORDER_04', true, '')));
        Observer.Finish();
    end;

    // Port LineMinZero: a header whose Body is a self-closing element.
    [Test]
    procedure RTV_LineMinZero_SelfClosingBody_Import()
    begin
        Initialize();
        ImportVariant(3, '', EnvelopDoc(HeadXml(3, 'Order', 'K10000', 'TR_ORDER_04', true, '<sc>')));
        Observer.Finish();
    end;

    // Port WrapFirst: the document has Body last (the order of the other ports).
    [Test]
    procedure RTV_WrapFirst_BodyLastInDoc_Import()
    begin
        Initialize();
        ImportVariant(4, '', IssueDoc(3));
        Observer.Finish();
    end;

    // Port WrapLast: the document has Body first.
    [Test]
    procedure RTV_WrapLast_BodyFirstInDoc_Import()
    begin
        Initialize();
        ImportVariant(1, '', IssueDoc(1));
        Observer.Finish();
    end;

    // Port Empty: every element has a value (control).
    [Test]
    procedure RTV_Empty_AllValued_Import()
    begin
        Initialize();
        ImportEmpty('');
        Observer.Finish();
    end;

    // Port Empty: OptCode, OptAmount, OptDate and OptTag left out.
    [Test]
    procedure RTV_Empty_OptionalMissing_Import()
    begin
        Initialize();
        ImportEmpty('missing');
        Observer.Finish();
    end;

    // Port Empty: the required Code field element empty.
    [Test]
    procedure RTV_Empty_Code_Import()
    begin
        Initialize();
        ImportEmpty('Cust');
        Observer.Finish();
    end;

    // Port Empty: the required Text field element empty.
    [Test]
    procedure RTV_Empty_Text_Import()
    begin
        Initialize();
        ImportEmpty('Note');
        Observer.Finish();
    end;

    // Port Empty: the required Decimal field element empty.
    [Test]
    procedure RTV_Empty_Decimal_Import()
    begin
        Initialize();
        ImportEmpty('Amount');
        Observer.Finish();
    end;

    // Port Empty: the required Date field element empty.
    [Test]
    procedure RTV_Empty_Date_Import()
    begin
        Initialize();
        ImportEmpty('DocDate');
        Observer.Finish();
    end;

    // Port Empty: the required text element empty.
    [Test]
    procedure RTV_Empty_TextElement_Import()
    begin
        Initialize();
        ImportEmpty('Tag');
        Observer.Finish();
    end;

    // Port Empty: the optional Code field element empty.
    [Test]
    procedure RTV_Empty_OptCode_Import()
    begin
        Initialize();
        ImportEmpty('OptCode');
        Observer.Finish();
    end;

    // Port Empty: the optional Decimal field element empty.
    [Test]
    procedure RTV_Empty_OptDecimal_Import()
    begin
        Initialize();
        ImportEmpty('OptAmount');
        Observer.Finish();
    end;

    // Port Empty: the optional Date field element empty.
    [Test]
    procedure RTV_Empty_OptDate_Import()
    begin
        Initialize();
        ImportEmpty('OptDate');
        Observer.Finish();
    end;

    // Port Empty: the optional text element empty.
    [Test]
    procedure RTV_Empty_OptTextElement_Import()
    begin
        Initialize();
        ImportEmpty('OptTag');
        Observer.Finish();
    end;

    // Port Empty: the required Code field element self-closing.
    [Test]
    procedure RTV_Empty_SelfClosingCode_Import()
    begin
        Initialize();
        ImportEmpty('sc:Cust');
        Observer.Finish();
    end;

    // Port Empty: the required Decimal field element self-closing.
    [Test]
    procedure RTV_Empty_SelfClosingDecimal_Import()
    begin
        Initialize();
        ImportEmpty('sc:Amount');
        Observer.Finish();
    end;

    // Port Empty: the required Date field element self-closing.
    [Test]
    procedure RTV_Empty_SelfClosingDate_Import()
    begin
        Initialize();
        ImportEmpty('sc:DocDate');
        Observer.Finish();
    end;

    // Port Empty: the required text element self-closing.
    [Test]
    procedure RTV_Empty_SelfClosingTextElement_Import()
    begin
        Initialize();
        ImportEmpty('sc:Tag');
        Observer.Finish();
    end;

    // Port Empty: every Code, Text and text element empty, Decimal and Date valued.
    [Test]
    procedure RTV_Empty_AllEmptyText_Import()
    begin
        Initialize();
        ImportEmpty('Cust,Note,Tag,OptCode,OptTag');
        Observer.Finish();
    end;

    // Port Filename (al-runner 7714): an Xml import from an InStream; OnPreXmlPort assigns Filename.
    [Test]
    procedure RTV_Filename_OnPre_Import()
    var
        Src: Record "ALT Blob" temporary;
        Port: XmlPort "XP RTV Filename";
        InS: InStream;
    begin
        Initialize();
        WriteSource(Src, '<Root><Row><Id>1</Id><Name>one</Name></Row><Row><Id>2</Id><Name>two</Name></Row></Root>', TextEncoding::UTF8, InS);
        Port.SetSource(InS);
        if Port.Import() then
            Observer.Observe('import', 'true')
        else begin
            Observer.Observe('import', 'false');
            Observer.ObserveError('error');
        end;
        Observer.Observe('log', Port.GetLog());
        Observer.Observe('rows', Port.Rows());
        Observer.Observe('filename after', Port.Filename());
        Observer.Finish();
    end;

    // Port Filename (al-runner 7714): an Xml export to an OutStream; OnPreXmlPort assigns Filename.
    [Test]
    procedure RTV_Filename_OnPre_Export()
    var
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "XP RTV Filename";
        OutS: OutStream;
        InS: InStream;
    begin
        Initialize();
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Port.Fill();
        Port.SetDestination(OutS);
        if Port.Export() then
            Observer.Observe('export', 'true')
        else begin
            Observer.Observe('export', 'false');
            Observer.ObserveError('error');
        end;
        Observer.Observe('log', Port.GetLog());
        Observer.Observe('filename after', Port.Filename());
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('content', ReadAll(InS));
        Observer.Finish();
    end;
}
