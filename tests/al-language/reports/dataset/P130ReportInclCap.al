// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-includecaption-property
// Scope: in-scope
// Fixtures used: P130Fixtures.al (tables 73536 and 73537), P130DatasetHelper.al (codeunit 73571), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: IncludeCaption = true on a column that reads a field of a GLOBAL RECORD VARIABLE (Base Application's Aged Accounts Receivable: column(Name1_Cust; Customer.Name) on an Integer data item)
//   and not a field of the data item's own table: the Labels block (name and text), the rows; next to a column of the data item's own field and one on a field of a variable of the same table
// Settles issue 130 reason 17 (IncludeCaption on a column that is not one field)
// BC versions: 29 (27 and 28 by CI)

report 73569 "LT P130 Incl Cap"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P130 Line")
        {
            column(LineName; Name) { IncludeCaption = true; }
            column(VarName; GItem.Name) { IncludeCaption = true; }
            column(VarNo; GItem."No.") { IncludeCaption = true; }
            column(VarQty; GItem.Qty) { }
            column(VarOpt; GItem.Opt) { IncludeCaption = true; }

            trigger OnAfterGetRecord()
            begin
                GItem.Get(CopyStr('ABC', Id, 1));
            end;
        }
    }

    var
        GItem: Record "LT P130 Item";
}

codeunit 73570 "LT P130 Report Incl Cap"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P130_IncludeCaptionOnVariableField_LabelsAndRows()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P130 Dataset";
        Rows: List of [Text];
        Labels: Text;
        i: Integer;
    begin
        Helper.Seed();
        Observer.Observe('read', Helper.Read(Report::"LT P130 Incl Cap", Rows, Labels));
        Observer.Observe('labels', Labels);
        Observer.Observe('row_count', Format(Rows.Count()));
        for i := 1 to Rows.Count() do
            Observer.Observe('row' + Format(i), Rows.Get(i));
        Observer.Expect('read', '');
        Observer.Expect('labels', 'LineNameCaption=Line name caption VarNameCaption=Name caption VarNoCaption=No. VarOptCaption=Opt ');
        Observer.Expect('row_count', '3');
        Observer.Expect('row1', 'LineName=line one VarName=Alpha VarNo=A VarQty=1 VarOpt=Alpha ');
        Observer.Expect('row2', 'LineName=line two VarName=Beta VarNo=B VarQty=2 VarOpt=Beta ');
        Observer.Expect('row3', 'LineName=line three VarName=Gamma VarNo=C VarQty=3 VarOpt=Gamma ');
        Observer.Verify();
    end;
}
