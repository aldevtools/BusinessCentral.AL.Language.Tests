// Objects for UePromotedTests.al (AL Runner issues 6150 and 6158): page extensions that add actionrefs to the promoted groups Category_New,
// Category_Report, Category_Process and to area(Promoted) of base pages that do not declare them. Fixtures: log 90336, pages 90337 to 90340,
// page extensions 90341 to 90344. Table "LT UE Row" is in UeTriggerObjects.al.

codeunit 90336 "LT UE Promo Log"
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

page 90337 "LT UE Promo Process"
{
    PageType = Card;
    SourceTable = "LT UE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
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
                var
                    Log: Codeunit "LT UE Promo Log";
                begin
                    Log.Add('BaseAct');
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(BaseAct_Promoted; BaseAct) { }
            }
        }
    }
}

pageextension 90341 "LT UE Promo Process Ext" extends "LT UE Promo Process"
{
    actions
    {
        addlast(Processing)
        {
            action(ExtNew)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT UE Promo Log";
                begin
                    Log.Add('ExtNew');
                end;
            }
            action(ExtReport)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT UE Promo Log";
                begin
                    Log.Add('ExtReport');
                end;
            }
            action(ExtProcess)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT UE Promo Log";
                begin
                    Log.Add('ExtProcess');
                end;
            }
        }
        addlast(Category_New)
        {
            actionref(ExtNew_Promoted; ExtNew) { }
        }
        addlast(Category_Report)
        {
            actionref(ExtReport_Promoted; ExtReport) { }
        }
        addlast(Category_Process)
        {
            actionref(ExtProcess_Promoted; ExtProcess) { }
        }
    }
}

page 90338 "LT UE Promo No Area"
{
    PageType = Card;
    SourceTable = "LT UE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
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
                var
                    Log: Codeunit "LT UE Promo Log";
                begin
                    Log.Add('BaseAct');
                end;
            }
        }
    }
}

pageextension 90342 "LT UE Promo No Area Ext" extends "LT UE Promo No Area"
{
    actions
    {
        addlast(Processing)
        {
            action(ExtLast)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT UE Promo Log";
                begin
                    Log.Add('ExtLast');
                end;
            }
            action(ExtFirst)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT UE Promo Log";
                begin
                    Log.Add('ExtFirst');
                end;
            }
        }
        addlast(Promoted)
        {
            actionref(ExtLast_Promoted; ExtLast) { }
        }
        addfirst(Promoted)
        {
            actionref(ExtFirst_Promoted; ExtFirst) { }
        }
    }
}

page 90339 "LT UE Promo No Actions"
{
    PageType = Card;
    SourceTable = "LT UE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
        }
    }
}

pageextension 90343 "LT UE Promo No Actions Ext" extends "LT UE Promo No Actions"
{
    actions
    {
        addlast(Navigation)
        {
            action(NavAct)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT UE Promo Log";
                begin
                    Log.Add('NavAct');
                end;
            }
            action(NavAct2)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT UE Promo Log";
                begin
                    Log.Add('NavAct2');
                end;
            }
        }
        addfirst(Promoted)
        {
            actionref(NavAct_Promoted; NavAct) { }
        }
        addlast(Promoted)
        {
            actionref(NavAct2_Promoted; NavAct2) { }
        }
    }
}

page 90340 "LT UE Promo No Actions Cat"
{
    PageType = Card;
    SourceTable = "LT UE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
        }
    }
}

pageextension 90344 "LT UE Promo No Actions Cat Ext" extends "LT UE Promo No Actions Cat"
{
    actions
    {
        addlast(Navigation)
        {
            action(CatAct)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT UE Promo Log";
                begin
                    Log.Add('CatAct');
                end;
            }
        }
        addlast(Category_New)
        {
            actionref(CatAct_Promoted; CatAct) { }
        }
    }
}
