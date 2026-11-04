// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-format-property
// Scope: in-scope
// Fixtures used: none — the xmlports under test ship in the Base Application, and "Temp Blob"
//   (System Application) is only the stream sink.
//
// WHAT THIS PINS. TestXmlPortPrecompiledObject covers dependency xmlports whose Format is Xml.
// These two Base Application xmlports declare Format = VariableText, so exporting them is the
// AL-observable proof that the platform reads a dependency port's declared Format:
//   5050 "Export Contact"          Direction = Export, Format = VariableText, TextEncoding = UTF8
//   9991 "Code Coverage Detailed"  Format = VariableText
//
// 5050's first tableelement is a single Integer row (Number = 1) whose text elements are
// Contact field captions, so its first exported line is a caption header whatever contacts
// the tenant holds. Written as variable text, that line is comma-separated quoted values; as
// XML it would start with '<'. Only the "No." caption is asserted — it is the first element
// and the one least likely to change — so the test is about the format, not the field list.

codeunit 60937 "Test XmlPort Dep VariableText"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure ExportContact_WritesVariableTextHeader()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        FirstLine: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        Xmlport.Export(Xmlport::"Export Contact", OutStr);

        Assert.IsTrue(TempBlob.Length() > 0, 'Export Contact must write its caption header line');
        TempBlob.CreateInStream(InStr);
        InStr.ReadText(FirstLine);
        Assert.IsTrue(StrPos(FirstLine, '"No.",') > 0,
            'a Format = VariableText port writes its first caption quoted and comma-separated: ' + FirstLine);
        Assert.AreEqual(0, StrPos(FirstLine, '<'),
            'a Format = VariableText port must not write XML: ' + FirstLine);
    end;

    [Test]
    procedure ExportCodeCoverageDetailed_NoThrow()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        Xmlport.Export(9991, OutStr);
    end;

    // The dependency port's declared Direction still holds on a variable-text port: 5050 is
    // Export-only, so Import refuses with a real AL error.
    [Test]
    procedure ExportContact_DeclaredExportDirection_RefusesImport()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('"C1","","Name"');
        TempBlob.CreateInStream(InStr);

        asserterror Xmlport.Import(Xmlport::"Export Contact", InStr);
        Assert.IsTrue(GetLastErrorText() <> '', 'an Export-only xmlport must refuse Import');
        Assert.IsTrue(GetLastErrorCode() <> '', 'the refusal must be a real AL error carrying an error code');
    end;
}
