// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-lookup-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables and pages of LT Y15 Lookup (91710 - 91712, 91713); own objects 94560 - 94579 (writer R6806)
// Probe: al-runner issue 6806, follow-up to 6639 (Y63, pages/lt-y15/Y15LookupThreeFieldLink.al). The Y63 hosts have a List page over
//   resources with a header field ResourceNo (OnLookup runs the resource list, OnValidate modifies the setting and calls
//   CurrPage.Update(false)), row triggers and function controls, and a ListPart linked on No., Group Code and Region Code with
//   one more part: an unlinked ListPart or a FactBox CardPart. This file measures three, four and more parts: two unlinked
//   ListParts (OtherA, OtherB, OtherC) before, between or after the linked part, with and without a FactBox CardPart, and the
//   reporter's shape (host with OnAfterGetCurrRecord only, parts without triggers). Every part logs its triggers with its own prefix
//   (p linked, o OtherA, q OtherB, w OtherC, c card, h host).

// Result (BC 28.5 on Windows; the CI legs check 27.5, 28.5 and 29.0): as with one or two parts. The lookup shows R2 in ResourceNo, runs
//   OnValidate once and stores R2; the globals and every part keep the values of before ('R1/'). The refresh of CurrPage.Update(false)
//   stays pending until the first access to a part that no call reached since the page opened (reading one of its controls) or a
//   move of a part. Parts read before the lookup and again after it run nothing and show the old values. The refresh runs the open's
//   reads again: the host rows, each part in layout order, then a tail: the host's current row once per ListPart of the content area,
//   then each of these ListParts but the last of the layout once less than the one before (OtherA twice, OtherB once with three).
//   A FactBox CardPart runs in the open's reads after the ListParts and is not in the tail. Four parts: host four times, then three,
//   two, one. The reporter's shape (host OnAfterGetCurrRecord only, parts without triggers): ResourceNo R2, CurrentNo and every
//   part R1, stored R2. A move of a part after the lookup adds reads of the host and the parts that follow (the *NextFirst tests).

codeunit 94560 "LT R6806 Log"
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

page 94561 "LT R6806 Linked Part"
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
                field(PartCurrent; Current) { ApplicationArea = All; Caption = 'Part Current'; }
                field(PartFn; GetNo()) { ApplicationArea = All; Caption = 'Part Fn'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('p-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('p-agcr ' + Rec."No.");
        Current := Rec."No." + '/' + StoredResourceNo();
    end;

    local procedure GetNo(): Code[20]
    begin
        Log.Add('p-fn ' + Rec."No.");
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
        Log: Codeunit "LT R6806 Log";
}

page 94562 "LT R6806 Other Part A"
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
                field(OtherACurrent; Current) { ApplicationArea = All; Caption = 'OtherA Current'; }
                field(OtherAFn; GetNo()) { ApplicationArea = All; Caption = 'OtherA Fn'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('o-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('o-agcr ' + Rec."No.");
        Current := Rec."No." + '/' + StoredResourceNo();
    end;

    local procedure GetNo(): Code[20]
    begin
        Log.Add('o-fn ' + Rec."No.");
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
        Log: Codeunit "LT R6806 Log";
}

page 94563 "LT R6806 Other Part B"
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
                field(OtherBCurrent; Current) { ApplicationArea = All; Caption = 'OtherB Current'; }
                field(OtherBFn; GetNo()) { ApplicationArea = All; Caption = 'OtherB Fn'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('q-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('q-agcr ' + Rec."No.");
        Current := Rec."No." + '/' + StoredResourceNo();
    end;

    local procedure GetNo(): Code[20]
    begin
        Log.Add('q-fn ' + Rec."No.");
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
        Log: Codeunit "LT R6806 Log";
}

page 94564 "LT R6806 Other Part C"
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
                field(OtherCCurrent; Current) { ApplicationArea = All; Caption = 'OtherC Current'; }
                field(OtherCFn; GetNo()) { ApplicationArea = All; Caption = 'OtherC Fn'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('w-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('w-agcr ' + Rec."No.");
        Current := Rec."No." + '/' + StoredResourceNo();
    end;

    local procedure GetNo(): Code[20]
    begin
        Log.Add('w-fn ' + Rec."No.");
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
        Log: Codeunit "LT R6806 Log";
}

page 94565 "LT R6806 Card Part"
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
            field(CardCurrent; Current) { ApplicationArea = All; Caption = 'Card Current'; }
            field(CardFn; GetNo()) { ApplicationArea = All; Caption = 'Card Fn'; }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('c-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('c-agcr ' + Rec."No.");
        Current := Rec."No." + '/' + StoredResourceNo();
    end;

    local procedure GetNo(): Code[20]
    begin
        Log.Add('c-fn ' + Rec."No.");
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
        Log: Codeunit "LT R6806 Log";
}

page 94566 "LT R6806 AB L Sched"
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
            part(OtherA; "LT R6806 Other Part A")
            {
                ApplicationArea = All;
            }
            part(OtherB; "LT R6806 Other Part B")
            {
                ApplicationArea = All;
            }
            part(Resources; "LT R6806 Linked Part")
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
        Log.Add('h-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('h-agcr ' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('h-fn ' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT R6806 Log";
}

page 94567 "LT R6806 L AB Sched"
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
            part(Resources; "LT R6806 Linked Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code"),
                              "Region Code" = field("Region Code");
            }
            part(OtherA; "LT R6806 Other Part A")
            {
                ApplicationArea = All;
            }
            part(OtherB; "LT R6806 Other Part B")
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
        Log.Add('h-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('h-agcr ' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('h-fn ' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT R6806 Log";
}

page 94568 "LT R6806 A L B Sched"
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
            part(OtherA; "LT R6806 Other Part A")
            {
                ApplicationArea = All;
            }
            part(Resources; "LT R6806 Linked Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code"),
                              "Region Code" = field("Region Code");
            }
            part(OtherB; "LT R6806 Other Part B")
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
        Log.Add('h-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('h-agcr ' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('h-fn ' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT R6806 Log";
}

page 94569 "LT R6806 AB L Card Sched"
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
            part(OtherA; "LT R6806 Other Part A")
            {
                ApplicationArea = All;
            }
            part(OtherB; "LT R6806 Other Part B")
            {
                ApplicationArea = All;
            }
            part(Resources; "LT R6806 Linked Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code"),
                              "Region Code" = field("Region Code");
            }
        }
        area(FactBoxes)
        {
            part(Details; "LT R6806 Card Part")
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
        Log.Add('h-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('h-agcr ' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('h-fn ' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT R6806 Log";
}

page 94570 "LT R6806 ABC L Sched"
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
            part(OtherA; "LT R6806 Other Part A")
            {
                ApplicationArea = All;
            }
            part(OtherB; "LT R6806 Other Part B")
            {
                ApplicationArea = All;
            }
            part(OtherC; "LT R6806 Other Part C")
            {
                ApplicationArea = All;
            }
            part(Resources; "LT R6806 Linked Part")
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
        Log.Add('h-agr ' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('h-agcr ' + Rec."No.");
        CurrentNo := Rec."No." + '/' + Setting."Resource No.";
    end;

    local procedure GetHostNo(): Code[20]
    begin
        Log.Add('h-fn ' + Rec."No.");
        exit(Rec."No." + '/' + Setting."Resource No.");
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
        Log: Codeunit "LT R6806 Log";
}

page 94571 "LT R6806 Plain Part"
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
            }
        }
    }
}

page 94572 "LT R6806 Plain Card Part"
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
            field("Group Code"; Rec."Group Code") { ApplicationArea = All; }
        }
    }
}

page 94573 "LT R6806 Rep AB L Sched"
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
                        if Page.RunModal(Page::"LT Y15 Lookup Resource List", Resource) <> Action::LookupOK then
                            exit(false);
                        Text := Resource."No.";
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        Setting.Modify();
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(CurrentNo; CurrentNo) { ApplicationArea = All; }
            }
            part(OtherA; "LT R6806 Plain Part")
            {
                ApplicationArea = All;
            }
            part(OtherB; "LT R6806 Plain Part")
            {
                ApplicationArea = All;
            }
            part(Resources; "LT R6806 Plain Part")
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

    trigger OnAfterGetCurrRecord()
    begin
        CurrentNo := Rec."No.";
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
}

page 94574 "LT R6806 Rep AB L Card Sched"
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
                        if Page.RunModal(Page::"LT Y15 Lookup Resource List", Resource) <> Action::LookupOK then
                            exit(false);
                        Text := Resource."No.";
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        Setting.Modify();
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(CurrentNo; CurrentNo) { ApplicationArea = All; }
            }
            part(OtherA; "LT R6806 Plain Part")
            {
                ApplicationArea = All;
            }
            part(OtherB; "LT R6806 Plain Part")
            {
                ApplicationArea = All;
            }
            part(Resources; "LT R6806 Plain Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Group Code" = field("Group Code"),
                              "Region Code" = field("Region Code");
            }
        }
        area(FactBoxes)
        {
            part(Details; "LT R6806 Plain Card Part")
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

    trigger OnAfterGetCurrRecord()
    begin
        CurrentNo := Rec."No.";
    end;

    var
        CurrentNo: Code[20];
        Setting: Record "LT Y15 Lookup Setting";
}

codeunit 94575 "LT R6806 Lookup Part Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT R6806 Log";


    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure R6806_ABL_LookupReadEachControl()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT R6806 AB L Sched";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABL(Schedule));
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
        Observer.Observe('after', SnapABL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agr R2;o-fn R2;o-agr R3;o-fn R3;o-agr R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agr R2;q-fn R2;q-agr R3;q-fn R3;q-agr R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
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
        Observer.Expect('after', 'R2|R1/|R1|R1/|R1/R2|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure R6806_LAB_LookupReadEachControl()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT R6806 L AB Sched";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapLAB(Schedule));
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
        Observer.Observe('OtherA read', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value());
        Observer.Observe('OtherA read log', Log.Take());
        Observer.Observe('OtherB read', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value());
        Observer.Observe('OtherB read log', Log.Take());
        Observer.Observe('after', SnapLAB(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;o-agr R1;o-fn R1;o-agr R2;o-fn R2;o-agr R3;o-fn R3;o-agr R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agr R2;q-fn R2;q-agr R3;q-fn R3;q-agr R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('resource no', 'R2');
        Observer.Expect('resource no log', '');
        Observer.Expect('current no', 'R1/');
        Observer.Expect('host fn', 'R1/R2');
        Observer.Expect('host log', '');
        Observer.Expect('Resources read', 'R1|R1/|R1/');
        Observer.Expect('Resources read log', '');
        Observer.Expect('OtherA read', 'R1|R1/|R1/');
        Observer.Expect('OtherA read log', '');
        Observer.Expect('OtherB read', 'R1|R1/|R1/');
        Observer.Expect('OtherB read log', '');
        Observer.Expect('after', 'R2|R1/|R1|R1/|R1/R2|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure R6806_ALB_LookupReadEachControl()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT R6806 A L B Sched";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapALB(Schedule));
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
        Observer.Observe('after', SnapALB(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agr R2;o-fn R2;o-agr R3;o-fn R3;o-agr R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;q-agr R1;q-fn R1;q-agr R2;q-fn R2;q-agr R3;q-fn R3;q-agr R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
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
        Observer.Expect('after', 'R2|R1/|R1|R1/|R1/R2|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure R6806_ABLK_LookupReadEachControl()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT R6806 AB L Card Sched";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABLK(Schedule));
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
        Observer.Observe('after', SnapABLK(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agr R2;o-fn R2;o-agr R3;o-fn R3;o-agr R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agr R2;q-fn R2;q-agr R3;q-fn R3;q-agr R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;c-agr R1;c-fn R1;c-agcr R1;c-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
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
        Observer.Expect('after', 'R2|R1/|R1|R1/|R1/R2|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure R6806_ABCL_LookupReadEachControl()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT R6806 ABC L Sched";
    begin
        Setup();
        Schedule.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('before', SnapABCL(Schedule));
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
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('after', SnapABCL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('open log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agr R2;o-fn R2;o-agr R3;o-fn R3;o-agr R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agr R2;q-fn R2;q-agr R3;q-fn R3;q-agr R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;w-agr R1;w-fn R1;w-agr R2;w-fn R2;w-agr R3;w-fn R3;w-agr R1;w-agr R1;w-fn R1;w-agcr R1;w-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;w-agr R1;w-fn R1;w-agcr R1;w-fn R1');
        Observer.Expect('before', '|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('before log', '');
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
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
        Observer.Expect('Resources read', 'R1|R1/|R1/');
        Observer.Expect('Resources read log', '');
        Observer.Expect('after', 'R2|R1/|R1|R1/|R1/R2|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure R6806_ABL_OtherBFirstReadAfterLookup()
    var
        Schedule: TestPage "LT R6806 AB L Sched";
    begin
        Setup();
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('OtherB first', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value());
        Observer.Observe('OtherB first log', Log.Take());
        Observer.Observe('OtherA read', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value());
        Observer.Observe('OtherA read log', Log.Take());
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('after', SnapABL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('OtherB first', 'R1|R1/R2');
        Observer.Expect('OtherB first log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agr R2;o-fn R2;o-agr R3;o-fn R3;o-agr R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agr R2;q-fn R2;q-agr R3;q-fn R3;q-agr R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1');
        Observer.Expect('OtherA read', 'R1|R1/R2');
        Observer.Expect('OtherA read log', '');
        Observer.Expect('Resources read', 'R1|R1/R2');
        Observer.Expect('Resources read log', '');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure R6806_ABL_ResourcesFirstReadAfterLookup()
    var
        Schedule: TestPage "LT R6806 AB L Sched";
    begin
        Setup();
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('Resources first', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value());
        Observer.Observe('Resources first log', Log.Take());
        Observer.Observe('OtherA read', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value());
        Observer.Observe('OtherA read log', Log.Take());
        Observer.Observe('OtherB read', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value());
        Observer.Observe('OtherB read log', Log.Take());
        Observer.Observe('after', SnapABL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('Resources first', 'R1|R1/R2');
        Observer.Expect('Resources first log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agr R2;o-fn R2;o-agr R3;o-fn R3;o-agr R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agr R2;q-fn R2;q-agr R3;q-fn R3;q-agr R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1');
        Observer.Expect('OtherA read', 'R1|R1/R2');
        Observer.Expect('OtherA read log', '');
        Observer.Expect('OtherB read', 'R1|R1/R2');
        Observer.Expect('OtherB read log', '');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure R6806_ABL_ResourcesNextFirst()
    var
        Schedule: TestPage "LT R6806 AB L Sched";
    begin
        Setup();
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('OtherA next', Format(Schedule.OtherA.Next(), 0, 9) + '|' + Schedule.OtherA."No.".Value());
        Observer.Observe('OtherA next log', Log.Take());
        Observer.Observe('OtherB next', Format(Schedule.OtherB.Next(), 0, 9) + '|' + Schedule.OtherB."No.".Value());
        Observer.Observe('OtherB next log', Log.Take());
        Observer.Observe('after', SnapABL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agr R2;o-fn R2;o-agr R3;o-fn R3;o-agr R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agr R2;q-fn R2;q-agr R3;q-fn R3;q-agr R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1');
        Observer.Expect('OtherA next', 'true|R2');
        Observer.Expect('OtherA next log', 'o-agr R2;o-agr R2;o-fn R2;o-agcr R2;o-fn R2;h-agr R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2;q-agr R2;q-agr R2;q-fn R2;q-agcr R2;q-fn R2;p-agr R2');
        Observer.Expect('OtherB next', 'true|R2');
        Observer.Expect('OtherB next log', 'q-agr R2;q-fn R2;q-agcr R2;q-fn R2');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', 'p-agr R1;h-agr R1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure R6806_ABL_OtherBNextFirst()
    var
        Schedule: TestPage "LT R6806 AB L Sched";
    begin
        Setup();
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('OtherB next', Format(Schedule.OtherB.Next(), 0, 9) + '|' + Schedule.OtherB."No.".Value());
        Observer.Observe('OtherB next log', Log.Take());
        Observer.Observe('OtherA next', Format(Schedule.OtherA.Next(), 0, 9) + '|' + Schedule.OtherA."No.".Value());
        Observer.Observe('OtherA next log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('after', SnapABL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('OtherB next', 'true|R2');
        Observer.Expect('OtherB next log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agr R2;o-fn R2;o-agr R3;o-fn R3;o-agr R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agr R2;q-fn R2;q-agr R3;q-fn R3;q-agr R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;q-agr R2;q-agr R2;q-fn R2;q-agcr R2;q-fn R2;h-agr R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2;o-agr R2;o-agr R2;o-fn R2;o-agcr R2;o-fn R2;p-agr R2');
        Observer.Expect('OtherA next', 'true|R2');
        Observer.Expect('OtherA next log', 'o-agr R2;o-fn R2;o-agcr R2;o-fn R2');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', '');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R2|R2/R2|R2/R2|R2|R2/R2|R2/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Expect('close log', 'p-agr R1;h-agr R1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CancelLookup')]
    procedure R6806_ABL_OtherBNextFirstAfterCancel()
    var
        Schedule: TestPage "LT R6806 AB L Sched";
    begin
        Setup();
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('OtherB next', Format(Schedule.OtherB.Next(), 0, 9) + '|' + Schedule.OtherB."No.".Value());
        Observer.Observe('OtherB next log', Log.Take());
        Observer.Observe('OtherA next', Format(Schedule.OtherA.Next(), 0, 9) + '|' + Schedule.OtherA."No.".Value());
        Observer.Observe('OtherA next log', Log.Take());
        Observer.Observe('Resources next', Format(Schedule.Resources.Next(), 0, 9) + '|' + Schedule.Resources."No.".Value());
        Observer.Observe('Resources next log', Log.Take());
        Observer.Observe('after', SnapABL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Expect('lookup log', 'lookup;h-fn R1');
        Observer.Expect('OtherB next', 'true|R2');
        Observer.Expect('OtherB next log', 'q-agr R2;q-agr R2;q-fn R2;q-agcr R2;q-fn R2;h-agr R2;h-agr R2;h-fn R2;h-agcr R2;h-fn R2;o-agr R2;o-agr R2;o-fn R2;o-agcr R2;o-fn R2;p-agr R2');
        Observer.Expect('OtherA next', 'true|R2');
        Observer.Expect('OtherA next log', 'o-agr R2;o-fn R2;o-agcr R2;o-fn R2');
        Observer.Expect('Resources next', 'false|R1');
        Observer.Expect('Resources next log', '');
        Observer.Expect('after', '|R1/|R1|R1/|R1/|R2|R2/|R2/|R2|R2/|R2/|R1|R1/|R1/');
        Observer.Expect('after log', '');
        Observer.Expect('close log', 'p-agr R1;h-agr R1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure R6806_LAB_OtherBFirstReadAfterLookup()
    var
        Schedule: TestPage "LT R6806 L AB Sched";
    begin
        Setup();
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('OtherB first', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value());
        Observer.Observe('OtherB first log', Log.Take());
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('OtherA read', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value());
        Observer.Observe('OtherA read log', Log.Take());
        Observer.Observe('after', SnapLAB(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('OtherB first', 'R1|R1/R2');
        Observer.Expect('OtherB first log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;o-agr R1;o-fn R1;o-agr R2;o-fn R2;o-agr R3;o-fn R3;o-agr R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agr R2;q-fn R2;q-agr R3;q-fn R3;q-agr R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1');
        Observer.Expect('Resources read', 'R1|R1/R2');
        Observer.Expect('Resources read log', '');
        Observer.Expect('OtherA read', 'R1|R1/R2');
        Observer.Expect('OtherA read log', '');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure R6806_ABLK_DetailsFirstReadAfterLookup()
    var
        Schedule: TestPage "LT R6806 AB L Card Sched";
    begin
        Setup();
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('Details first', Schedule.Details."No.".Value() + '|' + Schedule.Details.CardCurrent.Value());
        Observer.Observe('Details first log', Log.Take());
        Observer.Observe('OtherA read', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value());
        Observer.Observe('OtherA read log', Log.Take());
        Observer.Observe('OtherB read', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value());
        Observer.Observe('OtherB read log', Log.Take());
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('after', SnapABLK(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('Details first', 'R1|R1/R2');
        Observer.Expect('Details first log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agr R2;o-fn R2;o-agr R3;o-fn R3;o-agr R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agr R2;q-fn R2;q-agr R3;q-fn R3;q-agr R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;c-agr R1;c-fn R1;c-agcr R1;c-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1');
        Observer.Expect('OtherA read', 'R1|R1/R2');
        Observer.Expect('OtherA read log', '');
        Observer.Expect('OtherB read', 'R1|R1/R2');
        Observer.Expect('OtherB read log', '');
        Observer.Expect('Resources read', 'R1|R1/R2');
        Observer.Expect('Resources read log', '');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure R6806_ALB_OtherBFirstReadAfterLookup()
    var
        Schedule: TestPage "LT R6806 A L B Sched";
    begin
        Setup();
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('OtherB first', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value());
        Observer.Observe('OtherB first log', Log.Take());
        Observer.Observe('OtherA read', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value());
        Observer.Observe('OtherA read log', Log.Take());
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('after', SnapALB(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('OtherB first', 'R1|R1/R2');
        Observer.Expect('OtherB first log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agr R2;o-fn R2;o-agr R3;o-fn R3;o-agr R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;q-agr R1;q-fn R1;q-agr R2;q-fn R2;q-agr R3;q-fn R3;q-agr R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1');
        Observer.Expect('OtherA read', 'R1|R1/R2');
        Observer.Expect('OtherA read log', '');
        Observer.Expect('Resources read', 'R1|R1/R2');
        Observer.Expect('Resources read log', '');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure R6806_ABCL_OtherCFirstReadAfterLookup()
    var
        Schedule: TestPage "LT R6806 ABC L Sched";
    begin
        Setup();
        Schedule.OpenEdit();
        Log.Take();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('lookup log', Log.Take());
        Observer.Observe('OtherC first', Schedule.OtherC."No.".Value() + '|' + Schedule.OtherC.OtherCCurrent.Value());
        Observer.Observe('OtherC first log', Log.Take());
        Observer.Observe('OtherA read', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value());
        Observer.Observe('OtherA read log', Log.Take());
        Observer.Observe('OtherB read', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value());
        Observer.Observe('OtherB read log', Log.Take());
        Observer.Observe('Resources read', Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value());
        Observer.Observe('Resources read log', Log.Take());
        Observer.Observe('after', SnapABCL(Schedule));
        Observer.Observe('after log', Log.Take());
        Schedule.Close();
        Observer.Expect('lookup log', 'lookup;h-fn R1;validate R2;h-fn R1');
        Observer.Expect('OtherC first', 'R1|R1/R2');
        Observer.Expect('OtherC first log', 'h-agr R1;h-fn R1;h-agr R2;h-fn R2;h-agr R3;h-fn R3;h-agr R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agr R2;o-fn R2;o-agr R3;o-fn R3;o-agr R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agr R2;q-fn R2;q-agr R3;q-fn R3;q-agr R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;w-agr R1;w-fn R1;w-agr R2;w-fn R2;w-agr R3;w-fn R3;w-agr R1;w-agr R1;w-fn R1;w-agcr R1;w-fn R1;p-agr R1;p-fn R1;p-agr R1;p-fn R1;p-agcr R1;p-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;h-agr R1;h-fn R1;h-agcr R1;h-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;o-agr R1;o-fn R1;o-agcr R1;o-fn R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;q-agr R1;q-fn R1;q-agcr R1;q-fn R1;w-agr R1;w-fn R1;w-agcr R1;w-fn R1');
        Observer.Expect('OtherA read', 'R1|R1/R2');
        Observer.Expect('OtherA read log', '');
        Observer.Expect('OtherB read', 'R1|R1/R2');
        Observer.Expect('OtherB read log', '');
        Observer.Expect('Resources read', 'R1|R1/R2');
        Observer.Expect('Resources read log', '');
        Observer.Expect('after', 'R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2|R1|R1/R2|R1/R2');
        Observer.Expect('after log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure R6806_ReporterABL_LookupShowsPickedResource()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT R6806 Rep AB L Sched";
    begin
        Setup();
        Schedule.OpenEdit();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('current no', Schedule.CurrentNo.Value());
        Observer.Observe('row', Schedule."No.".Value());
        Observer.Observe('OtherA', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA."Group Code".Value());
        Observer.Observe('OtherB', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB."Group Code".Value());
        Observer.Observe('Resources', Schedule.Resources."No.".Value() + '|' + Schedule.Resources."Group Code".Value());
        Schedule.Close();
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('resource no', 'R2');
        Observer.Expect('current no', 'R1');
        Observer.Expect('row', 'R1');
        Observer.Expect('OtherA', 'R1|G1');
        Observer.Expect('OtherB', 'R1|G1');
        Observer.Expect('Resources', 'R1|G1');
        Observer.Expect('stored', 'R2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickSecondResource')]
    procedure R6806_ReporterABLK_LookupShowsPickedResource()
    var
        Setting: Record "LT Y15 Lookup Setting";
        Schedule: TestPage "LT R6806 Rep AB L Card Sched";
    begin
        Setup();
        Schedule.OpenEdit();
        Schedule.ResourceNo.Lookup();
        Observer.Observe('resource no', Schedule.ResourceNo.Value());
        Observer.Observe('current no', Schedule.CurrentNo.Value());
        Observer.Observe('row', Schedule."No.".Value());
        Observer.Observe('OtherA', Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA."Group Code".Value());
        Observer.Observe('OtherB', Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB."Group Code".Value());
        Observer.Observe('Resources', Schedule.Resources."No.".Value() + '|' + Schedule.Resources."Group Code".Value());
        Observer.Observe('Details', Schedule.Details."No.".Value() + '|' + Schedule.Details."Group Code".Value());
        Schedule.Close();
        Setting.Get();
        Observer.Observe('stored', Setting."Resource No.");
        Observer.Expect('resource no', 'R2');
        Observer.Expect('current no', 'R1');
        Observer.Expect('row', 'R1');
        Observer.Expect('OtherA', 'R1|G1');
        Observer.Expect('OtherB', 'R1|G1');
        Observer.Expect('Resources', 'R1|G1');
        Observer.Expect('Details', 'R1|G1');
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


    local procedure SnapABL(var Schedule: TestPage "LT R6806 AB L Sched"): Text
    begin
        exit(Schedule.ResourceNo.Value() + '|' + Schedule.HeaderCurrent.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.CurrentNo.Value() + '|' + Schedule.HostFn.Value() + '|' + Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value() + '|' + Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
    end;

    local procedure SnapLAB(var Schedule: TestPage "LT R6806 L AB Sched"): Text
    begin
        exit(Schedule.ResourceNo.Value() + '|' + Schedule.HeaderCurrent.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.CurrentNo.Value() + '|' + Schedule.HostFn.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value() + '|' + Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value() + '|' + Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value());
    end;

    local procedure SnapALB(var Schedule: TestPage "LT R6806 A L B Sched"): Text
    begin
        exit(Schedule.ResourceNo.Value() + '|' + Schedule.HeaderCurrent.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.CurrentNo.Value() + '|' + Schedule.HostFn.Value() + '|' + Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value() + '|' + Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value());
    end;

    local procedure SnapABLK(var Schedule: TestPage "LT R6806 AB L Card Sched"): Text
    begin
        exit(Schedule.ResourceNo.Value() + '|' + Schedule.HeaderCurrent.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.CurrentNo.Value() + '|' + Schedule.HostFn.Value() + '|' + Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value() + '|' + Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value() + '|' + Schedule.Details."No.".Value() + '|' + Schedule.Details.CardCurrent.Value() + '|' + Schedule.Details.CardFn.Value());
    end;

    local procedure SnapABCL(var Schedule: TestPage "LT R6806 ABC L Sched"): Text
    begin
        exit(Schedule.ResourceNo.Value() + '|' + Schedule.HeaderCurrent.Value() + '|' + Schedule."No.".Value() + '|' + Schedule.CurrentNo.Value() + '|' + Schedule.HostFn.Value() + '|' + Schedule.OtherA."No.".Value() + '|' + Schedule.OtherA.OtherACurrent.Value() + '|' + Schedule.OtherA.OtherAFn.Value() + '|' + Schedule.OtherB."No.".Value() + '|' + Schedule.OtherB.OtherBCurrent.Value() + '|' + Schedule.OtherB.OtherBFn.Value() + '|' + Schedule.OtherC."No.".Value() + '|' + Schedule.OtherC.OtherCCurrent.Value() + '|' + Schedule.OtherC.OtherCFn.Value() + '|' + Schedule.Resources."No.".Value() + '|' + Schedule.Resources.PartCurrent.Value() + '|' + Schedule.Resources.PartFn.Value());
    end;


    [ModalPageHandler]
    procedure PickSecondResource(var ResourceList: TestPage "LT Y15 Lookup Resource List")
    begin
        ResourceList.GoToKey('R2');
        ResourceList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelLookup(var ResourceList: TestPage "LT Y15 Lookup Resource List")
    begin
        ResourceList.GoToKey('R2');
        ResourceList.Cancel().Invoke();
    end;
}
