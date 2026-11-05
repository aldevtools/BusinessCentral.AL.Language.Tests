// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-work-with-translation-files
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 95994 and its table extension 95995; table extension 95996 of Base Application's
//   "Sales Invoice Header"; translation units in Translations/AL Language Coverage Tests.nl-NL.xlf.
// Probe (al-runner issue 7144, writer r7144): the caption of a field a table extension of this app adds, under GlobalLanguage 1043 (the app ships
//   an nl-NL translation file with a TableExtension unit for it), read with FieldCaption and with FieldRef.Caption; for an extension of the app's
//   own table and of a Base Application table. Controls: a field of the app's own table with a unit, an extension field without a unit, the same
//   reads under 1031 (no de-DE file) and 1033.
// BC versions: 27.0+

table 95994 "LT R7144 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'Row number';
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

tableextension 95995 "LT R7144 Row Ext" extends "LT R7144 Row"
{
    fields
    {
        field(95995; "R7144 Ext Code"; Code[20])
        {
            Caption = 'Extension code';
            DataClassification = SystemMetadata;
        }
        field(95996; "R7144 Ext Plain"; Text[30])
        {
            Caption = 'Plain caption';
            DataClassification = SystemMetadata;
        }
    }
}

tableextension 95996 "LT R7144 SIH Ext" extends "Sales Invoice Header"
{
    fields
    {
        field(95997; "R7144 SIH Payment ID"; Text[30])
        {
            Caption = 'Payment ID';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 95997 "LT R7144 Ext Field Caption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure R7144_FieldCaption_Dutch()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT R7144 Row";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1043);
        Observer.Observe('own table field', Row.FieldCaption("No."));
        Observer.Observe('own table extension field with unit', Row.FieldCaption("R7144 Ext Code"));
        Observer.Observe('own table extension field without unit', Row.FieldCaption("R7144 Ext Plain"));
        Observer.Observe('base app table extension field', SalesInvoiceHeader.FieldCaption("R7144 SIH Payment ID"));
        GlobalLanguage(Saved);
        Observer.Finish();
    end;

    [Test]
    procedure R7144_FieldRefCaption_Dutch()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1043);
        Observer.Observe('own table field', RefCaption(Database::"LT R7144 Row", 1));
        Observer.Observe('own table extension field with unit', RefCaption(Database::"LT R7144 Row", 95995));
        Observer.Observe('own table extension field without unit', RefCaption(Database::"LT R7144 Row", 95996));
        Observer.Observe('base app table extension field', RefCaption(Database::"Sales Invoice Header", 95997));
        GlobalLanguage(Saved);
        Observer.Finish();
    end;

    [Test]
    procedure R7144_Captions_GermanWithoutFile()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT R7144 Row";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        Observer.Observe('own table extension field', Row.FieldCaption("R7144 Ext Code"));
        Observer.Observe('base app table extension field', SalesInvoiceHeader.FieldCaption("R7144 SIH Payment ID"));
        Observer.Observe('base app table extension field ref', RefCaption(Database::"Sales Invoice Header", 95997));
        GlobalLanguage(Saved);
        Observer.Finish();
    end;

    [Test]
    procedure R7144_Captions_English()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT R7144 Row";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        Observer.Observe('own table extension field', Row.FieldCaption("R7144 Ext Code"));
        Observer.Observe('base app table extension field', SalesInvoiceHeader.FieldCaption("R7144 SIH Payment ID"));
        Observer.Observe('base app table extension field ref', RefCaption(Database::"Sales Invoice Header", 95997));
        GlobalLanguage(Saved);
        Observer.Finish();
    end;

    local procedure RefCaption(TableNo: Integer; FieldNo: Integer): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Caption: Text;
    begin
        RecRef.Open(TableNo);
        FldRef := RecRef.Field(FieldNo);
        Caption := FldRef.Caption();
        RecRef.Close();
        exit(Caption);
    end;
}
