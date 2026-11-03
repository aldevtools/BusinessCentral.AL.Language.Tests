// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT P87 Helper (codeunit 74228)
// Probe: written against BC 29 (runtime 16); every value is observed through Probe Observer and measured later on real BC 29. No request is ever sent.
// Facts: which header names are accepted by which HttpHeaders collection (request, request content, stand-alone content, response, response content)
// BC versions: 29

codeunit 74222 "LT P87 Header Matrix"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Kind: Integer; FromIdx: Integer; ToIdx: Integer)
    var
        Helper: Codeunit "LT P87 Helper";
        Names: List of [Text];
        i: Integer;
    begin
        Helper.Names(Names);
        for i := FromIdx to ToIdx do begin
            if not ((Kind = 5) and (Names.Get(i) in ['Content-Length', 'Transfer-Encoding'])) then
                if not ((Kind = 3) and (Names.Get(i) = 'Transfer-Encoding')) then
                    Observer.Observe(Names.Get(i), Helper.Matrix(Kind, Names.Get(i)));
        end;
    end;

    [Test]
    procedure MatrixRequestHeaders_Part1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 1, 2);
        Observer.Expect('Cache-Control', 'add=added;has=Yes;get=Yes/n=1/1=no-cache/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('Range', 'add=added;has=Yes;get=Yes/n=1/1=bytes=0-9/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 3, 4);
        Observer.Expect('If-Match', 'add=added;has=Yes;get=Yes/n=1/1="abc"/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('If-None-Match', 'add=added;has=Yes;get=Yes/n=1/1="abc"/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 5, 6);
        Observer.Expect('Content-Disposition', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('Content-Encoding', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 7, 8);
        Observer.Expect('Content-Language', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('Content-Length', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 9, 10);
        Observer.Expect('Expires', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('Last-Modified', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 11, 12);
        Observer.Expect('Authorization', 'add=added;has=Yes;get=Yes/n=1/1=Bearer abc/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('User-Agent', 'add=added;has=Yes;get=Yes/n=1/1=LT/1.0/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part7()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 13, 14);
        Observer.Expect('Accept', 'add=added;has=Yes;get=Yes/n=1/1=application/json/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('Accept-Encoding', 'add=added;has=Yes;get=Yes/n=1/1=gzip/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 15, 16);
        Observer.Expect('Content-Type', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('Host', 'add=added;has=Yes;get=Yes/n=1/1=a.example/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 17, 18);
        Observer.Expect('Connection', 'add=added;has=Yes;get=Yes/n=1/1=close/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('Transfer-Encoding', 'add=added;has=Yes;get=Yes/n=1/1=chunked/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestHeaders_Part10()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 19, 19);
        Observer.Expect('X-Custom', 'add=added;has=Yes;get=Yes/n=1/1=v/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 1, 2);
        Observer.Expect('Cache-Control', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('Range', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 3, 4);
        Observer.Expect('If-Match', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('If-None-Match', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 5, 6);
        Observer.Expect('Content-Disposition', 'add=added;has=Yes;get=Yes/n=1/1=attachment; filename="a.txt"/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('Content-Encoding', 'add=added;has=Yes;get=Yes/n=1/1=gzip/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 7, 8);
        Observer.Expect('Content-Language', 'add=added;has=Yes;get=Yes/n=1/1=en/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('Content-Length', 'add=added;has=Yes;get=Yes/n=1/1=5/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 9, 10);
        Observer.Expect('Expires', 'add=added;has=Yes;get=Yes/n=1/1=Tue, 15 Nov 1994 08:12:31 GMT/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('Last-Modified', 'add=added;has=Yes;get=Yes/n=1/1=Tue, 15 Nov 1994 08:12:31 GMT/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 11, 12);
        Observer.Expect('Authorization', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('User-Agent', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part7()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 13, 14);
        Observer.Expect('Accept', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('Accept-Encoding', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 15, 16);
        Observer.Expect('Content-Type', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];has=Yes;get=Yes/n=1/1=text/plain; charset=utf-8/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('Host', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 17, 18);
        Observer.Expect('Connection', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('Transfer-Encoding', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixRequestContentHeaders_Part10()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 19, 19);
        Observer.Expect('X-Custom', 'add=added;has=Yes;get=Yes/n=1/1=v/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 1, 2);
        Observer.Expect('Cache-Control', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('Range', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 3, 4);
        Observer.Expect('If-Match', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('If-None-Match', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 5, 6);
        Observer.Expect('Content-Disposition', 'add=added;has=Yes;get=Yes/n=1/1=attachment; filename="a.txt"/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('Content-Encoding', 'add=added;has=Yes;get=Yes/n=1/1=gzip/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 7, 8);
        Observer.Expect('Content-Language', 'add=added;has=Yes;get=Yes/n=1/1=en/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('Content-Length', 'add=added;has=Yes;get=Yes/n=1/1=5/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 9, 10);
        Observer.Expect('Expires', 'add=added;has=Yes;get=Yes/n=1/1=Tue, 15 Nov 1994 08:12:31 GMT/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('Last-Modified', 'add=added;has=Yes;get=Yes/n=1/1=Tue, 15 Nov 1994 08:12:31 GMT/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 11, 12);
        Observer.Expect('Authorization', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('User-Agent', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part7()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 13, 14);
        Observer.Expect('Accept', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('Accept-Encoding', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 15, 16);
        Observer.Expect('Content-Type', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];has=Yes;get=Yes/n=1/1=text/plain; charset=utf-8/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('Host', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 17, 18);
        Observer.Expect('Connection', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixStandaloneContentHeaders_Part10()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 19, 19);
        Observer.Expect('X-Custom', 'add=added;has=Yes;get=Yes/n=1/1=v/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 1, 2);
        Observer.Expect('Cache-Control', 'add=added;has=Yes;get=Yes/n=1/1=no-cache/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('Range', 'add=added;has=Yes;get=Yes/n=1/1=bytes=0-9/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 3, 4);
        Observer.Expect('If-Match', 'add=added;has=Yes;get=Yes/n=1/1="abc"/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('If-None-Match', 'add=added;has=Yes;get=Yes/n=1/1="abc"/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 5, 6);
        Observer.Expect('Content-Disposition', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('Content-Encoding', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 7, 8);
        Observer.Expect('Content-Language', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('Content-Length', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 9, 10);
        Observer.Expect('Expires', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('Last-Modified', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 11, 12);
        Observer.Expect('Authorization', 'add=added;has=Yes;get=Yes/n=1/1=Bearer abc/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('User-Agent', 'add=added;has=Yes;get=Yes/n=1/1=LT/1.0/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part7()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 13, 14);
        Observer.Expect('Accept', 'add=added;has=Yes;get=Yes/n=1/1=application/json/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('Accept-Encoding', 'add=added;has=Yes;get=Yes/n=1/1=gzip/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 15, 16);
        Observer.Expect('Content-Type', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('Host', 'add=added;has=Yes;get=Yes/n=1/1=a.example/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 17, 18);
        Observer.Expect('Connection', 'add=added;has=Yes;get=Yes/n=1/1=close/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('Transfer-Encoding', 'add=added;has=Yes;get=Yes/n=1/1=chunked/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseHeaders_Part10()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4, 19, 19);
        Observer.Expect('X-Custom', 'add=added;has=Yes;get=Yes/n=1/1=v/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 1, 2);
        Observer.Expect('Cache-Control', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('Range', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 3, 4);
        Observer.Expect('If-Match', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('If-None-Match', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 5, 6);
        Observer.Expect('Content-Disposition', 'add=added;has=Yes;get=Yes/n=1/1=attachment; filename="a.txt"/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('Content-Encoding', 'add=added;has=Yes;get=Yes/n=1/1=gzip/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 7, 8);
        Observer.Expect('Content-Language', 'add=added;has=Yes;get=Yes/n=1/1=en/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 9, 10);
        Observer.Expect('Expires', 'add=added;has=Yes;get=Yes/n=1/1=Tue, 15 Nov 1994 08:12:31 GMT/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('Last-Modified', 'add=added;has=Yes;get=Yes/n=1/1=Tue, 15 Nov 1994 08:12:31 GMT/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 11, 12);
        Observer.Expect('Authorization', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('User-Agent', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part7()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 13, 14);
        Observer.Expect('Accept', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('Accept-Encoding', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 15, 16);
        Observer.Expect('Content-Type', 'add=added;has=Yes;get=Yes/n=1/1=text/plain/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Expect('Host', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 17, 18);
        Observer.Expect('Connection', 'add=E[The requested operation cannot be perfor|InvalidOperation];has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation];get=No/n=0/1=/2=;rm=No;raw=No;has3=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure MatrixResponseContentHeaders_Part10()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 19, 19);
        Observer.Expect('X-Custom', 'add=added;has=Yes;get=Yes/n=1/1=v/2=;rm=Yes;raw=Yes;has3=Yes');
        Observer.Verify();
    end;

}
