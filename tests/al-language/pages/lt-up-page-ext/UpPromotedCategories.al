// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 90498 of UpPageExt.al; own codeunits 90507 (log) and 90509 (tests), page 90503 "LT UP Promoted Seven After"
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

pageextension 90504 "LT UP Promoted Seven After Ext" extends "LT UP Promoted Seven After"
{
    actions
    {
        addlast(Processing)
        {
            action(Extra)
            {
                Caption = 'Extra';
                trigger OnAction()
                var
                    Log: Codeunit "LT UP Promoted Log";
                begin
                    Log.Add('Extra');
                end;
            }
        }
        addafter(Category_Category7)
        {
            group(ExtraGroup)
            {
                Caption = 'Extra group';
                actionref(Extra_Promoted; Extra) { }
            }
        }
    }
}

page 90505 "LT UP Promoted Seven Last"
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

pageextension 90505 "LT UP Promoted Seven Last Ext" extends "LT UP Promoted Seven Last"
{
    actions
    {
        addlast(Processing)
        {
            action(Extra)
            {
                Caption = 'Extra';
                trigger OnAction()
                var
                    Log: Codeunit "LT UP Promoted Log";
                begin
                    Log.Add('Extra');
                end;
            }
        }
        addlast(Category_Category7)
        {
            actionref(Extra_Promoted; Extra) { }
        }
    }
}

page 90506 "LT UP Promoted Twelve After"
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

pageextension 90506 "LT UP Promoted Twelve After Ext" extends "LT UP Promoted Twelve After"
{
    actions
    {
        addlast(Processing)
        {
            action(Extra)
            {
                Caption = 'Extra';
                trigger OnAction()
                var
                    Log: Codeunit "LT UP Promoted Log";
                begin
                    Log.Add('Extra');
                end;
            }
        }
        addafter(Category_Category12)
        {
            group(ExtraGroup)
            {
                Caption = 'Extra group';
                actionref(Extra_Promoted; Extra) { }
            }
        }
    }
}

page 90507 "LT UP Promoted New Last"
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

pageextension 90507 "LT UP Promoted New Last Ext" extends "LT UP Promoted New Last"
{
    actions
    {
        addlast(Processing)
        {
            action(Extra)
            {
                Caption = 'Extra';
                trigger OnAction()
                var
                    Log: Codeunit "LT UP Promoted Log";
                begin
                    Log.Add('Extra');
                end;
            }
        }
        addlast(Category_New)
        {
            actionref(Extra_Promoted; Extra) { }
        }
    }
}

page 90508 "LT UP Promoted New After"
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

pageextension 90508 "LT UP Promoted New After Ext" extends "LT UP Promoted New After"
{
    actions
    {
        addlast(Processing)
        {
            action(Extra)
            {
                Caption = 'Extra';
                trigger OnAction()
                var
                    Log: Codeunit "LT UP Promoted Log";
                begin
                    Log.Add('Extra');
                end;
            }
        }
        addafter(Category_New)
        {
            group(ExtraGroup)
            {
                Caption = 'Extra group';
                actionref(Extra_Promoted; Extra) { }
            }
        }
    }
}

page 90509 "LT UP Promoted Declared After"
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

pageextension 90509 "LT UP Promoted Declared After Ext" extends "LT UP Promoted Declared After"
{
    actions
    {
        addlast(Processing)
        {
            action(Extra)
            {
                Caption = 'Extra';
                trigger OnAction()
                var
                    Log: Codeunit "LT UP Promoted Log";
                begin
                    Log.Add('Extra');
                end;
            }
        }
        addafter(Category_Category4)
        {
            group(ExtraGroup)
            {
                Caption = 'Extra group';
                actionref(Extra_Promoted; Extra) { }
            }
        }
    }
}

codeunit 90509 "LT UP Promoted Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedRow()
    var
        Row: Record "LT UP Page Row";
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.Insert();
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer"; var Log: Codeunit "LT UP Promoted Log"; Name: Text; Ok: Boolean)
    begin
        if Ok then
            Observer.Observe(Name, 'ok|' + Log.Take())
        else
            Observer.Observe(Name, 'error|' + GetLastErrorText());
    end;

    [TryFunction]
    local procedure TrySevenAfterAction(var Pg: TestPage "LT UP Promoted Seven After")
    begin
        Pg.Extra.Invoke();
    end;

    [TryFunction]
    local procedure TrySevenAfterRef(var Pg: TestPage "LT UP Promoted Seven After")
    begin
        Pg.Extra_Promoted.Invoke();
    end;

    [Test]
    procedure UP_PageExt_SevenAfter_addafter_CategoryCategory7()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT UP Promoted Log";
        Pg: TestPage "LT UP Promoted Seven After";
    begin
        SeedRow();
        Log.Take();
        Pg.OpenView();
        Observer.Observe('open log', Log.Take());
        Report(Observer, Log, 'Post', TryPostSevenAfter(Pg));
        Report(Observer, Log, 'Extra action', TrySevenAfterAction(Pg));
        Report(Observer, Log, 'Extra actionref', TrySevenAfterRef(Pg));
        Pg.Close();
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryPostSevenAfter(var Pg: TestPage "LT UP Promoted Seven After")
    begin
        Pg.Post.Invoke();
    end;

    [TryFunction]
    local procedure TrySevenLastAction(var Pg: TestPage "LT UP Promoted Seven Last")
    begin
        Pg.Extra.Invoke();
    end;

    [TryFunction]
    local procedure TrySevenLastRef(var Pg: TestPage "LT UP Promoted Seven Last")
    begin
        Pg.Extra_Promoted.Invoke();
    end;

    [Test]
    procedure UP_PageExt_SevenLast_addlast_CategoryCategory7()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT UP Promoted Log";
        Pg: TestPage "LT UP Promoted Seven Last";
    begin
        SeedRow();
        Log.Take();
        Pg.OpenView();
        Observer.Observe('open log', Log.Take());
        Report(Observer, Log, 'Post', TryPostSevenLast(Pg));
        Report(Observer, Log, 'Extra action', TrySevenLastAction(Pg));
        Report(Observer, Log, 'Extra actionref', TrySevenLastRef(Pg));
        Pg.Close();
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryPostSevenLast(var Pg: TestPage "LT UP Promoted Seven Last")
    begin
        Pg.Post.Invoke();
    end;

    [TryFunction]
    local procedure TryTwelveAfterAction(var Pg: TestPage "LT UP Promoted Twelve After")
    begin
        Pg.Extra.Invoke();
    end;

    [TryFunction]
    local procedure TryTwelveAfterRef(var Pg: TestPage "LT UP Promoted Twelve After")
    begin
        Pg.Extra_Promoted.Invoke();
    end;

    [Test]
    procedure UP_PageExt_TwelveAfter_addafter_CategoryCategory12()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT UP Promoted Log";
        Pg: TestPage "LT UP Promoted Twelve After";
    begin
        SeedRow();
        Log.Take();
        Pg.OpenView();
        Observer.Observe('open log', Log.Take());
        Report(Observer, Log, 'Post', TryPostTwelveAfter(Pg));
        Report(Observer, Log, 'Extra action', TryTwelveAfterAction(Pg));
        Report(Observer, Log, 'Extra actionref', TryTwelveAfterRef(Pg));
        Pg.Close();
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryPostTwelveAfter(var Pg: TestPage "LT UP Promoted Twelve After")
    begin
        Pg.Post.Invoke();
    end;

    [TryFunction]
    local procedure TryNewLastAction(var Pg: TestPage "LT UP Promoted New Last")
    begin
        Pg.Extra.Invoke();
    end;

    [TryFunction]
    local procedure TryNewLastRef(var Pg: TestPage "LT UP Promoted New Last")
    begin
        Pg.Extra_Promoted.Invoke();
    end;

    [Test]
    procedure UP_PageExt_NewLast_addlast_CategoryNew()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT UP Promoted Log";
        Pg: TestPage "LT UP Promoted New Last";
    begin
        SeedRow();
        Log.Take();
        Pg.OpenView();
        Observer.Observe('open log', Log.Take());
        Report(Observer, Log, 'Post', TryPostNewLast(Pg));
        Report(Observer, Log, 'Extra action', TryNewLastAction(Pg));
        Report(Observer, Log, 'Extra actionref', TryNewLastRef(Pg));
        Pg.Close();
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryPostNewLast(var Pg: TestPage "LT UP Promoted New Last")
    begin
        Pg.Post.Invoke();
    end;

    [TryFunction]
    local procedure TryNewAfterAction(var Pg: TestPage "LT UP Promoted New After")
    begin
        Pg.Extra.Invoke();
    end;

    [TryFunction]
    local procedure TryNewAfterRef(var Pg: TestPage "LT UP Promoted New After")
    begin
        Pg.Extra_Promoted.Invoke();
    end;

    [Test]
    procedure UP_PageExt_NewAfter_addafter_CategoryNew()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT UP Promoted Log";
        Pg: TestPage "LT UP Promoted New After";
    begin
        SeedRow();
        Log.Take();
        Pg.OpenView();
        Observer.Observe('open log', Log.Take());
        Report(Observer, Log, 'Post', TryPostNewAfter(Pg));
        Report(Observer, Log, 'Extra action', TryNewAfterAction(Pg));
        Report(Observer, Log, 'Extra actionref', TryNewAfterRef(Pg));
        Pg.Close();
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryPostNewAfter(var Pg: TestPage "LT UP Promoted New After")
    begin
        Pg.Post.Invoke();
    end;

    [TryFunction]
    local procedure TryDeclaredAfterAction(var Pg: TestPage "LT UP Promoted Declared After")
    begin
        Pg.Extra.Invoke();
    end;

    [TryFunction]
    local procedure TryDeclaredAfterRef(var Pg: TestPage "LT UP Promoted Declared After")
    begin
        Pg.Extra_Promoted.Invoke();
    end;

    [Test]
    procedure UP_PageExt_DeclaredAfter_addafter_CategoryCategory4()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT UP Promoted Log";
        Pg: TestPage "LT UP Promoted Declared After";
    begin
        SeedRow();
        Log.Take();
        Pg.OpenView();
        Observer.Observe('open log', Log.Take());
        Report(Observer, Log, 'Post', TryPostDeclaredAfter(Pg));
        Report(Observer, Log, 'Extra action', TryDeclaredAfterAction(Pg));
        Report(Observer, Log, 'Extra actionref', TryDeclaredAfterRef(Pg));
        Pg.Close();
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryPostDeclaredAfter(var Pg: TestPage "LT UP Promoted Declared After")
    begin
        Pg.Post.Invoke();
    end;

}
