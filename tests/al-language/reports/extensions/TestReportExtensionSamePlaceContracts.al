// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained tables 69010 and 69011, report 69012, report extensions 69013 and
//                69014, codeunits 69015 (log) and 69016 (tests)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins where data items land when several are added at ONE place, by one extension or by two (see
// TestReportExtensionDataItemPlacementContracts.al for one item per place). Every addfirst / addbefore / addafter inserts its items
// immediately next to the anchor, so with extensions applied in object id order:
//  - addfirst(Parent): the items of the later extension come first; the items of one extension keep their declaration
//    order (G1, then F1, F2);
//  - addbefore(ChildA): the later extension's item stands closest to ChildA (X1, X2, Y1, ChildA);
//  - addafter(ChildA): the later extension's item stands closest to ChildA (ChildA, Z2, Z1); two items of one extension keep their
//    declaration order (Z1, Z1b);
//  - addlast(Parent): the items are appended in application order, so the later extension is last (L1, L2, M1).
// The run order and the order of the columns in the dataset are the same: Parent;G1;F1;F2;X1;X2;Y1;ChildA;Z2;Z1;Z1b;L1;L2;M1.
// An anchor on a data item another extension added is not probed.
// BC versions: 27.5

table 69010 "Probe SP Parent"
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

table 69011 "Probe SP Child"
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

codeunit 69015 "Probe SP Log"
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

report 69012 "Probe SP Base"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Parent; "Probe SP Parent")
        {
            dataitem(ChildA; "Probe SP Child")
            {
                DataItemLink = ParentId = field(Id);

                column(AId; Id) { }

                trigger OnAfterGetRecord()
                begin
                    SpLog.Add('ChildA');
                end;
            }

            column(PId; Id) { }

            trigger OnAfterGetRecord()
            begin
                SpLog.Add('Parent');
            end;
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeSpLayout.rdl';
            Caption = 'Probe layout';
        }
    }

    var
        SpLog: Codeunit "Probe SP Log";
}

reportextension 69013 "Probe SP Ext1" extends "Probe SP Base"
{
    dataset
    {
        addbefore(ChildA)
        {
            dataitem(X1; "Probe SP Child")
            {
                DataItemLink = ParentId = field(Id);

                column(X1Id; Id) { }

                trigger OnAfterGetRecord()
                begin
                    SpLog.Add('X1');
                end;
            }
            dataitem(X2; "Probe SP Child")
            {
                DataItemLink = ParentId = field(Id);

                column(X2Id; Id) { }

                trigger OnAfterGetRecord()
                begin
                    SpLog.Add('X2');
                end;
            }
        }
        addfirst(Parent)
        {
            dataitem(F1; "Probe SP Child")
            {
                DataItemLink = ParentId = field(Id);

                column(F1Id; Id) { }

                trigger OnAfterGetRecord()
                begin
                    SpLog.Add('F1');
                end;
            }
            dataitem(F2; "Probe SP Child")
            {
                DataItemLink = ParentId = field(Id);

                column(F2Id; Id) { }

                trigger OnAfterGetRecord()
                begin
                    SpLog.Add('F2');
                end;
            }
        }
        addafter(ChildA)
        {
            dataitem(Z1; "Probe SP Child")
            {
                DataItemLink = ParentId = field(Id);

                column(Z1Id; Id) { }

                trigger OnAfterGetRecord()
                begin
                    SpLog.Add('Z1');
                end;
            }
            dataitem(Z1b; "Probe SP Child")
            {
                DataItemLink = ParentId = field(Id);

                column(Z1bId; Id) { }

                trigger OnAfterGetRecord()
                begin
                    SpLog.Add('Z1b');
                end;
            }
        }
        addlast(Parent)
        {
            dataitem(L1; "Probe SP Child")
            {
                DataItemLink = ParentId = field(Id);

                column(L1Id; Id) { }

                trigger OnAfterGetRecord()
                begin
                    SpLog.Add('L1');
                end;
            }
            dataitem(L2; "Probe SP Child")
            {
                DataItemLink = ParentId = field(Id);

                column(L2Id; Id) { }

                trigger OnAfterGetRecord()
                begin
                    SpLog.Add('L2');
                end;
            }
        }
    }

    var
        SpLog: Codeunit "Probe SP Log";
}

reportextension 69014 "Probe SP Ext2" extends "Probe SP Base"
{
    dataset
    {
        addbefore(ChildA)
        {
            dataitem(Y1; "Probe SP Child")
            {
                DataItemLink = ParentId = field(Id);

                column(Y1Id; Id) { }

                trigger OnAfterGetRecord()
                begin
                    SpLog.Add('Y1');
                end;
            }
        }
        addfirst(Parent)
        {
            dataitem(G1; "Probe SP Child")
            {
                DataItemLink = ParentId = field(Id);

                column(G1Id; Id) { }

                trigger OnAfterGetRecord()
                begin
                    SpLog.Add('G1');
                end;
            }
        }
        addlast(Parent)
        {
            dataitem(M1; "Probe SP Child")
            {
                DataItemLink = ParentId = field(Id);

                column(M1Id; Id) { }

                trigger OnAfterGetRecord()
                begin
                    SpLog.Add('M1');
                end;
            }
        }
        addafter(ChildA)
        {
            dataitem(Z2; "Probe SP Child")
            {
                DataItemLink = ParentId = field(Id);

                column(Z2Id; Id) { }

                trigger OnAfterGetRecord()
                begin
                    SpLog.Add('Z2');
                end;
            }
        }
    }

    var
        SpLog: Codeunit "Probe SP Log";
}

codeunit 69016 "Probe Report Ext Same Place"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure ItemsAtOnePlace_AreInsertedNextToTheAnchor_LaterExtensionNearest()
    var
        SpParent: Record "Probe SP Parent";
        SpChild: Record "Probe SP Child";
        SpLog: Codeunit "Probe SP Log";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Columns: Text;
    begin
        SpChild.DeleteAll();
        SpParent.DeleteAll();
        SpParent.Id := 1;
        SpParent.Insert();
        SpChild.Id := 10;
        SpChild.ParentId := 1;
        SpChild.Insert();
        Commit();
        SpLog.Take();

        TempBlob.CreateOutStream(OutStr);
        Assert.IsTrue(Report.SaveAs(Report::"Probe SP Base", '', ReportFormat::Xml, OutStr), 'SaveAs');

        Assert.AreEqual('Parent;G1;F1;F2;X1;X2;Y1;ChildA;Z2;Z1;Z1b;L1;L2;M1;', SpLog.Take(), 'run order');

        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Line := Line.Trim();
            if Line.StartsWith('<Column name="') then
                Columns += Line.Substring(15, Line.IndexOf('"', 15) - 15) + ' ';
        end;
        Assert.AreEqual('PId G1Id F1Id F2Id X1Id X2Id Y1Id AId Z2Id Z1Id Z1bId L1Id L2Id M1Id ', Columns, 'columns in the dataset');
    end;
}
