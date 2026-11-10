// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-columnfilter-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT QAW Line" (75081, queries/read-lifecycle/QueryAggregatedWriteInLoop.al);
//   own queries 75098-75101, test codeunit 75102
// local object: the ColumnFilter and DataItemTableFilter properties of the queries are what is under test
// Probe (observe only): al-runner issue 5199. TestQueryColumnFilter.al pins the rows of a query with a static ColumnFilter. This probe asks what
//   GetFilter(column) and GetFilters() answer for
//     a column with ColumnFilter = const, a column with ColumnFilter = filter(expression), a filter() element with a ColumnFilter,
//     a Count column with a ColumnFilter, and a data item with DataItemTableFilter on a field that is also a column,
//   on a fresh variable, after Open, after Read, after Close, after SetRange on another column, after SetFilter and SetRange on the column
//   itself (does the runtime filter replace the static one or add to it), and after the runtime filter is removed again.
//   Each step is observed as: GetFilter of the column, GetFilters, and the rows the query returns then.
//   Rows: header H1 lines 10, 20, 30 of contact C1; line 40 of contact C2; header H2 line 10 of contact C1. Kind is 1 for all but line 30 (kind 2).
// BC versions: 27, 28, 29

query 75098 "LT QCF Column Const"
{
    QueryType = Normal;
    OrderBy = ascending(HeaderNo), ascending(LineNo);

    elements
    {
        dataitem(L; "LT QAW Line")
        {
            column(HeaderNo; "Header No.") { }
            column(LineNo; "Line No.") { }
            column(ContactNo; "Contact No.")
            {
                ColumnFilter = ContactNo = const('C1');
            }
        }
    }
}

query 75099 "LT QCF Column Expr"
{
    QueryType = Normal;
    OrderBy = ascending(HeaderNo), ascending(LineNo);

    elements
    {
        dataitem(L; "LT QAW Line")
        {
            column(HeaderNo; "Header No.") { }
            column(LineNo; "Line No.")
            {
                ColumnFilter = LineNo = filter(> 10 & < 40);
            }
            column(ContactNo; "Contact No.") { }
            filter(KindF; Kind)
            {
                ColumnFilter = KindF = const(1);
            }
        }
    }
}

query 75100 "LT QCF Table Filter"
{
    QueryType = Normal;
    OrderBy = ascending(HeaderNo), ascending(LineNo);

    elements
    {
        dataitem(L; "LT QAW Line")
        {
            DataItemTableFilter = "Contact No." = const('C1');
            column(HeaderNo; "Header No.") { }
            column(LineNo; "Line No.") { }
            column(ContactNo; "Contact No.") { }
        }
    }
}

query 75101 "LT QCF Count Filter"
{
    QueryType = Normal;
    OrderBy = ascending(HeaderNo);

    elements
    {
        dataitem(L; "LT QAW Line")
        {
            column(HeaderNo; "Header No.") { }
            column(Qty)
            {
                Method = Count;
                ColumnFilter = Qty = filter(> 1);
            }
        }
    }
}

codeunit 75102 "LT QCF ColumnFilter GetFilter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Add(HeaderNo: Code[10]; LineNo: Integer; ContactNo: Code[10]; Kind: Integer)
    var
        Line: Record "LT QAW Line";
    begin
        Line.Init();
        Line."Header No." := HeaderNo;
        Line."Line No." := LineNo;
        Line."Contact No." := ContactNo;
        Line.Kind := Kind;
        Line.Insert();
    end;

    local procedure Seed()
    var
        Line: Record "LT QAW Line";
    begin
        Line.DeleteAll();
        Add('H1', 10, 'C1', 1);
        Add('H1', 20, 'C1', 1);
        Add('H1', 30, 'C1', 2);
        Add('H1', 40, 'C2', 1);
        Add('H2', 10, 'C1', 1);
    end;

    local procedure ConstRows(var Q: Query "LT QCF Column Const"): Text
    var
        Rows: Text;
    begin
        Q.Open();
        while Q.Read() do
            Rows += Q.HeaderNo + '/' + Format(Q.LineNo) + '/' + Q.ContactNo + ' ';
        Q.Close();
        exit(Rows);
    end;

    local procedure ConstState(var Q: Query "LT QCF Column Const"): Text
    begin
        exit('GetFilter(ContactNo)=[' + Q.GetFilter(ContactNo) + '] GetFilters=[' + Q.GetFilters() + ']');
    end;

    [Test]
    procedure ColumnFilterConst_GetFilter_Lifecycle()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QCF Column Const";
    begin
        Seed();
        Observer.Observe('fresh', ConstState(Q));
        Observer.Observe('other columns', 'GetFilter(HeaderNo)=[' + Q.GetFilter(HeaderNo) + '] GetFilter(LineNo)=[' + Q.GetFilter(LineNo) + ']');
        Q.Open();
        Observer.Observe('after Open', ConstState(Q));
        Observer.Observe('Read', Format(Q.Read()));
        Observer.Observe('after Read', ConstState(Q));
        Q.Close();
        Observer.Observe('after Close', ConstState(Q));
        Observer.Observe('rows', ConstRows(Q));
        Observer.Expect('fresh', 'GetFilter(ContactNo)=[C1] GetFilters=[Contact No.: C1]');
        Observer.Expect('other columns', 'GetFilter(HeaderNo)=[] GetFilter(LineNo)=[]');
        Observer.Expect('after Open', 'GetFilter(ContactNo)=[C1] GetFilters=[Contact No.: C1]');
        Observer.Expect('Read', 'Yes');
        Observer.Expect('after Read', 'GetFilter(ContactNo)=[C1] GetFilters=[Contact No.: C1]');
        Observer.Expect('after Close', 'GetFilter(ContactNo)=[C1] GetFilters=[Contact No.: C1]');
        Observer.Expect('rows', 'H1/10/C1 H1/20/C1 H1/30/C1 H2/10/C1 ');
        Observer.Verify();
    end;

    [Test]
    procedure ColumnFilterConst_RuntimeFilters()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QCF Column Const";
    begin
        Seed();
        Q.SetRange(HeaderNo, 'H1');
        Observer.Observe('SetRange on another column', ConstState(Q));
        Observer.Observe('SetRange on another column rows', ConstRows(Q));
        Q.SetRange(ContactNo, 'C2');
        Observer.Observe('SetRange C2 on the column', ConstState(Q));
        Observer.Observe('SetRange C2 on the column rows', ConstRows(Q));
        Q.SetFilter(ContactNo, 'C1|C2');
        Observer.Observe('SetFilter C1|C2 on the column', ConstState(Q));
        Observer.Observe('SetFilter C1|C2 on the column rows', ConstRows(Q));
        Observer.Expect('SetRange on another column', 'GetFilter(ContactNo)=[C1] GetFilters=[Header No.: H1, Contact No.: C1]');
        Observer.Expect('SetRange on another column rows', 'H1/10/C1 H1/20/C1 H1/30/C1 ');
        Observer.Expect('SetRange C2 on the column', 'GetFilter(ContactNo)=[C2] GetFilters=[Header No.: H1, Contact No.: C2]');
        Observer.Expect('SetRange C2 on the column rows', 'H1/40/C2 ');
        Observer.Expect('SetFilter C1|C2 on the column', 'GetFilter(ContactNo)=[C1|C2] GetFilters=[Header No.: H1, Contact No.: C1|C2]');
        Observer.Expect('SetFilter C1|C2 on the column rows', 'H1/10/C1 H1/20/C1 H1/30/C1 H1/40/C2 ');
        Observer.Verify();
    end;

    [Test]
    procedure ColumnFilterConst_RuntimeFilterRemoved()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QCF Column Const";
    begin
        Seed();
        Q.SetRange(HeaderNo, 'H1');
        Q.SetFilter(ContactNo, 'C1|C2');
        Q.SetRange(ContactNo);
        Observer.Observe('SetRange without a value on the column', ConstState(Q));
        Observer.Observe('SetRange without a value on the column rows', ConstRows(Q));
        Q.SetFilter(ContactNo, '');
        Observer.Observe('SetFilter blank on the column', ConstState(Q));
        Observer.Observe('SetFilter blank on the column rows', ConstRows(Q));
        Q.SetRange(HeaderNo);
        Observer.Observe('all runtime filters removed', ConstState(Q));
        Observer.Observe('all runtime filters removed rows', ConstRows(Q));
        Clear(Q);
        Observer.Observe('after Clear', ConstState(Q));
        Observer.Expect('SetRange without a value on the column', 'GetFilter(ContactNo)=[] GetFilters=[Header No.: H1]');
        Observer.Expect('SetRange without a value on the column rows', 'H1/10/C1 H1/20/C1 H1/30/C1 H1/40/C2 ');
        Observer.Expect('SetFilter blank on the column', 'GetFilter(ContactNo)=[] GetFilters=[Header No.: H1]');
        Observer.Expect('SetFilter blank on the column rows', 'H1/10/C1 H1/20/C1 H1/30/C1 H1/40/C2 ');
        Observer.Expect('all runtime filters removed', 'GetFilter(ContactNo)=[] GetFilters=[]');
        Observer.Expect('all runtime filters removed rows', 'H1/10/C1 H1/20/C1 H1/30/C1 H1/40/C2 H2/10/C1 ');
        Observer.Expect('after Clear', 'GetFilter(ContactNo)=[C1] GetFilters=[Contact No.: C1]');
        Observer.Verify();
    end;

    local procedure ExprRows(var Q: Query "LT QCF Column Expr"): Text
    var
        Rows: Text;
    begin
        Q.Open();
        while Q.Read() do
            Rows += Q.HeaderNo + '/' + Format(Q.LineNo) + '/' + Q.ContactNo + ' ';
        Q.Close();
        exit(Rows);
    end;

    local procedure ExprState(var Q: Query "LT QCF Column Expr"): Text
    begin
        exit('GetFilter(LineNo)=[' + Q.GetFilter(LineNo) + '] GetFilter(KindF)=[' + Q.GetFilter(KindF) + '] GetFilters=[' + Q.GetFilters() + ']');
    end;

    [Test]
    procedure ColumnFilterExpression_AndFilterElement()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QCF Column Expr";
    begin
        Seed();
        Observer.Observe('fresh', ExprState(Q));
        Observer.Observe('fresh rows', ExprRows(Q));
        Q.SetFilter(LineNo, '>=10');
        Observer.Observe('SetFilter >=10 on the column', ExprState(Q));
        Observer.Observe('SetFilter >=10 on the column rows', ExprRows(Q));
        Q.SetRange(KindF, 2);
        Observer.Observe('SetRange 2 on the filter element', ExprState(Q));
        Observer.Observe('SetRange 2 on the filter element rows', ExprRows(Q));
        Q.SetRange(LineNo);
        Q.SetRange(KindF);
        Observer.Observe('runtime filters removed', ExprState(Q));
        Observer.Observe('runtime filters removed rows', ExprRows(Q));
        Observer.Expect('fresh', 'GetFilter(LineNo)=[>10&<40] GetFilter(KindF)=[1] GetFilters=[Kind: 1, Line No.: >10&<40]');
        Observer.Expect('fresh rows', 'H1/20/C1 ');
        Observer.Expect('SetFilter >=10 on the column', 'GetFilter(LineNo)=[>=10] GetFilter(KindF)=[1] GetFilters=[Kind: 1, Line No.: >=10]');
        Observer.Expect('SetFilter >=10 on the column rows', 'H1/10/C1 H1/20/C1 H1/40/C2 H2/10/C1 ');
        Observer.Expect('SetRange 2 on the filter element', 'GetFilter(LineNo)=[>=10] GetFilter(KindF)=[2] GetFilters=[Kind: 2, Line No.: >=10]');
        Observer.Expect('SetRange 2 on the filter element rows', 'H1/30/C1 ');
        Observer.Expect('runtime filters removed', 'GetFilter(LineNo)=[] GetFilter(KindF)=[] GetFilters=[]');
        Observer.Expect('runtime filters removed rows', 'H1/10/C1 H1/20/C1 H1/30/C1 H1/40/C2 H2/10/C1 ');
        Observer.Verify();
    end;

    local procedure TableRows(var Q: Query "LT QCF Table Filter"): Text
    var
        Rows: Text;
    begin
        Q.Open();
        while Q.Read() do
            Rows += Q.HeaderNo + '/' + Format(Q.LineNo) + '/' + Q.ContactNo + ' ';
        Q.Close();
        exit(Rows);
    end;

    local procedure TableState(var Q: Query "LT QCF Table Filter"): Text
    begin
        exit('GetFilter(ContactNo)=[' + Q.GetFilter(ContactNo) + '] GetFilters=[' + Q.GetFilters() + ']');
    end;

    [Test]
    procedure DataItemTableFilter_GetFilter()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QCF Table Filter";
    begin
        Seed();
        Observer.Observe('fresh', TableState(Q));
        Observer.Observe('fresh rows', TableRows(Q));
        Q.SetRange(ContactNo, 'C2');
        Observer.Observe('SetRange C2 on the column', TableState(Q));
        Observer.Observe('SetRange C2 on the column rows', TableRows(Q));
        Q.SetRange(ContactNo);
        Observer.Observe('runtime filter removed', TableState(Q));
        Observer.Observe('runtime filter removed rows', TableRows(Q));
        Observer.Expect('fresh', 'GetFilter(ContactNo)=[] GetFilters=[]');
        Observer.Expect('fresh rows', 'H1/10/C1 H1/20/C1 H1/30/C1 H2/10/C1 ');
        Observer.Expect('SetRange C2 on the column', 'GetFilter(ContactNo)=[C2] GetFilters=[Contact No.: C2]');
        Observer.Expect('SetRange C2 on the column rows', '');
        Observer.Expect('runtime filter removed', 'GetFilter(ContactNo)=[] GetFilters=[]');
        Observer.Expect('runtime filter removed rows', 'H1/10/C1 H1/20/C1 H1/30/C1 H2/10/C1 ');
        Observer.Verify();
    end;

    local procedure CountRows(var Q: Query "LT QCF Count Filter"): Text
    var
        Rows: Text;
    begin
        Q.Open();
        while Q.Read() do
            Rows += Q.HeaderNo + '=' + Format(Q.Qty) + ' ';
        Q.Close();
        exit(Rows);
    end;

    local procedure CountState(var Q: Query "LT QCF Count Filter"): Text
    begin
        exit('GetFilter(Qty)=[' + Q.GetFilter(Qty) + '] GetFilters=[' + Q.GetFilters() + ']');
    end;

    [Test]
    procedure CountColumnFilter_GetFilter()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QCF Count Filter";
    begin
        Seed();
        Observer.Observe('fresh', CountState(Q));
        Observer.Observe('fresh rows', CountRows(Q));
        Q.SetFilter(Qty, '>0');
        Observer.Observe('SetFilter >0 on the column', CountState(Q));
        Observer.Observe('SetFilter >0 on the column rows', CountRows(Q));
        Q.SetRange(Qty);
        Observer.Observe('runtime filter removed', CountState(Q));
        Observer.Observe('runtime filter removed rows', CountRows(Q));
        Observer.Expect('fresh', 'GetFilter(Qty)=[>1] GetFilters=[Qty: >1]');
        Observer.Expect('fresh rows', 'H1=4 ');
        Observer.Expect('SetFilter >0 on the column', 'GetFilter(Qty)=[>0] GetFilters=[Qty: >0]');
        Observer.Expect('SetFilter >0 on the column rows', 'H1=4 H2=1 ');
        Observer.Expect('runtime filter removed', 'GetFilter(Qty)=[] GetFilters=[]');
        Observer.Expect('runtime filter removed rows', 'H1=4 H2=1 ');
        Observer.Verify();
    end;
}
