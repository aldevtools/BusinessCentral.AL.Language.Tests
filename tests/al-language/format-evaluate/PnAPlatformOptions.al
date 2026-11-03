// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldtype/fieldtype-option
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Platform options: FieldType and IsolationLevel member lists and ordinals
// Facts: ordinals and names of FieldType and IsolationLevel members through Format numbers 0, 1, 2, and Evaluate into them
// BC versions: 29 (27 and 28 by CI)

codeunit 70119 "LT PnA PlatformOptions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Ft(var Observer: Codeunit "Probe Observer"; Name: Text; V: FieldType)
    begin
        Observer.Observe(Name, Format(V, 0, 0) + '|' + Format(V, 0, 1) + '|' + Format(V, 0, 2));
    end;

    local procedure Il(var Observer: Codeunit "Probe Observer"; Name: Text; V: IsolationLevel)
    begin
        Observer.Observe(Name, Format(V, 0, 0) + '|' + Format(V, 0, 1) + '|' + Format(V, 0, 2));
    end;

    [Test]
    procedure FieldType_Members_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Ft(Observer, 'TableFilter', FieldType::TableFilter);
        Ft(Observer, 'RecordID', FieldType::RecordID);
        Ft(Observer, 'Date', FieldType::Date);
        Ft(Observer, 'Time', FieldType::Time);
        Ft(Observer, 'DateFormula', FieldType::DateFormula);
        Ft(Observer, 'Decimal', FieldType::Decimal);
        Ft(Observer, 'Media', FieldType::Media);
        Ft(Observer, 'MediaSet', FieldType::MediaSet);
        Ft(Observer, 'Text', FieldType::Text);
        Ft(Observer, 'Code', FieldType::Code);
        Observer.Expect('TableFilter', 'TableFilter|TableFilter|TableFilter');
        Observer.Expect('RecordID', 'RecordID|RecordID|RecordID');
        Observer.Expect('Date', 'Date|Date|Date');
        Observer.Expect('Time', 'Time|Time|Time');
        Observer.Expect('DateFormula', 'DateFormula|DateFormula|DateFormula');
        Observer.Expect('Decimal', 'Decimal|Decimal|Decimal');
        Observer.Expect('Media', 'Media|Media|Media');
        Observer.Expect('MediaSet', 'MediaSet|MediaSet|MediaSet');
        Observer.Expect('Text', 'Text|Text|Text');
        Observer.Expect('Code', 'Code|Code|Code');
        Observer.Verify();
    end;

    [Test]
    procedure FieldType_Members_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Ft(Observer, 'BLOB', FieldType::BLOB);
        Ft(Observer, 'Boolean', FieldType::Boolean);
        Ft(Observer, 'Integer', FieldType::Integer);
        Ft(Observer, 'Option', FieldType::Option);
        Ft(Observer, 'BigInteger', FieldType::BigInteger);
        Ft(Observer, 'Duration', FieldType::Duration);
        Ft(Observer, 'GUID', FieldType::GUID);
        Ft(Observer, 'DateTime', FieldType::DateTime);
        Observer.Expect('BLOB', 'BLOB|BLOB|BLOB');
        Observer.Expect('Boolean', 'Boolean|Boolean|Boolean');
        Observer.Expect('Integer', 'Integer|Integer|Integer');
        Observer.Expect('Option', 'Option|Option|Option');
        Observer.Expect('BigInteger', 'BigInteger|BigInteger|BigInteger');
        Observer.Expect('Duration', 'Duration|Duration|Duration');
        Observer.Expect('GUID', 'GUID|GUID|GUID');
        Observer.Expect('DateTime', 'DateTime|DateTime|DateTime');
        Observer.Verify();
    end;

    [Test]
    procedure IsolationLevel_Members()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Il(Observer, 'Default', IsolationLevel::Default);
        Il(Observer, 'UpdLock', IsolationLevel::UpdLock);
        Il(Observer, 'ReadCommitted', IsolationLevel::ReadCommitted);
        Il(Observer, 'RepeatableRead', IsolationLevel::RepeatableRead);
        Observer.Expect('Default', 'Default|Default|Default');
        Observer.Expect('UpdLock', 'UpdLock|UpdLock|UpdLock');
        Observer.Expect('ReadCommitted', 'ReadCommitted|ReadCommitted|ReadCommitted');
        Observer.Expect('RepeatableRead', 'RepeatableRead|RepeatableRead|RepeatableRead');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEval(Op: Integer; Src: Text)
    var
        F: FieldType;
        I: IsolationLevel;
        S: SecurityFilter;
    begin
        case Op of
            1:
                Evaluate(F, Src);
            2:
                Evaluate(I, Src);
            3:
                Evaluate(S, Src);
        end;
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; Op: Integer; Src: Text)
    begin
        Observer.Observe(Name, Format(TryEval(Op, Src)));
        Observer.ObserveError(Name);
    end;

    [Test]
    procedure Evaluate_IntoPlatformOptions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'fieldtype-name', 1, 'Integer');
        Probe(Observer, 'fieldtype-lowercase-name', 1, 'integer');
        Probe(Observer, 'fieldtype-ordinal-0', 1, '0');
        Probe(Observer, 'fieldtype-ordinal-5', 1, '5');
        Probe(Observer, 'fieldtype-ordinal-99', 1, '99');
        Probe(Observer, 'fieldtype-unknown', 1, 'Nope');
        Probe(Observer, 'isolation-name', 2, 'UpdLock');
        Probe(Observer, 'isolation-ordinal-1', 2, '1');
        Probe(Observer, 'isolation-unknown', 2, 'Nope');
        Probe(Observer, 'securityfilter-name', 3, 'Filtered');
        Probe(Observer, 'securityfilter-ordinal-2', 3, '2');
        Observer.Expect('fieldtype-name', 'Yes');
        Observer.Expect('fieldtype-name|text', '');
        Observer.Expect('fieldtype-name|code', '');
        Observer.Expect('fieldtype-lowercase-name', 'Yes');
        Observer.Expect('fieldtype-lowercase-name|text', '');
        Observer.Expect('fieldtype-lowercase-name|code', '');
        Observer.Expect('fieldtype-ordinal-0', 'Yes');
        Observer.Expect('fieldtype-ordinal-0|text', '');
        Observer.Expect('fieldtype-ordinal-0|code', '');
        Observer.Expect('fieldtype-ordinal-5', 'No');
        Observer.Expect('fieldtype-ordinal-5|code', 'InvalidOptionString');
        Observer.Expect('fieldtype-ordinal-99', 'No');
        Observer.Expect('fieldtype-ordinal-99|code', 'InvalidOptionString');
        Observer.Expect('fieldtype-unknown', 'No');
        Observer.Expect('fieldtype-unknown|code', 'InvalidOptionString');
        Observer.Expect('isolation-name', 'Yes');
        Observer.Expect('isolation-name|text', '');
        Observer.Expect('isolation-name|code', '');
        Observer.Expect('isolation-ordinal-1', 'Yes');
        Observer.Expect('isolation-ordinal-1|text', '');
        Observer.Expect('isolation-ordinal-1|code', '');
        Observer.Expect('isolation-unknown', 'No');
        Observer.Expect('isolation-unknown|text', '''Nope'' is not an option. The existing options are: Default, ReadUncommitted, ReadCommitted, RepeatableRead, UpdLock');
        Observer.Expect('isolation-unknown|code', 'InvalidOptionString');
        Observer.Expect('securityfilter-name', 'Yes');
        Observer.Expect('securityfilter-name|text', '');
        Observer.Expect('securityfilter-name|code', '');
        Observer.Expect('securityfilter-ordinal-2', 'Yes');
        Observer.Expect('securityfilter-ordinal-2|text', '');
        Observer.Expect('securityfilter-ordinal-2|code', '');
        Observer.Ignore('fieldtype-ordinal-5|text'); // a dump or environment data: observed, not asserted
        Observer.Ignore('fieldtype-ordinal-99|text'); // a dump or environment data: observed, not asserted
        Observer.Ignore('fieldtype-unknown|text'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;




}
