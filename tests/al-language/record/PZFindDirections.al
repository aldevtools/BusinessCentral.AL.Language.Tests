// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-find-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained tables 69353 and 69354, codeunit 69353
// Probe: written against a real BC 29.0 service tier (29.0.54011.55816); every literal below is what that tier produced. Other BC versions are checked by the CI matrix.
//
// Record.Find and RecordRef.Find with every order and subset of =, < and > (and -, +, an empty and invalid texts), on a table of the rows 10, 20, 30, from the key values 20 (a row), 25 (between rows),
// 5 (below all) and 35 (above all), and on an empty table. Each observation reads "<start>:<result>/<id after the call>". Record and RecordRef answer the same everywhere.
// The characters are tried in the order written: '<=' at 20 finds 10, '=<' finds 20; '>=' at 20 finds 30; '=' alone finds only an exact row; '-' finds the first row and '+' the last whatever the start.
// A failed Find leaves the key value as it was. An empty table answers No for every valid direction. An empty text or any other character (also a repeated sign or '-' with another sign) raises
// "There is an invalid character in the Find expression '<text>'..." (code DB:BadSearchMethod).
// BC versions: 29.0
table 69353 "PZ Find Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69353 "PZ Find Directions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "PZ Find Row";
        Empty: Record "ALT Shape 00";
        i: Integer;
    begin
        Row.DeleteAll();
        Empty.DeleteAll();
        for i := 1 to 3 do begin
            Row.Id := i * 10;
            Row.Txt := 't' + Format(i * 10);
            Row.Insert();
        end;
    end;

    [TryFunction]
    local procedure TryRecordFind(Direction: Text; StartId: Integer; var Found: Boolean; var AfterId: Integer; Empty: Boolean)
    var
        Row: Record "PZ Find Row";
        EmptyRow: Record "ALT Shape 00";
    begin
        if Empty then begin
            EmptyRow.Id := StartId;
            Found := EmptyRow.Find(Direction);
            AfterId := EmptyRow.Id;
        end else begin
            Row.Id := StartId;
            Found := Row.Find(Direction);
            AfterId := Row.Id;
        end;
    end;

    [TryFunction]
    local procedure TryRecordRefFind(Direction: Text; StartId: Integer; var Found: Boolean; var AfterId: Integer; Empty: Boolean)
    var
        RecRef: RecordRef;
    begin
        if Empty then
            RecRef.Open(Database::"ALT Shape 00")
        else
            RecRef.Open(Database::"PZ Find Row");
        RecRef.Field(1).Value := StartId;
        Found := RecRef.Find(Direction);
        AfterId := RecRef.Field(1).Value;
    end;

    local procedure One(Direction: Text; StartId: Integer; UseRecordRef: Boolean; Empty: Boolean): Text
    var
        Found: Boolean;
        AfterId: Integer;
        Ok: Boolean;
    begin
        if UseRecordRef then
            Ok := TryRecordRefFind(Direction, StartId, Found, AfterId, Empty)
        else
            Ok := TryRecordFind(Direction, StartId, Found, AfterId, Empty);
        if not Ok then begin
            ClearLastError();
            exit(StartId.ToText() + ':error');
        end;
        exit(StartId.ToText() + ':' + Format(Found) + '/' + Format(AfterId));
    end;

    local procedure AllPositions(Direction: Text; UseRecordRef: Boolean): Text
    begin
        exit(One(Direction, 20, UseRecordRef, false) + ' ' + One(Direction, 25, UseRecordRef, false) + ' ' + One(Direction, 5, UseRecordRef, false) + ' ' + One(Direction, 35, UseRecordRef, false) + ' empty ' + One(Direction, 20, UseRecordRef, true));
    end;

    local procedure ObserveDirections(Directions: List of [Text]; var Observer: Codeunit "Probe Observer")
    var
        Direction: Text;
    begin
        Seed();
        foreach Direction in Directions do begin
            Observer.Observe('record [' + Direction + ']', AllPositions(Direction, false));
            Observer.Observe('recordref [' + Direction + ']', AllPositions(Direction, true));
        end;
    end;

    [Test]
    procedure Find_SingleDirections()
    var
        D: List of [Text];
        Observer: Codeunit "Probe Observer";
    begin
        D.AddRange('=', '<', '>', '-', '+', '');
        ObserveDirections(D, Observer);
        Observer.Expect('record [=]', '20:Yes/20 25:No/25 5:No/5 35:No/35 empty 20:No/20');
        Observer.Expect('recordref [=]', '20:Yes/20 25:No/25 5:No/5 35:No/35 empty 20:No/20');
        Observer.Expect('record [<]', '20:Yes/10 25:Yes/20 5:No/5 35:Yes/30 empty 20:No/20');
        Observer.Expect('recordref [<]', '20:Yes/10 25:Yes/20 5:No/5 35:Yes/30 empty 20:No/20');
        Observer.Expect('record [>]', '20:Yes/30 25:Yes/30 5:Yes/10 35:No/35 empty 20:No/20');
        Observer.Expect('recordref [>]', '20:Yes/30 25:Yes/30 5:Yes/10 35:No/35 empty 20:No/20');
        Observer.Expect('record [-]', '20:Yes/10 25:Yes/10 5:Yes/10 35:Yes/10 empty 20:No/20');
        Observer.Expect('recordref [-]', '20:Yes/10 25:Yes/10 5:Yes/10 35:Yes/10 empty 20:No/20');
        Observer.Expect('record [+]', '20:Yes/30 25:Yes/30 5:Yes/30 35:Yes/30 empty 20:No/20');
        Observer.Expect('recordref [+]', '20:Yes/30 25:Yes/30 5:Yes/30 35:Yes/30 empty 20:No/20');
        Observer.Expect('record []', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('recordref []', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Verify();
    end;

    [Test]
    procedure Find_TwoCharacterDirections()
    var
        D: List of [Text];
        Observer: Codeunit "Probe Observer";
    begin
        D.AddRange('=<', '<=', '=>', '>=', '<>', '><');
        ObserveDirections(D, Observer);
        Observer.Expect('record [=<]', '20:Yes/20 25:Yes/20 5:No/5 35:Yes/30 empty 20:No/20');
        Observer.Expect('recordref [=<]', '20:Yes/20 25:Yes/20 5:No/5 35:Yes/30 empty 20:No/20');
        Observer.Expect('record [<=]', '20:Yes/10 25:Yes/20 5:No/5 35:Yes/30 empty 20:No/20');
        Observer.Expect('recordref [<=]', '20:Yes/10 25:Yes/20 5:No/5 35:Yes/30 empty 20:No/20');
        Observer.Expect('record [=>]', '20:Yes/20 25:Yes/30 5:Yes/10 35:No/35 empty 20:No/20');
        Observer.Expect('recordref [=>]', '20:Yes/20 25:Yes/30 5:Yes/10 35:No/35 empty 20:No/20');
        Observer.Expect('record [>=]', '20:Yes/30 25:Yes/30 5:Yes/10 35:No/35 empty 20:No/20');
        Observer.Expect('recordref [>=]', '20:Yes/30 25:Yes/30 5:Yes/10 35:No/35 empty 20:No/20');
        Observer.Expect('record [<>]', '20:Yes/10 25:Yes/20 5:Yes/10 35:Yes/30 empty 20:No/20');
        Observer.Expect('recordref [<>]', '20:Yes/10 25:Yes/20 5:Yes/10 35:Yes/30 empty 20:No/20');
        Observer.Expect('record [><]', '20:Yes/30 25:Yes/30 5:Yes/10 35:Yes/30 empty 20:No/20');
        Observer.Expect('recordref [><]', '20:Yes/30 25:Yes/30 5:Yes/10 35:Yes/30 empty 20:No/20');
        Observer.Verify();
    end;

    [Test]
    procedure Find_ThreeCharacterDirections()
    var
        D: List of [Text];
        Observer: Codeunit "Probe Observer";
    begin
        D.AddRange('=><', '=<>', '<=>', '><=', '<>=', '>=<');
        ObserveDirections(D, Observer);
        Observer.Expect('record [=><]', '20:Yes/20 25:Yes/30 5:Yes/10 35:Yes/30 empty 20:No/20');
        Observer.Expect('recordref [=><]', '20:Yes/20 25:Yes/30 5:Yes/10 35:Yes/30 empty 20:No/20');
        Observer.Expect('record [=<>]', '20:Yes/20 25:Yes/20 5:Yes/10 35:Yes/30 empty 20:No/20');
        Observer.Expect('recordref [=<>]', '20:Yes/20 25:Yes/20 5:Yes/10 35:Yes/30 empty 20:No/20');
        Observer.Expect('record [<=>]', '20:Yes/10 25:Yes/20 5:Yes/10 35:Yes/30 empty 20:No/20');
        Observer.Expect('recordref [<=>]', '20:Yes/10 25:Yes/20 5:Yes/10 35:Yes/30 empty 20:No/20');
        Observer.Expect('record [><=]', '20:Yes/30 25:Yes/30 5:Yes/10 35:Yes/30 empty 20:No/20');
        Observer.Expect('recordref [><=]', '20:Yes/30 25:Yes/30 5:Yes/10 35:Yes/30 empty 20:No/20');
        Observer.Expect('record [<>=]', '20:Yes/10 25:Yes/20 5:Yes/10 35:Yes/30 empty 20:No/20');
        Observer.Expect('recordref [<>=]', '20:Yes/10 25:Yes/20 5:Yes/10 35:Yes/30 empty 20:No/20');
        Observer.Expect('record [>=<]', '20:Yes/30 25:Yes/30 5:Yes/10 35:Yes/30 empty 20:No/20');
        Observer.Expect('recordref [>=<]', '20:Yes/30 25:Yes/30 5:Yes/10 35:Yes/30 empty 20:No/20');
        Observer.Verify();
    end;

    [Test]
    procedure Find_InvalidDirections()
    var
        D: List of [Text];
        Observer: Codeunit "Probe Observer";
    begin
        D.AddRange('x', '=x', 'X', '==', '<<', '>>', '=<>=', ' ', '-+', '=-', '+-', '<-', '=<>x');
        ObserveDirections(D, Observer);
        Observer.Expect('record [x]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('recordref [x]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('record [=x]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('recordref [=x]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('record [X]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('recordref [X]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('record [==]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('recordref [==]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('record [<<]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('recordref [<<]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('record [>>]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('recordref [>>]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('record [=<>=]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('recordref [=<>=]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('record [ ]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('recordref [ ]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('record [-+]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('recordref [-+]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('record [=-]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('recordref [=-]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('record [+-]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('recordref [+-]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('record [<-]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('recordref [<-]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('record [=<>x]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Expect('recordref [=<>x]', '20:error 25:error 5:error 35:error empty 20:error');
        Observer.Verify();
    end;

    [Test]
    procedure Find_InvalidDirection_ErrorText()
    var
        Found: Boolean;
        AfterId: Integer;
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Ok := TryRecordFind('x', 20, Found, AfterId, false);
        Observer.Observe('record x', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TryRecordFind('', 20, Found, AfterId, false);
        Observer.Observe('record empty', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TryRecordRefFind('x', 20, Found, AfterId, false);
        Observer.Observe('recordref x', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TryRecordRefFind('', 20, Found, AfterId, false);
        Observer.Observe('recordref empty', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Observer.Expect('record x', 'No There is an invalid character in the Find expression ''x''.\\In Find expressions, you can use =, >, and < in combinations, where each sign can only appear once, or you can use - or +.|DB:BadSearchMethod');
        Observer.Expect('record empty', 'No There is an invalid character in the Find expression ''''.\\In Find expressions, you can use =, >, and < in combinations, where each sign can only appear once, or you can use - or +.|DB:BadSearchMethod');
        Observer.Expect('recordref x', 'No There is an invalid character in the Find expression ''x''.\\In Find expressions, you can use =, >, and < in combinations, where each sign can only appear once, or you can use - or +.|DB:BadSearchMethod');
        Observer.Expect('recordref empty', 'No There is an invalid character in the Find expression ''''.\\In Find expressions, you can use =, >, and < in combinations, where each sign can only appear once, or you can use - or +.|DB:BadSearchMethod');
        Observer.Verify();
    end;
}
