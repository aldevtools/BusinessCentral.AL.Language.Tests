// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setascending-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (tables 92840 and 92841, codeunit 92842)
// Probe (writer Y43, gap cycle 4, G4-15): SetAscending(FlowField, false) after SetCurrentKey on a SUM FlowField with two field() conditions
//   (the header/line shape of a sales document), with a filter on an Option field and a date range: Count, FindFirst and the FlowField value
//   read without CalcFields, the FindSet order with a tie, a zero row and a negative row, SetAscending(true), FindLast and Next(-1),
//   SetAscending followed by Ascending(true), and SetCurrentKey(FlowField, "No.") with the FlowField descending.
//   Seed: primary key order, insert order and Amount order all differ. Neighbour: SetCurrentKeyFlowFieldOrder.al (count FlowField, Ascending(false)).
// Probe: values recorded on the BC 29 SaaS sandbox; other BC versions are checked by the corpus CI matrix.

table 92840 "LT Y43 SA Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; DocType; Option) { OptionMembers = Quote,Order; }
        field(3; DocNo; Code[20]) { }
        field(4; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 92841 "LT Y43 SA Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; DocType; Option) { OptionMembers = Quote,Order; }
        field(2; "No."; Code[20]) { }
        field(3; PostDate; Date) { }
        field(4; Amount; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT Y43 SA Line".Amount where(DocType = field(DocType), DocNo = field("No.")));
        }
    }

    keys
    {
        key(PK; DocType, "No.") { Clustered = true; }
    }
}

codeunit 92842 "LT Y43 SA FlowField Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure AddHeader(DocType: Option Quote,"Order"; No: Code[20]; PostDate: Date)
    var
        H: Record "LT Y43 SA Header";
    begin
        H.DocType := DocType;
        H."No." := No;
        H.PostDate := PostDate;
        H.Insert();
    end;

    local procedure AddLine(Id: Integer; DocType: Option Quote,"Order"; DocNo: Code[20]; Amount: Decimal)
    var
        L: Record "LT Y43 SA Line";
    begin
        L.Id := Id;
        L.DocType := DocType;
        L.DocNo := DocNo;
        L.Amount := Amount;
        L.Insert();
    end;

    local procedure Seed()
    var
        H: Record "LT Y43 SA Header";
        L: Record "LT Y43 SA Line";
        DocType: Option Quote,"Order";
    begin
        H.DeleteAll();
        L.DeleteAll();
        // inserted out of key order; Amount: H1 30, H2 50, H3 0 (no lines), H4 30 (tie with H1), H5 -5, H6 7 (outside the date filter), Q1 100 (a quote)
        AddHeader(DocType::Order, 'H4', 20240115D);
        AddHeader(DocType::Order, 'H2', 20240115D);
        AddHeader(DocType::Quote, 'Q1', 20240115D);
        AddHeader(DocType::Order, 'H5', 20240115D);
        AddHeader(DocType::Order, 'H1', 20240115D);
        AddHeader(DocType::Order, 'H6', 20240115D - 400);
        AddHeader(DocType::Order, 'H3', 20240115D);
        AddLine(7, DocType::Order, 'H4', 30);
        AddLine(3, DocType::Order, 'H1', 20);
        AddLine(5, DocType::Order, 'H2', 50);
        AddLine(1, DocType::Order, 'H1', 10);
        AddLine(2, DocType::Order, 'H5', -5);
        AddLine(4, DocType::Order, 'H6', 7);
        AddLine(6, DocType::Quote, 'Q1', 100);
    end;

    local procedure Filter(var H: Record "LT Y43 SA Header")
    begin
        H.SetRange(DocType, H.DocType::Order);
        H.SetFilter(PostDate, '>=%1&<=%2', 20240115D - 30, 20240115D);
    end;

    [TryFunction]
    local procedure TrySetAscending(var H: Record "LT Y43 SA Header"; Ascending: Boolean)
    begin
        H.SetAscending(Amount, Ascending);
    end;

    [TryFunction]
    local procedure TryCount(var H: Record "LT Y43 SA Header"; var Result: Integer)
    begin
        Result := H.Count();
    end;

    [TryFunction]
    local procedure TryFindFirst(var H: Record "LT Y43 SA Header"; var Found: Boolean)
    begin
        Found := H.FindFirst();
    end;

    [TryFunction]
    local procedure TryLoop(var H: Record "LT Y43 SA Header"; var Order: Text)
    begin
        Order := '';
        if H.FindSet() then
            repeat
                H.CalcFields(Amount);
                Order += H."No." + ':' + Format(H.Amount) + ' ';
            until H.Next() = 0;
    end;

    [TryFunction]
    local procedure TryLoopBack(var H: Record "LT Y43 SA Header"; var Order: Text)
    begin
        Order := '';
        if H.FindLast() then
            repeat
                H.CalcFields(Amount);
                Order += H."No." + ':' + Format(H.Amount) + ' ';
            until H.Next(-1) = 0;
    end;

    local procedure Loop(var H: Record "LT Y43 SA Header"): Text
    var
        Order: Text;
    begin
        ClearLastError();
        if TryLoop(H, Order) then
            exit('ok:' + Order);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure LoopBack(var H: Record "LT Y43 SA Header"): Text
    var
        Order: Text;
    begin
        ClearLastError();
        if TryLoopBack(H, Order) then
            exit('ok:' + Order);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure SetAsc(var H: Record "LT Y43 SA Header"; Ascending: Boolean): Text
    begin
        ClearLastError();
        if TrySetAscending(H, Ascending) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Y43_G415_SetAscendingFalse_CountFindFirst()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "LT Y43 SA Header";
        N: Integer;
        Found: Boolean;
    begin
        Seed();
        Filter(H);
        H.SetCurrentKey(Amount);
        Observer.Observe('setAscending', SetAsc(H, false));
        ClearLastError();
        Observer.Observe('countOk', Format(TryCount(H, N)));
        Observer.ObserveError('count');
        Observer.Observe('count', Format(N));
        Observer.Observe('findFirstOk', Format(TryFindFirst(H, Found)));
        Observer.ObserveError('findFirst');
        Observer.Observe('found', Format(Found));
        Observer.Observe('no', H."No.");
        Observer.Observe('amountNoCalc', Format(H.Amount));
        H.CalcFields(Amount);
        Observer.Observe('amountCalc', Format(H.Amount));
        Observer.Expect('setAscending', 'ok');
        Observer.Expect('countOk', 'Yes');
        Observer.Expect('count|text', '');
        Observer.Expect('count|code', '');
        Observer.Expect('count', '5');
        Observer.Expect('findFirstOk', 'Yes');
        Observer.Expect('findFirst|text', '');
        Observer.Expect('findFirst|code', '');
        Observer.Expect('found', 'Yes');
        Observer.Expect('no', 'H2');
        Observer.Expect('amountNoCalc', '50');
        Observer.Expect('amountCalc', '50');
        Observer.Verify();
    end;

    [Test]
    procedure Y43_G415_SetAscendingFalse_FindSetOrder()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "LT Y43 SA Header";
    begin
        Seed();
        Filter(H);
        H.SetCurrentKey(Amount);
        Observer.Observe('setAscending', SetAsc(H, false));
        Observer.Observe('order', Loop(H));
        Observer.Observe('getAscendingAmount', Format(H.GetAscending(Amount)));
        Observer.Observe('ascending', Format(H.Ascending()));
        Observer.Observe('currentKey', H.CurrentKey());
        Observer.Observe('view', H.GetView(false));
        Observer.Expect('setAscending', 'ok');
        Observer.Expect('order', 'ok:H2:50 H1:30 H4:30 H3:0 H5:-5 ');
        Observer.Expect('getAscendingAmount', 'No');
        Observer.Expect('ascending', 'No');
        Observer.Expect('currentKey', 'Amount');
        Observer.Expect('view', 'VERSION(1) SORTING(Field4) ORDER(1) WHERE(Field1=1(1),Field3=1(>=2023-12-16&<=2024-01-15))');
        Observer.Verify();
    end;

    [Test]
    procedure Y43_G415_SetAscendingTrue_FindSetOrder()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "LT Y43 SA Header";
    begin
        Seed();
        Filter(H);
        H.SetCurrentKey(Amount);
        Observer.Observe('setAscending', SetAsc(H, true));
        Observer.Observe('order', Loop(H));
        Observer.Observe('getAscendingAmount', Format(H.GetAscending(Amount)));
        Observer.Observe('view', H.GetView(false));
        Observer.Expect('setAscending', 'ok');
        Observer.Expect('order', 'ok:H5:-5 H3:0 H1:30 H4:30 H2:50 ');
        Observer.Expect('getAscendingAmount', 'Yes');
        Observer.Expect('view', 'VERSION(1) SORTING(Field4) WHERE(Field1=1(1),Field3=1(>=2023-12-16&<=2024-01-15))');
        Observer.Verify();
    end;

    [Test]
    procedure Y43_G415_SetAscendingFalse_FindLast_Next()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "LT Y43 SA Header";
    begin
        Seed();
        Filter(H);
        H.SetCurrentKey(Amount);
        Observer.Observe('setAscending', SetAsc(H, false));
        Observer.Observe('orderBack', LoopBack(H));
        Observer.Expect('setAscending', 'ok');
        Observer.Expect('orderBack', 'ok:H5:-5 H3:0 H4:30 H1:30 H2:50 ');
        Observer.Verify();
    end;

    [Test]
    procedure Y43_G415_SetAscending_Then_AscendingTrue()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "LT Y43 SA Header";
    begin
        Seed();
        Filter(H);
        H.SetCurrentKey(Amount);
        Observer.Observe('setAscending', SetAsc(H, false));
        H.Ascending(true);
        Observer.Observe('getAscendingAmount', Format(H.GetAscending(Amount)));
        Observer.Observe('ascending', Format(H.Ascending()));
        Observer.Observe('order', Loop(H));
        Observer.Observe('view', H.GetView(false));
        Observer.Expect('setAscending', 'ok');
        Observer.Expect('getAscendingAmount', 'Yes');
        Observer.Expect('ascending', 'Yes');
        Observer.Expect('order', 'ok:H5:-5 H3:0 H1:30 H4:30 H2:50 ');
        Observer.Expect('view', 'VERSION(1) SORTING(Field4) WHERE(Field1=1(1),Field3=1(>=2023-12-16&<=2024-01-15))');
        Observer.Verify();
    end;

    [Test]
    procedure Y43_G415_KeyFlowFieldThenPk_SetAscendingFalse()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "LT Y43 SA Header";
    begin
        Seed();
        Filter(H);
        H.SetCurrentKey(Amount, "No.");
        Observer.Observe('setAscending', SetAsc(H, false));
        Observer.Observe('order', Loop(H));
        Observer.Observe('getAscendingAmount', Format(H.GetAscending(Amount)));
        Observer.Observe('getAscendingNo', Format(H.GetAscending("No.")));
        Observer.Observe('currentKey', H.CurrentKey());
        Observer.Observe('view', H.GetView(false));
        Observer.Expect('setAscending', 'ok');
        Observer.Expect('order', 'ok:H2:50 H1:30 H4:30 H3:0 H5:-5 ');
        Observer.Expect('getAscendingAmount', 'No');
        Observer.Expect('getAscendingNo', 'Yes');
        Observer.Expect('currentKey', 'Amount,No.');
        Observer.Expect('view', 'VERSION(1) SORTING(Field4,Field2) ORDER(1,0) WHERE(Field1=1(1),Field3=1(>=2023-12-16&<=2024-01-15))');
        Observer.Verify();
    end;
}
