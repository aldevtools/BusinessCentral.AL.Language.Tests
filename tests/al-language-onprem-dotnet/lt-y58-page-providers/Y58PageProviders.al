// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained table 61462, pages 61462-61465,
//   codeunits 61462, 61463
// Probe: the server classes behind the System Application "Page Summary Provider" and "Page Action Provider", called directly:
//   - Microsoft.Dynamics.Nav.Runtime.PageSummary.NavPageSummaryALFunctions: GetSummaryFields(PageId) (field numbers of the
//     Brick field group, in order), GetAvailableTableFields(PageId) (the table fields behind the page's visible controls), and
//     GetSummary(PageId, Bookmark, FieldList): Success, and per field Caption, FieldType, Value.ToString(), Tooltip, ExtendedType.
//   - Microsoft.Dynamics.Nav.Runtime.NavPageActionALFunctions.GetActions(PageId): Success, ErrorMessage, and per action
//     ActionType, ActionSubtype, Caption, RunObjectType, RunObjectId, RunObjectView, RunObjectViewFilter and the parent action
//     (by caption; generated action ids are not asserted).
// Facts: GetSummaryFields returns the Brick fields with the first two swapped, Blob fields included; GetAvailableTableFields
//   returns the fields of the visible controls in page order (an empty list for a page without fields); FieldType.ToString() is the
//   AL type name (BLOB for a Blob, value '*'); a control without ToolTip gives ''; an invalid bookmark or a deleted record gives
//   Success = false without an error; GetActions of an unknown page gives Success = false and a "metadata object ... was not found" text.
// Expected values: corpus CI (Linux containers) BC 27.5, 28.5 and 29.0, batch runs 41332956805, 41336116625, 41336138376.
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.Ncl")
    {
        type("Microsoft.Dynamics.Nav.Runtime.PageSummary.NavPageSummaryALFunctions"; LtY58SummaryFunctions) { }
        type("Microsoft.Dynamics.Nav.Runtime.PageSummary.NavPageSummaryALResponse"; LtY58SummaryResponse) { }
        type("Microsoft.Dynamics.Nav.Runtime.PageSummary.NavPageSummaryALField"; LtY58SummaryField) { }
        type("Microsoft.Dynamics.Nav.Runtime.NavPageActionALFunctions"; LtY58ActionFunctions) { }
        type("Microsoft.Dynamics.Nav.Runtime.NavPageActionALResponse"; LtY58ActionResponse) { }
    }
    assembly("Microsoft.Dynamics.Nav.Types")
    {
        type("Microsoft.Dynamics.Nav.Types.Metadata.NavPageActionAL"; LtY58PageActionAL) { }
    }
}

table 61462 "LT Y58 Provider Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { Caption = 'No.'; }
        field(2; Description; Text[50]) { Caption = 'Description'; }
        field(3; Amount; Decimal) { Caption = 'Amount'; }
        field(4; "Posting Date"; Date) { Caption = 'Posting Date'; }
        field(5; Blocked; Boolean) { Caption = 'Blocked'; }
        field(6; Notes; Blob) { Caption = 'Notes'; }
        field(7; Hidden; Text[30]) { Caption = 'Hidden'; }
        field(8; Kind; Option) { Caption = 'Kind'; OptionMembers = " ",Small,Large; }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
    fieldgroups
    {
        fieldgroup(Brick; Description, "No.", Amount, Notes, "Posting Date") { }
    }
}

page 61462 "LT Y58 Provider Role Center"
{
    Caption = 'LT Y58 Role Center';
    PageType = RoleCenter;
    ApplicationArea = All;

    actions
    {
        area(Embedding)
        {
            action(ListWithViews)
            {
                ApplicationArea = All;
                Caption = 'List with views';
                RunObject = page "LT Y58 Provider List";
                ToolTip = 'Opens the list.';
            }
            action(EmptyCard)
            {
                ApplicationArea = All;
                Caption = 'Empty card';
                RunObject = page "LT Y58 Provider Empty Card";
                ToolTip = 'Opens the empty card.';
            }
            action(ReportItem)
            {
                ApplicationArea = All;
                Caption = 'A codeunit item';
                RunObject = codeunit "LT Y58 Page Providers";
                ToolTip = 'Runs a codeunit.';
            }
        }
        area(Processing)
        {
            action(ProcessingItem)
            {
                ApplicationArea = All;
                Caption = 'Processing item';
                RunObject = page "LT Y58 Provider List";
                ToolTip = 'Opens the list.';
            }
        }
    }
}

page 61463 "LT Y58 Provider List"
{
    Caption = 'LT Y58 Provider List';
    PageType = List;
    SourceTable = "LT Y58 Provider Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    CardPageId = "LT Y58 Provider Card";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ToolTip = 'Specifies the number.'; }
                field(Blocked; Rec.Blocked) { ToolTip = 'Specifies if blocked.'; }
            }
        }
    }
    views
    {
        view(BlockedRows)
        {
            Caption = 'Blocked rows';
            Filters = where(Blocked = const(true));
        }
        view(BigAmounts)
        {
            Caption = 'Big amounts';
            Filters = where(Amount = filter(> 100));
        }
    }
}

page 61464 "LT Y58 Provider Empty Card"
{
    Caption = 'LT Y58 Provider Empty Card';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
}

page 61465 "LT Y58 Provider Card"
{
    Caption = 'LT Y58 Provider Card';
    PageType = Card;
    SourceTable = "LT Y58 Provider Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ToolTip = 'Specifies the number.'; }
            field(Description; Rec.Description) { ToolTip = 'Specifies the description.'; }
            field(Amount; Rec.Amount) { }
            field(Blocked; Rec.Blocked) { ToolTip = 'Specifies if blocked.'; }
            field(Kind; Rec.Kind) { ToolTip = 'Specifies the kind.'; }
            field(Hidden; Rec.Hidden) { Visible = false; ToolTip = 'Specifies a hidden value.'; }
        }
    }
}

codeunit 61462 "LT Y58 Page Providers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SummaryFunctions: DotNet LtY58SummaryFunctions;

    local procedure InsertRow(var Row: Record "LT Y58 Provider Row")
    var
        OutS: OutStream;
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'P-1';
        Row.Description := 'Provider row';
        Row.Amount := 1234.5;
        Row."Posting Date" := DMY2Date(15, 1, 2024);
        Row.Blocked := true;
        Row.Kind := Row.Kind::Small;
        Row.Hidden := 'hidden';
        Row.Notes.CreateOutStream(OutS);
        OutS.WriteText('blob text');
        Row.Insert();
    end;

    local procedure ListText(PageId: Integer; Available: Boolean): Text
    var
        FieldNo: Integer;
        Result: Text;
    begin
        if Available then begin
            if IsNull(SummaryFunctions.GetAvailableTableFields(PageId)) then
                exit('null');
            foreach FieldNo in SummaryFunctions.GetAvailableTableFields(PageId) do
                Result += Format(FieldNo) + ',';
        end else begin
            if IsNull(SummaryFunctions.GetSummaryFields(PageId)) then
                exit('null');
            foreach FieldNo in SummaryFunctions.GetSummaryFields(PageId) do
                Result += Format(FieldNo) + ',';
        end;
        exit(Result);
    end;

    local procedure SummaryText(PageId: Integer; Bookmark: Text; Available: Boolean): Text
    var
        Response: DotNet LtY58SummaryResponse;
        SummaryField: DotNet LtY58SummaryField;
        Result: Text;
    begin
        if Available then
            Response := SummaryFunctions.GetSummary(PageId, Bookmark, SummaryFunctions.GetAvailableTableFields(PageId))
        else
            Response := SummaryFunctions.GetSummary(PageId, Bookmark, SummaryFunctions.GetSummaryFields(PageId));
        Result := 'success=' + Format(Response.Success) + ';';
        if not IsNull(Response.SummaryFields) then
            foreach SummaryField in Response.SummaryFields do
                Result += Format(SummaryField.Caption) + '|' + SummaryField.FieldType.ToString() + '|' + Format(SummaryField.FieldType) + '|' +
                    SummaryField.Value.ToString() + '|' + Format(SummaryField.Tooltip) + '|' + SummaryField.ExtendedType.ToString() + ';';
        exit(Result);
    end;

    [TryFunction]
    local procedure TrySummary(PageId: Integer; Bookmark: Text; Available: Boolean; var Result: Text)
    begin
        Result := SummaryText(PageId, Bookmark, Available);
    end;

    [Test]
    procedure PageSummaryFunctions_FieldLists()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('summary fields of card', ListText(Page::"LT Y58 Provider Card", false));
        Observer.Observe('summary fields of list', ListText(Page::"LT Y58 Provider List", false));
        Observer.Observe('summary fields of empty card', ListText(Page::"LT Y58 Provider Empty Card", false));
        Observer.Observe('available fields of card', ListText(Page::"LT Y58 Provider Card", true));
        Observer.Observe('available fields of list', ListText(Page::"LT Y58 Provider List", true));
        Observer.Observe('available fields of empty card', ListText(Page::"LT Y58 Provider Empty Card", true));
        Observer.Expect('summary fields of card', '2,1,3,6,4,');
        Observer.Expect('summary fields of list', '2,1,3,6,4,');
        Observer.Expect('summary fields of empty card', '');
        Observer.Expect('available fields of card', '1,2,3,5,8,');
        Observer.Expect('available fields of list', '1,5,');
        Observer.Expect('available fields of empty card', '');
        Observer.Verify();
    end;

    [Test]
    procedure PageSummaryFunctions_GetSummary()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y58 Provider Row";
        Result: Text;
    begin
        InsertRow(Row);
        if TrySummary(Page::"LT Y58 Provider Card", Format(Row.RecordId, 0, 10), false, Result) then
            Observer.Observe('card brick summary', Result)
        else
            Observer.ObserveError('card brick summary');
        if TrySummary(Page::"LT Y58 Provider Card", Format(Row.RecordId, 0, 10), true, Result) then
            Observer.Observe('card available summary', Result)
        else
            Observer.ObserveError('card available summary');
        Observer.Expect('card brick summary', 'success=Yes;Description|Text|Text|Provider row|Specifies the description.|Undefined;No.|Code|Code|P-1|Specifies the number.|Undefined;Amount|Decimal|Decimal|1,234.5||Undefined;Notes|BLOB|BLOB|*||Undefined;Posting Date|Date|Date|01/15/24||Undefined;');
        Observer.Expect('card available summary', 'success=Yes;No.|Code|Code|P-1|Specifies the number.|Undefined;Description|Text|Text|Provider row|Specifies the description.|Undefined;Amount|Decimal|Decimal|1,234.5||Undefined;Blocked|Boolean|Boolean|Yes|Specifies if blocked.|Undefined;Kind|Option|Option|Small|Specifies the kind.|Undefined;');
        Observer.Verify();
    end;

    [Test]
    procedure PageSummaryFunctions_BadBookmark()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y58 Provider Row";
        Bookmark: Text;
        Result: Text;
    begin
        InsertRow(Row);
        if TrySummary(Page::"LT Y58 Provider Card", 'not a bookmark', false, Result) then
            Observer.Observe('invalid bookmark', Result)
        else
            Observer.ObserveError('invalid bookmark');
        Bookmark := Format(Row.RecordId, 0, 10);
        Row.Delete();
        if TrySummary(Page::"LT Y58 Provider Card", Bookmark, false, Result) then
            Observer.Observe('deleted record', Result)
        else
            Observer.ObserveError('deleted record');
        Observer.Expect('invalid bookmark', 'success=No;');
        Observer.Expect('deleted record', 'success=No;');
        Observer.Verify();
    end;
}

codeunit 61463 "LT Y58 Page Action Functions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ActionFunctions: DotNet LtY58ActionFunctions;

    local procedure ActionsText(PageId: Integer): Text
    var
        Response: DotNet LtY58ActionResponse;
        PageAction: DotNet LtY58PageActionAL;
        Parent: DotNet LtY58PageActionAL;
        Ids: List of [Integer];
        Captions: List of [Text];
        ParentCaption: Text;
        Result: Text;
    begin
        Response := ActionFunctions.GetActions(PageId);
        Result := 'success=' + Format(Response.Success) + ';error=' + Format(Response.ErrorMessage) + ';';
        if IsNull(Response.PageActions) then
            exit(Result + 'actions=null');
        foreach PageAction in Response.PageActions do begin
            Ids.Add(PageAction.ActionId);
            Captions.Add(CaptionOf(PageAction));
        end;
        foreach PageAction in Response.PageActions do begin
            ParentCaption := 'none';
            if Ids.Contains(PageAction.ParentActionId) then
                ParentCaption := Captions.Get(Ids.IndexOf(PageAction.ParentActionId))
            else
                if PageAction.ParentActionId <> 0 then
                    ParentCaption := 'unknown';
            Result += StrSubstNo('[%1/%2/%3/%4/%5/%6/%7/parent:%8]', PageAction.ActionType, PageAction.ActionSubtype, CaptionOf(PageAction),
                PageAction.RunObjectType, PageAction.RunObjectId, Format(PageAction.RunObjectView), Format(PageAction.RunObjectViewFilter), ParentCaption);
        end;
        exit(Result);
    end;

    local procedure CaptionOf(PageAction: DotNet LtY58PageActionAL): Text
    begin
        if IsNull(PageAction.Caption) then
            exit('(null caption)');
        exit(PageAction.Caption.ToString());
    end;

    [TryFunction]
    local procedure TryActions(PageId: Integer; var Result: Text)
    begin
        Result := ActionsText(PageId);
    end;

    local procedure ObserveActions(Observer: Codeunit "Probe Observer"; Name: Text; PageId: Integer)
    var
        Result: Text;
    begin
        if TryActions(PageId, Result) then
            Observer.Observe(Name, Result)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure PageActionFunctions_RoleCenter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveActions(Observer, 'role center', Page::"LT Y58 Provider Role Center");
        Observer.Finish();
    end;

    [Test]
    procedure PageActionFunctions_ListViews()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveActions(Observer, 'list with views', Page::"LT Y58 Provider List");
        Observer.Finish();
    end;

    [Test]
    procedure PageActionFunctions_EmptyAndUnknown()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveActions(Observer, 'empty card', Page::"LT Y58 Provider Empty Card");
        ObserveActions(Observer, 'unknown page', 99999999);
        ObserveActions(Observer, 'page 0', 0);
        Observer.Finish();
    end;
}
