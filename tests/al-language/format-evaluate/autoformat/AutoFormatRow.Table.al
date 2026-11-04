// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoformattype-property
// Scope: in-scope
// Fixtures used: none
//
// Source table for the AutoFormat suite. One Decimal field carried by every page control
// under test, so the only thing differing between controls is the page-side formatting
// property — not the stored value. "Currency Code" feeds AutoFormatType = 1's
// AutoFormatExpression; it is deliberately a plain Code[10] with no TableRelation, so the
// suite measures the platform's AutoFormat resolution rather than a Currency record lookup.

table 60603 "ALT AutoFormat Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { DataClassification = CustomerContent; }
        field(2; "Amount"; Decimal) { DataClassification = CustomerContent; }
        field(3; "Currency Code"; Code[10]) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
