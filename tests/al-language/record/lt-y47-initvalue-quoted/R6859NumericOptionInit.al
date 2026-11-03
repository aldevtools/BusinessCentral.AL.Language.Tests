// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-initvalue-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); enum 94900, tables 94900-94903, page 94900, test codeunit 94900
// Probe (al-runner issue 6859): InitValue of an Option or Enum field whose members are named like numbers ("10","20",... "100"). Does the quoted
//   value name the MEMBER or the ORDINAL? Tables 94900 (members "10".."120", InitValue "100"), 94901 (members "3","2","1","0", whose names collide
//   with the ordinals; quoted and bare InitValue), 94902 (names with spaces, a blank member, upper and lower case) and 94903 (an enum whose
//   names are numbers and whose ordinals differ from the names). Observed after Init(), on a fresh variable, after Insert + Get, through
//   RecordRef.Init, after Validate of the default and on a new row of a Card TestPage. Each step runs in a TryFunction.
// Result (Windows BC 27.5 and 28.5, same on every step): a quoted or bare InitValue that is a member's name picks the member NAMED so, never the
//   ordinal ("100" is the member "100" at ordinal 9; with members "3","2","1","0" both "1" and bare 1 give the member "1" at ordinal 2). The match
//   ignores case ("net 30" gives "Net 30"); " " gives the blank member. On an enum the same holds for names that are numbers.
// BC versions: 27, 28, 29

enum 94900 "LT R6859 Numbers"
{
    Extensible = true;

    value(0; "10") { }
    value(1; "20") { }
    value(3; "5") { }
    value(7; "7") { }
    value(100; "1") { }
}

table 94900 "LT R6859 Num Names"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Integer) { }
        field(2; Hundred; Option) { OptionMembers = "10","20","30","40","50","60","70","80","90","100","110","120"; InitValue = "100"; }
        field(3; First; Option) { OptionMembers = "10","20","30","40","50","60","70","80","90","100","110","120"; InitValue = "10"; }
        field(4; Last; Option) { OptionMembers = "10","20","30","40","50","60","70","80","90","100","110","120"; InitValue = "120"; }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}

table 94901 "LT R6859 Collide"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Integer) { }
        field(2; QuotedOne; Option) { OptionMembers = "3","2","1","0"; InitValue = "1"; }
        field(3; BareOne; Option) { OptionMembers = "3","2","1","0"; InitValue = 1; }
        field(4; QuotedZero; Option) { OptionMembers = "3","2","1","0"; InitValue = "0"; }
        field(5; QuotedTwo; Option) { OptionMembers = "3","2","1","0"; InitValue = "2"; }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}

table 94902 "LT R6859 Spaces"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Integer) { }
        field(2; Net60; Option) { OptionMembers = " ","Net 30","Net 60","Due On Receipt"; InitValue = "Net 60"; }
        field(3; Blank; Option) { OptionMembers = " ","Net 30","Net 60","Due On Receipt"; InitValue = " "; }
        field(4; Due; Option) { OptionMembers = " ","Net 30","Net 60","Due On Receipt"; InitValue = "Due On Receipt"; }
        field(5; LowerCase; Option) { OptionMembers = " ","Net 30","Net 60","Due On Receipt"; InitValue = "net 30"; }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}

table 94903 "LT R6859 Num Enum"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Integer) { }
        field(2; Twenty; Enum "LT R6859 Numbers") { InitValue = "20"; }
        field(3; Seven; Enum "LT R6859 Numbers") { InitValue = "7"; }
        field(4; Five; Enum "LT R6859 Numbers") { InitValue = "5"; }
        field(5; One; Enum "LT R6859 Numbers") { InitValue = "1"; }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}

page 94900 "LT R6859 Card"
{
    PageType = Card;
    SourceTable = "LT R6859 Num Names";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Primary Key"; Rec."Primary Key") { ApplicationArea = All; }
            field(Hundred; Rec.Hundred) { ApplicationArea = All; }
            field(First; Rec.First) { ApplicationArea = All; }
            field(Last; Rec.Last) { ApplicationArea = All; }
        }
    }
}

page 94901 "LT R6859 Collide Card"
{
    PageType = Card;
    SourceTable = "LT R6859 Collide";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Primary Key"; Rec."Primary Key") { ApplicationArea = All; }
            field(QuotedOne; Rec.QuotedOne) { ApplicationArea = All; }
            field(BareOne; Rec.BareOne) { ApplicationArea = All; }
            field(QuotedZero; Rec.QuotedZero) { ApplicationArea = All; }
            field(QuotedTwo; Rec.QuotedTwo) { ApplicationArea = All; }
        }
    }
}

codeunit 94900 "LT R6859 Numeric Init"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Step(Ok: Boolean; Value: Text): Text
    begin
        if Ok then
            exit('ok ' + Value);
        exit('error ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure RefDump(var Ref: RecordRef; Ids: List of [Integer]): Text
    var
        Id: Integer;
        Result: Text;
    begin
        foreach Id in Ids do
            Result += Format(Ref.Field(Id).Value) + '/' + Format(Ref.Field(Id).Value, 0, 2) + ';';
        exit(Result);
    end;

    [TryFunction]
    local procedure TryRefInit(TableNo: Integer; Ids: List of [Integer]; var Value: Text)
    var
        Ref: RecordRef;
    begin
        Ref.Open(TableNo);
        Ref.Init();
        Value := RefDump(Ref, Ids);
    end;

    local procedure DumpNumNames(Row: Record "LT R6859 Num Names"): Text
    begin
        exit(Format(Row.Hundred) + '/' + Format(Row.Hundred, 0, 2) + ';' + Format(Row.First) + '/' + Format(Row.First, 0, 2) + ';' + Format(Row.Last) + '/' + Format(Row.Last, 0, 2) + ';');
    end;

    [TryFunction]
    local procedure TryInitNumNames(var Value: Text)
    var
        Row: Record "LT R6859 Num Names";
    begin
        Row.Init();
        Value := DumpNumNames(Row);
    end;

    [TryFunction]
    local procedure TryFreshNumNames(var Value: Text)
    var
        Row: Record "LT R6859 Num Names";
    begin
        Value := DumpNumNames(Row);
    end;

    [TryFunction]
    local procedure TryGetNumNames(var Value: Text)
    var
        Back: Record "LT R6859 Num Names";
    begin
        Back.Get(1);
        Value := DumpNumNames(Back);
    end;

    [TryFunction]
    local procedure TryValidateNumNames(var Value: Text)
    var
        Row: Record "LT R6859 Num Names";
    begin
        Row.Init();
        Row.Validate(Hundred);
        Row.Validate(First);
        Row.Validate(Last);
        Value := DumpNumNames(Row);
    end;

    [Test]
    procedure R6859_NumNames()
    var
        Observer: Codeunit "Probe Observer";
        Ids: List of [Integer];
        Value: Text;
        Row: Record "LT R6859 Num Names";
    begin
        Ids.Add(2);
        Ids.Add(3);
        Ids.Add(4);
        ClearLastError();
        Observer.Observe('init', Step(TryInitNumNames(Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('fresh', Step(TryFreshNumNames(Value), Value));
        ClearLastError();
        Value := '';
        Row.Init();
        Row."Primary Key" := 1;
        Row.Insert();
        ClearLastError();
        Observer.Observe('insertGet', Step(TryGetNumNames(Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('refInit', Step(TryRefInit(Database::"LT R6859 Num Names", Ids, Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('validate', Step(TryValidateNumNames(Value), Value));
        Observer.Expect('init', 'ok 100/9;10/0;120/11;');
        Observer.Expect('fresh', 'ok 100/9;10/0;120/11;');
        Observer.Expect('insertGet', 'ok 100/9;10/0;120/11;');
        Observer.Expect('refInit', 'ok 100/9;10/0;120/11;');
        Observer.Expect('validate', 'ok 100/9;10/0;120/11;');
        Observer.Verify();
    end;


    local procedure DumpCollide(Row: Record "LT R6859 Collide"): Text
    begin
        exit(Format(Row.QuotedOne) + '/' + Format(Row.QuotedOne, 0, 2) + ';' + Format(Row.BareOne) + '/' + Format(Row.BareOne, 0, 2) + ';' + Format(Row.QuotedZero) + '/' + Format(Row.QuotedZero, 0, 2) + ';' + Format(Row.QuotedTwo) + '/' + Format(Row.QuotedTwo, 0, 2) + ';');
    end;

    [TryFunction]
    local procedure TryInitCollide(var Value: Text)
    var
        Row: Record "LT R6859 Collide";
    begin
        Row.Init();
        Value := DumpCollide(Row);
    end;

    [TryFunction]
    local procedure TryFreshCollide(var Value: Text)
    var
        Row: Record "LT R6859 Collide";
    begin
        Value := DumpCollide(Row);
    end;

    [TryFunction]
    local procedure TryGetCollide(var Value: Text)
    var
        Back: Record "LT R6859 Collide";
    begin
        Back.Get(1);
        Value := DumpCollide(Back);
    end;

    [TryFunction]
    local procedure TryValidateCollide(var Value: Text)
    var
        Row: Record "LT R6859 Collide";
    begin
        Row.Init();
        Row.Validate(QuotedOne);
        Row.Validate(BareOne);
        Row.Validate(QuotedZero);
        Row.Validate(QuotedTwo);
        Value := DumpCollide(Row);
    end;

    [Test]
    procedure R6859_Collide()
    var
        Observer: Codeunit "Probe Observer";
        Ids: List of [Integer];
        Value: Text;
        Row: Record "LT R6859 Collide";
    begin
        Ids.Add(2);
        Ids.Add(3);
        Ids.Add(4);
        Ids.Add(5);
        ClearLastError();
        Observer.Observe('init', Step(TryInitCollide(Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('fresh', Step(TryFreshCollide(Value), Value));
        ClearLastError();
        Value := '';
        Row.Init();
        Row."Primary Key" := 1;
        Row.Insert();
        ClearLastError();
        Observer.Observe('insertGet', Step(TryGetCollide(Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('refInit', Step(TryRefInit(Database::"LT R6859 Collide", Ids, Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('validate', Step(TryValidateCollide(Value), Value));
        Observer.Expect('init', 'ok 1/2;1/2;0/3;2/1;');
        Observer.Expect('fresh', 'ok 1/2;1/2;0/3;2/1;');
        Observer.Expect('insertGet', 'ok 1/2;1/2;0/3;2/1;');
        Observer.Expect('refInit', 'ok 1/2;1/2;0/3;2/1;');
        Observer.Expect('validate', 'ok 1/2;1/2;0/3;2/1;');
        Observer.Verify();
    end;


    local procedure DumpSpaces(Row: Record "LT R6859 Spaces"): Text
    begin
        exit(Format(Row.Net60) + '/' + Format(Row.Net60, 0, 2) + ';' + Format(Row.Blank) + '/' + Format(Row.Blank, 0, 2) + ';' + Format(Row.Due) + '/' + Format(Row.Due, 0, 2) + ';' + Format(Row.LowerCase) + '/' + Format(Row.LowerCase, 0, 2) + ';');
    end;

    [TryFunction]
    local procedure TryInitSpaces(var Value: Text)
    var
        Row: Record "LT R6859 Spaces";
    begin
        Row.Init();
        Value := DumpSpaces(Row);
    end;

    [TryFunction]
    local procedure TryFreshSpaces(var Value: Text)
    var
        Row: Record "LT R6859 Spaces";
    begin
        Value := DumpSpaces(Row);
    end;

    [TryFunction]
    local procedure TryGetSpaces(var Value: Text)
    var
        Back: Record "LT R6859 Spaces";
    begin
        Back.Get(1);
        Value := DumpSpaces(Back);
    end;

    [TryFunction]
    local procedure TryValidateSpaces(var Value: Text)
    var
        Row: Record "LT R6859 Spaces";
    begin
        Row.Init();
        Row.Validate(Net60);
        Row.Validate(Blank);
        Row.Validate(Due);
        Row.Validate(LowerCase);
        Value := DumpSpaces(Row);
    end;

    [Test]
    procedure R6859_Spaces()
    var
        Observer: Codeunit "Probe Observer";
        Ids: List of [Integer];
        Value: Text;
        Row: Record "LT R6859 Spaces";
    begin
        Ids.Add(2);
        Ids.Add(3);
        Ids.Add(4);
        Ids.Add(5);
        ClearLastError();
        Observer.Observe('init', Step(TryInitSpaces(Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('fresh', Step(TryFreshSpaces(Value), Value));
        ClearLastError();
        Value := '';
        Row.Init();
        Row."Primary Key" := 1;
        Row.Insert();
        ClearLastError();
        Observer.Observe('insertGet', Step(TryGetSpaces(Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('refInit', Step(TryRefInit(Database::"LT R6859 Spaces", Ids, Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('validate', Step(TryValidateSpaces(Value), Value));
        Observer.Expect('init', 'ok Net 60/2; /0;Due On Receipt/3;Net 30/1;');
        Observer.Expect('fresh', 'ok Net 60/2; /0;Due On Receipt/3;Net 30/1;');
        Observer.Expect('insertGet', 'ok Net 60/2; /0;Due On Receipt/3;Net 30/1;');
        Observer.Expect('refInit', 'ok Net 60/2; /0;Due On Receipt/3;Net 30/1;');
        Observer.Expect('validate', 'ok Net 60/2; /0;Due On Receipt/3;Net 30/1;');
        Observer.Verify();
    end;


    local procedure DumpNumEnum(Row: Record "LT R6859 Num Enum"): Text
    begin
        exit(Format(Row.Twenty) + '/' + Format(Row.Twenty.AsInteger()) + ';' + Format(Row.Seven) + '/' + Format(Row.Seven.AsInteger()) + ';' + Format(Row.Five) + '/' + Format(Row.Five.AsInteger()) + ';' + Format(Row.One) + '/' + Format(Row.One.AsInteger()) + ';');
    end;

    [TryFunction]
    local procedure TryInitNumEnum(var Value: Text)
    var
        Row: Record "LT R6859 Num Enum";
    begin
        Row.Init();
        Value := DumpNumEnum(Row);
    end;

    [TryFunction]
    local procedure TryFreshNumEnum(var Value: Text)
    var
        Row: Record "LT R6859 Num Enum";
    begin
        Value := DumpNumEnum(Row);
    end;

    [TryFunction]
    local procedure TryGetNumEnum(var Value: Text)
    var
        Back: Record "LT R6859 Num Enum";
    begin
        Back.Get(1);
        Value := DumpNumEnum(Back);
    end;

    [TryFunction]
    local procedure TryValidateNumEnum(var Value: Text)
    var
        Row: Record "LT R6859 Num Enum";
    begin
        Row.Init();
        Row.Validate(Twenty);
        Row.Validate(Seven);
        Row.Validate(Five);
        Row.Validate(One);
        Value := DumpNumEnum(Row);
    end;

    [Test]
    procedure R6859_NumEnum()
    var
        Observer: Codeunit "Probe Observer";
        Ids: List of [Integer];
        Value: Text;
        Row: Record "LT R6859 Num Enum";
    begin
        Ids.Add(2);
        Ids.Add(3);
        Ids.Add(4);
        Ids.Add(5);
        ClearLastError();
        Observer.Observe('init', Step(TryInitNumEnum(Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('fresh', Step(TryFreshNumEnum(Value), Value));
        ClearLastError();
        Value := '';
        Row.Init();
        Row."Primary Key" := 1;
        Row.Insert();
        ClearLastError();
        Observer.Observe('insertGet', Step(TryGetNumEnum(Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('refInit', Step(TryRefInit(Database::"LT R6859 Num Enum", Ids, Value), Value));
        ClearLastError();
        Value := '';
        Observer.Observe('validate', Step(TryValidateNumEnum(Value), Value));
        Observer.Expect('init', 'ok 20/1;7/7;5/3;1/100;');
        Observer.Expect('fresh', 'ok 20/1;7/7;5/3;1/100;');
        Observer.Expect('insertGet', 'ok 20/1;7/7;5/3;1/100;');
        Observer.Expect('refInit', 'ok 20/1;7/7;5/3;1/100;');
        Observer.Expect('validate', 'ok 20/1;7/7;5/3;1/100;');
        Observer.Verify();
    end;


    [Test]
    procedure R6859_NewRowOnCard()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R6859 Card";
        Card2: TestPage "LT R6859 Collide Card";
    begin
        Card.OpenNew();
        Observer.Observe('numNames', Card.Hundred.Value + '|' + Card.First.Value + '|' + Card.Last.Value);
        Card.Close();
        Card2.OpenNew();
        Observer.Observe('collide', Card2.QuotedOne.Value + '|' + Card2.BareOne.Value + '|' + Card2.QuotedZero.Value + '|' + Card2.QuotedTwo.Value);
        Card2.Close();
        Observer.Expect('numNames', '100|10|120');
        Observer.Expect('collide', '1|1|0|2');
        Observer.Verify();
    end;
}
