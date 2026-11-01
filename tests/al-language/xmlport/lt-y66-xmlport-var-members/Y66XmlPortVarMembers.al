// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); xmlports 61100 and 61101 of AL Language XApp A (tests/al-language-xapp-a/Y66XaXmlPorts.al);
//   own xmlports 93400 and 93401, test codeunit 93403
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

xmlport 93400 "LT Y66 XP Export"
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

xmlport 93401 "LT Y66 XP Import"
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

codeunit 93403 "LT Y66 XmlPort Var Members"
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Observe('returned export', ExportVar(A));
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Y66_XmlPortVar_PropertiesBeforeRun()
    var
        Port: XmlPort "LT Y66 XA XP Export";
        Imp: XmlPort "LT Y66 XP Import";
    begin
        Observer.Observe('currentpath', '[' + Port.CurrentPath() + ']');
        Observer.Observe('importfile export', Format(Port.ImportFile()));
        Observer.Observe('importfile import', Format(Imp.ImportFile()));
        Observer.Observe('textencoding', Format(Port.TextEncoding()));
        Observer.Observe('filename', '[' + Port.Filename() + ']');
        Imp.ImportFile(false);
        Observer.Observe('importfile after set', Format(Imp.ImportFile()));
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
        TempBlob.CreateInStream(InStr);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line + '/';
        end;
        exit(Result);
    end;
}
