// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 73288, SingleInstance log 73289 (used only by test codeunit 73291), xmlport 73290
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SessionInformation.Callstack read from an xmlport that is exported to an OutStream: OnPreXmlPort, OnPostXmlPort, the OnPreXmlItem and OnAfterGetRecord triggers of a table element,
// the OnBeforePassVariable trigger of a text element, and a local and a global procedure of the xmlport. The entries are the frames above the test runner, innermost first.
// BC versions: 29 (27 and 28 by CI)

table 73288 "LT P129 CS XRow"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73289 "LT P129 CS Log4"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + '|';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure Frames(): Text
    var
        Stack: Text;
        Position: Integer;
    begin
        Stack := SessionInformation.Callstack;
        Position := StrPos(Stack, '"Test Runner - Mgt"');
        if Position > 0 then
            exit(CopyStr(Stack, 1, Position - 1));
        exit(Stack);
    end;
}

xmlport 73290 "LT P129 CS Xml"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(XRow; "LT P129 CS XRow")
            {
                fieldelement(Id; XRow.Id) { }

                trigger OnPreXmlItem()
                begin
                    L.Add('table element OnPreXmlItem: ' + L.Frames());
                end;

                trigger OnAfterGetRecord()
                begin
                    L.Add('table element OnAfterGetRecord: ' + L.Frames());
                    LocalProc();
                end;
            }
            textelement(Free)
            {
                trigger OnBeforePassVariable()
                begin
                    Free := 'x';
                    L.Add('text element OnBeforePassVariable: ' + L.Frames());
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        L.Add('OnPreXmlPort: ' + L.Frames());
        GlobalProc();
    end;

    trigger OnPostXmlPort()
    begin
        L.Add('OnPostXmlPort: ' + L.Frames());
    end;

    local procedure LocalProc()
    begin
        L.Add('local procedure: ' + L.Frames());
    end;

    procedure GlobalProc()
    begin
        L.Add('global procedure: ' + L.Frames());
    end;

    var
        L: Codeunit "LT P129 CS Log4";
}

codeunit 73291 "LT P129 CS XmlPort"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P129 CS Log4";

    [Test]
    procedure P129_Callstack_XmlPortTriggersAndProcedures()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P129 CS XRow";
        TempBlob: Codeunit "Temp Blob";
        Out: OutStream;
        Entries: List of [Text];
        Entry: Text;
        I: Integer;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        L.Take();
        TempBlob.CreateOutStream(Out);
        Xmlport.Export(Xmlport::"LT P129 CS Xml", Out);
        Entries := L.Take().Split('|');
        foreach Entry in Entries do begin
            I += 1;
            if Entry <> '' then
                Observer.Observe('xmlport ' + Format(I), Entry);
        end;
        Observer.Expect('xmlport 1', 'OnPreXmlPort: "LT P129 CS Log4"(CodeUnit 73289).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Xml"(XmlPort 73290).OnPreXmlPort(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS XmlPort"(CodeUnit 73291).P129_Callstack_XmlPortTriggersAndProcedures line 15 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('xmlport 2', 'global procedure: "LT P129 CS Log4"(CodeUnit 73289).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Xml"(XmlPort 73290).GlobalProc line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Xml"(XmlPort 73290).OnPreXmlPort(Trigger) line 3 - AL Language Coverage Tests by AL Language version x\"LT P129 CS XmlPort"(CodeUnit 73291).P129_Callstack_XmlPortTriggersAndProcedures line 15 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('xmlport 3', 'table element OnPreXmlItem: "LT P129 CS Log4"(CodeUnit 73289).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Xml"(XmlPort 73290)."XRow - OnPreXmlItem"(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS XmlPort"(CodeUnit 73291).P129_Callstack_XmlPortTriggersAndProcedures line 15 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('xmlport 4', 'table element OnAfterGetRecord: "LT P129 CS Log4"(CodeUnit 73289).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Xml"(XmlPort 73290)."XRow - OnAfterGetRecord"(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS XmlPort"(CodeUnit 73291).P129_Callstack_XmlPortTriggersAndProcedures line 15 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('xmlport 5', 'local procedure: "LT P129 CS Log4"(CodeUnit 73289).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Xml"(XmlPort 73290).LocalProc line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Xml"(XmlPort 73290)."XRow - OnAfterGetRecord"(Trigger) line 3 - AL Language Coverage Tests by AL Language version x\"LT P129 CS XmlPort"(CodeUnit 73291).P129_Callstack_XmlPortTriggersAndProcedures line 15 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('xmlport 6', 'text element OnBeforePassVariable: "LT P129 CS Log4"(CodeUnit 73289).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Xml"(XmlPort 73290)."Free - OnBeforePassVariable"(Trigger) line 3 - AL Language Coverage Tests by AL Language version x\"LT P129 CS XmlPort"(CodeUnit 73291).P129_Callstack_XmlPortTriggersAndProcedures line 15 - AL Language Coverage Tests by AL Language version x\');
        Observer.Expect('xmlport 7', 'OnPostXmlPort: "LT P129 CS Log4"(CodeUnit 73289).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Xml"(XmlPort 73290).OnPostXmlPort(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS XmlPort"(CodeUnit 73291).P129_Callstack_XmlPortTriggersAndProcedures line 15 - AL Language Coverage Tests by AL Language version x\');
        Observer.Verify();
    end;




}
