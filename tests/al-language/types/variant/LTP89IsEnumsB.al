// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), enum LT P89 Color (74626)
// Probe: written against BC 29 (observation only; facts are measured later). P89
// BC versions: 29

codeunit 74629 "LT P89 Is Enums B"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Flags(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsObjectType() then
            R += 'ObjectType,';
        if V.IsReportFormat() then
            R += 'ReportFormat,';
        if V.IsTableConnectionType() then
            R += 'TableConnectionType,';
        if V.IsTestPermissions() then
            R += 'TestPermissions,';
        if V.IsTextEncoding() then
            R += 'TextEncoding,';
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
    procedure ObjectType_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: ObjectType;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := ObjectType::Table;
        V := X;
        Observer.Observe('table', Flags(V));
        Observer.Observe('table_format', Format(X));
        V := Format(X);
        Observer.Observe('table_text', Flags(V));
        X := ObjectType::Codeunit;
        V := X;
        Observer.Observe('codeunit', Flags(V));
        Observer.Observe('codeunit_format', Format(X));
        V := Format(X);
        Observer.Observe('codeunit_text', Flags(V));
        X := ObjectType::Page;
        V := X;
        Observer.Observe('page', Flags(V));
        Observer.Observe('page_format', Format(X));
        V := Format(X);
        Observer.Observe('page_text', Flags(V));
        V := ObjectType::Table;
        Observer.Observe('literal', Flags(V));
        Observer.Expect('default', 'ObjectType,');
        Observer.Expect('table', 'ObjectType,');
        Observer.Expect('table_format', 'Table');
        Observer.Expect('table_text', 'Text,');
        Observer.Expect('codeunit', 'ObjectType,');
        Observer.Expect('codeunit_format', 'Codeunit');
        Observer.Expect('codeunit_text', 'Text,');
        Observer.Expect('page', 'ObjectType,');
        Observer.Expect('page_format', 'Page');
        Observer.Expect('page_text', 'Text,');
        Observer.Expect('literal', 'ObjectType,');
        Observer.Verify();
    end;

    [Test]
    procedure ReportFormat_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: ReportFormat;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := ReportFormat::Pdf;
        V := X;
        Observer.Observe('pdf', Flags(V));
        Observer.Observe('pdf_format', Format(X));
        V := Format(X);
        Observer.Observe('pdf_text', Flags(V));
        X := ReportFormat::Word;
        V := X;
        Observer.Observe('word', Flags(V));
        Observer.Observe('word_format', Format(X));
        V := Format(X);
        Observer.Observe('word_text', Flags(V));
        X := ReportFormat::Excel;
        V := X;
        Observer.Observe('excel', Flags(V));
        Observer.Observe('excel_format', Format(X));
        V := Format(X);
        Observer.Observe('excel_text', Flags(V));
        V := ReportFormat::Pdf;
        Observer.Observe('literal', Flags(V));
        Observer.Expect('default', 'ReportFormat,');
        Observer.Expect('pdf', 'ReportFormat,');
        Observer.Expect('pdf_format', 'Pdf');
        Observer.Expect('pdf_text', 'Text,');
        Observer.Expect('word', 'ReportFormat,');
        Observer.Expect('word_format', 'Word');
        Observer.Expect('word_text', 'Text,');
        Observer.Expect('excel', 'ReportFormat,');
        Observer.Expect('excel_format', 'Excel');
        Observer.Expect('excel_text', 'Text,');
        Observer.Expect('literal', 'ReportFormat,');
        Observer.Verify();
    end;

    [Test]
    procedure TableConnectionType_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: TableConnectionType;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := TableConnectionType::CRM;
        V := X;
        Observer.Observe('crm', Flags(V));
        Observer.Observe('crm_format', Format(X));
        V := Format(X);
        Observer.Observe('crm_text', Flags(V));
        X := TableConnectionType::ExternalSQL;
        V := X;
        Observer.Observe('externalsql', Flags(V));
        Observer.Observe('externalsql_format', Format(X));
        V := Format(X);
        Observer.Observe('externalsql_text', Flags(V));
        V := TableConnectionType::CRM;
        Observer.Observe('literal', Flags(V));
        Observer.Expect('default', 'TableConnectionType,');
        Observer.Expect('crm', 'TableConnectionType,');
        Observer.Expect('crm_format', 'CRM');
        Observer.Expect('crm_text', 'Text,');
        Observer.Expect('externalsql', 'TableConnectionType,');
        Observer.Expect('externalsql_format', 'ExternalSQL');
        Observer.Expect('externalsql_text', 'Text,');
        Observer.Expect('literal', 'TableConnectionType,');
        Observer.Verify();
    end;

    [Test]
    procedure TestPermissions_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: TestPermissions;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := TestPermissions::Disabled;
        V := X;
        Observer.Observe('disabled', Flags(V));
        Observer.Observe('disabled_format', Format(X));
        V := Format(X);
        Observer.Observe('disabled_text', Flags(V));
        X := TestPermissions::Restrictive;
        V := X;
        Observer.Observe('restrictive', Flags(V));
        Observer.Observe('restrictive_format', Format(X));
        V := Format(X);
        Observer.Observe('restrictive_text', Flags(V));
        X := TestPermissions::NonRestrictive;
        V := X;
        Observer.Observe('nonrestrictive', Flags(V));
        Observer.Observe('nonrestrictive_format', Format(X));
        V := Format(X);
        Observer.Observe('nonrestrictive_text', Flags(V));
        X := TestPermissions::InheritFromTestCodeunit;
        V := X;
        Observer.Observe('inheritfromtestcodeunit', Flags(V));
        Observer.Observe('inheritfromtestcodeunit_format', Format(X));
        V := Format(X);
        Observer.Observe('inheritfromtestcodeunit_text', Flags(V));
        V := TestPermissions::Disabled;
        Observer.Observe('literal', Flags(V));
        Observer.Expect('default', 'TestPermissions,');
        Observer.Expect('disabled', 'TestPermissions,');
        Observer.Expect('disabled_format', 'Disabled');
        Observer.Expect('disabled_text', 'Text,');
        Observer.Expect('restrictive', 'TestPermissions,');
        Observer.Expect('restrictive_format', 'Restrictive');
        Observer.Expect('restrictive_text', 'Text,');
        Observer.Expect('nonrestrictive', 'TestPermissions,');
        Observer.Expect('nonrestrictive_format', 'NonRestrictive');
        Observer.Expect('nonrestrictive_text', 'Text,');
        Observer.Expect('inheritfromtestcodeunit', 'TestPermissions,');
        Observer.Expect('inheritfromtestcodeunit_format', 'InheritFromTestCodeunit');
        Observer.Expect('inheritfromtestcodeunit_text', 'Text,');
        Observer.Expect('literal', 'TestPermissions,');
        Observer.Verify();
    end;

    [Test]
    procedure TextEncoding_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: TextEncoding;
        V: Variant;
    begin
        V := X;
        Observer.Observe('default', Flags(V));
        X := TextEncoding::UTF8;
        V := X;
        Observer.Observe('utf8', Flags(V));
        Observer.Observe('utf8_format', Format(X));
        V := Format(X);
        Observer.Observe('utf8_text', Flags(V));
        X := TextEncoding::UTF16;
        V := X;
        Observer.Observe('utf16', Flags(V));
        Observer.Observe('utf16_format', Format(X));
        V := Format(X);
        Observer.Observe('utf16_text', Flags(V));
        X := TextEncoding::MSDos;
        V := X;
        Observer.Observe('msdos', Flags(V));
        Observer.Observe('msdos_format', Format(X));
        V := Format(X);
        Observer.Observe('msdos_text', Flags(V));
        X := TextEncoding::Windows;
        V := X;
        Observer.Observe('windows', Flags(V));
        Observer.Observe('windows_format', Format(X));
        V := Format(X);
        Observer.Observe('windows_text', Flags(V));
        V := TextEncoding::UTF8;
        Observer.Observe('literal', Flags(V));
        Observer.Expect('default', 'TextEncoding,');
        Observer.Expect('utf8', 'TextEncoding,');
        Observer.Expect('utf8_format', 'UTF8');
        Observer.Expect('utf8_text', 'Text,');
        Observer.Expect('utf16', 'TextEncoding,');
        Observer.Expect('utf16_format', 'UTF16');
        Observer.Expect('utf16_text', 'Text,');
        Observer.Expect('msdos', 'TextEncoding,');
        Observer.Expect('msdos_format', 'MSDos');
        Observer.Expect('msdos_text', 'Text,');
        Observer.Expect('windows', 'TextEncoding,');
        Observer.Expect('windows_format', 'Windows');
        Observer.Expect('windows_text', 'Text,');
        Observer.Expect('literal', 'TextEncoding,');
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
