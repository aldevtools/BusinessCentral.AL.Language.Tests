// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoformatexpression-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (tables 92843-92844, tableextension 92845, codeunits 92846-92847)
// Probe (writer Y43, gap cycle 4, G4-12): Format and StrSubstNo in code of a table field with AutoFormatType = 11 (a custom format expression):
//   a literal expression, an expression in a TABLE EXTENSION that calls a procedure of a GLOBAL record variable of the extension (a setup table
//   whose GetFormat returns '<Precision,%1><Standard Format,0>' from a stored field, or '' for an unknown field number), an expression without a
//   Precision code, and a procedure of the row itself; how often the expression runs, and Error() text substitution.
//   Culture: en-US (decimal point, comma as thousands separator) on the corpus containers and the SaaS sandbox.
// Probe: values recorded on the BC 29 SaaS sandbox; other BC versions are checked by the corpus CI matrix.

codeunit 92846 "LT Y43 AF11 Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

table 92843 "LT Y43 AF11 Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; Places; Text[5]) { InitValue = '2:5'; }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    procedure GetFormat(FieldNo: Integer): Text
    var
        Log: Codeunit "LT Y43 AF11 Log";
    begin
        Log.Add('getformat');
        if not Get() then
            Init();
        case FieldNo of
            FieldNo(Places):
                exit(StrSubstNo('<Precision,%1><Standard Format,0>', Places));
        end;
        exit('');
    end;
}

table 92844 "LT Y43 AF11 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Lit11; Decimal) { AutoFormatType = 11; AutoFormatExpression = '<Precision,2:5><Standard Format,0>'; }
        field(3; Plain; Decimal) { }
        field(4; Own11; Decimal) { AutoFormatType = 11; AutoFormatExpression = GetOwnFormat(); }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    procedure GetOwnFormat(): Text
    var
        Log: Codeunit "LT Y43 AF11 Log";
    begin
        Log.Add('own');
        exit('<Precision,1:1><Standard Format,0>');
    end;
}

tableextension 92845 "LT Y43 AF11 Row Ext" extends "LT Y43 AF11 Row"
{
    fields
    {
        field(92845; Ext11; Decimal) { AutoFormatType = 11; AutoFormatExpression = S.GetFormat(S.FieldNo(Places)); }
        field(92846; Ext11Blank; Decimal) { AutoFormatType = 11; AutoFormatExpression = S.GetFormat(0); }
        field(92847; Ext11Int; Decimal) { AutoFormatType = 11; AutoFormatExpression = '<Integer Thousand><Decimals,3>'; }
    }

    var
        S: Record "LT Y43 AF11 Setup";
}

codeunit 92847 "LT Y43 AF11 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedSetup(Places: Text[5])
    var
        S: Record "LT Y43 AF11 Setup";
        Log: Codeunit "LT Y43 AF11 Log";
    begin
        S.DeleteAll();
        S.Init();
        S.Places := Places;
        S.Insert();
        Log.Take();
    end;

    local procedure Value(Index: Integer): Decimal
    begin
        case Index of
            1:
                exit(1234.5);
            2:
                exit(10);
            3:
                exit(0.123456);
            4:
                exit(-2.5);
        end;
        exit(0);
    end;

    local procedure ValueName(Index: Integer): Text
    begin
        exit(Format(Value(Index), 0, 9));
    end;

    [Test]
    procedure Y43_G412_Ext11_StrSubstNo()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT Y43 AF11 Row";
        S: Record "LT Y43 AF11 Setup";
        i: Integer;
    begin
        SeedSetup('2:5');
        for i := 1 to 5 do begin
            T.Ext11 := Value(i);
            Observer.Observe('Ext11_StrSubstNo_' + ValueName(i), StrSubstNo('%1', T.Ext11));
        end;
        S.Get();
        S.Places := '0:2';
        S.Modify();
        for i := 1 to 5 do begin
            T.Ext11 := Value(i);
            Observer.Observe('Ext11_StrSubstNo_0:2_' + ValueName(i), StrSubstNo('%1', T.Ext11));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Y43_G412_Ext11_Format()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT Y43 AF11 Row";
        i: Integer;
    begin
        SeedSetup('2:5');
        for i := 1 to 5 do begin
            T.Ext11 := Value(i);
            Observer.Observe('Ext11_Format_' + ValueName(i), Format(T.Ext11));
            Observer.Observe('Ext11_Format01_' + ValueName(i), Format(T.Ext11, 0, 1));
            Observer.Observe('Ext11_Format02_' + ValueName(i), Format(T.Ext11, 0, 2));
            Observer.Observe('Ext11_Format09_' + ValueName(i), Format(T.Ext11, 0, 9));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Y43_G412_Lit11_StrSubstNo_Format()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT Y43 AF11 Row";
        i: Integer;
    begin
        for i := 1 to 5 do begin
            T.Lit11 := Value(i);
            T.Plain := Value(i);
            Observer.Observe('Lit11_StrSubstNo_' + ValueName(i), StrSubstNo('%1', T.Lit11));
            Observer.Observe('Lit11_Format_' + ValueName(i), Format(T.Lit11));
            Observer.Observe('Plain_StrSubstNo_' + ValueName(i), StrSubstNo('%1', T.Plain));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Y43_G412_Ext11Blank()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT Y43 AF11 Row";
        i: Integer;
    begin
        SeedSetup('2:5');
        for i := 1 to 5 do begin
            T.Ext11Blank := Value(i);
            Observer.Observe('Ext11Blank_StrSubstNo_' + ValueName(i), StrSubstNo('%1', T.Ext11Blank));
            Observer.Observe('Ext11Blank_Format_' + ValueName(i), Format(T.Ext11Blank));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Y43_G412_Ext11Int()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT Y43 AF11 Row";
        i: Integer;
    begin
        for i := 1 to 5 do begin
            T.Ext11Int := Value(i);
            Observer.Observe('Ext11Int_StrSubstNo_' + ValueName(i), StrSubstNo('%1', T.Ext11Int));
            Observer.Observe('Ext11Int_Format_' + ValueName(i), Format(T.Ext11Int));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Y43_G412_Own11()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT Y43 AF11 Row";
        Log: Codeunit "LT Y43 AF11 Log";
        i: Integer;
    begin
        Log.Take();
        for i := 1 to 5 do begin
            T.Own11 := Value(i);
            Observer.Observe('Own11_StrSubstNo_' + ValueName(i), StrSubstNo('%1', T.Own11));
            Observer.Observe('Own11_Format_' + ValueName(i), Format(T.Own11));
        end;
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y43_G412_Ext11_CallCount()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT Y43 AF11 Row";
        Log: Codeunit "LT Y43 AF11 Log";
    begin
        SeedSetup('2:5');
        T.Ext11 := 1234.5;
        Observer.Observe('logBefore', Log.Take());
        Observer.Observe('strSubstNoTwice', StrSubstNo('%1 %2', T.Ext11, T.Ext11));
        Observer.Observe('logStrSubstNo', Log.Take());
        Observer.Observe('format', Format(T.Ext11));
        Observer.Observe('logFormat', Log.Take());
        asserterror Error('%1', T.Ext11);
        Observer.Observe('errorText', GetLastErrorText());
        Observer.Observe('logError', Log.Take());
        Observer.Finish();
    end;
}
