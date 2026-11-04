// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT VaT Helper (71026), table LT VaT Rec (71027)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71036 "LT VaT Collections"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PassByValue_And_ByVar()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT VaT Helper";
        V: Variant;
    begin
        V := 5;
        Observer.Observe('byvalue_result', Helper.TakeByValue(V));
        Observer.Observe('byvalue_caller_after', Format(V));
        Observer.Observe('byvalue_caller_flags', Helper.Flags(V));
        Helper.TakeByVar(V);
        Observer.Observe('byvar_caller_after', Format(V));
        Observer.Observe('byvar_caller_flags', Helper.Flags(V));
        Clear(V);
        Helper.TakeByVar(V);
        Observer.Observe('byvar_from_empty', Format(V));
        Observer.Expect('byvalue_result', 'changed');
        Observer.Expect('byvalue_caller_after', '5');
        Observer.Expect('byvalue_caller_flags', 'Integer,');
        Observer.Expect('byvar_caller_after', 'changed');
        Observer.Expect('byvar_caller_flags', 'Text,');
        Observer.Expect('byvar_from_empty', 'changed');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_Holds_Copy_Of_Record_And_Container()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT VaT Rec";
        Back: Record "LT VaT Rec";
        V: Variant;
        L: List of [Text];
        BackL: List of [Text];
    begin
        Rec.DeleteAll();
        Rec.Id := 1; Rec.Name := 'one';
        V := Rec;
        Rec.Name := 'changed';
        Back := V;
        Observer.Observe('record_copy_name', Back.Name);
        L.Add('a');
        V := L;
        L.Add('b');
        BackL := V;
        Observer.Observe('list_after_add', Format(BackL.Count()));
        Observer.Expect('record_copy_name', 'one');
        Observer.Expect('list_after_add', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_Assigned_From_Variant_And_Clear()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT VaT Helper";
        A: Variant;
        B: Variant;
    begin
        A := 5; B := A;
        Observer.Observe('copy_flags', Helper.Flags(B));
        A := 'x';
        Observer.Observe('copy_independent', Format(B));
        Clear(B);
        Observer.Observe('cleared_flags', Helper.Flags(B));
        Observer.Observe('cleared_format', Format(B));
        B := A; A := B; B := B;
        Observer.Observe('self_assign', Format(B));
        Observer.Expect('copy_flags', 'Integer,');
        Observer.Expect('copy_independent', '5');
        Observer.Expect('cleared_flags', '');
        Observer.Expect('cleared_format', '');
        Observer.Expect('self_assign', 'x');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_Of_Variant_Nesting()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT VaT Helper";
        A: Variant;
        B: Variant;
        C: Variant;
    begin
        A := 7; B := A; C := B;
        Observer.Observe('flags', Helper.Flags(C));
        Observer.Observe('value', Format(C));
        Observer.Expect('flags', 'Integer,');
        Observer.Expect('value', '7');
        Observer.Verify();
    end;
}
