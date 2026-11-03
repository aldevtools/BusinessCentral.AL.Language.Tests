// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68900, codeunit 68901 (log), page 68902, page
//                extensions 68903, 68904, 68905, codeunit 68906 (tests)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins how page extensions use the base page's members and in which order several of them run:
//  - Protected variables (Integer, Record) and a protected procedure of the base page are named from an
//    extension's triggers and actions. The extension and the base share ONE instance: the extension's
//    OnOpenPage reads what the base set (counter 10, record id 77) and writes counter 20; an extension action
//    calls the protected procedure and changes the counter and the record, and the base's action and
//    OnClosePage read those changes (record id 88).
//  - A variable of the base that is not protected is a compile error in the extension (AL0161); a test cannot show that.
//  - Order: for OnOpenPage and OnClosePage the base runs first, then the extensions in OBJECT ID order (ids
//    68903 "Probe PX Ext", 68904 "Probe PX Zeta", 68905 "Probe PX Alpha": Alpha has the first name and runs last).
//    OnAfterGetCurrRecord of an extension runs again after each action.
// BC versions: 27.5

table 68900 "Probe PX Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 68901 "Probe PX Log"
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

page 68902 "Probe PX Page"
{
    PageType = Card;
    SourceTable = "Probe PX Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Txt; Rec.Txt) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BaseAct)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    PxLog.Add('base action counter=' + Format(Counter));
                    Counter += 1;
                end;
            }
        }
    }

    protected var
        Counter: Integer;
        Other: Record "Probe PX Table";

    var
        Hidden: Integer;
        PxLog: Codeunit "Probe PX Log";

    trigger OnOpenPage()
    begin
        Counter := 10;
        Other.Id := 77;
        Hidden := 5;
        PxLog.Add('base OnOpenPage');
    end;

    trigger OnClosePage()
    begin
        PxLog.Add('base OnClosePage counter=' + Format(Counter) + ' other=' + Format(Other.Id));
    end;

    protected procedure Bump(): Integer
    begin
        Counter += 100;
        exit(Counter);
    end;
}

pageextension 68903 "Probe PX Ext" extends "Probe PX Page"
{
    actions
    {
        addlast(Processing)
        {
            action(ExtAct)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    PxLog.Add('ext action counter=' + Format(Counter) + ' bump=' + Format(Bump()));
                    Counter += 5;
                    Other.Id := 88;
                end;
            }
        }
    }

    var
        PxLog: Codeunit "Probe PX Log";

    trigger OnOpenPage()
    begin
        PxLog.Add('ext OnOpenPage counter=' + Format(Counter) + ' other=' + Format(Other.Id));
        Counter := 20;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        PxLog.Add('ext AfterGetCurrRecord counter=' + Format(Counter));
    end;
}

pageextension 68904 "Probe PX Zeta" extends "Probe PX Page"
{
    var
        PxLog: Codeunit "Probe PX Log";

    trigger OnOpenPage()
    begin
        PxLog.Add('Zeta OnOpenPage counter=' + Format(Counter));
        Counter += 1;
    end;

    trigger OnClosePage()
    begin
        PxLog.Add('Zeta OnClosePage counter=' + Format(Counter));
    end;
}

pageextension 68905 "Probe PX Alpha" extends "Probe PX Page"
{
    var
        PxLog: Codeunit "Probe PX Log";

    trigger OnOpenPage()
    begin
        PxLog.Add('Alpha OnOpenPage counter=' + Format(Counter));
        Counter += 2;
    end;

    trigger OnClosePage()
    begin
        PxLog.Add('Alpha OnClosePage counter=' + Format(Counter));
    end;
}

codeunit 68906 "Probe Page Ext Base Members"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Extensions_ShareTheBasePagesInstance_AndRunInObjectIdOrder()
    var
        PxRec: Record "Probe PX Table";
        PxLog: Codeunit "Probe PX Log";
        PxPage: TestPage "Probe PX Page";
    begin
        PxRec.DeleteAll();
        PxRec.Id := 1;
        PxRec.Insert();
        Commit();
        PxLog.Take();

        PxPage.OpenView();
        PxPage.ExtAct.Invoke();
        PxPage.BaseAct.Invoke();
        PxPage.Close();

        Assert.AreEqual(
            'base OnOpenPage;ext OnOpenPage counter=10 other=77;Zeta OnOpenPage counter=20;Alpha OnOpenPage counter=21;' +
            'ext AfterGetCurrRecord counter=23;ext action counter=23 bump=123;ext AfterGetCurrRecord counter=128;' +
            'base action counter=128;ext AfterGetCurrRecord counter=129;base OnClosePage counter=129 other=88;' +
            'Zeta OnClosePage counter=129;Alpha OnClosePage counter=129;',
            PxLog.Take(), 'log');
    end;
}
