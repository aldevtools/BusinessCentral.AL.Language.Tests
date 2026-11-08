// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-work-with-translation-files
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table extension 96160 of Base Application's Item (adds one field, modifies two captions);
//   enum extension 96161 of Base Application's "Sales Document Type"; translation units in Translations/AL Language Coverage Tests.nl-NL.xlf.
// Probe (al-runner issue 7184, writer cw-7184): what a Base Application caption reads under GlobalLanguage 1043 when this app ships an nl-NL
//   file and extends the table (or enum) the caption belongs to: Item.FieldCaption and FieldRef.Caption of fields the extension does not
//   touch, of fields it modifies with and without a unit in the file, of a field whose unit in the file has the id of the ORIGINAL Base
//   Application property (a cross-app unit), Format and Evaluate of a Base Application enum value under an enum extension of this app,
//   and Sales Invoice Header."No." (this app extends that table in R7144ExtFieldCaption.al).
// The corpus ships only an nl-NL file (a de-DE file would break R7144_Captions_GermanWithoutFile), so the language is Dutch.
// BC versions: 27.0+

tableextension 96160 "LT R7184 Item Ext" extends Item
{
    fields
    {
        field(96160; "R7184 Ext Code"; Code[20])
        {
            Caption = 'R7184 extension code';
            DataClassification = SystemMetadata;
        }
        modify(Description)
        {
            Caption = 'LT Item Description';
        }
        modify("Search Description")
        {
            Caption = 'LT Item Search';
        }
        modify("Description 2")
        {
            Caption = 'LT Item Description Two';
        }
        modify("Unit Price")
        {
            Caption = 'LT Item Price';
        }
    }
}

enumextension 96161 "LT R7184 Sales Doc Type Ext" extends "Sales Document Type"
{
    value(96160; "R7184 Extra")
    {
        Caption = 'R7184 Extra type';
    }
}

codeunit 96162 "LT R7184 Base App Caption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure R7184_ItemFieldCaptions_Dutch()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record Item;
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1043);
        Observer.Observe('Item.FieldCaption Base Unit of Measure (not touched)', Item.FieldCaption("Base Unit of Measure"));
        Observer.Observe('FieldRef.Caption 8 Base Unit of Measure (not touched)', RefCaption(Database::Item, 8));
        Observer.Observe('Item.FieldCaption Description (modify, unit)', Item.FieldCaption(Description));
        Observer.Observe('FieldRef.Caption 3 Description (modify, unit)', RefCaption(Database::Item, 3));
        Observer.Observe('Item.FieldCaption Search Description (modify, no unit)', Item.FieldCaption("Search Description"));
        Observer.Observe('FieldRef.Caption 4 Search Description (modify, no unit)', RefCaption(Database::Item, 4));
        Observer.Observe('Item.FieldCaption Description 2 (modify, unit with Field kind)', Item.FieldCaption("Description 2"));
        Observer.Observe('Item.FieldCaption Unit Price (modify, unit with the original Item id)', Item.FieldCaption("Unit Price"));
        Observer.Observe('Item.FieldCaption Unit Cost (cross-app unit)', Item.FieldCaption("Unit Cost"));
        Observer.Observe('FieldRef.Caption 22 Unit Cost (cross-app unit)', RefCaption(Database::Item, 22));
        Observer.Observe('Item.FieldCaption extension field', Item.FieldCaption("R7184 Ext Code"));
        Observer.Observe('FieldRef.Caption extension field', RefCaption(Database::Item, 96160));
        GlobalLanguage(Saved);
        Observer.Expect('Item.FieldCaption Base Unit of Measure (not touched)', 'Base Unit of Measure');
        Observer.Expect('FieldRef.Caption 8 Base Unit of Measure (not touched)', 'Base Unit of Measure');
        Observer.Expect('Item.FieldCaption Description (modify, unit)', 'LT Item Description');
        Observer.Expect('FieldRef.Caption 3 Description (modify, unit)', 'LT Item Description');
        Observer.Expect('Item.FieldCaption Search Description (modify, no unit)', 'LT Item Search');
        Observer.Expect('FieldRef.Caption 4 Search Description (modify, no unit)', 'LT Item Search');
        Observer.Expect('Item.FieldCaption Description 2 (modify, unit with Field kind)', 'LT Item Description Two');
        Observer.Expect('Item.FieldCaption Unit Price (modify, unit with the original Item id)', 'LT Item Price');
        Observer.Expect('Item.FieldCaption Unit Cost (cross-app unit)', 'Unit Cost');
        Observer.Expect('FieldRef.Caption 22 Unit Cost (cross-app unit)', 'Unit Cost');
        Observer.Expect('Item.FieldCaption extension field', 'R7184 extension code');
        Observer.Expect('FieldRef.Caption extension field', 'R7184 extension code');
        Observer.Verify();
    end;

    [Test]
    procedure R7184_ItemFieldCaptions_English()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record Item;
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        Observer.Observe('Item.FieldCaption Base Unit of Measure', Item.FieldCaption("Base Unit of Measure"));
        Observer.Observe('FieldRef.Caption 8', RefCaption(Database::Item, 8));
        Observer.Observe('Item.FieldCaption Description (modify)', Item.FieldCaption(Description));
        Observer.Observe('Item.FieldCaption Unit Cost', Item.FieldCaption("Unit Cost"));
        GlobalLanguage(Saved);
        Observer.Expect('Item.FieldCaption Base Unit of Measure', 'Base Unit of Measure');
        Observer.Expect('FieldRef.Caption 8', 'Base Unit of Measure');
        Observer.Expect('Item.FieldCaption Description (modify)', 'LT Item Description');
        Observer.Expect('Item.FieldCaption Unit Cost', 'Unit Cost');
        Observer.Verify();
    end;

    [Test]
    procedure R7184_ItemOptionCaptions_Dutch()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record Item;
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1043);
        Item.Type := Item.Type::Service;
        Observer.Observe('Format Item.Type Service', Format(Item.Type));
        Item."Costing Method" := Item."Costing Method"::Average;
        Observer.Observe('Format Item.Costing Method Average', Format(Item."Costing Method"));
        Observer.Observe('FieldRef.OptionCaption 10 Type', RefOptionCaption(Database::Item, 10));
        Observer.Observe('FieldRef.OptionCaption 21 Costing Method', RefOptionCaption(Database::Item, 21));
        Observer.Observe('Item.FieldCaption Type', Item.FieldCaption(Type));
        Observer.Observe('Item.FieldCaption Costing Method', Item.FieldCaption("Costing Method"));
        GlobalLanguage(Saved);
        Observer.Expect('Format Item.Type Service', 'Service');
        Observer.Expect('Format Item.Costing Method Average', 'Average');
        Observer.Expect('FieldRef.OptionCaption 10 Type', 'Inventory,Service,Non-Inventory');
        Observer.Expect('FieldRef.OptionCaption 21 Costing Method', 'FIFO,LIFO,Specific,Average,Standard');
        Observer.Expect('Item.FieldCaption Type', 'Type');
        Observer.Expect('Item.FieldCaption Costing Method', 'Costing Method');
        Observer.Verify();
    end;

    [Test]
    procedure R7184_BaseAppEnumValue_Dutch()
    var
        Observer: Codeunit "Probe Observer";
        SalesDocType: Enum "Sales Document Type";
        Parsed: Enum "Sales Document Type";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1043);
        SalesDocType := SalesDocType::Order;
        Observer.Observe('Format Base App value Order', Format(SalesDocType));
        Observer.Observe('Format own extension value', Format(SalesDocType::"R7184 Extra"));
        Observer.Observe('Evaluate Order ok', BoolText(Evaluate(Parsed, 'Order')));
        Observer.Observe('Evaluate Order value', Format(Parsed.AsInteger(), 0, 9));
        Parsed := SalesDocType::Quote;
        Observer.Observe('Evaluate Bestelling ok', BoolText(Evaluate(Parsed, 'Bestelling')));
        Observer.Observe('Evaluate Bestelling value', Format(Parsed.AsInteger(), 0, 9));
        Parsed := SalesDocType::Quote;
        Observer.Observe('Evaluate own value caption ok', BoolText(Evaluate(Parsed, 'R7184 Extra type')));
        Observer.Observe('Evaluate own value caption value', Format(Parsed.AsInteger(), 0, 9));
        Observer.Observe('Ordinals', Format(SalesDocType.Ordinals().Count()));
        GlobalLanguage(Saved);
        Observer.Expect('Format Base App value Order', 'Order');
        Observer.Expect('Format own extension value', 'R7184 Extra type');
        Observer.Expect('Evaluate Order ok', 'True');
        Observer.Expect('Evaluate Order value', '1');
        Observer.Expect('Evaluate Bestelling ok', 'False');
        Observer.Expect('Evaluate Bestelling value', '0');
        Observer.Expect('Evaluate own value caption ok', 'True');
        Observer.Expect('Evaluate own value caption value', '96160');
        Observer.Expect('Ordinals', '7');
        Observer.Verify();
    end;

    [Test]
    procedure R7184_SalesInvoiceHeaderNo_Dutch()
    var
        Observer: Codeunit "Probe Observer";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1043);
        Observer.Observe('SalesInvoiceHeader.FieldCaption No.', SalesInvoiceHeader.FieldCaption("No."));
        Observer.Observe('FieldRef.Caption 3 No.', RefCaption(Database::"Sales Invoice Header", 3));
        GlobalLanguage(Saved);
        Observer.Expect('SalesInvoiceHeader.FieldCaption No.', 'No.');
        Observer.Expect('FieldRef.Caption 3 No.', 'No.');
        Observer.Verify();
    end;

    local procedure BoolText(Value: Boolean): Text
    begin
        if Value then
            exit('True');
        exit('False');
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

    local procedure RefOptionCaption(TableNo: Integer; FieldNo: Integer): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Caption: Text;
    begin
        RecRef.Open(TableNo);
        FldRef := RecRef.Field(FieldNo);
        Caption := FldRef.OptionCaption();
        RecRef.Close();
        exit(Caption);
    end;
}
