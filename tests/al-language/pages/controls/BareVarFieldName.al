// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-controls
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 75150, codeunit 75151, page 75152, test codeunit 75153
// Probe (al-runner issue 7397): a page variable with the same name as a field of the source table, and a control bound to the
//   bare name: field(AmountCtl; Amount). Which one does the control bind, the page variable or the field? Shapes: Decimal
//   (Amount), Text (Description), a quoted name with a space ("Unit Code"), and a variable of another type than the field
//   (Qty: Text against an Integer field). Observed: the control's value after open and after GoToKey, its caption (the fields
//   have captions that differ from their names), a value typed with SetValue, what the control's OnValidate, OnAfterGetRecord
//   and OnClosePage read through the bare name and through Rec, the stored row after Close, and a CaptionClass expression that
//   reads the bare name. In the page's code a bare name binds to the field (AL 16 rejects `Qty := 'text'` with AL0122, so the
//   variables cannot be set from code and keep their default values); the control's value tells which one it shows.
// local object: the probe needs a table whose field names are also page variable names
// BC versions: 27, 28, 29

#pragma warning disable AL0604
table 75150 "PCV VarField Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Amount; Decimal) { Caption = 'Row Amount Cap'; }
        field(3; Description; Text[50]) { Caption = 'Row Desc Cap'; }
        field(4; "Unit Code"; Code[10]) { Caption = 'Row Unit Cap'; }
        field(5; Qty; Integer) { Caption = 'Row Qty Cap'; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 75151 "PCV VarField Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Lines;
        Lines := '';
    end;
}

page 75152 "PCV VarField Card"
{
    PageType = Card;
    SourceTable = "PCV VarField Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(AmountCtl; Amount)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    Log.Add('V-amount bare=' + Format(Amount) + ' rec=' + Format(Rec.Amount));
                end;
            }
            field(DescCtl; Description)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    Log.Add('V-desc bare=' + Description + ' rec=' + Rec.Description);
                end;
            }
            field(UnitCtl; "Unit Code")
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    Log.Add('V-unit bare=' + "Unit Code" + ' rec=' + Rec."Unit Code");
                end;
            }
            field(QtyCtl; Qty)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    Log.Add('V-qty bare=' + Format(Qty) + ' rec=' + Format(Rec.Qty));
                end;
            }
            field(CaptionCtl; Rec."No.")
            {
                ApplicationArea = All;
                CaptionClass = '3,cc ' + Format(Amount);
            }
        }
    }

    var
        Log: Codeunit "PCV VarField Log";
        Amount: Decimal;
        Description: Text[50];
        "Unit Code": Code[10];
        Qty: Text[30];

    trigger OnOpenPage()
    begin
        Log.Add('open rec=' + Format(Rec.Amount) + '/' + Rec.Description + '/' + Rec."Unit Code" + '/' + Format(Rec.Qty));
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('agr ' + Rec."No." + ' bare=' + Format(Amount) + '/' + Description + '/' + "Unit Code" + '/' + Format(Qty) +
            ' rec=' + Format(Rec.Amount) + '/' + Rec.Description + '/' + Rec."Unit Code" + '/' + Format(Rec.Qty));
    end;

    trigger OnClosePage()
    begin
        Log.Add('close bare=' + Format(Amount) + '/' + Description + '/' + "Unit Code" + '/' + Format(Qty) +
            ' rec=' + Format(Rec.Amount) + '/' + Rec.Description + '/' + Rec."Unit Code" + '/' + Format(Rec.Qty));
    end;
}
#pragma warning restore AL0604

codeunit 75153 "PCV VarField Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "PCV VarField Row";
        Log: Codeunit "PCV VarField Log";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'R1';
        Row.Amount := 100;
        Row.Description := 'rec desc';
        Row."Unit Code" := 'RECU';
        Row.Qty := 5;
        Row.Insert();
        Log.Take();
    end;

    local procedure RowText(): Text
    var
        Row: Record "PCV VarField Row";
    begin
        if not Row.Get('R1') then
            exit('no row');
        exit(Format(Row.Amount) + '/' + Row.Description + '/' + Row."Unit Code" + '/' + Format(Row.Qty));
    end;

    // CLAIM: what the controls bound to a bare name that is both a page variable and a source field show, and their captions.
    [Test]
    procedure PCV_BareVarField_Read()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PCV VarField Log";
        Card: TestPage "PCV VarField Card";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('open amount', Card.AmountCtl.Value());
        Observer.Observe('open desc', Card.DescCtl.Value());
        Observer.Observe('open unit', Card.UnitCtl.Value());
        Observer.Observe('open qty', Card.QtyCtl.Value());
        Card.GoToKey('R1');
        Observer.Observe('row amount', Card.AmountCtl.Value());
        Observer.Observe('row desc', Card.DescCtl.Value());
        Observer.Observe('row unit', Card.UnitCtl.Value());
        Observer.Observe('row qty', Card.QtyCtl.Value());
        Observer.Observe('caption amount', Card.AmountCtl.Caption());
        Observer.Observe('caption desc', Card.DescCtl.Caption());
        Observer.Observe('caption unit', Card.UnitCtl.Caption());
        Observer.Observe('caption qty', Card.QtyCtl.Caption());
        Observer.Observe('captionclass', Card.CaptionCtl.Caption());
        Card.Close();
        Observer.Observe('log', Log.Take());
        Observer.Observe('stored', RowText());
        Observer.Finish();
    end;

    // CLAIM: where a value typed into those controls goes: the page variable, the field, the stored row.
    [Test]
    procedure PCV_BareVarField_Write()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PCV VarField Log";
        Card: TestPage "PCV VarField Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Log.Take();
        Card.AmountCtl.SetValue('42');
        Card.DescCtl.SetValue('typed desc');
        Card.UnitCtl.SetValue('TYPU');
        Card.QtyCtl.SetValue('9');
        Observer.Observe('typed amount', Card.AmountCtl.Value());
        Observer.Observe('typed desc', Card.DescCtl.Value());
        Observer.Observe('typed unit', Card.UnitCtl.Value());
        Observer.Observe('typed qty', Card.QtyCtl.Value());
        Observer.Observe('captionclass', Card.CaptionCtl.Caption());
        Card.Close();
        Observer.Observe('log', Log.Take());
        Observer.Observe('stored', RowText());
        Observer.Finish();
    end;
}
