// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-valuesallowed-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 92651 - 92657
// Probe: gap cycle 3 spec C3-15. TestField.SetValue on a page control with ValuesAllowed in shapes the corpus did not pin yet (the card over a
//   Rec enum field is pageext/lt-page-ext-properties/PageFieldValuesAllowed.al, a request page Integer variable is
//   pages/lt-report-page-properties/05-requestpage-valuesallowed.al): a ConfirmationDialog control over an enum field of a global record
//   variable, an Option page variable, request page controls over Enum variables (member names, and a list that mixes an ordinal with names),
//   a repeater control of a List. SetValue with an Enum value, with an Integer, with a text. Every literal asserted below is what the BC
//   service tier produced.
// Facts: the control's Value after an allowed SetValue, the error text and code of a value outside the list, the Value after that error,
//   whether the control's OnValidate ran, and what the page or request page holds afterwards.
// BC versions: 27, 28, 29

enum 92651 "LT Y37 VA Status"
{
    Extensible = false;
    value(0; Simulated) { }
    value(1; Planned) { }
    value(2; "Firm Planned") { }
    value(3; Released) { }
    value(4; Finished) { }
}

enum 92652 "LT Y37 VA Stock"
{
    Extensible = false;
    value(0; " ") { }
    value(1; "Full and Partial") { }
    value(2; Full) { }
    value(3; None) { }
    value(4; Partial) { }
}

table 92653 "LT Y37 VA Order"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Status; Enum "LT Y37 VA Status") { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 92654 "LT Y37 VA Dialog"
{
    PageType = ConfirmationDialog;
    Caption = 'Y37 Change Status';
    DataCaptionExpression = '';
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NewStatus; Ord.Status)
            {
                ApplicationArea = All;
                ValuesAllowed = "Firm Planned", Released, Finished;

                trigger OnValidate()
                begin
                    ValidateLog += 'status:' + Format(Ord.Status) + ';';
                end;
            }
            field(OptCtl; OptVar)
            {
                ApplicationArea = All;
                ValuesAllowed = B, C;

                trigger OnValidate()
                begin
                    ValidateLog += 'opt:' + Format(OptVar) + ';';
                end;
            }
        }
    }

    var
        Ord: Record "LT Y37 VA Order";
        OptVar: Option A,B,C;
        ValidateLog: Text;

    procedure Set(NewOrd: Record "LT Y37 VA Order")
    begin
        Ord := NewOrd;
        OptVar := OptVar::B;
    end;

    procedure Result(): Text
    begin
        exit(Format(Ord.Status) + '|' + Format(OptVar) + '|' + ValidateLog);
    end;
}

report 92655 "LT Y37 VA Report"
{
    ProcessingOnly = true;
    UseRequestPage = true;

    dataset
    {
        dataitem(Ord; "LT Y37 VA Order")
        {
            UseTemporary = true;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ReservedFromStock; StockVar)
                {
                    ApplicationArea = All;
                    ValuesAllowed = " ", "Full and Partial", Full;
                }
                field(MixedStock; MixedVar)
                {
                    ApplicationArea = All;
                    ValuesAllowed = 0, None, Partial;
                }
            }
        }
    }

    var
        StockVar: Enum "LT Y37 VA Stock";
        MixedVar: Enum "LT Y37 VA Stock";
}

page 92656 "LT Y37 VA List"
{
    PageType = List;
    SourceTable = "LT Y37 VA Order";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ValuesAllowed = Planned, Released;
                }
            }
        }
    }
}

codeunit 92657 "LT Y37 VA Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [ModalPageHandler]
    procedure DialogHandler(var P: TestPage "LT Y37 VA Dialog")
    begin
        Observer.Observe('initial', P.NewStatus.Value());
        P.NewStatus.SetValue(Enum::"LT Y37 VA Status"::Finished);
        Observer.Observe('enum finished', P.NewStatus.Value());
        P.NewStatus.SetValue('Released');
        Observer.Observe('text released', P.NewStatus.Value());
        asserterror P.NewStatus.SetValue(Enum::"LT Y37 VA Status"::Planned);
        Observer.ObserveError('enum planned');
        Observer.Observe('after planned', P.NewStatus.Value());
        asserterror P.NewStatus.SetValue('Simulated');
        Observer.ObserveError('text simulated');
        P.NewStatus.SetValue(2);
        Observer.Observe('integer 2', P.NewStatus.Value());
        Observer.Observe('opt initial', P.OptCtl.Value());
        P.OptCtl.SetValue('C');
        Observer.Observe('opt c', P.OptCtl.Value());
        asserterror P.OptCtl.SetValue('A');
        Observer.ObserveError('opt a');
        Observer.Observe('opt after a', P.OptCtl.Value());
        P.Yes().Invoke();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure LT_C315_Dialog_GlobalRecordEnumField()
    var
        O: Record "LT Y37 VA Order";
        Pg: Page "LT Y37 VA Dialog";
    begin
        O."No." := 'O1';
        O.Status := O.Status::Released;
        Pg.Set(O);
        Observer.Observe('runmodal', Format(Pg.RunModal()));
        Observer.Observe('result', Pg.Result());
        Observer.Expect('initial', 'Released');
        Observer.Expect('enum finished', 'Finished');
        Observer.Expect('text released', 'Released');
        Observer.Expect('enum planned|text', 'Validation error for Field: NewStatus,  Message = ''Your entry of ''3'' is not an acceptable value for ''NewStatus''.''');
        Observer.Expect('enum planned|code', 'TestValidation');
        Observer.Expect('after planned', '3');
        Observer.Expect('text simulated|text', 'Validation error for Field: NewStatus,  Message = ''Your entry of ''Simulated'' is not an acceptable value for ''NewStatus''.''');
        Observer.Expect('text simulated|code', 'TestValidation');
        Observer.Expect('integer 2', 'Firm Planned');
        Observer.Expect('opt initial', 'B');
        Observer.Expect('opt c', 'C');
        Observer.Expect('opt a|text', 'Validation error for Field: OptCtl,  Message = ''Your entry of ''A'' is not an acceptable value for ''OptCtl''.''');
        Observer.Expect('opt a|code', 'TestValidation');
        Observer.Expect('opt after a', '2');
        Observer.Expect('runmodal', 'Cancel');
        Observer.Expect('result', 'Firm Planned|C|status:Finished;status:Released;status:Firm Planned;opt:C;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ReportHandler(var RP: TestRequestPage "LT Y37 VA Report")
    begin
        Observer.Observe('initial', RP.ReservedFromStock.Value());
        RP.ReservedFromStock.SetValue(Enum::"LT Y37 VA Stock"::Full);
        Observer.Observe('enum full', RP.ReservedFromStock.Value());
        RP.ReservedFromStock.SetValue(1);
        Observer.Observe('integer 1', RP.ReservedFromStock.Value());
        RP.ReservedFromStock.SetValue('Full');
        Observer.Observe('text full', RP.ReservedFromStock.Value());
        asserterror RP.ReservedFromStock.SetValue(Enum::"LT Y37 VA Stock"::None);
        Observer.ObserveError('enum none');
        Observer.Observe('after none', RP.ReservedFromStock.Value());
        asserterror RP.ReservedFromStock.SetValue(4);
        Observer.ObserveError('integer 4');
        RP.MixedStock.SetValue('Partial');
        Observer.Observe('mixed partial', RP.MixedStock.Value());
        RP.MixedStock.SetValue(Enum::"LT Y37 VA Stock"::" ");
        Observer.Observe('mixed blank', RP.MixedStock.Value());
        RP.MixedStock.SetValue(3);
        Observer.Observe('mixed integer 3', RP.MixedStock.Value());
        asserterror RP.MixedStock.SetValue('Full');
        Observer.ObserveError('mixed full');
        Observer.Observe('mixed after full', RP.MixedStock.Value());
        RP.ReservedFromStock.SetValue('Full and Partial');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ReportHandler')]
    procedure LT_C315_RequestPage_EnumVariables()
    var
        Xml: Text;
    begin
        Xml := Report.RunRequestPage(Report::"LT Y37 VA Report");
        Observer.Observe('xml options', CopyStr(Xml, StrPos(Xml, '<Options>'), StrPos(Xml, '</Options>') + 10 - StrPos(Xml, '<Options>')));
        Observer.Expect('initial', ' ');
        Observer.Expect('enum full', 'Full');
        Observer.Expect('integer 1', 'Full and Partial');
        Observer.Expect('text full', 'Full');
        Observer.Expect('enum none|text', 'Validation error for Field: ReservedFromStock,  Message = ''Your entry of ''2'' is not an acceptable value for ''ReservedFromStock''.''');
        Observer.Expect('enum none|code', 'TestValidation');
        Observer.Expect('after none', '2');
        Observer.Expect('integer 4|text', 'Validation error for Field: ReservedFromStock,  Message = ''Your entry of ''2'' is not an acceptable value for ''ReservedFromStock''.''');
        Observer.Expect('integer 4|code', 'TestValidation');
        Observer.Expect('mixed partial', 'Partial');
        Observer.Expect('mixed blank', ' ');
        Observer.Expect('mixed integer 3', 'None');
        Observer.Expect('mixed full|text', 'Validation error for Field: MixedStock,  Message = ''Your entry of ''Full'' is not an acceptable value for ''MixedStock''.''');
        Observer.Expect('mixed full|code', 'TestValidation');
        Observer.Expect('mixed after full', '3');
        Observer.Expect('xml options', '<Options><Field name="StockVar">1</Field><Field name="MixedVar">3</Field></Options>');
        Observer.Verify();
    end;

    [Test]
    procedure LT_C315_List_RepeaterRecField()
    var
        O: Record "LT Y37 VA Order";
        P: TestPage "LT Y37 VA List";
    begin
        O.DeleteAll();
        O."No." := 'O1';
        O.Status := O.Status::Planned;
        O.Insert();
        O."No." := 'O2';
        O.Status := O.Status::Finished;
        O.Insert();
        // asserterror below rolls back the open write transaction: commit the rows first.
        Commit();
        P.OpenEdit();
        P.GoToKey('O2');
        Observer.Observe('o2 initial', P.Status.Value());
        P.Status.SetValue(Enum::"LT Y37 VA Status"::Released);
        Observer.Observe('o2 released', P.Status.Value());
        P.First();
        O.Get('O2');
        Observer.Observe('o2 stored after move', Format(O.Status));
        Commit();
        P.GoToKey('O2');
        asserterror P.Status.SetValue(Enum::"LT Y37 VA Status"::Finished);
        Observer.ObserveError('o2 finished');
        Observer.Observe('o2 after finished', P.Status.Value());
        P.First();
        asserterror P.Status.SetValue('Simulated');
        Observer.ObserveError('o1 simulated');
        Observer.Observe('o1 after simulated', P.Status.Value());
        P.Close();
        O.Get('O1');
        Observer.Observe('o1 stored', Format(O.Status));
        O.Get('O2');
        Observer.Observe('o2 stored', Format(O.Status));
        Observer.Expect('o2 initial', '4');
        Observer.Expect('o2 released', 'Released');
        Observer.Expect('o2 stored after move', 'Released');
        Observer.Expect('o2 finished|text', 'Validation error for Field: Status,  Message = ''Your entry of ''3'' is not an acceptable value for ''Status''.''');
        Observer.Expect('o2 finished|code', 'TestValidation');
        Observer.Expect('o2 after finished', '3');
        Observer.Expect('o1 simulated|text', 'Validation error for Field: Status,  Message = ''Your entry of ''Simulated'' is not an acceptable value for ''Status''.''');
        Observer.Expect('o1 simulated|code', 'TestValidation');
        Observer.Expect('o1 after simulated', '3');
        Observer.Expect('o1 stored', 'Planned');
        Observer.Expect('o2 stored', 'Released');
        Observer.Verify();
    end;
}
