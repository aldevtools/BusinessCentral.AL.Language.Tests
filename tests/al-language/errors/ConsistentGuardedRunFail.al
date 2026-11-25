// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-consistent-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 88970-88974 (GRF X, GRF Y, GRF Mode, GRF Inner, GRF Tests)
// Probe: from al-runner issue 8970, second round (posting preview: the inner codeunit marks tables with Consistent(false) through
//   several record variables and then fails on purpose). Neighbors of ConsistentGuardedRun.al and ConsistentGuardedRunEnd.al.
// Area: a guarded Codeunit.Run (Ok := Codeunit.Run(...)) while Consistent(false) marks a table, by the inner codeunit or by the caller.
//   - the inner codeunit ends (a) with Error after writes, (b) with Error and no writes, (c) normally, (d) with Commit and then Error;
//   - the mark is set by the caller before the run on the table the inner codeunit writes, on another table, on a temporary record,
//     or by the inner codeunit;
//   - mark sequences through several variables of one table: false by A then false by C; false by A, true by B; false by A, true by B,
//     false by C; each with a second table marked, the run failing and succeeding;
//   - a Commit inside the inner codeunit under a CommitBehavior::Error and a CommitBehavior::Ignore procedure while marks are held;
//   - a FieldError and a TestField after a mark set on a codeunit global.
//   Each cell reads the run's return value and last error (text and code), whether a Commit in the caller raises (and its text), the
//   same after Consistent(true) on the caller's marking variable, and the rows a commit made durable.
//   How the cells are run: RunThenEnd runs the guarded run, writes the return value and the last error to the log of "GRF Mode",
//   and ends with Error('END'); the test calls it under asserterror, so a run that raises and a run that returns are both read.
//   CommitThenEnd does the same for Commit(). The rows the run committed stay; asserterror rolls back only what came after.
//   Some cells repeat a shape as a plain statement (no asserterror around the run) to show the wrapper does not change the result.
// The values are what BC produced.
// local object: the tests must commit (a guarded Codeunit.Run commits), and the inner codeunit is the code under test.
// BC versions: 27.5, 28.5, 29.0

table 88970 "GRF X"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 88971 "GRF Y"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Code; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// The steps the inner codeunit runs, and a log the caller writes (a SingleInstance codeunit is not rolled back).
codeunit 88972 "GRF Mode"
{
    SingleInstance = true;

    var
        Steps: Text;
        LogText: Text;

    procedure Set(NewSteps: Text)
    begin
        Steps := NewSteps;
        LogText := '';
    end;

    procedure Get(): Text
    begin
        exit(Steps);
    end;

    procedure Log(Line: Text)
    begin
        LogText += Line + ';';
    end;

    procedure GetLog(): Text
    begin
        exit(LogText);
    end;
}

// The inner codeunit: runs the steps of "GRF Mode", comma separated.
//   x / y: table GRF X / GRF Y. f = Consistent(false), t = Consistent(true).
//   a, b, c: three local variables of DoSteps (alive until the run ends); p: a local variable of a procedure (gone when it returns);
//   g: a codeunit global; tmp: a temporary record of GRF X.
codeunit 88973 "GRF Inner"
{
    trigger OnRun()
    begin
        DoSteps();
    end;

    var
        GlobalX: Record "GRF X";

    procedure DoSteps()
    var
        Mode: Codeunit "GRF Mode";
        XA: Record "GRF X";
        XB: Record "GRF X";
        XC: Record "GRF X";
        YA: Record "GRF Y";
        YB: Record "GRF Y";
        YC: Record "GRF Y";
        TempX: Record "GRF X" temporary;
        Step: Text;
    begin
        foreach Step in Mode.Get().Split(',') do
            case Step of
                'insx':
                    InsertX('inner');
                'insy':
                    InsertY(5);
                'startx':
                    StartX();
                'fxp':
                    MarkXInProcedure();
                'fyp':
                    MarkYInProcedure();
                'fxa':
                    XA.Consistent(false);
                'fxb':
                    XB.Consistent(false);
                'fxc':
                    XC.Consistent(false);
                'txa':
                    XA.Consistent(true);
                'txb':
                    XB.Consistent(true);
                'txc':
                    XC.Consistent(true);
                'fya':
                    YA.Consistent(false);
                'fyb':
                    YB.Consistent(false);
                'fyc':
                    YC.Consistent(false);
                'tya':
                    YA.Consistent(true);
                'tyb':
                    YB.Consistent(true);
                'fxg':
                    GlobalX.Consistent(false);
                'fxtmp':
                    TempX.Consistent(false);
                'commit':
                    Commit();
                'cbcommit':
                    CommitUnderError();
                'cbignore':
                    CommitUnderIgnore();
                'err':
                    Error('inner failed');
                'fielderr':
                    begin
                        YA.Init();
                        YA.FieldError(Code, 'must be set');
                    end;
                'testfield':
                    begin
                        YA.Init();
                        YA.TestField(Code);
                    end;
            end;
    end;

    local procedure InsertX(Name: Text[30])
    var
        X: Record "GRF X";
    begin
        X.Init();
        X.Id := 0;
        X.Name := Name;
        X.Insert();
    end;

    local procedure InsertY(Id: Integer)
    var
        Y: Record "GRF Y";
    begin
        Y.Init();
        Y.Id := Id;
        Y.Insert();
    end;

    // The preview state shape: insert a row and mark the table from the same local variable.
    local procedure StartX()
    var
        X: Record "GRF X";
    begin
        X.Init();
        X.Id := 0;
        X.Name := 'state';
        X.Insert();
        X.Consistent(false);
    end;

    local procedure MarkXInProcedure()
    var
        X: Record "GRF X";
    begin
        X.Consistent(false);
    end;

    local procedure MarkYInProcedure()
    var
        Y: Record "GRF Y";
    begin
        Y.Consistent(false);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure CommitUnderError()
    begin
        Commit();
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure CommitUnderIgnore()
    begin
        Commit();
    end;
}

codeunit 88974 "GRF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mode: Codeunit "GRF Mode";

    local procedure Initialize(Steps: Text)
    var
        X: Record "GRF X";
        Y: Record "GRF Y";
    begin
        X.Consistent(true);
        Y.Consistent(true);
        X.DeleteAll();
        Y.DeleteAll();
        Commit();
        ClearLastError();
        Mode.Set(Steps);
    end;

    local procedure Rows(): Text
    var
        X: Record "GRF X";
        Y: Record "GRF Y";
        Names: Text;
    begin
        if X.FindSet() then
            repeat
                Names += X.Name + ';';
            until X.Next() = 0;
        exit('[' + Names + '] y=' + Format(Y.Count()));
    end;

    // The rows a commit made durable: an unrelated error undoes every write since the last commit.
    local procedure DurableRows(): Text
    begin
        asserterror Error('unrelated');
        ClearLastError();
        exit(Rows());
    end;

    local procedure RunThenEnd()
    var
        Ok: Boolean;
    begin
        Ok := Codeunit.Run(Codeunit::"GRF Inner");
        Mode.Log('run=' + Format(Ok));
        Mode.Log('text=' + GetLastErrorText());
        Mode.Log('code=' + GetLastErrorCode());
        ClearLastError();
        Error('END');
    end;

    local procedure CommitThenEnd()
    begin
        Commit();
        Error('END');
    end;

    // ---- (1) the caller marks before the run; the inner codeunit ends in four ways ----

    local procedure CallerCell(Mark: Text; Steps: Text)
    var
        Observer: Codeunit "Probe Observer";
        MarkX: Record "GRF X";
        MarkY: Record "GRF Y";
        TempX: Record "GRF X" temporary;
    begin
        Initialize(Steps);
        case Mark of
            'x':
                MarkX.Consistent(false);
            'y':
                MarkY.Consistent(false);
            'tmp':
                TempX.Consistent(false);
        end;
        asserterror RunThenEnd();
        Observer.ObserveError('run end');
        Observer.Observe('log', Mode.GetLog());
        asserterror CommitThenEnd();
        Observer.ObserveError('commit');
        case Mark of
            'x':
                MarkX.Consistent(true);
            'y':
                MarkY.Consistent(true);
            'tmp':
                TempX.Consistent(true);
        end;
        asserterror CommitThenEnd();
        Observer.ObserveError('commit after true');
        Observer.Observe('durable rows', DurableRows());
        Observer.Finish();
    end;

    [Test]
    procedure CallerMarksX_InnerInsertsXAndFails()
    begin
        CallerCell('x', 'insx,err');
    end;

    [Test]
    procedure CallerMarksX_InnerFailsNoWrite()
    begin
        CallerCell('x', 'err');
    end;

    [Test]
    procedure CallerMarksX_InnerInsertsXAndEnds()
    begin
        CallerCell('x', 'insx');
    end;

    [Test]
    procedure CallerMarksX_InnerInsertsXCommitsAndFails()
    begin
        CallerCell('x', 'insx,commit,err');
    end;

    [Test]
    procedure CallerMarksY_InnerInsertsXAndFails()
    begin
        CallerCell('y', 'insx,err');
    end;

    [Test]
    procedure CallerMarksY_InnerFailsNoWrite()
    begin
        CallerCell('y', 'err');
    end;

    [Test]
    procedure CallerMarksY_InnerInsertsXAndEnds()
    begin
        CallerCell('y', 'insx');
    end;

    [Test]
    procedure CallerMarksY_InnerInsertsXCommitsAndFails()
    begin
        CallerCell('y', 'insx,commit,err');
    end;

    [Test]
    procedure CallerMarksTemp_InnerInsertsXAndFails()
    begin
        CallerCell('tmp', 'insx,err');
    end;

    [Test]
    procedure CallerMarksTemp_InnerFailsNoWrite()
    begin
        CallerCell('tmp', 'err');
    end;

    [Test]
    procedure CallerMarksTemp_InnerInsertsXAndEnds()
    begin
        CallerCell('tmp', 'insx');
    end;

    [Test]
    procedure CallerMarksTemp_InnerInsertsXCommitsAndFails()
    begin
        CallerCell('tmp', 'insx,commit,err');
    end;

    [Test]
    procedure CallerNoMark_InnerMarksXInsertsAndFails()
    begin
        CallerCell('x-none', 'fxa,insx,err');
    end;

    [Test]
    procedure CallerNoMark_InnerMarksXFailsNoWrite()
    begin
        CallerCell('x-none', 'fxa,err');
    end;

    [Test]
    procedure CallerNoMark_InnerMarksXInsertsAndEnds()
    begin
        CallerCell('x-none', 'fxa,insx');
    end;

    [Test]
    procedure CallerNoMark_InnerInsertsXCommitsMarksAndFails()
    begin
        CallerCell('x-none', 'insx,commit,fxa,err');
    end;

    [Test]
    procedure CallerNoMark_InnerMarksXInsertsCommitsAndFails()
    begin
        CallerCell('x-none', 'fxa,insx,commit,err');
    end;

    // ---- (2) the inner codeunit marks through several variables (the preview groups of issue 8970) ----

    local procedure InnerCell(Steps: Text)
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize(Steps);
        asserterror RunThenEnd();
        Observer.ObserveError('run end');
        Observer.Observe('log', Mode.GetLog());
        asserterror CommitThenEnd();
        Observer.ObserveError('commit');
        Observer.Observe('durable rows', DurableRows());
        Observer.Finish();
    end;

    [Test]
    procedure Inner_StartX_MarkYByA_MarkYByC_Fails()
    begin
        InnerCell('startx,fya,fyc,err');
    end;

    [Test]
    procedure Inner_StartX_InsertY_MarkYByA_MarkYByC_Fails()
    begin
        InnerCell('startx,insy,fya,fyc,err');
    end;

    [Test]
    procedure Inner_StartX_MarkYInProcTwice_Fails()
    begin
        InnerCell('startx,fyp,fyp,err');
    end;

    [Test]
    procedure Inner_StartX_MarkYByA_MarkYByC_Ends()
    begin
        InnerCell('startx,fya,fyc');
    end;

    [Test]
    procedure Inner_StartX_TrueXByB_MarkYByA_Fails()
    begin
        InnerCell('startx,txb,fya,err');
    end;

    [Test]
    procedure Inner_StartX_TrueXByB_MarkYByA_Ends()
    begin
        InnerCell('startx,txb,fya');
    end;

    [Test]
    procedure Inner_StartX_TrueXByB_Ends()
    begin
        InnerCell('startx,txb');
    end;

    [Test]
    procedure Inner_MarkXByA_TrueXByB_MarkYByA_Fails()
    begin
        InnerCell('fxa,txb,fya,err');
    end;

    [Test]
    procedure Inner_MarkXByA_TrueXByB_MarkXByC_MarkYByA_Fails()
    begin
        InnerCell('fxa,txb,fxc,fya,err');
    end;

    [Test]
    procedure Inner_MarkXByA_TrueXByB_MarkXByC_MarkYByA_Ends()
    begin
        InnerCell('fxa,txb,fxc,fya');
    end;

    [Test]
    procedure Inner_MarkXByA_TrueXByB_MarkXByC_TrueXByA_TrueYByA_Ends()
    begin
        InnerCell('fxa,txb,fxc,fya,txa,tya');
    end;

    [Test]
    procedure Inner_MarkXByA_TrueXByB_MarkXByC_TrueXByC_TrueYByA_Ends()
    begin
        InnerCell('fxa,txb,fxc,fya,txc,tya');
    end;

    [Test]
    procedure Inner_MarkYByA_MarkXByA_Ends()
    begin
        InnerCell('fya,fxa');
    end;

    // ---- (3) a Commit inside the inner codeunit while marks are held ----

    [Test]
    procedure Inner_MarkXMarkY_CommitUnderCommitBehaviorError()
    begin
        InnerCell('fxa,fyb,cbcommit');
    end;

    [Test]
    procedure Inner_InsertX_CommitUnderCommitBehaviorError()
    begin
        InnerCell('insx,cbcommit');
    end;

    [Test]
    procedure Inner_MarkXMarkY_PlainCommit()
    begin
        InnerCell('fxa,fyb,commit');
    end;

    [Test]
    procedure Inner_MarkXInsertX_CommitUnderCommitBehaviorIgnore_Ends()
    begin
        InnerCell('fxa,insx,cbignore');
    end;

    [Test]
    procedure Inner_MarkXInsertX_CommitUnderCommitBehaviorIgnore_Fails()
    begin
        InnerCell('fxa,insx,cbignore,err');
    end;

    [Test]
    procedure Inner_MarkXTrueX_InsertX_CommitUnderCommitBehaviorIgnore_Ends()
    begin
        InnerCell('fxa,txa,insx,cbignore');
    end;

    // ---- (4) FieldError and TestField after a mark on a codeunit global ----

    [Test]
    procedure Inner_MarkGlobal_FieldError()
    begin
        InnerCell('fxg,fielderr');
    end;

    [Test]
    procedure Inner_MarkGlobal_InsertX_FieldError()
    begin
        InnerCell('fxg,insx,fielderr');
    end;

    [Test]
    procedure Inner_FieldErrorNoMark()
    begin
        InnerCell('insx,fielderr');
    end;

    [Test]
    procedure Inner_MarkGlobal_InsertY_TestField()
    begin
        InnerCell('fxg,insy,testfield');
    end;

    [Test]
    procedure Inner_MarkTemp_InsertX_Fails()
    begin
        InnerCell('fxtmp,insx,err');
    end;

    // ---- (5) the same shapes as plain statements: no asserterror around the run ----

    [Test]
    procedure Plain_StartX_MarkYByA_MarkYByC_Fails()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('startx,insy,fya,fyc,err');
        Ok := Codeunit.Run(Codeunit::"GRF Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Observer.Observe('rows after run', Rows());
        asserterror CommitThenEnd();
        Observer.ObserveError('commit');
        Observer.Observe('durable rows', DurableRows());
        Observer.Finish();
    end;

    [Test]
    procedure Plain_MarkGlobal_InsertX_FieldError()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('fxg,insx,fielderr');
        Ok := Codeunit.Run(Codeunit::"GRF Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        asserterror CommitThenEnd();
        Observer.ObserveError('commit');
        Observer.Observe('durable rows', DurableRows());
        Observer.Finish();
    end;

    [Test]
    procedure Plain_MarkXByA_TrueXByB_MarkXByC_MarkYByA_Fails_ThenCommit()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('fxa,txb,fxc,fya,insx,err');
        Ok := Codeunit.Run(Codeunit::"GRF Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        asserterror CommitThenEnd();
        Observer.ObserveError('commit');
        Observer.Observe('durable rows', DurableRows());
        Observer.Finish();
    end;
}
