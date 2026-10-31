// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (LT Y17 SW *)
// Probe (gap cycle 1, G14): a sum (and -sum, average, min, max) FlowField whose WHERE tests a FlowField of the summed table (the Bank Acc.
//   Reconciliation "Total Outstd Bank Transactions" shape: "Check Ledger Entries" = const(0) / filter(> 0), a count FlowField).
//   Nearby pin: record/lt-calcformula-date-literal/CalcFormulaDateLiteral.al:76-95 (count / lookup with such a condition).
// Probe: values recorded on the BC 29 SaaS sandbox; other BC versions are checked by the corpus CI matrix.

table 91811 "LT Y17 SW Detail"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Owner Entry No."; Integer) { }
        field(3; "Doc Date"; Date) { }
        field(4; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 91812 "LT Y17 SW Entry"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Acct No."; Code[20]) { }
        field(3; Open; Boolean) { }
        field(4; Amount; Decimal) { }
        field(5; "Posting Date"; Date) { }
        field(10; "Detail Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT Y17 SW Detail" where("Owner Entry No." = field("Entry No.")));
        }
        field(11; "Date Filter"; Date) { FieldClass = FlowFilter; }
        field(12; "Detail Count In Period"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT Y17 SW Detail" where("Owner Entry No." = field("Entry No."), "Doc Date" = field("Date Filter")));
        }
        field(13; "Detail Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT Y17 SW Detail".Amount where("Owner Entry No." = field("Entry No.")));
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Acct; "Acct No.", Open) { SumIndexFields = Amount; }
    }
}

table 91813 "LT Y17 SW Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Acct No."; Code[20]) { }
        field(10; "Sum No Detail"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT Y17 SW Entry".Amount where("Acct No." = field("Acct No."), Open = const(true), "Detail Count" = const(0)));
        }
        field(11; "Sum With Detail"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT Y17 SW Entry".Amount where("Acct No." = field("Acct No."), Open = const(true), "Detail Count" = filter(> 0)));
        }
        field(12; "Neg Sum No Detail"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = - sum("LT Y17 SW Entry".Amount where("Acct No." = field("Acct No."), Open = const(true), "Detail Count" = const(0)));
        }
        field(13; "Avg With Detail"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = average("LT Y17 SW Entry".Amount where("Acct No." = field("Acct No."), Open = const(true), "Detail Count" = filter(> 0)));
        }
        field(14; "Min With Detail"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = min("LT Y17 SW Entry".Amount where("Acct No." = field("Acct No."), Open = const(true), "Detail Count" = filter(> 0)));
        }
        field(15; "Max With Detail"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = max("LT Y17 SW Entry".Amount where("Acct No." = field("Acct No."), Open = const(true), "Detail Count" = filter(> 0)));
        }
        field(16; "Sum In Period"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT Y17 SW Entry".Amount where("Acct No." = field("Acct No."), "Detail Count In Period" = filter(> 0)));
        }
        field(17; "Sum Detail Amount NonZero"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT Y17 SW Entry".Amount where("Acct No." = field("Acct No."), "Detail Amount" = filter(<> 0)));
        }
        field(18; "Sum No Detail All"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT Y17 SW Entry".Amount where("Acct No." = field("Acct No."), "Detail Count" = const(0)));
        }
    }

    keys
    {
        key(PK; "Acct No.") { Clustered = true; }
    }
}

codeunit 91814 "LT Y17 SW Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        D: Record "LT Y17 SW Detail";
        O: Record "LT Y17 SW Entry";
        H: Record "LT Y17 SW Header";
    begin
        D.DeleteAll();
        O.DeleteAll();
        H.DeleteAll();
        AddEntry(5, 'A', true, 40, 20240105D);
        AddEntry(3, 'A', true, 7.5, 20240103D);
        AddEntry(1, 'A', true, 10, 20240101D);
        AddEntry(4, 'A', false, 100, 20240104D);
        AddEntry(2, 'A', true, -25, 20240102D);
        AddEntry(6, 'B', true, 999, 20240106D);
        AddDetail(3, 3, 20240105D, 0);
        AddDetail(1, 2, 20240105D, 5);
        AddDetail(2, 3, 20240210D, 0);
        AddDetail(4, 6, 20240105D, 1);
        AddHeader('C');
        AddHeader('A');
        AddHeader('B');
    end;

    local procedure AddEntry(No: Integer; Acct: Code[20]; IsOpen: Boolean; Amt: Decimal; PostingDate: Date)
    var
        O: Record "LT Y17 SW Entry";
    begin
        O.Init();
        O."Entry No." := No;
        O."Acct No." := Acct;
        O.Open := IsOpen;
        O.Amount := Amt;
        O."Posting Date" := PostingDate;
        O.Insert();
    end;

    local procedure AddDetail(No: Integer; Owner: Integer; DocDate: Date; Amt: Decimal)
    var
        D: Record "LT Y17 SW Detail";
    begin
        D.Init();
        D."Entry No." := No;
        D."Owner Entry No." := Owner;
        D."Doc Date" := DocDate;
        D.Amount := Amt;
        D.Insert();
    end;

    local procedure AddHeader(Acct: Code[20])
    var
        H: Record "LT Y17 SW Header";
    begin
        H.Init();
        H."Acct No." := Acct;
        H.Insert();
    end;

    local procedure ObserveBasic(var Observer: Codeunit "Probe Observer"; Tag: Text; Acct: Code[20])
    var
        H: Record "LT Y17 SW Header";
    begin
        H.Get(Acct);
        H.CalcFields("Sum No Detail", "Sum With Detail");
        Observer.Observe(Tag + ' ' + Acct + ' no detail', Format(H."Sum No Detail", 0, 9));
        Observer.Observe(Tag + ' ' + Acct + ' with detail', Format(H."Sum With Detail", 0, 9));
    end;

    [Test]
    procedure CalcSumWhereFlowField_Basic()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ObserveBasic(Observer, 'sum', 'A');
        ObserveBasic(Observer, 'sum', 'B');
        ObserveBasic(Observer, 'sum', 'C');
        Observer.Finish();
    end;

    local procedure ObserveOther(var Observer: Codeunit "Probe Observer"; Acct: Code[20])
    var
        H: Record "LT Y17 SW Header";
    begin
        H.Get(Acct);
        H.CalcFields("Neg Sum No Detail", "Avg With Detail", "Min With Detail", "Max With Detail");
        Observer.Observe(Acct + ' neg sum', Format(H."Neg Sum No Detail", 0, 9));
        Observer.Observe(Acct + ' avg', Format(H."Avg With Detail", 0, 9));
        Observer.Observe(Acct + ' min', Format(H."Min With Detail", 0, 9));
        Observer.Observe(Acct + ' max', Format(H."Max With Detail", 0, 9));
    end;

    [Test]
    procedure CalcSumWhereFlowField_OtherMethods()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "LT Y17 SW Header";
    begin
        Seed();
        ObserveOther(Observer, 'A');
        ObserveOther(Observer, 'C');
        H.Get('A');
        H.CalcFields("Sum No Detail All");
        Observer.Observe('A sum no detail incl closed', Format(H."Sum No Detail All", 0, 9));
        Observer.Finish();
    end;

    [Test]
    procedure CalcSumWhereFlowField_AfterDetailChange()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "LT Y17 SW Header";
    begin
        Seed();
        H.Get('A');
        H.CalcFields("Sum No Detail", "Sum With Detail");
        AddDetail(10, 1, 20240105D, 0);
        H.CalcFields("Sum No Detail", "Sum With Detail");
        Observer.Observe('same var no detail', Format(H."Sum No Detail", 0, 9));
        Observer.Observe('same var with detail', Format(H."Sum With Detail", 0, 9));
        ObserveBasic(Observer, 'fresh', 'A');
        Observer.Finish();
    end;

    [Test]
    procedure CalcSumWhereFlowField_FilterOnHeader()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "LT Y17 SW Header";
        Keys: Text;
    begin
        Seed();
        H.SetFilter("Sum No Detail", '>0');
        if H.FindSet() then
            repeat
                Keys += H."Acct No." + ';';
            until H.Next() = 0;
        Observer.Observe('no detail >0', Keys);
        Keys := '';
        H.Reset();
        H.SetFilter("Sum With Detail", '<>0');
        if H.FindSet() then
            repeat
                Keys += H."Acct No." + ';';
            until H.Next() = 0;
        Observer.Observe('with detail <>0', Keys);
        H.Reset();
        H.SetRange("Sum With Detail", 0);
        Observer.Observe('with detail =0 count', Format(H.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure CalcSumWhereFlowField_ConditionWithFlowFilter()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "LT Y17 SW Header";
    begin
        Seed();
        H.Get('A');
        H.CalcFields("Sum In Period", "Sum Detail Amount NonZero");
        Observer.Observe('A in period', Format(H."Sum In Period", 0, 9));
        Observer.Observe('A detail amount nonzero', Format(H."Sum Detail Amount NonZero", 0, 9));
        H.Get('B');
        H.CalcFields("Sum In Period", "Sum Detail Amount NonZero");
        Observer.Observe('B in period', Format(H."Sum In Period", 0, 9));
        Observer.Observe('B detail amount nonzero', Format(H."Sum Detail Amount NonZero", 0, 9));
        Observer.Finish();
    end;

    [Test]
    procedure CalcSumWhereFlowField_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "LT Y17 SW Header" temporary;
    begin
        Seed();
        H.Init();
        H."Acct No." := 'A';
        H.Insert();
        H.CalcFields("Sum No Detail", "Sum With Detail", "Neg Sum No Detail");
        Observer.Observe('temp A no detail', Format(H."Sum No Detail", 0, 9));
        Observer.Observe('temp A with detail', Format(H."Sum With Detail", 0, 9));
        Observer.Observe('temp A neg', Format(H."Neg Sum No Detail", 0, 9));
        Observer.Finish();
    end;
}
