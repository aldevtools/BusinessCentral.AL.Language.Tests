// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: ALT Parent, ALT Child, ALT Universal, LT U Page Src (69585)
// Objects of the issue 601 probes (report, report extension, query, XmlPort properties); the tests are in UPropertyTests.al.
// Object ids 69783 to 69788. The layout files LtUReport.rdlc and LtUReport.docx are written by the AL compiler when they are missing, like the other layouts of this app.

report 69783 "LT U Report"
{
    RDLCLayout = './_fixtures/layouts/LtUReport.rdlc';
    WordLayout = './_fixtures/layouts/LtUReport.docx';
    InherentPermissions = X;
    InherentEntitlements = X;

    dataset
    {
        dataitem(Parent; "ALT Parent")
        {
            CalcFields = "Child Amount";

            column(EntryNo; "Entry No.") { }
            column(ParentCode; Code) { }

            trigger OnAfterGetRecord()
            var
                State: Codeunit "LT U State";
            begin
                State.Add(StrSubstNo('base count=%1 amount=%2 first=%3', Parent."Child Count", Parent."Child Amount", Parent."First Child Code"));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(RelField; RelField) { ApplicationArea = All; }
                field(AmtField; AmtField)
                {
                    ApplicationArea = All;
                    AutoFormatType = 11;
                    AutoFormatExpression = '<Precision,3:3><Standard Format,0>';
                }
                field(DfField; DfField) { ApplicationArea = All; }
            }
        }
    }

    labels
    {
        PlainLabel = 'A plain label';
    }

    var
        RelField: Integer;
        AmtField: Decimal;
        DfField: DateFormula;
}

reportextension 69784 "LT U Report Ext" extends "LT U Report"
{
    dataset
    {
        modify(Parent)
        {
            CalcFields = "Child Count";

            trigger OnAfterAfterGetRecord()
            var
                State: Codeunit "LT U State";
            begin
                State.Add(StrSubstNo('ext count=%1 amount=%2 first=%3', Parent."Child Count", Parent."Child Amount", Parent."First Child Code"));
            end;
        }
    }

    requestpage
    {
        layout
        {
            addlast(Content)
            {
                field(ExtRelField; ExtRelField) { ApplicationArea = All; TableRelation = "LT U Page Src".Id; }
            }
        }
    }

    var
        ExtRelField: Integer;
}

report 69785 "LT U Report Plain"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    trigger OnPreReport()
    var
        State: Codeunit "LT U State";
    begin
        State.Add('plain report ran');
    end;
}

query 69786 "LT U Query Inherent"
{
    InherentPermissions = X;
    InherentEntitlements = X;

    elements
    {
        dataitem(Universal; "ALT Universal")
        {
            column(EntryNo; "Entry No.") { }
        }
    }
}

query 69787 "LT U Query Plain"
{
    elements
    {
        dataitem(Universal; "ALT Universal")
        {
            column(EntryNo; "Entry No.") { }
        }
    }
}

xmlport 69788 "LT U XmlPort"
{
    Direction = Both;
    Format = Xml;
    DefaultFieldsValidation = false;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT U Page Src")
            {
                XmlName = 'Row';
                MinOccurs = Zero;
                fieldattribute(Id; Row.Id) { Occurrence = Required; }
                fieldattribute(Dec; Row.Dec) { Occurrence = Optional; }
                textattribute(RequiredText) { Occurrence = Required; }
                textattribute(OptionalText) { Occurrence = Optional; }
                textattribute(BigAttr) { Occurrence = Optional; TextType = BigText; }
                fieldelement(Txt; Row.Txt) { MinOccurs = Zero; FieldValidate = Yes; }
                fieldelement(Rel; Row.Rel) { MinOccurs = Zero; FieldValidate = Yes; }
                fieldelement(Rel2; Row.Rel2) { MinOccurs = Zero; }

                trigger OnAfterInitRecord()
                begin
                    Row.Note := 'init';
                end;

                trigger OnBeforeInsertRecord()
                var
                    State: Codeunit "LT U State";
                    BigValue: Text;
                begin
                    BigAttr.GetSubText(BigValue, 1);
                    State.Add(StrSubstNo('import required=%1 optional=%2 bigLength=%3 big=%4', RequiredText, OptionalText, BigAttr.Length(), BigValue));
                end;

                trigger OnPreXmlItem()
                begin
                    RequiredText := 'req';
                    OptionalText := '';
                    BigAttr.AddText('big');
                end;
            }
        }
    }
}
