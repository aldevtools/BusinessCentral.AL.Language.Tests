// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 73292, SingleInstance log 73293 (used only by test codeunit 73295), query 73294
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SessionInformation.Callstack read from the OnBeforeOpen trigger of a query that is opened with Query.Open: the frame text for an object of type Query.
// BC versions: 29 (27 and 28 by CI)

table 73292 "LT P129 CS QRow"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73293 "LT P129 CS Log5"
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

query 73294 "LT P129 CS Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(QRow; "LT P129 CS QRow")
        {
            column(Id; Id) { }
        }
    }

    trigger OnBeforeOpen()
    begin
        L.Add('query OnBeforeOpen: ' + L.Frames());
    end;

    var
        L: Codeunit "LT P129 CS Log5";
}

codeunit 73295 "LT P129 CS Query Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P129 CS Log5";

    [Test]
    procedure P129_Callstack_QueryOnBeforeOpen()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P129 CS QRow";
        Q: Query "LT P129 CS Query";
        Entries: List of [Text];
        Entry: Text;
        I: Integer;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        L.Take();
        Q.Open();
        Q.Close();
        Entries := L.Take().Split('|');
        foreach Entry in Entries do begin
            I += 1;
            if Entry <> '' then
                Observer.Observe('query ' + Format(I), Entry);
        end;
        Observer.Expect('query 1', 'query OnBeforeOpen: "LT P129 CS Log5"(CodeUnit 73293).Frames line 5 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Query"(Query 73294).OnBeforeOpen(Trigger) line 2 - AL Language Coverage Tests by AL Language version x\"LT P129 CS Query Test"(CodeUnit 73295).P129_Callstack_QueryOnBeforeOpen line 13 - AL Language Coverage Tests by AL Language version x\');
        Observer.Verify();
    end;
}
