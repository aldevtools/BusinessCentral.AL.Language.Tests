// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.io.file.exists
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet)
// Fixtures used: Probe Observer (69160); report 94587 "LT Y86 Rdlc Report" (report/lt-y86-request-page/Y86LayoutStreams.al); test codeunit 99330
// Probe (writer Y86): (1) al-runtime-rs assumption dotnet-file-exists-sees-run-files: System.IO.File.Exists, ReadAllText and FileInfo.Exists of a file that AL
// wrote (File type, Report.SaveAsXml, XmlDocument.Save, TextWriter), after AL deleted it, after .NET deleted it, and the AL File.Exists of a file .NET wrote.
// (2) al-runtime-rs assumption dotnet-enum-member-through-property: X.P::M on a DotNet variable X whose property P is a .NET enum, with X assigned,
// with X unassigned and with a property getter that throws.
// BC versions: 27, 28, 29

dotnet
{
    assembly("mscorlib")
    {
        type("System.IO.File"; LtY86File) { }
        type("System.IO.FileInfo"; LtY86FileInfo) { }
        type("System.IO.FileAttributes"; LtY86FileAttributes) { }
    }

    assembly("System.Xml")
    {
        type("System.Xml.XmlDocument"; LtY86XmlDocument) { }
        type("System.Xml.XmlNodeType"; LtY86XmlNodeType) { }
    }
}

codeunit 99330 "LT Y86 DotNet Files"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        DotNetFile: DotNet LtY86File;

    local procedure NewPath(Ext: Text): Text
    begin
        exit(TemporaryPath() + 'lty86' + DelChr(Format(CreateGuid()), '=', '{}-') + Ext);
    end;

    local procedure WriteWithAl(Path: Text; Content: Text)
    var
        F: File;
        OutS: OutStream;
    begin
        F.WriteMode(true);
        F.TextMode(true);
        F.Create(Path);
        F.CreateOutStream(OutS);
        OutS.WriteText(Content);
        F.Close();
    end;

    [TryFunction]
    local procedure TryReadAll(Path: Text; var Result: Text)
    begin
        Result := DotNetFile.ReadAllText(Path);
    end;

    local procedure ReadAll(Path: Text): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryReadAll(Path, Result) then
            exit('[' + Result + ']');
        exit('error ' + GetLastErrorCode());
    end;

    [Test]
    procedure Y86_DotNetSeesFileWrittenByAl()
    var
        Obs: Codeunit "Probe Observer";
        Path: Text;
    begin
        Path := NewPath('.txt');
        Obs.Observe('before: AL', Format(File.Exists(Path)));
        Obs.Observe('before: DotNet', Format(DotNetFile.Exists(Path)));
        WriteWithAl(Path, 'hello');
        Obs.Observe('written: AL', Format(File.Exists(Path)));
        Obs.Observe('written: DotNet', Format(DotNetFile.Exists(Path)));
        Obs.Observe('written: ReadAllText', ReadAll(Path));
        Erase(Path);
        Obs.Observe('erased by AL: AL', Format(File.Exists(Path)));
        Obs.Observe('erased by AL: DotNet', Format(DotNetFile.Exists(Path)));
        Obs.Observe('erased by AL: ReadAllText', ReadAll(Path));
        Obs.Finish();
    end;

    [Test]
    procedure Y86_AlSeesFileWrittenByDotNet()
    var
        Obs: Codeunit "Probe Observer";
        Path: Text;
    begin
        Path := NewPath('.txt');
        DotNetFile.WriteAllText(Path, 'from dotnet');
        Obs.Observe('written by DotNet: DotNet', Format(DotNetFile.Exists(Path)));
        Obs.Observe('written by DotNet: AL', Format(File.Exists(Path)));
        Obs.Observe('written by DotNet: ReadAllText', ReadAll(Path));
        DotNetFile.Delete(Path);
        Obs.Observe('deleted by DotNet: DotNet', Format(DotNetFile.Exists(Path)));
        Obs.Observe('deleted by DotNet: AL', Format(File.Exists(Path)));
        Obs.Finish();
    end;

    [Test]
    procedure Y86_DotNetSeesReportSaveAsXml()
    var
        Obs: Codeunit "Probe Observer";
        Path: Text;
        Xml: Text;
    begin
        Path := NewPath('.xml');
        Obs.Observe('before: DotNet', Format(DotNetFile.Exists(Path)));
        Report.SaveAsXml(Report::"LT Y86 Rdlc Report", Path);
        Obs.Observe('SaveAsXml: AL', Format(File.Exists(Path)));
        Obs.Observe('SaveAsXml: DotNet', Format(DotNetFile.Exists(Path)));
        Xml := ReadAll(Path);
        Obs.Observe('SaveAsXml: starts with xml declaration', Format(CopyStr(Xml, 1, 6) = '[<?xml'));
        Obs.Observe('SaveAsXml: has ReportDataSet', Format(StrPos(Xml, 'ReportDataSet') > 0));
        Erase(Path);
        Obs.Observe('erased: DotNet', Format(DotNetFile.Exists(Path)));
        Obs.Finish();
    end;

    [Test]
    procedure Y86_DotNetSeesXmlDocumentSave()
    var
        Obs: Codeunit "Probe Observer";
        Doc: DotNet LtY86XmlDocument;
        Path: Text;
    begin
        Path := NewPath('.xml');
        Doc := Doc.XmlDocument();
        Doc.LoadXml('<a><b>1</b></a>');
        Doc.Save(Path);
        Obs.Observe('Save: DotNet', Format(DotNetFile.Exists(Path)));
        Obs.Observe('Save: AL', Format(File.Exists(Path)));
        Obs.Observe('Save: text has b', Format(StrPos(ReadAll(Path), '<b>1</b>') > 0));
        Erase(Path);
        Obs.Observe('erased: DotNet', Format(DotNetFile.Exists(Path)));
        Obs.Finish();
    end;

    [Test]
    procedure Y86_FileInfoOfAlFile()
    var
        Obs: Codeunit "Probe Observer";
        Info: DotNet LtY86FileInfo;
        Path: Text;
    begin
        Path := NewPath('.txt');
        Info := Info.FileInfo(Path);
        Obs.Observe('missing: Exists', Format(Info.Exists));
        WriteWithAl(Path, 'twelve bytes');
        Info := Info.FileInfo(Path);
        Obs.Observe('written: Exists', Format(Info.Exists));
        Obs.Observe('written: Length', Format(Info.Length));
        Obs.Observe('written: Name has lty86', Format(StrPos(Info.Name, 'lty86') = 1));
        Erase(Path);
        Obs.Finish();
    end;

    // ---- dotnet-enum-member-through-property

    [Test]
    procedure Y86_EnumMemberThroughProperty_Assigned()
    var
        Obs: Codeunit "Probe Observer";
        Doc: DotNet LtY86XmlDocument;
    begin
        Doc := Doc.XmlDocument();
        Obs.Observe('member Document', Format(Doc.NodeType::Document));
        Obs.Observe('member Element', Format(Doc.NodeType::Element));
        Obs.Observe('member Element ordinal', Format(Doc.NodeType::Element, 0, 2));
        Obs.Observe('compare to own type', Format(Doc.NodeType = Doc.NodeType::Document));
        Obs.Observe('compare to other member', Format(Doc.NodeType = Doc.NodeType::Element));
        Obs.Finish();
    end;

    [Test]
    procedure Y86_EnumMemberThroughProperty_Unassigned()
    var
        Obs: Codeunit "Probe Observer";
        Doc: DotNet LtY86XmlDocument;
    begin
        asserterror Obs.Observe('unassigned member', Format(Doc.NodeType::Element));
        Obs.ObserveError('unassigned');
        Obs.Finish();
    end;

    [Test]
    procedure Y86_EnumMemberThroughProperty_GetterThrows()
    var
        Obs: Codeunit "Probe Observer";
        Info: DotNet LtY86FileInfo;
    begin
        Info := Info.FileInfo(TemporaryPath() + 'lty86-never-written-' + DelChr(Format(CreateGuid()), '=', '{}-'));
        asserterror Obs.Observe('getter member', Format(Info.Attributes::Directory));
        Obs.ObserveError('getter');
        Obs.Finish();
    end;
}
