// Probe: two page extensions of one app modify the same controls (Editable, Enabled, Visible, OptionCaption) and wrap the validation of a control with OnBeforeValidate and OnAfterValidate.
// Settles: md:261 (Editable, Enabled, Visible, OptionCaption of two competing extensions; a modify block that sets RunObject does not compile (AL0246), see the manifest), md:262 (OnBeforeValidate / OnAfterValidate order with a table OnValidate and on a variable control).
// md:260 and the dependency-app half of md:261 need a second app and cannot be probed here (see the manifest).

table 68676 "W2 Ext Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "W2 Ext Log";
            begin
                Log.Add('table.Name(' + Name + ')');
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 68677 "W2 Ext Log"
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

page 68679 "W2 Ext Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Ext Row";
    SourceTableTemporary = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(RecName; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Log: Codeunit "W2 Ext Log";
                begin
                    Log.Add('page.RecName(' + Rec.Name + ')');
                end;
            }
            field(VarName; VarNameText)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Log: Codeunit "W2 Ext Log";
                begin
                    Log.Add('page.VarName(' + VarNameText + ')');
                end;
            }
            field(PlainName; PlainNameText)
            {
                ApplicationArea = All;
            }

            // Editable: A base true, low false, high true. B base false, low true, high false. C base true, low false only.
            field(EditA; EditAText) { ApplicationArea = All; Editable = true; }
            field(EditB; EditBText) { ApplicationArea = All; Editable = false; }
            field(EditC; EditCText) { ApplicationArea = All; Editable = true; }
            // Enabled
            field(EnabledA; EnabledAText) { ApplicationArea = All; Enabled = true; }
            field(EnabledB; EnabledBText) { ApplicationArea = All; Enabled = false; }
            field(EnabledC; EnabledCText) { ApplicationArea = All; Enabled = true; }
            // Visible
            field(VisibleA; VisibleAText) { ApplicationArea = All; Visible = true; }
            field(VisibleB; VisibleBText) { ApplicationArea = All; Visible = false; }
            field(VisibleC; VisibleCText) { ApplicationArea = All; Visible = true; }
            // OptionCaption: A both extensions set it, C only the low one, D none.
            field(OptionA; OptionAVar) { ApplicationArea = All; }
            field(OptionC; OptionCVar) { ApplicationArea = All; }
            field(OptionD; OptionDVar) { ApplicationArea = All; OptionCaption = 'Base1,Base2,Base3'; }
        }
    }

    protected var
        VarNameText: Text;
        PlainNameText: Text;
        EditAText: Text;
        EditBText: Text;
        EditCText: Text;
        EnabledAText: Text;
        EnabledBText: Text;
        EnabledCText: Text;
        VisibleAText: Text;
        VisibleBText: Text;
        VisibleCText: Text;
        OptionAVar: Option First,Second,Third;
        OptionCVar: Option First,Second,Third;
        OptionDVar: Option First,Second,Third;
}

pageextension 68680 "W2 Ext Card Low" extends "W2 Ext Card"
{
    layout
    {
        modify(EditA) { Editable = false; }
        modify(EditB) { Editable = true; }
        modify(EditC) { Editable = false; }
        modify(EnabledA) { Enabled = false; }
        modify(EnabledB) { Enabled = true; }
        modify(EnabledC) { Enabled = false; }
        modify(VisibleA) { Visible = false; }
        modify(VisibleB) { Visible = true; }
        modify(VisibleC) { Visible = false; }
        modify(OptionA) { OptionCaption = 'LowA1,LowA2,LowA3'; }
        modify(OptionC) { OptionCaption = 'LowC1,LowC2,LowC3'; }
        modify(RecName)
        {
            trigger OnBeforeValidate()
            var
                Log: Codeunit "W2 Ext Log";
            begin
                Log.Add('low.before.RecName(' + Rec.Name + ')');
            end;

            trigger OnAfterValidate()
            var
                Log: Codeunit "W2 Ext Log";
            begin
                Log.Add('low.after.RecName(' + Rec.Name + ')');
            end;
        }
        modify(VarName)
        {
            trigger OnBeforeValidate()
            var
                Log: Codeunit "W2 Ext Log";
            begin
                Log.Add('low.before.VarName(' + VarNameText + ')');
            end;

            trigger OnAfterValidate()
            var
                Log: Codeunit "W2 Ext Log";
            begin
                Log.Add('low.after.VarName(' + VarNameText + ')');
            end;
        }
        modify(PlainName)
        {
            trigger OnBeforeValidate()
            var
                Log: Codeunit "W2 Ext Log";
            begin
                Log.Add('low.before.PlainName(' + PlainNameText + ')');
            end;

            trigger OnAfterValidate()
            var
                Log: Codeunit "W2 Ext Log";
            begin
                Log.Add('low.after.PlainName(' + PlainNameText + ')');
            end;
        }
    }
}

pageextension 68681 "W2 Ext Card High" extends "W2 Ext Card"
{
    layout
    {
        modify(EditA) { Editable = true; }
        modify(EditB) { Editable = false; }
        modify(EnabledA) { Enabled = true; }
        modify(EnabledB) { Enabled = false; }
        modify(VisibleA) { Visible = true; }
        modify(VisibleB) { Visible = false; }
        modify(OptionA) { OptionCaption = 'HighA1,HighA2,HighA3'; }
        modify(RecName)
        {
            trigger OnBeforeValidate()
            var
                Log: Codeunit "W2 Ext Log";
            begin
                Log.Add('high.before.RecName(' + Rec.Name + ')');
            end;

            trigger OnAfterValidate()
            var
                Log: Codeunit "W2 Ext Log";
            begin
                Log.Add('high.after.RecName(' + Rec.Name + ')');
            end;
        }
        modify(VarName)
        {
            trigger OnBeforeValidate()
            var
                Log: Codeunit "W2 Ext Log";
            begin
                Log.Add('high.before.VarName(' + VarNameText + ')');
            end;

            trigger OnAfterValidate()
            var
                Log: Codeunit "W2 Ext Log";
            begin
                Log.Add('high.after.VarName(' + VarNameText + ')');
            end;
        }
        modify(PlainName)
        {
            trigger OnBeforeValidate()
            var
                Log: Codeunit "W2 Ext Log";
            begin
                Log.Add('high.before.PlainName(' + PlainNameText + ')');
            end;

            trigger OnAfterValidate()
            var
                Log: Codeunit "W2 Ext Log";
            begin
                Log.Add('high.after.PlainName(' + PlainNameText + ')');
            end;
        }
    }
}

codeunit 68678 "W2 Ext Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // ---- md:261 ----

    [Test]
    procedure TwoExtensions_EditableAndEnabled()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Ext Card";
    begin
        Pg.OpenEdit();
        Observer.Observe('editable_A_low_false_high_true', Format(Pg.EditA.Editable()));
        Observer.Observe('editable_B_low_true_high_false', Format(Pg.EditB.Editable()));
        Observer.Observe('editable_C_low_false_only', Format(Pg.EditC.Editable()));
        Observer.Observe('enabled_A_low_false_high_true', Format(Pg.EnabledA.Enabled()));
        Observer.Observe('enabled_B_low_true_high_false', Format(Pg.EnabledB.Enabled()));
        Observer.Observe('enabled_C_low_false_only', Format(Pg.EnabledC.Enabled()));
        Pg.Close();
        Observer.Expect('editable_A_low_false_high_true', 'Yes');
        Observer.Expect('editable_B_low_true_high_false', 'No');
        Observer.Expect('editable_C_low_false_only', 'No');
        Observer.Expect('enabled_A_low_false_high_true', 'Yes');
        Observer.Expect('enabled_B_low_true_high_false', 'No');
        Observer.Expect('enabled_C_low_false_only', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TwoExtensions_Visible()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Ext Card";
        Seen: Boolean;
        Ok: Boolean;
    begin
        Pg.OpenEdit();
        Ok := VisibleOfA(Pg, Seen);
        Observer.Observe('visible_A_low_false_high_true|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('visible_A')
        else
            Observer.Observe('visible_A_low_false_high_true', Format(Seen));
        Ok := VisibleOfB(Pg, Seen);
        Observer.Observe('visible_B_low_true_high_false|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('visible_B')
        else
            Observer.Observe('visible_B_low_true_high_false', Format(Seen));
        Ok := VisibleOfC(Pg, Seen);
        Observer.Observe('visible_C_low_false_only|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('visible_C')
        else
            Observer.Observe('visible_C_low_false_only', Format(Seen));
        Pg.Close();
        Observer.Expect('visible_A_low_false_high_true|ok', 'Yes');
        Observer.Expect('visible_A_low_false_high_true', 'Yes');
        Observer.Expect('visible_B_low_true_high_false|ok', 'No');
        Observer.Expect('visible_B|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('visible_B|code', 'TestFieldNotFound');
        Observer.Expect('visible_C_low_false_only|ok', 'No');
        Observer.Expect('visible_C|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('visible_C|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure TwoExtensions_OptionCaption()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Ext Card";
        Ok: Boolean;
    begin
        Pg.OpenEdit();
        Observer.Observe('A_both_extensions|initial', Pg.OptionA.Value());
        Observer.Observe('C_low_only|initial', Pg.OptionC.Value());
        Observer.Observe('D_none|initial', Pg.OptionD.Value());
        Ok := SetOptionA(Pg, 'HighA2');
        Observer.Observe('A_set_high_caption|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('A_set_high_caption');
        Observer.Observe('A_set_high_caption|value', Pg.OptionA.Value());
        Ok := SetOptionA(Pg, 'LowA3');
        Observer.Observe('A_set_low_caption|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('A_set_low_caption');
        Observer.Observe('A_set_low_caption|value', Pg.OptionA.Value());
        Ok := SetOptionC(Pg, 'LowC2');
        Observer.Observe('C_set_low_caption|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('C_set_low_caption');
        Observer.Observe('C_set_low_caption|value', Pg.OptionC.Value());
        Pg.Close();
        Observer.Expect('A_both_extensions|initial', 'HighA1');
        Observer.Expect('C_low_only|initial', 'LowC1');
        Observer.Expect('D_none|initial', 'Base1');
        Observer.Expect('A_set_high_caption|ok', 'Yes');
        Observer.Expect('A_set_high_caption|value', 'HighA2');
        Observer.Expect('A_set_low_caption|ok', 'No');
        Observer.Expect('A_set_low_caption|text', 'Validation error for Field: OptionA,  Message = ''Your entry of ''LowA3'' is not an acceptable value for ''OptionA''.''');
        Observer.Expect('A_set_low_caption|code', 'TestValidation');
        Observer.Expect('A_set_low_caption|value', '1');
        Observer.Expect('C_set_low_caption|ok', 'Yes');
        Observer.Expect('C_set_low_caption|value', 'LowC2');
        Observer.Verify();
    end;

    // ---- md:262 ----

    [Test]
    procedure Validate_VariableControl()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Ext Log";
        Pg: TestPage "W2 Ext Card";
    begin
        Pg.OpenEdit();
        Log.Take();
        Pg.VarName.SetValue('first');
        Observer.Observe('set_first', Log.Take());
        Pg.VarName.SetValue('second');
        Observer.Observe('set_second', Log.Take());
        Pg.Close();
        Observer.Expect('set_first', 'low.before.VarName(first);high.before.VarName(first);page.VarName(first);low.after.VarName(first);high.after.VarName(first);');
        Observer.Expect('set_second', 'low.before.VarName(second);high.before.VarName(second);page.VarName(second);low.after.VarName(second);high.after.VarName(second);');
        Observer.Verify();
    end;

    // The control has no OnValidate of its own: only the two modify blocks run.
    [Test]
    procedure Validate_VariableControlWithoutOwnTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Ext Log";
        Pg: TestPage "W2 Ext Card";
    begin
        Pg.OpenEdit();
        Log.Take();
        Pg.PlainName.SetValue('first');
        Observer.Observe('set_first', Log.Take());
        Pg.Close();
        Observer.Expect('set_first', 'low.before.PlainName(first);high.before.PlainName(first);low.after.PlainName(first);high.after.PlainName(first);');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure VisibleOfA(var Pg: TestPage "W2 Ext Card"; var Result: Boolean)
    begin
        Result := Pg.VisibleA.Visible();
    end;

    [TryFunction]
    local procedure VisibleOfB(var Pg: TestPage "W2 Ext Card"; var Result: Boolean)
    begin
        Result := Pg.VisibleB.Visible();
    end;

    [TryFunction]
    local procedure VisibleOfC(var Pg: TestPage "W2 Ext Card"; var Result: Boolean)
    begin
        Result := Pg.VisibleC.Visible();
    end;

    [TryFunction]
    local procedure SetOptionA(var Pg: TestPage "W2 Ext Card"; Input: Text)
    begin
        Pg.OptionA.SetValue(Input);
    end;

    [TryFunction]
    local procedure SetOptionC(var Pg: TestPage "W2 Ext Card"; Input: Text)
    begin
        Pg.OptionC.SetValue(Input);
    end;

    // ---- Added by writer bs (corpus issue #668, items 105 and 107): page 83161 and pageextension 83161 in
    //      tableextension/lt-bs-tableext-leads/BsObjects.al ----

    [Test]
    procedure PageExt_GlobalWithBasePageGlobalName_UsedInVisible()
    // CLAIM (issue #668 item 107): the base page uses its global X in Visible of control Id; the page extension declares its own global X,
    // sets it to true in OnOpenPage and uses it in Visible of its control BsExtA. It compiles; at run time is each Visible bound to its
    // own X?
    var
        Observer: Codeunit "Probe Observer";
        Base: Record "LT BS Base";
        Card: TestPage "LT BS Card";
    begin
        Base.DeleteAll();
        Base.Id := 1;
        Base.Insert();
        Card.OpenView();
        Observer.Observe('base_control_visible', Format(Card.Id.Visible()));
        Observer.Observe('extension_control_visible', Format(Card.BsExtA.Visible()));
        Card.Close();
        Base.DeleteAll();
        Observer.Expect('base_control_visible', 'No');
        Observer.Expect('extension_control_visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure PageExt_ProtectedLabelVariable_Readable()
    // CLAIM (issue #668 item 105): a page extension declares `protected var BsProtectedTxt: Label 'LT BS protected label';`. It compiles
    // and publishes(?); a procedure of the extension, called on a Page variable, returns the label text.
    var
        Observer: Codeunit "Probe Observer";
        Card: Page "LT BS Card";
    begin
        Observer.Observe('protected_label', Card.BsGetProtectedLabel());
        Observer.Expect('protected_label', 'LT BS protected label');
        Observer.Verify();
    end;
}
