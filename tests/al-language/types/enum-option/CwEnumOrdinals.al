// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/enum/enum-ordinals--method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained enum 85437, enumextensions 85438 and 85439, table 85440,
//   test codeunit 85441
// Probe: corpus #670 items 69, 70, 72 (writer CW). Facts:
//   - an enum declared out of ordinal order (1 Text, 3 Date, 2 Decimal) plus an enumextension (0 None, 4 Code): Names() and Ordinals()
//     order, Format, AsInteger, <, > and = between members, the order of a table key on the enum field and a range filter on it;
//   - an enumextension (of this app) of Base Application's extensible enum "Sales Line Type" with ordinal 6 (unused there: 0-5 and 10):
//     Names() and Ordinals() of the base enum include it. Reusing an ordinal the base enum has (1) is AL0231 (must-not-compile case 1782).
// Results: Names() and Ordinals() follow declaration order (base, then extension), not ordinal order; comparisons, key order and
//   range filters follow the ordinal; the Base Application enum lists the extension value 6 last (after 10).
// BC versions: 27, 28, 29

enum 85437 "LT CW Field Kind"
{
    Extensible = true;
    value(1; Text) { Caption = 'Text caption'; }
    value(3; Date) { Caption = 'Date caption'; }
    value(2; Decimal) { Caption = 'Decimal caption'; }
}

enumextension 85438 "LT CW Field Kind Ext" extends "LT CW Field Kind"
{
    value(4; Code) { Caption = 'Code caption'; }
    value(0; None) { Caption = 'None caption'; }
}

enumextension 85439 "LT CW Sales Line Type Ext" extends "Sales Line Type"
{
    value(6; "LT CW Six") { Caption = 'LT CW Six caption'; }
}

table 85440 "LT CW Kind Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT CW Field Kind") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByKind; Kind) { }
    }
}

codeunit 85441 "LT CW Enum Ordinals"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure JoinInts(L: List of [Integer]): Text
    var
        I: Integer;
        R: Text;
    begin
        foreach I in L do
            R += Format(I) + ',';
        exit(R);
    end;

    local procedure JoinTexts(L: List of [Text]): Text
    var
        T: Text;
        R: Text;
    begin
        foreach T in L do
            R += T + ',';
        exit(R);
    end;

    [Test]
    procedure CW_OutOfOrder_NamesOrdinalsFormat()
    var
        Observer: Codeunit "Probe Observer";
        K: Enum "LT CW Field Kind";
        Ord: Integer;
        R: Text;
    begin
        Observer.Observe('ordinals', JoinInts(Enum::"LT CW Field Kind".Ordinals()));
        Observer.Observe('names', JoinTexts(Enum::"LT CW Field Kind".Names()));
        foreach Ord in Enum::"LT CW Field Kind".Ordinals() do begin
            K := Enum::"LT CW Field Kind".FromInteger(Ord);
            R += Format(K) + '/' + Format(K, 0, 1) + '/' + Format(K, 0, 2) + ';';
        end;
        Observer.Observe('format', R);
        Observer.Expect('ordinals', '1,3,2,4,0,');
        Observer.Expect('names', 'Text,Date,Decimal,Code,None,');
        Observer.Expect('format', 'Text caption/Text caption/1;Date caption/Date caption/3;Decimal caption/Decimal caption/2;Code caption/Code caption/4;None caption/None caption/0;');
        Observer.Verify();
    end;

    [Test]
    procedure CW_OutOfOrder_Comparison()
    var
        Observer: Codeunit "Probe Observer";
        K: Enum "LT CW Field Kind";
    begin
        K := K::Date;
        Observer.Observe('Date > Decimal', Format(K > K::Decimal));
        Observer.Observe('Date < Code', Format(K < K::Code));
        Observer.Observe('Date = 3', Format(K = 3));
        Observer.Observe('Date = Date', Format(K = K::Date));
        K := K::None;
        Observer.Observe('None < Text', Format(K < K::Text));
        Observer.Observe('Decimal < Date', Format(Enum::"LT CW Field Kind"::Decimal < Enum::"LT CW Field Kind"::Date));
        Observer.Expect('Date > Decimal', 'Yes');
        Observer.Expect('Date < Code', 'Yes');
        Observer.Expect('Date = 3', 'Yes');
        Observer.Expect('Date = Date', 'Yes');
        Observer.Expect('None < Text', 'Yes');
        Observer.Expect('Decimal < Date', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CW_OutOfOrder_KeyOrderAndFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CW Kind Row";
        R: Text;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Kind := Row.Kind::Code;
        Row.Insert();
        Row.Id := 2;
        Row.Kind := Row.Kind::Text;
        Row.Insert();
        Row.Id := 3;
        Row.Kind := Row.Kind::Date;
        Row.Insert();
        Row.Id := 4;
        Row.Kind := Row.Kind::None;
        Row.Insert();
        Row.Id := 5;
        Row.Kind := Row.Kind::Decimal;
        Row.Insert();
        Row.SetCurrentKey(Kind);
        if Row.FindSet() then
            repeat
                R += Format(Row.Id) + ':' + Format(Row.Kind, 0, 2) + ',';
            until Row.Next() = 0;
        Observer.Observe('key order', R);
        Row.SetRange(Kind, Row.Kind::Text, Row.Kind::Date);
        R := '';
        if Row.FindSet() then
            repeat
                R += Format(Row.Id) + ',';
            until Row.Next() = 0;
        Observer.Observe('range Text..Date', R + '|' + Row.GetFilter(Kind));
        Row.SetRange(Kind, Row.Kind::Date, Row.Kind::Decimal);
        Observer.Observe('range Date..Decimal', Format(Row.Count()) + '|' + Row.GetFilter(Kind));
        Observer.Expect('key order', '4:0,2:1,5:2,3:3,1:4,');
        Observer.Expect('range Text..Date', '2,5,3,|Text caption..Date caption');
        Observer.Expect('range Date..Decimal', '0|Date caption..Decimal caption');
        Observer.Verify();
    end;

    [Test]
    procedure CW_BaseAppEnumExtension_NamesOrdinals()
    var
        Observer: Codeunit "Probe Observer";
        T: Enum "Sales Line Type";
    begin
        Observer.Observe('ordinals', JoinInts(Enum::"Sales Line Type".Ordinals()));
        Observer.Observe('names', JoinTexts(Enum::"Sales Line Type".Names()));
        T := Enum::"Sales Line Type".FromInteger(6);
        Observer.Observe('six', Format(T) + '|' + Format(T, 0, 1) + '|' + Format(T.AsInteger()));
        Observer.Observe('six > ten', Format(T > T::"Allocation Account"));
        Observer.Expect('ordinals', '0,1,2,3,4,5,10,6,');
        Observer.Expect('names', ' ,G/L Account,Item,Resource,Fixed Asset,Charge (Item),Allocation Account,LT CW Six,');
        Observer.Expect('six', 'LT CW Six caption|LT CW Six caption|6');
        Observer.Expect('six > ten', 'No');
        Observer.Verify();
    end;
}
