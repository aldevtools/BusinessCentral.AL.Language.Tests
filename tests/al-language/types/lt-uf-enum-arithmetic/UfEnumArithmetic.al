// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-enums
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained enum 90321, table 90322, test codeunit 90323
// Probe (outside issue 6156): arithmetic with an Enum operand. `Usage - 1` on an Enum variable and an Enum field, + - * div mod (unary minus is must-not-compile case 2268), the Enum on either side, unary minus, the result
//   in a comparison and assigned to an Integer, a Decimal, an Enum and an Enum field; the value of the result. The compiler gives warning AL0603 (implicit conversion).
//   The comparison operators between enum values are in misc/lt-cv-odd-leads/CvEnumOrdinalCompare.al.
// BC versions: 27-29

enum 90321 "LT UF Usage"
{
    Extensible = true;

    value(0; " ") { }
    value(1; Quote) { }
    value(2; Order) { }
    value(3; Invoice) { }
}

table 90322 "LT UF Enum Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Usage; Enum "LT UF Usage") { }
        field(3; Other; Enum "LT UF Usage") { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 90323 "LT UF Enum Arithmetic"
{
    Subtype = Test;

    [Test]
    procedure Variable_Operators()
    var
        Observer: Codeunit "Probe Observer";
        Usage: Enum "LT UF Usage";
        Result: Integer;
    begin
        Usage := Usage::Invoice;
        Result := Usage - 1;
        Observer.Observe('minus 1', Format(Result));
        Result := Usage + 1;
        Observer.Observe('plus 1', Format(Result));
        Result := Usage * 2;
        Observer.Observe('times 2', Format(Result));
        Result := Usage div 2;
        Observer.Observe('div 2', Format(Result));
        Result := Usage mod 2;
        Observer.Observe('mod 2', Format(Result));
        Result := 10 - Usage;
        Observer.Observe('10 minus', Format(Result));
        Result := 1 + Usage;
        Observer.Observe('1 plus', Format(Result));
        Result := Usage - Usage::Quote;
        Observer.Observe('minus enum', Format(Result));
        Result := Usage + Usage;
        Observer.Observe('plus self', Format(Result));
        Observer.Finish();
    end;

    [Test]
    procedure Field_Operators()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT UF Enum Row";
        Result: Integer;
    begin
        Row.Usage := Row.Usage::Invoice;
        Result := Row.Usage - 1;
        Observer.Observe('minus 1', Format(Result));
        Result := Row.Usage + 1;
        Observer.Observe('plus 1', Format(Result));
        Result := Row.Usage * 3;
        Observer.Observe('times 3', Format(Result));
        Row.Other := Row.Other::Order;
        Result := Row.Usage - Row.Other;
        Observer.Observe('field minus field', Format(Result));
        Observer.Finish();
    end;

    [Test]
    procedure Comparisons_AndConditions()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT UF Enum Row";
        Usage: Enum "LT UF Usage";
    begin
        Usage := Usage::Invoice;
        Row.Usage := Row.Usage::Order;
        Observer.Observe('var - 1 = 2', Format(Usage - 1 = 2));
        Observer.Observe('var + 1 > 3', Format(Usage + 1 > 3));
        Observer.Observe('var - 1 = Order', Format(Usage - 1 = Usage::Order));
        Observer.Observe('field + 1 = Invoice', Format(Row.Usage + 1 = Row.Usage::Invoice));
        Observer.Observe('var - 1 = field', Format(Usage - 1 = Row.Usage));
        Observer.Observe('field + 1 = var', Format(Row.Usage + 1 = Usage));
        Observer.Observe('field + 1 > 2', Format(Row.Usage + 1 > 2));
        if Usage - 1 = 2 then
            Observer.Observe('if branch', 'taken')
        else
            Observer.Observe('if branch', 'not taken');
        Observer.Finish();
    end;

    [Test]
    procedure ResultIntoOtherTypes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT UF Enum Row";
        Usage: Enum "LT UF Usage";
        Back: Enum "LT UF Usage";
        Dec: Decimal;
        Txt: Text;
    begin
        Usage := Usage::Invoice;
        Dec := Usage - 1;
        Observer.Observe('decimal', Format(Dec));
        Dec := Usage / 2;
        Observer.Observe('decimal division', Format(Dec));
        Back := Usage - 1;
        Observer.Observe('enum var', Format(Back));
        Observer.Observe('enum var ordinal', Format(Back.AsInteger()));
        Row.Usage := Usage - 2;
        Observer.Observe('enum field', Format(Row.Usage));
        Row.Usage := Row.Usage + 1;
        Observer.Observe('enum field plus 1', Format(Row.Usage));
        Txt := Format(Usage - 1) + '/' + Format(Usage + 1);
        Observer.Observe('format', Txt);
        Observer.Observe('asinteger same', Format((Usage.AsInteger() - 1) = (Usage - 1)));
        Observer.Finish();
    end;

    [Test]
    procedure OutOfRangeResult()
    var
        Observer: Codeunit "Probe Observer";
        Usage: Enum "LT UF Usage";
        Back: Enum "LT UF Usage";
        Result: Integer;
    begin
        Usage := Usage::Quote;
        Result := Usage - 5;
        Observer.Observe('negative', Format(Result));
        ClearLastError();
        if not TryAssign(Back, Usage + 10) then
            Observer.ObserveError('assign 11 to enum')
        else
            Observer.Observe('assign 11 to enum', 'no error');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryAssign(var Target: Enum "LT UF Usage"; Value: Integer)
    begin
        Target := Enum::"LT UF Usage".FromInteger(Value);
    end;
}
