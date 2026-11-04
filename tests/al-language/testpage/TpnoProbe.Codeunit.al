// Fixture for TestPageNeverOpened_Tests.al. A SingleInstance fixture is owned by exactly one
// test codeunit, so this is a separate copy of the close-veto probe rather than a shared one.
/// <summary>
/// Session-scoped state for "TPNO Veto Card": what its OnQueryClosePage answers, and how often
/// each close-lifecycle trigger ran. SingleInstance rather than a table so the counters cannot
/// be rolled back or committed by anything the close does.
/// </summary>
codeunit 67041 "TPNO Probe"
{
    SingleInstance = true;

    var
        Mode: Integer;
        QueryCloseCount: Integer;
        ClosePageCount: Integer;
        CloseRefusedErr: Label 'TPNO close refused by OnQueryClosePage';
        CloseQst: Label 'TPNO close this page?';

    procedure Reset(NewMode: Integer)
    begin
        Mode := NewMode;
        QueryCloseCount := 0;
        ClosePageCount := 0;
    end;

    procedure ModeAllow(): Integer
    begin
        exit(0);
    end;

    procedure ModeVeto(): Integer
    begin
        exit(1);
    end;

    procedure ModeConfirm(): Integer
    begin
        exit(2);
    end;

    procedure ModeError(): Integer
    begin
        exit(3);
    end;

    procedure AnswerQueryClose(): Boolean
    begin
        QueryCloseCount += 1;
        case Mode of
            ModeVeto():
                exit(false);
            ModeConfirm():
                exit(Confirm(CloseQst));
            ModeError():
                Error(CloseRefusedErr);
        end;
        exit(true);
    end;

    procedure NoteClosePage()
    begin
        ClosePageCount += 1;
    end;

    procedure QueryCloseCalls(): Integer
    begin
        exit(QueryCloseCount);
    end;

    procedure ClosePageCalls(): Integer
    begin
        exit(ClosePageCount);
    end;
}
