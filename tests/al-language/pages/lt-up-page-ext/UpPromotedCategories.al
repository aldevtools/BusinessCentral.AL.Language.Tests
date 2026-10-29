// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 90498 of UpPageExt.al; own codeunits 90507 (log) and 90509 (tests), page 90503, page extension 90504
// Probe (writer UP, al-runner issue 6217): addafter() / addlast() of a promoted category group the page does not declare (Category_Category7,
//   Category_Category12, Category_New) on a page that declares only Category_Process and Category_Category4; the extension's actionrefs invoked from a TestPage.
//   Already pinned: addafter(Category_New / Report / Process) on a page without actions (pages/W1ActionAreasPromoted.al:82), addlast/addfirst(Category_Category4)
//   (pages/lt-page-ext-promoted/PageExtPromotedCategoryRisky.al). An unknown anchor is AL0271 (must-not-compile case 2290).
// BC versions: 27-29

codeunit 90507 "LT UP Promoted Log"
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
        R: Text;
    begin
        R := Entries;
        Entries := '';
        exit(R);
    end;
}

page 90503 "LT UP Promoted List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT UP Page Row";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Post)
            {
                Caption = 'Post';
                trigger OnAction()
                var
                    Log: Codeunit "LT UP Promoted Log";
                begin
                    Log.Add('Post');
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(Post_Promoted; Post) { }
            }
            group(Category_Category4)
            {
                Caption = 'Page';
            }
        }
    }
}

pageextension 90504 "LT UP Promoted List Ext" extends "LT UP Promoted List"
{
    actions
    {
        addlast(Processing)
        {
            action(AfterSeven)
            {
                Caption = 'After Seven';
                trigger OnAction()
                var
                    Log: Codeunit "LT UP Promoted Log";
                begin
                    Log.Add('AfterSeven');
                end;
            }
            action(LastSeven)
            {
                Caption = 'Last Seven';
                trigger OnAction()
                var
                    Log: Codeunit "LT UP Promoted Log";
                begin
                    Log.Add('LastSeven');
                end;
            }
            action(AfterTwelve)
            {
                Caption = 'After Twelve';
                trigger OnAction()
                var
                    Log: Codeunit "LT UP Promoted Log";
                begin
                    Log.Add('AfterTwelve');
                end;
            }
            action(LastNew)
            {
                Caption = 'Last New';
                trigger OnAction()
                var
                    Log: Codeunit "LT UP Promoted Log";
                begin
                    Log.Add('LastNew');
                end;
            }
            action(AfterNew)
            {
                Caption = 'After New';
                trigger OnAction()
                var
                    Log: Codeunit "LT UP Promoted Log";
                begin
                    Log.Add('AfterNew');
                end;
            }
        }
        addafter(Category_Category7)
        {
            group(UpAfterSeven)
            {
                Caption = 'After Seven';
                actionref(AfterSeven_Promoted; AfterSeven) { }
            }
        }
        addlast(Category_Category7)
        {
            actionref(LastSeven_Promoted; LastSeven) { }
        }
        addafter(Category_Category12)
        {
            group(UpAfterTwelve)
            {
                Caption = 'After Twelve';
                actionref(AfterTwelve_Promoted; AfterTwelve) { }
            }
        }
        addlast(Category_New)
        {
            actionref(LastNew_Promoted; LastNew) { }
        }
        addafter(Category_New)
        {
            group(UpAfterNew)
            {
                Caption = 'After New';
                actionref(AfterNew_Promoted; AfterNew) { }
            }
        }
    }
}

codeunit 90509 "LT UP Promoted Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure UP_PageExt_ActionrefsInUndeclaredCategories()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT UP Promoted Log";
        Row: Record "LT UP Page Row";
        Pg: TestPage "LT UP Promoted List";
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.Insert();
        Log.Take();
        Pg.OpenView();
        Observer.Observe('open log', Log.Take());
        Pg.Post_Promoted.Invoke();
        Pg.AfterSeven_Promoted.Invoke();
        Pg.LastSeven_Promoted.Invoke();
        Pg.AfterTwelve_Promoted.Invoke();
        Pg.LastNew_Promoted.Invoke();
        Pg.AfterNew_Promoted.Invoke();
        Observer.Observe('refs invoked', Log.Take());
        Pg.AfterSeven.Invoke();
        Pg.LastNew.Invoke();
        Observer.Observe('actions invoked', Log.Take());
        Pg.Close();
        Observer.Expect('open log', '');
        Observer.Expect('refs invoked', 'Post;AfterSeven;LastSeven;AfterTwelve;LastNew;AfterNew;');
        Observer.Expect('actions invoked', 'AfterSeven;LastNew;');
        Observer.Verify();
    end;
}
