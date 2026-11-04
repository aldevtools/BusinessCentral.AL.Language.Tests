// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-findfirstfield-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73452, page 73453, codeunit 73454
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the page control Code and a local Code[20] of the same name: FindFirstField / FindNextField / FindPreviousField with the bare name, result and row reached; COMPILE RISK: if the local variable wins, the call may not compile (drop this file).
// BC versions: 29 (27 and 28 by CI)

table 73452 "LT P164 A Rec"
{
    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { }
    }
    keys { key(PK; "Code") { Clustered = true; } }
}

page 73453 "LT P164 A List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT P164 A Rec";
    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 73454 "LT P164 A Find"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P164 A Rec";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."Code" := 'A';
        Row.Name := 'n1';
        Row.Insert();
        Row.Init();
        Row."Code" := 'B';
        Row.Name := 'n2';
        Row.Insert();
        Row.Init();
        Row."Code" := 'C';
        Row.Name := 'n1';
        Row.Insert();
    end;

    [Test]
    procedure P164_FindFirstField_BareNameWithLocalOfTheSameName()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P164 A List";
        "Code": Code[20];
    begin
        Seed();
        "Code" := 'C';
        List.OpenView();
        Observer.Observe('hit-b', Format(List.FindFirstField("Code", 'B')));
        Observer.Observe('hit-b-at', List."Code".Value());
        Observer.Observe('hit-c-by-local', Format(List.FindFirstField("Code", 'C')));
        Observer.Observe('hit-c-at', List."Code".Value());
        Observer.Observe('miss', Format(List.FindFirstField("Code", 'Z')));
        Observer.Observe('miss-at', List."Code".Value());
        Observer.Observe('next-name-n1', Format(List.FindFirstField(Name, 'n1')));
        Observer.Observe('next-name-at', List."Code".Value());
        Observer.Observe('next-field', Format(List.FindNextField(Name, 'n1')));
        Observer.Observe('next-field-at', List."Code".Value());
        Observer.Observe('prev-field', Format(List.FindPreviousField(Name, 'n1')));
        Observer.Observe('prev-field-at', List."Code".Value());
        Observer.Observe('local-after', Format("Code"));
        List.Close();
        Observer.Expect('hit-b', 'Yes');
        Observer.Expect('hit-b-at', 'B');
        Observer.Expect('hit-c-by-local', 'Yes');
        Observer.Expect('hit-c-at', 'C');
        Observer.Expect('miss', 'No');
        Observer.Expect('miss-at', 'C');
        Observer.Expect('next-name-n1', 'Yes');
        Observer.Expect('next-name-at', 'A');
        Observer.Expect('next-field', 'Yes');
        Observer.Expect('next-field-at', 'C');
        Observer.Expect('prev-field', 'Yes');
        Observer.Expect('prev-field-at', 'A');
        Observer.Expect('local-after', 'C');
        Observer.Verify();
    end;

    [Test]
    procedure P164_FindFirstField_QualifiedControlWithLocalOfTheSameName()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P164 A List";
        "Code": Code[20];
    begin
        Seed();
        "Code" := 'C';
        List.OpenView();
        Observer.Observe('hit-qualified', Format(List.FindFirstField(List."Code", 'B')));
        Observer.Observe('hit-qualified-at', List."Code".Value());
        Observer.Observe('local-after', Format("Code"));
        List.Close();
        Observer.Expect('hit-qualified', 'Yes');
        Observer.Expect('hit-qualified-at', 'B');
        Observer.Expect('local-after', 'C');
        Observer.Verify();
    end;
}
