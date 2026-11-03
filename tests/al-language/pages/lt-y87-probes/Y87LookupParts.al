// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-lookup-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables and pages of LT Y15 Lookup (91710 - 91712, 91713); own objects 94630 - 94645 (writer Y87)
// Probe (writer Y87, from the runtime lane rt-6806): TestField.Lookup on a host with MORE parts than pages/lt-y15/Y15LookupThreeFieldLink.al
//   (two parts) pins. The host is a List over resources with a header field ResourceNo (OnLookup runs the resource list, OnValidate modifies
//   the setting and calls CurrPage.Update(false)), row triggers and function controls, one ListPart linked on No., Group Code and Region Code
//   (L) and other unlinked ListParts (A to E) or FactBox CardParts (K, M). The layout letters name the order of the parts in the Content area
//   (FactBox cards last): ABCDL five parts with the linked part last, ABCDEL six, ALBC and ABLC four parts with the linked part NOT last,
//   ABLKM three ListParts and two CardParts, LKM one ListPart and two CardParts. Every part logs its triggers with its own prefix
//   (h host, p linked, a to e the other ListParts, k and m the cards) and kind (r OnAfterGetRecord, c OnAfterGetCurrRecord, f function
//   control) and the resource number, for example hrR1. Per host: every control read after the lookup (in layout order and in reverse order),
//   a move of a part (Next) as the first access after the lookup, a Next of the host and then a Previous.
// BC versions: 27, 28, 29

codeunit 94630 "LT Y87 Log"
{
    SingleInstance = true;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    var
        Entries: Text;
}

page 94631 "LT Y87 Part L"
{
    PageType = ListPart;
    SourceTable = "LT Y15 Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Group Code"; Rec."Group Code") { ApplicationArea = All; }
                field(PartCurrent; Current) { ApplicationArea = All; Caption = 'PartCurrent'; }
                field(PartFn; GetNo()) { ApplicationArea = All; Caption = 'PartFn'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('pr' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('pc' + Rec."No.");
        Current := Rec."No." + '/' + StoredResourceNo();
    end;

    local procedure GetNo(): Code[20]
    begin
        Log.Add('pf' + Rec."No.");
        exit(Rec."No." + '/' + StoredResourceNo());
    end;

    local procedure StoredResourceNo(): Code[20]
    var
        Setting: Record "LT Y15 Lookup Setting";
    begin
        if Setting.Get() then
            exit(Setting."Resource No.");
    end;

    var
        Current: Code[20];
        Log: Codeunit "LT Y87 Log";
}

page 94632 "LT Y87 Part A"
{
    PageType = ListPart;
    SourceTable = "LT Y15 Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Group Code"; Rec."Group Code") { ApplicationArea = All; }
                field(OtherACurrent; Current) { ApplicationArea = All; Caption = 'OtherACurrent'; }
                field(OtherAFn; GetNo()) { ApplicationArea = All; Caption = 'OtherAFn'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('ar' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('ac' + Rec."No.");
        Current := Rec."No." + '/' + StoredResourceNo();
    end;

    local procedure GetNo(): Code[20]
    begin
        Log.Add('af' + Rec."No.");
        exit(Rec."No." + '/' + StoredResourceNo());
    end;

    local procedure StoredResourceNo(): Code[20]
    var
        Setting: Record "LT Y15 Lookup Setting";
    begin
        if Setting.Get() then
            exit(Setting."Resource No.");
    end;

    var
        Current: Code[20];
        Log: Codeunit "LT Y87 Log";
}

page 94633 "LT Y87 Part B"
{
    PageType = ListPart;
    SourceTable = "LT Y15 Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Group Code"; Rec."Group Code") { ApplicationArea = All; }
                field(OtherBCurrent; Current) { ApplicationArea = All; Caption = 'OtherBCurrent'; }
                field(OtherBFn; GetNo()) { ApplicationArea = All; Caption = 'OtherBFn'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('br' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('bc' + Rec."No.");
        Current := Rec."No." + '/' + StoredResourceNo();
    end;

    local procedure GetNo(): Code[20]
    begin
        Log.Add('bf' + Rec."No.");
        exit(Rec."No." + '/' + StoredResourceNo());
    end;

    local procedure StoredResourceNo(): Code[20]
    var
        Setting: Record "LT Y15 Lookup Setting";
    begin
        if Setting.Get() then
            exit(Setting."Resource No.");
    end;

    var
        Current: Code[20];
        Log: Codeunit "LT Y87 Log";
}

page 94634 "LT Y87 Part C"
{
    PageType = ListPart;
    SourceTable = "LT Y15 Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Group Code"; Rec."Group Code") { ApplicationArea = All; }
                field(OtherCCurrent; Current) { ApplicationArea = All; Caption = 'OtherCCurrent'; }
                field(OtherCFn; GetNo()) { ApplicationArea = All; Caption = 'OtherCFn'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('cr' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('cc' + Rec."No.");
        Current := Rec."No." + '/' + StoredResourceNo();
    end;

    local procedure GetNo(): Code[20]
    begin
        Log.Add('cf' + Rec."No.");
        exit(Rec."No." + '/' + StoredResourceNo());
    end;

    local procedure StoredResourceNo(): Code[20]
    var
        Setting: Record "LT Y15 Lookup Setting";
    begin
        if Setting.Get() then
            exit(Setting."Resource No.");
    end;

    var
        Current: Code[20];
        Log: Codeunit "LT Y87 Log";
}

page 94635 "LT Y87 Part D"
{
    PageType = ListPart;
    SourceTable = "LT Y15 Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Group Code"; Rec."Group Code") { ApplicationArea = All; }
                field(OtherDCurrent; Current) { ApplicationArea = All; Caption = 'OtherDCurrent'; }
                field(OtherDFn; GetNo()) { ApplicationArea = All; Caption = 'OtherDFn'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('dr' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('dc' + Rec."No.");
        Current := Rec."No." + '/' + StoredResourceNo();
    end;

    local procedure GetNo(): Code[20]
    begin
        Log.Add('df' + Rec."No.");
        exit(Rec."No." + '/' + StoredResourceNo());
    end;

    local procedure StoredResourceNo(): Code[20]
    var
        Setting: Record "LT Y15 Lookup Setting";
    begin
        if Setting.Get() then
            exit(Setting."Resource No.");
    end;

    var
        Current: Code[20];
        Log: Codeunit "LT Y87 Log";
}

page 94636 "LT Y87 Part E"
{
    PageType = ListPart;
    SourceTable = "LT Y15 Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Group Code"; Rec."Group Code") { ApplicationArea = All; }
                field(OtherECurrent; Current) { ApplicationArea = All; Caption = 'OtherECurrent'; }
                field(OtherEFn; GetNo()) { ApplicationArea = All; Caption = 'OtherEFn'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('er' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('ec' + Rec."No.");
        Current := Rec."No." + '/' + StoredResourceNo();
    end;

    local procedure GetNo(): Code[20]
    begin
        Log.Add('ef' + Rec."No.");
        exit(Rec."No." + '/' + StoredResourceNo());
    end;

    local procedure StoredResourceNo(): Code[20]
    var
        Setting: Record "LT Y15 Lookup Setting";
    begin
        if Setting.Get() then
            exit(Setting."Resource No.");
    end;

    var
        Current: Code[20];
        Log: Codeunit "LT Y87 Log";
}

page 94637 "LT Y87 Part K"
{
    PageType = CardPart;
    SourceTable = "LT Y15 Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(CardCurrent; Current) { ApplicationArea = All; Caption = 'CardCurrent'; }
            field(CardFn; GetNo()) { ApplicationArea = All; Caption = 'CardFn'; }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('kr' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('kc' + Rec."No.");
        Current := Rec."No." + '/' + StoredResourceNo();
    end;

    local procedure GetNo(): Code[20]
    begin
        Log.Add('kf' + Rec."No.");
        exit(Rec."No." + '/' + StoredResourceNo());
    end;

    local procedure StoredResourceNo(): Code[20]
    var
        Setting: Record "LT Y15 Lookup Setting";
    begin
        if Setting.Get() then
            exit(Setting."Resource No.");
    end;

    var
        Current: Code[20];
        Log: Codeunit "LT Y87 Log";
}

page 94638 "LT Y87 Part M"
{
    PageType = CardPart;
    SourceTable = "LT Y15 Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Card2Current; Current) { ApplicationArea = All; Caption = 'Card2Current'; }
            field(Card2Fn; GetNo()) { ApplicationArea = All; Caption = 'Card2Fn'; }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('mr' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('mc' + Rec."No.");
        Current := Rec."No." + '/' + StoredResourceNo();
    end;

    local procedure GetNo(): Code[20]
    begin
        Log.Add('mf' + Rec."No.");
        exit(Rec."No." + '/' + StoredResourceNo());
    end;

    local procedure StoredResourceNo(): Code[20]
    var
        Setting: Record "LT Y15 Lookup Setting";
    begin
        if Setting.Get() then
            exit(Setting."Resource No.");
    end;

    var
        Current: Code[20];
        Log: Codeunit "LT Y87 Log";
}

page 94639 "LT Y87 Host ABCDL"
{
    PageType = List;
    SourceTable = "LT Y15 Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(ResourceNo; Setting."Resource No.")
                {
                    ApplicationArea = All;
                    Caption = 'Resource No.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Resource: Record "LT Y15 Lookup Resource";
                    begin
                        Log.Add('lookup');
                        if Page.RunModal(Page::"LT Y15 Lookup Resource List", Resource) <> Action::LookupOK then
                            exit(false);
                        Text := Resource."No.";
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        Log.Add('validate ' + Setting."Resource No.");
                        Setting.Modify();
                        CurrPage.Update(false);
                    end;
                }
                field(HeaderCurrent; CurrentNo) { ApplicationArea = All; Caption = 'Header Current'; }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(CurrentNo; CurrentNo) { ApplicationArea = All; Caption = 'Current No.'; }
                field(HostFn; GetHostNo()) { ApplicationArea = All; Caption = 'Host Fn'; }
            }
            part(OtherA; "LT Y87 Part A")
            {
                ApplicationArea = All;
            }
            part(OtherB; "LT Y87 Part B")
            {
                ApplicationArea = All;
            }
            part(OtherC; "LT Y87 Part C")
            {
                ApplicationArea = All;
            }
            part(OtherD; "LT Y87 Part D")
            {
                ApplicationArea = All;
            }
            part(Resources; "LT Y87 Part L")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code"),
                              "Region Code" = field("Region Code");
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Setting.Get() then
            Setting.Insert();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('hr' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('hc' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('hf' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT Y87 Log";
}

page 94640 "LT Y87 Host ABCDEL"
{
    PageType = List;
    SourceTable = "LT Y15 Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(ResourceNo; Setting."Resource No.")
                {
                    ApplicationArea = All;
                    Caption = 'Resource No.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Resource: Record "LT Y15 Lookup Resource";
                    begin
                        Log.Add('lookup');
                        if Page.RunModal(Page::"LT Y15 Lookup Resource List", Resource) <> Action::LookupOK then
                            exit(false);
                        Text := Resource."No.";
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        Log.Add('validate ' + Setting."Resource No.");
                        Setting.Modify();
                        CurrPage.Update(false);
                    end;
                }
                field(HeaderCurrent; CurrentNo) { ApplicationArea = All; Caption = 'Header Current'; }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(CurrentNo; CurrentNo) { ApplicationArea = All; Caption = 'Current No.'; }
                field(HostFn; GetHostNo()) { ApplicationArea = All; Caption = 'Host Fn'; }
            }
            part(OtherA; "LT Y87 Part A")
            {
                ApplicationArea = All;
            }
            part(OtherB; "LT Y87 Part B")
            {
                ApplicationArea = All;
            }
            part(OtherC; "LT Y87 Part C")
            {
                ApplicationArea = All;
            }
            part(OtherD; "LT Y87 Part D")
            {
                ApplicationArea = All;
            }
            part(OtherE; "LT Y87 Part E")
            {
                ApplicationArea = All;
            }
            part(Resources; "LT Y87 Part L")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code"),
                              "Region Code" = field("Region Code");
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Setting.Get() then
            Setting.Insert();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('hr' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('hc' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('hf' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT Y87 Log";
}

page 94641 "LT Y87 Host ALBC"
{
    PageType = List;
    SourceTable = "LT Y15 Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(ResourceNo; Setting."Resource No.")
                {
                    ApplicationArea = All;
                    Caption = 'Resource No.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Resource: Record "LT Y15 Lookup Resource";
                    begin
                        Log.Add('lookup');
                        if Page.RunModal(Page::"LT Y15 Lookup Resource List", Resource) <> Action::LookupOK then
                            exit(false);
                        Text := Resource."No.";
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        Log.Add('validate ' + Setting."Resource No.");
                        Setting.Modify();
                        CurrPage.Update(false);
                    end;
                }
                field(HeaderCurrent; CurrentNo) { ApplicationArea = All; Caption = 'Header Current'; }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(CurrentNo; CurrentNo) { ApplicationArea = All; Caption = 'Current No.'; }
                field(HostFn; GetHostNo()) { ApplicationArea = All; Caption = 'Host Fn'; }
            }
            part(OtherA; "LT Y87 Part A")
            {
                ApplicationArea = All;
            }
            part(Resources; "LT Y87 Part L")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code"),
                              "Region Code" = field("Region Code");
            }
            part(OtherB; "LT Y87 Part B")
            {
                ApplicationArea = All;
            }
            part(OtherC; "LT Y87 Part C")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Setting.Get() then
            Setting.Insert();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('hr' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('hc' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('hf' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT Y87 Log";
}

page 94642 "LT Y87 Host ABLC"
{
    PageType = List;
    SourceTable = "LT Y15 Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(ResourceNo; Setting."Resource No.")
                {
                    ApplicationArea = All;
                    Caption = 'Resource No.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Resource: Record "LT Y15 Lookup Resource";
                    begin
                        Log.Add('lookup');
                        if Page.RunModal(Page::"LT Y15 Lookup Resource List", Resource) <> Action::LookupOK then
                            exit(false);
                        Text := Resource."No.";
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        Log.Add('validate ' + Setting."Resource No.");
                        Setting.Modify();
                        CurrPage.Update(false);
                    end;
                }
                field(HeaderCurrent; CurrentNo) { ApplicationArea = All; Caption = 'Header Current'; }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(CurrentNo; CurrentNo) { ApplicationArea = All; Caption = 'Current No.'; }
                field(HostFn; GetHostNo()) { ApplicationArea = All; Caption = 'Host Fn'; }
            }
            part(OtherA; "LT Y87 Part A")
            {
                ApplicationArea = All;
            }
            part(OtherB; "LT Y87 Part B")
            {
                ApplicationArea = All;
            }
            part(Resources; "LT Y87 Part L")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code"),
                              "Region Code" = field("Region Code");
            }
            part(OtherC; "LT Y87 Part C")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Setting.Get() then
            Setting.Insert();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('hr' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('hc' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('hf' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT Y87 Log";
}

page 94643 "LT Y87 Host ABLKM"
{
    PageType = List;
    SourceTable = "LT Y15 Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(ResourceNo; Setting."Resource No.")
                {
                    ApplicationArea = All;
                    Caption = 'Resource No.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Resource: Record "LT Y15 Lookup Resource";
                    begin
                        Log.Add('lookup');
                        if Page.RunModal(Page::"LT Y15 Lookup Resource List", Resource) <> Action::LookupOK then
                            exit(false);
                        Text := Resource."No.";
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        Log.Add('validate ' + Setting."Resource No.");
                        Setting.Modify();
                        CurrPage.Update(false);
                    end;
                }
                field(HeaderCurrent; CurrentNo) { ApplicationArea = All; Caption = 'Header Current'; }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(CurrentNo; CurrentNo) { ApplicationArea = All; Caption = 'Current No.'; }
                field(HostFn; GetHostNo()) { ApplicationArea = All; Caption = 'Host Fn'; }
            }
            part(OtherA; "LT Y87 Part A")
            {
                ApplicationArea = All;
            }
            part(OtherB; "LT Y87 Part B")
            {
                ApplicationArea = All;
            }
            part(Resources; "LT Y87 Part L")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code"),
                              "Region Code" = field("Region Code");
            }
        }
        area(FactBoxes)
        {
            part(Details; "LT Y87 Part K")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
            part(Details2; "LT Y87 Part M")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Setting.Get() then
            Setting.Insert();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('hr' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('hc' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('hf' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT Y87 Log";
}

page 94644 "LT Y87 Host LKM"
{
    PageType = List;
    SourceTable = "LT Y15 Lookup Resource";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(ResourceNo; Setting."Resource No.")
                {
                    ApplicationArea = All;
                    Caption = 'Resource No.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Resource: Record "LT Y15 Lookup Resource";
                    begin
                        Log.Add('lookup');
                        if Page.RunModal(Page::"LT Y15 Lookup Resource List", Resource) <> Action::LookupOK then
                            exit(false);
                        Text := Resource."No.";
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        Log.Add('validate ' + Setting."Resource No.");
                        Setting.Modify();
                        CurrPage.Update(false);
                    end;
                }
                field(HeaderCurrent; CurrentNo) { ApplicationArea = All; Caption = 'Header Current'; }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(CurrentNo; CurrentNo) { ApplicationArea = All; Caption = 'Current No.'; }
                field(HostFn; GetHostNo()) { ApplicationArea = All; Caption = 'Host Fn'; }
            }
            part(Resources; "LT Y87 Part L")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code"),
                              "Region Code" = field("Region Code");
            }
        }
        area(FactBoxes)
        {
            part(Details; "LT Y87 Part K")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
            part(Details2; "LT Y87 Part M")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Setting.Get() then
            Setting.Insert();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('hr' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('hc' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('hf' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT Y87 Log";
}

codeunit 94645 "LT Y87 Lookup Part Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y87 Log";


    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABCDL_ReadEach()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABCDL";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABCDL(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('resource no log', Log.Take());
        Observer.Observe('current no', Schedule.CurrentNo.Value());
        Observer.Observe('host fn', Schedule.HostFn.Value());
        Observer.Observe('host log', Log.Take());
        Observer.Observe('OtherA read', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value());
        Observer.Observe('OtherA read log', Log.Take());
        Observer.Observe('OtherB read', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value());
        Observer.Observe('OtherB read log', Log.Take());
        Observer.Observe('OtherC read', Schedule.OtherC."No.".Value() + '|' + Schedule.OtherC.OtherCCurrent.Value() + '|' + Schedule.OtherC.OtherCFn.Value());
        Observer.Observe('OtherC read log', Log.Take());
        Observer.Observe('OtherD read', Schedule.OtherD."No.".Value() + '|' + Schedule.OtherD.OtherDCurrent.Value() + '|' + Schedule.OtherD.OtherDFn.Value());
        Observer.Observe('OtherD read log', Log.Take());
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('after', SnapABCDL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;drR2;dfR2;drR3;dfR3;drR1;drR1;dfR1;dcR1;dfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;dcR1;dfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('resource no', 'R2');
        Observer.Expect('resource no log', '');
        Observer.Expect('current no', 'R1/');
        Observer.Expect('host fn', 'R1/R2');
        Observer.Expect('host log', '');
        Observer.Expect('OtherA read', 'R1|R1/|R1/');
        Observer.Expect('OtherA read log', '');
        Observer.Expect('OtherB read', 'R1|R1/|R1/');
        Observer.Expect('OtherB read log', '');
        Observer.Expect('OtherC read', 'R1|R1/|R1/');
        Observer.Expect('OtherC read log', '');
        Observer.Expect('OtherD read', 'R1|R1/|R1/');
        Observer.Expect('OtherD read log', '');
        Observer.Expect('Resources read', 'R1|R1/|R1/');
        Observer.Expect('Resources read log', '');
        Observer.Expect('after', 'R2|R1/|R1|R1/|R1/R2|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABCDL_ReadReverse()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABCDL";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABCDL(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('OtherD read', Schedule.OtherD."No.".Value() + '|' + Schedule.OtherD.OtherDCurrent.Value() + '|' + Schedule.OtherD.OtherDFn.Value());
        Observer.Observe('OtherD read log', Log.Take());
        Observer.Observe('OtherC read', Schedule.OtherC."No.".Value() + '|' + Schedule.OtherC.OtherCCurrent.Value() + '|' + Schedule.OtherC.OtherCFn.Value());
        Observer.Observe('OtherC read log', Log.Take());
        Observer.Observe('OtherB read', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value());
        Observer.Observe('OtherB read log', Log.Take());
        Observer.Observe('OtherA read', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value());
        Observer.Observe('OtherA read log', Log.Take());
        Observer.Observe('after', SnapABCDL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;drR2;dfR2;drR3;dfR3;drR1;drR1;dfR1;dcR1;dfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;dcR1;dfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('Resources read', 'R1|R1/|R1/');
        Observer.Expect('Resources read log', '');
        Observer.Expect('OtherD read', 'R1|R1/|R1/');
        Observer.Expect('OtherD read log', '');
        Observer.Expect('OtherC read', 'R1|R1/|R1/');
        Observer.Expect('OtherC read log', '');
        Observer.Expect('OtherB read', 'R1|R1/|R1/');
        Observer.Expect('OtherB read log', '');
        Observer.Expect('OtherA read', 'R1|R1/|R1/');
        Observer.Expect('OtherA read log', '');
        Observer.Expect('after', 'R2|R1/|R1|R1/|R1/R2|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABCDL_NextOtherA()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABCDL";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABCDL(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('OtherA next', Format(Schedule.OtherA.Next(), 0, 9) + '|' + Schedule.OtherA."No.".Value());
        Observer.Observe('OtherA next log', Log.Take());
        Observer.Observe('OtherB next', Format(Schedule.OtherB.Next(), 0, 9) + '|' + Schedule.OtherB."No.".Value());
        Observer.Observe('OtherB next log', Log.Take());
        Observer.Observe('OtherC next', Format(Schedule.OtherC.Next(), 0, 9) + '|' + Schedule.OtherC."No.".Value());
        Observer.Observe('OtherC next log', Log.Take());
        Observer.Observe('OtherD next', Format(Schedule.OtherD.Next(), 0, 9) + '|' + Schedule.OtherD."No.".Value());
        Observer.Observe('OtherD next log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('after', SnapABCDL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;drR2;dfR2;drR3;dfR3;drR1;drR1;dfR1;dcR1;dfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;dcR1;dfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('OtherA next', 'true|R2');
        Observer.Expect('OtherA next log', 'arR2;arR2;afR2;acR2;afR2;hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR2;afR2;arR3;afR3;arR2;arR1;afR1;arR2;arR2;afR2;acR2;afR2;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;drR2;dfR2;drR3;dfR3;drR1;drR1;dfR1;dcR1;dfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;dcR1;dfR1');
        Observer.Expect('OtherB next', 'true|R2');
        Observer.Expect('OtherB next log', 'brR2;brR2;bfR2;bcR2;bfR2;hrR2;hrR2;hfR2;hcR2;hfR2;arR2;arR2;afR2;acR2;afR2;crR2;crR2;cfR2;ccR2;cfR2;drR2;drR2;dfR2;dcR2;dfR2;prR2');
        Observer.Expect('OtherC next', 'true|R2');
        Observer.Expect('OtherC next log', 'crR2;cfR2;ccR2;cfR2');
        Observer.Expect('OtherD next', 'true|R2');
        Observer.Expect('OtherD next log', 'drR2;dfR2;dcR2;dfR2');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', '');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', 'prR1;hrR1');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABCDL_NextResources()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABCDL";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABCDL(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('OtherA next', Format(Schedule.OtherA.Next(), 0, 9) + '|' + Schedule.OtherA."No.".Value());
        Observer.Observe('OtherA next log', Log.Take());
        Observer.Observe('OtherB next', Format(Schedule.OtherB.Next(), 0, 9) + '|' + Schedule.OtherB."No.".Value());
        Observer.Observe('OtherB next log', Log.Take());
        Observer.Observe('OtherC next', Format(Schedule.OtherC.Next(), 0, 9) + '|' + Schedule.OtherC."No.".Value());
        Observer.Observe('OtherC next log', Log.Take());
        Observer.Observe('OtherD next', Format(Schedule.OtherD.Next(), 0, 9) + '|' + Schedule.OtherD."No.".Value());
        Observer.Observe('OtherD next log', Log.Take());
        Observer.Observe('after', SnapABCDL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;drR2;dfR2;drR3;dfR3;drR1;drR1;dfR1;dcR1;dfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;dcR1;dfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;drR2;dfR2;drR3;dfR3;drR1;drR1;dfR1;dcR1;dfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;dcR1;dfR1');
        Observer.Expect('OtherA next', 'true|R2');
        Observer.Expect('OtherA next log', 'arR2;arR2;afR2;acR2;afR2;hrR2;hrR2;hfR2;hcR2;hfR2;brR2;brR2;bfR2;bcR2;bfR2;crR2;crR2;cfR2;ccR2;cfR2;drR2;drR2;dfR2;dcR2;dfR2;prR2');
        Observer.Expect('OtherB next', 'true|R2');
        Observer.Expect('OtherB next log', 'brR2;bfR2;bcR2;bfR2');
        Observer.Expect('OtherC next', 'true|R2');
        Observer.Expect('OtherC next log', 'crR2;cfR2;ccR2;cfR2');
        Observer.Expect('OtherD next', 'true|R2');
        Observer.Expect('OtherD next log', 'drR2;dfR2;dcR2;dfR2');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', 'prR1;hrR1');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABCDL_HostNext()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABCDL";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABCDL(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('host next', Format(Schedule.Next(), 0, 9) + '|' + Schedule."No.".Value());
        Observer.Observe('host next log', Log.Take());
        Observer.Observe('after next', SnapABCDL(Schedule));
        Observer.Observe('after next log', Log.Take());
        Observer.Observe('host previous', Format(Schedule.Previous(), 0, 9) + '|' + Schedule."No.".Value());
        Observer.Observe('host previous log', Log.Take());
        Observer.Observe('after', SnapABCDL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;drR2;dfR2;drR3;dfR3;drR1;drR1;dfR1;dcR1;dfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;dcR1;dfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('host next', 'true|R2');
        Observer.Expect('host next log', 'hrR2;hrR2;hfR2;hcR2;hfR2;hrR2;hfR2;hrR3;hfR3;hrR2;hrR1;hfR1;hrR2;hrR2;hfR2;hcR2;hfR2;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;drR2;dfR2;drR3;dfR3;drR1;drR1;dfR1;dcR1;dfR1;prR2;pfR2;prR2;pfR2;pcR2;pfR2;hrR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR2;hrR2;hfR2;hcR2;hfR2;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR2;arR2;afR2;acR2;afR2;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR2;brR2;bfR2;bcR2;bfR2;crR1;cfR1;ccR1;cfR1;crR2;crR2;cfR2;ccR2;cfR2;drR2;drR2;dfR2;dcR2;dfR2');
        Observer.Expect('after next', 'R2|R2/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2');
        Observer.Expect('after next log', '');
        Observer.Expect('host previous', 'true|R1');
        Observer.Expect('host previous log', 'hrR1;hrR1;hfR1;hcR1;hfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;arR1;arR1;afR1;acR1;afR1;brR1;brR1;bfR1;bcR1;bfR1;crR1;crR1;cfR1;ccR1;cfR1;drR1;drR1;dfR1;dcR1;dfR1');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABCDEL_ReadEach()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABCDEL";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABCDEL(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('resource no log', Log.Take());
        Observer.Observe('current no', Schedule.CurrentNo.Value());
        Observer.Observe('host fn', Schedule.HostFn.Value());
        Observer.Observe('host log', Log.Take());
        Observer.Observe('OtherA read', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value());
        Observer.Observe('OtherA read log', Log.Take());
        Observer.Observe('OtherB read', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value());
        Observer.Observe('OtherB read log', Log.Take());
        Observer.Observe('OtherC read', Schedule.OtherC."No.".Value() + '|' + Schedule.OtherC.OtherCCurrent.Value() + '|' + Schedule.OtherC.OtherCFn.Value());
        Observer.Observe('OtherC read log', Log.Take());
        Observer.Observe('OtherD read', Schedule.OtherD."No.".Value() + '|' + Schedule.OtherD.OtherDCurrent.Value() + '|' + Schedule.OtherD.OtherDFn.Value());
        Observer.Observe('OtherD read log', Log.Take());
        Observer.Observe('OtherE read', Schedule.OtherE."No.".Value() + '|' + Schedule.OtherE.OtherECurrent.Value() + '|' + Schedule.OtherE.OtherEFn.Value());
        Observer.Observe('OtherE read log', Log.Take());
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('after', SnapABCDEL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;drR2;dfR2;drR3;dfR3;drR1;drR1;dfR1;dcR1;dfR1;erR1;efR1;erR2;efR2;erR3;efR3;erR1;erR1;efR1;ecR1;efR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;dcR1;dfR1;drR1;dfR1;dcR1;dfR1;erR1;efR1;ecR1;efR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('resource no', 'R2');
        Observer.Expect('resource no log', '');
        Observer.Expect('current no', 'R1/');
        Observer.Expect('host fn', 'R1/R2');
        Observer.Expect('host log', '');
        Observer.Expect('OtherA read', 'R1|R1/|R1/');
        Observer.Expect('OtherA read log', '');
        Observer.Expect('OtherB read', 'R1|R1/|R1/');
        Observer.Expect('OtherB read log', '');
        Observer.Expect('OtherC read', 'R1|R1/|R1/');
        Observer.Expect('OtherC read log', '');
        Observer.Expect('OtherD read', 'R1|R1/|R1/');
        Observer.Expect('OtherD read log', '');
        Observer.Expect('OtherE read', 'R1|R1/|R1/');
        Observer.Expect('OtherE read log', '');
        Observer.Expect('Resources read', 'R1|R1/|R1/');
        Observer.Expect('Resources read log', '');
        Observer.Expect('after', 'R2|R1/|R1|R1/|R1/R2|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABCDEL_ReadReverse()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABCDEL";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABCDEL(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('OtherE read', Schedule.OtherE."No.".Value() + '|' + Schedule.OtherE.OtherECurrent.Value() + '|' + Schedule.OtherE.OtherEFn.Value());
        Observer.Observe('OtherE read log', Log.Take());
        Observer.Observe('OtherD read', Schedule.OtherD."No.".Value() + '|' + Schedule.OtherD.OtherDCurrent.Value() + '|' + Schedule.OtherD.OtherDFn.Value());
        Observer.Observe('OtherD read log', Log.Take());
        Observer.Observe('OtherC read', Schedule.OtherC."No.".Value() + '|' + Schedule.OtherC.OtherCCurrent.Value() + '|' + Schedule.OtherC.OtherCFn.Value());
        Observer.Observe('OtherC read log', Log.Take());
        Observer.Observe('OtherB read', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value());
        Observer.Observe('OtherB read log', Log.Take());
        Observer.Observe('OtherA read', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value());
        Observer.Observe('OtherA read log', Log.Take());
        Observer.Observe('after', SnapABCDEL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;drR2;dfR2;drR3;dfR3;drR1;drR1;dfR1;dcR1;dfR1;erR1;efR1;erR2;efR2;erR3;efR3;erR1;erR1;efR1;ecR1;efR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;dcR1;dfR1;drR1;dfR1;dcR1;dfR1;erR1;efR1;ecR1;efR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('Resources read', 'R1|R1/|R1/');
        Observer.Expect('Resources read log', '');
        Observer.Expect('OtherE read', 'R1|R1/|R1/');
        Observer.Expect('OtherE read log', '');
        Observer.Expect('OtherD read', 'R1|R1/|R1/');
        Observer.Expect('OtherD read log', '');
        Observer.Expect('OtherC read', 'R1|R1/|R1/');
        Observer.Expect('OtherC read log', '');
        Observer.Expect('OtherB read', 'R1|R1/|R1/');
        Observer.Expect('OtherB read log', '');
        Observer.Expect('OtherA read', 'R1|R1/|R1/');
        Observer.Expect('OtherA read log', '');
        Observer.Expect('after', 'R2|R1/|R1|R1/|R1/R2|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABCDEL_NextOtherA()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABCDEL";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABCDEL(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('OtherA next', Format(Schedule.OtherA.Next(), 0, 9) + '|' + Schedule.OtherA."No.".Value());
        Observer.Observe('OtherA next log', Log.Take());
        Observer.Observe('OtherB next', Format(Schedule.OtherB.Next(), 0, 9) + '|' + Schedule.OtherB."No.".Value());
        Observer.Observe('OtherB next log', Log.Take());
        Observer.Observe('OtherC next', Format(Schedule.OtherC.Next(), 0, 9) + '|' + Schedule.OtherC."No.".Value());
        Observer.Observe('OtherC next log', Log.Take());
        Observer.Observe('OtherD next', Format(Schedule.OtherD.Next(), 0, 9) + '|' + Schedule.OtherD."No.".Value());
        Observer.Observe('OtherD next log', Log.Take());
        Observer.Observe('OtherE next', Format(Schedule.OtherE.Next(), 0, 9) + '|' + Schedule.OtherE."No.".Value());
        Observer.Observe('OtherE next log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('after', SnapABCDEL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;drR2;dfR2;drR3;dfR3;drR1;drR1;dfR1;dcR1;dfR1;erR1;efR1;erR2;efR2;erR3;efR3;erR1;erR1;efR1;ecR1;efR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;dcR1;dfR1;drR1;dfR1;dcR1;dfR1;erR1;efR1;ecR1;efR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('OtherA next', 'true|R2');
        Observer.Expect('OtherA next log', 'arR2;arR2;afR2;acR2;afR2;hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR2;afR2;arR3;afR3;arR2;arR1;afR1;arR2;arR2;afR2;acR2;afR2;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;drR2;dfR2;drR3;dfR3;drR1;drR1;dfR1;dcR1;dfR1;erR1;efR1;erR2;efR2;erR3;efR3;erR1;erR1;efR1;ecR1;efR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;dcR1;dfR1;drR1;dfR1;dcR1;dfR1;erR1;efR1;ecR1;efR1');
        Observer.Expect('OtherB next', 'true|R2');
        Observer.Expect('OtherB next log', 'brR2;brR2;bfR2;bcR2;bfR2;hrR2;hrR2;hfR2;hcR2;hfR2;arR2;arR2;afR2;acR2;afR2;crR2;crR2;cfR2;ccR2;cfR2;drR2;drR2;dfR2;dcR2;dfR2;erR2;erR2;efR2;ecR2;efR2;prR2');
        Observer.Expect('OtherC next', 'true|R2');
        Observer.Expect('OtherC next log', 'crR2;cfR2;ccR2;cfR2');
        Observer.Expect('OtherD next', 'true|R2');
        Observer.Expect('OtherD next log', 'drR2;dfR2;dcR2;dfR2');
        Observer.Expect('OtherE next', 'true|R2');
        Observer.Expect('OtherE next log', 'erR2;efR2;ecR2;efR2');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', '');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', 'prR1;hrR1');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABCDEL_NextResources()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABCDEL";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABCDEL(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('OtherA next', Format(Schedule.OtherA.Next(), 0, 9) + '|' + Schedule.OtherA."No.".Value());
        Observer.Observe('OtherA next log', Log.Take());
        Observer.Observe('OtherB next', Format(Schedule.OtherB.Next(), 0, 9) + '|' + Schedule.OtherB."No.".Value());
        Observer.Observe('OtherB next log', Log.Take());
        Observer.Observe('OtherC next', Format(Schedule.OtherC.Next(), 0, 9) + '|' + Schedule.OtherC."No.".Value());
        Observer.Observe('OtherC next log', Log.Take());
        Observer.Observe('OtherD next', Format(Schedule.OtherD.Next(), 0, 9) + '|' + Schedule.OtherD."No.".Value());
        Observer.Observe('OtherD next log', Log.Take());
        Observer.Observe('OtherE next', Format(Schedule.OtherE.Next(), 0, 9) + '|' + Schedule.OtherE."No.".Value());
        Observer.Observe('OtherE next log', Log.Take());
        Observer.Observe('after', SnapABCDEL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;drR2;dfR2;drR3;dfR3;drR1;drR1;dfR1;dcR1;dfR1;erR1;efR1;erR2;efR2;erR3;efR3;erR1;erR1;efR1;ecR1;efR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;dcR1;dfR1;drR1;dfR1;dcR1;dfR1;erR1;efR1;ecR1;efR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;drR2;dfR2;drR3;dfR3;drR1;drR1;dfR1;dcR1;dfR1;erR1;efR1;erR2;efR2;erR3;efR3;erR1;erR1;efR1;ecR1;efR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;dcR1;dfR1;drR1;dfR1;dcR1;dfR1;erR1;efR1;ecR1;efR1');
        Observer.Expect('OtherA next', 'true|R2');
        Observer.Expect('OtherA next log', 'arR2;arR2;afR2;acR2;afR2;hrR2;hrR2;hfR2;hcR2;hfR2;brR2;brR2;bfR2;bcR2;bfR2;crR2;crR2;cfR2;ccR2;cfR2;drR2;drR2;dfR2;dcR2;dfR2;erR2;erR2;efR2;ecR2;efR2;prR2');
        Observer.Expect('OtherB next', 'true|R2');
        Observer.Expect('OtherB next log', 'brR2;bfR2;bcR2;bfR2');
        Observer.Expect('OtherC next', 'true|R2');
        Observer.Expect('OtherC next log', 'crR2;cfR2;ccR2;cfR2');
        Observer.Expect('OtherD next', 'true|R2');
        Observer.Expect('OtherD next log', 'drR2;dfR2;dcR2;dfR2');
        Observer.Expect('OtherE next', 'true|R2');
        Observer.Expect('OtherE next log', 'erR2;efR2;ecR2;efR2');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', 'prR1;hrR1');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABCDEL_HostNext()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABCDEL";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABCDEL(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('host next', Format(Schedule.Next(), 0, 9) + '|' + Schedule."No.".Value());
        ObserveChunks('host next log', Log.Take());
        Observer.Observe('after next', SnapABCDEL(Schedule));
        Observer.Observe('after next log', Log.Take());
        Observer.Observe('host previous', Format(Schedule.Previous(), 0, 9) + '|' + Schedule."No.".Value());
        Observer.Observe('host previous log', Log.Take());
        Observer.Observe('after', SnapABCDEL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;drR2;dfR2;drR3;dfR3;drR1;drR1;dfR1;dcR1;dfR1;erR1;efR1;erR2;efR2;erR3;efR3;erR1;erR1;efR1;ecR1;efR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;dcR1;dfR1;drR1;dfR1;dcR1;dfR1;erR1;efR1;ecR1;efR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('host next', 'true|R2');
        Observer.Expect('host next log 1', 'hrR2;hrR2;hfR2;hcR2;hfR2;hrR2;hfR2;hrR3;hfR3;hrR2;hrR1;hfR1;hrR2;hrR2;hfR2;hcR2;hfR2;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;drR1;dfR1;drR2;dfR2;drR3;dfR3;drR1;drR1;dfR1;dcR1;dfR1;erR1;efR1;erR2;efR2;erR3;efR3;erR1;erR1;efR1;ecR1;efR1;prR2;pfR2;prR2;pfR2;pcR2;pfR2;hrR1;hrR1;');
        Observer.Expect('host next log 2', 'hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR2;hrR2;hfR2;hcR2;hfR2;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR2;arR2;afR2;acR2;afR2;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;brR2;brR2;bfR2;bcR2;bfR2;crR1;cfR1;ccR1;cfR1;crR1;cfR1;ccR1;cfR1;crR2;crR2;cfR2;ccR2;cfR2;drR1;dfR1;dcR1;dfR1;drR2;');
        Observer.Expect('host next log 3', 'drR2;dfR2;dcR2;dfR2;erR2;erR2;efR2;ecR2;efR2');
        Observer.Expect('after next', 'R2|R2/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2');
        Observer.Expect('after next log', '');
        Observer.Expect('host previous', 'true|R1');
        Observer.Expect('host previous log', 'hrR1;hrR1;hfR1;hcR1;hfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;arR1;arR1;afR1;acR1;afR1;brR1;brR1;bfR1;bcR1;bfR1;crR1;crR1;cfR1;ccR1;cfR1;drR1;drR1;dfR1;dcR1;dfR1;erR1;erR1;efR1;ecR1;efR1');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ALBC_ReadEach()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ALBC";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapALBC(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('resource no log', Log.Take());
        Observer.Observe('current no', Schedule.CurrentNo.Value());
        Observer.Observe('host fn', Schedule.HostFn.Value());
        Observer.Observe('host log', Log.Take());
        Observer.Observe('OtherA read', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value());
        Observer.Observe('OtherA read log', Log.Take());
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('OtherB read', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value());
        Observer.Observe('OtherB read log', Log.Take());
        Observer.Observe('OtherC read', Schedule.OtherC."No.".Value() + '|' + Schedule.OtherC.OtherCCurrent.Value() + '|' + Schedule.OtherC.OtherCFn.Value());
        Observer.Observe('OtherC read log', Log.Take());
        Observer.Observe('after', SnapALBC(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;prR1;pfR1;pcR1;pfR1;prR1;pfR1;pcR1;pfR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('resource no', 'R2');
        Observer.Expect('resource no log', '');
        Observer.Expect('current no', 'R1/');
        Observer.Expect('host fn', 'R1/R2');
        Observer.Expect('host log', '');
        Observer.Expect('OtherA read', 'R1|R1/|R1/');
        Observer.Expect('OtherA read log', '');
        Observer.Expect('Resources read', 'R1|R1/|R1/');
        Observer.Expect('Resources read log', '');
        Observer.Expect('OtherB read', 'R1|R1/|R1/');
        Observer.Expect('OtherB read log', '');
        Observer.Expect('OtherC read', 'R1|R1/|R1/');
        Observer.Expect('OtherC read log', '');
        Observer.Expect('after', 'R2|R1/|R1|R1/|R1/R2|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ALBC_ReadReverse()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ALBC";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapALBC(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('OtherC read', Schedule.OtherC."No.".Value() + '|' + Schedule.OtherC.OtherCCurrent.Value() + '|' + Schedule.OtherC.OtherCFn.Value());
        Observer.Observe('OtherC read log', Log.Take());
        Observer.Observe('OtherB read', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value());
        Observer.Observe('OtherB read log', Log.Take());
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('OtherA read', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value());
        Observer.Observe('OtherA read log', Log.Take());
        Observer.Observe('after', SnapALBC(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;prR1;pfR1;pcR1;pfR1;prR1;pfR1;pcR1;pfR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('OtherC read', 'R1|R1/|R1/');
        Observer.Expect('OtherC read log', '');
        Observer.Expect('OtherB read', 'R1|R1/|R1/');
        Observer.Expect('OtherB read log', '');
        Observer.Expect('Resources read', 'R1|R1/|R1/');
        Observer.Expect('Resources read log', '');
        Observer.Expect('OtherA read', 'R1|R1/|R1/');
        Observer.Expect('OtherA read log', '');
        Observer.Expect('after', 'R2|R1/|R1|R1/|R1/R2|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ALBC_NextOtherA()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ALBC";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapALBC(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('OtherA next', Format(Schedule.OtherA.Next(), 0, 9) + '|' + Schedule.OtherA."No.".Value());
        Observer.Observe('OtherA next log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('OtherB next', Format(Schedule.OtherB.Next(), 0, 9) + '|' + Schedule.OtherB."No.".Value());
        Observer.Observe('OtherB next log', Log.Take());
        Observer.Observe('OtherC next', Format(Schedule.OtherC.Next(), 0, 9) + '|' + Schedule.OtherC."No.".Value());
        Observer.Observe('OtherC next log', Log.Take());
        Observer.Observe('after', SnapALBC(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;prR1;pfR1;pcR1;pfR1;prR1;pfR1;pcR1;pfR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('OtherA next', 'true|R2');
        Observer.Expect('OtherA next log', 'arR2;arR2;afR2;acR2;afR2;hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR2;afR2;arR3;afR3;arR2;arR1;afR1;arR2;arR2;afR2;acR2;afR2;prR1;pfR1;prR1;pfR1;pcR1;pfR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;prR1;pfR1;pcR1;pfR1;prR1;pfR1;pcR1;pfR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', '');
        Observer.Expect('OtherB next', 'true|R2');
        Observer.Expect('OtherB next log', 'brR2;brR2;bfR2;bcR2;bfR2;hrR2;hrR2;hfR2;hcR2;hfR2;arR2;arR2;afR2;acR2;afR2;prR2;crR2;crR2;cfR2;ccR2;cfR2');
        Observer.Expect('OtherC next', 'true|R2');
        Observer.Expect('OtherC next log', 'crR2;cfR2;ccR2;cfR2');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', 'prR1;hrR1');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ALBC_NextResources()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ALBC";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapALBC(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('OtherA next', Format(Schedule.OtherA.Next(), 0, 9) + '|' + Schedule.OtherA."No.".Value());
        Observer.Observe('OtherA next log', Log.Take());
        Observer.Observe('OtherB next', Format(Schedule.OtherB.Next(), 0, 9) + '|' + Schedule.OtherB."No.".Value());
        Observer.Observe('OtherB next log', Log.Take());
        Observer.Observe('OtherC next', Format(Schedule.OtherC.Next(), 0, 9) + '|' + Schedule.OtherC."No.".Value());
        Observer.Observe('OtherC next log', Log.Take());
        Observer.Observe('after', SnapALBC(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;prR1;pfR1;pcR1;pfR1;prR1;pfR1;pcR1;pfR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;prR1;pfR1;pcR1;pfR1;prR1;pfR1;pcR1;pfR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('OtherA next', 'true|R2');
        Observer.Expect('OtherA next log', 'arR2;arR2;afR2;acR2;afR2;hrR2;hrR2;hfR2;hcR2;hfR2;prR2;brR2;brR2;bfR2;bcR2;bfR2;crR2;crR2;cfR2;ccR2;cfR2');
        Observer.Expect('OtherB next', 'true|R2');
        Observer.Expect('OtherB next log', 'brR2;bfR2;bcR2;bfR2');
        Observer.Expect('OtherC next', 'true|R2');
        Observer.Expect('OtherC next log', 'crR2;cfR2;ccR2;cfR2');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', 'prR1;hrR1');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ALBC_NextOtherC()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ALBC";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapALBC(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('OtherC next', Format(Schedule.OtherC.Next(), 0, 9) + '|' + Schedule.OtherC."No.".Value());
        Observer.Observe('OtherC next log', Log.Take());
        Observer.Observe('OtherA next', Format(Schedule.OtherA.Next(), 0, 9) + '|' + Schedule.OtherA."No.".Value());
        Observer.Observe('OtherA next log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('OtherB next', Format(Schedule.OtherB.Next(), 0, 9) + '|' + Schedule.OtherB."No.".Value());
        Observer.Observe('OtherB next log', Log.Take());
        Observer.Observe('after', SnapALBC(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;prR1;pfR1;pcR1;pfR1;prR1;pfR1;pcR1;pfR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('OtherC next', 'true|R2');
        Observer.Expect('OtherC next log', 'crR2;crR2;cfR2;ccR2;cfR2;hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR2;cfR2;crR3;cfR3;crR2;crR1;cfR1;crR2;crR2;cfR2;ccR2;cfR2;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;prR1;pfR1;pcR1;pfR1');
        Observer.Expect('OtherA next', 'true|R2');
        Observer.Expect('OtherA next log', 'arR2;arR2;afR2;acR2;afR2;hrR2;hrR2;hfR2;hcR2;hfR2;prR2;brR2;brR2;bfR2;bcR2;bfR2;crR2;cfR2;ccR2;cfR2');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', '');
        Observer.Expect('OtherB next', 'true|R2');
        Observer.Expect('OtherB next log', 'brR2;bfR2;bcR2;bfR2');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', 'prR1;hrR1');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ALBC_HostNext()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ALBC";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapALBC(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('host next', Format(Schedule.Next(), 0, 9) + '|' + Schedule."No.".Value());
        Observer.Observe('host next log', Log.Take());
        Observer.Observe('after next', SnapALBC(Schedule));
        Observer.Observe('after next log', Log.Take());
        Observer.Observe('host previous', Format(Schedule.Previous(), 0, 9) + '|' + Schedule."No.".Value());
        Observer.Observe('host previous log', Log.Take());
        Observer.Observe('after', SnapALBC(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;prR1;pfR1;pcR1;pfR1;prR1;pfR1;pcR1;pfR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('host next', 'true|R2');
        Observer.Expect('host next log', 'hrR2;hrR2;hfR2;hcR2;hfR2;hrR2;hfR2;hrR3;hfR3;hrR2;hrR1;hfR1;hrR2;hrR2;hfR2;hcR2;hfR2;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;prR2;pfR2;prR2;pfR2;pcR2;pfR2;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hrR1;hfR1;hcR1;hfR1;hrR2;hrR2;hfR2;hcR2;hfR2;hrR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR2;arR2;afR2;acR2;afR2;arR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;prR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('after next', 'R2|R2/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after next log', '');
        Observer.Expect('host previous', 'true|R1');
        Observer.Expect('host previous log', 'hrR1;hfR1;hcR1;hfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;ccR1;cfR1');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABLC_ReadEach()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABLC";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABLC(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('resource no log', Log.Take());
        Observer.Observe('current no', Schedule.CurrentNo.Value());
        Observer.Observe('host fn', Schedule.HostFn.Value());
        Observer.Observe('host log', Log.Take());
        Observer.Observe('OtherA read', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value());
        Observer.Observe('OtherA read log', Log.Take());
        Observer.Observe('OtherB read', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value());
        Observer.Observe('OtherB read log', Log.Take());
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('OtherC read', Schedule.OtherC."No.".Value() + '|' + Schedule.OtherC.OtherCCurrent.Value() + '|' + Schedule.OtherC.OtherCFn.Value());
        Observer.Observe('OtherC read log', Log.Take());
        Observer.Observe('after', SnapABLC(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;pcR1;pfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('resource no', 'R2');
        Observer.Expect('resource no log', '');
        Observer.Expect('current no', 'R1/');
        Observer.Expect('host fn', 'R1/R2');
        Observer.Expect('host log', '');
        Observer.Expect('OtherA read', 'R1|R1/|R1/');
        Observer.Expect('OtherA read log', '');
        Observer.Expect('OtherB read', 'R1|R1/|R1/');
        Observer.Expect('OtherB read log', '');
        Observer.Expect('Resources read', 'R1|R1/|R1/');
        Observer.Expect('Resources read log', '');
        Observer.Expect('OtherC read', 'R1|R1/|R1/');
        Observer.Expect('OtherC read log', '');
        Observer.Expect('after', 'R2|R1/|R1|R1/|R1/R2|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABLC_ReadReverse()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABLC";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABLC(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('OtherC read', Schedule.OtherC."No.".Value() + '|' + Schedule.OtherC.OtherCCurrent.Value() + '|' + Schedule.OtherC.OtherCFn.Value());
        Observer.Observe('OtherC read log', Log.Take());
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('OtherB read', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value());
        Observer.Observe('OtherB read log', Log.Take());
        Observer.Observe('OtherA read', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value());
        Observer.Observe('OtherA read log', Log.Take());
        Observer.Observe('after', SnapABLC(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;pcR1;pfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('OtherC read', 'R1|R1/|R1/');
        Observer.Expect('OtherC read log', '');
        Observer.Expect('Resources read', 'R1|R1/|R1/');
        Observer.Expect('Resources read log', '');
        Observer.Expect('OtherB read', 'R1|R1/|R1/');
        Observer.Expect('OtherB read log', '');
        Observer.Expect('OtherA read', 'R1|R1/|R1/');
        Observer.Expect('OtherA read log', '');
        Observer.Expect('after', 'R2|R1/|R1|R1/|R1/R2|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABLC_NextOtherA()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABLC";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABLC(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('OtherA next', Format(Schedule.OtherA.Next(), 0, 9) + '|' + Schedule.OtherA."No.".Value());
        Observer.Observe('OtherA next log', Log.Take());
        Observer.Observe('OtherB next', Format(Schedule.OtherB.Next(), 0, 9) + '|' + Schedule.OtherB."No.".Value());
        Observer.Observe('OtherB next log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('OtherC next', Format(Schedule.OtherC.Next(), 0, 9) + '|' + Schedule.OtherC."No.".Value());
        Observer.Observe('OtherC next log', Log.Take());
        Observer.Observe('after', SnapABLC(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;pcR1;pfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('OtherA next', 'true|R2');
        Observer.Expect('OtherA next log', 'arR2;arR2;afR2;acR2;afR2;hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR2;afR2;arR3;afR3;arR2;arR1;afR1;arR2;arR2;afR2;acR2;afR2;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;pcR1;pfR1');
        Observer.Expect('OtherB next', 'true|R2');
        Observer.Expect('OtherB next log', 'brR2;brR2;bfR2;bcR2;bfR2;hrR2;hrR2;hfR2;hcR2;hfR2;arR2;arR2;afR2;acR2;afR2;prR2;crR2;crR2;cfR2;ccR2;cfR2');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', '');
        Observer.Expect('OtherC next', 'true|R2');
        Observer.Expect('OtherC next log', 'crR2;cfR2;ccR2;cfR2');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', 'prR1;hrR1');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABLC_NextResources()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABLC";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABLC(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('OtherA next', Format(Schedule.OtherA.Next(), 0, 9) + '|' + Schedule.OtherA."No.".Value());
        Observer.Observe('OtherA next log', Log.Take());
        Observer.Observe('OtherB next', Format(Schedule.OtherB.Next(), 0, 9) + '|' + Schedule.OtherB."No.".Value());
        Observer.Observe('OtherB next log', Log.Take());
        Observer.Observe('OtherC next', Format(Schedule.OtherC.Next(), 0, 9) + '|' + Schedule.OtherC."No.".Value());
        Observer.Observe('OtherC next log', Log.Take());
        Observer.Observe('after', SnapABLC(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;pcR1;pfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;pcR1;pfR1');
        Observer.Expect('OtherA next', 'true|R2');
        Observer.Expect('OtherA next log', 'arR2;arR2;afR2;acR2;afR2;hrR2;hrR2;hfR2;hcR2;hfR2;brR2;brR2;bfR2;bcR2;bfR2;prR2;crR2;crR2;cfR2;ccR2;cfR2');
        Observer.Expect('OtherB next', 'true|R2');
        Observer.Expect('OtherB next log', 'brR2;bfR2;bcR2;bfR2');
        Observer.Expect('OtherC next', 'true|R2');
        Observer.Expect('OtherC next log', 'crR2;cfR2;ccR2;cfR2');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', 'prR1;hrR1');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABLC_NextOtherC()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABLC";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABLC(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('OtherC next', Format(Schedule.OtherC.Next(), 0, 9) + '|' + Schedule.OtherC."No.".Value());
        Observer.Observe('OtherC next log', Log.Take());
        Observer.Observe('OtherA next', Format(Schedule.OtherA.Next(), 0, 9) + '|' + Schedule.OtherA."No.".Value());
        Observer.Observe('OtherA next log', Log.Take());
        Observer.Observe('OtherB next', Format(Schedule.OtherB.Next(), 0, 9) + '|' + Schedule.OtherB."No.".Value());
        Observer.Observe('OtherB next log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('after', SnapABLC(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;pcR1;pfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('OtherC next', 'true|R2');
        Observer.Expect('OtherC next log', 'crR2;crR2;cfR2;ccR2;cfR2;hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;crR2;cfR2;crR3;cfR3;crR2;crR1;cfR1;crR2;crR2;cfR2;ccR2;cfR2;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('OtherA next', 'true|R2');
        Observer.Expect('OtherA next log', 'arR2;arR2;afR2;acR2;afR2;hrR2;hrR2;hfR2;hcR2;hfR2;brR2;brR2;bfR2;bcR2;bfR2;prR2;crR2;cfR2;ccR2;cfR2');
        Observer.Expect('OtherB next', 'true|R2');
        Observer.Expect('OtherB next log', 'brR2;bfR2;bcR2;bfR2');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', '');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', 'prR1;hrR1');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABLC_HostNext()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABLC";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABLC(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('host next', Format(Schedule.Next(), 0, 9) + '|' + Schedule."No.".Value());
        Observer.Observe('host next log', Log.Take());
        Observer.Observe('after next', SnapABLC(Schedule));
        Observer.Observe('after next log', Log.Take());
        Observer.Observe('host previous', Format(Schedule.Previous(), 0, 9) + '|' + Schedule."No.".Value());
        Observer.Observe('host previous log', Log.Take());
        Observer.Observe('after', SnapABLC(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;pcR1;pfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('host next', 'true|R2');
        Observer.Expect('host next log', 'hrR2;hrR2;hfR2;hcR2;hfR2;hrR2;hfR2;hrR3;hfR3;hrR2;hrR1;hfR1;hrR2;hrR2;hfR2;hcR2;hfR2;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR2;pfR2;prR2;pfR2;pcR2;pfR2;crR1;cfR1;crR2;cfR2;crR3;cfR3;crR1;crR1;cfR1;ccR1;cfR1;hrR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR2;hrR2;hfR2;hcR2;hfR2;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR2;arR2;afR2;acR2;afR2;arR1;arR1;afR1;acR1;afR1;brR2;brR2;bfR2;bcR2;bfR2;brR1;brR1;bfR1;bcR1;bfR1;prR1');
        Observer.Expect('after next', 'R2|R2/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after next log', '');
        Observer.Expect('host previous', 'true|R1');
        Observer.Expect('host previous log', 'hrR1;hfR1;hcR1;hfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1;crR1;cfR1;ccR1;cfR1');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABLKM_ReadEach()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABLKM";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABLKM(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('resource no log', Log.Take());
        Observer.Observe('current no', Schedule.CurrentNo.Value());
        Observer.Observe('host fn', Schedule.HostFn.Value());
        Observer.Observe('host log', Log.Take());
        Observer.Observe('OtherA read', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value());
        Observer.Observe('OtherA read log', Log.Take());
        Observer.Observe('OtherB read', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value());
        Observer.Observe('OtherB read log', Log.Take());
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('Details read', Schedule.Details."No.".Value() + '|' + Schedule.Details.CardCurrent.Value() + '|' + Schedule.Details.CardFn.Value());
        Observer.Observe('Details read log', Log.Take());
        Observer.Observe('Details2 read', Schedule.Details2."No.".Value() + '|' + Schedule.Details2.Card2Current.Value() + '|' + Schedule.Details2.Card2Fn.Value());
        Observer.Observe('Details2 read log', Log.Take());
        Observer.Observe('after', SnapABLKM(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('resource no', 'R2');
        Observer.Expect('resource no log', '');
        Observer.Expect('current no', 'R1/');
        Observer.Expect('host fn', 'R1/R2');
        Observer.Expect('host log', '');
        Observer.Expect('OtherA read', 'R1|R1/|R1/');
        Observer.Expect('OtherA read log', '');
        Observer.Expect('OtherB read', 'R1|R1/|R1/');
        Observer.Expect('OtherB read log', '');
        Observer.Expect('Resources read', 'R1|R1/|R1/');
        Observer.Expect('Resources read log', '');
        Observer.Expect('Details read', 'R1|R1/|R1/');
        Observer.Expect('Details read log', '');
        Observer.Expect('Details2 read', 'R1|R1/|R1/');
        Observer.Expect('Details2 read log', '');
        Observer.Expect('after', 'R2|R1/|R1|R1/|R1/R2|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABLKM_ReadReverse()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABLKM";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABLKM(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('Details2 read', Schedule.Details2."No.".Value() + '|' + Schedule.Details2.Card2Current.Value() + '|' + Schedule.Details2.Card2Fn.Value());
        Observer.Observe('Details2 read log', Log.Take());
        Observer.Observe('Details read', Schedule.Details."No.".Value() + '|' + Schedule.Details.CardCurrent.Value() + '|' + Schedule.Details.CardFn.Value());
        Observer.Observe('Details read log', Log.Take());
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('OtherB read', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value());
        Observer.Observe('OtherB read log', Log.Take());
        Observer.Observe('OtherA read', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value());
        Observer.Observe('OtherA read log', Log.Take());
        Observer.Observe('after', SnapABLKM(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('Details2 read', 'R1|R1/|R1/');
        Observer.Expect('Details2 read log', '');
        Observer.Expect('Details read', 'R1|R1/|R1/');
        Observer.Expect('Details read log', '');
        Observer.Expect('Resources read', 'R1|R1/|R1/');
        Observer.Expect('Resources read log', '');
        Observer.Expect('OtherB read', 'R1|R1/|R1/');
        Observer.Expect('OtherB read log', '');
        Observer.Expect('OtherA read', 'R1|R1/|R1/');
        Observer.Expect('OtherA read log', '');
        Observer.Expect('after', 'R2|R1/|R1|R1/|R1/R2|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABLKM_NextOtherA()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABLKM";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABLKM(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('OtherA next', Format(Schedule.OtherA.Next(), 0, 9) + '|' + Schedule.OtherA."No.".Value());
        Observer.Observe('OtherA next log', Log.Take());
        Observer.Observe('OtherB next', Format(Schedule.OtherB.Next(), 0, 9) + '|' + Schedule.OtherB."No.".Value());
        Observer.Observe('OtherB next log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('Details next', Format(Schedule.Details.Next(), 0, 9) + '|' + Schedule.Details."No.".Value());
        Observer.Observe('Details next log', Log.Take());
        Observer.Observe('Details2 next', Format(Schedule.Details2.Next(), 0, 9) + '|' + Schedule.Details2."No.".Value());
        Observer.Observe('Details2 next log', Log.Take());
        Observer.Observe('after', SnapABLKM(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('OtherA next', 'true|R2');
        Observer.Expect('OtherA next log', 'arR2;arR2;afR2;acR2;afR2;hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR2;afR2;arR3;afR3;arR2;arR1;afR1;arR2;arR2;afR2;acR2;afR2;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('OtherB next', 'true|R2');
        Observer.Expect('OtherB next log', 'brR2;brR2;bfR2;bcR2;bfR2;hrR2;hrR2;hfR2;hcR2;hfR2;arR2;arR2;afR2;acR2;afR2;prR2');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', '');
        Observer.Expect('Details next', 'false|R1');
        Observer.Expect('Details next log', '');
        Observer.Expect('Details2 next', 'false|R1');
        Observer.Expect('Details2 next log', '');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', 'prR1;hrR1');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABLKM_NextResources()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABLKM";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABLKM(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('OtherA next', Format(Schedule.OtherA.Next(), 0, 9) + '|' + Schedule.OtherA."No.".Value());
        Observer.Observe('OtherA next log', Log.Take());
        Observer.Observe('OtherB next', Format(Schedule.OtherB.Next(), 0, 9) + '|' + Schedule.OtherB."No.".Value());
        Observer.Observe('OtherB next log', Log.Take());
        Observer.Observe('Details next', Format(Schedule.Details.Next(), 0, 9) + '|' + Schedule.Details."No.".Value());
        Observer.Observe('Details next log', Log.Take());
        Observer.Observe('Details2 next', Format(Schedule.Details2.Next(), 0, 9) + '|' + Schedule.Details2."No.".Value());
        Observer.Observe('Details2 next log', Log.Take());
        Observer.Observe('after', SnapABLKM(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('OtherA next', 'true|R2');
        Observer.Expect('OtherA next log', 'arR2;arR2;afR2;acR2;afR2;hrR2;hrR2;hfR2;hcR2;hfR2;brR2;brR2;bfR2;bcR2;bfR2;prR2');
        Observer.Expect('OtherB next', 'true|R2');
        Observer.Expect('OtherB next log', 'brR2;bfR2;bcR2;bfR2');
        Observer.Expect('Details next', 'false|R1');
        Observer.Expect('Details next log', '');
        Observer.Expect('Details2 next', 'false|R1');
        Observer.Expect('Details2 next log', '');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', 'prR1;hrR1');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABLKM_NextDetails2()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABLKM";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABLKM(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('Details2 next', Format(Schedule.Details2.Next(), 0, 9) + '|' + Schedule.Details2."No.".Value());
        Observer.Observe('Details2 next log', Log.Take());
        Observer.Observe('OtherA next', Format(Schedule.OtherA.Next(), 0, 9) + '|' + Schedule.OtherA."No.".Value());
        Observer.Observe('OtherA next log', Log.Take());
        Observer.Observe('OtherB next', Format(Schedule.OtherB.Next(), 0, 9) + '|' + Schedule.OtherB."No.".Value());
        Observer.Observe('OtherB next log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('Details next', Format(Schedule.Details.Next(), 0, 9) + '|' + Schedule.Details."No.".Value());
        Observer.Observe('Details next log', Log.Take());
        Observer.Observe('after', SnapABLKM(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('Details2 next', 'false|R1');
        Observer.Expect('Details2 next log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('OtherA next', 'true|R2');
        Observer.Expect('OtherA next log', 'arR2;arR2;afR2;acR2;afR2;hrR2;hrR2;hfR2;hcR2;hfR2;brR2;brR2;bfR2;bcR2;bfR2;prR2');
        Observer.Expect('OtherB next', 'true|R2');
        Observer.Expect('OtherB next log', 'brR2;bfR2;bcR2;bfR2');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', '');
        Observer.Expect('Details next', 'false|R1');
        Observer.Expect('Details next log', '');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', 'prR1;hrR1');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_ABLKM_HostNext()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host ABLKM";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABLKM(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('host next', Format(Schedule.Next(), 0, 9) + '|' + Schedule."No.".Value());
        Observer.Observe('host next log', Log.Take());
        Observer.Observe('after next', SnapABLKM(Schedule));
        Observer.Observe('after next log', Log.Take());
        Observer.Observe('host previous', Format(Schedule.Previous(), 0, 9) + '|' + Schedule."No.".Value());
        Observer.Observe('host previous log', Log.Take());
        Observer.Observe('after', SnapABLKM(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;arR1;afR1;acR1;afR1;arR1;afR1;acR1;afR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('host next', 'true|R2');
        Observer.Expect('host next log', 'hrR2;hrR2;hfR2;hcR2;hfR2;hrR2;hfR2;hrR3;hfR3;hrR2;hrR1;hfR1;hrR2;hrR2;hfR2;hcR2;hfR2;arR1;afR1;arR2;afR2;arR3;afR3;arR1;arR1;afR1;acR1;afR1;brR1;bfR1;brR2;bfR2;brR3;bfR3;brR1;brR1;bfR1;bcR1;bfR1;prR2;pfR2;prR2;pfR2;pcR2;pfR2;krR2;kfR2;kcR2;kfR2;mrR2;mfR2;mcR2;mfR2;hrR1;hrR1;hfR1;hcR1;hfR1;hrR1;hfR1;hcR1;hfR1;hrR2;hrR2;hfR2;hcR2;hfR2;arR1;afR1;acR1;afR1;arR2;arR2;afR2;acR2;afR2;brR2;brR2;bfR2;bcR2;bfR2');
        Observer.Expect('after next', 'R2|R2/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2');
        Observer.Expect('after next log', '');
        Observer.Expect('host previous', 'true|R1');
        Observer.Expect('host previous log', 'hrR1;hrR1;hfR1;hcR1;hfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1;arR1;arR1;afR1;acR1;afR1;brR1;brR1;bfR1;bcR1;bfR1');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_LKM_ReadEach()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host LKM";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapLKM(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('resource no log', Log.Take());
        Observer.Observe('current no', Schedule.CurrentNo.Value());
        Observer.Observe('host fn', Schedule.HostFn.Value());
        Observer.Observe('host log', Log.Take());
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('Details read', Schedule.Details."No.".Value() + '|' + Schedule.Details.CardCurrent.Value() + '|' + Schedule.Details.CardFn.Value());
        Observer.Observe('Details read log', Log.Take());
        Observer.Observe('Details2 read', Schedule.Details2."No.".Value() + '|' + Schedule.Details2.Card2Current.Value() + '|' + Schedule.Details2.Card2Fn.Value());
        Observer.Observe('Details2 read log', Log.Take());
        Observer.Observe('after', SnapLKM(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('resource no', 'R2');
        Observer.Expect('resource no log', '');
        Observer.Expect('current no', 'R1/');
        Observer.Expect('host fn', 'R1/R2');
        Observer.Expect('host log', '');
        Observer.Expect('Resources read', 'R1|R1/|R1/');
        Observer.Expect('Resources read log', '');
        Observer.Expect('Details read', 'R1|R1/|R1/');
        Observer.Expect('Details read log', '');
        Observer.Expect('Details2 read', 'R1|R1/|R1/');
        Observer.Expect('Details2 read log', '');
        Observer.Expect('after', 'R2|R1/|R1|R1/|R1/R2|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_LKM_ReadReverse()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host LKM";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapLKM(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('Details2 read', Schedule.Details2."No.".Value() + '|' + Schedule.Details2.Card2Current.Value() + '|' + Schedule.Details2.Card2Fn.Value());
        Observer.Observe('Details2 read log', Log.Take());
        Observer.Observe('Details read', Schedule.Details."No.".Value() + '|' + Schedule.Details.CardCurrent.Value() + '|' + Schedule.Details.CardFn.Value());
        Observer.Observe('Details read log', Log.Take());
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('after', SnapLKM(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('Details2 read', 'R1|R1/|R1/');
        Observer.Expect('Details2 read log', '');
        Observer.Expect('Details read', 'R1|R1/|R1/');
        Observer.Expect('Details read log', '');
        Observer.Expect('Resources read', 'R1|R1/|R1/');
        Observer.Expect('Resources read log', '');
        Observer.Expect('after', 'R2|R1/|R1|R1/|R1/R2|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_LKM_NextResources()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host LKM";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapLKM(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('Details next', Format(Schedule.Details.Next(), 0, 9) + '|' + Schedule.Details."No.".Value());
        Observer.Observe('Details next log', Log.Take());
        Observer.Observe('Details2 next', Format(Schedule.Details2.Next(), 0, 9) + '|' + Schedule.Details2."No.".Value());
        Observer.Observe('Details2 next log', Log.Take());
        Observer.Observe('after', SnapLKM(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1');
        Observer.Expect('Details next', 'false|R1');
        Observer.Expect('Details next log', '');
        Observer.Expect('Details2 next', 'false|R1');
        Observer.Expect('Details2 next log', '');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_LKM_NextDetails2()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host LKM";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapLKM(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('Details2 next', Format(Schedule.Details2.Next(), 0, 9) + '|' + Schedule.Details2."No.".Value());
        Observer.Observe('Details2 next log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('Details next', Format(Schedule.Details.Next(), 0, 9) + '|' + Schedule.Details."No.".Value());
        Observer.Observe('Details next log', Log.Take());
        Observer.Observe('after', SnapLKM(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('Details2 next', 'false|R1');
        Observer.Expect('Details2 next log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', '');
        Observer.Expect('Details next', 'false|R1');
        Observer.Expect('Details next log', '');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;



    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure Y87_LKM_HostNext()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT Y87 Host LKM";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapLKM(Schedule));
        Observer.Observe('before log', Log.Take());
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('host next', Format(Schedule.Next(), 0, 9) + '|' + Schedule."No.".Value());
        Observer.Observe('host next log', Log.Take());
        Observer.Observe('after next', SnapLKM(Schedule));
        Observer.Observe('after next log', Log.Take());
        Observer.Observe('host previous', Format(Schedule.Previous(), 0, 9) + '|' + Schedule."No.".Value());
        Observer.Observe('host previous log', Log.Take());
        Observer.Observe('after', SnapLKM(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'hrR1;hfR1;hrR2;hfR2;hrR3;hfR3;hrR1;hrR1;hfR1;hcR1;hfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;hfR1;validate R2;hfR1');
        Observer.Expect('host next', 'true|R2');
        Observer.Expect('host next log', 'hrR2;hrR2;hfR2;hcR2;hfR2;hrR2;hfR2;hrR3;hfR3;hrR2;hrR1;hfR1;hrR2;hrR2;hfR2;hcR2;hfR2;prR2;pfR2;prR2;pfR2;pcR2;pfR2;krR2;kfR2;kcR2;kfR2;mrR2;mfR2;mcR2;mfR2;hrR2;hfR2;hcR2;hfR2');
        Observer.Expect('after next', 'R2|R2/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2');
        Observer.Expect('after next log', '');
        Observer.Expect('host previous', 'true|R1');
        Observer.Expect('host previous log', 'hrR1;hrR1;hfR1;hcR1;hfR1;prR1;pfR1;prR1;pfR1;pcR1;pfR1;krR1;kfR1;kcR1;kfR1;mrR1;mfR1;mcR1;mfR1;hrR1;hfR1;hcR1;hfR1');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;




    local procedure Setup()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Resource: Record "LT Y15 Lookup Resource";
    begin
        Log.Take();
        Setting.DeleteAll();
        Resource.DeleteAll();
        InsertResource(Resource, 'R1', 'G1');
        InsertResource(Resource, 'R2', 'G1');
        InsertResource(Resource, 'R3', 'G2');
    end;

    local procedure InsertResource(var Resource: Record "LT Y15 Lookup Resource"; ResourceNo: Code[20]; GroupCode: Code[20])
    begin
        Resource.Init();
        Resource."No." := ResourceNo;
        Resource."Group Code" := GroupCode;
        Resource.Insert();
    end;


    local procedure ObserveChunks(Label: Text; Value: Text)
    var
        Index: Integer;
        Part: Integer;
    begin
        // keeps every observation short enough that the failure message of the runner never cuts it
        Part := 1;
        Index := 1;
        while Index <= StrLen(Value) do begin
            Observer.Observe(Label + ' ' + Format(Part), CopyStr(Value, Index, 400));
            Index += 400;
            Part += 1;
        end;
    end;

    local procedure SnapABCDL(var Schedule: TestPage "LT Y87 Host ABCDL"): Text
    begin
        exit(Schedule.ResourceNo.Value() + '|' + Schedule.HeaderCurrent.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.CurrentNo.Value() + '|' + Schedule.HostFn.Value() + '|' + Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value() + '|' + Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value() + '|' + Schedule.OtherC."No.".Value() + '|' + Schedule.OtherC.OtherCCurrent.Value() + '|' + Schedule.OtherC.OtherCFn.Value() + '|' + Schedule.OtherD."No.".Value() + '|' + Schedule.OtherD.OtherDCurrent.Value() + '|' + Schedule.OtherD.OtherDFn.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
    end;

    local procedure SnapABCDEL(var Schedule: TestPage "LT Y87 Host ABCDEL"): Text
    begin
        exit(Schedule.ResourceNo.Value() + '|' + Schedule.HeaderCurrent.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.CurrentNo.Value() + '|' + Schedule.HostFn.Value() + '|' + Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value() + '|' + Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value() + '|' + Schedule.OtherC."No.".Value() + '|' + Schedule.OtherC.OtherCCurrent.Value() + '|' + Schedule.OtherC.OtherCFn.Value() + '|' + Schedule.OtherD."No.".Value() + '|' + Schedule.OtherD.OtherDCurrent.Value() + '|' + Schedule.OtherD.OtherDFn.Value() + '|' + Schedule.OtherE."No.".Value() + '|' + Schedule.OtherE.OtherECurrent.Value() + '|' + Schedule.OtherE.OtherEFn.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
    end;

    local procedure SnapALBC(var Schedule: TestPage "LT Y87 Host ALBC"): Text
    begin
        exit(Schedule.ResourceNo.Value() + '|' + Schedule.HeaderCurrent.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.CurrentNo.Value() + '|' + Schedule.HostFn.Value() + '|' + Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value() + '|' + Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value() + '|' + Schedule.OtherC."No.".Value() + '|' + Schedule.OtherC.OtherCCurrent.Value() + '|' + Schedule.OtherC.OtherCFn.Value());
    end;

    local procedure SnapABLC(var Schedule: TestPage "LT Y87 Host ABLC"): Text
    begin
        exit(Schedule.ResourceNo.Value() + '|' + Schedule.HeaderCurrent.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.CurrentNo.Value() + '|' + Schedule.HostFn.Value() + '|' + Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value() + '|' + Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value() + '|' + Schedule.OtherC."No.".Value() + '|' + Schedule.OtherC.OtherCCurrent.Value() + '|' + Schedule.OtherC.OtherCFn.Value());
    end;

    local procedure SnapABLKM(var Schedule: TestPage "LT Y87 Host ABLKM"): Text
    begin
        exit(Schedule.ResourceNo.Value() + '|' + Schedule.HeaderCurrent.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.CurrentNo.Value() + '|' + Schedule.HostFn.Value() + '|' + Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value() + '|' + Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value() + '|' + Schedule.Details."No.".Value() + '|' + Schedule.Details.CardCurrent.Value() + '|' + Schedule.Details.CardFn.Value() + '|' + Schedule.Details2."No.".Value() + '|' + Schedule.Details2.Card2Current.Value() + '|' + Schedule.Details2.Card2Fn.Value());
    end;

    local procedure SnapLKM(var Schedule: TestPage "LT Y87 Host LKM"): Text
    begin
        exit(Schedule.ResourceNo.Value() + '|' + Schedule.HeaderCurrent.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.CurrentNo.Value() + '|' + Schedule.HostFn.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value() + '|' + Schedule.Details."No.".Value() + '|' + Schedule.Details.CardCurrent.Value() + '|' + Schedule.Details.CardFn.Value() + '|' + Schedule.Details2."No.".Value() + '|' + Schedule.Details2.Card2Current.Value() + '|' + Schedule.Details2.Card2Fn.Value());
    end;


    [ModalPageHandler]
    procedure PickSecondResource(var ResourceList: TestPage "LT Y15 Lookup Resource List")
    begin
        ResourceList.GoToKey('R2');
        ResourceList.OK().Invoke();
    end;
}