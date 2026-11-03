// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: none
// Objects of the issue 600 probes (page, part and page extension properties); the tests are in UPageProps.al.
// Object ids 69585 to 69591, 69593 to 69595.

table 69585 "LT U Page Src"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT U Lookup List";

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30])
        {
            trigger OnValidate()
            begin
                Note := 'validated ' + Txt;
            end;
        }
        field(3; Dec; Decimal) { }
        field(4; Note; Text[30]) { }
        field(5; Rel; Integer) { TableRelation = "LT U Page Src".Id; }
        field(6; Rel2; Integer) { TableRelation = "LT U Page Src".Id; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

tableextension 69586 "LT U Page Src Ext" extends "LT U Page Src"
{
    fields
    {
        field(69586; AutoPlain; Decimal) { DataClassification = SystemMetadata; }
        field(69587; AutoCustom; Decimal)
        {
            DataClassification = SystemMetadata;
            AutoFormatType = 11;
            AutoFormatExpression = '<Precision,3:3><Standard Format,0>';
        }
        field(69588; AutoCurrency; Decimal)
        {
            DataClassification = SystemMetadata;
            AutoFormatType = 1;
            AutoFormatExpression = 'XXX';
        }
    }
}

page 69591 "LT U Lookup List"
{
    PageType = List;
    SourceTable = "LT U Page Src";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(Txt; Rec.Txt) { }
            }
        }
    }
}

page 69587 "LT U Part Page"
{
    PageType = ListPart;
    SourceTable = "LT U Page Src";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(Txt; Rec.Txt) { }
            }
        }
    }
}

page 69594 "LT U Api Page"
{
    PageType = API;
    APIPublisher = 'ltu';
    APIGroup = 'probe';
    APIVersion = 'v1.0';
    EntityName = 'ltuRow';
    EntitySetName = 'ltuRows';
    SourceTable = "LT U Page Src";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    Editable = false;
    DataAccessIntent = ReadOnly;

    layout
    {
        area(Content)
        {
            field(id; Rec.SystemId) { }
            field(txt; Rec.Txt) { }
            part(lines; "LT U Part Page")
            {
                EntityName = 'ltuLine';
                EntitySetName = 'ltuLines';
                SubPageLink = Id = field(Id);
            }
        }
    }
}

page 69595 "LT U Preview Dialog"
{
    PageType = PromptDialog;
    Extensible = false;
    IsPreview = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Prompt)
        {
            field(Question; Question) { }
        }
        area(Content)
        {
            field(Answer; Answer) { }
        }
    }

    var
        Question: Text;
        Answer: Text;
}

page 69588 "LT U Base Card"
{
    PageType = Card;
    SourceTable = "LT U Page Src";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            group(GrpVisible)
            {
                field(InVisibleGroup; Rec.Txt) { }
            }
            group(GrpEditable)
            {
                field(InEditableGroup; Rec.Note) { }
            }
            field(DecField; Rec.Dec) { DecimalPlaces = 2 : 2; }
            field(DrillOn; Rec.Txt)
            {
                DrillDown = true;

                trigger OnDrillDown()
                begin
                    Error('drilled on');
                end;
            }
            field(DrillOff; Rec.Txt)
            {
                DrillDown = false;

                trigger OnDrillDown()
                begin
                    Error('drilled off');
                end;
            }
            field(LookupField; Rec.Rel) { }
            field(EnabledField; Rec.Note) { Enabled = true; }
            field(AutoPlainField; Rec.AutoPlain) { }
            field(AutoCustomField; Rec.AutoCustom) { }
            field(AutoCurrencyField; Rec.AutoCurrency) { }
            field(AutoOnPage; Rec.AutoPlain)
            {
                AutoFormatType = 11;
                AutoFormatExpression = '<Precision,1:1><Standard Format,0>';
            }
            part(PartHost; "LT U Part Page")
            {
                UpdatePropagation = Both;
                ShowFilter = false;
                SubPageLink = Id = field(Id);
            }
            part(PartSub; "LT U Part Page")
            {
                UpdatePropagation = SubPart;
                ShowFilter = true;
                Editable = true;
                SubPageLink = Id = field(Id);
            }
            label(Lbl)
            {
                Caption = 'A label';
                Enabled = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActEnabled)
            {
                Enabled = true;

                trigger OnAction()
                begin
                end;
            }
            action(ActVisible)
            {
                Visible = true;

                trigger OnAction()
                begin
                end;
            }
            action(ActScope)
            {
                Scope = Page;

                trigger OnAction()
                begin
                end;
            }
            action(ActFooter)
            {
                InFooterBar = false;

                trigger OnAction()
                begin
                end;
            }
            action(ActRefTarget)
            {
                trigger OnAction()
                begin
                end;
            }
            customaction(CustomVisible)
            {
                CustomActionType = Flow;
                FlowId = '5c6d7e8f-1a2b-4c3d-9e0f-a1b2c3d4e5fa';
                Visible = false;
            }
            fileuploadaction(UploadEnabled)
            {
                Enabled = false;
                Scope = Page;

                trigger OnAction(Files: List of [FileUpload])
                begin
                end;
            }
        }
        area(Promoted)
        {
            actionref(ActRefTarget_Promoted; ActRefTarget) { Visible = false; }
        }
    }
}

pageextension 69589 "LT U Base Card Ext" extends "LT U Base Card"
{
    layout
    {
        modify(GrpVisible) { Visible = false; }
        modify(GrpEditable) { Editable = false; }
        modify(EnabledField) { Enabled = false; }
        modify(Lbl) { Enabled = true; }
        addlast(Content)
        {
            group(ExtGrpHidden)
            {
                Visible = false;

                field(ExtInHidden; Rec.Txt) { }
            }
            group(ExtGrpReadOnly)
            {
                Editable = false;

                field(ExtInReadOnly; Rec.Note) { }
            }
            field(ExtDec; Rec.Dec) { DecimalPlaces = 3 : 3; }
            field(ExtDrillOn; Rec.Txt)
            {
                DrillDown = true;

                trigger OnDrillDown()
                begin
                    Error('ext drilled on');
                end;
            }
            field(ExtDrillOff; Rec.Txt)
            {
                DrillDown = false;

                trigger OnDrillDown()
                begin
                    Error('ext drilled off');
                end;
            }
            field(ExtLookupOn; Rec.Rel) { Lookup = true; }
            field(ExtLookupOff; Rec.Rel) { Lookup = false; }
            field(ExtEnabledOff; Rec.Note) { Enabled = false; }
            field(ExtAutoCustom; Rec.AutoCustom) { }
            field(ExtAutoPage; Rec.AutoPlain)
            {
                AutoFormatType = 11;
                AutoFormatExpression = '<Precision,1:1><Standard Format,0>';
            }
            part(ExtPart; "LT U Part Page")
            {
                ShowFilter = false;
                Editable = false;
                SubPageLink = Id = field(Id);
            }
        }
    }

    actions
    {
        modify(ActEnabled) { Enabled = false; }
        modify(ActVisible) { Visible = false; }
        modify(ActRefTarget_Promoted) { Visible = true; }
        addlast(Processing)
        {
            action(ExtActEnabledOff)
            {
                Enabled = false;

                trigger OnAction()
                begin
                end;
            }
            action(ExtActVisibleOff)
            {
                Visible = false;

                trigger OnAction()
                begin
                end;
            }
            action(ExtActScope)
            {
                Scope = Repeater;
                InFooterBar = true;

                trigger OnAction()
                begin
                end;
            }
        }
    }
}

page 69590 "LT U Role Center"
{
    PageType = RoleCenter;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(RoleCenter)
        {
            part(Rows; "LT U Part Page") { }
        }
    }
}

profile "LT U Profile"
{
    Caption = 'LT U Profile';
    RoleCenter = "LT U Role Center";
    Enabled = true;
}

profileextension "LT U Profile Ext" extends "LT U Profile"
{
    Enabled = false;
}

pageextension 69593 "LT U Lookup List Ext" extends "LT U Lookup List"
{
    Editable = true;
    DataCaptionExpression = 'LT U ext caption';
}
