//sub:pages
// Gap cycle 4, spec G4-08: a page control's CaptionClass expression whose text changes after an action (with and without
// CurrPage.Update), after a refill of a temporary Worksheet by an action (the Item Tracing shape), on a row move (an
// expression over Rec), when the action sets the same text again, and for an area-3 text. The open and SetValue cases are
// pinned in misc/W2CaptionClass.al. The subscriber is bound manually and logs every OnResolveCaptionClass call for an
// area that starts with Y42 or is 3; it resolves area Y42R to 'resolved:<expr>'.

table 92822 "LT Y42 Cc Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 92826 "LT Y42 Cc Subscriber"
{
    EventSubscriberInstance = Manual;

    var
        Calls: Text;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Calls;
        Calls := '';
        exit(Result);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', true, true)]
    local procedure OnResolve(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        if not (CaptionArea.StartsWith('Y42') or (CaptionArea = '3')) then
            exit;
        Calls += 'resolve(' + CaptionArea + '|' + CaptionExpr + ');';
        if CaptionArea = 'Y42R' then begin
            Caption := 'resolved:' + CaptionExpr;
            Resolved := true;
        end;
    end;
}

page 92826 "LT Y42 Cc List"
{
    PageType = List;
    SourceTable = "LT Y42 Cc Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Head)
            {
                ShowCaption = false;
                label(Lbl)
                {
                    ApplicationArea = All;
                    CaptionClass = Format(CapText);
                    ShowCaption = false;
                }
                field(CapFld; Rec.Name)
                {
                    ApplicationArea = All;
                    CaptionClass = CapText;
                }
            }
            repeater(Lines)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(RowCap; Rec.Name)
                {
                    ApplicationArea = All;
                    CaptionClass = 'Y42R,row ' + Format(Rec.Id);
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetUpd)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CapText := 'Y42R,action';
                    CurrPage.Update(false);
                end;
            }
            action(SetNoUpd)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CapText := 'Y42R,noupd';
                end;
            }
            action(Same)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CapText := CapText;
                    CurrPage.Update(false);
                end;
            }
            action(Area3)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CapText := '3,area three';
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        CapText: Text;

    trigger OnOpenPage()
    begin
        CapText := 'Y42R,start';
    end;
}

// The Item Tracing shape: a Worksheet over a temporary table that an action refills, then CurrPage.Update(false).
page 92827 "LT Y42 Cc Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT Y42 Cc Row";
    SourceTableTemporary = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Head)
            {
                ShowCaption = false;
                label(Lbl)
                {
                    ApplicationArea = All;
                    CaptionClass = Format(CapText);
                    ShowCaption = false;
                }
                field(CapFld; Rec.Name)
                {
                    ApplicationArea = All;
                    CaptionClass = CapText;
                }
            }
            repeater(Lines)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Trace)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    I: Integer;
                begin
                    Traced += 1;
                    Rec.DeleteAll();
                    for I := 1 to 2 do begin
                        Rec.Init();
                        Rec.Id := Traced * 10 + I;
                        Rec.Name := 'row ' + Format(Rec.Id);
                        Rec.Insert();
                    end;
                    CapText := 'Y42R,traced ' + Format(Traced);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        CapText: Text;
        Traced: Integer;

    trigger OnOpenPage()
    begin
        CapText := 'Y42R,start';
    end;
}

codeunit 92827 "LT Y42 Cc Refill"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        S: Codeunit "LT Y42 Cc Subscriber";
        Bound: Boolean;

    local procedure Seed()
    var
        Row: Record "LT Y42 Cc Row";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to 3 do begin
            Row.Id := I;
            Row.Name := 'n' + Format(I);
            Row.Insert();
        end;
        if not Bound then
            Bound := BindSubscription(S);
        S.Take();
    end;

    // Step 1: the action changes the variable and calls CurrPage.Update(false).
    [Test]
    procedure Cc8_Action_Update()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y42 Cc List";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('events open', S.Take());
        Observer.Observe('caption open', TP.CapFld.Caption());
        Observer.Observe('events caption open', S.Take());
        TP.SetUpd.Invoke();
        Observer.Observe('events action', S.Take());
        Observer.Observe('caption action', TP.CapFld.Caption());
        Observer.Observe('events caption action', S.Take());
        TP.Close();
        Observer.Observe('events close', S.Take());
        Observer.Finish();
    end;

    // Step 2: the action changes the variable without CurrPage.Update, then a row move.
    [Test]
    procedure Cc8_Action_NoUpdate()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y42 Cc List";
    begin
        Seed();
        TP.OpenEdit();
        S.Take();
        TP.SetNoUpd.Invoke();
        Observer.Observe('events action', S.Take());
        Observer.Observe('caption action', TP.CapFld.Caption());
        Observer.Observe('events caption action', S.Take());
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('events next', S.Take());
        Observer.Observe('caption next', TP.CapFld.Caption());
        Observer.Observe('events caption next', S.Take());
        TP.Close();
        Observer.Finish();
    end;

    // Step 3: a Worksheet over a temporary table refilled by an action (the Item Tracing shape), twice.
    [Test]
    procedure Cc8_TempWorksheet_Trace()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y42 Cc Worksheet";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('events open', S.Take());
        TP.Trace.Invoke();
        Observer.Observe('events trace1', S.Take());
        Observer.Observe('caption trace1', TP.CapFld.Caption());
        Observer.Observe('events caption trace1', S.Take());
        Observer.Observe('first id trace1', TP.Id.Value());
        TP.Trace.Invoke();
        Observer.Observe('events trace2', S.Take());
        Observer.Observe('caption trace2', TP.CapFld.Caption());
        Observer.Observe('events caption trace2', S.Take());
        TP.Close();
        Observer.Finish();
    end;

    // Step 4: an expression over Rec on a row move.
    [Test]
    procedure Cc8_RowExpr_Next()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y42 Cc List";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('events open', S.Take());
        Observer.Observe('rowcap open', TP.RowCap.Caption());
        Observer.Observe('events rowcap open', S.Take());
        TP.Next();
        Observer.Observe('events next', S.Take());
        Observer.Observe('rowcap next', TP.RowCap.Caption());
        Observer.Observe('events rowcap next', S.Take());
        TP.Previous();
        Observer.Observe('events previous', S.Take());
        Observer.Observe('rowcap previous', TP.RowCap.Caption());
        Observer.Observe('events rowcap previous', S.Take());
        TP.Close();
        Observer.Finish();
    end;

    // Step 5: the action sets the same text again and calls CurrPage.Update(false).
    [Test]
    procedure Cc8_SameText_Action()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y42 Cc List";
    begin
        Seed();
        TP.OpenEdit();
        S.Take();
        TP.Same.Invoke();
        Observer.Observe('events same', S.Take());
        Observer.Observe('caption same', TP.CapFld.Caption());
        Observer.Observe('events caption same', S.Take());
        TP.Close();
        Observer.Finish();
    end;

    // Step 6: the action changes the text to an area-3 text.
    [Test]
    procedure Cc8_Area3_Action()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y42 Cc List";
    begin
        Seed();
        TP.OpenEdit();
        S.Take();
        TP.Area3.Invoke();
        Observer.Observe('events area3', S.Take());
        Observer.Observe('caption area3', TP.CapFld.Caption());
        Observer.Observe('events caption area3', S.Take());
        TP.Close();
        Observer.Finish();
    end;
}
