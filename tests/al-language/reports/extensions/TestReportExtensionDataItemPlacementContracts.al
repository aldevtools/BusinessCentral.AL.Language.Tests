// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained tables 68810 and 68811, report 68812, report
//                extension 68813, codeunits 68814 (log) and 68815 (tests)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins where the data items a report extension adds run, and where they and their columns sit in the
// dataset. The compiler allows addbefore / addafter only on a NESTED data item (AL0680 "Cannot use
// addBefore or addAfter on a top-level data item"); addfirst / addlast name the parent.
//  - The order is positional: the parent's own trigger, the items added with addfirst(Parent),
//    those added with addbefore(ChildA), ChildA, those added with addafter(ChildA), those added with
//    addbefore(ChildB), ChildB, and the items added with addlast(Parent) last. Each runs once per parent row.
//  - Report.SaveAs lists the data items, and their columns, in the same order.
// BC versions: 27.5

table 68810 "Probe Place Parent"
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

table 68811 "Probe Place Child"
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

codeunit 68814 "Probe Place Log"
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

report 68812 "Probe Place Base"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Parent; "Probe Place Parent")
        {
            dataitem(ChildA; "Probe Place Child")
            {
                DataItemLink = ParentId = field(Id);

                column(AId; Id) { }

                trigger OnAfterGetRecord()
                begin
                    PlaceLog.Add('ChildA' + Format(Id));
                end;
            }
            dataitem(ChildB; "Probe Place Child")
            {
                DataItemLink = ParentId = field(Id);

                column(BId; Id) { }

                trigger OnAfterGetRecord()
                begin
                    PlaceLog.Add('ChildB' + Format(Id));
                end;
            }

            column(PId; Id) { }

            trigger OnAfterGetRecord()
            begin
                PlaceLog.Add('Parent' + Format(Id));
            end;
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbePlaceLayout.rdl';
            Caption = 'Probe layout';
        }
    }

    var
        PlaceLog: Codeunit "Probe Place Log";
}

reportextension 68813 "Probe Place Ext" extends "Probe Place Base"
{
    dataset
    {
        addfirst(Parent)
        {
            dataitem(ExtFirst; "Probe Place Child")
            {
                DataItemLink = ParentId = field(Id);

                column(EFId; Id) { }

                trigger OnAfterGetRecord()
                begin
                    PlaceLog.Add('ExtFirst' + Format(Id));
                end;
            }
        }
        addafter(ChildA)
        {
            dataitem(ExtAfterA; "Probe Place Child")
            {
                DataItemLink = ParentId = field(Id);

                column(EAId; Id) { }

                trigger OnAfterGetRecord()
                begin
                    PlaceLog.Add('ExtAfterA' + Format(Id));
                end;
            }
        }
        addbefore(ChildB)
        {
            dataitem(ExtBeforeB; "Probe Place Child")
            {
                DataItemLink = ParentId = field(Id);

                column(EBId; Id) { }

                trigger OnAfterGetRecord()
                begin
                    PlaceLog.Add('ExtBeforeB' + Format(Id));
                end;
            }
        }
        addlast(Parent)
        {
            dataitem(ExtLast; "Probe Place Child")
            {
                DataItemLink = ParentId = field(Id);

                column(ELId; Id) { }

                trigger OnAfterGetRecord()
                begin
                    PlaceLog.Add('ExtLast' + Format(Id));
                end;
            }
        }
        addbefore(ChildA)
        {
            dataitem(ExtBeforeA; "Probe Place Child")
            {
                DataItemLink = ParentId = field(Id);

                column(EBAId; Id) { }

                trigger OnAfterGetRecord()
                begin
                    PlaceLog.Add('ExtBeforeA' + Format(Id));
                end;
            }
        }
    }

    var
        PlaceLog: Codeunit "Probe Place Log";
}

codeunit 68815 "Probe Report Ext Placement"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure AddedDataItems_RunAndAreWrittenInPositionOrder()
    var
        PlaceParent: Record "Probe Place Parent";
        PlaceChild: Record "Probe Place Child";
        PlaceLog: Codeunit "Probe Place Log";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Names: Text;
        Columns: Text;
    begin
        PlaceChild.DeleteAll();
        PlaceParent.DeleteAll();
        PlaceParent.Id := 1;
        PlaceParent.Insert();
        PlaceChild.Id := 10;
        PlaceChild.ParentId := 1;
        PlaceChild.Insert();
        Commit();
        PlaceLog.Take();

        TempBlob.CreateOutStream(OutStr);
        Assert.IsTrue(Report.SaveAs(Report::"Probe Place Base", '', ReportFormat::Xml, OutStr), 'SaveAs');

        Assert.AreEqual('Parent1;ExtFirst10;ExtBeforeA10;ChildA10;ExtAfterA10;ExtBeforeB10;ChildB10;ExtLast10;', PlaceLog.Take(), 'trigger order');

        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Line := Line.Trim();
            if Line.StartsWith('<DataItem ') then
                Names += Line.Substring(Line.IndexOf('name="') + 6, Line.IndexOf('"', Line.IndexOf('name="') + 6) - Line.IndexOf('name="') - 6) + ' ';
            if Line.StartsWith('<Column ') then
                Columns += Line.Substring(15, Line.IndexOf('"', 15) - 15) + ' ';
        end;
        Assert.AreEqual('Parent ExtFirst ExtBeforeA ChildA ExtAfterA ExtBeforeB ChildB ExtLast ', Names, 'data items in the dataset');
        Assert.AreEqual('PId EFId EBAId AId EAId EBId BId ELId ', Columns, 'columns in the dataset');
    end;
}
