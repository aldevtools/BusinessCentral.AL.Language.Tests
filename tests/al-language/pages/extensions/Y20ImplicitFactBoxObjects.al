// Objects of writer Y20's probes (al-runner issue 6490), tests in Y20ImplicitFactBoxes.al: a Worksheet, a Document, a ListPlus, a
// StandardDialog, a ConfirmationDialog and a NavigatePage page that declare no area(FactBoxes), each with a page extension that adds a hidden part by addfirst(FactBoxes) (the part is loaded from the
// extension's OnAfterGetCurrRecord, the reporter's shape) and a part with a SubPageLink by addlast(FactBoxes).

table 92120 "LT Y20 FB Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; K; Code[10]) { }
        field(2; Name; Text[30]) { }
    }
    keys { key(PK; K) { Clustered = true; } }
}

page 92121 "LT Y20 FB Box"
{
    PageType = CardPart;
    SourceTable = "LT Y20 FB Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(BoxK; Rec.K) { ApplicationArea = All; }
            field(LoadedCtl; Loaded) { ApplicationArea = All; Caption = 'Loaded'; }
        }
    }

    var
        Loaded: Code[10];

    procedure LoadData(R: Record "LT Y20 FB Row")
    begin
        Loaded := R.K;
    end;
}

page 92122 "LT Y20 FB Sheet"
{
    PageType = Worksheet;
    SourceTable = "LT Y20 FB Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(K; Rec.K) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 92122 "LT Y20 FB Sheet Ext" extends "LT Y20 FB Sheet"
{
    layout
    {
        addfirst(factboxes)
        {
            part(Box; "LT Y20 FB Box") { ApplicationArea = All; Visible = false; }
        }
        addlast(FactBoxes)
        {
            part(LinkedBox; "LT Y20 FB Box")
            {
                ApplicationArea = All;
                SubPageLink = K = field(K);
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Box.Page.LoadData(Rec);
    end;
}

page 92123 "LT Y20 FB Doc"
{
    PageType = Document;
    SourceTable = "LT Y20 FB Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(K; Rec.K) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 92123 "LT Y20 FB Doc Ext" extends "LT Y20 FB Doc"
{
    layout
    {
        addfirst(factboxes)
        {
            part(Box; "LT Y20 FB Box") { ApplicationArea = All; Visible = false; }
        }
        addlast(FactBoxes)
        {
            part(LinkedBox; "LT Y20 FB Box")
            {
                ApplicationArea = All;
                SubPageLink = K = field(K);
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Box.Page.LoadData(Rec);
    end;
}

page 92124 "LT Y20 FB ListPlus"
{
    PageType = ListPlus;
    SourceTable = "LT Y20 FB Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(K; Rec.K) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 92124 "LT Y20 FB ListPlus Ext" extends "LT Y20 FB ListPlus"
{
    layout
    {
        addfirst(factboxes)
        {
            part(Box; "LT Y20 FB Box") { ApplicationArea = All; Visible = false; }
        }
        addlast(FactBoxes)
        {
            part(LinkedBox; "LT Y20 FB Box")
            {
                ApplicationArea = All;
                SubPageLink = K = field(K);
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Box.Page.LoadData(Rec);
    end;
}

page 92127 "LT Y20 FB Dialog"
{
    PageType = StandardDialog;
    SourceTable = "LT Y20 FB Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(K; Rec.K) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 92127 "LT Y20 FB Dialog Ext" extends "LT Y20 FB Dialog"
{
    layout
    {
        addfirst(factboxes)
        {
            part(Box; "LT Y20 FB Box") { ApplicationArea = All; Visible = false; }
        }
        addlast(FactBoxes)
        {
            part(LinkedBox; "LT Y20 FB Box")
            {
                ApplicationArea = All;
                SubPageLink = K = field(K);
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Box.Page.LoadData(Rec);
    end;
}

page 92128 "LT Y20 FB Confirm"
{
    PageType = ConfirmationDialog;
    SourceTable = "LT Y20 FB Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(K; Rec.K) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 92128 "LT Y20 FB Confirm Ext" extends "LT Y20 FB Confirm"
{
    layout
    {
        addfirst(factboxes)
        {
            part(Box; "LT Y20 FB Box") { ApplicationArea = All; Visible = false; }
        }
        addlast(FactBoxes)
        {
            part(LinkedBox; "LT Y20 FB Box")
            {
                ApplicationArea = All;
                SubPageLink = K = field(K);
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Box.Page.LoadData(Rec);
    end;
}

page 92129 "LT Y20 FB Navigate"
{
    PageType = NavigatePage;
    SourceTable = "LT Y20 FB Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(K; Rec.K) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 92129 "LT Y20 FB Navigate Ext" extends "LT Y20 FB Navigate"
{
    layout
    {
        addfirst(factboxes)
        {
            part(Box; "LT Y20 FB Box") { ApplicationArea = All; Visible = false; }
        }
        addlast(FactBoxes)
        {
            part(LinkedBox; "LT Y20 FB Box")
            {
                ApplicationArea = All;
                SubPageLink = K = field(K);
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Box.Page.LoadData(Rec);
    end;
}
