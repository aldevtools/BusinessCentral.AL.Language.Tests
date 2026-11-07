// Objects of writer Y20's probes (al-runner issue 6490), tests in Y20ImplicitFactBoxes.al: a Worksheet, a Document, a ListPlus, a
// StandardDialog, a ConfirmationDialog and a NavigatePage page that declare no area(FactBoxes), each with a page extension that adds a hidden part by addfirst(FactBoxes) (the part is loaded from the
// extension's OnAfterGetCurrRecord, the reporter's shape) and a part with a SubPageLink by addlast(FactBoxes).

page 92121 "LT Y20 FB Box"
{
    PageType = CardPart;
    SourceTable = "ALT Shape 20";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(BoxK; Rec.Code) { ApplicationArea = All; }
            field(LoadedCtl; Loaded) { ApplicationArea = All; Caption = 'Loaded'; }
        }
    }

    var
        Loaded: Code[10];

    procedure LoadData(R: Record "ALT Shape 20")
    begin
        Loaded := R.Code;
    end;
}

page 92122 "LT Y20 FB Sheet"
{
    PageType = Worksheet;
    SourceTable = "ALT Shape 20";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(K; Rec.Code) { ApplicationArea = All; }
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
                SubPageLink = Code = field(Code);
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
    SourceTable = "ALT Shape 20";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(K; Rec.Code) { ApplicationArea = All; }
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
                SubPageLink = Code = field(Code);
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
    SourceTable = "ALT Shape 20";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(K; Rec.Code) { ApplicationArea = All; }
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
                SubPageLink = Code = field(Code);
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
    SourceTable = "ALT Shape 20";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(K; Rec.Code) { ApplicationArea = All; }
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
                SubPageLink = Code = field(Code);
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
    SourceTable = "ALT Shape 20";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(K; Rec.Code) { ApplicationArea = All; }
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
                SubPageLink = Code = field(Code);
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
    SourceTable = "ALT Shape 20";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(K; Rec.Code) { ApplicationArea = All; }
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
                SubPageLink = Code = field(Code);
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Box.Page.LoadData(Rec);
    end;
}
