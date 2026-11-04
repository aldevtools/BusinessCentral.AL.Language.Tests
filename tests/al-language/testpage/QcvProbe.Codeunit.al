// Fixture for TestPageCloseVeto_Tests.al.
/// <summary>
/// Session-scoped state for "QCV Veto Card": what its OnQueryClosePage answers, and how often
/// each close-lifecycle trigger ran. SingleInstance rather than a table so the counters cannot
/// be rolled back or committed by anything the close does.
/// </summary>
codeunit 60439 "QCV Probe"
{
    SingleInstance = true;

    var
        Mode: Integer;
        QueryCloseCount: Integer;
        ClosePageCount: Integer;
        CloseRefusedErr: Label 'QCV close refused by OnQueryClosePage';
        CloseQst: Label 'QCV close this page?';

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
