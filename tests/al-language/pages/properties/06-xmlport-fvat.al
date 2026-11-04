// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

xmlport 72147 "LT P121 XP FieldValAttr"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(RowEl; "LT P121 Row")
            {
                fieldattribute(Id; RowEl.Id) { }
                fieldattribute(Txt; RowEl.Txt)
                {
                    FieldValidate = Yes;
                }
                fieldattribute(Qty; RowEl.Qty)
                {
                    FieldValidate = No;
                }
            }
        }
    }

}

// Writer BP (corpus issue 664, mibuso forum thread 293879): Rec and xRec inside OnValidate when an XMLport import validates the field
// (FieldValidate = Yes), for a new row and for an existing row updated with AutoUpdate = true.
table 82560 "LT BP XP xRec Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Other; Text[30]) { }
        field(3; Txt; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT P121 Log";
            begin
                Log.Add('val Rec=' + Format(Id) + '/' + Other + '/' + Txt + ' xRec=' + Format(xRec.Id) + '/' + xRec.Other + '/' + xRec.Txt +
                    ' CurrFieldNo=' + Format(CurrFieldNo));
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 82561 "LT BP XP xRec New"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(RowEl; "LT BP XP xRec Row")
            {
                fieldattribute(Id; RowEl.Id) { }
                fieldattribute(Other; RowEl.Other) { }
                fieldattribute(Txt; RowEl.Txt) { FieldValidate = Yes; }
            }
        }
    }
}

xmlport 82562 "LT BP XP xRec Update"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(RowEl; "LT BP XP xRec Row")
            {
                AutoUpdate = true;
                fieldattribute(Id; RowEl.Id) { }
                fieldattribute(Other; RowEl.Other) { }
                fieldattribute(Txt; RowEl.Txt) { FieldValidate = Yes; }
            }
        }
    }
}
codeunit 72148 "LT P121 XP FieldValAttr Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P121_Import()
    var
        Helper: Codeunit "LT P121 Helper";
        Log: Codeunit "LT P121 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        Helper.ImportText(Xmlport::"LT P121 XP FieldValAttr", '<Root><RowEl Id="21" Txt="t21" Qty="5"/></Root>');
        Observer.Observe('validate_log', Log.Take());
        Observer.Observe('rows', Helper.Rows());
        Observer.Expect('validate_log', 'val Txt=t21;');
        Observer.Expect('rows', '1:a:10,2:b:20,21:t21:5,');
        Observer.Verify();
    end;


    // Writer BP (corpus issue 664): xRec in OnValidate during an XMLport import, new row and AutoUpdate of an existing row.
    [Test]
    procedure BP_Import_xRecInOnValidate()
    var
        Helper: Codeunit "LT P121 Helper";
        Log: Codeunit "LT P121 Log";
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BP XP xRec Row";
        Rows: Text;
    begin
        Helper.Seed();
        Row.DeleteAll();
        Row.Id := 5;
        Row.Other := 'old other';
        Row.Txt := 'old';
        Row.Insert();
        Helper.ImportText(Xmlport::"LT BP XP xRec New", '<Root><RowEl Id="7" Other="o7" Txt="t7"/></Root>');
        Observer.Observe('new row', Log.Take());
        Helper.ImportText(Xmlport::"LT BP XP xRec Update", '<Root><RowEl Id="5" Other="new other" Txt="new"/></Root>');
        Observer.Observe('autoupdate row', Log.Take());
        if Row.FindSet() then
            repeat
                Rows += Format(Row.Id) + ':' + Row.Other + ':' + Row.Txt + ',';
            until Row.Next() = 0;
        Observer.Observe('rows', Rows);
        Observer.Expect('new row', 'val Rec=7/o7/t7 xRec=7/o7/t7 CurrFieldNo=0;');
        Observer.Expect('autoupdate row', 'val Rec=5/new other/new xRec=5/new other/new CurrFieldNo=0;');
        Observer.Expect('rows', '5:new other:new,7:o7:t7,');
        Observer.Verify();
    end;
}
