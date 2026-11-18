#!/usr/bin/env python3
"""Pick the test codeunits that a change can affect, so that CI runs those instead of the whole suite.

    select-tests.py --base REV [--head REV] [--merge-base] [--repo DIR] [--json FILE] [--github]
    select-tests.py --full-reason TEXT [--head REV] [--repo DIR] [--json FILE] [--github]
    select-tests.py --codeunits JSON [--head REV] [--repo DIR] [--json FILE] [--github]
    select-tests.py --check-reuse JSON --head REV [--repo DIR]

The change is the tree diff from the merge base of BASE and HEAD to HEAD (three dots, BASE...HEAD): what HEAD changed
since it left BASE. For a pull request BASE is the merge commit's first parent, which is also the merge base. For a
dispatched run BASE is select_base (for example al-runtime-rs-staging): a branch cut from master or from an older
staging then stays a subset run after master and staging move on. In a shallow clone with no merge base the script
fetches the missing history first. Both trees are read from git objects, so no checkout of either is needed.

What is selected, per test job of .github/workflows/ci.yml:
  * every test codeunit (Subtype = Test, at least one [Test] procedure) declared in a changed file, and
  * every test codeunit that references a changed object, directly or through other objects: an object that names a
    changed object by name or id is itself treated as changed, until nothing new is found. An extension object
    (tableextension, pageextension, enumextension, ...) also counts as a change of the object it extends. A changed
    object is one whose code changed, not every object of a changed file.
  * event subscribers: an object that runs a publisher may run its automatic subscribers, so the tests that use the
    publisher are selected for a changed subscriber (Graph.fires). A Manual subscriber runs only once bound, which names
    its codeunit. A subscriber that can run in any test (platform publisher, install or upgrade event, a publisher more
    than MAX_PUBLISHER_USERS test codeunits use, a name the scan cannot resolve) means a full run.
  * shared fixtures (CONTRIBUTING.md, standing rule 3; check-fixture-edit.py classifies the edit): an edit that is an
    allowed addition also selects every test codeunit that can read an object without naming it (SCAN_BLIND); any other
    edit, or a failed check, means a full run.
  * every job also runs one small test codeunit outside any #if (the sentinel): the reusable workflow fails a leg that
    ran no test at all, and a selected codeunit can be compiled out on an older BC version. The leg still compiles and
    publishes every app.
Only codeunits inside the job's own codeunit_range are selected, so a codeunit the full run leaves out stays out.

--codeunits (ci.yml: the workflow_dispatch input select_codeunits) skips the diff and uses a given selection: a JSON
object {test app dir: "50010,50012..50015|50020"}. The corpus CI batcher passes the union of the selections it made for
each branch of a batch alone: the selection of the merged diff would mostly be a full run (more than MAX_FILES files).
Only runnable test codeunits of the job's range are kept (a range never pulls in a Subtype = Test codeunit without a
[Test] procedure); every app still gets its sentinel; an app the input leaves out gets only its sentinel, and
ci-shards.py then starts no shard for it. An input that cannot be read, or that names an app no test job reads the selection for, means a full run.

A change to ci.yml that edits nothing but the values of codeunit_range lines (a "CI range edit") is no reason for a
full run: the selection is made as usual, plus every test codeunit the edit brings into its job's range.

A full run is chosen instead when the change touches something a reference scan cannot follow (the rules are in
FULL_RULES below and in CONTRIBUTING.md, "Test selection in CI"). Any error in this script also means a full run.
Every full-run reason has a kind (reason_kinds in --json, same order as reasons); readers match the kind, not the text.

--check-reuse (the al-runtime-rs corpus bump, ADR-077) asks whether results reused from an older commit still hold at
HEAD: a JSON object {source commit: {test app dir: "ids"}}. A result of codeunit K from commit S holds at HEAD only when
the selection of S..HEAD (two dots, no file cap) is a subset run that does not select K; a full-run reason of a kind in
REUSE_KINDS does not count. The exit code is 1 when any result is refused (each is printed) or the check fails, else 0.

Output: the step summary (--github: $GITHUB_STEP_SUMMARY), and the job output `subset` ($GITHUB_OUTPUT): a JSON object
{test app dir: "id,id,..."}; {} means a full run. ci.yml passes the value as codeunit_range, or the job's full range
when its key is missing. --json FILE writes the whole result (mode, reasons, per app selection with the why).
"""
import argparse
import importlib.util
import io
import json
import os
import re
import subprocess
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
CI_YML = '.github/workflows/ci.yml'
MAX_FILES = 50
# The full-run reasons that do not make a reused result stale (--check-reuse): the file cap (a span of many merges passes
# it, and --check-reuse computes the selection without it), and an empty diff or one that no test app reads.
REUSE_KINDS = {'file-cap', 'nothing-to-select', 'no-changed-files'}

# Paths outside the CI apps that no CI leg reads. A change to anything else outside the CI apps means a full run.
IGNORED_OUTSIDE_APPS = (
    re.compile(r'^docs/'), re.compile(r'^scripts/'), re.compile(r'^\.claude/'), re.compile(r'^tests/must-not-compile/'),
    re.compile(r'^[^/]+\.md$'), re.compile(r'^tests/[^/]+\.md$'), re.compile(r'^tests/al-surface(-inscope)?\.json$'),
    re.compile(r'^(tests/)?v2-classification\.json$'), re.compile(r'^\.gitignore$'),
    # The restructure rename map and facts-changes file: read by facts.py (coverage-facts job) and by al-runtime-rs, never by a BC leg.
    re.compile(r'^tests/rename-map\.tsv$'), re.compile(r'^tests/facts-changes\.tsv$'),
    # The Windows nightly's own files: ci.yml and the scripts it runs never read them.
    re.compile(r'^\.github/nightly-windows/'), re.compile(r'^\.github/workflows/nightly-windows\.yml$'),
)
# Files inside a CI app that the compile does not read.
IGNORED_INSIDE_APP = re.compile(r'(\.md|\.py|/bc-full-results\.json|/\.dev/.*)$')

KINDS = ('codeunit', 'table', 'tableextension', 'page', 'pageextension', 'pagecustomization', 'report', 'reportextension',
         'query', 'xmlport', 'enum', 'enumextension', 'permissionset', 'permissionsetextension', 'interface',
         'controladdin', 'profile', 'entitlement')
EXTENSION_KINDS = {'tableextension', 'pageextension', 'pagecustomization', 'reportextension', 'enumextension',
                   'permissionsetextension'}
PERMISSION_KINDS = {'permissionset', 'permissionsetextension', 'entitlement'}

# One pass over the source: comments (dropped), strings, quoted identifiers, braces, everything else.
LEX = re.compile(r"//[^\n]*|/\*.*?\*/|'(?:[^']|'')*'|\"[^\"\n]*\"|[{}]|[^/'\"{}]+|/", re.S)
WORD = re.compile(r'[A-Za-z_][A-Za-z0-9_]*|\d+')
NAME = r'(?:"[^"\n]*"|[A-Za-z_][A-Za-z0-9_]*)'
QUALIFIED = r'(?:(?:%s)\s*\.\s*)*%s' % (NAME, NAME)
HEADER = re.compile(r'\b(%s)\b(?:\s+(\d+))?\s+(%s)(?:\s+(?:extends|customizes)\s+(%s))?' % ('|'.join(KINDS), NAME, QUALIFIED),
                    re.I | re.S)
DOTNET_HEADER = re.compile(r'\bdotnet\s*$', re.I)
DOTNET_ALIAS = re.compile(r'\btype\s*\(\s*"[^"]*"\s*;\s*(%s)\s*\)' % NAME, re.I)
SUBTYPE = re.compile(r'\bSubtype\s*=\s*(\w+)\s*;', re.I)
TEST_ATTR = re.compile(r'\[\s*Test\s*\]', re.I)
HANDLER_ATTR = re.compile(r'\[\s*HandlerFunctions\s*\(', re.I)
SUBSCRIBER_ATTR = re.compile(r'\[\s*EventSubscriber\s*\(', re.I)
# [EventSubscriber(ObjectType::Table, Database::"X", 'OnAfterInsertEvent', ...)]: the publisher's type, its name or id, the event.
SUBSCRIBER_ARGS = re.compile(r"\[\s*EventSubscriber\s*\(\s*ObjectType\s*::\s*(\w+)\s*,\s*(?:\w+\s*::\s*(%s)|(\d+))\s*,\s*"
                             r"('(?:[^']|'')*'|%s)" % (QUALIFIED, NAME), re.I)
MANUAL = re.compile(r'\bEventSubscriberInstance\s*=\s*Manual\s*;', re.I)
SINGLE_INSTANCE = re.compile(r'\bSingleInstance\s*=\s*true\s*;', re.I)
PUBLISHER_KINDS = {'table': 'table', 'codeunit': 'codeunit', 'page': 'page', 'report': 'report', 'query': 'query',
                   'xmlport': 'xmlport'}
# Platform codeunits whose events fire in every session or around install and upgrade, whatever a test names. They are
# not corpus objects, so a subscriber to them is unresolved anyway; the list keeps that true if a corpus object ever
# takes one of these names.
GLOBAL_PUBLISHERS = {'global triggers', 'system initialization', 'company triggers', 'extension triggers',
                     'system action triggers', 'database triggers', 'navapp triggers'}
GLOBAL_EVENT = re.compile(r'install|upgrade', re.I)
# A subscriber is selected by the tests that use its publisher only while at most this many test codeunits use the
# publisher (directly or through other objects). Above it the publisher is shared fixture: a subscriber there changes
# the behavior of many unrelated tests, and effects between codeunits that a subset run does not reproduce
# (SingleInstance state, rows an earlier codeunit left) become likely. Measured on al-runtime-rs-staging, 2026-10-19:
# the publishers of the subscribers writers add for their own objects were used by 0 to 13 test codeunits; the shared
# fixture publishers ("ALT Triggered", "ALT Event Publisher", "ALT Subscribed Table", ...) by 255 to 258, mostly
# through "ALTFixtureCleanup". 40 is three times the largest narrow one and far below the shared ones.
MAX_PUBLISHER_USERS = 40
PREPROCESSOR_IF = re.compile(r'^\s*#if\b', re.I | re.M)
# Test codeunits the name scan cannot tie to the objects they read (scan-blind): they name a metadata or system table
# (AllObj, Field, Page Control Field, ..., or a table id 2000000000 and up), Open a RecordRef or Query by a value that is
# no literal id, or Run a page, codeunit, report, xmlport or query by a variable. A shared fixture changed by an addition
# also runs every one of them (CONTRIBUTING.md, standing rule 3). On master 2cf60e0e: 213, 81 and 103 test codeunits,
# 367 in all.
_META = (r'AllObj|AllObjWithCaption|Field|Key|Table Metadata|Page Metadata|Page Control Field|All Control Fields|'
         r'Codeunit Metadata|CodeUnit Metadata|Report Metadata|Query Metadata|Table Information|Event Subscription|'
         r'Application Object Metadata|Page Action|Table Field Types|Table Relations Metadata|Page Table Field|'
         r'Report Data Items|Object|Object Metadata|Expanded Permission|Permission|Tenant Permission|Enum Metadata|'
         r'Table Synch\. Setup|Database Key Groups|Page Info And Fields|Page Data Personalization|Api Web Service|'
         r'Page Documentation')
SCAN_BLIND = (
    re.compile(r'\b(?:Record|Database\s*::|RecordRef|Query)\s+"?(?:%s)"?\s*(?:;|\)|,|temporary)|\bDatabase\s*::\s*"?(?:%s)"?'
               r'(?![\w ])|\b20000000\d\d\b|\b2000000[12]\d\d\b' % (_META, _META), re.I),
    re.compile(r'\.\s*Open\s*\(\s*(?!Database\s*::)(?!\d+\s*[,)])[A-Za-z_"]', re.I),
    re.compile(r'\b(?:Page|Codeunit|Report|Xmlport|Query)\s*\.\s*(?:Run|RunModal|Execute|SaveAs\w*|Export|Import)\s*\(\s*'
               r'(?!(?:Page|Codeunit|Report|Xmlport|Query)\s*::)(?!\d+\s*[,)])[A-Za-z_"]', re.I),
)


KIND_WORD = re.compile(r'\b(?:%s)\b' % '|'.join(KINDS), re.I)
HEADER_TAIL = re.compile(r'\s*(?:implements\b[^{]*)?', re.I)


def declaration(head_text):
    """The object declaration of the text before an object's '{': the last one that reaches the '{' (only an
    implements clause may follow), so a stray line such as "report 98103, test codeunit 98104" above it is not read as
    the declaration. Without such a match, the last declaration found anywhere in the text."""
    for k in reversed([m.start() for m in KIND_WORD.finditer(head_text)]):
        m = HEADER.match(head_text, k)
        if m and HEADER_TAIL.fullmatch(head_text, m.end()):
            return m
    hm = None
    for hm in HEADER.finditer(head_text):
        pass
    return hm


def has_code(text):
    """False for a file of comments and blank lines only."""
    return any(not (t.startswith('//') or t.startswith('/*') or t.isspace()) for t in (m.group(0) for m in LEX.finditer(text)))


def unquote(name):
    name = name.strip()
    if name.startswith('"') and name.endswith('"'):
        name = name[1:-1]
    return name.lower()


def last_name(qualified):
    """The object name of a possibly namespaced name: Microsoft.Sales."Gen. Jnl.-Post" -> gen. jnl.-post."""
    return unquote(re.findall(NAME, qualified)[-1])


class Obj:
    __slots__ = ('path', 'kind', 'id', 'name', 'display', 'target', 'subtype', 'tests', 'handlers', 'subscriber', 'size',
                 'tokens', 'aliases', 'conditional', 'subscriptions', 'manual', 'single', 'text')

    def keys(self):
        """What other objects use to name this one."""
        k = {self.name} if self.name else set()
        if self.id:
            k.add(self.id)
        if self.target:
            k.add(self.target)
        k.update(self.aliases)
        return k

    def label(self):
        return ' '.join(x for x in (self.kind, self.id, '"%s"' % self.display if self.display else None) if x)


def parse_al(path, text):
    """The top-level objects of one .al file. An object's tokens are the identifiers, quoted identifiers, numbers and
    string literals of its header and body, lower-cased, comments left out."""
    objs = []
    depth = 0
    header = []
    body = []
    conditional = bool(PREPROCESSOR_IF.search(text))
    for m in LEX.finditer(text):
        t = m.group(0)
        if t.startswith('//') or t.startswith('/*'):
            continue
        if depth == 0:
            if t == '{':
                depth = 1
                body = []
                head_tokens = header
                head_text = ''.join(header)
                header = []
                hm = declaration(head_text)
                o = Obj()
                o.path, o.aliases, o.conditional = path, set(), conditional
                if hm is not None:
                    o.kind, o.id, o.name = hm.group(1).lower(), hm.group(2), unquote(hm.group(3))
                    o.display = hm.group(3).strip().strip('"')
                    target = hm.group(4)
                    o.target = last_name(target) if target else None
                    if o.kind not in EXTENSION_KINDS:
                        o.target = None
                elif DOTNET_HEADER.search(head_text):
                    o.kind, o.id, o.name, o.display, o.target = 'dotnet', None, None, None, None
                else:
                    o.kind = None  # not an object we can read: the caller decides
                    o.id = o.name = o.display = o.target = None
                o.tokens = head_tokens
                objs.append(o)
            else:
                header.append(t)
            continue
        if t == '{':
            depth += 1
        elif t == '}':
            depth -= 1
            if depth == 0:
                finish(objs[-1], body)
                continue
        body.append(t)
    return objs


def words(parts):
    tokens = set()
    for part in parts:
        if part.startswith("'"):
            tokens.add(part[1:-1].replace("''", "'").lower())
        elif part.startswith('"'):
            tokens.add(part[1:-1].lower())
        else:
            tokens.update(w.lower() for w in WORD.findall(part))
    return tokens


def finish(o, body):
    text = ''.join(body)
    # what the object is, comments left out and whitespace outside strings folded: equal text = unchanged object
    o.text = ''.join(t if t[:1] in '\'"' else re.sub(r'\s+', ' ', t) for t in o.tokens + body).strip()
    head, tokens = words(o.tokens), words(body)
    # The header's own id and name are not a reference: without this, table 60985 would "name" codeunit 60985.
    o.tokens = tokens | (head - {o.id, o.name})
    sm = SUBTYPE.search(text)
    o.subtype = sm.group(1).lower() if (sm and o.kind == 'codeunit') else None
    o.tests = len(TEST_ATTR.findall(text)) if o.subtype == 'test' else 0
    o.handlers = bool(HANDLER_ATTR.search(text))
    o.subscriber = bool(SUBSCRIBER_ATTR.search(text))
    # one (publisher kind, publisher name or id, event) per [EventSubscriber]; None for one this scan cannot read
    subs = [(m.group(1).lower(), last_name(m.group(2)) if m.group(2) else m.group(3),
             unquote(m.group(4).strip("'"))) for m in SUBSCRIBER_ARGS.finditer(text)]
    o.subscriptions = subs + [None] * (len(SUBSCRIBER_ATTR.findall(text)) - len(subs))
    o.manual = bool(MANUAL.search(text))
    o.single = bool(SINGLE_INSTANCE.search(text))
    o.size = len(text)
    if o.kind == 'dotnet':
        o.aliases = {unquote(a) for a in DOTNET_ALIAS.findall(text)}


# ---------- git ----------

class Git:
    def __init__(self, repo):
        self.repo = repo

    def run(self, *args, binary=False):
        p = subprocess.run(['git', '-C', self.repo] + list(args), capture_output=True)
        if p.returncode != 0:
            raise RuntimeError('git %s: %s' % (' '.join(args), p.stderr.decode(errors='replace').strip()))
        return p.stdout if binary else p.stdout.decode('utf-8', errors='replace')

    def rev(self, rev):
        return self.run('rev-parse', '--verify', rev + '^{commit}').strip()

    def merge_base(self, base, head):
        try:
            return self.run('merge-base', base, head).strip()
        except RuntimeError:
            if self.run('rev-parse', '--is-shallow-repository').strip() != 'true':
                raise
        # a CI checkout (depth 2, select_base fetched with depth 1) has no common history yet: fetch it, then retry
        self.run('fetch', '--no-tags', '--quiet', '--unshallow', 'origin', base, head)
        return self.run('merge-base', base, head).strip()

    def changed(self, base, head):
        out = self.run('diff', '--name-only', '--no-renames', '-z', base, head)
        return sorted(f for f in out.split('\0') if f)

    def files(self, rev):
        return [f for f in self.run('ls-tree', '-r', '-z', '--name-only', rev).split('\0') if f]

    def read(self, rev, paths):
        """{path: text} for the paths that exist in rev."""
        paths = list(paths)
        if not paths:
            return {}
        out = {}
        data = subprocess.run(['git', '-C', self.repo, 'cat-file', '--batch'], capture_output=True,
                              input=''.join('%s:%s\n' % (rev, p) for p in paths).encode()).stdout
        pos = 0
        for p in paths:
            nl = data.index(b'\n', pos)
            head = data[pos:nl].decode(errors='replace').split(' ')
            pos = nl + 1
            if len(head) == 2 and head[1] == 'missing':
                continue
            size = int(head[2])
            out[p] = data[pos:pos + size].decode('utf-8-sig', errors='replace')
            pos += size + 1
        return out


# ---------- ci.yml ----------

RANGE_EXPR = re.compile(r"^\$\{\{\s*fromJson\(needs\.prepare\.outputs\.subset\)\[\s*'([^']+)'\s*\]\s*\|\|\s*'([^']*)'\s*\}\}$")


def parse_ci(text):
    """The jobs of ci.yml that call the BC test workflow: [{job, app_dirs, test_app_dirs, range, key}]. `key` is the
    subset key the job's codeunit_range reads, or None when the job always runs its full range."""
    jobs, cur, in_jobs = [], None, False
    lines = text.split('\n')
    i = 0
    while i < len(lines):
        line = lines[i]
        if re.match(r'^jobs:\s*$', line):
            in_jobs = True
        elif in_jobs and re.match(r'^  ([A-Za-z0-9_-]+):\s*$', line):
            cur = {'job': line.strip()[:-1], 'with': {}}
            jobs.append(cur)
        elif cur is not None:
            m = re.match(r'^      ([a-z_]+):\s*(.*?)\s*$', line)
            if m and lines_in_with(lines, i):
                key, val = m.group(1), m.group(2)
                if val in ('|', '|-', '>'):
                    vals = []
                    while i + 1 < len(lines) and (lines[i + 1].startswith('        ') or not lines[i + 1].strip()):
                        i += 1
                        if lines[i].strip():
                            vals.append(lines[i].strip())
                    val = '\n'.join(vals)
                elif len(val) >= 2 and val[0] == val[-1] and val[0] in '"\'':
                    val = val[1:-1]
                cur['with'][key] = val
        i += 1
    out = []
    for j in jobs:
        w = j['with']
        if 'test_app_dirs' not in w or 'codeunit_range' not in w:
            continue
        rng, key = w['codeunit_range'], None
        m = RANGE_EXPR.match(rng)
        if m:
            key, rng = m.group(1), m.group(2)
        out.append({'job': j['job'], 'app_dirs': [d for d in w.get('app_dirs', '').split('\n') if d],
                    'test_app_dirs': [d for d in w['test_app_dirs'].split('\n') if d], 'range': rng, 'key': key})
    return out


def lines_in_with(lines, i):
    """True when line i sits under a `    with:` key of its job."""
    for k in range(i - 1, -1, -1):
        s = lines[k]
        if re.match(r'^    [a-z_-]+:', s):
            return s.strip() == 'with:'
        if re.match(r'^  \S', s):
            return False
    return False


RANGE_LINE = re.compile(r'^      codeunit_range:\s*(.*?)\s*$')


def range_line_key(lines, i):
    """For a codeunit_range line of a test job: ('key', subset key or None). None when line i is not one."""
    m = RANGE_LINE.match(lines[i])
    if not m or not lines_in_with(lines, i):
        return None
    k = RANGE_EXPR.match(m.group(1))
    return ('key', k.group(1) if k else None)


def ci_range_edit(base_text, head_text):
    """True when ci.yml changed, but only in the values of codeunit_range lines (a "CI range edit"): same lines
    otherwise, and every changed codeunit_range line still reads the same subset key (or still none)."""
    b, h = base_text.split('\n'), head_text.split('\n')
    if len(b) != len(h):
        return False
    diff = [i for i, (x, y) in enumerate(zip(b, h)) if x != y]
    return bool(diff) and all(range_line_key(b, i) is not None and range_line_key(b, i) == range_line_key(h, i)
                              for i in diff)


def spans(expr):
    out = []
    for part in expr.replace('|', ',').split(','):
        part = part.strip()
        if not part:
            continue
        lo, _, hi = part.partition('..')
        try:
            out.append((int(lo), int(hi or lo)))
        except ValueError:
            pass
    return out


def in_spans(sp, cid):
    return any(lo <= cid <= hi for lo, hi in sp)


# ---------- the selection ----------

def app_of(path, app_dirs):
    for d in app_dirs:
        if path.startswith(d.rstrip('/') + '/'):
            return d
    return None


class Head:
    """What a selection needs of HEAD, read once and shared by every diff to it (--check-reuse): the test jobs of ci.yml,
    the files, and, on first use, the objects with their reference graph."""

    def __init__(self, git, head, ci_text=None):
        self.git, self.head = git, head
        self.ci = parse_ci(ci_text if ci_text is not None else git.read(head, [CI_YML]).get(CI_YML, ''))
        self.test_apps = {}
        for j in self.ci:
            for d in j['test_app_dirs']:
                self.test_apps.setdefault(d, []).append(j)
        self.ci_apps = sorted({d for j in self.ci for d in j['app_dirs'] + j['test_app_dirs']}, key=len, reverse=True)
        self.all_files = git.files(head)
        self.app_resources = resource_dirs(git, head, self.ci_apps)
        self.objs = None

    def load(self):
        if self.objs is not None:
            return self
        al_files = [f for f in self.all_files if f.endswith('.al') and app_of(f, self.ci_apps)]
        self.texts = self.git.read(self.head, al_files)
        self.objs = []
        for f in al_files:
            self.objs.extend(parse_al(f, self.texts[f]))
        index = {}
        for n, o in enumerate(self.objs):
            for t in o.tokens:
                index.setdefault(t, []).append(n)
        self.by_path = {}
        for n, o in enumerate(self.objs):
            self.by_path.setdefault(o.path, []).append(n)
        self.runnable = runnable_fn(self.objs, self.test_apps)
        self.graph = Graph(self.objs, index, self.runnable,
                           lambda: microsoft_names(self.git, self.head, self.all_files, self.ci_apps))
        self.scan_blind = [n for n, o in enumerate(self.objs) if self.runnable(n) and any(p.search(o.text) for p in SCAN_BLIND)]
        return self


def fixture_check():
    """check-fixture-edit.py, the owner of the fixture edit rule (CONTRIBUTING.md, standing rule 3)."""
    spec = importlib.util.spec_from_file_location('check_fixture_edit', os.path.join(HERE, 'check-fixture-edit.py'))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def select(git, base, head, merge_base=True, ci_text=None, max_files=MAX_FILES, loaded=None):
    """The selection for the diff base..head (base...head with merge_base). max_files=None: no file cap (--check-reuse
    needs the selection of a long span). loaded: a Head of the same head, to share its graph between diffs."""
    head = git.rev(head)
    base = git.rev(base)
    if merge_base:
        base = git.merge_base(base, head)
    result = {'base': base, 'head': head, 'mode': 'subset', 'reasons': [], 'reason_kinds': [], 'changed_files': [], 'apps': {}}
    h = loaded if loaded is not None else Head(git, head, ci_text)
    if h.head != head:
        raise ValueError('the loaded head is %s, not %s' % (h.head, head))
    ci, test_apps, ci_apps, all_files = h.ci, h.test_apps, h.ci_apps, h.all_files
    if not ci:
        return full(result, ('ci-unreadable', 'could not read the test jobs of %s' % CI_YML))
    unwired = [j['job'] for j in ci if not j['key']]
    if len(unwired) == len(ci):
        return full(result, ('ci-unwired', 'no test job of %s reads the selection' % CI_YML))
    dependency_only = sorted(set(ci_apps) - set(test_apps))

    changed = git.changed(base, head)
    result['changed_files'] = changed
    if not changed:
        return full(result, ('no-changed-files', 'no changed files between %s and %s' % (base[:10], head[:10])))

    ci_texts = git.read(base, [CI_YML]), git.read(head, [CI_YML])
    range_edit = CI_YML in changed and ci_range_edit(ci_texts[0].get(CI_YML, ''), ci_texts[1].get(CI_YML, ''))
    app_resources = h.app_resources
    relevant, ignored = [], []
    reasons = []
    for f in changed:
        app = app_of(f, ci_apps)
        if f == CI_YML and range_edit:
            result['ci_range_edit'] = [f]  # only codeunit_range values changed: select as usual
        elif f.startswith('.github/') and not any(p.search(f) for p in IGNORED_OUTSIDE_APPS):
            reasons.append(('ci-config', 'CI configuration changed: %s' % f))
        elif app is None:
            if any(p.search(f) for p in IGNORED_OUTSIDE_APPS) or test_app_outside_ci(f, all_files, ci_apps):
                ignored.append(f)
            else:
                reasons.append(('outside-apps', 'file outside the test apps that CI may read: %s' % f))
        elif app in dependency_only:
            reasons.append(('dependency-app', 'dependency app changed: %s' % f))
        elif f == app + '/app.json' or f.startswith(app + '/.alpackages/'):
            reasons.append(('manifest', 'app manifest or symbols changed: %s' % f))
        elif any(f.startswith(r + '/') for r in app_resources.get(app, ())):
            reasons.append(('resource', 'app resource changed (NavApp.ListResources sees every resource): %s' % f))
        elif IGNORED_INSIDE_APP.search(f) and not f.endswith('.al'):
            ignored.append(f)
        else:
            relevant.append(f)
    result['ignored_files'] = ignored
    if max_files is not None and len(relevant) > max_files:
        reasons.append(('file-cap', '%d changed files in the test apps (more than %d)' % (len(relevant), max_files)))
    if reasons:
        return full(result, *reasons)
    if not relevant:
        return full(result, ('nothing-to-select', 'no changed file in the test apps, so nothing to select'))

    # shared fixtures (CONTRIBUTING.md, standing rule 3): an edit beyond an addition, or a failed check, is a full run
    fixture_edits = []
    if any(f.endswith('.al') for f in relevant):
        try:
            fixture_edits = fixture_check().classify(git, base, head)
        except Exception as e:  # noqa: BLE001 - the edit could not be classified: run everything
            reasons.append(('fixture-check-failed', 'the fixture edit check failed (%s: %s)' % (type(e).__name__, e)))
        for r in fixture_edits:
            if r['class'] != 'additive':
                reasons.append(('fixture-edit-other', 'shared fixture changed beyond an addition (%s, %s): %s'
                                % (r['path'], r['object'], r['reason'])))
    if reasons:
        return full(result, *reasons)

    h.load()
    texts, objs, by_path, runnable, graph = h.texts, h.objs, h.by_path, h.runnable, h.graph

    # seeds: the changed objects of the changed files (head and base versions), objects that name a changed non-AL file.
    # An object whose text is the same on both sides is not a seed: it can only behave differently through a changed
    # object it names, and the closure reaches it from there.
    base_texts = git.read(base, [f for f in relevant if f.endswith('.al')])
    seeds = []  # (description, keys, head object indices, needs_coverage, follow_events)
    why = {}  # every test codeunit declared in a changed file runs, changed or not
    for f in relevant:
        if f.endswith('.al'):
            here = by_path.get(f, []) if f in texts else []
            for n in here:
                if runnable(n):
                    why[n] = 'changed: %s' % f
            base_objs = parse_al(f, base_texts[f]) if f in base_texts else []
            if f in texts and not here and has_code(texts[f]):
                reasons.append(('unreadable', 'no AL object found in %s' % f))
            if file_scope(texts.get(f, '')) != file_scope(base_texts.get(f, '')):
                base_sig, head_sig = set(), set()  # using, namespace or #define changed: every object of the file counts
            else:
                base_sig, head_sig = {sig(o) for o in base_objs}, {sig(objs[n]) for n in here}
            changed_here = [n for n in here if sig(objs[n]) not in base_sig]
            changed_base = [o for o in base_objs if sig(o) not in head_sig]
            for o in [objs[n] for n in changed_here] + changed_base:
                if o.kind is None:
                    reasons.append(('unreadable', 'an object in %s could not be read' % f))
                elif o.subtype in ('install', 'upgrade', 'testrunner'):
                    reasons.append(('subtype', 'Subtype = %s codeunit in %s' % (o.subtype.capitalize(), f)))
                elif o.kind in PERMISSION_KINDS:
                    reasons.append(('permission', '%s in %s' % (o.kind, f)))
            if changed_here:
                seeds.append(('changed: %s' % f, set(), changed_here, True, True))
            elif here and not changed_base:
                # only comments or layout changed: nothing behaves differently; run the users of the file's objects
                seeds.append(('changed (comments or layout only): %s' % f, set(), here, True, False))
            # the base version of a changed or removed subscriber fired in the tests that use its publisher
            for o in changed_base:
                pubs, cause = graph.fires(o)
                if cause:
                    reasons.append(('subscriber', 'event subscriber in %s (%s, before this change): it %s' % (f, o.label(), cause)))
                elif pubs:
                    seeds.append(('event subscriber changed or removed in %s (%s)' % (f, o.label()), set(), pubs, False,
                                  True))
            gone = {o.name for o in changed_base} - {objs[n].name for n in here}
            if gone:
                # deleted or renamed objects: the compile proves nothing else names them; follow their names anyway
                keys = set().union(*[o.keys() for o in changed_base if o.name in gone])
                seeds.append(('object removed from %s' % f, keys, [], False, True))
        else:
            base_name = f.rsplit('/', 1)[-1].lower()
            app = app_of(f, ci_apps)
            users = [n for n, o in enumerate(objs) if o.path.startswith(app + '/') and base_name in texts[o.path].lower()]
            users = sorted({n for n in users})
            if not users and f in all_files:
                reasons.append(('unnamed-file', 'no AL object names the changed file %s' % f))
            seeds.append(('changed: %s (named in %s)' % (f, ', '.join(sorted({objs[n].path for n in users})) or 'nothing'),
                          set(), users, f in all_files, True))
    if reasons:
        return full(result, *reasons)

    for desc, keys, here, needs_cover, events in seeds:
        reached, escapes = graph.closure(keys, here, events)
        for n, reason in escapes:
            reasons.append(('escape', '%s: %s %s, which %s' % (desc, 'it declares' if n in here else 'it can run',
                                                    '%s (%s)' % (objs[n].label(), objs[n].path), reason)))
        tests = {n: v for n, v in reached.items() if runnable(n)}
        if needs_cover and not tests and not escapes:
            reasons.append(('no-user', 'nothing in a test codeunit uses what %s declares, so its effect is unknown' % desc.split(': ', 1)[-1]))
        for n, v in tests.items():
            if n not in why:
                why[n] = describe(objs, v, desc)
    if reasons:
        return full(result, *reasons)
    if range_edit:
        # a test codeunit the CI range edit brings into its job's range has never run in CI: run it too
        base_ranges = {}
        for j in parse_ci(ci_texts[0].get(CI_YML, '')):
            for d in j['test_app_dirs']:
                base_ranges.setdefault(d, []).extend(spans(j['range']))
        for n in range(len(objs)):
            app = runnable(n)
            if app and n not in why and not in_spans(base_ranges.get(app, []), int(objs[n].id)):
                why[n] = 'brought into codeunit_range by the CI range edit in %s' % CI_YML
    additive = [r for r in fixture_edits if r['class'] == 'additive']
    if additive:
        seen = '%s, %s' % (additive[0]['path'], additive[0]['object'])
        for n in h.scan_blind:
            if n not in why:
                why[n] = 'can read an object without naming it (SCAN_BLIND), and a shared fixture changed by an addition: %s' % seen
    if not why:
        return full(result, ('nothing-to-select', 'nothing selected'))

    for app, jobs in sorted(test_apps.items()):
        if not any(j['key'] for j in jobs):
            continue
        picked = sorted((n for n in why if runnable(n) == app), key=lambda n: int(objs[n].id))
        entry = {'codeunits': [{'id': int(objs[n].id), 'name': objs[n].display, 'file': objs[n].path, 'why': why[n]}
                               for n in picked],
                 'test_codeunits_in_app': sum(1 for n in range(len(objs)) if runnable(n) == app)}
        # One test codeunit outside any #if always runs too: the test workflow fails a leg that runs no codeunit, and a
        # selected codeunit can be compiled out on an older BC version.
        s = sentinel(objs, [n for n in range(len(objs)) if runnable(n) == app and not objs[n].conditional])
        if s is None:
            return full(result, ('no-sentinel', 'no test codeunit without #if in %s to keep its leg running' % app))
        if s not in picked:
            entry['codeunits'].append({'id': int(objs[s].id), 'name': objs[s].display, 'file': objs[s].path,
                                       'why': 'sentinel: one small codeunit every leg runs, so that no leg runs zero codeunits',
                                       'sentinel': True})
        entry['sentinel'] = not picked
        result['apps'][app] = entry
    result['unwired_jobs'] = unwired
    return result


def runnable_fn(objs, test_apps):
    """runnable(n): the test app whose job runs objs[n] (a Subtype = Test codeunit with a [Test] procedure inside the
    job's codeunit_range), else None."""
    def runnable(n):
        o = objs[n]
        if o.subtype != 'test' or not o.tests or not o.id:
            return None
        app = app_of(o.path, list(test_apps))
        if app is None:
            return None
        if not any(in_spans(spans(j['range']), int(o.id)) for j in test_apps[app]):
            return None
        return app
    return runnable


def parse_given(text):
    """The select_codeunits input: {test app dir: [(lo, hi)]}. Raises ValueError, stricter than spans()."""
    try:
        d = json.loads(text)
    except ValueError as e:
        raise ValueError('not JSON: %s' % e)
    if not isinstance(d, dict) or not d:
        raise ValueError('not a non-empty JSON object {test app dir: "ids"}')
    out = {}
    for app, expr in d.items():
        if not isinstance(expr, str):
            raise ValueError('the value for %s is not a string' % app)
        sp = []
        for part in expr.replace('|', ',').split(','):
            part = part.strip()
            if not part:
                continue
            lo, sep, hi = (x.strip() for x in part.partition('..'))
            if not lo.isdigit() or (sep and not hi.isdigit()):
                raise ValueError('%r for %s is no id or lo..hi range' % (part, app))
            lo, hi = int(lo), int(hi) if sep else int(lo)
            if hi < lo:
                raise ValueError('range %r for %s ends before it starts' % (part, app))
            sp.append((lo, hi))
        out[app] = sp
    return out


def given(git, head, text, ci_text=None):
    """--codeunits: the given selection, checked against HEAD's objects and ci.yml (see the module docstring)."""
    head = git.rev(head)
    result = {'base': None, 'head': head, 'mode': 'subset', 'reasons': [], 'reason_kinds': [], 'changed_files': [], 'apps': {},
              'given': True}
    try:
        want = parse_given(text)
    except ValueError as e:
        return full(result, ('given-invalid', 'the select_codeunits input is not valid (%s)' % e))
    ci = parse_ci(ci_text if ci_text is not None else git.read(head, [CI_YML]).get(CI_YML, ''))
    if not ci:
        return full(result, ('ci-unreadable', 'could not read the test jobs of %s' % CI_YML))
    test_apps = {}
    for j in ci:
        for d in j['test_app_dirs']:
            test_apps.setdefault(d, []).append(j)
    wired = sorted(d for d, jobs in test_apps.items() if any(j['key'] for j in jobs))
    unknown = sorted(set(want) - set(wired))
    if unknown:
        return full(result, ('given-unknown-app', 'the select_codeunits input names %s, which is no test app whose job reads the selection'
                    % ', '.join(unknown)))
    ci_apps = sorted({d for j in ci for d in j['app_dirs'] + j['test_app_dirs']}, key=len, reverse=True)
    al_files = [f for f in git.files(head) if f.endswith('.al') and app_of(f, ci_apps)]
    texts = git.read(head, al_files)
    objs = []
    for f in al_files:
        objs.extend(parse_al(f, texts[f]))
    runnable = runnable_fn(objs, test_apps)
    for app in wired:
        cands = [n for n in range(len(objs)) if runnable(n) == app]
        sp = want.get(app, [])
        picked = sorted((n for n in cands if in_spans(sp, int(objs[n].id))), key=lambda n: int(objs[n].id))
        entry = {'codeunits': [{'id': int(objs[n].id), 'name': objs[n].display, 'file': objs[n].path,
                                'why': 'named in the select_codeunits input'} for n in picked],
                 'test_codeunits_in_app': len(cands)}
        found = {c['id'] for c in entry['codeunits']}
        if sum(hi - lo + 1 for lo, hi in sp) <= 100000:  # a listed id that is no runnable test codeunit: say so
            entry['dropped'] = sorted({i for lo, hi in sp for i in range(lo, hi + 1) if hi == lo} - found)
        s = sentinel(objs, [n for n in cands if not objs[n].conditional])
        if s is None:
            return full(result, ('no-sentinel', 'no test codeunit without #if in %s to keep its leg running' % app))
        if s not in picked:
            entry['codeunits'].append({'id': int(objs[s].id), 'name': objs[s].display, 'file': objs[s].path,
                                       'why': 'sentinel: one small codeunit every leg runs, so that no leg runs zero codeunits',
                                       'sentinel': True})
        entry['sentinel'] = not picked
        result['apps'][app] = entry
    result['unwired_jobs'] = [j['job'] for j in ci if not j['key']]
    return result


class Graph:
    """The reference graph of the test apps' objects: who may run what."""

    def __init__(self, objs, index, runnable, symbols=lambda: {}):
        self.objs, self.index, self.runnable = objs, index, runnable
        self.symbols, self.ms_names = symbols, None
        self.by_kind = {}
        for n, o in enumerate(objs):
            if o.kind in PUBLISHER_KINDS.values():
                for k in (o.name, o.id):
                    if k:
                        self.by_kind.setdefault((o.kind, k), []).append(n)
        self.users = {}

    def fires(self, o):
        """([publisher object index], None) for an object whose event subscribers may run, or ([], why) when one of
        them can run in any test. A subscriber runs when its publisher's event is raised, so whatever may run the
        publisher may run the subscriber. A Manual subscriber runs only after BindSubscription on an instance of its
        codeunit, which names the codeunit, so the plain reference scan covers it. A SingleInstance one stays bound into
        later test codeunits, so it is treated like an automatic one."""
        if not o.subscriptions or (o.manual and not o.single):
            return [], None
        out = []
        for s in o.subscriptions:
            if s is None:
                return [], 'has an [EventSubscriber] whose publisher this scan cannot read, so it can run in any test'
            kind, name, event = s
            what = '%s %s event %s' % (kind, name if name.isdigit() else '"%s"' % name, event)
            if GLOBAL_EVENT.search(event) or name in GLOBAL_PUBLISHERS:
                return [], 'subscribes to %s, which fires around install, upgrade or every session' % what
            found = self.by_kind.get((PUBLISHER_KINDS.get(kind), name))
            if not found:
                return [], ('subscribes to %s, which is not an object of the test apps (a platform, System or Base '
                            'Application object), so it can run in any test' % what)
            if self.ms_names is None:
                try:
                    self.ms_names = self.symbols()
                except Exception as e:  # noqa: BLE001 - any failure: the name check cannot be made
                    self.ms_names = 'the Microsoft symbol packages could not be read (%s: %s)' % (type(e).__name__, e)
            if isinstance(self.ms_names, str):
                return [], 'subscribes to %s; %s, so it can run in any test' % (what, self.ms_names)
            if (PUBLISHER_KINDS.get(kind), name) in self.ms_names:
                return [], ('subscribes to %s; a Microsoft object has that name too, so the scan cannot tell which one, '
                            'and it can run in any test' % what)
            for p in found:
                k = self.user_count(p)
                if k > MAX_PUBLISHER_USERS:
                    return [], 'subscribes to %s, which %d test codeunits use (more than %d)' % (what, k, MAX_PUBLISHER_USERS)
                out.append(p)
        return out, None

    def user_count(self, p):
        if p not in self.users:
            reached, _ = self.closure(set(), [p], follow_events=False)
            self.users[p] = sum(1 for n in reached if self.runnable(n))
        return self.users[p]

    def closure(self, keys, start, follow_events=True):
        """({object index: (key, from)}, escapes) for every object that names one of keys or a key of start, directly
        or through other objects, or that runs an event whose subscriber is reached; from is the object the key belongs
        to (None for a key of a removed object; key None: from is the subscriber whose publisher this is). escapes:
        [(object index, why)] for a reached object whose effect is not limited to the tests that reach it (an event
        subscriber that can run in any test, an install or upgrade codeunit)."""
        objs = self.objs
        reached = {n: None for n in start}
        work = list(start)  # reached objects whose keys and events are still to follow
        todo = [(k, None) for k in keys]
        seen, escapes = set(), []
        while work or todo:
            while todo:
                k, src = todo.pop()
                if k in seen:
                    continue
                seen.add(k)
                for n in self.index.get(k, ()):
                    if n not in reached:
                        reached[n] = (k, src)
                        work.append(n)
            while work:
                n = work.pop()
                todo.extend((k, n) for k in objs[n].keys())
                if not follow_events:
                    continue
                if objs[n].subtype in ('install', 'upgrade'):
                    escapes.append((n, 'runs when the app is installed or upgraded, before any test'))
                pubs, why = self.fires(objs[n])
                if why:
                    escapes.append((n, why))
                for p in pubs:
                    if p not in reached:
                        reached[p] = (None, n)
                        work.append(p)
        return reached, escapes


SYMBOL_KINDS = {'Tables': 'table', 'Codeunits': 'codeunit', 'Pages': 'page', 'Reports': 'report', 'Queries': 'query',
                'XmlPorts': 'xmlport'}


def microsoft_names(git, rev, files, ci_apps):
    """{(kind, lower-case name)} of the objects in the symbol packages (.alpackages/*.app) of the CI apps. A package
    that cannot be read raises, and the caller makes that a full run. The packages are not committed (they are
    Microsoft's), so a tree without any raises too: an empty set would narrow the selection without knowing."""
    names = set()

    def walk(d):
        for key, kind in SYMBOL_KINDS.items():
            for o in d.get(key) or []:
                names.add((kind, o['Name'].lower()))
        for ns in d.get('Namespaces') or []:
            walk(ns)
    apps = [f for f in files if f.endswith('.app') and '/.alpackages/' in f and app_of(f, ci_apps)]
    if not apps:
        raise RuntimeError('no Microsoft symbol packages in the tree')
    for f in apps:
        data = git.run('cat-file', 'blob', '%s:%s' % (rev, f), binary=True)
        z = zipfile.ZipFile(io.BytesIO(data[data.find(b'PK\x03\x04'):]))
        walk(json.loads(z.read('SymbolReference.json').decode('utf-8-sig')))
    return names


def sig(o):
    return (o.kind, o.id, o.name, o.text)


FILE_SCOPE = re.compile(r'^\s*(?:(?:using|namespace)\s+[^;]+;|#\s*(?:define|undef)\b[^\n]*)', re.I | re.M)


def file_scope(text):
    """The statements of a file that change how every object in it compiles: namespace, using, #define, #undef."""
    code = ''.join(t for t in (m.group(0) for m in LEX.finditer(text)) if not (t.startswith('//') or t.startswith('/*')))
    return [re.sub(r'\s+', ' ', x.strip()).lower() for x in FILE_SCOPE.findall(code)]


def describe(objs, via, seed):
    if via is None:
        return seed
    key, src = via
    if src is None:
        return 'uses "%s"; %s' % (key, seed)
    o = objs[src]
    if key is None:
        return 'raises an event of which %s subscribes; %s' % (o.label(), seed)
    if o.target and key == o.target:
        return 'uses "%s", which %s extends; %s' % (key, o.label(), seed)
    return 'uses %s; %s' % (o.label(), seed)


def sentinel(objs, candidates):
    """The cheapest-looking test codeunit: no handler functions, fewest tests, least code, lowest id."""
    if not candidates:
        return None
    return min(candidates, key=lambda n: (objs[n].handlers, objs[n].tests, objs[n].size, int(objs[n].id)))


def resource_dirs(git, head, apps):
    out = {}
    texts = git.read(head, [a + '/app.json' for a in apps])
    for a in apps:
        try:
            manifest = json.loads(texts.get(a + '/app.json', '{}'))
        except ValueError:
            continue
        out[a] = [a + '/' + r.strip('/') for r in manifest.get('resourceFolders', [])]
    return out


def test_app_outside_ci(f, all_files, ci_apps):
    """A file of an app under tests/ that no CI job builds (for example the isolation probe app)."""
    parts = f.split('/')
    return len(parts) > 2 and parts[0] == 'tests' and ('tests/%s/app.json' % parts[1]) in all_files \
        and ('tests/' + parts[1]) not in ci_apps


def full(result, *reasons):
    """A full run. reasons: (kind, text) pairs; --json writes the texts as reasons and the kinds as reason_kinds, in the
    same order. Readers match a reason by its kind, never by its text."""
    pairs = list(dict.fromkeys(reasons))
    result['mode'] = 'full'
    result['reasons'] = [t for _, t in pairs]
    result['reason_kinds'] = [k for k, _ in pairs]
    result['apps'] = {}
    return result


# ---------- output ----------

def subset_output(result):
    if result['mode'] != 'subset':
        return {}
    return {app: ','.join(str(c['id']) for c in e['codeunits']) for app, e in result['apps'].items()}


def summary(result):
    out = []
    if result['mode'] == 'full':
        out.append('## Test selection: full run\n')
        out.append('Every test codeunit in every job runs. Why:\n')
        out.extend('- %s' % r for r in result['reasons'])
    else:
        n = sum(1 for e in result['apps'].values() for c in e['codeunits'] if not c.get('sentinel'))
        out.append('## Test selection: %d test codeunit%s\n' % (n, '' if n == 1 else 's'))
        out.append('Only the test codeunits that the change can affect run. Every app is still compiled and published. '
                   'Rules: CONTRIBUTING.md, "Test selection in CI". Add the label `full-run` to a pull request and '
                   're-run all jobs to run everything.\n')
        for app, e in result['apps'].items():
            own = sum(1 for c in e['codeunits'] if not c.get('sentinel'))
            label = 'nothing affected, sentinel only' if e.get('sentinel') else '%d of %d' % (own, e['test_codeunits_in_app'])
            out.append('- `%s`: %s' % (app, label))
        if result.get('given'):
            out.append('- selection given by the `select_codeunits` input of this run (the CI batcher passes the union of '
                       'the selections of the branches it merged), not computed from a diff')
            for app, e in result['apps'].items():
                if e.get('dropped'):
                    out.append('- `%s`: listed but no runnable test codeunit of the job range: %s'
                               % (app, ', '.join(map(str, e['dropped']))))
        if result.get('ci_range_edit'):
            out.append('- `%s`: only `codeunit_range` values changed (CI range edit), so no full run' % CI_YML)
        if result.get('unwired_jobs'):
            out.append('- jobs that always run their full range: %s' % ', '.join(result['unwired_jobs']))
        out.append('\n| App | Codeunit | Name | Why |\n|---|---|---|---|')
        for app, e in result['apps'].items():
            for c in e['codeunits']:
                out.append('| `%s` | %d | %s | %s |' % (app, c['id'], c['name'].replace('|', '\\|'), c['why'].replace('|', '\\|')))
    if result.get('base'):
        out.append('\nDiff: `%s..%s`, %d changed file%s%s.' % (
            result['base'][:10], (result.get('head') or '')[:10], len(result.get('changed_files', [])),
            '' if len(result.get('changed_files', [])) == 1 else 's',
            ', %d of them not read by CI' % len(result['ignored_files']) if result.get('ignored_files') else ''))
    return '\n'.join(out) + '\n'


def check_reuse(git, head, text, ci_text=None):
    """--check-reuse: [refusal text] for reused results that HEAD may have made stale. text: {source commit: {test app
    dir: "ids"}}. A reused codeunit is refused when the selection of source..HEAD (two dots, no file cap) selects it, and
    every codeunit of a source commit when that span has a full-run reason other than REUSE_KINDS."""
    try:
        given_by_source = json.loads(text)
        if not isinstance(given_by_source, dict) or not given_by_source:
            raise ValueError('not a non-empty JSON object')
        wanted = {src: parse_given(json.dumps(apps)) for src, apps in given_by_source.items()}
    except ValueError as e:
        return ['the --check-reuse input is not {source commit: {test app dir: "ids"}} (%s)' % e]
    head = git.rev(head)
    loaded = Head(git, head, ci_text)
    refused = []
    for src in sorted(wanted):
        r = select(git, src, head, False, ci_text, max_files=None, loaded=loaded)
        span = '%s..%s' % (src[:10], head[:10])
        if r['mode'] == 'full':
            refused.extend('%s: full-run reason %s: %s' % (span, k, t)
                           for k, t in zip(r['reason_kinds'], r['reasons']) if k not in REUSE_KINDS)
            continue
        for app, sp in sorted(wanted[src].items()):
            for c in r['apps'].get(app, {}).get('codeunits', []):
                if not c.get('sentinel') and in_spans(sp, c['id']):
                    refused.append('%s: %s codeunit %d is selected (%s)' % (span, app, c['id'], c['why']))
    return refused


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--base')
    ap.add_argument('--head', default='HEAD')
    ap.add_argument('--repo', default='.')
    ap.add_argument('--merge-base', action='store_true',
                    help='diff from the merge base of BASE and HEAD (what a branch changed since it left BASE); '
                         'the default, kept for older callers')
    ap.add_argument('--ci-yml', help='read the test jobs from this file instead of HEAD:%s (local measurements)' % CI_YML)
    ap.add_argument('--full-reason')
    ap.add_argument('--codeunits', help='use this selection, a JSON object {test app dir: "ids and lo..hi ranges"}, '
                                        'instead of a diff (ci.yml: the select_codeunits input)')
    ap.add_argument('--check-reuse', help='JSON {source commit: {test app dir: "ids"}}: exit 1 and print each reused '
                                          'result HEAD may have made stale (al-runtime-rs corpus bump)')
    ap.add_argument('--json')
    ap.add_argument('--github', action='store_true', help='write $GITHUB_STEP_SUMMARY and $GITHUB_OUTPUT')
    a = ap.parse_args(argv)
    if a.check_reuse is not None:
        try:
            refused = check_reuse(Git(a.repo), a.head, a.check_reuse, open(a.ci_yml).read() if a.ci_yml else None)
        except Exception as e:  # noqa: BLE001 - the check could not be made: refuse, never pass
            refused = ['the reuse check failed (%s: %s)' % (type(e).__name__, e)]
        for line in refused:
            print('refused: %s' % line)
        if not refused:
            print('every reused result is still valid at %s' % a.head)
        return 1 if refused else 0
    if not a.full_reason and not a.base and a.codeunits is None:
        ap.error('--base, --codeunits, --check-reuse or --full-reason is required')
    git = Git(a.repo)
    if a.full_reason:
        result = full({'base': None, 'head': None, 'mode': 'full', 'reasons': [], 'apps': {}}, ('requested', a.full_reason))
    else:
        try:
            ci_text = open(a.ci_yml).read() if a.ci_yml else None
            if a.codeunits is not None:
                result = given(git, a.head, a.codeunits, ci_text)
            else:
                result = select(git, a.base, a.head, True, ci_text)
        except Exception as e:  # never block CI on this script: run everything
            result = full({'base': None, 'head': None, 'mode': 'full', 'reasons': [], 'apps': {}},
                          ('script-failed', 'the selection script failed (%s: %s)' % (type(e).__name__, e)))
    text = summary(result)
    print(text)
    if a.json:
        with open(a.json, 'w') as f:
            json.dump(result, f, indent=1)
    if a.github:
        if os.environ.get('GITHUB_STEP_SUMMARY'):
            with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as f:
                f.write(text)
        if os.environ.get('GITHUB_OUTPUT'):
            with open(os.environ['GITHUB_OUTPUT'], 'a') as f:
                f.write('subset=%s\n' % json.dumps(subset_output(result), separators=(',', ':')))
        n = sum(1 for e in result['apps'].values() for c in e['codeunits'] if not c.get('sentinel'))
        print('::notice title=Test selection::%s' % (
            'full run: ' + '; '.join(result['reasons'])[:900] if result['mode'] == 'full'
            else '%d test codeunit(s) selected; the prepare job summary says which and why' % n))
    return 0


if __name__ == '__main__':
    sys.exit(main())
