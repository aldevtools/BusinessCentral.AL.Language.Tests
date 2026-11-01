// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-fields
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93334
// Probe (writer Y64, al-runner issue 6645): filters on the user-name system FlowFields SystemCreatedByUserName, SystemCreatedByFullName,
//   SystemModifiedByUserName and SystemModifiedByFullName (2000000005-2000000008, BC 29 only): FieldRef.GetFilter with no filter and after
//   SetView, SetFilter and SetRange, GetRangeMin/Max, the reporter's loop over the Field rows of a table that reads GetFilter of every field,
//   Record.SetRange/SetFilter/GetFilter on the fields, Count and FindSet with such a filter, CalcFields and CalcField. The user name depends on
//   the environment, so values are compared with UserId() (and the User table's full name), not shown. Already pinned: the Field rows
//   (platform/lt-y35-username-field-rows), FieldRef Number/Class/Type/Length/Value (system-fields/W6SystemFieldStamps.al:239).
// BC versions: 29 (the fields do not exist before BC 29; the tests are BC29PLUS)

table 93334 "LT Y64 UN Filter Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 93335 "LT Y64 UN Filter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y64_UserNameFields_Exist()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LT Y64 UN Filter Row");
        Observer.Observe('exist 2000000005', Format(RecRef.FieldExist(2000000005)));
        RecRef.Close();
        Observer.Finish();
    end;
#if BC29PLUS

    local procedure Seed()
    var
        Row: Record "LT Y64 UN Filter Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'alpha';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'bravo';
        Row.Insert();
    end;

    local procedure Mask(Value: Text): Text
    var
        Me: Text;
    begin
        Me := UserId();
        if Me <> '' then
            Value := Value.Replace(Me, '<me>');
        Me := MyFullName();
        if Me <> '' then
            Value := Value.Replace(Me, '<full>');
        exit(Value);
    end;

    local procedure MyFullName(): Text
    var
        U: Record User;
    begin
        U.SetRange("User Security ID", UserSecurityId());
        if U.FindFirst() then
            exit(U."Full Name");
        exit('');
    end;

    [Test]
    procedure Y64_UserNameFields_FieldRefGetFilter_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        FldRef: FieldRef;
        No: Integer;
    begin
        Seed();
        RecRef.Open(Database::"LT Y64 UN Filter Row");
        for No := 2000000005 to 2000000008 do begin
            FldRef := RecRef.Field(No);
            Observer.Observe(Format(No) + ' getfilter', '[' + FldRef.GetFilter() + ']');
            Observer.Observe(Format(No) + ' name', FldRef.Name());
        end;
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y64_UserNameFields_FieldRefSetFilterSetRange()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Seed();
        RecRef.Open(Database::"LT Y64 UN Filter Row");
        FldRef := RecRef.Field(2000000005);
        FldRef.SetFilter('<>%1', '');
        Observer.Observe('setfilter getfilter', Mask(FldRef.GetFilter()));
        Observer.Observe('setfilter count', Format(RecRef.Count()));
        FldRef.SetRange(UserId());
        Observer.Observe('setrange getfilter', Mask(FldRef.GetFilter()));
        Observer.Observe('setrange min max', Mask(Format(FldRef.GetRangeMin()) + '|' + Format(FldRef.GetRangeMax())));
        Observer.Observe('setrange count', Format(RecRef.Count()));
        FldRef.SetRange('nobody-y64');
        Observer.Observe('other user count', Format(RecRef.Count()));
        FldRef.SetRange();
        Observer.Observe('cleared getfilter', '[' + FldRef.GetFilter() + ']');
        FldRef := RecRef.Field(2000000006);
        FldRef.SetFilter('*');
        Observer.Observe('full name filter', FldRef.GetFilter());
        Observer.Observe('full name count', Format(RecRef.Count()));
        Observer.Observe('getfilters', Mask(RecRef.GetFilters()));
        Observer.Observe('getview', Mask(RecRef.GetView()));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y64_UserNameFields_ReporterLoopOverFieldRows()
    var
        Observer: Codeunit "Probe Observer";
        MyField: Record Field;
        RecRef: RecordRef;
        FldRef: FieldRef;
        Result: Text;
        Visited: Integer;
    begin
        Seed();
        RecRef.Open(Database::"LT Y64 UN Filter Row");
        RecRef.SetView('WHERE(Name=FILTER(a*))');
        MyField.SetRange(TableNo, Database::"LT Y64 UN Filter Row");
        MyField.SetRange(ObsoleteState, MyField.ObsoleteState::No);
        if MyField.FindSet() then
            repeat
                Visited += 1;
                FldRef := RecRef.Field(MyField."No.");
                if FldRef.GetFilter() <> '' then
                    Result += Format(MyField."No.") + '=' + FldRef.GetFilter() + ';';
            until MyField.Next() = 0;
        Observer.Observe('filters', Result);
        Observer.Observe('fields visited', Format(Visited));
        RecRef.SetView(StrSubstNo('WHERE(SystemCreatedByUserName=FILTER(<>''''),Name=FILTER(b*))'));
        Result := '';
        if MyField.FindSet() then
            repeat
                FldRef := RecRef.Field(MyField."No.");
                if FldRef.GetFilter() <> '' then
                    Result += Format(MyField."No.") + '=' + FldRef.GetFilter() + ';';
            until MyField.Next() = 0;
        Observer.Observe('filters with a user-name filter', Result);
        Observer.Observe('count with a user-name filter', Format(RecRef.Count()));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y64_UserNameFields_RecordFilters()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y64 UN Filter Row";
        Names: Text;
    begin
        Seed();
        Row.SetRange(SystemCreatedByUserName, UserId());
        Observer.Observe('setrange getfilter', Mask(Row.GetFilter(SystemCreatedByUserName)));
        Observer.Observe('setrange count', Format(Row.Count()));
        Row.SetFilter(SystemModifiedByUserName, '<>%1', 'nobody-y64');
        Observer.Observe('setfilter getfilter', Row.GetFilter(SystemModifiedByUserName));
        Observer.Observe('both count', Format(Row.Count()));
        Row.SetFilter(SystemCreatedByFullName, '%1', 'nobody-y64');
        Observer.Observe('full name no match count', Format(Row.Count()));
        Observer.Observe('getfilters', Mask(Row.GetFilters()));
        Row.Reset();
        Row.FindFirst();
        Observer.Observe('before calcfields', '[' + Row.SystemCreatedByUserName + ']');
        Row.CalcFields(SystemCreatedByUserName, SystemModifiedByUserName, SystemCreatedByFullName);
        Observer.Observe('calcfields user is me', Format(Row.SystemCreatedByUserName = UserId()));
        Observer.Observe('calcfields modified user is me', Format(Row.SystemModifiedByUserName = UserId()));
        Observer.Observe('calcfields full name is mine', Format(Row.SystemCreatedByFullName = MyFullName()));
        Row.SetRange(SystemCreatedByUserName, UserId());
        if Row.FindSet() then
            repeat
                Names += Row.Name + ';';
            until Row.Next() = 0;
        Observer.Observe('findset', Names);
        Observer.Finish();
    end;
#endif
}
