// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-enum-assignment-compatibility
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), enums 70190-70194 and table 70190 (P67Defs.al), self-contained test codeunit 70196
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: P67 Option assigned to an Enum variable and field
// BC versions: 29 (27 and 28 by CI)

codeunit 70196 "LT P67 Option To Enum"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure OptionToEnumVariable_Dst()
    var
        Observer: Codeunit "Probe Observer";
        D: Enum "LT P67 Dst";
        Opt: Option A,B,C,D,E;
        i: Integer;
    begin
        for i := 0 to 4 do begin
            Opt := i;
            D := Opt;
            Observer.Observe('dst' + Format(i), '[' + Format(D) + ']');
            Observer.Observe('dst' + Format(i) + '_n', Format(D.AsInteger()));
        end;
        Observer.Expect('dst0', '[None]');
        Observer.Expect('dst0_n', '0');
        Observer.Expect('dst1', '[Uno]');
        Observer.Expect('dst1_n', '1');
        Observer.Expect('dst2', '[Dos]');
        Observer.Expect('dst2_n', '2');
        Observer.Expect('dst3', '[Tres Cap]');
        Observer.Expect('dst3_n', '3');
        Observer.Expect('dst4', '[4]');
        Observer.Expect('dst4_n', '4');
        Observer.Verify();
    end;

    [Test]
    procedure OptionToEnumVariable_Plain()
    var
        Observer: Codeunit "Probe Observer";
        P: Enum "LT P67 Plain";
        Opt: Option A,B,C,D,E;
        i: Integer;
    begin
        for i := 0 to 4 do begin
            Opt := i;
            P := Opt;
            Observer.Observe('plain' + Format(i), '[' + Format(P) + ']');
            Observer.Observe('plain' + Format(i) + '_n', Format(P.AsInteger()));
        end;
        Observer.Expect('plain0', '[None]');
        Observer.Expect('plain0_n', '0');
        Observer.Expect('plain1', '[Uno]');
        Observer.Expect('plain1_n', '1');
        Observer.Expect('plain2', '[Dos]');
        Observer.Expect('plain2_n', '2');
        Observer.Expect('plain3', '[3]');
        Observer.Expect('plain3_n', '3');
        Observer.Expect('plain4', '[4]');
        Observer.Expect('plain4_n', '4');
        Observer.Verify();
    end;

    [Test]
    procedure OptionToEnumField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P67 Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 0 to 4 do begin
            Row.Opt := i;
            Row.Kind := Row.Opt;
            Row.Plain := Row.Opt;
            Observer.Observe('kind' + Format(i), '[' + Format(Row.Kind) + ']');
            Observer.Observe('kind' + Format(i) + '_n', Format(Row.Kind.AsInteger()));
            Observer.Observe('plain' + Format(i), '[' + Format(Row.Plain) + ']');
            Observer.Observe('plain' + Format(i) + '_n', Format(Row.Plain.AsInteger()));
        end;
        Observer.Expect('kind0', '[None]');
        Observer.Expect('kind0_n', '0');
        Observer.Expect('plain0', '[None]');
        Observer.Expect('plain0_n', '0');
        Observer.Expect('kind1', '[Uno]');
        Observer.Expect('kind1_n', '1');
        Observer.Expect('plain1', '[Uno]');
        Observer.Expect('plain1_n', '1');
        Observer.Expect('kind2', '[Dos]');
        Observer.Expect('kind2_n', '2');
        Observer.Expect('plain2', '[Dos]');
        Observer.Expect('plain2_n', '2');
        Observer.Expect('kind3', '[Tres Cap]');
        Observer.Expect('kind3_n', '3');
        Observer.Expect('plain3', '[3]');
        Observer.Expect('plain3_n', '3');
        Observer.Expect('kind4', '[4]');
        Observer.Expect('kind4_n', '4');
        Observer.Expect('plain4', '[4]');
        Observer.Expect('plain4_n', '4');
        Observer.Verify();
    end;

    [Test]
    procedure OptionToEnumField_InsertLacking()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P67 Row";
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.Opt := Row.Opt::E;
        Row.Plain := Row.Opt;
        Row.Insert();
        Observer.Observe('insert_lacking_plain', 'no error');
        Observer.Observe('count', Format(Row.Count()));
        Row.Plain := Row.Plain::Dos;
        Row.Kind := Row.Opt;
        Row.Insert();
        Observer.Observe('insert_lacking_kind', 'no error');
        Observer.Observe('count2', Format(Row.Count()));
        Observer.Expect('insert_lacking_plain', 'no error');
        Observer.Expect('count', '1');
        Observer.Expect('insert_lacking_kind', 'no error');
        Observer.Expect('count2', '2');
        Observer.Verify();
    end;
}
