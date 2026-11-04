// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own enum 95579, tables 95580 and 95581, test codeunit 95582
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced
//   (al-runner issue 6999: a where() clause whose constant is written with `::`).
// Facts: Validate of a field whose TableRelation has a where() clause with an enum-qualified const (`const("Enum"::Value)`), with the
//   const of a table number (`const(Database::"Table")`) and with a filter of two table numbers (`filter(Database::A | Database::B)`),
//   in the table form, the table.field form and inside an if/else chain: a value whose related row matches the where() is accepted, a
//   value whose row does not match and a value with no row give the error text and code observed.
// BC versions: 27, 28, 29

enum 95579 "LT R6 Rel Status"
{
    Extensible = true;

    value(0; Open) { }
    value(1; Certified) { }
    value(2; Closed) { }
}

table 95580 "LT R6 Rel Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Status; Enum "LT R6 Rel Status") { }
        field(3; TabNo; Integer) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 95581 "LT R6 Rel Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tmpl; Code[20])
        {
            TableRelation = "LT R6 Rel Header" where(Status = const("LT R6 Rel Status"::Certified));
        }
        field(3; DocNo; Code[20])
        {
            TableRelation = "LT R6 Rel Header"."Code" where(Status = const("LT R6 Rel Status"::Open));
        }
        field(4; TabConst; Code[20])
        {
            TableRelation = "LT R6 Rel Header"."Code" where(TabNo = const(Database::"LT R6 Rel Line"));
        }
        field(5; TabFilter; Code[20])
        {
            TableRelation = "LT R6 Rel Header"."Code" where(TabNo = filter(Database::"LT R6 Rel Line" | Database::"LT R6 Rel Header"));
        }
        field(6; Typ; Option)
        {
            OptionMembers = Option,Decimal,Other;
        }
        field(7; Feature; Code[20])
        {
            TableRelation = if (Typ = const(Option)) "LT R6 Rel Header"."Code" where(TabNo = const(Database::"LT R6 Rel Line"), Status = const(Certified))
            else
            if (Typ = const(Decimal)) "LT R6 Rel Header"."Code" where(TabNo = filter(Database::"LT R6 Rel Line" | Database::"LT R6 Rel Header"));
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 95582 "LT R6 Rel Qualified Const"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        H: Record "LT R6 Rel Header";
    begin
        H.DeleteAll();
        Add('CERT-LINE', H.Status::Certified, Database::"LT R6 Rel Line");
        Add('OPEN-HEAD', H.Status::Open, Database::"LT R6 Rel Header");
        Add('CLOSED-OTHER', H.Status::Closed, 18);
    end;

    local procedure Add(Code: Code[20]; Status: Enum "LT R6 Rel Status"; TabNo: Integer)
    var
        H: Record "LT R6 Rel Header";
    begin
        H."Code" := Code;
        H.Status := Status;
        H.TabNo := TabNo;
        H.Insert();
    end;

    [TryFunction]
    local procedure TryValidate(var L: Record "LT R6 Rel Line"; FieldNo: Integer; Value: Code[20])
    begin
        case FieldNo of
            2:
                L.Validate(Tmpl, Value);
            3:
                L.Validate(DocNo, Value);
            4:
                L.Validate(TabConst, Value);
            5:
                L.Validate(TabFilter, Value);
            7:
                L.Validate(Feature, Value);
        end;
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; var L: Record "LT R6 Rel Line"; Name: Text; FieldNo: Integer; Value: Code[20])
    begin
        ClearLastError();
        if TryValidate(L, FieldNo, Value) then
            Observer.Observe(Name, 'ok')
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure EnumConst()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "LT R6 Rel Line";
    begin
        Seed();
        Probe(Observer, L, 'table form, matching', 2, 'CERT-LINE');
        Probe(Observer, L, 'table form, other status', 2, 'OPEN-HEAD');
        Probe(Observer, L, 'table form, no row', 2, 'NONE');
        Probe(Observer, L, 'field form, matching', 3, 'OPEN-HEAD');
        Probe(Observer, L, 'field form, other status', 3, 'CERT-LINE');
        Probe(Observer, L, 'field form, blank', 3, '');
        Observer.Expect('table form, matching', 'ok');
        Observer.Expect('table form, other status', 'error:The field Tmpl of table LT R6 Rel Line contains a value (OPEN-HEAD) that cannot be found in the related table (LT R6 Rel Header).|DB:NothingInsideFilter');
        Observer.Expect('table form, no row', 'error:The field Tmpl of table LT R6 Rel Line contains a value (NONE) that cannot be found in the related table (LT R6 Rel Header).|DB:NothingInsideFilter');
        Observer.Expect('field form, matching', 'ok');
        Observer.Expect('field form, other status', 'error:The field DocNo of table LT R6 Rel Line contains a value (CERT-LINE) that cannot be found in the related table (LT R6 Rel Header).|DB:NothingInsideFilter');
        Observer.Expect('field form, blank', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure DatabaseConstAndFilter()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "LT R6 Rel Line";
    begin
        Seed();
        Probe(Observer, L, 'const, matching', 4, 'CERT-LINE');
        Probe(Observer, L, 'const, other table', 4, 'OPEN-HEAD');
        Probe(Observer, L, 'filter, first table', 5, 'CERT-LINE');
        Probe(Observer, L, 'filter, second table', 5, 'OPEN-HEAD');
        Probe(Observer, L, 'filter, neither table', 5, 'CLOSED-OTHER');
        Observer.Expect('const, matching', 'ok');
        Observer.Expect('const, other table', 'error:The field TabConst of table LT R6 Rel Line contains a value (OPEN-HEAD) that cannot be found in the related table (LT R6 Rel Header).|DB:NothingInsideFilter');
        Observer.Expect('filter, first table', 'ok');
        Observer.Expect('filter, second table', 'ok');
        Observer.Expect('filter, neither table', 'error:The field TabFilter of table LT R6 Rel Line contains a value (CLOSED-OTHER) that cannot be found in the related table (LT R6 Rel Header).|DB:NothingInsideFilter');
        Observer.Verify();
    end;

    [Test]
    procedure ConditionalChain()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "LT R6 Rel Line";
    begin
        Seed();
        L.Typ := L.Typ::Option;
        Probe(Observer, L, 'option arm, matching', 7, 'CERT-LINE');
        Probe(Observer, L, 'option arm, other table', 7, 'OPEN-HEAD');
        L.Typ := L.Typ::Decimal;
        Probe(Observer, L, 'decimal arm, second table', 7, 'OPEN-HEAD');
        Probe(Observer, L, 'decimal arm, neither table', 7, 'CLOSED-OTHER');
        L.Typ := L.Typ::Other;
        Probe(Observer, L, 'no arm applies', 7, 'ANYTHING');
        Observer.Expect('option arm, matching', 'ok');
        Observer.Expect('option arm, other table', 'error:The field Feature of table LT R6 Rel Line contains a value (OPEN-HEAD) that cannot be found in the related table (LT R6 Rel Header).|DB:NothingInsideFilter');
        Observer.Expect('decimal arm, second table', 'ok');
        Observer.Expect('decimal arm, neither table', 'error:The field Feature of table LT R6 Rel Line contains a value (CLOSED-OTHER) that cannot be found in the related table (LT R6 Rel Header).|DB:NothingInsideFilter');
        Observer.Expect('no arm applies', 'ok');
        Observer.Verify();
    end;
}
