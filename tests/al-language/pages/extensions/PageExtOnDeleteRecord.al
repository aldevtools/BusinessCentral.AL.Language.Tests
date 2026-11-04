// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-ondeleterecord-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 73950, log 73951, page 73952, page extension 73953, test codeunit 73954
// Probe: written against BC; every literal asserted below is what BC produced (BC 27, 28 and 29 by the corpus CI matrix).
// Settles GitHub issue 216 item 10 (NP Retail blockers): a page extension's OnDeleteRecord trigger when a row is deleted through a TestPage: whether it runs,
// whether it runs before or after the base page's trigger, and whether its exit(false) (or the base page's) stops the delete (row still there, error or not).
// TestPage has no member for the standard Delete command, so the delete is issued by a page action with Rec.Delete(true) (the base page's own trigger
// for that path is pinned in pages/lt-page-filtergroup-assumptions/P99DeleteEvent.al); the log says which of the two triggers ran, in order.
// BC versions: 27, 28, 29

table 73950 "LT PXD Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73951 "LT PXD Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        BaseResult: Boolean;
        ExtResult: Boolean;

    procedure Reset(NewBase: Boolean; NewExt: Boolean)
    begin
        Entries := '';
        BaseResult := NewBase;
        ExtResult := NewExt;
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;

    procedure Base(): Boolean
    begin
        exit(BaseResult);
    end;

    procedure Ext(): Boolean
    begin
        exit(ExtResult);
    end;
}

page 73952 "LT PXD List"
{
    PageType = List;
    SourceTable = "LT PXD Row";
    ApplicationArea = All;
    UsageCategory = None;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteIt)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    var
        Log: Codeunit "LT PXD Log";
    begin
        Log.Add('base');
        exit(Log.Base());
    end;
}

pageextension 73953 "LT PXD List Ext" extends "LT PXD List"
{
    trigger OnDeleteRecord(): Boolean
    var
        Log: Codeunit "LT PXD Log";
    begin
        Log.Add('ext');
        exit(Log.Ext());
    end;
}

codeunit 73954 "LT PXD Ext OnDeleteRecord"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Run(BaseResult: Boolean; ExtResult: Boolean; Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT PXD Log";
        Row: Record "LT PXD Row";
        List: TestPage "LT PXD List";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Log.Reset(BaseResult, ExtResult);
        List.OpenEdit();
        List.GoToKey(1);
        ClearLastError();
        Observer.Observe('delete', Format(TryDelete(List)));
        Observer.Observe('error', GetLastErrorText());
        Observer.Observe('log', Log.Get());
        Observer.Observe('row_exists', Format(Row.Get(1)));
        List.Close();
    end;

    [TryFunction]
    local procedure TryDelete(var List: TestPage "LT PXD List")
    begin
        List.DeleteIt.Invoke();
    end;

    [Test]
    procedure OnDeleteRecord_BothTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(true, true, Observer);
        Observer.Expect('delete', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('log', '');
        Observer.Expect('row_exists', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure OnDeleteRecord_ExtFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(true, false, Observer);
        Observer.Expect('delete', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('log', '');
        Observer.Expect('row_exists', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure OnDeleteRecord_BaseFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(false, true, Observer);
        Observer.Expect('delete', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('log', '');
        Observer.Expect('row_exists', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure OnDeleteRecord_BothFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(false, false, Observer);
        Observer.Expect('delete', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('log', '');
        Observer.Expect('row_exists', 'No');
        Observer.Verify();
    end;
}
