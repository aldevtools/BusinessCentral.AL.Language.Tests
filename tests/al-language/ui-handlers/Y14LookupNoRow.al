// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 91668, pages 91669, codeunits 91671 and 91698
// Probe: observe probe (writer Y14, 2026-10-31, runtime asks from partner-app triage); every literal asserted below is what the BC service tier produced.
// Facts: Page.RunModal(0, Rec) on a table with a LookupPageId (read-only list) when Rec has a filter group 2 filter and a view on the primary key that
//   matches no row, on an empty table and on a table with rows: whether OK is found in the ModalPageHandler, the Action returned, and whether the table
//   OnInsert runs. Related pin: errors/lt-ms-refusals-129/Y9LookupNoRow.al (same question without LookupPageId, FilterGroup(2) and a view).
// BC versions: 27, 28, 29

table 91668 "LT Y14 LK Hdr"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT Y14 LK Lookup";

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Kind; Code[10]) { }
        field(3; Name; Text[30]) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }

    trigger OnInsert()
    var
        Log: Codeunit "LT Y14 LK Log";
    begin
        Log.Add('insert(' + "No." + ')');
        if "No." = '' then
            Error('Number series required');
    end;
}

codeunit 91698 "LT Y14 LK Log"
{
    SingleInstance = true;

    var
        Text: Text;

    procedure Add(Entry: Text)
    begin
        Text += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Text;
        Text := '';
        exit(Result);
    end;
}

page 91669 "LT Y14 LK Lookup"
{
    PageType = List;
    SourceTable = "LT Y14 LK Hdr";
    Editable = false;
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 91671 "LT Y14 LK Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y14 LK Log";

    [ModalPageHandler]
    procedure OkHandler(var P: TestPage "LT Y14 LK Lookup")
    begin
        Log.Add('first=' + Format(P.First()));
        P.OK().Invoke();
        Log.Add('ok invoked');
    end;

    local procedure Seed(WithRows: Boolean)
    var
        H: Record "LT Y14 LK Hdr";
    begin
        H.DeleteAll();
        if WithRows then begin
            H."No." := 'A';
            H.Kind := 'Order';
            H.Insert();
            H."No." := 'B';
            H.Kind := 'Quote';
            H.Insert();
        end;
        Commit();
        Log.Take();
    end;

    local procedure RunLookup(Observer: Codeunit "Probe Observer"; Name: Text; WithRows: Boolean)
    var
        H: Record "LT Y14 LK Hdr";
        Result: Action;
    begin
        ClearLastError();
        Seed(WithRows);
        H.FilterGroup(2);
        H.SetFilter(Kind, 'Order');
        H.FilterGroup(0);
        H.SetView('WHERE(No.=CONST(X))');
        asserterror begin
            Result := Page.RunModal(0, H);
            Error('returned');
        end;
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' result', Format(Result));
        Observer.Observe(Name + ' log', Log.Take());
        Observer.Observe(Name + ' rows', Format(H.Count()));
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure Lookup_ViewMatchesNoRow_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunLookup(Observer, 'empty', false);
        Observer.Expect('empty|text', 'The built-in action = OK is not found on the page.');
        Observer.Expect('empty|code', 'TestActionNotFound');
        Observer.Expect('empty result', 'None');
        Observer.Expect('empty log', 'first=No;');
        Observer.Expect('empty rows', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure Lookup_ViewMatchesNoRow_TableWithRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunLookup(Observer, 'rows', true);
        Observer.Expect('rows|text', 'The built-in action = OK is not found on the page.');
        Observer.Expect('rows|code', 'TestActionNotFound');
        Observer.Expect('rows result', 'None');
        Observer.Expect('rows log', 'first=No;');
        Observer.Expect('rows rows', '0');
        Observer.Verify();
    end;
}
