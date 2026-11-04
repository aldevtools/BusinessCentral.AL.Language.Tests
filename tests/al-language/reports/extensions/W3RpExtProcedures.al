//sub:reportext
// Report extension that adds data items and declares procedures and variables (md:202, md:257, md:973 of the batch list = the row of docs/probes-needed.md
// "A reportextension that declares procedures and adds data items", line 972 of the file).
// Base report with a nested item; the extension adds an item with addlast(Parent), modifies the Parent triggers (all six), and declares a global
// variable and procedures that read its own data item. Two base reports: one that SaveAs can run (columns, not ProcessingOnly) and one for Report.Run.

codeunit 67709 "W3 ExtProc Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 67710 "W3 ExtProc Save Base"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Parent; "W3 Row")
        {
            column(ParentId; Id) { }

            dataitem(ChildA; "W3 Child")
            {
                DataItemLink = ParentId = field(Id);

                column(ChildAId; Id) { }

                trigger OnPreDataItem()
                begin
                    L.Add('ChildA pre');
                end;

                trigger OnAfterGetRecord()
                begin
                    L.Add('ChildA row ' + Format(ChildA.Id));
                end;

                trigger OnPostDataItem()
                begin
                    L.Add('ChildA post');
                end;
            }

            trigger OnPreDataItem()
            begin
                L.Add('Parent pre');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('Parent row ' + Format(Parent.Id));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('Parent post');
            end;
        }
    }

    var
        L: Codeunit "W3 ExtProc Log";

    trigger OnPreReport()
    begin
        L.Add('base PreReport');
    end;

    trigger OnPostReport()
    begin
        L.Add('base PostReport');
    end;
}

reportextension 67711 "W3 ExtProc Save Ext" extends "W3 ExtProc Save Base"
{
    dataset
    {
        modify(Parent)
        {
            trigger OnBeforePreDataItem()
            begin
                L.Add('ext BeforePreDataItem');
            end;

            trigger OnAfterPreDataItem()
            begin
                L.Add('ext AfterPreDataItem');
            end;

            trigger OnBeforeAfterGetRecord()
            begin
                L.Add('ext BeforeAfterGetRecord ' + Format(Parent.Id));
            end;

            trigger OnAfterAfterGetRecord()
            begin
                L.Add('ext AfterAfterGetRecord ' + Format(Parent.Id));
            end;

            trigger OnBeforePostDataItem()
            begin
                L.Add('ext BeforePostDataItem');
            end;

            trigger OnAfterPostDataItem()
            begin
                L.Add('ext AfterPostDataItem');
            end;
        }
        addlast(Parent)
        {
            dataitem(ExtChild; "W3 Child")
            {
                DataItemLink = ParentId = field(Id);

                column(ExtChildId; Id) { }

                trigger OnPreDataItem()
                begin
                    L.Add('ExtChild pre');
                end;

                trigger OnAfterGetRecord()
                begin
                    L.Add('ExtChild row ' + Format(ExtChild.Id));
                end;

                trigger OnPostDataItem()
                begin
                    L.Add('ExtChild post');
                end;
            }
        }
    }

    var
        OwnCounter: Integer;
        L: Codeunit "W3 ExtProc Log";

    procedure ExtBump(): Integer
    begin
        OwnCounter += 1;
        exit(OwnCounter);
    end;

    procedure ExtChildCount(): Integer
    begin
        exit(ExtChild.Count());
    end;

    procedure ExtChildFilters(): Text
    var
        OldGroup: Integer;
        Link: Text;
    begin
        OldGroup := ExtChild.FilterGroup();
        ExtChild.FilterGroup(4);
        Link := ExtChild.GetFilter(ParentId);
        ExtChild.FilterGroup(OldGroup);
        exit('g0=[' + ExtChild.GetFilters() + '] g4=[' + Link + ']');
    end;

    trigger OnPreReport()
    begin
        OwnCounter += 10;
        L.Add('ext PreReport counter=' + Format(OwnCounter));
    end;

    trigger OnPostReport()
    begin
        L.Add('ext PostReport counter=' + Format(OwnCounter));
    end;
}

report 67712 "W3 ExtProc Run Base"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Parent; "W3 Row")
        {
            trigger OnAfterGetRecord()
            begin
                L.Add('Parent row ' + Format(Parent.Id));
            end;
        }
    }

    var
        L: Codeunit "W3 ExtProc Log";
}

reportextension 67713 "W3 ExtProc Run Ext" extends "W3 ExtProc Run Base"
{
    dataset
    {
        addlast(Parent)
        {
            dataitem(ExtChild; "W3 Child")
            {
                DataItemLink = ParentId = field(Id);

                trigger OnAfterGetRecord()
                begin
                    L.Add('ExtChild row ' + Format(ExtChild.Id));
                end;
            }
        }
    }

    var
        OwnCounter: Integer;
        L: Codeunit "W3 ExtProc Log";

    procedure ExtBump(): Integer
    begin
        OwnCounter += 1;
        exit(OwnCounter);
    end;

    procedure ExtChildCount(): Integer
    begin
        exit(ExtChild.Count());
    end;

    procedure ExtChildFilters(): Text
    var
        OldGroup: Integer;
        Link: Text;
    begin
        OldGroup := ExtChild.FilterGroup();
        ExtChild.FilterGroup(4);
        Link := ExtChild.GetFilter(ParentId);
        ExtChild.FilterGroup(OldGroup);
        exit('g0=[' + ExtChild.GetFilters() + '] g4=[' + Link + ']');
    end;

    trigger OnPreReport()
    begin
        OwnCounter += 10;
    end;
}

codeunit 67714 "W3 ExtProc Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "W3 ExtProc Log";
        Dataset: Codeunit "W3 Dataset";

    local procedure Seed()
    var
        Row: Record "W3 Row";
        Child: Record "W3 Child";
    begin
        Row.DeleteAll();
        Child.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Child.Id := 1;
        Child.ParentId := 1;
        Child.Insert();
        Child.Id := 2;
        Child.ParentId := 1;
        Child.Insert();
        Child.Id := 3;
        Child.ParentId := 2;
        Child.Insert();
        Commit();
        L.Take();
    end;

    // md:202: where an item added with addlast(Parent) runs relative to the parent's own nested item and to the six extension triggers of the parent.
    [Test]
    procedure SaveAs_AddedItem_RunsAfterTheParentsNestedItems_Order()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Dataset.Save(Report::"W3 ExtProc Save Base", '', Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.Observe('log', L.Take());
        Observer.Observe('structure', Dataset.Tokens(Xml));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('log', 'base PreReport;ext PreReport counter=10;ext BeforePreDataItem;Parent pre;ext AfterPreDataItem;ext BeforeAfterGetRecord 1;Parent row 1;ext AfterAfterGetRecord 1;ChildA pre;ChildA row 1;ChildA row 2;ChildA post;ExtChild pre;ExtChild row 1;ExtChild row 2;ExtChild post;ext BeforeAfterGetRecord 2;Parent row 2;ext AfterAfterGetRecord 2;ChildA pre;ChildA row 3;ChildA post;ExtChild pre;ExtChild row 3;ExtChild post;ext BeforePostDataItem;Parent post;ext AfterPostDataItem;base PostReport;ext PostReport counter=10;');
        Observer.Expect('structure', 'DIs DI c:ParentId DIs DI c:ChildAId /DI DI c:ChildAId /DI DI c:ExtChildId /DI DI c:ExtChildId /DI /DIs /DI DI c:ParentId DIs DI c:ChildAId /DI DI c:ExtChildId /DI /DIs /DI /DIs');
        Observer.Verify();
    end;

    // md:257 and md:973 (batch numbering): state of the extension's global variable across calls of its procedure on one base variable.
    [Test]
    procedure ExtensionProcedure_StateOnOneVariableAndOnANewVariable()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "W3 ExtProc Save Base";
        Other: Report "W3 ExtProc Save Base";
    begin
        Observer.Observe('first', Format(Rpt.ExtBump()));
        Observer.Observe('second', Format(Rpt.ExtBump()));
        Observer.Observe('other variable', Format(Other.ExtBump()));
        Observer.Observe('first again', Format(Rpt.ExtBump()));
        Clear(Rpt);
        Observer.Observe('after Clear', Format(Rpt.ExtBump()));
        Observer.Expect('first', '1');
        Observer.Expect('second', '2');
        Observer.Expect('other variable', '1');
        Observer.Expect('first again', '3');
        Observer.Expect('after Clear', '1');
        Observer.Verify();
    end;

    [Test]
    procedure ExtensionProcedure_StateAfterSaveAs_KeptOrReset()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "W3 ExtProc Save Base";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        Observer.Observe('before', Format(Rpt.ExtBump()));
        TempBlob.CreateOutStream(OutS);
        Rpt.SaveAs('', ReportFormat::Xml, OutS);
        Observer.Observe('log', L.Take());
        Observer.Observe('after SaveAs', Format(Rpt.ExtBump()));
        Observer.Expect('before', '1');
        Observer.Expect('log', 'base PreReport;ext PreReport counter=11;ext BeforePreDataItem;Parent pre;ext AfterPreDataItem;ext BeforeAfterGetRecord 1;Parent row 1;ext AfterAfterGetRecord 1;ChildA pre;ChildA row 1;ChildA row 2;ChildA post;ExtChild pre;ExtChild row 1;ExtChild row 2;ExtChild post;ext BeforeAfterGetRecord 2;Parent row 2;ext AfterAfterGetRecord 2;ChildA pre;ChildA row 3;ChildA post;ExtChild pre;ExtChild row 3;ExtChild post;ext BeforePostDataItem;Parent post;ext AfterPostDataItem;base PostReport;ext PostReport counter=11;');
        Observer.Expect('after SaveAs', '12');
        Observer.Verify();
    end;

    [Test]
    procedure ExtensionProcedure_StateAfterRun_KeptOrReset()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "W3 ExtProc Run Base";
    begin
        Seed();
        Observer.Observe('before', Format(Rpt.ExtBump()));
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Observe('after Run', Format(Rpt.ExtBump()));
        Observer.Expect('before', '1');
        Observer.Expect('log', 'Parent row 1;ExtChild row 1;ExtChild row 2;Parent row 2;ExtChild row 3;');
        Observer.Expect('after Run', '1');
        Observer.Verify();
    end;

    // md:973 (batch numbering): the extension's added data item as a record inside its procedure, before and after SaveAs.
    [Test]
    procedure ExtensionProcedure_ReadsAddedDataItem_BeforeAndAfterSaveAs()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "W3 ExtProc Save Base";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        Observer.Observe('count before', Format(Rpt.ExtChildCount()));
        Observer.Observe('filters before', Rpt.ExtChildFilters());
        TempBlob.CreateOutStream(OutS);
        Rpt.SaveAs('', ReportFormat::Xml, OutS);
        Observer.Observe('count after', Format(Rpt.ExtChildCount()));
        Observer.Observe('filters after', Rpt.ExtChildFilters());
        Observer.Expect('count before', '3');
        Observer.Expect('filters before', 'g0=[] g4=[]');
        Observer.Expect('count after', '1');
        Observer.Expect('filters after', 'g0=[] g4=[2]');
        Observer.Verify();
    end;

    [Test]
    procedure ExtensionProcedure_ReadsAddedDataItem_BeforeAndAfterRun()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "W3 ExtProc Run Base";
    begin
        Seed();
        Observer.Observe('count before', Format(Rpt.ExtChildCount()));
        Observer.Observe('filters before', Rpt.ExtChildFilters());
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Observe('count after', Format(Rpt.ExtChildCount()));
        Observer.Observe('filters after', Rpt.ExtChildFilters());
        Observer.Expect('count before', '3');
        Observer.Expect('filters before', 'g0=[] g4=[]');
        Observer.Expect('log', 'Parent row 1;ExtChild row 1;ExtChild row 2;Parent row 2;ExtChild row 3;');
        Observer.Expect('count after', '3');
        Observer.Expect('filters after', 'g0=[] g4=[]');
        Observer.Verify();
    end;
}
