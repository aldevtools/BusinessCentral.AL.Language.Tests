// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51744 "Probe Auto Split Lines"
{
    PageType = ListPart;
    SourceTable = "Probe Line";
    ApplicationArea = All;
    AutoSplitKey = true;
    DelayedInsert = true;
    PopulateAllFields = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(ItemNo; Rec.ItemNo)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        if NamedProcedureCalled then
                            Error('CurrPage.SaveRecord invoked the page procedure.');
                        if not Shadow.Get(Rec.LineNo) then
                            Error('Shadow line %1 was absent after SaveRecord.', Rec.LineNo);
                        Shadow.Value := Rec.ItemNo;
                        Shadow.Modify();
                    end;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(Shadow);
    end;

    procedure Bind(var Shared: Record "Probe Shadow" temporary)
    begin
        Shadow.Copy(Shared, true);
        Subscriber.Initialize(Shadow);
        BindSubscription(Subscriber);
    end;

    internal procedure SaveRecord()
    begin
        NamedProcedureCalled := true;
    end;

    procedure Unbind()
    begin
        UnbindSubscription(Subscriber);
    end;

    var
        Subscriber: Codeunit "Probe Shadow Subscriber";
        NamedProcedureCalled: Boolean;
        Shadow: Record "Probe Shadow" temporary;
}
