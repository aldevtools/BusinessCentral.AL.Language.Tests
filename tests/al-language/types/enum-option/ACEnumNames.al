// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/enum/enum-names--method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: Enum.Names() and Enum.Ordinals() on an extensible enum with sparse ordinals, a value name with a space, and an enum extension. Settles #626 items 6 and 7.
// BC versions: 27, 28, 29

enum 77500 "LT AC Names Enum"
{
    Extensible = true;

    value(0; Alpha) { }
    value(5; "Beta Value") { Caption = 'Beta caption'; }
    value(2; Gamma) { }
    value(100; Delta) { }
}

enumextension 77501 "LT AC Names Ext" extends "LT AC Names Enum"
{
    value(50; "Ext Fifty") { }
    value(7; ExtSeven) { }
}

enum 77503 "LT AC Names Single"
{
    value(3; Only) { }
}

codeunit 77502 "LT AC Enum Names"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_EnumNames()
    var
        Observer: Codeunit "Probe Observer";
        Names: List of [Text];
        Name: Text;
        Joined: Text;
        E: Enum "LT AC Names Enum";
    begin
        Names := E.Names();
        Observer.Observe('count', Format(Names.Count()));
        foreach Name in Names do
            Joined += '[' + Name + ']';
        Observer.Observe('names', Joined);
        Names := Enum::"LT AC Names Enum".Names();
        Observer.Observe('count_qualified', Format(Names.Count()));
        Observer.Observe('first', Names.Get(1));
        Observer.Observe('last', Names.Get(Names.Count()));
        Observer.Observe('contains_space_name', Format(Names.Contains('Beta Value')));
        Observer.Observe('contains_ext_name', Format(Names.Contains('Ext Fifty')));
        Observer.Observe('contains_caption', Format(Names.Contains('Beta caption')));
        Observer.Expect('count', '6');
        Observer.Expect('names', '[Alpha][Beta Value][Gamma][Delta][Ext Fifty][ExtSeven]');
        Observer.Expect('count_qualified', '6');
        Observer.Expect('first', 'Alpha');
        Observer.Expect('last', 'ExtSeven');
        Observer.Expect('contains_space_name', 'Yes');
        Observer.Expect('contains_ext_name', 'Yes');
        Observer.Expect('contains_caption', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AC_EnumOrdinals()
    var
        Observer: Codeunit "Probe Observer";
        Ordinals: List of [Integer];
        Ordinal: Integer;
        Joined: Text;
        E: Enum "LT AC Names Enum";
    begin
        Ordinals := E.Ordinals();
        Observer.Observe('count', Format(Ordinals.Count()));
        foreach Ordinal in Ordinals do
            Joined += '[' + Format(Ordinal) + ']';
        Observer.Observe('ordinals', Joined);
        Ordinals := Enum::"LT AC Names Enum".Ordinals();
        Observer.Observe('count_qualified', Format(Ordinals.Count()));
        Observer.Observe('first', Format(Ordinals.Get(1)));
        Observer.Observe('last', Format(Ordinals.Get(Ordinals.Count())));
        Observer.Observe('contains_ext_ordinal', Format(Ordinals.Contains(50)));
        Observer.Observe('contains_missing', Format(Ordinals.Contains(1)));
        Observer.Expect('count', '6');
        Observer.Expect('ordinals', '[0][5][2][100][50][7]');
        Observer.Expect('count_qualified', '6');
        Observer.Expect('first', '0');
        Observer.Expect('last', '7');
        Observer.Expect('contains_ext_ordinal', 'Yes');
        Observer.Expect('contains_missing', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AC_EnumNamesOrdinalsSingle()
    var
        Observer: Codeunit "Probe Observer";
        S: Enum "LT AC Names Single";
        Names: List of [Text];
        Ordinals: List of [Integer];
    begin
        Names := S.Names();
        Ordinals := S.Ordinals();
        Observer.Observe('names_count', Format(Names.Count()));
        Observer.Observe('name_1', Names.Get(1));
        Observer.Observe('ordinals_count', Format(Ordinals.Count()));
        Observer.Observe('ordinal_1', Format(Ordinals.Get(1)));
        Observer.Expect('names_count', '1');
        Observer.Expect('name_1', 'Only');
        Observer.Expect('ordinals_count', '1');
        Observer.Expect('ordinal_1', '3');
        Observer.Verify();
    end;

    [Test]
    procedure AC_EnumNamesMatchOrdinals()
    var
        Observer: Codeunit "Probe Observer";
        E: Enum "LT AC Names Enum";
        Names: List of [Text];
        Ordinals: List of [Integer];
        i: Integer;
        Joined: Text;
    begin
        Names := E.Names();
        Ordinals := E.Ordinals();
        Observer.Observe('same_count', Format(Names.Count() = Ordinals.Count()));
        for i := 1 to Names.Count() do begin
            E := Enum::"LT AC Names Enum".FromInteger(Ordinals.Get(i));
            Joined += '[' + Format(Ordinals.Get(i)) + '=' + Format(E) + '/' + Names.Get(i) + ']';
        end;
        Observer.Observe('pairs', Joined);
        Observer.Expect('same_count', 'Yes');
        Observer.Expect('pairs', '[0=Alpha/Alpha][5=Beta caption/Beta Value][2=Gamma/Gamma][100=Delta/Delta][50=Ext Fifty/Ext Fifty][7=ExtSeven/ExtSeven]');
        Observer.Verify();
    end;
}
