// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-skip-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Temp Blob (System Application).
// Probe (al-runner issue 8032, item 2): an XMLport import whose table element (the header) has a linked child table element
//   (LinkTable, LinkFields) and calls currXMLport.Skip() in its OnBeforeInsertRecord, which runs after the child rows were read.
//   Cells: the reporter's port (temporary header, Skip when Header.Get fails) through the static Xmlport.Import and through an
//   instance; a temporary header that is never skipped (control); one of two headers skipped; a skipped header with no lines;
//   a non-temporary header always skipped and never skipped. Observed: the child rows stored (Header Code, Line No., Amount),
//   the header rows kept, and the order of the insert triggers.
// BC versions: 27, 28, 29

// local object: the test checks the rows an import of this exact table shape stores.
table 91020 "XP Skip Header"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { }
    }
    keys { key(PK; "Code") { Clustered = true; } }
}

// local object: the linked child table of the import.
table 91021 "XP Skip Line"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Header Code"; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Amount; Integer) { }
    }
    keys { key(PK; "Header Code", "Line No.") { Clustered = true; } }
}

// local object: the reporter's port. Mode 0 (default) = skip when Header.Get fails, 1 = never skip, 2 = skip header H1 only.
xmlport 91020 "XP Skip Temp Header"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Header; "XP Skip Header")
            {
                SourceTableView = sorting("Code");
                UseTemporary = true;
                fieldattribute(Code; Header."Code") { }
                fieldattribute(Name; Header.Name) { }

                tableelement(Line; "XP Skip Line")
                {
                    LinkTable = Header;
                    LinkFields = "Header Code" = field("Code");
                    fieldattribute(LineNo; Line."Line No.") { }
                    fieldattribute(Amount; Line.Amount) { }

                    trigger OnBeforeInsertRecord()
                    begin
                        Trace += 'L' + Format(Line."Line No.") + '(' + Line."Header Code" + ') ';
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    Trace += 'H' + Header."Code" + ' ';
                    case Mode of
                        0:
                            if not Header.Get(Header."Code") then
                                currXMLport.Skip();
                        2:
                            if Header."Code" = 'H1' then
                                currXMLport.Skip();
                    end;
                end;

                trigger OnAfterInsertRecord()
                begin
                    Trace += 'h' + Header."Code" + ' ';
                end;
            }
        }
    }

    var
        Mode: Integer;
        Trace: Text;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetTrace(): Text
    begin
        exit(Trace.TrimEnd());
    end;

    procedure HeaderRows() Result: Text
    begin
        Header.Reset();
        if Header.FindSet() then
            repeat
                Result += Header."Code" + ':' + Header.Name + ';';
            until Header.Next() = 0;
    end;
}

// local object: the same port with a non-temporary header. Mode 0 (default) = always skip, 1 = never skip.
xmlport 91021 "XP Skip Real Header"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Header; "XP Skip Header")
            {
                fieldattribute(Code; Header."Code") { }
                fieldattribute(Name; Header.Name) { }

                tableelement(Line; "XP Skip Line")
                {
                    LinkTable = Header;
                    LinkFields = "Header Code" = field("Code");
                    fieldattribute(LineNo; Line."Line No.") { }
                    fieldattribute(Amount; Line.Amount) { }

                    trigger OnBeforeInsertRecord()
                    begin
                        Trace += 'L' + Format(Line."Line No.") + '(' + Line."Header Code" + ') ';
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    Trace += 'H' + Header."Code" + ' ';
                    if Mode = 0 then
                        currXMLport.Skip();
                end;

                trigger OnAfterInsertRecord()
                begin
                    Trace += 'h' + Header."Code" + ' ';
                end;
            }
        }
    }

    var
        Mode: Integer;
        Trace: Text;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure GetTrace(): Text
    begin
        exit(Trace.TrimEnd());
    end;
}

codeunit 91020 "XP Skip Linked Header"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        OneHeaderTwoLinesTok: Label '<Root><Header Code="H1" Name="First"><Line LineNo="1" Amount="5"/><Line LineNo="2" Amount="7"/></Header></Root>', Locked = true;
        TwoHeadersTok: Label '<Root><Header Code="H1" Name="First"><Line LineNo="1" Amount="5"/><Line LineNo="2" Amount="7"/></Header><Header Code="H2" Name="Second"><Line LineNo="1" Amount="9"/></Header></Root>', Locked = true;
        NoLinesTok: Label '<Root><Header Code="H1" Name="First"/></Root>', Locked = true;

    // The reporter's call: static Xmlport.Import, temporary header skipped (Get fails), two lines.
    [Test]
    procedure Skip_TempHeaderWithLines_Static()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        Initialize();
        Prepare(TempBlob, OneHeaderTwoLinesTok, InS);
        Xmlport.Import(Xmlport::"XP Skip Temp Header", InS);
        Observer.Observe('lines', LineRows());
        Observer.Observe('real_headers', RealHeaderRows());
        Observer.Finish();
    end;

    // The same through an instance: the temporary header rows kept and the trigger order.
    [Test]
    procedure Skip_TempHeaderWithLines_Instance()
    begin
        RunTemp('guard', 0, OneHeaderTwoLinesTok);
    end;

    // Control: the temporary header is never skipped.
    [Test]
    procedure Skip_TempHeaderNever_Instance()
    begin
        RunTemp('never', 1, OneHeaderTwoLinesTok);
    end;

    // Two headers, the first (with two lines) skipped, the second (one line) kept.
    [Test]
    procedure Skip_FirstOfTwoTempHeaders_Instance()
    begin
        RunTemp('first_of_two', 2, TwoHeadersTok);
    end;

    // The reporter's guard on a header with no lines.
    [Test]
    procedure Skip_TempHeaderNoLines_Instance()
    begin
        RunTemp('no_lines', 0, NoLinesTok);
    end;

    // A non-temporary header, always skipped.
    [Test]
    procedure Skip_RealHeaderWithLines_Instance()
    begin
        RunReal('real_skip', 0);
    end;

    // Control: a non-temporary header, never skipped.
    [Test]
    procedure Skip_RealHeaderNever_Instance()
    begin
        RunReal('real_never', 1);
    end;

    local procedure RunTemp(Name: Text; Mode: Integer; Xml: Text)
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "XP Skip Temp Header";
        InS: InStream;
    begin
        Initialize();
        Prepare(TempBlob, Xml, InS);
        Port.SetMode(Mode);
        Port.SetSource(InS);
        Port.Import();
        Observer.Observe(Name + '|lines', LineRows());
        Observer.Observe(Name + '|temp_headers', Port.HeaderRows());
        Observer.Observe(Name + '|real_headers', RealHeaderRows());
        Observer.Observe(Name + '|trace', Port.GetTrace());
        Observer.Finish();
    end;

    local procedure RunReal(Name: Text; Mode: Integer)
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "XP Skip Real Header";
        InS: InStream;
    begin
        Initialize();
        Prepare(TempBlob, OneHeaderTwoLinesTok, InS);
        Port.SetMode(Mode);
        Port.SetSource(InS);
        Port.Import();
        Observer.Observe(Name + '|lines', LineRows());
        Observer.Observe(Name + '|real_headers', RealHeaderRows());
        Observer.Observe(Name + '|trace', Port.GetTrace());
        Observer.Finish();
    end;

    local procedure Initialize()
    var
        Header: Record "XP Skip Header";
        Line: Record "XP Skip Line";
    begin
        Header.DeleteAll();
        Line.DeleteAll();
    end;

    local procedure Prepare(var TempBlob: Codeunit "Temp Blob"; Xml: Text; var InS: InStream)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Xml);
        TempBlob.CreateInStream(InS);
    end;

    local procedure LineRows() Result: Text
    var
        Line: Record "XP Skip Line";
    begin
        if Line.FindSet() then
            repeat
                Result += Line."Header Code" + '/' + Format(Line."Line No.") + '/' + Format(Line.Amount) + ';';
            until Line.Next() = 0;
    end;

    local procedure RealHeaderRows() Result: Text
    var
        Header: Record "XP Skip Header";
    begin
        if Header.FindSet() then
            repeat
                Result += Header."Code" + ':' + Header.Name + ';';
            until Header.Next() = 0;
    end;
}
