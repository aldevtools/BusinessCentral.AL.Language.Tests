// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-fielderror-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 74854 and codeunit 74855
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: TextConst variables may not compile in the Cloud app, and FieldError(Field, TextConst) may be ambiguous (own file so a compile failure drops only this file).
// Facts: GetLastErrorText(true) against GetLastErrorText(false) and GetLastErrorCode for FieldError(Field, TextConst) on a filled and a blank field.
// BC versions: 29 (27 and 28 by CI)

table 74854 "LT FETC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 74855 "LT FETC FieldError Const"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        MsgConst: TextConst ENU = 'text const message';

    local procedure Forms(Name: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Name + '_true', GetLastErrorText(true));
        Observer.Observe(Name + '_false', GetLastErrorText(false));
        Observer.Observe(Name + '_code', GetLastErrorCode());
        ClearLastError();
    end;

    [Test]
    procedure FieldErrorTextConst_FilledAndBlank_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT FETC Row";
    begin
        Row.Code := 'TC1';
        Row.Name := 'Actual';
        asserterror Row.FieldError(Name, MsgConst);
        Forms('filled', Observer);
        Row.Name := '';
        asserterror Row.FieldError(Name, MsgConst);
        Forms('blank', Observer);
        Observer.Expect('filled_true', 'FieldError on field LT FETC Row.Name, message: text const message');
        Observer.Expect('filled_false', 'Name text const message in LT FETC Row Code=''TC1''.');
        Observer.Expect('filled_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('blank_true', 'FieldError on field LT FETC Row.Name, message: text const message');
        Observer.Expect('blank_false', 'Name text const message in LT FETC Row Code=''TC1''.');
        Observer.Expect('blank_code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;
}
