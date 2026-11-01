// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); xmlports 61100 and 61101 of AL Language XApp A (tests/al-language-xapp-a/Y66XaXmlPorts.al);
//   own xmlports 93500 and 93501, test codeunit 93503
// Probe (al-runner issue 6657, writer Y66): the members of an XmlPort variable. The reporter's shape (global procedure, SetTableView of a
// record with SetRecFilter, SetDestination, Export) on an XmlPort of another app and of the same app; the results of Export() and Import();
// every receiver kind: a local and a global variable, a var and a by-value parameter, an array element, the result of a procedure returning
// an XmlPort, X := Y and Clear(X) (is the state of the global procedure copied, shared or reset?); Export and Import twice on one variable;
// CurrentPath, ImportFile, TextEncoding and Filename of a variable that has not run.
// Pinned elsewhere: SetTableView + Export (xmlport/TestXmlPortExportImportContracts.al:124), instance Run (xml/lt-xmlport-run-export/
// XmlportRunExport.al:151), CurrentPath inside triggers (platform/lt-xmlport-session-navapp-cookie/P94XpPathFlow.al).
// Does not compile: X.Break(), X.BreakUnbound(), X.Quit(), X.Skip() on a variable (AL0161, tests/must-not-compile/cases/2642),
// X.UseRequestPage(..) (AL0132, case 2643).
// BC versions: 27, 28, 29

xmlport 93500 "LT Y66 XP Export"
{
    Format = Xml;
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textattribute(Flag)
            {
                trigger OnBeforePassVariable()
                begin
                    Flag := Format(MyFlag);
                end;
            }
            tableelement(I; Integer)
            {
                SourceTableView = sorting(Number);
                fieldelement(N; I.Number) { }
            }
        }
    }

    var
        MyFlag: Boolean;

    procedure MyProc(NewFlag: Boolean)
    begin
        MyFlag := NewFlag;
    end;

    procedure GetFlag(): Boolean
    begin
        exit(MyFlag);
    end;
}

xmlport 93501 "LT Y66 XP Import"
{
    Format = Xml;
    Direction = Import;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(N)
            {
                MinOccurs = Zero;
                MaxOccurs = Unbounded;

                trigger OnAfterAssignVariable()
                begin
                    Got += N + ';';
                end;
            }
        }
    }

    var
        Got: Text;

    procedure GetGot(): Text
    begin
        exit(Got);
    end;
}

codeunit 93503 "LT Y66 XmlPort Var Members"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        GlobalPort: XmlPort "LT Y66 XP Export";

    [Test]
    procedure Y66_XmlPortVar_ReporterShape_OtherApp()
    var
        TempBlob: Codeunit "Temp Blob";
        MyXmlPort: XmlPort "LT Y66 XA XP Export";
        MyRec: Record Integer;
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        MyRec.Number := 2;
        MyRec.SetRecFilter();
        MyXmlPort.MyProc(true);
        MyXmlPort.SetTableView(MyRec);
        MyXmlPort.SetDestination(OutStr);
        MyXmlPort.Export();
        Observer.Observe('xml', BlobText(TempBlob));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>/<Root Flag="Yes">/  <I>/    <N>2</N>/  </I>/</Root>/');
        Observer.Verify();
    end;

    [Test]
    procedure Y66_XmlPortVar_ReporterShape_SameApp()
    var
        TempBlob: Codeunit "Temp Blob";
        MyXmlPort: XmlPort "LT Y66 XP Export";
        MyRec: Record Integer;
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        MyRec.Number := 2;
        MyRec.SetRecFilter();
        MyXmlPort.MyProc(true);
        MyXmlPort.SetTableView(MyRec);
        MyXmlPort.SetDestination(OutStr);
        MyXmlPort.Export();
        Observer.Observe('xml', BlobText(TempBlob));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>/<Root Flag="Yes">/  <I>/    <N>2</N>/  </I>/</Root>/');
        Observer.Verify();
    end;

    [Test]
    procedure Y66_XmlPortVar_ExportImportResults()
    var
        TempBlob: Codeunit "Temp Blob";
        ExportPort: XmlPort "LT Y66 XA XP Export";
        ImportPort: XmlPort "LT Y66 XA XP Import";
        LocalImport: XmlPort "LT Y66 XP Import";
        MyRec: Record Integer;
        OutStr: OutStream;
        InStr: InStream;
        Ok: Boolean;
    begin
        TempBlob.CreateOutStream(OutStr);
        MyRec.SetRange(Number, 1, 2);
        ExportPort.SetTableView(MyRec);
        ExportPort.SetDestination(OutStr);
        Ok := ExportPort.Export();
        Observer.Observe('export result', Format(Ok));
        Observer.Observe('export flag', Format(ExportPort.GetFlag()));
        Observer.Observe('export xml', BlobText(TempBlob));
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('<Root><N>a</N><N>b</N></Root>');
        TempBlob.CreateInStream(InStr);
        ImportPort.SetSource(InStr);
        Ok := ImportPort.Import();
        Observer.Observe('import result', Format(Ok));
        Observer.Observe('import got', ImportPort.GetGot());
        TempBlob.CreateInStream(InStr);
        LocalImport.SetSource(InStr);
        LocalImport.Import();
        Observer.Observe('local import got', LocalImport.GetGot());
        Observer.Expect('export result', 'Yes');
        Observer.Expect('export flag', 'No');
        Observer.Expect('export xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>/<Root Flag="No">/  <I>/    <N>1</N>/  </I>/  <I>/    <N>2</N>/  </I>/</Root>/');
        Observer.Expect('import result', 'Yes');
        Observer.Expect('import got', 'a;b;');
        Observer.Expect('local import got', 'a;b;');
        Observer.Verify();
    end;

    [Test]
    procedure Y66_XmlPortVar_GlobalAndParameters()
    var
        Port: XmlPort "LT Y66 XP Export";
    begin
        GlobalPort.MyProc(true);
        Observer.Observe('global', ExportGlobal());
        SetFlagVar(Port);
        Observer.Observe('after var param', Format(Port.GetFlag()));
        Clear(Port);
        SetFlagValue(Port);
        Observer.Observe('after by-value param', Format(Port.GetFlag()));
        Port.MyProc(true);
        Observer.Observe('by-value param sees caller flag', ExportValue(Port));
        Observer.Observe('var param export', ExportVar(Port));
        Observer.Expect('global', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>/<Root Flag="Yes">/  <I>/    <N>3</N>/  </I>/</Root>/');
        Observer.Expect('after var param', 'Yes');
        Observer.Expect('after by-value param', 'Yes');
        Observer.Expect('by-value param sees caller flag', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>/<Root Flag="Yes">/  <I>/    <N>4</N>/  </I>/</Root>/');
        Observer.Expect('var param export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>/<Root Flag="Yes">/  <I>/    <N>4</N>/  </I>/</Root>/');
        Observer.Verify();
    end;

    [Test]
    procedure Y66_XmlPortVar_ArrayReturnAssignClear()
    var
        Ports: array[2] of XmlPort "LT Y66 XP Export";
        A: XmlPort "LT Y66 XP Export";
        B: XmlPort "LT Y66 XP Export";
    begin
        Ports[2].MyProc(true);
        Observer.Observe('array 1 flag', Format(Ports[1].GetFlag()));
        Observer.Observe('array 2 flag', Format(Ports[2].GetFlag()));
        Observer.Observe('array 2 export', ExportVar(Ports[2]));
        A := Flagged();
        Observer.Observe('returned flag', Format(A.GetFlag()));
        Clear(A);
        Observer.Observe('cleared flag', Format(A.GetFlag()));
        B.MyProc(true);
        A := B;
        Observer.Observe('assigned flag', Format(A.GetFlag()));
        B.MyProc(false);
        Observer.Observe('assigned flag after source change', Format(A.GetFlag()));
        A.MyProc(true);
        Clear(B);
        Observer.Observe('A after Clear(B)', Format(A.GetFlag()));
        Observer.Expect('array 1 flag', 'No');
        Observer.Expect('array 2 flag', 'Yes');
        Observer.Expect('array 2 export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>/<Root Flag="Yes">/  <I>/    <N>4</N>/  </I>/</Root>/');
        Observer.Expect('returned flag', 'Yes');
        Observer.Expect('cleared flag', 'No');
        Observer.Expect('assigned flag', 'Yes');
        Observer.Expect('assigned flag after source change', 'No');
        Observer.Expect('A after Clear(B)', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Y66_XmlPortVar_Twice()
    var
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "LT Y66 XP Export";
        Imp: XmlPort "LT Y66 XP Import";
        MyRec: Record Integer;
        OutStr: OutStream;
        InStr: InStream;
    begin
        MyRec.SetRange(Number, 1, 1);
        Port.SetTableView(MyRec);
        Port.MyProc(true);
        TempBlob.CreateOutStream(OutStr);
        Port.SetDestination(OutStr);
        Port.Export();
        Observer.Observe('first', BlobText(TempBlob));
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        Port.SetDestination(OutStr);
        Observer.Observe('second export', TryExport(Port));
        Observer.Observe('second', BlobText(TempBlob));
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        Observer.Observe('third export without SetDestination', TryExport(Port));
        Observer.Observe('third', BlobText(TempBlob));
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('<Root><N>a</N></Root>');
        TempBlob.CreateInStream(InStr);
        Imp.SetSource(InStr);
        Imp.Import();
        TempBlob.CreateInStream(InStr);
        Imp.SetSource(InStr);
        Observer.Observe('second import', TryImport(Imp));
        Observer.Observe('got', Imp.GetGot());
        Observer.Expect('first', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>/<Root Flag="Yes">/  <I>/    <N>1</N>/  </I>/</Root>/');
        Observer.Expect('second export', 'ok');
        Observer.Expect('second', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>/<Root Flag="Yes">/  <I>/    <N>1</N>/  </I>/</Root>/');
        Observer.Expect('third export without SetDestination', 'ok');
        Observer.Expect('third', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>/<Root Flag="Yes">/  <I>/    <N>1</N>/  </I>/</Root>/');
        Observer.Expect('second import', 'ok');
        Observer.Expect('got', 'a;a;');
        Observer.Verify();
    end;

    [Test]
    procedure Y66_XmlPortVar_PropertiesBeforeRun()
    var
        Mode: Integer;
        R: Text;
    begin
        for Mode := 1 to 7 do begin
            ClearLastError();
            if PropMode(Mode, R) then
                Observer.Observe(Format(Mode) + ' ' + PropName(Mode), '[' + R + ']')
            else
                Observer.Observe(Format(Mode) + ' ' + PropName(Mode), 'E ' + GetLastErrorText() + '|' + GetLastErrorCode());
        end;
        Observer.Expect('1 currentpath', '[]');
        Observer.Expect('2 importfile of export', '[No]');
        Observer.Expect('3 importfile of import', '[Yes]');
        Observer.Expect('4 textencoding', '[MSDos]');
        Observer.Expect('5 filename', '[]');
        Observer.Expect('6 import ImportFile(false)', 'E The XMLPort ''LT Y66 XP Import'' is designed for import only.|XmlPortImportDirection');
        Observer.Expect('7 export ImportFile(true)', 'E The XMLPort ''LT Y66 XA XP Export'' is designed for export only.|XmlPortExportDirection');
        Observer.Verify();
    end;

    local procedure PropName(Mode: Integer): Text
    begin
        case Mode of
            1:
                exit('currentpath');
            2:
                exit('importfile of export');
            3:
                exit('importfile of import');
            4:
                exit('textencoding');
            5:
                exit('filename');
            6:
                exit('import ImportFile(false)');
            7:
                exit('export ImportFile(true)');
        end;
    end;

    [TryFunction]
    local procedure PropMode(Mode: Integer; var R: Text)
    var
        Port: XmlPort "LT Y66 XA XP Export";
        Imp: XmlPort "LT Y66 XP Import";
    begin
        case Mode of
            1:
                R := Port.CurrentPath();
            2:
                R := Format(Port.ImportFile());
            3:
                R := Format(Imp.ImportFile());
            4:
                R := Format(Port.TextEncoding());
            5:
                R := Port.Filename();
            6:
                begin
                    Imp.ImportFile(false);
                    R := Format(Imp.ImportFile());
                end;
            7:
                begin
                    Port.ImportFile(true);
                    R := Format(Port.ImportFile());
                end;
        end;
    end;

    // Held, not a test: on the SaaS sandbox (BC 29) SetTableView + Export on an XmlPort variable that got the result of a procedure returning
    // an XmlPort raised an uncatchable "Unexpected CLR exception thrown.: System.ObjectDisposedException: Cannot access a disposed object.
    // Object name: 'Microsoft.Dynamics.Nav.Runtime.StubNavRecord'." (in NavXmlPort.SetTableView). Its flag reads Yes before that.
    procedure Suspect_XmlPortVar_ReturnedThenExport()
    var
        A: XmlPort "LT Y66 XP Export";
    begin
        A := Flagged();
        Observer.Observe('returned export', ExportVar(A));
        Observer.Finish();
    end;

    local procedure Flagged(): XmlPort "LT Y66 XP Export"
    var
        Port: XmlPort "LT Y66 XP Export";
    begin
        Port.MyProc(true);
        exit(Port);
    end;

    local procedure SetFlagVar(var Port: XmlPort "LT Y66 XP Export")
    begin
        Port.MyProc(true);
    end;

    local procedure SetFlagValue(Port: XmlPort "LT Y66 XP Export")
    begin
        Port.MyProc(true);
    end;

    local procedure ExportGlobal(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        MyRec: Record Integer;
        OutStr: OutStream;
    begin
        MyRec.SetRange(Number, 3, 3);
        GlobalPort.SetTableView(MyRec);
        TempBlob.CreateOutStream(OutStr);
        GlobalPort.SetDestination(OutStr);
        GlobalPort.Export();
        exit(BlobText(TempBlob));
    end;

    local procedure ExportValue(Port: XmlPort "LT Y66 XP Export"): Text
    begin
        exit(ExportVar(Port));
    end;

    local procedure ExportVar(var Port: XmlPort "LT Y66 XP Export"): Text
    var
        TempBlob: Codeunit "Temp Blob";
        MyRec: Record Integer;
        OutStr: OutStream;
    begin
        MyRec.SetRange(Number, 4, 4);
        Port.SetTableView(MyRec);
        TempBlob.CreateOutStream(OutStr);
        Port.SetDestination(OutStr);
        Port.Export();
        exit(BlobText(TempBlob));
    end;

    local procedure TryExport(var Port: XmlPort "LT Y66 XP Export"): Text
    begin
        ClearLastError();
        if DoExport(Port) then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure DoExport(var Port: XmlPort "LT Y66 XP Export")
    begin
        Port.Export();
    end;

    local procedure TryImport(var Port: XmlPort "LT Y66 XP Import"): Text
    begin
        ClearLastError();
        if DoImport(Port) then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure DoImport(var Port: XmlPort "LT Y66 XP Import")
    begin
        Port.Import();
    end;

    local procedure BlobText(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        if not TempBlob.HasValue() then
            exit('<empty>');
        TempBlob.CreateInStream(InStr, TextEncoding::UTF16);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line + '/';
        end;
        exit(Result);
    end;
}
