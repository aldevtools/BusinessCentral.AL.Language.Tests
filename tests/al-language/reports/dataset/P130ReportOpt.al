// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-optioncaption-property
// Scope: in-scope
// Fixtures used: P130Fixtures.al (table 73536), P130DatasetHelper.al (codeunit 73571), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the dataset (Report.SaveAs Xml) of report columns that read a global Option VARIABLE: with the column property OptionCaption (Base Application's Purchase Reservation Avail. does
//   column(LineStatus; LineStatus) { OptionCaption = ' ,Shipped,...'; }), without it, as Format(variable), for the members, the blank member, and a caption list shorter than the member list
// Settles issue 130 reason 9 (report column LineStatus states the property OptionCaption: its effect on the dataset)
// BC versions: 29 (27 and 28 by CI)

report 73565 "LT P130 Opt Col"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P130 Item")
        {
            column(No; "No.") { }
            column(VarCap; GStatus)
            {
                OptionCaption = ' ,Shipped,Full Shipment,Partial Shipment,No Shipment';
            }
            column(VarNoCap; GStatus) { }
            column(VarFormat; Format(GStatus)) { }
            column(ShortCap; GShort)
            {
                OptionCaption = 'One,Two';
            }
            column(ShortNoCap; GShort) { }

            trigger OnAfterGetRecord()
            begin
                GStatus := Qty;
                GShort := Qty mod 3;
            end;
        }
    }

    var
        GStatus: Option " ",Shipped,"Full Shipment","Partial Shipment","No Shipment";
        GShort: Option A,B,C;
}

codeunit 73566 "LT P130 Report Opt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P130_OptionCaptionOnVariableColumn_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P130 Dataset";
        Rows: List of [Text];
        Labels: Text;
        i: Integer;
    begin
        Helper.Seed();
        Observer.Observe('read', Helper.Read(Report::"LT P130 Opt Col", Rows, Labels));
        Observer.Observe('row_count', Format(Rows.Count()));
        for i := 1 to Rows.Count() do
            Observer.Observe('row' + Format(i), Rows.Get(i));
        Observer.Observe('labels', Labels);
        Observer.Expect('read', '');
        Observer.Expect('row_count', '5');
        Observer.Expect('row1', 'No=A VarCap=Shipped VarNoCap=Shipped VarFormat=Shipped ShortCap=Two ShortNoCap=B ');
        Observer.Expect('row2', 'No=B VarCap=Full Shipment VarNoCap=Full Shipment VarFormat=Full Shipment ShortCap=2 ShortNoCap=C ');
        Observer.Expect('row3', 'No=C VarCap=Partial Shipment VarNoCap=Partial Shipment VarFormat=Partial Shipment ShortCap=One ShortNoCap=A ');
        Observer.Expect('row4', 'No=D VarCap=No Shipment VarNoCap=No Shipment VarFormat=No Shipment ShortCap=Two ShortNoCap=B ');
        Observer.Expect('row5', 'No=E VarCap=  VarNoCap=  VarFormat=  ShortCap=One ShortNoCap=A ');
        Observer.Expect('labels', '');
        Observer.Verify();
    end;
}
