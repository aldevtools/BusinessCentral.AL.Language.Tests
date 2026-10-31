// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: in-scope
// Fixtures used: Probe Observer (69160); cross-app fixtures A, D and B (tests/al-language-xapp-a/Y8XaInstallOrder.al, xapp-d/Y8XdInstallOrder.al,
// xapp-b/Y8XbInstallOrder.al)
// Probe: install order across apps (al-runtime-rs docs/probes-needed.md install-order leftovers, writer Y8, 2026-10-30).
//   1. Do the table-extension triggers of a later app (B extends A's table 61180 with an OnBeforeInsert trigger and a field with an InitValue) run
//      on A's table while A installs? Row 1 is written by A's install code with Insert(true).
//   2. Does an app's install code see the rows that an unrelated app (no dependency path: D and B) wrote during its own, earlier install?
// The corpus publishes A, D, B, C (ci.yml app_dirs); other hosts may install B before D. So the facts about D and B are asserted as relations to the
// install sequence the log records (an app's install sees exactly the rows of the apps installed before it; B's trigger ran on a row exactly
// when B was installed before that row was written), not as one fixed order.
// Facts: (1) No: row 1 (written by A's install) has Note 'A' and an empty "Y8 XB Mark" (B's InitValue is not applied to rows that exist when B is
// installed); B's own install row has 'B+BX' and 'B init' (B's extension triggers and InitValue are active during B's own install). (2) Yes: every
// app's install sees exactly the rows of the apps installed before it, also without a dependency path (on the SaaS sandbox, which installs B before D,
// D saw '1=A;20=B+BX;' and D's row got '+BX' and 'B init'; the corpus CI order A, D, B is checked by the same relations).

codeunit 91420 "LT Y8 Install Order Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeqOf(App: Text): Integer
    var
        Log: Record "LT Y8 XA Install Log";
    begin
        Log.SetRange(App, App);
        if Log.FindFirst() then
            exit(Log.Seq);
        exit(-1);
    end;

    local procedure SeenOf(App: Text): Text
    var
        Log: Record "LT Y8 XA Install Log";
    begin
        Log.SetRange(App, App);
        if Log.FindFirst() then
            exit(Log.Seen);
        exit('<no log row>');
    end;

    local procedure WriterOf(RowNo: Integer): Text
    begin
        case RowNo of
            1:
                exit('A');
            10:
                exit('D');
            20:
                exit('B');
        end;
        exit('?');
    end;

    local procedure ExpectedSeen(App: Text): Text
    var
        Data: Record "LT Y8 XA Data";
        Result: Text;
    begin
        if Data.FindSet() then
            repeat
                if SeqOf(WriterOf(Data."No.")) < SeqOf(App) then
                    Result += Format(Data."No.") + '=' + Data.Note + ';';
            until Data.Next() = 0;
        exit(Result);
    end;

    local procedure NoteOf(RowNo: Integer): Text
    var
        Data: Record "LT Y8 XA Data";
    begin
        if Data.Get(RowNo) then
            exit(Data.Note);
        exit('<no row>');
    end;

    local procedure MarkOf(RowNo: Integer): Text
    var
        Data: Record "LT Y8 XA Data";
    begin
        if Data.Get(RowNo) then
            exit(Data."Y8 XB Mark");
        exit('<no row>');
    end;

    [Test]
    procedure Y8_LaterAppTableExtension_DuringEarlierInstall()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT Y8 XA Data" temporary;
    begin
        Observer.Observe('a_installed_first', Format((SeqOf('A') < SeqOf('D')) and (SeqOf('A') < SeqOf('B'))));
        Observer.Observe('row1_note', NoteOf(1));
        Observer.Observe('row1_mark', MarkOf(1));
        Observer.Observe('row20_note', NoteOf(20));
        Observer.Observe('row20_mark', MarkOf(20));
        Temp.Init();
        Temp."No." := 99;
        Temp.Note := 'T';
        Temp.Insert(true);
        Observer.Observe('control_now_note', Temp.Note);
        Observer.Observe('control_now_mark', Temp."Y8 XB Mark");
        Observer.Expect('a_installed_first', 'Yes');
        Observer.Expect('row1_note', 'A');
        Observer.Expect('row1_mark', '');
        Observer.Expect('row20_note', 'B+BX');
        Observer.Expect('row20_mark', 'B init');
        Observer.Expect('control_now_note', 'T+BX');
        Observer.Expect('control_now_mark', 'B init');
        Observer.Verify();
    end;

    [Test]
    procedure Y8_UnrelatedApps_SeeEarlierInstallRows()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT Y8 XA Install Log";
        Order: Text;
    begin
        Observer.Observe('log_rows', Format(Log.Count()));
        Observer.Observe('a_sees_expected', Format(SeenOf('A') = ExpectedSeen('A')));
        Observer.Observe('d_sees_expected', Format(SeenOf('D') = ExpectedSeen('D')));
        Observer.Observe('b_sees_expected', Format(SeenOf('B') = ExpectedSeen('B')));
        Observer.Observe('a_seen', SeenOf('A'));
        Observer.Observe('row10_has_bx_iff_b_before_d', Format(NoteOf(10).Contains('+BX') = (SeqOf('B') < SeqOf('D'))));
        Observer.Observe('row10_mark_set_iff_b_before_d', Format((MarkOf(10) <> '') = (SeqOf('B') < SeqOf('D'))));
        if Log.FindSet() then
            repeat
                Order += Log.App + '[' + Log.Seen + ']';
            until Log.Next() = 0;
        Observer.Observe('raw_order_not_asserted', Order);
        Observer.Observe('raw_row10_not_asserted', NoteOf(10) + '/' + MarkOf(10));
        Observer.Expect('log_rows', '3');
        Observer.Expect('a_sees_expected', 'Yes');
        Observer.Expect('d_sees_expected', 'Yes');
        Observer.Expect('b_sees_expected', 'Yes');
        Observer.Expect('a_seen', '');
        Observer.Expect('row10_has_bx_iff_b_before_d', 'Yes');
        Observer.Expect('row10_mark_set_iff_b_before_d', 'Yes');
        Observer.Ignore('raw_order_not_asserted'); // install order differs per host: observed, not asserted
        Observer.Ignore('raw_row10_not_asserted'); // depends on the install order: observed, not asserted
        Observer.Verify();
    end;
}
