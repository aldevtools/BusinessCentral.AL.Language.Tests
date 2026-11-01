// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-initvalue-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); enum 92900, table 92900, test codeunit 92901
// Probe (al-runner issue 6585): InitValue of an Enum field written as a single-quoted string ('G/L Account'), next to the double-quoted
//   ("G/L Account") and bare (Item) forms, on an own enum, on Base App enum "Sales Line Type" and on an Option field. Observed: the value
//   after Init(), on a fresh record variable, after Insert + Get, through RecordRef.Init, and the ordinal.
//   Odd single-quoted values the compiler does not check against the enum ('Unknown', 'g/l account', '1', 'G/L Account ' with a trailing
//   space) and the bare ordinal 1, each in its own table (92901-92905), read through Init() in a TryFunction.
//   An Option field rejects the single-quoted form at compile time (AL0294): must-not-compile cases 2540, 2541; an unknown bare member: 2542.
// BC versions: 27, 28, 29

enum 92900 "LT Y47 Line Type"
{
    Extensible = true;

    value(0; " ") { }
    value(1; "G/L Account") { }
    value(2; Item) { }
    value(3; "Fixed Asset") { }
}

table 92900 "LT Y47 Init Quoted"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; "Line Type"; Enum "LT Y47 Line Type") { InitValue = 'G/L Account'; }
        field(3; "Line Type Dq"; Enum "LT Y47 Line Type") { InitValue = "G/L Account"; }
        field(4; "Line Type Sq Plain"; Enum "LT Y47 Line Type") { InitValue = 'Item'; }
        field(5; "Line Type Bare"; Enum "LT Y47 Line Type") { InitValue = Item; }
        field(6; "Line Type Fa"; Enum "LT Y47 Line Type") { InitValue = 'Fixed Asset'; }
        field(7; "Sales Type"; Enum "Sales Line Type") { InitValue = 'G/L Account'; }
        field(8; "Opt Dq"; Option) { OptionMembers = " ","G/L Account",Item; InitValue = "G/L Account"; }
        field(9; "No Init"; Enum "LT Y47 Line Type") { }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}

table 92901 "LT Y47 Odd Unknown"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; "Line Type"; Enum "LT Y47 Line Type") { InitValue = 'Unknown'; }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}

table 92902 "LT Y47 Odd Lower"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; "Line Type"; Enum "LT Y47 Line Type") { InitValue = 'g/l account'; }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}

table 92903 "LT Y47 Odd Digit"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; "Line Type"; Enum "LT Y47 Line Type") { InitValue = '1'; }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}

table 92904 "LT Y47 Odd Ordinal"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; "Line Type"; Enum "LT Y47 Line Type") { InitValue = 1; }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}

table 92905 "LT Y47 Odd Space"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; "Line Type"; Enum "LT Y47 Line Type") { InitValue = 'G/L Account '; }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}

codeunit 92901 "LT Y47 Enum Init Quoted"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Dump(Row: Record "LT Y47 Init Quoted"): Text
    begin
        exit(Format(Row."Line Type") + '|' + Format(Row."Line Type Dq") + '|' + Format(Row."Line Type Sq Plain") + '|' +
          Format(Row."Line Type Bare") + '|' + Format(Row."Line Type Fa") + '|' + Format(Row."Sales Type") + '|' +
          Format(Row."Opt Dq") + '|' + Format(Row."No Init"));
    end;

    local procedure Ordinals(Row: Record "LT Y47 Init Quoted"): Text
    begin
        exit(Format(Row."Line Type".AsInteger()) + '|' + Format(Row."Line Type Dq".AsInteger()) + '|' + Format(Row."Line Type Sq Plain".AsInteger()) + '|' +
          Format(Row."Line Type Bare".AsInteger()) + '|' + Format(Row."Line Type Fa".AsInteger()) + '|' + Format(Row."Sales Type".AsInteger()) + '|' +
          Format(Row."Opt Dq") + '|' + Format(Row."No Init".AsInteger()));
    end;

    [Test]
    procedure Y47_InitValue_SingleQuoted_AfterInit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y47 Init Quoted";
    begin
        Row.Init();
        Observer.Observe('init', Dump(Row));
        Observer.Observe('ordinals', Ordinals(Row));
        Observer.Observe('isGl', Format(Row."Line Type" = Row."Line Type"::"G/L Account"));
        Observer.Observe('salesIsGl', Format(Row."Sales Type" = Row."Sales Type"::"G/L Account"));
        Observer.Expect('init', 'G/L Account|G/L Account|Item|Item|Fixed Asset|G/L Account|G/L Account| ');
        Observer.Expect('ordinals', '1|1|2|2|3|1|G/L Account|0');
        Observer.Expect('isGl', 'Yes');
        Observer.Expect('salesIsGl', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Y47_InitValue_SingleQuoted_FreshVariable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y47 Init Quoted";
    begin
        Observer.Observe('fresh', Dump(Row));
        Clear(Row);
        Observer.Observe('afterClear', Dump(Row));
        Row."Line Type" := Row."Line Type"::Item;
        Row.Init();
        Observer.Observe('initAfterAssign', Dump(Row));
        Observer.Expect('fresh', 'G/L Account|G/L Account|Item|Item|Fixed Asset|G/L Account|G/L Account| ');
        Observer.Expect('afterClear', 'G/L Account|G/L Account|Item|Item|Fixed Asset|G/L Account|G/L Account| ');
        Observer.Expect('initAfterAssign', 'G/L Account|G/L Account|Item|Item|Fixed Asset|G/L Account|G/L Account| ');
        Observer.Verify();
    end;

    [Test]
    procedure Y47_InitValue_SingleQuoted_InsertGet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y47 Init Quoted";
        Read: Record "LT Y47 Init Quoted";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."Primary Key" := 'A';
        Row.Insert();
        Read.Get('A');
        Observer.Observe('get', Dump(Read));
        Observer.Observe('countGl', Format(CountGl()));
        Observer.Expect('get', 'G/L Account|G/L Account|Item|Item|Fixed Asset|G/L Account|G/L Account| ');
        Observer.Expect('countGl', '1');
        Observer.Verify();
    end;

    local procedure CountGl(): Integer
    var
        Row: Record "LT Y47 Init Quoted";
    begin
        Row.SetRange("Line Type", Row."Line Type"::"G/L Account");
        exit(Row.Count());
    end;

    [Test]
    procedure Y47_InitValue_SingleQuoted_RecordRefInit()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
    begin
        Ref.Open(Database::"LT Y47 Init Quoted");
        Ref.Init();
        Observer.Observe('f2', Format(Ref.Field(2).Value));
        Observer.Observe('f6', Format(Ref.Field(6).Value));
        Observer.Observe('f7', Format(Ref.Field(7).Value));
        Observer.Observe('f8', Format(Ref.Field(8).Value));
        Observer.Observe('f2int', Format(Ref.Field(2).Value, 0, 9));
        Ref.Close();
        Observer.Expect('f2', 'G/L Account');
        Observer.Expect('f6', 'Fixed Asset');
        Observer.Expect('f7', 'G/L Account');
        Observer.Expect('f8', 'G/L Account');
        Observer.Expect('f2int', '1');
        Observer.Verify();
    end;

    // Each step of the odd tables runs in its own TryFunction: 'ok <value>' or 'error <text>|<code>'.
    local procedure Step(Ok: Boolean; Value: Text): Text
    begin
        if Ok then
            exit('ok ' + Value);
        exit('error ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryRefInit(TableNo: Integer; var Ref: RecordRef)
    begin
        Ref.Open(TableNo);
        Ref.Init();
    end;

    [TryFunction]
    local procedure TryRefFormat(var Ref: RecordRef; var Value: Text)
    begin
        Value := Format(Ref.Field(2).Value);
    end;

    [TryFunction]
    local procedure TryRefOrdinal(var Ref: RecordRef; var Value: Text)
    begin
        Value := Format(Ref.Field(2).Value, 0, 9);
    end;

    local procedure ObserveRef(var Observer: Codeunit "Probe Observer"; TableNo: Integer)
    var
        Ref: RecordRef;
        Value: Text;
    begin
        ClearLastError();
        Observer.Observe('refInit', Step(TryRefInit(TableNo, Ref), ''));
        ClearLastError();
        Observer.Observe('refFormat', Step(TryRefFormat(Ref, Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('refOrdinal', Step(TryRefOrdinal(Ref, Value), Value));
    end;

    [TryFunction]
    local procedure TryInitUnknown(var Row: Record "LT Y47 Odd Unknown")
    begin
        Row.Init();
    end;

    [TryFunction]
    local procedure TryFormatUnknown(var Row: Record "LT Y47 Odd Unknown"; var Value: Text)
    begin
        Value := Format(Row."Line Type");
    end;

    [TryFunction]
    local procedure TryOrdinalUnknown(var Row: Record "LT Y47 Odd Unknown"; var Value: Text)
    begin
        Value := Format(Row."Line Type".AsInteger());
    end;

    [Test]
    procedure Y47_InitValue_Unknown()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y47 Odd Unknown";
        Value: Text;
    begin
        ObserveRef(Observer, Database::"LT Y47 Odd Unknown");
        ClearLastError();
        Observer.Observe('recInit', Step(TryInitUnknown(Row), ''));
        ClearLastError();
        Observer.Observe('recFormat', Step(TryFormatUnknown(Row, Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('recOrdinal', Step(TryOrdinalUnknown(Row, Value), Value));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryInitLower(var Row: Record "LT Y47 Odd Lower")
    begin
        Row.Init();
    end;

    [TryFunction]
    local procedure TryFormatLower(var Row: Record "LT Y47 Odd Lower"; var Value: Text)
    begin
        Value := Format(Row."Line Type");
    end;

    [TryFunction]
    local procedure TryOrdinalLower(var Row: Record "LT Y47 Odd Lower"; var Value: Text)
    begin
        Value := Format(Row."Line Type".AsInteger());
    end;

    [Test]
    procedure Y47_InitValue_Lower()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y47 Odd Lower";
        Value: Text;
    begin
        ObserveRef(Observer, Database::"LT Y47 Odd Lower");
        ClearLastError();
        Observer.Observe('recInit', Step(TryInitLower(Row), ''));
        ClearLastError();
        Observer.Observe('recFormat', Step(TryFormatLower(Row, Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('recOrdinal', Step(TryOrdinalLower(Row, Value), Value));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryInitDigit(var Row: Record "LT Y47 Odd Digit")
    begin
        Row.Init();
    end;

    [TryFunction]
    local procedure TryFormatDigit(var Row: Record "LT Y47 Odd Digit"; var Value: Text)
    begin
        Value := Format(Row."Line Type");
    end;

    [TryFunction]
    local procedure TryOrdinalDigit(var Row: Record "LT Y47 Odd Digit"; var Value: Text)
    begin
        Value := Format(Row."Line Type".AsInteger());
    end;

    [Test]
    procedure Y47_InitValue_Digit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y47 Odd Digit";
        Value: Text;
    begin
        ObserveRef(Observer, Database::"LT Y47 Odd Digit");
        ClearLastError();
        Observer.Observe('recInit', Step(TryInitDigit(Row), ''));
        ClearLastError();
        Observer.Observe('recFormat', Step(TryFormatDigit(Row, Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('recOrdinal', Step(TryOrdinalDigit(Row, Value), Value));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryInitOrdinal(var Row: Record "LT Y47 Odd Ordinal")
    begin
        Row.Init();
    end;

    [TryFunction]
    local procedure TryFormatOrdinal(var Row: Record "LT Y47 Odd Ordinal"; var Value: Text)
    begin
        Value := Format(Row."Line Type");
    end;

    [TryFunction]
    local procedure TryOrdinalOrdinal(var Row: Record "LT Y47 Odd Ordinal"; var Value: Text)
    begin
        Value := Format(Row."Line Type".AsInteger());
    end;

    [Test]
    procedure Y47_InitValue_Ordinal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y47 Odd Ordinal";
        Value: Text;
    begin
        ObserveRef(Observer, Database::"LT Y47 Odd Ordinal");
        ClearLastError();
        Observer.Observe('recInit', Step(TryInitOrdinal(Row), ''));
        ClearLastError();
        Observer.Observe('recFormat', Step(TryFormatOrdinal(Row, Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('recOrdinal', Step(TryOrdinalOrdinal(Row, Value), Value));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryInitSpace(var Row: Record "LT Y47 Odd Space")
    begin
        Row.Init();
    end;

    [TryFunction]
    local procedure TryFormatSpace(var Row: Record "LT Y47 Odd Space"; var Value: Text)
    begin
        Value := Format(Row."Line Type");
    end;

    [TryFunction]
    local procedure TryOrdinalSpace(var Row: Record "LT Y47 Odd Space"; var Value: Text)
    begin
        Value := Format(Row."Line Type".AsInteger());
    end;

    [Test]
    procedure Y47_InitValue_Space()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y47 Odd Space";
        Value: Text;
    begin
        ObserveRef(Observer, Database::"LT Y47 Odd Space");
        ClearLastError();
        Observer.Observe('recInit', Step(TryInitSpace(Row), ''));
        ClearLastError();
        Observer.Observe('recFormat', Step(TryFormatSpace(Row, Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('recOrdinal', Step(TryOrdinalSpace(Row, Value), Value));
        Observer.Finish();
    end;
}
