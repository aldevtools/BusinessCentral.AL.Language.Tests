// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 75087-75090, queries 75091-75096, test codeunit 75097
// local object: the FlowFields (Lookup, Count, Exist) of the third data item of a join chain are the subject of the probe; no shared fixture has them
// Probe (observe only): al-runner issue 7401 (follow-up to 6990). QueryOuterFlowFilters.al and QueryOuterFlowKinds.al pin a filter() element and a
//   column over a FlowField of a data item joined directly below the top data item. This probe asks the same one level deeper:
//   Contact > Line > Header, with the FlowFields on Header, for the join types
//     Inner Outer   Line InnerJoin, Header LeftOuterJoin (the reported chain)
//     Outer Outer   Line LeftOuterJoin, Header LeftOuterJoin
//     Default       no SqlJoinType on either
//     Inner Inner   both InnerJoin (control)
//   each as filter() elements over the Lookup, Count and Exist FlowFields (SetFilter and SetRange on them, then the rows) and, for the first two,
//   as plain columns over them (values, and SetRange on the column). The queries are global variables of the test codeunit, as in the report.
//   Rows: contact C1 has line 1 (header H1), line 2 (header H2) and line 3 (header H9, which does not exist); C2 has line 4 (header H3);
//   C3 has no line. Header H1 has customer K1 (Alpha), H2 has K2 (Beta), H3 has K9 (no such customer), H4 has no line.
//   "Customer Name" = lookup(Customer.Name), "Line Count" = count(Line where Header No.), "Has Customer" = exist(Customer).
//   A row is observed as contact/line/header, with [name|count|has] for the column queries.
// BC versions: 27, 28, 29

table 75087 "LT QOJ Contact"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 75088 "LT QOJ Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; "Contact No."; Code[10]) { }
        field(3; "Header No."; Code[10]) { }
    }
    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}

table 75089 "LT QOJ Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; "Customer No."; Code[10]) { }
        field(10; "Customer Name"; Text[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT QOJ Customer".Name where("No." = field("Customer No.")));
            Editable = false;
        }
        field(11; "Line Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT QOJ Line" where("Header No." = field("No.")));
            Editable = false;
        }
        field(12; "Has Customer"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("LT QOJ Customer" where("No." = field("Customer No.")));
            Editable = false;
        }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 75090 "LT QOJ Customer"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

query 75091 "LT QOJ Inner Outer Filter"
{
    QueryType = Normal;
    OrderBy = ascending(ContactNo), ascending(LineNo);

    elements
    {
        dataitem(Contact; "LT QOJ Contact")
        {
            column(ContactNo; "No.") { }

            dataitem(Line; "LT QOJ Line")
            {
                DataItemLink = "Contact No." = Contact."No.";
                SqlJoinType = InnerJoin;
                column(LineNo; "Line No.") { }

                dataitem(Hdr; "LT QOJ Header")
                {
                    DataItemLink = "No." = Line."Header No.";
                    SqlJoinType = LeftOuterJoin;
                    column(HdrNo; "No.") { }
                    filter(Hdr_Customer_Name; "Customer Name") { }
                    filter(Hdr_Line_Count; "Line Count") { }
                    filter(Hdr_Has_Customer; "Has Customer") { }
                }
            }
        }
    }
}

query 75092 "LT QOJ Inner Outer Column"
{
    QueryType = Normal;
    OrderBy = ascending(ContactNo), ascending(LineNo);

    elements
    {
        dataitem(Contact; "LT QOJ Contact")
        {
            column(ContactNo; "No.") { }

            dataitem(Line; "LT QOJ Line")
            {
                DataItemLink = "Contact No." = Contact."No.";
                SqlJoinType = InnerJoin;
                column(LineNo; "Line No.") { }

                dataitem(Hdr; "LT QOJ Header")
                {
                    DataItemLink = "No." = Line."Header No.";
                    SqlJoinType = LeftOuterJoin;
                    column(HdrNo; "No.") { }
                    column(Hdr_Customer_Name; "Customer Name") { }
                    column(Hdr_Line_Count; "Line Count") { }
                    column(Hdr_Has_Customer; "Has Customer") { }
                }
            }
        }
    }
}

query 75093 "LT QOJ Outer Outer Filter"
{
    QueryType = Normal;
    OrderBy = ascending(ContactNo), ascending(LineNo);

    elements
    {
        dataitem(Contact; "LT QOJ Contact")
        {
            column(ContactNo; "No.") { }

            dataitem(Line; "LT QOJ Line")
            {
                DataItemLink = "Contact No." = Contact."No.";
                SqlJoinType = LeftOuterJoin;
                column(LineNo; "Line No.") { }

                dataitem(Hdr; "LT QOJ Header")
                {
                    DataItemLink = "No." = Line."Header No.";
                    SqlJoinType = LeftOuterJoin;
                    column(HdrNo; "No.") { }
                    filter(Hdr_Customer_Name; "Customer Name") { }
                    filter(Hdr_Line_Count; "Line Count") { }
                    filter(Hdr_Has_Customer; "Has Customer") { }
                }
            }
        }
    }
}

query 75094 "LT QOJ Outer Outer Column"
{
    QueryType = Normal;
    OrderBy = ascending(ContactNo), ascending(LineNo);

    elements
    {
        dataitem(Contact; "LT QOJ Contact")
        {
            column(ContactNo; "No.") { }

            dataitem(Line; "LT QOJ Line")
            {
                DataItemLink = "Contact No." = Contact."No.";
                SqlJoinType = LeftOuterJoin;
                column(LineNo; "Line No.") { }

                dataitem(Hdr; "LT QOJ Header")
                {
                    DataItemLink = "No." = Line."Header No.";
                    SqlJoinType = LeftOuterJoin;
                    column(HdrNo; "No.") { }
                    column(Hdr_Customer_Name; "Customer Name") { }
                    column(Hdr_Line_Count; "Line Count") { }
                    column(Hdr_Has_Customer; "Has Customer") { }
                }
            }
        }
    }
}

query 75095 "LT QOJ Default Filter"
{
    QueryType = Normal;
    OrderBy = ascending(ContactNo), ascending(LineNo);

    elements
    {
        dataitem(Contact; "LT QOJ Contact")
        {
            column(ContactNo; "No.") { }

            dataitem(Line; "LT QOJ Line")
            {
                DataItemLink = "Contact No." = Contact."No.";
                column(LineNo; "Line No.") { }

                dataitem(Hdr; "LT QOJ Header")
                {
                    DataItemLink = "No." = Line."Header No.";
                    column(HdrNo; "No.") { }
                    filter(Hdr_Customer_Name; "Customer Name") { }
                    filter(Hdr_Line_Count; "Line Count") { }
                    filter(Hdr_Has_Customer; "Has Customer") { }
                }
            }
        }
    }
}

query 75096 "LT QOJ Inner Inner Filter"
{
    QueryType = Normal;
    OrderBy = ascending(ContactNo), ascending(LineNo);

    elements
    {
        dataitem(Contact; "LT QOJ Contact")
        {
            column(ContactNo; "No.") { }

            dataitem(Line; "LT QOJ Line")
            {
                DataItemLink = "Contact No." = Contact."No.";
                SqlJoinType = InnerJoin;
                column(LineNo; "Line No.") { }

                dataitem(Hdr; "LT QOJ Header")
                {
                    DataItemLink = "No." = Line."Header No.";
                    SqlJoinType = InnerJoin;
                    column(HdrNo; "No.") { }
                    filter(Hdr_Customer_Name; "Customer Name") { }
                    filter(Hdr_Line_Count; "Line Count") { }
                    filter(Hdr_Has_Customer; "Has Customer") { }
                }
            }
        }
    }
}

codeunit 75097 "LT QOJ Outer Flow Below Join"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        QInnerOuterF: Query "LT QOJ Inner Outer Filter";
        QInnerOuterC: Query "LT QOJ Inner Outer Column";
        QOuterOuterF: Query "LT QOJ Outer Outer Filter";
        QOuterOuterC: Query "LT QOJ Outer Outer Column";
        QDefaultF: Query "LT QOJ Default Filter";
        QInnerInnerF: Query "LT QOJ Inner Inner Filter";

    local procedure AddLine(LineNo: Integer; ContactNo: Code[10]; HeaderNo: Code[10])
    var
        Line: Record "LT QOJ Line";
    begin
        Line.Init();
        Line."Line No." := LineNo;
        Line."Contact No." := ContactNo;
        Line."Header No." := HeaderNo;
        Line.Insert();
    end;

    local procedure AddHeader(No: Code[10]; CustomerNo: Code[10])
    var
        Header: Record "LT QOJ Header";
    begin
        Header.Init();
        Header."No." := No;
        Header."Customer No." := CustomerNo;
        Header.Insert();
    end;

    local procedure Seed()
    var
        Contact: Record "LT QOJ Contact";
        Line: Record "LT QOJ Line";
        Header: Record "LT QOJ Header";
        Customer: Record "LT QOJ Customer";
    begin
        Contact.DeleteAll();
        Line.DeleteAll();
        Header.DeleteAll();
        Customer.DeleteAll();
        Contact."No." := 'C1';
        Contact.Insert();
        Contact."No." := 'C2';
        Contact.Insert();
        Contact."No." := 'C3';
        Contact.Insert();
        AddLine(1, 'C1', 'H1');
        AddLine(2, 'C1', 'H2');
        AddLine(3, 'C1', 'H9');
        AddLine(4, 'C2', 'H3');
        AddHeader('H1', 'K1');
        AddHeader('H2', 'K2');
        AddHeader('H3', 'K9');
        AddHeader('H4', 'K1');
        Customer."No." := 'K1';
        Customer.Name := 'Alpha';
        Customer.Insert();
        Customer."No." := 'K2';
        Customer.Name := 'Beta';
        Customer.Insert();
    end;

    [TryFunction]
    local procedure TryRows_QInnerOuterF(Step: Integer; var Rows: Text)
    begin
        Clear(QInnerOuterF);
        case Step of
            1:
                ;
            2:
                QInnerOuterF.SetFilter(Hdr_Customer_Name, 'Alpha');
            3:
                QInnerOuterF.SetRange(Hdr_Customer_Name, '');
            4:
                QInnerOuterF.SetFilter(Hdr_Customer_Name, '<>Alpha');
            5:
                QInnerOuterF.SetFilter(Hdr_Customer_Name, '@*a');
            6:
                QInnerOuterF.SetRange(Hdr_Line_Count, 1);
            7:
                QInnerOuterF.SetRange(Hdr_Line_Count, 0);
            8:
                QInnerOuterF.SetFilter(Hdr_Line_Count, '>0');
            9:
                QInnerOuterF.SetRange(Hdr_Has_Customer, true);
            10:
                QInnerOuterF.SetRange(Hdr_Has_Customer, false);
            11:
                begin
                    QInnerOuterF.SetFilter(Hdr_Customer_Name, 'Alpha|Beta');
                    QInnerOuterF.SetRange(ContactNo, 'C1');
                end;
        end;
        Rows := 'filters [' + QInnerOuterF.GetFilters() + '] rows ';
        QInnerOuterF.Open();
        while QInnerOuterF.Read() do
            Rows += QInnerOuterF.ContactNo + '/' + Format(QInnerOuterF.LineNo) + '/' + QInnerOuterF.HdrNo + ' ';
        QInnerOuterF.Close();
    end;

    [TryFunction]
    local procedure TryRows_QInnerOuterC(Step: Integer; var Rows: Text)
    begin
        Clear(QInnerOuterC);
        case Step of
            1:
                ;
            2:
                QInnerOuterC.SetFilter(Hdr_Customer_Name, 'Alpha');
            3:
                QInnerOuterC.SetRange(Hdr_Customer_Name, '');
            4:
                QInnerOuterC.SetFilter(Hdr_Customer_Name, '<>Alpha');
            5:
                QInnerOuterC.SetFilter(Hdr_Customer_Name, '@*a');
            6:
                QInnerOuterC.SetRange(Hdr_Line_Count, 1);
            7:
                QInnerOuterC.SetRange(Hdr_Line_Count, 0);
            8:
                QInnerOuterC.SetFilter(Hdr_Line_Count, '>0');
            9:
                QInnerOuterC.SetRange(Hdr_Has_Customer, true);
            10:
                QInnerOuterC.SetRange(Hdr_Has_Customer, false);
            11:
                begin
                    QInnerOuterC.SetFilter(Hdr_Customer_Name, 'Alpha|Beta');
                    QInnerOuterC.SetRange(ContactNo, 'C1');
                end;
        end;
        Rows := 'filters [' + QInnerOuterC.GetFilters() + '] rows ';
        QInnerOuterC.Open();
        while QInnerOuterC.Read() do
            Rows += QInnerOuterC.ContactNo + '/' + Format(QInnerOuterC.LineNo) + '/' + QInnerOuterC.HdrNo + '[' + QInnerOuterC.Hdr_Customer_Name + '|' + Format(QInnerOuterC.Hdr_Line_Count) + '|' + Format(QInnerOuterC.Hdr_Has_Customer) + ']' + ' ';
        QInnerOuterC.Close();
    end;

    [TryFunction]
    local procedure TryRows_QOuterOuterF(Step: Integer; var Rows: Text)
    begin
        Clear(QOuterOuterF);
        case Step of
            1:
                ;
            2:
                QOuterOuterF.SetFilter(Hdr_Customer_Name, 'Alpha');
            3:
                QOuterOuterF.SetRange(Hdr_Customer_Name, '');
            4:
                QOuterOuterF.SetFilter(Hdr_Customer_Name, '<>Alpha');
            5:
                QOuterOuterF.SetFilter(Hdr_Customer_Name, '@*a');
            6:
                QOuterOuterF.SetRange(Hdr_Line_Count, 1);
            7:
                QOuterOuterF.SetRange(Hdr_Line_Count, 0);
            8:
                QOuterOuterF.SetFilter(Hdr_Line_Count, '>0');
            9:
                QOuterOuterF.SetRange(Hdr_Has_Customer, true);
            10:
                QOuterOuterF.SetRange(Hdr_Has_Customer, false);
            11:
                begin
                    QOuterOuterF.SetFilter(Hdr_Customer_Name, 'Alpha|Beta');
                    QOuterOuterF.SetRange(ContactNo, 'C1');
                end;
        end;
        Rows := 'filters [' + QOuterOuterF.GetFilters() + '] rows ';
        QOuterOuterF.Open();
        while QOuterOuterF.Read() do
            Rows += QOuterOuterF.ContactNo + '/' + Format(QOuterOuterF.LineNo) + '/' + QOuterOuterF.HdrNo + ' ';
        QOuterOuterF.Close();
    end;

    [TryFunction]
    local procedure TryRows_QOuterOuterC(Step: Integer; var Rows: Text)
    begin
        Clear(QOuterOuterC);
        case Step of
            1:
                ;
            2:
                QOuterOuterC.SetFilter(Hdr_Customer_Name, 'Alpha');
            3:
                QOuterOuterC.SetRange(Hdr_Customer_Name, '');
            4:
                QOuterOuterC.SetFilter(Hdr_Customer_Name, '<>Alpha');
            5:
                QOuterOuterC.SetFilter(Hdr_Customer_Name, '@*a');
            6:
                QOuterOuterC.SetRange(Hdr_Line_Count, 1);
            7:
                QOuterOuterC.SetRange(Hdr_Line_Count, 0);
            8:
                QOuterOuterC.SetFilter(Hdr_Line_Count, '>0');
            9:
                QOuterOuterC.SetRange(Hdr_Has_Customer, true);
            10:
                QOuterOuterC.SetRange(Hdr_Has_Customer, false);
            11:
                begin
                    QOuterOuterC.SetFilter(Hdr_Customer_Name, 'Alpha|Beta');
                    QOuterOuterC.SetRange(ContactNo, 'C1');
                end;
        end;
        Rows := 'filters [' + QOuterOuterC.GetFilters() + '] rows ';
        QOuterOuterC.Open();
        while QOuterOuterC.Read() do
            Rows += QOuterOuterC.ContactNo + '/' + Format(QOuterOuterC.LineNo) + '/' + QOuterOuterC.HdrNo + '[' + QOuterOuterC.Hdr_Customer_Name + '|' + Format(QOuterOuterC.Hdr_Line_Count) + '|' + Format(QOuterOuterC.Hdr_Has_Customer) + ']' + ' ';
        QOuterOuterC.Close();
    end;

    [TryFunction]
    local procedure TryRows_QDefaultF(Step: Integer; var Rows: Text)
    begin
        Clear(QDefaultF);
        case Step of
            1:
                ;
            2:
                QDefaultF.SetFilter(Hdr_Customer_Name, 'Alpha');
            3:
                QDefaultF.SetRange(Hdr_Customer_Name, '');
            4:
                QDefaultF.SetFilter(Hdr_Customer_Name, '<>Alpha');
            5:
                QDefaultF.SetFilter(Hdr_Customer_Name, '@*a');
            6:
                QDefaultF.SetRange(Hdr_Line_Count, 1);
            7:
                QDefaultF.SetRange(Hdr_Line_Count, 0);
            8:
                QDefaultF.SetFilter(Hdr_Line_Count, '>0');
            9:
                QDefaultF.SetRange(Hdr_Has_Customer, true);
            10:
                QDefaultF.SetRange(Hdr_Has_Customer, false);
            11:
                begin
                    QDefaultF.SetFilter(Hdr_Customer_Name, 'Alpha|Beta');
                    QDefaultF.SetRange(ContactNo, 'C1');
                end;
        end;
        Rows := 'filters [' + QDefaultF.GetFilters() + '] rows ';
        QDefaultF.Open();
        while QDefaultF.Read() do
            Rows += QDefaultF.ContactNo + '/' + Format(QDefaultF.LineNo) + '/' + QDefaultF.HdrNo + ' ';
        QDefaultF.Close();
    end;

    [TryFunction]
    local procedure TryRows_QInnerInnerF(Step: Integer; var Rows: Text)
    begin
        Clear(QInnerInnerF);
        case Step of
            1:
                ;
            2:
                QInnerInnerF.SetFilter(Hdr_Customer_Name, 'Alpha');
            3:
                QInnerInnerF.SetRange(Hdr_Customer_Name, '');
            4:
                QInnerInnerF.SetFilter(Hdr_Customer_Name, '<>Alpha');
            5:
                QInnerInnerF.SetFilter(Hdr_Customer_Name, '@*a');
            6:
                QInnerInnerF.SetRange(Hdr_Line_Count, 1);
            7:
                QInnerInnerF.SetRange(Hdr_Line_Count, 0);
            8:
                QInnerInnerF.SetFilter(Hdr_Line_Count, '>0');
            9:
                QInnerInnerF.SetRange(Hdr_Has_Customer, true);
            10:
                QInnerInnerF.SetRange(Hdr_Has_Customer, false);
            11:
                begin
                    QInnerInnerF.SetFilter(Hdr_Customer_Name, 'Alpha|Beta');
                    QInnerInnerF.SetRange(ContactNo, 'C1');
                end;
        end;
        Rows := 'filters [' + QInnerInnerF.GetFilters() + '] rows ';
        QInnerInnerF.Open();
        while QInnerInnerF.Read() do
            Rows += QInnerInnerF.ContactNo + '/' + Format(QInnerInnerF.LineNo) + '/' + QInnerInnerF.HdrNo + ' ';
        QInnerInnerF.Close();
    end;

    local procedure StepName(Step: Integer): Text
    begin
        case Step of
            1:
                exit('no filter');
            2:
                exit('name Alpha');
            3:
                exit('name blank');
            4:
                exit('name <>Alpha');
            5:
                exit('name @*a');
            6:
                exit('count 1');
            7:
                exit('count 0');
            8:
                exit('count >0');
            9:
                exit('has customer true');
            10:
                exit('has customer false');
            11:
                exit('name Alpha|Beta and contact C1');
        end;
    end;

    local procedure Run(QueryNo: Integer; Step: Integer; var Rows: Text): Boolean
    begin
        case QueryNo of
            1:
                exit(TryRows_QInnerOuterF(Step, Rows));
            2:
                exit(TryRows_QInnerOuterC(Step, Rows));
            3:
                exit(TryRows_QOuterOuterF(Step, Rows));
            4:
                exit(TryRows_QOuterOuterC(Step, Rows));
            5:
                exit(TryRows_QDefaultF(Step, Rows));
            6:
                exit(TryRows_QInnerInnerF(Step, Rows));
        end;
    end;

    local procedure ObserveSteps(var Observer: Codeunit "Probe Observer"; QueryNo: Integer; FromStep: Integer; ToStep: Integer)
    var
        Step: Integer;
        Rows: Text;
    begin
        Seed();
        for Step := FromStep to ToStep do begin
            Rows := '';
            ClearLastError();
            if Run(QueryNo, Step, Rows) then
                Observer.Observe(StepName(Step), Rows)
            else
                Observer.ObserveError(StepName(Step));
        end;
    end;

    [Test]
    procedure InnerThenLeftOuter_FilterElements_NameFilters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSteps(Observer, 1, 1, 5);
        Observer.Finish();
    end;

    [Test]
    procedure InnerThenLeftOuter_FilterElements_CountAndExistFilters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSteps(Observer, 1, 6, 11);
        Observer.Finish();
    end;

    [Test]
    procedure InnerThenLeftOuter_Columns_NameFilters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSteps(Observer, 2, 1, 5);
        Observer.Finish();
    end;

    [Test]
    procedure InnerThenLeftOuter_Columns_CountAndExistFilters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSteps(Observer, 2, 6, 11);
        Observer.Finish();
    end;

    [Test]
    procedure LeftOuterThenLeftOuter_FilterElements_NameFilters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSteps(Observer, 3, 1, 5);
        Observer.Finish();
    end;

    [Test]
    procedure LeftOuterThenLeftOuter_FilterElements_CountAndExistFilters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSteps(Observer, 3, 6, 11);
        Observer.Finish();
    end;

    [Test]
    procedure LeftOuterThenLeftOuter_Columns_NameFilters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSteps(Observer, 4, 1, 5);
        Observer.Finish();
    end;

    [Test]
    procedure LeftOuterThenLeftOuter_Columns_CountAndExistFilters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSteps(Observer, 4, 6, 11);
        Observer.Finish();
    end;

    [Test]
    procedure DefaultJoins_FilterElements_NameFilters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSteps(Observer, 5, 1, 5);
        Observer.Finish();
    end;

    [Test]
    procedure DefaultJoins_FilterElements_CountAndExistFilters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSteps(Observer, 5, 6, 11);
        Observer.Finish();
    end;

    [Test]
    procedure InnerThenInner_FilterElements_Control_NameFilters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSteps(Observer, 6, 1, 5);
        Observer.Finish();
    end;

    [Test]
    procedure InnerThenInner_FilterElements_Control_CountAndExistFilters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSteps(Observer, 6, 6, 11);
        Observer.Finish();
    end;
}
