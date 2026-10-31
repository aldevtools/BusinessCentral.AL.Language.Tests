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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Y47_InitValue_OddSingleQuoted()
    var
        Observer: Codeunit "Probe Observer";
        RowUnknown: Record "LT Y47 Odd Unknown";
        RowLower: Record "LT Y47 Odd Lower";
        RowDigit: Record "LT Y47 Odd Digit";
        RowOrdinal: Record "LT Y47 Odd Ordinal";
        RowSpace: Record "LT Y47 Odd Space";
    begin
        Observer.Observe('unknown', TryText(Database::"LT Y47 Odd Unknown"));
        Observer.Observe('lower', TryText(Database::"LT Y47 Odd Lower"));
        Observer.Observe('digit', TryText(Database::"LT Y47 Odd Digit"));
        Observer.Observe('ordinal', TryText(Database::"LT Y47 Odd Ordinal"));
        Observer.Observe('space', TryText(Database::"LT Y47 Odd Space"));
        ClearLastError();
        if TryInitUnknown(RowUnknown) then
            Observer.Observe('unknownRec', Format(RowUnknown."Line Type".AsInteger()) + ' ' + Format(RowUnknown."Line Type"))
        else
            Observer.Observe('unknownRec', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryInitLower(RowLower) then
            Observer.Observe('lowerRec', Format(RowLower."Line Type".AsInteger()) + ' ' + Format(RowLower."Line Type"))
        else
            Observer.Observe('lowerRec', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryInitDigit(RowDigit) then
            Observer.Observe('digitRec', Format(RowDigit."Line Type".AsInteger()) + ' ' + Format(RowDigit."Line Type"))
        else
            Observer.Observe('digitRec', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryInitOrdinal(RowOrdinal) then
            Observer.Observe('ordinalRec', Format(RowOrdinal."Line Type".AsInteger()) + ' ' + Format(RowOrdinal."Line Type"))
        else
            Observer.Observe('ordinalRec', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryInitSpace(RowSpace) then
            Observer.Observe('spaceRec', Format(RowSpace."Line Type".AsInteger()) + ' ' + Format(RowSpace."Line Type"))
        else
            Observer.Observe('spaceRec', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Finish();
    end;

    local procedure TryText(TableNo: Integer): Text
    var
        Ref: RecordRef;
    begin
        ClearLastError();
        if TryRefInit(TableNo, Ref) then
            exit(Format(Ref.Field(2).Value, 0, 9) + ' ' + Format(Ref.Field(2).Value));
        exit('error ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryRefInit(TableNo: Integer; var Ref: RecordRef)
    begin
        Ref.Open(TableNo);
        Ref.Init();
    end;

    [TryFunction]
    local procedure TryInitUnknown(var Row: Record "LT Y47 Odd Unknown")
    begin
        Row.Init();
    end;

    [TryFunction]
    local procedure TryInitLower(var Row: Record "LT Y47 Odd Lower")
    begin
        Row.Init();
    end;

    [TryFunction]
    local procedure TryInitDigit(var Row: Record "LT Y47 Odd Digit")
    begin
        Row.Init();
    end;

    [TryFunction]
    local procedure TryInitOrdinal(var Row: Record "LT Y47 Odd Ordinal")
    begin
        Row.Init();
    end;

    [TryFunction]
    local procedure TryInitSpace(var Row: Record "LT Y47 Odd Space")
    begin
        Row.Init();
    end;
}
