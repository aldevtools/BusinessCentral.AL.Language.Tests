// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/char/char-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained table 83756, reports 83757 and 83759, report extension 83758, codeunits 83760 and 83761
// Probe: writer BV (2026-10-19, Windows check 3 item BB, from writer BB's probe of corpus issue 653 item 2). The report values were measured on Windows BC 27.5
// and 29.0 (official containers) and on the Linux tiers; every literal asserted below is what those tiers produced.
// Facts: a Char VARIABLE passed to a report procedure Bump(A: Integer) fails with 'Unable to convert from System.Char to System.Int32.' (code Conversion),
// caught by a TryFunction, both when a report extension adds an overload Bump(A: Text) and on a report without an extension (both measured on Windows too).
// A procedure Bump(A: Integer) of ANOTHER codeunit fails the same way (measured on the Linux tiers only, queued for the Windows nightly); a local procedure of
// the calling codeunit is the control.
// BC versions: 27, 28, 29

table 83756 "LT BV Char Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 83757 "LT BV Char Base Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset { dataitem(Row; "LT BV Char Row") { } }

    procedure Bump(A: Integer): Text
    begin
        exit('base integer ' + Format(A));
    end;
}

reportextension 83758 "LT BV Char Base Report Ext" extends "LT BV Char Base Report"
{
    procedure Bump(A: Text): Text
    begin
        exit('extension text ' + A);
    end;
}

report 83759 "LT BV Char Plain Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset { dataitem(Row; "LT BV Char Row") { } }

    procedure Bump(A: Integer): Text
    begin
        exit('plain integer ' + Format(A));
    end;
}

codeunit 83760 "LT BV Char Target"
{
    procedure Bump(A: Integer): Text
    begin
        exit('codeunit integer ' + Format(A));
    end;
}

codeunit 83761 "LT BV Report Char Arg"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryBumpExt(var R: Report "LT BV Char Base Report"; Ch: Char; var Result: Text)
    begin
        Result := R.Bump(Ch);
    end;

    [TryFunction]
    local procedure TryBumpPlain(var R: Report "LT BV Char Plain Report"; Ch: Char; var Result: Text)
    begin
        Result := R.Bump(Ch);
    end;

    [Test]
    procedure ReportWithExtension_CharVariableToIntegerOverload()
    var
        Observer: Codeunit "Probe Observer";
        R: Report "LT BV Char Base Report";
        Ch: Char;
        Result: Text;
    begin
        Ch := 'q';
        Result := '-';
        ClearLastError();
        Observer.Observe('ok', Format(TryBumpExt(R, Ch, Result)));
        Observer.Observe('result', Result);
        Observer.ObserveError('char var');
        Observer.Expect('ok', 'No');
        Observer.Expect('result', '-');
        Observer.Expect('char var|text', 'Unable to convert from System.Char to System.Int32.');
        Observer.Expect('char var|code', 'Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReport_CharVariableToInteger()
    var
        Observer: Codeunit "Probe Observer";
        R: Report "LT BV Char Plain Report";
        Ch: Char;
        Result: Text;
    begin
        Ch := 'q';
        Result := '-';
        ClearLastError();
        Observer.Observe('ok', Format(TryBumpPlain(R, Ch, Result)));
        Observer.Observe('result', Result);
        Observer.ObserveError('char var');
        Observer.Expect('ok', 'No');
        Observer.Expect('result', '-');
        Observer.Expect('char var|text', 'Unable to convert from System.Char to System.Int32.');
        Observer.Expect('char var|code', 'Conversion');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryBumpCodeunit(var Target: Codeunit "LT BV Char Target"; Ch: Char; var Result: Text)
    begin
        Result := Target.Bump(Ch);
    end;

    local procedure LocalBump(A: Integer): Text
    begin
        exit('local integer ' + Format(A));
    end;

    [Test]
    procedure OtherCodeunit_CharVariableToInteger()
    var
        Observer: Codeunit "Probe Observer";
        Target: Codeunit "LT BV Char Target";
        Ch: Char;
        Result: Text;
    begin
        Ch := 'q';
        Result := '-';
        ClearLastError();
        Observer.Observe('ok', Format(TryBumpCodeunit(Target, Ch, Result)));
        Observer.Observe('result', Result);
        Observer.ObserveError('char var');
        Observer.Expect('ok', 'No');
        Observer.Expect('result', '-');
        Observer.Expect('char var|text', 'Unable to convert from System.Char to System.Int32.');
        Observer.Expect('char var|code', 'Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure LocalProcedure_CharVariableToInteger_Control()
    var
        Observer: Codeunit "Probe Observer";
        Ch: Char;
    begin
        Ch := 'q';
        Observer.Observe('result', LocalBump(Ch));
        Observer.Expect('result', 'local integer 113');
        Observer.Verify();
    end;
    // Writer PY-C (al-runtime-rs PR 339, probes-needed "Ternary and call-argument conversion"): a Char variable into BigInteger, Decimal, Byte and
    // Duration parameters of a codeunit and a report procedure (85205, 85206); into an Integer parameter of a page, query, xmlport and table
    // procedure (85207-85210); and a Char expression that is not a variable (a call, Text[i]) into an Integer parameter of another codeunit.
    local procedure PYC_Step(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean; Result: Text)
    begin
        if Ok then
            Observer.Observe(Name, 'ok|' + Result)
        else
            Observer.Observe(Name, 'error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
    end;

    [TryFunction]
    local procedure PYC_CuBig(Ch: Char; var R: Text)
    var
        T: Codeunit "LT PYC Char Target";
    begin
        R := T.BumpBig(Ch);
    end;

    [TryFunction]
    local procedure PYC_CuDec(Ch: Char; var R: Text)
    var
        T: Codeunit "LT PYC Char Target";
    begin
        R := T.BumpDec(Ch);
    end;

    [TryFunction]
    local procedure PYC_CuByte(Ch: Char; var R: Text)
    var
        T: Codeunit "LT PYC Char Target";
    begin
        R := T.BumpByte(Ch);
    end;

    [TryFunction]
    local procedure PYC_CuDur(Ch: Char; var R: Text)
    var
        T: Codeunit "LT PYC Char Target";
    begin
        R := T.BumpDur(Ch);
    end;

    [TryFunction]
    local procedure PYC_RepBig(Ch: Char; var R: Text)
    var
        Rep: Report "LT PYC Char Report";
    begin
        R := Rep.BumpBig(Ch);
    end;

    [TryFunction]
    local procedure PYC_RepDec(Ch: Char; var R: Text)
    var
        Rep: Report "LT PYC Char Report";
    begin
        R := Rep.BumpDec(Ch);
    end;

    [TryFunction]
    local procedure PYC_RepByte(Ch: Char; var R: Text)
    var
        Rep: Report "LT PYC Char Report";
    begin
        R := Rep.BumpByte(Ch);
    end;

    [TryFunction]
    local procedure PYC_RepDur(Ch: Char; var R: Text)
    var
        Rep: Report "LT PYC Char Report";
    begin
        R := Rep.BumpDur(Ch);
    end;

    [Test]
    procedure PYC_Char_NumberParameters_CodeunitAndReport()
    var
        Observer: Codeunit "Probe Observer";
        Ch: Char;
        R: Text;
    begin
        Ch := 'q';
        ClearLastError();
        PYC_Step(Observer, 'codeunit bigint', PYC_CuBig(Ch, R), R);
        PYC_Step(Observer, 'codeunit decimal', PYC_CuDec(Ch, R), R);
        PYC_Step(Observer, 'codeunit byte', PYC_CuByte(Ch, R), R);
        PYC_Step(Observer, 'codeunit duration', PYC_CuDur(Ch, R), R);
        PYC_Step(Observer, 'report bigint', PYC_RepBig(Ch, R), R);
        PYC_Step(Observer, 'report decimal', PYC_RepDec(Ch, R), R);
        PYC_Step(Observer, 'report byte', PYC_RepByte(Ch, R), R);
        PYC_Step(Observer, 'report duration', PYC_RepDur(Ch, R), R);
        Observer.Expect('codeunit bigint', 'error|Unable to convert from System.Char to System.Int64.|Conversion');
        Observer.Expect('codeunit decimal', 'error|Unable to convert from System.Char to Microsoft.Dynamics.Nav.Runtime.Decimal18.|Conversion');
        Observer.Expect('codeunit byte', 'ok|codeunit byte q');
        Observer.Expect('codeunit duration', 'ok|codeunit duration 113 milliseconds');
        Observer.Expect('report bigint', 'error|Unable to convert from System.Char to System.Int64.|Conversion');
        Observer.Expect('report decimal', 'error|Unable to convert from System.Char to Microsoft.Dynamics.Nav.Runtime.Decimal18.|Conversion');
        Observer.Expect('report byte', 'ok|report byte q');
        Observer.Expect('report duration', 'ok|report duration 113 milliseconds');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure PYC_PageInt(Ch: Char; var R: Text)
    var
        P: Page "LT PYC Char Page";
    begin
        R := P.Bump(Ch);
    end;

    [TryFunction]
    local procedure PYC_QueryInt(Ch: Char; var R: Text)
    var
        Q: Query "LT PYC Char Query";
    begin
        R := Q.Bump(Ch);
    end;

    [TryFunction]
    local procedure PYC_XmlPortInt(Ch: Char; var R: Text)
    var
        X: XmlPort "LT PYC Char XmlPort";
    begin
        R := X.Bump(Ch);
    end;

    [TryFunction]
    local procedure PYC_TableInt(Ch: Char; var R: Text)
    var
        H: Record "LT PYC Char Holder";
    begin
        R := H.Bump(Ch);
    end;

    [TryFunction]
    local procedure PYC_CallExpr(var R: Text)
    var
        T: Codeunit "LT PYC Char Target";
    begin
        R := T.BumpInt(PYC_GiveChar());
    end;

    [TryFunction]
    local procedure PYC_IndexExpr(Value: Text; var R: Text)
    var
        T: Codeunit "LT PYC Char Target";
    begin
        R := T.BumpInt(Value[2]);
    end;

    local procedure PYC_GiveChar(): Char
    begin
        exit('q');
    end;

    [Test]
    procedure PYC_Char_IntegerParameters_OtherObjectsAndExpressions()
    var
        Observer: Codeunit "Probe Observer";
        Ch: Char;
        R: Text;
    begin
        Ch := 'q';
        ClearLastError();
        PYC_Step(Observer, 'page integer', PYC_PageInt(Ch, R), R);
        PYC_Step(Observer, 'query integer', PYC_QueryInt(Ch, R), R);
        PYC_Step(Observer, 'xmlport integer', PYC_XmlPortInt(Ch, R), R);
        PYC_Step(Observer, 'table integer', PYC_TableInt(Ch, R), R);
        PYC_Step(Observer, 'call result to codeunit integer', PYC_CallExpr(R), R);
        PYC_Step(Observer, 'text index to codeunit integer', PYC_IndexExpr('pq', R), R);
        Observer.Observe('text index to local integer', LocalBump('pq'[2]));
        Observer.Expect('page integer', 'error|Unable to convert from System.Char to System.Int32.|Conversion');
        Observer.Expect('query integer', 'error|Unable to convert from System.Char to System.Int32.|Conversion');
        Observer.Expect('xmlport integer', 'error|Unable to convert from System.Char to System.Int32.|Conversion');
        Observer.Expect('table integer', 'error|Unable to convert from System.Char to System.Int32.|Conversion');
        Observer.Expect('call result to codeunit integer', 'error|Unable to convert from System.Char to System.Int32.|Conversion');
        Observer.Expect('text index to codeunit integer', 'error|Unable to convert from System.Char to System.Int32.|Conversion');
        Observer.Expect('text index to local integer', 'local integer 113');
        Observer.Verify();
    end;
}

// Writer PY-C: receivers for the PYC_Char tests above. Not test codeunits.
codeunit 85205 "LT PYC Char Target"
{
    procedure BumpInt(A: Integer): Text
    begin
        exit('codeunit integer ' + Format(A));
    end;

    procedure BumpBig(A: BigInteger): Text
    begin
        exit('codeunit bigint ' + Format(A));
    end;

    procedure BumpDec(A: Decimal): Text
    begin
        exit('codeunit decimal ' + Format(A));
    end;

    procedure BumpByte(A: Byte): Text
    begin
        exit('codeunit byte ' + Format(A));
    end;

    procedure BumpDur(A: Duration): Text
    begin
        exit('codeunit duration ' + Format(A));
    end;
}

report 85206 "LT PYC Char Report"
{
    ProcessingOnly = true;
    UsageCategory = None;
    dataset { dataitem(Row; "LT BV Char Row") { } }

    procedure BumpBig(A: BigInteger): Text
    begin
        exit('report bigint ' + Format(A));
    end;

    procedure BumpDec(A: Decimal): Text
    begin
        exit('report decimal ' + Format(A));
    end;

    procedure BumpByte(A: Byte): Text
    begin
        exit('report byte ' + Format(A));
    end;

    procedure BumpDur(A: Duration): Text
    begin
        exit('report duration ' + Format(A));
    end;
}

page 85207 "LT PYC Char Page"
{
    PageType = Card;
    SourceTable = "LT BV Char Row";
    UsageCategory = None;

    procedure Bump(A: Integer): Text
    begin
        exit('page integer ' + Format(A));
    end;
}

query 85208 "LT PYC Char Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT BV Char Row")
        {
            column(Id; Id) { }
        }
    }

    procedure Bump(A: Integer): Text
    begin
        exit('query integer ' + Format(A));
    end;
}

xmlport 85209 "LT PYC Char XmlPort"
{
    schema
    {
        textelement(Root)
        {
        }
    }

    procedure Bump(A: Integer): Text
    begin
        exit('xmlport integer ' + Format(A));
    end;
}

table 85210 "LT PYC Char Holder"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    procedure Bump(A: Integer): Text
    begin
        exit('table integer ' + Format(A));
    end;
}
