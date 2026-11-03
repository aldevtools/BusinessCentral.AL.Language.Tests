// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-text-record-joker-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 94734 - 94736
// Probe (writer Y89, from the runtime lane rt-pages-1103g; builds on pages/lt-y74-fqn-run/Y74FqnRunForms.al where the same three calls are held as Suspect_Err_* procedures):
// Page.Run and Page.RunModal with a fully qualified NAME that names no page: a missing page in an existing namespace, a table, a codeunit, a namespace without a
// name, an empty name; each with the name alone and with a record. One [Test] per call: one of them may end the session in a CLR exception.
// BC versions: 28.0 and later (runtime 17.0; BC 27 rejects the fully qualified name overloads, see must-not-compile 0664)

#if BC28PLUS
namespace LT.Y89.Fqn;

table 94734 "LT Y89 Fq Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 94735 "LT Y89 Fq Card"
{
    PageType = Card;
    SourceTable = "LT Y89 Fq Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Txt; Rec.Txt) { ApplicationArea = All; }
        }
    }
}

codeunit 94736 "LT Y89 Fq Run Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Txt := 'T1';
        Row.Insert();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_Missing_Run()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y89.Fqn.LT Y89 Fq Missing');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_Missing_RunRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y89.Fqn.LT Y89 Fq Missing', Row);
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_Missing_RunModal()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('LT.Y89.Fqn.LT Y89 Fq Missing');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_Missing_RunModalRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('LT.Y89.Fqn.LT Y89 Fq Missing', Row);
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_Empty_Run()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Fqn_Empty_RunRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('', Row);
        Observer.ObserveError('e');
        Observer.Expect('e|text', 'You tried to invoke the Page object with the ID 0 from the object LT Y89 Fq Run Tests. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('e|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_Empty_RunModal()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Fqn_Empty_RunModalRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('', Row);
        Observer.ObserveError('e');
        Observer.Expect('e|text', 'You tried to invoke the Page object with the ID 0 from the object LT Y89 Fq Run Tests. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('e|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_TableName_Run()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y89.Fqn.LT Y89 Fq Row');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_TableName_RunRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y89.Fqn.LT Y89 Fq Row', Row);
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_TableName_RunModal()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('LT.Y89.Fqn.LT Y89 Fq Row');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_TableName_RunModalRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('LT.Y89.Fqn.LT Y89 Fq Row', Row);
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_CodeunitName_Run()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y89.Fqn.LT Y89 Fq Run Tests');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_CodeunitName_RunRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y89.Fqn.LT Y89 Fq Run Tests', Row);
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_CodeunitName_RunModal()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('LT.Y89.Fqn.LT Y89 Fq Run Tests');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_CodeunitName_RunModalRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('LT.Y89.Fqn.LT Y89 Fq Run Tests', Row);
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_OtherNamespace_Run()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y89.Other.LT Y89 Fq Card');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_OtherNamespace_RunRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y89.Other.LT Y89 Fq Card', Row);
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_OtherNamespace_RunModal()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('LT.Y89.Other.LT Y89 Fq Card');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_OtherNamespace_RunModalRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('LT.Y89.Other.LT Y89 Fq Card', Row);
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_NamespaceOnly_Run()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y89.Fqn');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_NamespaceOnly_RunRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y89.Fqn', Row);
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_NamespaceOnly_RunModal()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('LT.Y89.Fqn');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_NamespaceOnly_RunModalRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('LT.Y89.Fqn', Row);
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Fqn_NoNamespace_Run()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT Y89 Fq Card');
        Observer.ObserveError('e');
        Observer.Expect('e|text', 'The provided object name is not fully qualified.');
        Observer.Expect('e|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_Fqn_NoNamespace_RunRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT Y89 Fq Card', Row);
        Observer.ObserveError('e');
        Observer.Expect('e|text', 'The provided object name is not fully qualified.');
        Observer.Expect('e|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_Fqn_NoNamespace_RunModal()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('LT Y89 Fq Card');
        Observer.ObserveError('e');
        Observer.Expect('e|text', 'The provided object name is not fully qualified.');
        Observer.Expect('e|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_Fqn_NoNamespace_RunModalRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('LT Y89 Fq Card', Row);
        Observer.ObserveError('e');
        Observer.Expect('e|text', 'The provided object name is not fully qualified.');
        Observer.Expect('e|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_Fqn_TrailingDot_Run()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y89.Fqn.');
        Observer.ObserveError('e');
        Observer.Expect('e|text', 'The provided object name is not fully qualified.');
        Observer.Expect('e|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_Fqn_TrailingDot_RunRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y89.Fqn.', Row);
        Observer.ObserveError('e');
        Observer.Expect('e|text', 'The provided object name is not fully qualified.');
        Observer.Expect('e|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_Fqn_TrailingDot_RunModal()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('LT.Y89.Fqn.');
        Observer.ObserveError('e');
        Observer.Expect('e|text', 'The provided object name is not fully qualified.');
        Observer.Expect('e|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_Fqn_TrailingDot_RunModalRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('LT.Y89.Fqn.', Row);
        Observer.ObserveError('e');
        Observer.Expect('e|text', 'The provided object name is not fully qualified.');
        Observer.Expect('e|code', 'InvalidOperation');
        Observer.Verify();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_Quoted_Run()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y89.Fqn."LT Y89 Fq Missing"');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_Quoted_RunRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y89.Fqn."LT Y89 Fq Missing"', Row);
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_Quoted_RunModal()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('LT.Y89.Fqn."LT Y89 Fq Missing"');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Windows BC 28.5 (writer Y89, 2026-11-03): this call ends in an uncatchable System.NullReferenceException (NavForm.Run*Async), the same on Windows as on Linux:
    // not an assertable behavior, so this is not a [Test]. The runtime refuses it.
    procedure Y89_Fqn_Quoted_RunModalRec()
    var
        Row: Record "LT Y89 Fq Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal('LT.Y89.Fqn."LT Y89 Fq Missing"', Row);
        Observer.ObserveError('e');
        Observer.Finish();
    end;
}
#endif
