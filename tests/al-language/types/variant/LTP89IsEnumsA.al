// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), enum LT P89 Color (74626)
// Probe: written against BC 29 (observation only; facts are measured later). P89
// BC versions: 29

codeunit 74628 "LT P89 Is Enums A"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Flags(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsAction() then
            R += 'Action,';
        if V.IsClientType() then
            R += 'ClientType,';
        if V.IsDataClassification() then
            R += 'DataClassification,';
        if V.IsDefaultLayout() then
            R += 'DefaultLayout,';
        if V.IsExecutionMode() then
            R += 'ExecutionMode,';
        if V.IsOption() then
            R += 'Option,';
        if V.IsInteger() then
            R += 'Integer,';
        if V.IsBigInteger() then
            R += 'BigInteger,';
        if V.IsText() then
            R += 'Text,';
        if V.IsCode() then
            R += 'Code,';
        if V.IsChar() then
            R += 'Char,';
        if V.IsByte() then
            R += 'Byte,';
        if V.IsBoolean() then
            R += 'Boolean,';
        exit(R);
    end;

    [Test]
    procedure Action_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: Action;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := Action::OK;
        V := X;
        Observer.Observe('ok', Flags(V));
        Observer.Observe('ok_format', Format(X));
        V := Format(X);
        Observer.Observe('ok_text', Flags(V));
        X := Action::Cancel;
        V := X;
        Observer.Observe('cancel', Flags(V));
        Observer.Observe('cancel_format', Format(X));
        V := Format(X);
        Observer.Observe('cancel_text', Flags(V));
        X := Action::LookupOK;
        V := X;
        Observer.Observe('lookupok', Flags(V));
        Observer.Observe('lookupok_format', Format(X));
        V := Format(X);
        Observer.Observe('lookupok_text', Flags(V));
        X := Action::LookupCancel;
        V := X;
        Observer.Observe('lookupcancel', Flags(V));
        Observer.Observe('lookupcancel_format', Format(X));
        V := Format(X);
        Observer.Observe('lookupcancel_text', Flags(V));
        X := Action::Yes;
        V := X;
        Observer.Observe('yes', Flags(V));
        Observer.Observe('yes_format', Format(X));
        V := Format(X);
        Observer.Observe('yes_text', Flags(V));
        X := Action::No;
        V := X;
        Observer.Observe('no', Flags(V));
        Observer.Observe('no_format', Format(X));
        V := Format(X);
        Observer.Observe('no_text', Flags(V));
        V := Action::OK;
        Observer.Observe('literal', Flags(V));
        Observer.Expect('default', 'Action,');
        Observer.Expect('ok', 'Action,');
        Observer.Expect('ok_format', 'OK');
        Observer.Expect('ok_text', 'Text,');
        Observer.Expect('cancel', 'Action,');
        Observer.Expect('cancel_format', 'Cancel');
        Observer.Expect('cancel_text', 'Text,');
        Observer.Expect('lookupok', 'Action,');
        Observer.Expect('lookupok_format', 'LookupOK');
        Observer.Expect('lookupok_text', 'Text,');
        Observer.Expect('lookupcancel', 'Action,');
        Observer.Expect('lookupcancel_format', 'LookupCancel');
        Observer.Expect('lookupcancel_text', 'Text,');
        Observer.Expect('yes', 'Action,');
        Observer.Expect('yes_format', 'Yes');
        Observer.Expect('yes_text', 'Text,');
        Observer.Expect('no', 'Action,');
        Observer.Expect('no_format', 'No');
        Observer.Expect('no_text', 'Text,');
        Observer.Expect('literal', 'Action,');
        Observer.Verify();
    end;

    [Test]
    procedure ClientType_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: ClientType;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := ClientType::Web;
        V := X;
        Observer.Observe('web', Flags(V));
        Observer.Observe('web_format', Format(X));
        V := Format(X);
        Observer.Observe('web_text', Flags(V));
        X := ClientType::Background;
        V := X;
        Observer.Observe('background', Flags(V));
        Observer.Observe('background_format', Format(X));
        V := Format(X);
        Observer.Observe('background_text', Flags(V));
        X := ClientType::Default;
        V := X;
        Observer.Observe('default', Flags(V));
        Observer.Observe('default_format', Format(X));
        V := Format(X);
        Observer.Observe('default_text', Flags(V));
        V := ClientType::Web;
        Observer.Observe('literal', Flags(V));
        Observer.Expect('default', 'ClientType,');
        Observer.Expect('web', 'ClientType,');
        Observer.Expect('web_format', 'Web');
        Observer.Expect('web_text', 'Text,');
        Observer.Expect('background', 'ClientType,');
        Observer.Expect('background_format', 'Background');
        Observer.Expect('background_text', 'Text,');
        Observer.Expect('default', 'ClientType,');
        Observer.Expect('default_format', 'Default');
        Observer.Expect('default_text', 'Text,');
        Observer.Expect('literal', 'ClientType,');
        Observer.Verify();
    end;

    [Test]
    procedure DataClassification_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: DataClassification;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := DataClassification::CustomerContent;
        V := X;
        Observer.Observe('customercontent', Flags(V));
        Observer.Observe('customercontent_format', Format(X));
        V := Format(X);
        Observer.Observe('customercontent_text', Flags(V));
        X := DataClassification::SystemMetadata;
        V := X;
        Observer.Observe('systemmetadata', Flags(V));
        Observer.Observe('systemmetadata_format', Format(X));
        V := Format(X);
        Observer.Observe('systemmetadata_text', Flags(V));
        X := DataClassification::ToBeClassified;
        V := X;
        Observer.Observe('tobeclassified', Flags(V));
        Observer.Observe('tobeclassified_format', Format(X));
        V := Format(X);
        Observer.Observe('tobeclassified_text', Flags(V));
        V := DataClassification::CustomerContent;
        Observer.Observe('literal', Flags(V));
        Observer.Expect('default', 'DataClassification,');
        Observer.Expect('customercontent', 'DataClassification,');
        Observer.Expect('customercontent_format', 'CustomerContent');
        Observer.Expect('customercontent_text', 'Text,');
        Observer.Expect('systemmetadata', 'DataClassification,');
        Observer.Expect('systemmetadata_format', 'SystemMetadata');
        Observer.Expect('systemmetadata_text', 'Text,');
        Observer.Expect('tobeclassified', 'DataClassification,');
        Observer.Expect('tobeclassified_format', 'ToBeClassified');
        Observer.Expect('tobeclassified_text', 'Text,');
        Observer.Expect('literal', 'DataClassification,');
        Observer.Verify();
    end;

    [Test]
    procedure DefaultLayout_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: DefaultLayout;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := DefaultLayout::RDLC;
        V := X;
        Observer.Observe('rdlc', Flags(V));
        Observer.Observe('rdlc_format', Format(X));
        V := Format(X);
        Observer.Observe('rdlc_text', Flags(V));
        X := DefaultLayout::Word;
        V := X;
        Observer.Observe('word', Flags(V));
        Observer.Observe('word_format', Format(X));
        V := Format(X);
        Observer.Observe('word_text', Flags(V));
        V := DefaultLayout::RDLC;
        Observer.Observe('literal', Flags(V));
        Observer.Expect('default', 'DefaultLayout,');
        Observer.Expect('rdlc', 'DefaultLayout,');
        Observer.Expect('rdlc_format', 'RDLC');
        Observer.Expect('rdlc_text', 'Text,');
        Observer.Expect('word', 'DefaultLayout,');
        Observer.Expect('word_format', 'Word');
        Observer.Expect('word_text', 'Text,');
        Observer.Expect('literal', 'DefaultLayout,');
        Observer.Verify();
    end;

    [Test]
    procedure ExecutionMode_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: ExecutionMode;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := ExecutionMode::Debug;
        V := X;
        Observer.Observe('debug', Flags(V));
        Observer.Observe('debug_format', Format(X));
        V := Format(X);
        Observer.Observe('debug_text', Flags(V));
        X := ExecutionMode::Standard;
        V := X;
        Observer.Observe('standard', Flags(V));
        Observer.Observe('standard_format', Format(X));
        V := Format(X);
        Observer.Observe('standard_text', Flags(V));
        V := ExecutionMode::Debug;
        Observer.Observe('literal', Flags(V));
        Observer.Expect('default', 'ExecutionMode,');
        Observer.Expect('debug', 'ExecutionMode,');
        Observer.Expect('debug_format', 'Debug');
        Observer.Expect('debug_text', 'Text,');
        Observer.Expect('standard', 'ExecutionMode,');
        Observer.Expect('standard_format', 'Standard');
        Observer.Expect('standard_text', 'Text,');
        Observer.Expect('literal', 'ExecutionMode,');
        Observer.Verify();
    end;

    [Test]
    procedure NearTypes()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,B,C;
        E: Enum "LT P89 Color";
        I: Integer;
        Bi: BigInteger;
        T: Text;
        C: Code[10];
        V: Variant;
    begin
        V := O; Observer.Observe('option', Flags(V));
        V := E; Observer.Observe('enum', Flags(V));
        V := I; Observer.Observe('integer', Flags(V));
        V := Bi; Observer.Observe('biginteger', Flags(V));
        T := 'x'; V := T; Observer.Observe('text', Flags(V));
        C := 'X'; V := C; Observer.Observe('code', Flags(V));
        V := true; Observer.Observe('boolean', Flags(V));
        Observer.Expect('option', 'Option,');
        Observer.Expect('enum', 'Option,');
        Observer.Expect('integer', 'Integer,');
        Observer.Expect('biginteger', 'BigInteger,');
        Observer.Expect('text', 'Text,');
        Observer.Expect('code', 'Code,');
        Observer.Expect('boolean', 'Boolean,');
        Observer.Verify();
    end;
}
