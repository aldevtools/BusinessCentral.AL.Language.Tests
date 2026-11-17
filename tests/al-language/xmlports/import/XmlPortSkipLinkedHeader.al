// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-skip-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Temp Blob (System Application).
// Probe (al-runner issue 8032, item 2): an XMLport import whose table element (the header) has a linked child table element
//   (LinkTable, LinkFields) and calls currXMLport.Skip() in its OnBeforeInsertRecord, which runs after the child rows were read.
//   Cells: the reporter's port (temporary header, Skip when Header.Get fails) through the static Xmlport.Import and through an
//   instance; a temporary header that is never skipped (control); one of two headers skipped; a skipped header with no lines;
//   a non-temporary header always skipped and never skipped. Observed: the child rows stored (Header Code, Line No., Amount),
//   the header rows kept, and the order of the insert triggers. Added: the same port with the line element optional
//   (MinOccurs = Zero) for the header with no lines.
// Measured on BC 27.5 and 28.5 (same result on both):
// - The header's OnBeforeInsertRecord runs before the line elements are read (trace "HH1 L1(H1) L2(H1)").
// - Skip() on the header, temporary or not, keeps the lines that follow it: both lines are stored with Header Code H1; the
//   header row is not kept and its OnAfterInsertRecord does not run. Static Xmlport.Import and an instance give the same rows.
// - Never skipped: the header row is kept, OnAfterInsertRecord runs before the lines ("HH1 hH1 L1(H1) L2(H1)").
// - Two headers, the first skipped: all three lines stored, only H2 kept.
// - A header with no lines and the line element at its default MinOccurs: Import raises "Imported XML cannot validate with the
//   schema: The element 'Header' has incomplete content. List of possible elements expected: 'Line'."
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
// local object: the reporter's port with the line element optional (MinOccurs = Zero), so a header with no lines passes the
// schema. Modes as "XP Skip Temp Header".
xmlport 91022 "XP Skip Temp Hdr Opt"
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
                    MinOccurs = Zero;
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
        Observer.Expect('lines', 'H1/1/5;H1/2/7;');
        Observer.Expect('real_headers', '');
        Observer.Verify();
    end;

    // The same through an instance: the temporary header rows kept and the trigger order.
    [Test]
    procedure Skip_TempHeaderWithLines_Instance()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTemp(Observer, 'guard', 0, OneHeaderTwoLinesTok);
        Observer.Expect('guard|lines', 'H1/1/5;H1/2/7;');
        Observer.Expect('guard|temp_headers', '');
        Observer.Expect('guard|real_headers', '');
        Observer.Expect('guard|trace', 'HH1 L1(H1) L2(H1)');
        Observer.Verify();
    end;

    // Control: the temporary header is never skipped.
    [Test]
    procedure Skip_TempHeaderNever_Instance()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTemp(Observer, 'never', 1, OneHeaderTwoLinesTok);
        Observer.Expect('never|lines', 'H1/1/5;H1/2/7;');
        Observer.Expect('never|temp_headers', 'H1:First;');
        Observer.Expect('never|real_headers', '');
        Observer.Expect('never|trace', 'HH1 hH1 L1(H1) L2(H1)');
        Observer.Verify();
    end;

    // Two headers, the first (with two lines) skipped, the second (one line) kept.
    [Test]
    procedure Skip_FirstOfTwoTempHeaders_Instance()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTemp(Observer, 'first_of_two', 2, TwoHeadersTok);
        Observer.Expect('first_of_two|lines', 'H1/1/5;H1/2/7;H2/1/9;');
        Observer.Expect('first_of_two|temp_headers', 'H2:Second;');
        Observer.Expect('first_of_two|real_headers', '');
        Observer.Expect('first_of_two|trace', 'HH1 L1(H1) L2(H1) HH2 hH2 L1(H2)');
        Observer.Verify();
    end;

    // The reporter's guard on a header with no lines.
    [Test]
    procedure Skip_TempHeaderNoLines_Instance()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "XP Skip Temp Header";
        InS: InStream;
    begin
        Initialize();
        Prepare(TempBlob, NoLinesTok, InS);
        Port.SetMode(0);
        Port.SetSource(InS);
        asserterror Port.Import();
        Observer.ObserveError('no_lines|import');
        Observer.Observe('no_lines|lines', LineRows());
        Observer.Observe('no_lines|real_headers', RealHeaderRows());
        Observer.Observe('no_lines|trace', Port.GetTrace());
        Observer.Finish();
    end;

    // The reporter's guard on a header with no lines, the line element optional: the schema accepts the header.
    [Test]
    procedure Skip_TempHeaderNoLinesOptional_Instance()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTempOpt(Observer, 'opt_no_lines', 0, NoLinesTok);
        Observer.Finish();
    end;

    // Control: the line element optional, a header with no lines, never skipped.
    [Test]
    procedure Skip_TempHeaderNoLinesOptionalNever_Instance()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTempOpt(Observer, 'opt_no_lines_never', 1, NoLinesTok);
        Observer.Finish();
    end;

    // The line element optional, a header with two lines, the reporter's guard.
    [Test]
    procedure Skip_TempHeaderWithLinesOptional_Instance()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTempOpt(Observer, 'opt_guard', 0, OneHeaderTwoLinesTok);
        Observer.Finish();
    end;

    // A non-temporary header, always skipped.
    [Test]
    procedure Skip_RealHeaderWithLines_Instance()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunReal(Observer, 'real_skip', 0);
        Observer.Expect('real_skip|lines', 'H1/1/5;H1/2/7;');
        Observer.Expect('real_skip|real_headers', '');
        Observer.Expect('real_skip|trace', 'HH1 L1(H1) L2(H1)');
        Observer.Verify();
    end;

    // Control: a non-temporary header, never skipped.
    [Test]
    procedure Skip_RealHeaderNever_Instance()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunReal(Observer, 'real_never', 1);
        Observer.Expect('real_never|lines', 'H1/1/5;H1/2/7;');
        Observer.Expect('real_never|real_headers', 'H1:First;');
        Observer.Expect('real_never|trace', 'HH1 hH1 L1(H1) L2(H1)');
        Observer.Verify();
    end;

    local procedure RunTemp(var Observer: Codeunit "Probe Observer"; Name: Text; Mode: Integer; Xml: Text)
    var
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
    end;

    local procedure RunTempOpt(var Observer: Codeunit "Probe Observer"; Name: Text; Mode: Integer; Xml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "XP Skip Temp Hdr Opt";
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
    end;

    local procedure RunReal(var Observer: Codeunit "Probe Observer"; Name: Text; Mode: Integer)
    var
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
