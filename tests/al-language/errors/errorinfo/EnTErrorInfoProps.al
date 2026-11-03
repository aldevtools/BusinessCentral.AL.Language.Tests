// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-data-type
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
//
// ErrorInfo: Create overloads and every property default, set and get.
// Fixtures used: Probe Observer (69160); self-contained table 73026
// BC versions: 29 (27 and 28 by CI)

table 73026 "LT EnT Info Rec"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 73026 "LT EnT ErrorInfo Props"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Create_Defaults()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
        Rid: RecordId;
    begin
        ErrInfo := ErrorInfo.Create();
        Observer.Observe('message', ErrInfo.Message);
        Observer.Observe('detailed', ErrInfo.DetailedMessage);
        Observer.Observe('title', ErrInfo.Title);
        Observer.Observe('collectible', Format(ErrInfo.Collectible));
        Observer.Observe('verbosity', Format(ErrInfo.Verbosity));
        Observer.Observe('errortype', Format(ErrInfo.ErrorType));
        Observer.Observe('tableid', Format(ErrInfo.TableId));
        Observer.Observe('fieldno', Format(ErrInfo.FieldNo));
        Observer.Observe('pageno', Format(ErrInfo.PageNo));
        Observer.Observe('systemid', Format(IsNullGuid(ErrInfo.SystemId)));
        Rid := ErrInfo.RecordId;
        Observer.Observe('recordid', Format(Rid));
        Observer.Observe('customdim', Format(ErrInfo.CustomDimensions.Count()));
        Observer.Expect('message', '');
        Observer.Expect('detailed', '');
        Observer.Expect('title', '');
        Observer.Expect('collectible', 'Yes');
        Observer.Expect('verbosity', 'Error');
        Observer.Expect('errortype', 'Client');
        Observer.Expect('tableid', '0');
        Observer.Expect('fieldno', '0');
        Observer.Expect('pageno', '0');
        Observer.Expect('systemid', 'Yes');
        Observer.Expect('recordid', '');
        Observer.Expect('customdim', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Create_WithMessage()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
    begin
        ErrInfo := ErrorInfo.Create('hello');
        Observer.Observe('message', ErrInfo.Message);
        Observer.Observe('collectible', Format(ErrInfo.Collectible));
        Observer.Observe('verbosity', Format(ErrInfo.Verbosity));
        ErrInfo := ErrorInfo.Create('');
        Observer.Observe('empty', ErrInfo.Message);
        ErrInfo := ErrorInfo.Create('a%1b');
        Observer.Observe('placeholder', ErrInfo.Message);
        ErrInfo := ErrorInfo.Create('äöü ✓');
        Observer.Observe('unicode', ErrInfo.Message);
        Observer.Expect('message', 'hello');
        Observer.Expect('collectible', 'No');
        Observer.Expect('verbosity', 'Error');
        Observer.Expect('empty', '');
        Observer.Expect('placeholder', 'a%1b');
        Observer.Expect('unicode', 'äöü ✓');
        Observer.Verify();
    end;

    [Test]
    procedure Create_FullOverload()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
        Rec: Record "LT EnT Info Rec";
        Dim: Dictionary of [Text, Text];
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := 'A1';
        Rec.Insert();
        Dim.Add('k', 'v');
        ErrInfo := ErrorInfo.Create('msg');
        ErrInfo.Collectible := true;
        ErrInfo.RecordId := Rec.RecordId;
        ErrInfo.FieldNo := Rec.FieldNo(Name);
        ErrInfo.Verbosity := Verbosity::Warning;
        ErrInfo.ErrorType := ErrorType::Client;
        ErrInfo.CustomDimensions := Dim;
        ErrInfo.SystemId := Rec.SystemId;
        Observer.Observe('message', ErrInfo.Message);
        Observer.Observe('collectible', Format(ErrInfo.Collectible));
        Observer.Observe('tableid', Format(ErrInfo.TableId));
        Observer.Observe('fieldno', Format(ErrInfo.FieldNo));
        Observer.Observe('pageno', Format(ErrInfo.PageNo));
        Observer.Observe('verbosity', Format(ErrInfo.Verbosity));
        Observer.Observe('errortype', Format(ErrInfo.ErrorType));
        Observer.Observe('recordid', Format(ErrInfo.RecordId));
        Observer.Observe('sysid equal', Format(ErrInfo.SystemId = Rec.SystemId));
        Observer.Observe('dim count', Format(ErrInfo.CustomDimensions.Count()));
        Observer.Observe('dim k', ErrInfo.CustomDimensions.Get('k'));
        Observer.Expect('message', 'msg');
        Observer.Expect('collectible', 'Yes');
        Observer.Expect('tableid', '0');
        Observer.Expect('fieldno', '2');
        Observer.Expect('pageno', '0');
        Observer.Expect('verbosity', 'Warning');
        Observer.Expect('errortype', 'Client');
        Observer.Expect('recordid', 'LT EnT Info Rec: A1');
        Observer.Expect('sysid equal', 'Yes');
        Observer.Expect('dim count', '1');
        Observer.Expect('dim k', 'v');
        Observer.Verify();
    end;

    [Test]
    procedure Properties_SetGet()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
    begin
        ErrInfo.Message := 'm1';
        ErrInfo.DetailedMessage := 'd1';
        ErrInfo.Title := 't1';
        ErrInfo.Collectible := true;
        ErrInfo.Verbosity := Verbosity::Critical;
        ErrInfo.ErrorType := ErrorType::Client;
        ErrInfo.TableId := 73026;
        ErrInfo.FieldNo := 2;
        ErrInfo.PageNo := 1;
        Observer.Observe('message', ErrInfo.Message);
        Observer.Observe('detailed', ErrInfo.DetailedMessage);
        Observer.Observe('title', ErrInfo.Title);
        Observer.Observe('collectible', Format(ErrInfo.Collectible));
        Observer.Observe('verbosity', Format(ErrInfo.Verbosity));
        Observer.Observe('errortype', Format(ErrInfo.ErrorType));
        Observer.Observe('tableid', Format(ErrInfo.TableId));
        Observer.Observe('fieldno', Format(ErrInfo.FieldNo));
        Observer.Observe('pageno', Format(ErrInfo.PageNo));
        Observer.Expect('message', 'm1');
        Observer.Expect('detailed', 'd1');
        Observer.Expect('title', 't1');
        Observer.Expect('collectible', 'Yes');
        Observer.Expect('verbosity', 'Critical');
        Observer.Expect('errortype', 'Client');
        Observer.Expect('tableid', '73026');
        Observer.Expect('fieldno', '2');
        Observer.Expect('pageno', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Properties_Verbosity_AllValues()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
    begin
        ErrInfo.Verbosity := Verbosity::Critical;
        Observer.Observe('critical', Format(ErrInfo.Verbosity));
        ErrInfo.Verbosity := Verbosity::Error;
        Observer.Observe('error', Format(ErrInfo.Verbosity));
        ErrInfo.Verbosity := Verbosity::Warning;
        Observer.Observe('warning', Format(ErrInfo.Verbosity));
        ErrInfo.Verbosity := Verbosity::Normal;
        Observer.Observe('normal', Format(ErrInfo.Verbosity));
        ErrInfo.Verbosity := Verbosity::Verbose;
        Observer.Observe('verbose', Format(ErrInfo.Verbosity));
        ErrInfo.ErrorType := ErrorType::Client;
        Observer.Observe('client', Format(ErrInfo.ErrorType));
        ErrInfo.ErrorType := ErrorType::Internal;
        Observer.Observe('internal', Format(ErrInfo.ErrorType));
        Observer.Observe('client ord', Format(ErrorType::Client, 0, 2));
        Observer.Observe('internal ord', Format(ErrorType::Internal, 0, 2));
        Observer.Observe('critical ord', Format(Verbosity::Critical, 0, 2));
        Observer.Observe('verbose ord', Format(Verbosity::Verbose, 0, 2));
        Observer.Expect('critical', 'Critical');
        Observer.Expect('error', 'Error');
        Observer.Expect('warning', 'Warning');
        Observer.Expect('normal', 'Normal');
        Observer.Expect('verbose', 'Verbose');
        Observer.Expect('client', 'Client');
        Observer.Expect('internal', 'Internal');
        Observer.Expect('client ord', '0');
        Observer.Expect('internal ord', '1');
        Observer.Expect('critical ord', '1');
        Observer.Expect('verbose ord', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Properties_Message_Edge()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
        Long: Text;
    begin
        ErrInfo.Message := '';
        Observer.Observe('empty', ErrInfo.Message);
        ErrInfo.Message := '   ';
        Observer.Observe('blank', Format(StrLen(ErrInfo.Message)));
        Long := PadStr('', 5000, 'x');
        ErrInfo.Message := Long;
        Observer.Observe('long len', Format(StrLen(ErrInfo.Message)));
        ErrInfo.DetailedMessage := Long;
        Observer.Observe('long detailed len', Format(StrLen(ErrInfo.DetailedMessage)));
        ErrInfo.Title := Long;
        Observer.Observe('long title len', Format(StrLen(ErrInfo.Title)));
        asserterror ErrInfo.Message := 'a' + Format(10, 0, '<Number>') + 'b';
        Observer.ObserveError('af175');
        Observer.Observe('formatted', ErrInfo.Message);
        Observer.Expect('empty', '');
        Observer.Expect('blank', '3');
        Observer.Expect('long len', '5000');
        Observer.Expect('long detailed len', '5000');
        Observer.Expect('long title len', '5000');
        Observer.Expect('af175|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Number>');
        Observer.Expect('af175|code', 'InvalidFormatString');
        Observer.Ignore('formatted'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;





    [Test]
    procedure Properties_RecordId_SystemId()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
        Rec: Record "LT EnT Info Rec";
        Rid: RecordId;
        G: Guid;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec."No." := 'R1';
        Rec.Insert();
        Rid := Rec.RecordId;
        ErrInfo.RecordId := Rid;
        Observer.Observe('rid equal', Format(ErrInfo.RecordId = Rid));
        Observer.Observe('tableid after rid', Format(ErrInfo.TableId));
        ErrInfo.SystemId := Rec.SystemId;
        Observer.Observe('sysid equal', Format(ErrInfo.SystemId = Rec.SystemId));
        ErrInfo.SystemId := G;
        Observer.Observe('sysid null', Format(IsNullGuid(ErrInfo.SystemId)));
        ErrInfo.TableId := 73026;
        Observer.Observe('tableid', Format(ErrInfo.TableId));
        ErrInfo.TableId := 0;
        Observer.Observe('tableid zero', Format(ErrInfo.TableId));
        ErrInfo.FieldNo := -1;
        Observer.Observe('fieldno neg', Format(ErrInfo.FieldNo));
        Observer.Expect('rid equal', 'Yes');
        Observer.Expect('tableid after rid', '0');
        Observer.Expect('sysid equal', 'Yes');
        Observer.Expect('sysid null', 'Yes');
        Observer.Expect('tableid', '73026');
        Observer.Expect('tableid zero', '0');
        Observer.Expect('fieldno neg', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure Properties_CustomDimensions()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
        Dim: Dictionary of [Text, Text];
        K: Text;
    begin
        Dim.Add('a', '1');
        Dim.Add('b', '2');
        ErrInfo.CustomDimensions := Dim;
        Observer.Observe('count', Format(ErrInfo.CustomDimensions.Count()));
        Observer.Observe('a', ErrInfo.CustomDimensions.Get('a'));
        Observer.Observe('contains c', Format(ErrInfo.CustomDimensions.ContainsKey('c')));
        Dim.Add('c', '3');
        Observer.Observe('copy semantic', Format(ErrInfo.CustomDimensions.Count()));
        foreach K in ErrInfo.CustomDimensions.Keys() do
            Observer.Observe('key ' + K, ErrInfo.CustomDimensions.Get(K));
        Clear(Dim);
        ErrInfo.CustomDimensions := Dim;
        Observer.Observe('cleared', Format(ErrInfo.CustomDimensions.Count()));
        Observer.Expect('count', '2');
        Observer.Expect('a', '1');
        Observer.Expect('contains c', 'No');
        Observer.Expect('copy semantic', '3');
        Observer.Expect('key a', '1');
        Observer.Expect('key b', '2');
        Observer.Expect('key c', '3');
        Observer.Expect('cleared', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_Semantics()
    var
        Observer: Codeunit "Probe Observer";
        A: ErrorInfo;
        B: ErrorInfo;
    begin
        A.Message := 'one';
        B := A;
        B.Message := 'two';
        Observer.Observe('a after b change', A.Message);
        Observer.Observe('b', B.Message);
        Clear(A);
        Observer.Observe('cleared', A.Message);
        Observer.Observe('b kept', B.Message);
        Observer.Expect('a after b change', 'two');
        Observer.Expect('b', 'two');
        Observer.Expect('cleared', '');
        Observer.Expect('b kept', '');
        Observer.Verify();
    end;
}
