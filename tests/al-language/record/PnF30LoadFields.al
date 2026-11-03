// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-loadfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73933, codeunit 73934
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "Record.LoadFields(Fields)" (Tests-SCM-Service ...: LoadFields, TestField with an ErrorInfo, ... issue 41)
// Facts: LoadFields on a cleared record with the blank key present and absent (statement form and Boolean form), the values read afterwards, AreFieldsLoaded, Modify;
//   LoadFields after Get with a field assigned in between
// BC versions: 29 (27 and 28 by CI)

table 73933 "LT PnF LF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
        field(4; Note; Text[30]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 73934 "LT PnF LoadFields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedBlankKey()
    var
        Row: Record "LT PnF LF Row";
    begin
        Row.DeleteAll();
        Row.Code := '';
        Row.Name := 'blank-key';
        Row.Qty := 5;
        Row.Note := 'note';
        Row.Insert();
    end;

    [Test]
    procedure LoadFields_FreshRecord_RowPresent()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF LF Row";
    begin
        SeedBlankKey();
        Clear(Row);
        Row.LoadFields(Name);
        Observer.Observe('name', Row.Name);
        Observer.Observe('qty', Format(Row.Qty));
        Observer.Observe('note', Row.Note);
        Observer.Observe('loaded_name', Format(Row.AreFieldsLoaded(Row.Name)));
        Observer.Observe('loaded_qty', Format(Row.AreFieldsLoaded(Row.Qty)));
        Observer.Observe('loaded_code', Format(Row.AreFieldsLoaded(Row.Code)));
        Observer.Observe('loaded_note', Format(Row.AreFieldsLoaded(Row.Note)));
        Observer.Expect('name', '');
        Observer.Expect('qty', '0');
        Observer.Expect('note', '');
        Observer.Expect('loaded_name', 'No');
        Observer.Expect('loaded_qty', 'No');
        Observer.Expect('loaded_code', 'No');
        Observer.Expect('loaded_note', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_FreshRecord_BooleanForm()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF LF Row";
        Ok: Boolean;
    begin
        SeedBlankKey();
        Clear(Row);
        Ok := Row.LoadFields(Name);
        Observer.Observe('result', Format(Ok));
        Observer.Observe('name', Row.Name);
        Observer.Expect('result', 'No');
        Observer.Expect('name', '');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_FreshRecord_Modify()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF LF Row";
        Check: Record "LT PnF LF Row";
    begin
        SeedBlankKey();
        Clear(Row);
        Row.LoadFields(Name);
        Row.Name := 'changed';
        Row.Modify();
        Check.Get('');
        Observer.Observe('name', Check.Name);
        Observer.Observe('qty', Format(Check.Qty));
        Observer.Observe('note', Check.Note);
        Observer.Expect('name', 'changed');
        Observer.Expect('qty', '0');
        Observer.Expect('note', '');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_FreshRecord_NoRow_Statement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF LF Row";
    begin
        Row.DeleteAll();
        Clear(Row);
        Row.LoadFields(Name);
        Observer.Observe('no_error', 'ok');
        Observer.Observe('name', Row.Name);
        Observer.Observe('qty', Format(Row.Qty));
        Observer.Observe('loaded_name', Format(Row.AreFieldsLoaded(Row.Name)));
        Observer.Expect('no_error', 'ok');
        Observer.Expect('name', '');
        Observer.Expect('qty', '0');
        Observer.Expect('loaded_name', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_FreshRecord_NoRow_BooleanForm()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF LF Row";
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Clear(Row);
        Ok := Row.LoadFields(Name);
        Observer.Observe('result', Format(Ok));
        Observer.Expect('result', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_KeyAssigned()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF LF Row";
    begin
        SeedBlankKey();
        Row.Code := 'K1';
        Row.Name := 'k1';
        Row.Qty := 8;
        Row.Insert();
        Clear(Row);
        Row.Code := 'K1';
        Row.LoadFields(Name);
        Observer.Observe('name', Row.Name);
        Observer.Observe('qty', Format(Row.Qty));
        Observer.Observe('loaded_name', Format(Row.AreFieldsLoaded(Row.Name)));
        Observer.Expect('name', '');
        Observer.Expect('qty', '0');
        Observer.Expect('loaded_name', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_AfterGet_Assigned()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF LF Row";
    begin
        SeedBlankKey();
        Row.Get('');
        Row.Name := 'assigned';
        Row.Qty := 99;
        Row.LoadFields(Name);
        Observer.Observe('name', Row.Name);
        Observer.Observe('qty', Format(Row.Qty));
        Observer.Observe('loaded_name', Format(Row.AreFieldsLoaded(Row.Name)));
        Observer.Expect('name', 'assigned');
        Observer.Expect('qty', '99');
        Observer.Expect('loaded_name', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_FilledByHand()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF LF Row";
    begin
        SeedBlankKey();
        Clear(Row);
        Row.Name := 'by hand';
        Row.LoadFields(Name);
        Observer.Observe('name', Row.Name);
        Observer.Observe('qty', Format(Row.Qty));
        Observer.Expect('name', 'by hand');
        Observer.Expect('qty', '0');
        Observer.Verify();
    end;
}
