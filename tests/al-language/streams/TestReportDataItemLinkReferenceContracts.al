// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-dataitemlinkreference-property
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained tables 69060 and 69061, report 69062, codeunits 69063 (log) and 69064 (tests)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins DataItemLinkReference: a data item under an Integer data item (Mid, rows 1 and 2) under Parent (rows 1 and 2) that names Parent in
// DataItemLinkReference links its DataItemLink fields to the NAMED data item's current row, not to the enclosing one:
//  - ChildRef (ParentId = field(Id), DataItemLinkReference = Parent) gives, for Parent 1, child 1 under each of the two Mid rows and, for
//    Parent 2, children 2 and 3 under each of them;
//  - ChildNoRef (Id = field(Number)) without the reference links to the enclosing Mid row: Mid 1 gives child 1, Mid 2 child 2.
// BC versions: 27.5

table 69060 "Probe LR Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 69061 "Probe LR Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69063 "Probe LR Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

report 69062 "Probe LR Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Parent; "Probe LR Parent")
        {
            column(PId; Id) { }

            dataitem(Mid; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));

                column(MNum; Number) { }

                dataitem(ChildRef; "Probe LR Child")
                {
                    DataItemLink = ParentId = field(Id);
                    DataItemLinkReference = Parent;

                    column(CId; Id) { }

                    trigger OnAfterGetRecord()
                    begin
                        LrLog.Add('P' + Format(Parent.Id) + ' mid' + Format(Mid.Number) + ' ref child' + Format(ChildRef.Id));
                    end;
                }
                dataitem(ChildNoRef; "Probe LR Child")
                {
                    DataItemLink = Id = field(Number);

                    column(NId; Id) { }

                    trigger OnAfterGetRecord()
                    begin
                        LrLog.Add('P' + Format(Parent.Id) + ' mid' + Format(Mid.Number) + ' noref child' + Format(ChildNoRef.Id));
                    end;
                }
            }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeLrLayout.rdl';
            Caption = 'Probe layout';
        }
    }

    var
        LrLog: Codeunit "Probe LR Log";
}

codeunit 69064 "Probe DataItemLinkReference"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure DataItemLinkReference_LinksToTheNamedDataItem()
    var
        LrParent: Record "Probe LR Parent";
        LrChild: Record "Probe LR Child";
        LrLog: Codeunit "Probe LR Log";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        LrChild.DeleteAll();
        LrParent.DeleteAll();
        LrParent.Id := 1;
        LrParent.Insert();
        LrParent.Id := 2;
        LrParent.Insert();
        LrChild.Id := 1;
        LrChild.ParentId := 1;
        LrChild.Insert();
        LrChild.Id := 2;
        LrChild.ParentId := 2;
        LrChild.Insert();
        LrChild.Id := 3;
        LrChild.ParentId := 2;
        LrChild.Insert();
        Commit();
        LrLog.Take();

        TempBlob.CreateOutStream(OutStr);
        Assert.IsTrue(Report.SaveAs(Report::"Probe LR Report", '', ReportFormat::Xml, OutStr), 'SaveAs');

        Assert.AreEqual(
            'P1 mid1 ref child1;P1 mid1 noref child1;' +
            'P1 mid2 ref child1;P1 mid2 noref child2;' +
            'P2 mid1 ref child2;P2 mid1 ref child3;P2 mid1 noref child1;' +
            'P2 mid2 ref child2;P2 mid2 ref child3;P2 mid2 noref child2;',
            LrLog.Take(), 'log');
    end;
}
