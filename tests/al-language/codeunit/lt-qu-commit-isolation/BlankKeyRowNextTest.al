// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-requiredtestisolation-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-transactionmodel-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 93106, pages 93107, 93108, test codeunit 93109 (writer Y57)
// Probe: the shape of Microsoft's "SMTP Account Auth Tests" (RequiredTestIsolation = Disabled, a GLOBAL TestPage and a GLOBAL record
//   variable, some tests with TransactionModel AutoRollback) on an own table whose primary key is a Guid: a row with a blank key, written
//   by one test, read by the NEXT test of the same codeunit. Writers: a Card TestPage OpenEdit on the empty table, SetValue of Name, Close
//   (DelayedInsert false and true), the same under AutoRollback, a record Insert of a blank key (default and AutoRollback), and a Card left
//   open at the end of the test (closed by the next test). Each writer is preceded by a Cleanup test (DeleteAll) and followed by a Read test.
//   Writers and cleanups never fail; only the Read tests observe. Tests run in the order they are declared.
//   Harness (see RqIsolationModes.al in this folder): no handlers and TestPermissions = Disabled, so BC 28+ Linux legs run this codeunit
//   through the TestRunnerHub with its RequiredTestIsolation; BC 27 under Test Runner - Isol. Codeunit (130450).
// BC versions: 27, 28, 29

table 93106 "LT Y57 Iso Account"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Guid) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 93107 "LT Y57 Iso Card"
{
    PageType = Card;
    SourceTable = "LT Y57 Iso Account";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 93108 "LT Y57 Iso Card Delayed"
{
    PageType = Card;
    SourceTable = "LT Y57 Iso Account";
    ApplicationArea = All;
    UsageCategory = None;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 93109 "LT Y57 Blank Key Isolation"
{
    Subtype = Test;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        Account: Record "LT Y57 Iso Account";
        CardPage: TestPage "LT Y57 Iso Card";

    local procedure Rows(): Text
    var
        Row: Record "LT Y57 Iso Account";
        NullGuid: Guid;
        Result: Text;
    begin
        Result := Format(Row.Count());
        if Row.Get(NullGuid) then
            Result += '|blank key: ' + Row.Name
        else
            Result += '|no blank key';
        exit(Result);
    end;

    local procedure Cleanup()
    var
        Row: Record "LT Y57 Iso Account";
    begin
        Row.DeleteAll();
    end;

    [Test]
    procedure A0_Cleanup()
    begin
        Cleanup();
    end;

    [Test]
    procedure A1_Write_CardSetValue()
    begin
        CardPage.OpenEdit();
        CardPage.NameCtl.SetValue('a1');
        CardPage.Close();
    end;

    [Test]
    procedure A2_Read()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure B0_Cleanup()
    begin
        Cleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure B1_Write_CardSetValue_AutoRollback()
    begin
        CardPage.OpenEdit();
        CardPage.NameCtl.SetValue('b1');
        CardPage.Close();
    end;

    [Test]
    procedure B2_Read()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure C0_Cleanup()
    begin
        Cleanup();
    end;

    [Test]
    procedure C1_Write_DelayedCardSetValue()
    var
        DelayedPage: TestPage "LT Y57 Iso Card Delayed";
    begin
        DelayedPage.OpenEdit();
        DelayedPage.NameCtl.SetValue('c1');
        DelayedPage.Close();
    end;

    [Test]
    procedure C2_Read()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure D0_Cleanup()
    begin
        Cleanup();
    end;

    [Test]
    procedure D1_Write_BlankKeyInsert()
    begin
        Account.Init();
        Account.Name := 'd1';
        Account.Insert();
    end;

    [Test]
    procedure D2_Read()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', Rows());
        Observer.Observe('global record name', Account.Name);
        Observer.Finish();
    end;

    [Test]
    procedure E0_Cleanup()
    begin
        Cleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure E1_Write_BlankKeyInsert_AutoRollback()
    var
        Row: Record "LT Y57 Iso Account";
    begin
        Row.Init();
        Row.Name := 'e1';
        Row.Insert();
    end;

    [Test]
    procedure E2_Read()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure F0_Cleanup()
    begin
        Cleanup();
    end;

    [Test]
    procedure F1_Write_CardLeftOpen()
    begin
        CardPage.OpenEdit();
        CardPage.NameCtl.SetValue('f1');
    end;

    [Test]
    procedure F2_Read_CloseLeftOpen()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows before close', Rows());
        ClearLastError();
        if TryClose() then
            Observer.Observe('close', 'ok')
        else
            Observer.Observe('close', 'error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe('rows after close', Rows());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryClose()
    begin
        CardPage.Close();
    end;

    [Test]
    procedure Z_Cleanup()
    begin
        Cleanup();
    end;
}
