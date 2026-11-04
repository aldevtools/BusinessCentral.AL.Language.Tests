// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 85364
// Facts: corpus issue 670 (odd AL behavior leads, part E): `<`, `>`, `<=`, `>=` between enum values (the compiler gives warning AL0603, an
//   implicit conversion to Integer, and no error) for an enum whose ordinals are not in declaration order and for a value added by an
//   enumextension of the same app; an Integer or Option field assigned to an enum field (warning AL0603 only); `if E = Enum::X.FromInteger(n)`
//   and `case Enum::X.FromInteger(n) of` compile and run.
// Leads: microsoft/AL issues 5893, 5800, 5774, 5830, 5811.
// Probe: values observed on a local BC 29.0 tier; 27.5 and 28.5 checked by the corpus CI.
// BC versions: 27, 28, 29
enum 85364 "LT CV Level"
{
    Extensible = true;

    value(20; High) { Caption = 'High'; }
    value(1; Low) { Caption = 'Low'; }
    value(10; Surplus) { Caption = 'Surplus'; }
}

enumextension 85364 "LT CV Level Ext" extends "LT CV Level"
{
    value(5; Middle) { Caption = 'Middle'; }
}

table 85364 "LT CV Level Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Level; Enum "LT CV Level") { }
        field(3; Int; Integer) { }
        field(4; Opt; Option) { OptionMembers = Zero,One,Two; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 85364 "LT CV Enum Ordinal Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Cmp(L: Enum "LT CV Level"; R: Enum "LT CV Level"): Text
    begin
        exit(Format(L < R) + '|' + Format(L > R) + '|' + Format(L <= R) + '|' + Format(L >= R));
    end;

    [Test]
    procedure CompareOutOfOrderOrdinals()
    var
        Row: Record "LT CV Level Row";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('high_vs_low', Cmp(Enum::"LT CV Level"::High, Enum::"LT CV Level"::Low));
        Observer.Observe('low_vs_surplus', Cmp(Enum::"LT CV Level"::Low, Enum::"LT CV Level"::Surplus));
        Observer.Observe('surplus_vs_high', Cmp(Enum::"LT CV Level"::Surplus, Enum::"LT CV Level"::High));
        Observer.Observe('surplus_vs_surplus', Cmp(Enum::"LT CV Level"::Surplus, Enum::"LT CV Level"::Surplus));
        Observer.Observe('middle_vs_low', Cmp(Enum::"LT CV Level"::Middle, Enum::"LT CV Level"::Low));
        Observer.Observe('middle_vs_surplus', Cmp(Enum::"LT CV Level"::Middle, Enum::"LT CV Level"::Surplus));
        Row.Level := Row.Level::High;
        Observer.Observe('field_lt_surplus', Format(Row.Level < Row.Level::Surplus));
        Observer.Observe('field_gt_surplus', Format(Row.Level > Row.Level::Surplus));
        Row.Level := Row.Level::Middle;
        Observer.Observe('ext_field_lt_surplus', Format(Row.Level < Row.Level::Surplus));
        Observer.Observe('names', Format(Enum::"LT CV Level".Names().Count()) + ':' + Enum::"LT CV Level".Names().Get(1) + ',' + Enum::"LT CV Level".Names().Get(4));
        Observer.Expect('high_vs_low', 'No|Yes|No|Yes');
        Observer.Expect('low_vs_surplus', 'Yes|No|Yes|No');
        Observer.Expect('surplus_vs_high', 'Yes|No|Yes|No');
        Observer.Expect('surplus_vs_surplus', 'No|No|Yes|Yes');
        Observer.Expect('middle_vs_low', 'No|Yes|No|Yes');
        Observer.Expect('middle_vs_surplus', 'Yes|No|Yes|No');
        Observer.Expect('field_lt_surplus', 'No');
        Observer.Expect('field_gt_surplus', 'Yes');
        Observer.Expect('ext_field_lt_surplus', 'Yes');
        Observer.Expect('names', '4:High,Middle');
        Observer.Verify();
    end;

    [Test]
    procedure IntegerAndOptionToEnum()
    var
        Row: Record "LT CV Level Row";
        E: Enum "LT CV Level";
        X: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Row.Int := 10;
        Row.Level := Row.Int;
        Observer.Observe('int_field_10', Format(Row.Level));
        Row.Int := 5;
        Row.Level := Row.Int;
        Observer.Observe('int_field_5', Format(Row.Level));
        Row.Int := 3;
        Row.Level := Row.Int;
        Observer.Observe('int_field_3|format', Format(Row.Level));
        Observer.Observe('int_field_3|ordinal', Format(Row.Level.AsInteger()));
        X := 20;
        E := X;
        Observer.Observe('int_var_20', Format(E));
        Row.Opt := Row.Opt::One;
        Row.Level := Row.Opt;
        Observer.Observe('opt_one', Format(Row.Level));
        Row.Level := Enum::"LT CV Level".FromInteger(Row.Int + 2);
        Observer.Observe('frominteger_field', Format(Row.Level));
        Observer.Expect('int_field_10', 'Surplus');
        Observer.Expect('int_field_5', 'Middle');
        Observer.Expect('int_field_3|format', '3');
        Observer.Expect('int_field_3|ordinal', '3');
        Observer.Expect('int_var_20', 'High');
        Observer.Expect('opt_one', 'Low');
        Observer.Expect('frominteger_field', 'Middle');
        Observer.Verify();
    end;

    [Test]
    procedure FromIntegerInIfAndCase()
    var
        E: Enum "LT CV Level";
        X: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        E := E::Surplus;
        X := 10;
        Observer.Observe('if_eq', Format(E = Enum::"LT CV Level".FromInteger(X)));
        X := 1;
        Observer.Observe('if_ne', Format(E = Enum::"LT CV Level".FromInteger(X)));
        Observer.Observe('asinteger_eq', Format(E.AsInteger() = 10));
        X := 5;
        case Enum::"LT CV Level".FromInteger(X) of
            Enum::"LT CV Level"::Low:
                Observer.Observe('case_5', 'Low');
            Enum::"LT CV Level"::Middle:
                Observer.Observe('case_5', 'Middle');
            else
                Observer.Observe('case_5', 'else');
        end;
        X := 20;
        case Enum::"LT CV Level".FromInteger(X) of
            Enum::"LT CV Level"::High:
                Observer.Observe('case_20', 'High');
            else
                Observer.Observe('case_20', 'else');
        end;
        Observer.Expect('if_eq', 'Yes');
        Observer.Expect('if_ne', 'No');
        Observer.Expect('asinteger_eq', 'Yes');
        Observer.Expect('case_5', 'Middle');
        Observer.Expect('case_20', 'High');
        Observer.Verify();
    end;
}
