// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 80005, test codeunit 80006
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: Record.Get with an Integer value (a literal and a variable) on a table whose primary key is Code[20], with and without a row '123':
// the result, the record loaded, and the error text and code if it raises.
// BC versions: 27, 28, 29

table 80005 "LT AT Code Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 80006 "LT AT Get Integer On Code Key"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(WithRow: Boolean)
    var
        Row: Record "LT AT Code Key";
    begin
        Row.DeleteAll();
        Row."No." := 'A1';
        Row.Name := 'other';
        Row.Insert();
        if not WithRow then
            exit;
        Row."No." := '123';
        Row.Name := 'hit';
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryGetLiteral(var Row: Record "LT AT Code Key"; var Found: Boolean)
    begin
        Found := Row.Get(123);
    end;

    [TryFunction]
    local procedure TryGetVariable(var Row: Record "LT AT Code Key"; var Found: Boolean)
    var
        N: Integer;
    begin
        N := 123;
        Found := Row.Get(N);
    end;

    [TryFunction]
    local procedure TryGetBare(var Row: Record "LT AT Code Key")
    begin
        Row.Get(123);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; Mode: Integer)
    var
        Row: Record "LT AT Code Key";
        Found: Boolean;
        Ok: Boolean;
    begin
        ClearLastError();
        case Mode of
            0:
                Ok := TryGetLiteral(Row, Found);
            1:
                Ok := TryGetVariable(Row, Found);
            2:
                Ok := TryGetBare(Row);
        end;
        if Ok then begin
            if Mode <> 2 then
                Observer.Observe(Name, Format(Found))
            else
                Observer.Observe(Name, 'no error');
            Observer.Observe(Name + ' row', Row."No." + '|' + Row.Name);
        end else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure AT_GetInteger_CodeKey_RowExists()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(true);
        Probe(Observer, 'literal', 0);
        Probe(Observer, 'variable', 1);
        Observer.Expect('literal', 'Yes');
        Observer.Expect('literal row', '123|hit');
        Observer.Expect('variable', 'Yes');
        Observer.Expect('variable row', '123|hit');
        Observer.Verify();
    end;

    [Test]
    procedure AT_GetInteger_CodeKey_RowMissing_ReturnValueUsed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(false);
        Probe(Observer, 'literal', 0);
        Probe(Observer, 'variable', 1);
        Observer.Expect('literal', 'No');
        Observer.Expect('literal row', '|');
        Observer.Expect('variable', 'No');
        Observer.Expect('variable row', '|');
        Observer.Verify();
    end;

    [Test]
    procedure AT_GetInteger_CodeKey_RowMissing_Bare()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed(false);
        Probe(Observer, 'bare', 2);
        Observer.Expect('bare|text', 'The LT AT Code Key does not exist. Identification fields and values: No.=''123''');
        Observer.Expect('bare|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;
}
