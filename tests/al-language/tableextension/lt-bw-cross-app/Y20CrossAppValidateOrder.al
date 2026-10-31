// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/tableextension/devenv-onbeforevalidate-tableextension-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (69160); cross-app fixtures A (table "LT Y20 XA Validate" and its extension), B, C and D (one table
//   extension each, tests/al-language-xapp-*/Y20X?Validate.al); the table extension below.
// Probe (writer Y20, al-runner issue 6486): measured on a BC 29 SaaS sandbox; 27 and 28 by the corpus CI matrix.
// Facts: the order in which OnBeforeValidate, the table's OnValidate and OnAfterValidate of table extensions in five apps run for one
//   field. Dependencies: B and D depend on A, C on A, B and D, this app on A, B and C; B and D do not depend on each other. Two
//   extensions in one app are pinned in record/lt-modify-field-two/ModifyFieldTwoExtensions.al.
// BC versions: 27, 28, 29

tableextension 92118 "LT Y20 Main Validate Ext" extends "LT Y20 XA Validate"
{
    fields
    {
        modify(F)
        {
            trigger OnBeforeValidate()
            begin
                Log += 'main-before;';
            end;

            trigger OnAfterValidate()
            begin
                Log += 'main-after;';
            end;
        }
    }
}

codeunit 92119 "LT Y20 Cross App Validate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y20_CrossApp_ValidateOrder()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y20 XA Validate";
    begin
        R.Validate(F, 'X');
        Observer.Observe('validate', R.Log);
        R.Log := '';
        R.Validate(F, 'Y');
        Observer.Observe('validate_again', R.Log);
        Observer.Finish();
    end;

    [Test]
    procedure Y20_CrossApp_ValidateOrder_StoredRecord()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y20 XA Validate";
    begin
        R.DeleteAll();
        R.K := 'K1';
        R.Insert();
        R.Get('K1');
        R.Validate(F, 'Z');
        R.Modify();
        R.Get('K1');
        Observer.Observe('stored', R.F + '|' + R.Log);
        Observer.Finish();
    end;
}
