#!/usr/bin/env python3
"""Corpus restructure, pull request M (moves): put every test file into <app>/<area>/<topic>/.

  restructure-move.py plan [--ref REF ...] [--write]
      map every file under tests/ of the checkout (and of each --ref, for branches that are still open) to its new path.
      Files listed in .github/restructure/path-map.tsv keep that decision. A file that is not listed (added after the map
      was made) is mapped by rule: its folder's decision when the folder is already mapped, else the folder rules below,
      else the content classifier. Every rule-mapped file is printed for review; nothing is dropped.
      --write stores the result back into path-map.tsv (decisions already in it never change).
  restructure-move.py apply [--part 1|2]
      (--part: GitHub shows at most 3,000 files of a pull request, so the move can land in two pull requests. Part 1 moves
      the files whose target area sorts before SPLIT_AT, part 2 the rest; run part 2 on the master that has part 1.)
      plan, then: `git mv` every file, rewrite the layout path strings (RDLCLayout, WordLayout, ExcelLayout, LayoutFile and
      other quoted app-relative paths) of the moved non-AL files, follow app.json resourceFolders, remove the tracked build
      outputs, write the area READMEs. Stages everything; commits nothing.
  restructure-move.py check BASE
      prove the move: `git diff -M100% --name-status BASE` (staged and committed) holds only R100 renames, the area READMEs,
      the deleted build outputs, the restructure data files and the files whose layout paths were rewritten.

Must-not-compile cases stay flat (the runner and check-must-not-compile.py read cases/ flat). The isolation-probe, internals
fixture and xapp apps stay as they are (CONTRIBUTING.md, "Multi-app fixtures").
"""
import collections
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from facts import strip  # noqa: E402

DATA = os.path.join(HERE, '..', 'restructure')
MAP = os.path.join(DATA, 'path-map.tsv')
FOLDER_MAP = os.path.join(DATA, 'folder-map.tsv')
SENSITIVE = os.path.join(DATA, 'sensitive-files.tsv')
DELETE = '(delete: build output)'
LAYOUT_EXT = ('.rdl', '.rdlc', '.docx', '.xlsx', '.rlblayout', '.dotx')
FIXED_APPS = ('must-not-compile', 'al-language-isolation-probe', 'al-language-internals-fixture')
DOCS = ('README.md', 'CONTRIBUTING.md', 'CLAUDE.md', 'tests/must-not-compile/README.md', 'scripts/conversion-matrix/README.md',
        'scripts/conversion-matrix/gen.py', '.github/ISSUE_TEMPLATE/wrong-test.yml', 'tests/al-language/PLAN.md')
DOC_PATH = re.compile(r'tests/al-language[a-z-]*/[A-Za-z0-9_./-]+')
BUILD_OUTPUT = re.compile(r'^tests/al-language/(.*\.app|bc-full-results\.json)$')

AREAS = [
    ('_fixtures', 'Shared objects only: tables, pages, reports, xmlports, queries, codeunits, events, enums, interfaces, '
                  'permission sets and report layouts that many test codeunits use. A shared fixture never changes once merged.'),
    ('language', 'Statements, operators, preprocessor directives, identifiers, scope, `with`, procedures as values: the '
                 'language itself, apart from a data type or an object type.'),
    ('types', 'The simple data types: Date, Time, DateTime, Duration, Decimal, Integer, BigInteger, Text, Code, Char, Guid, '
              'Variant, Enum and Option, arrays, Clear, and the operators and conversions between them.'),
    ('format-evaluate', 'Format and Evaluate of every type, format strings and AutoFormat.'),
    ('text', 'Text and Code methods, TextBuilder, BigText, TextConst and Label.'),
    ('collections', 'List, Dictionary and the array functions (CopyArray, ArrayLen, CompressArray).'),
    ('json', 'JsonObject, JsonArray, JsonToken and JsonValue.'),
    ('xml', 'XmlDocument, XmlElement, XmlNode, XmlAttribute, namespaces and XPath.'),
    ('http', 'HttpClient, HttpRequestMessage, HttpResponseMessage, HttpContent and HttpHeaders.'),
    ('streams', 'InStream and OutStream, Blob fields, TempBlob, Media and MediaSet, files in memory.'),
    ('record', 'The Record type: insert, modify, delete, get and find; filters; keys and sorting; FlowFields and CalcFields; '
               'loading fields; table views; temporary records; system fields; TestField; table relations; captions.'),
    ('recordref-fieldref', 'RecordRef, FieldRef and KeyRef.'),
    ('table-objects', 'The table object: table and field properties, table and field triggers, table extensions, table globals.'),
    ('codeunits', 'Codeunit.Run, OnRun, SingleInstance, TableNo, interfaces, procedures and overloads, call depth.'),
    ('events', 'Event publishers and subscribers, BindSubscription, platform trigger events, subscriber order, events of '
               'extensions.'),
    ('errors', 'Error, asserterror, ErrorInfo, collected errors, GetLastError*, TryFunction and the texts of runtime errors.'),
    ('pages', 'The page object: page triggers, parts, controls, actions, CurrPage, Run and RunModal, page properties, page '
              'extensions, application areas, page background tasks, FilterPageBuilder, lookups.'),
    ('testpage', 'The TestPage and TestPart API: opening, navigating, fields and actions, filters, lifecycle and teardown.'),
    ('ui-handlers', 'Test handlers: MessageHandler, ConfirmHandler, StrMenuHandler, ModalPageHandler, PageHandler, '
                    'ReportHandler, RequestPageHandler and the notification handlers.'),
    ('reports', 'The report object: running, dataset and data items, request pages, layouts and SaveAs, report extensions.'),
    ('xmlports', 'The xmlport object: import, export, element and attribute properties.'),
    ('queries', 'The query object: joins and links, filters and FlowFields, reading.'),
    ('session-system', 'Session, Company, User, NavApp, IsolatedStorage, TaskScheduler, StartSession and the system functions.'),
    ('metadata', 'Virtual and system tables (AllObj, Field, page metadata) and other platform tables.'),
    ('permissions', 'Permission sets, entitlements, access control, inherent permissions and TestPermissions.'),
    ('install-upgrade', 'Install and upgrade codeunits, upgrade tags, DataTransfer.'),
    ('localization', 'Captions in other languages, translation files, language and region settings.'),
    ('profiles', 'Profiles and page customizations.'),
    ('controladdins', 'Control add-ins.'),
    ('test-framework', 'Test runner behavior, test isolation, test permissions of the runner and code coverage.'),
]
AREA_NAMES = [a for a, _ in AREAS]

# ---- folder rules (plan section B; the same rules made folder-map.tsv)
TOP = {
    '_fixtures': '_fixtures', 'fixtures': '_fixtures',
    'access-control': 'permissions/access-control', 'addin': 'controladdins', 'appareas': 'pages/application-area',
    'autoformat': 'format-evaluate/autoformat', 'bgtasks': 'pages/background-tasks', 'calcfields': 'record/flowfields',
    'codeunit': 'codeunits', 'collections': 'collections', 'controls': 'pages/controls', 'coverage': 'test-framework/code-coverage',
    'dateformulacontrol': 'pages/controls', 'enum': 'types/enum-option', 'error-handling': 'errors', 'errors': 'errors',
    'errorinfo': 'errors/errorinfo', 'events': 'events', 'extensionevents': 'events/extension-events',
    'fieldref': 'recordref-fieldref/fieldref', 'recordref': 'recordref-fieldref/recordref', 'filterpage': 'pages/filterpagebuilder',
    'filters': 'record/filters', 'handlers': 'SPLIT', 'install': 'install-upgrade', 'json': 'json', 'localization': 'localization',
    'Translations': 'localization/translations', 'lookups': 'pages/lookups', 'media': 'streams/media', 'metadata': 'metadata',
    'misc': 'SPLIT', 'network': 'http', 'pageapplicationarea': 'pages/application-area', 'pageext': 'pages/extensions',
    'pageextensioncontrol': 'pages/extensions', 'pageextensionpart': 'pages/extensions', 'pageextensiontrigger': 'pages/extensions',
    'pagefindrecord': 'pages/triggers', 'pages': 'pages', 'pagesave': 'pages/record-save', 'pageupdate': 'pages/currpage',
    'permissions': 'permissions', 'platform': 'metadata', 'profile': 'profiles', 'query': 'queries', 'record': 'record', 'records': 'record',
    'report': 'reports', 'reportext': 'reports/extensions', 'reportextensiontrigger': 'reports/extensions', 'runner': 'test-framework',
    'session': 'session-system', 'streams': 'streams', 'system-fields': 'record/system-fields', 'tableextension': 'table-objects/extensions',
    'tableextensiontrigger': 'table-objects/extensions', 'tableglobals': 'table-objects/globals', 'testfilter': 'testpage/filters',
    'testpageclose': 'testpage/lifecycle', 'testpageteardown': 'testpage/lifecycle', 'testpart': 'testpage/parts', 'text': 'text',
    'types': 'types', 'xml': 'xml', 'xmlport': 'xmlports', 'src': '', '.dev': 'KEEP', '.alpackages': 'KEEP',
}
TOPICS = {
    'record': [('flowfields', r'flowfield|calcfield|calcsums|calcformula|autocalc|sum-where'), ('filters', r'filter|wildcard|in$|record-id-in|placeholder'),
               ('keys-sorting', r'key|sort|ascending|currentkey'), ('load-fields', r'loadfield|fields-loaded|arefieldsloaded|load-fields'),
               ('views', r'setview|view'), ('table-relation', r'relation'), ('testfield', r'testfield'),
               ('temporary', r'temp'), ('system-fields', r'system|stamp|sqltimestamp|sqldatatype'),
               ('crud', r'insert|modify|delete|rename|get|find|read|write|transferfields|dup|truncate|initvalue|record-size|copy'),
               ('captions', r'caption'), ('events', r'events'), ('table-properties', r'props|table-field|windows-language|published|table-connection|time-zone|feature-key|long-field')],
    'types': [('format-evaluate', r'format|evaluate|totext|number-to-text|auto-format'), ('date-time', r'date|time|week|quarter'),
              ('duration', r'duration'), ('variant', r'variant'), ('enum-option', r'enum|option'), ('guid', r'guid'),
              ('text-code-char', r'char|code-digits|text|byte|label|secret'), ('decimal-integer', r'decimal|bigint|integer|round|scalar|arith'),
              ('operators-expressions', r'operator|ternary|expression|precedence|implicit|conversion|this|case'), ('arrays', r'array'),
              ('clear', r'clear')],
    'pages': [('extensions', r'pageext|page-ext|ext-'), ('parts', r'part'), ('testpage', r'testpage|test-page|testfilter'),
              ('controls', r'control|enum-control|style|set-value|decimal-bounds|width'), ('actions', r'action|promot'),
              ('triggers', r'onfind|oninsert|onlookup|trigger|onaftergetrec|onnewrecord|new-line|new-row|query-close|events?$|event'),
              ('currpage', r'currpage|update|setrecord|settableview|sourceview|selection'), ('run-modal', r'run|modal|lookup'),
              ('properties', r'propert|caption|editab|metadata|layout|types|filtergroup|application|presentation'), ('lifecycle', r'lifecycle|close|variable')],
    'reports': [('request-page', r'request'), ('dataset', r'dataset|dataitem|data-item|column|maxiteration|set-table'),
                ('layouts-saveas', r'layout|rdlc|output|save|render|printer|xml-blob|merger'), ('extensions', r'reportext|report-ext'),
                ('runtime', r'run|props|members|processing|clearall|this|format|char|pre-render|metadata|showprint|params|fqn')],
    'xmlports': [('import', r'import|validation|linktable|datatransfer'), ('shapes-properties', r'.')],
    'events': [('platform-triggers', r'platform|global|trigger|company|system|setup'), ('subscriber-order', r'order'),
               ('page-events', r'page'), ('table-events', r'table|insert|filter'), ('binding-senders', r'sender|by-value|var|with|subscription|.')],
    'session-system': [('company', r'company'), ('isolated-storage', r'isolated|encryption|decrypt'), ('session', r'session|sleep|sql|request|user|geolocation|.')],
    'metadata': [('code-coverage', r'code-coverage'), ('platform-tables', r'table|columns|rows|field|members|tenant|contoso|database|license|layout|metadata|personalization|privacy|username|env'),
                 ('session-system', r'.')],
    'http': [('headers', r'header|cookie|cache'), ('client', r'.')],
    'json': [('json', r'.')], 'xml': [('xml', r'.')],
    'text': [('textbuilder-bigtext', r'textbuilder|bigtext'), ('textconst-label', r'textconst|label'), ('text-methods', r'.')],
    'streams': [('media', r'media'), ('blob-tempblob', r'blob|gzip|download'), ('instream-outstream', r'.')],
    'queries': [('joins-links', r'join|link|relation'), ('flowfields-filters', r'flowfield|filter|setrange'), ('read-lifecycle', r'.')],
    'install-upgrade': [('install-order', r'order|first|block'), ('install-triggers', r'.')],
    'permissions': [('testpermissions', r'testpermission|runner'), ('permission-sets', r'perm|license|security|metadata|moved|access')],
    'errors': [('errorinfo', r'errorinfo|notif'), ('last-error', r'last-error|callstack|emit'), ('error-texts', r'.')],
    'codeunits': [('interfaces', r'interface|enums-interfaces'), ('run-onrun', r'onrun|run|commit|isolation|carry'), ('call-depth', r'depth'),
                  ('procedures', r'procedure|overload|var|alias|props'), ('code-coverage', r'coverage')],
}
GRAB = re.compile(r'(refusals|^\d+$|^probes$|^tests$|^values$|^pages$|^records$|^reports$|^xml$|^json$|^http$|^query$|odd-leads|-leads$|triage|probes-needed|probe-requests|ms-refusals|small-probes|assumptions$|partner-gaps|^[a-z]{1,2}\d{0,4}$|^y\d+$|^(np|bn|bo)\d|^w[bcd]$|-probes$|^aq$|^f3-|^at-|inferred-behaviors|outside-)')
WRITER = re.compile(r'^(?:[a-z]{1,2}\d{0,4}|y\d+|r\d+|p\d+|w\d|bn\d|bo\d|np\d|ss\d+|x\d)-')

# ---- content classifier for files of grab-bag and mixed folders
SIG = [
    ('testpage', [r'\bTestPage\b', r'\.OpenEdit\(', r'\.OpenView\(', r'\.GoToKey\(', r'\.Trap\(', r'\bTestPart\b']),
    ('ui-handlers', [r'\[(ModalPageHandler|MessageHandler|ConfirmHandler|StrMenuHandler|PageHandler|SendNotificationHandler|HyperlinkHandler|RecallNotificationHandler)\]', r'HandlerFunctions']),
    ('reports', [r'^\s*report\s+\d+', r'\bReport\.(Run|RunModal|SaveAs|Execute)', r'\bRequestPage\b', r'\[RequestPageHandler\]', r'\[ReportHandler\]']),
    ('xmlports', [r'^\s*xmlport\s+\d+', r'\bXmlport\.']),
    ('queries', [r'^\s*query\s+\d+', r'\bQuery\s+"']),
    ('json', [r'\bJson(Object|Array|Token|Value)\b']), ('xml', [r'\bXml(Document|Element|Node|Attribute|NamespaceManager)\b']),
    ('http', [r'\bHttp(Client|RequestMessage|ResponseMessage|Content|Headers)\b']),
    ('streams', [r'\b(InStream|OutStream|TempBlob|BigText)\b', r'\bMedia(Set)?\b']),
    ('recordref-fieldref', [r'\b(RecordRef|FieldRef|KeyRef)\b']),
    ('errors', [r'\basserterror\b', r'\bErrorInfo\b', r'GetLastError(Text|Code|CallStack)', r'\[TryFunction\]', r'\bCollectingErrors\b']),
    ('events', [r'\[EventSubscriber\(', r'\[(IntegrationEvent|BusinessEvent|InternalEvent)\(', r'\b(Bind|Unbind)Subscription\b']),
    ('format-evaluate', [r'\bFormat\(', r'\bEvaluate\(']),
    ('text', [r'\bTextBuilder\b', r'\bStrSubstNo\(', r'\.(Substring|Replace|Split|PadLeft|PadRight|IndexOf|Trim|ToUpper|ToLower)\(', r'\b(CopyStr|StrPos|StrLen|ConvertStr|DelChr|SelectStr|IncStr)\(']),
    ('types', [r'\b(Duration|DateTime|Variant|Guid|BigInteger|DateFormula|SecretText)\b', r'\b(CalcDate|DMY2Date|Date2DMY|CreateDateTime|CreateGuid)\(']),
    ('collections', [r'\bList of \[', r'\bDictionary of \[', r'\bCopyArray\(', r'\bArrayLen\(']),
    ('pages', [r'^\s*page\s+\d+', r'\bCurrPage\b', r'^\s*pageextension\s+\d+', r'\bPage\.(Run|RunModal)\(']),
    ('session-system', [r'\bSession\.', r'\bCompanyName\(', r'\bUserId\(', r'\bNavApp\.', r'\bTaskScheduler\.', r'\bStartSession\(', r'\bIsolatedStorage\.', r'\bDatabase\.']),
    ('permissions', [r'^\s*permissionset\s+\d+', r'\bInherentPermissions\b', r'\bTestPermissions\b', r'^\s*entitlement\s', r'\bPermissions\s*=']),
    ('install-upgrade', [r'Subtype\s*=\s*(Install|Upgrade)', r'\bUpgradeTag\b', r'\bDataTransfer\b']),
    ('metadata', [r'\bAllObj(WithCaption)?\b', r'Record\s+Field\b', r'Record\s+"Field"', r'\bObject Metadata\b', r'"Page Metadata"']),
    ('table-objects', [r'\btrigger\s+On(Validate|Insert|Modify|Delete|Rename)\b', r'\bTableRelation\b', r'^\s*tableextension\s+\d+']),
    ('record', [r'\.(SetRange|SetFilter|FindSet|FindFirst|FindLast|Insert|Modify|Delete|DeleteAll|Get|Next|SetCurrentKey|CalcFields|LockTable|Count|IsEmpty|Rename|TransferFields|Copy)\(']),
    ('codeunits', [r'\bCodeunit\.Run\(', r'SingleInstance\s*=', r'^\s*interface\s+"', r'\bimplements\b']),
    ('language', [r'\bcase\b.+\bof\b', r'\bforeach\b', r'#if\b', r'\bwith\b.+\bdo\b']),
]
SIGC = [(a, [re.compile(p, re.I | re.M) for p in ps]) for a, ps in SIG]
WEIGHT = {'record': 0.25, 'format-evaluate': 0.1, 'types': 0.5, 'text': 0.6, 'language': 0.5, 'session-system': 0.8, 'errors': 0.4}
NAME_HEADS = (('record', ('record',)), ('json', ('json', 'jsonobject', 'jsonarray', 'jsontoken')), ('xml', ('xml', 'xmldocument', 'xmlnode', 'xmlelement')),
              ('testpage', ('testpage', 'testpart')), ('reports', ('report', 'requestpage')), ('recordref-fieldref', ('recordref', 'fieldref')),
              ('text', ('text', 'textbuilder', 'strsubstno')), ('format-evaluate', ('format', 'evaluate')), ('http', ('http', 'httpclient')),
              ('xmlports', ('xmlport',)), ('queries', ('query',)), ('pages', ('page', 'currpage')))
LOW_CONFIDENCE = 0.25
TOPIC_SCOPE = {
    'flowfields': 'FlowFields, CalcFields, CalcSums, CalcFormula and AutoCalcFields', 'filters': 'SetRange, SetFilter, filter syntax and GetFilter(s)',
    'keys-sorting': 'keys, SetCurrentKey, SetAscending and sort order', 'load-fields': 'SetLoadFields, AddLoadFields and AreFieldsLoaded',
    'views': 'SetView and GetView', 'table-relation': 'TableRelation and its conditions', 'testfield': 'TestField and FieldError',
    'temporary': 'temporary records and tables', 'system-fields': 'SystemId, SystemCreatedAt and the other system fields, timestamps',
    'crud': 'Insert, Modify, Delete, Rename, Get, Find*, TransferFields, Copy and Init', 'captions': 'captions and CaptionClass of fields and records',
    'events': 'record and table events seen from the record', 'table-properties': 'table and field properties seen through a record',
    'date-time': 'Date, Time and DateTime, date formulas and date functions', 'duration': 'Duration and its arithmetic',
    'variant': 'Variant and its Is* tests', 'enum-option': 'Enum and Option values, ordinals, names and conversions', 'guid': 'Guid',
    'text-code-char': 'Text, Code, Char, Byte, Label and SecretText as values', 'decimal-integer': 'Decimal, Integer, BigInteger and rounding',
    'operators-expressions': 'operators, precedence, ternary, implicit conversions', 'arrays': 'arrays', 'clear': 'Clear and ClearAll',
    'extensions': 'extension objects of this object type', 'parts': 'page parts and subpages', 'controls': 'page controls and their properties',
    'actions': 'actions and promoted actions', 'triggers': 'page triggers', 'currpage': 'CurrPage, Update, SetRecord, SetTableView, SetSelectionFilter',
    'run-modal': 'Page.Run and RunModal and their results', 'properties': 'page properties', 'lifecycle': 'opening, closing and page variables',
    'application-area': 'ApplicationArea', 'background-tasks': 'page background tasks', 'filterpagebuilder': 'FilterPageBuilder',
    'lookups': 'Lookup and DrillDown', 'record-save': 'how a page saves its record', 'request-page': 'request pages',
    'dataset': 'datasets, data items and columns', 'layouts-saveas': 'layouts, rendering and Report.SaveAs*', 'runtime': 'running a report and its members',
    'import': 'xmlport import', 'shapes-properties': 'xmlport shapes, elements and properties', 'platform-triggers': 'platform trigger events',
    'subscriber-order': 'the order subscribers run in', 'page-events': 'page events', 'table-events': 'table events',
    'binding-senders': 'binding, senders and parameters of subscribers', 'extension-events': 'events of extension objects',
    'company': 'Company and CompanyName', 'isolated-storage': 'IsolatedStorage and encryption', 'session': 'Session, User and system functions',
    'code-coverage': 'code coverage', 'platform-tables': 'platform and system tables', 'session-system': 'platform objects about the session (REVIEW)',
    'headers': 'HttpHeaders and cookies', 'client': 'HttpClient and requests', 'json': 'the JSON types', 'xml': 'the XML types',
    'textbuilder-bigtext': 'TextBuilder and BigText', 'textconst-label': 'TextConst and Label', 'text-methods': 'Text and Code methods',
    'media': 'Media and MediaSet', 'blob-tempblob': 'Blob fields and TempBlob', 'instream-outstream': 'InStream and OutStream',
    'joins-links': 'query joins and links', 'flowfields-filters': 'query filters and FlowFields', 'read-lifecycle': 'Open, Read, Close and SaveAs',
    'install-order': 'the order install and upgrade code runs in', 'install-triggers': 'install and upgrade triggers',
    'testpermissions': 'TestPermissions and the runner permission sets', 'permission-sets': 'permission sets and entitlements',
    'access-control': 'access control', 'errorinfo': 'ErrorInfo and error notifications', 'last-error': 'GetLastError* and call stacks',
    'error-texts': 'the texts of runtime errors', 'interfaces': 'interfaces', 'run-onrun': 'Codeunit.Run, OnRun and commit behavior',
    'call-depth': 'call depth', 'procedures': 'procedures, overloads, var parameters', 'autoformat': 'AutoFormatType and AutoFormatExpression',
    'filters-lifecycle': 'TestPage filters', 'globals': 'table globals', 'fieldref': 'FieldRef', 'recordref': 'RecordRef and KeyRef',
    'translations': 'translation files', 'app-xliff': 'app translation files', 'dotnet': 'DotNet interop',
}


def git(*args, cwd=None):
    return subprocess.run(['git', *args], cwd=cwd, capture_output=True, text=True, check=True).stdout


def classify(src):
    s = strip(src)
    sc = collections.Counter()
    for a, ps in SIGC:
        n = sum(len(p.findall(s)) for p in ps)
        if n:
            sc[a] = n * WEIGHT.get(a, 1.0)
    for n in re.findall(r'procedure\s+(\w+)\s*\(', s):
        h = n.split('_')[0].lower()
        for a, keys in NAME_HEADS:
            if h in keys:
                sc[a] += 3
    if not sc:
        return 'language', 0.0
    (a1, v1), *rest = sc.most_common(3)
    v2 = rest[0][1] if rest else 0
    return a1, round((v1 - v2) / v1, 2) if v1 else 0.0


def clean(seg):
    t = seg[3:] if seg.startswith('lt-') else seg
    return WRITER.sub('', t) or t


def folder_rule(d):
    """Target folder of folder d by the plan rules: a path, 'KEEP' or 'SPLIT:<app dir>' (classify per file)."""
    parts = d.split('/')
    app = parts[1]
    if len(parts) == 2 or app in FIXED_APPS or app.startswith('al-language-xapp'):
        return 'KEEP', 'fixed app or app root'
    top, sub = parts[2], parts[3:]
    base = f'tests/{app}'
    if top == '_fixtures':
        return 'KEEP', 'shared fixture'
    if top == 'Translations' or 'res' in sub:
        return 'KEEP', 'translation or resource folder (fixed by the compiler or app.json resourceFolders)'
    if (top in AREA_NAMES or top == 'dotnet') and not (sub and (sub[0].startswith('lt-') or WRITER.match(sub[0]) or GRAB.search(sub[0]))):
        return 'KEEP', 'already in the area layout'
    if top.startswith('lt-') and app != 'al-language':
        c = clean(top)
        area = 'dotnet' if 'dotnet' in app else ('test-framework' if 'testlibraries' in app else None)
        if area is None:
            for a, pat in (('streams/files', r'file'), ('session-system', r'system|debugger|y5'), ('record/fulltext', r'fulltext')):
                if re.search(pat, c):
                    area = a
                    break
        if area is None:
            return f'SPLIT:{base}', 'per-writer folder of a secondary app, split by file'
        return '/'.join([base, area, c] + sub), 'per-writer folder of a secondary app'
    area = TOP.get(top)
    if area is None:
        area = 'SPLIT' if top.startswith('lt-') else 'REVIEW'
    if area in ('KEEP', ''):
        return 'KEEP', 'not test source'
    if area == 'REVIEW':
        return f'SPLIT:{base}', 'unknown top-level folder, split by file'
    seg = sub[0] if sub else ''
    c = clean(seg) if seg else ''
    if area == 'SPLIT' or (seg and GRAB.search(c if c != seg else (seg[3:] if seg.startswith('lt-') else seg))):
        return f'SPLIT:{base}', 'grab-bag or mixed folder, split by file'
    head = area.split('/')[0]
    if not seg:
        return f'{base}/{area}', 'area folder'
    if '/' in area:
        tgt = f'{base}/{area}'
    else:
        topic = next((t for t, pat in TOPICS.get(head, []) if re.search(pat, c)), None)
        tgt = f'{base}/{area}/{topic or c}'
        if (area, topic) in (('types', 'format-evaluate'), ('pages', 'testpage')):
            tgt = f'{base}/{topic}'  # its own area (plan section B)
    why = 'topic folder' if '/' in area or topic or head not in TOPICS else 'topic folder, REVIEW: no topic rule matched'
    if len(sub) > 1:
        tgt += '/' + '/'.join(sub[1:])
    return tgt, why


def read_map():
    m = {}
    if os.path.exists(MAP):
        for line in open(MAP, encoding='utf-8'):
            if line.startswith('old_path\t') or not line.strip():
                continue
            f = line.rstrip('\n').split('\t')
            m[f[0]] = (f[1], f[2] if len(f) > 2 else 'map')
    return m


def plan(root, refs=()):
    """Return {old: (new, how)} for every file under tests/ of the checkout and of each ref, and the review rows."""
    files = {f: None for f in git('ls-files', 'tests/', cwd=root).split('\n') if f}
    for ref in refs:
        for f in git('ls-tree', '-r', '--name-only', ref, 'tests/', cwd=root).split('\n'):
            if f and f not in files:
                files[f] = ref
    frozen = read_map()

    def content(f):
        ref = files[f]
        if ref:
            return git('show', f'{ref}:{f}', cwd=root)
        return open(os.path.join(root, f), encoding='utf-8-sig', errors='replace').read()

    out, review = {}, []
    by_dir = collections.defaultdict(set)
    for old, (new, _) in frozen.items():
        if new != DELETE:
            by_dir[os.path.dirname(old)].add(os.path.dirname(new))
    pending = []
    targets = {n for n, _ in frozen.values()}
    target_dirs = {os.path.dirname(n) for n in targets}
    for f in files:
        if f in frozen:
            out[f] = frozen[f]
        elif f in targets:
            out[f] = (f, 'map: already at its new path')
        else:
            pending.append(f)
    split_files = []
    for f in pending:
        d, name = os.path.dirname(f), os.path.basename(f)
        parts = f.split('/')
        if BUILD_OUTPUT.match(f):
            out[f] = (DELETE, 'rule: build output')
        elif len(parts) == 2:
            out[f] = (f, 'rule: file of tests/ itself')
        elif len(parts) == 3:
            if parts[1] == 'al-language' and name.lower().endswith(LAYOUT_EXT):
                out[f] = (f'tests/al-language/_fixtures/layouts/{name}', 'rule: app-root layout')
            else:
                out[f] = (f, 'rule: app root file')
        elif d in target_dirs and d not in by_dir:
            out[f] = (f, 'rule: folder of the new layout')
        else:
            tgt, why = folder_rule(d)
            if not tgt.startswith('SPLIT:') and len(by_dir.get(d, ())) == 1:
                out[f] = (next(iter(by_dir[d])) + '/' + name, 'rule: folder already mapped')
            elif tgt == 'KEEP':
                out[f] = (f, f'rule: {why}')
            elif tgt.startswith('SPLIT:'):
                split_files.append((f, tgt[6:]))
            else:
                out[f] = (f'{tgt}/{name}', f'rule: {why}')
        if f in out and out[f][0] != f:
            review.append((f, out[f][0], out[f][1], ''))
    # files of grab-bag folders. AL files: the classifier picks the area; a support object (not a test codeunit) follows the
    # test codeunits of its folder that use it; when the whole folder is new, all its files follow the area most of its test
    # codeunits are about (one new folder is one writer topic). Non-AL files follow the AL file of the app that names them.
    info = {}
    for f, base in split_files:
        if f.endswith('.al'):
            src = content(f)
            is_test = bool(re.search(r'Subtype\s*=\s*Test\b', src, re.I))
            names = re.findall(r'^\s*(?:table|page|report|query|xmlport|enum|codeunit|interface|tableextension|pageextension)\s+\d+\s+("[^"]+"|\w+)', src, re.I | re.M)
            info[f] = (is_test, names, src) + classify(src) + (base,)
    new_dirs = {os.path.dirname(f) for f, _ in split_files} - set(by_dir)
    for d in new_dirs:
        votes = collections.Counter(info[g][3] for g in info if os.path.dirname(g) == d and info[g][0])
        home = TOP.get(d.split('/')[2], 'SPLIT') if len(d.split('/')) > 2 else 'SPLIT'
        if home not in ('SPLIT', 'KEEP', ''):
            votes = collections.Counter({home.split('/')[0]: 1})
        if votes:
            a, n = votes.most_common(1)[0]
            for g in info:
                if os.path.dirname(g) == d:
                    info[g] = info[g][:3] + (a, round(n / sum(votes.values()), 2), info[g][5], 'folder')
    for f, base in split_files:
        name = os.path.basename(f)
        if f not in info:
            continue
        is_test, names, src, a, conf, _ = info[f][:6]
        how = f'rule: classifier ({conf})'
        home = TOP.get(f.split('/')[2], 'SPLIT')
        if len(info[f]) > 6:
            how = f'rule: new grab-bag folder, area of its top folder or of most of its test codeunits ({conf})'
        elif conf < 0.5 and home not in ('SPLIT', 'KEEP', ''):
            a, how = home.split('/')[0], f'rule: classifier unsure ({conf}), area of the top folder'
        elif not is_test and names:
            users = collections.Counter(info[g][3] for g in info if g != f and info[g][0] and os.path.dirname(g) == os.path.dirname(f)
                                        and any(n in info[g][2] for n in names))
            users.update(os.path.dirname(out[g][0]).split('/')[2] for g in out if os.path.dirname(g) == os.path.dirname(f)
                         and g.endswith('.al') and g in frozen and any(n in content(g) for n in names)
                         and len(out[g][0].split('/')) > 3)
            if users:
                a, conf, how = users.most_common(1)[0][0], 1.0, 'rule: support object follows its test codeunit'
        out[f] = (f'{base}/{a}/{name}', how)
        review.append((f, out[f][0], how, 'LOW' if conf < LOW_CONFIDENCE else ''))
    al_of_app = collections.defaultdict(list)
    for g in files:
        if g.endswith('.al'):
            al_of_app[app_of(g)].append(g)
    # a non-AL file that an older map left behind in a folder that is split up (it would keep the old folder alive)
    for f in files:
        if not f.endswith('.al') and out.get(f, (None,))[0] == f and len(f.split('/')) > 3:
            tgt = folder_rule(os.path.dirname(f))[0]
            if tgt.startswith('SPLIT:'):
                split_files.append((f, tgt[6:]))
    for f, base in split_files:
        if f in info:
            continue
        name = os.path.basename(f)
        rel = f[len(app_of(f)) + 1:]
        users = [g for g in al_of_app[app_of(f)] if rel in content(g)]
        if users:
            out[f] = (os.path.dirname(out[users[0]][0]) + '/' + name, 'rule: follows the AL file that names it')
            review.append((f, out[f][0], out[f][1], ''))
        else:
            out[f] = (f'{base}/_fixtures/layouts/unreferenced/{name}' if name.lower().endswith(LAYOUT_EXT) else f'{base}/{name}',
                      'rule: non-AL file of a split folder, no AL file names it (candidate for removal)')
            review.append((f, out[f][0], out[f][1], 'LOW'))
    # a file whose path a test asserts (a layout name read back from the metadata) stays where it is: moving it would change
    # an observed value, and expected values are never edited in a move
    pinned = asserted_paths(al_of_app, content)
    for f in files:
        if not f.endswith('.al') and (app_of(f), f[len(app_of(f)) + 1:].lower()) in pinned and out[f][0] != f:
            out[f] = (f, 'rule: a test asserts this path, it stays')
            review.append((f, f, out[f][1], ''))
    return out, review, files


PROPERTY = re.compile(r'^(LayoutFile|RDLCLayout|WordLayout|ExcelLayout|Scripts|StyleSheets|Images|StartupScript|RecreateScript|RefreshScript)\s*=', re.I)


def quoted_paths(src):
    """(match, in a path property) for every quoted file path of an AL source."""
    for m in QUOTED.finditer(src):
        start = max(src.rfind(c, 0, m.start()) for c in ';{}') + 1
        ctx = '\n'.join(line.split('//')[0] for line in src[start:m.start()].split('\n')).strip()
        yield m, bool(PROPERTY.match(ctx))


def asserted_paths(al_of_app, content):
    keys = set()
    for app, fs in al_of_app.items():
        for g in fs:
            for m, prop in quoted_paths(content(g)):
                if not prop:
                    s = m.group(1)
                    keys.add((app, (s[2:] if s.startswith('./') else s).replace('\\', '/').lower()))
    return keys


def check_collisions(out):
    tgt = collections.defaultdict(list)
    for old, (new, _) in out.items():
        if new != DELETE:
            tgt[new.lower()].append(old)
    return {k: v for k, v in tgt.items() if len(v) > 1}


def write_map(out, files):
    with open(MAP, 'w', encoding='utf-8') as o:
        o.write('old_path\tnew_path\thow\n')
        for old in sorted(out):
            new, how = out[old]
            o.write(f'{old}\t{new}\t{"map" if how == "map" else how}\n')


def cmd_plan(root, args):
    refs = [args[i + 1] for i, a in enumerate(args) if a == '--ref']
    out, review, files = plan(root, refs)
    col = check_collisions(out)
    for k, v in col.items():
        print(f'COLLISION {k}: {", ".join(v)}')
    moved = sum(1 for o, (n, _) in out.items() if n != o)
    print(f'files {len(out)}, move {moved}, delete {sum(1 for n, _ in out.values() if n == DELETE)}, '
          f'mapped by rule {len(review)} (low confidence {sum(1 for r in review if r[3])})')
    for r in review:
        print('REVIEW\t' + '\t'.join(map(str, r)))
    if '--write' in args:
        write_map(out, files)
    return 1 if col else 0


# ---- apply
QUOTED = re.compile(r"'((?:\./)?[^'\n]+\.(?:rdl|rdlc|docx|xlsx|rlblayout|dotx|txt|json|csv|bin|xml|xlf|png|css|js))'", re.I)


def app_of(p):
    return '/'.join(p.split('/')[:2])


SPLIT_AT = 'recordref-fieldref'


def area_of(p):
    parts = p.split('/')
    return parts[2] if len(parts) > 3 else ''


def in_part(n, part):
    if part is None:
        return True
    first = n == DELETE or area_of(n) < SPLIT_AT
    return first if part == 1 else not first


def apply(root, part=None):
    out, review, files = plan(root)
    if check_collisions(out):
        sys.exit('collisions; run plan')
    moves = {o: n for o, (n, _) in out.items() if n != o and files[o] is None and in_part(n, part)}
    # 1. path strings: quoted app-relative paths of moved non-AL files, in the AL files of the same app
    rel_moves = {}
    for o, n in moves.items():
        if n != DELETE and not o.endswith('.al'):
            if app_of(o) != app_of(n):
                sys.exit(f'non-AL file changes app: {o}')
            rel_moves[(app_of(o), o[len(app_of(o)) + 1:].lower())] = n[len(app_of(n)) + 1:]
    old_dirs, kept_dirs = collections.defaultdict(set), set()
    for o, (n, _) in out.items():
        a, d = app_of(o), os.path.dirname(o[len(app_of(o)) + 1:]).lower()
        if n == o:
            kept_dirs.add((a, d))
        elif n != DELETE:
            old_dirs[(a, d)].add(os.path.dirname(n[len(app_of(n)) + 1:]))
    gone_dirs = {k for k in old_dirs if k not in kept_dirs}
    dir_moves = {k: next(iter(v)) for k, v in old_dirs.items() if len(v) == 1 and k in gone_dirs}
    al_of_app = collections.defaultdict(list)
    for g in files:
        if g.endswith('.al') and files[g] is None:
            al_of_app[app_of(g)].append(g)
    pinned = asserted_paths(al_of_app, lambda g: open(os.path.join(root, g), encoding='utf-8-sig', errors='replace').read())
    edited = []
    for f in files:
        if not f.endswith('.al') or files[f] is not None:
            continue
        # generated layouts follow their AL file: only rewrite them in the part that moves it (or when it never moves)
        own_move = f in moves or out[f][0] == f
        p = os.path.join(root, f)
        src = open(p, encoding='utf-8-sig', errors='strict', newline='').read()
        raw = open(p, 'rb').read()
        bom = raw.startswith(b'\xef\xbb\xbf')

        def sub(m):
            s = m.group(1)
            dot = s.startswith('./')
            key = (app_of(f), (s[2:] if dot else s).replace('\\', '/').lower())
            if key in pinned:
                return m.group(0)
            if key in rel_moves:
                return "'" + ('./' if dot else '') + rel_moves[key] + "'"
            # a layout the compiler generates (not committed) in a folder that moves: follow the folder, so the generated file
            # lands next to its report and no old folder comes back at build time
            d = os.path.dirname(key[1])
            if not own_move:
                return m.group(0)
            if not d and key[0] == 'tests/al-language' and s.lower().endswith(LAYOUT_EXT):
                # app-root layouts move to _fixtures/layouts, also the ones the compiler generates
                return "'" + ('./' if dot else '') + '_fixtures/layouts/' + s.split('/')[-1] + "'"
            if d and (key[0], d) in gone_dirs and s.lower().endswith(LAYOUT_EXT):
                nd = dir_moves.get((key[0], d)) or os.path.dirname(moves.get(f, f))[len(key[0]) + 1:]
                return "'" + ('./' if dot else '') + nd + '/' + os.path.basename(s) + "'"
            return m.group(0)
        parts, last = [], 0
        for m, prop in quoted_paths(src):
            if prop:
                parts += [src[last:m.start()], sub(m)]
                last = m.end()
        new = ''.join(parts) + src[last:]
        if new != src:
            open(p, 'w', encoding='utf-8-sig' if bom else 'utf-8', newline='').write(new)
            edited.append(f)
    # 2. app.json resourceFolders
    for app in sorted({app_of(o) for o in moves}):
        aj = os.path.join(root, app, 'app.json')
        if not os.path.exists(aj):
            continue
        txt = open(aj, encoding='utf-8-sig').read()
        m = re.search(r'"resourceFolders"\s*:\s*\[([^\]]*)\]', txt)
        if not m:
            continue
        for folder in re.findall(r'"([^"]+)"', m.group(1)):
            pre = f'{app}/{folder}/'
            if any(o.startswith(pre) for o in moves):
                sys.exit(f'{aj}: resource folder {folder} would move; map its files to stay or extend apply()')
    # 3. git mv / rm
    for o, n in sorted(moves.items()):
        if n == DELETE:
            git('rm', '-q', '--', o, cwd=root)
        else:
            os.makedirs(os.path.join(root, os.path.dirname(n)), exist_ok=True)
            git('mv', '--', o, n, cwd=root)
    if edited:
        git('add', '--', *[moves.get(f, f) for f in edited], cwd=root)
    # 4. paths in the docs that name moved files or folders (dated history under docs/ stays as written)
    full_dirs = {}
    for (a, d), nd in dir_moves.items():
        full_dirs[f'{a}/{d}'] = f'{a}/{nd}'
    lower_moves = {o.lower(): n for o, n in moves.items() if n != DELETE}
    doc_edits = []
    for doc in DOCS:
        p = os.path.join(root, doc)
        if not os.path.exists(p):
            continue
        txt = open(p, encoding='utf-8').read()

        def dsub(m):
            t = m.group(0)
            core = t.rstrip('./')
            tail = t[len(core):]
            if core.lower() in lower_moves:
                return lower_moves[core.lower()] + tail
            if core.lower() in full_dirs:
                return full_dirs[core.lower()] + tail
            return t
        new = DOC_PATH.sub(dsub, txt)
        if new != txt:
            open(p, 'w', encoding='utf-8').write(new)
            doc_edits.append(doc)
    if doc_edits:
        git('add', '--', *doc_edits, cwd=root)
    # 5. READMEs
    readmes = write_readmes(root, out, files, part)
    git('add', '--', *readmes, cwd=root)
    le = os.path.join(DATA, 'layout-edits.txt')
    prev = {line.strip() for line in open(le) if line.strip() and not line.startswith('#')} if os.path.exists(le) else set()
    with open(le, 'w', encoding='utf-8') as o:
        o.write('# AL files whose quoted layout/resource paths apply() rewrote (path after the move); check accepts only these as modified\n')
        for f in sorted(prev | {moves.get(f, f) for f in edited}):
            o.write(f + '\n')
    git('add', '--', os.path.relpath(os.path.join(DATA, 'layout-edits.txt'), root), cwd=root)
    print(f'moved {sum(1 for n in moves.values() if n != DELETE)}, deleted {sum(1 for n in moves.values() if n == DELETE)}, '
          f'layout path edits {len(edited)}, doc path edits {len(doc_edits)}, READMEs {len(readmes)}')


def write_readmes(root, out, files, part=None):
    final = {}
    for o, (n, _) in out.items():
        if files[o] is None and n != DELETE:
            final[n] = o
    def read(n):
        return open(os.path.join(root, n if os.path.exists(os.path.join(root, n)) else final[n]), encoding='utf-8-sig', errors='replace').read()
    # fixture names: objects defined under _fixtures
    fx = {}
    for n in final:
        if n.startswith('tests/al-language/_fixtures/') and n.endswith('.al'):
            src = read(n)
            for kind, oid, name in re.findall(r'^\s*(table|page|report|query|xmlport|enum|codeunit|interface|permissionset)\s+(\d+)\s+"([^"]+)"', src, re.I | re.M):
                fx[name] = f'{kind.lower()} {oid}'
    sens = {}
    if os.path.exists(SENSITIVE):
        for line in open(SENSITIVE, encoding='utf-8'):
            f = line.rstrip('\n').split('\t')
            if len(f) > 1 and ('line-number-in-text' in f[1] or 'callstack-object-id' in f[1]) and f[0] in out:
                sens[out[f[0]][0]] = f[1]
    mnc = collections.defaultdict(list)
    areas_tsv = os.path.join(root, 'tests/must-not-compile/areas.tsv')
    for line in open(areas_tsv, encoding='utf-8'):
        f = line.rstrip('\n').split('\t')
        if len(f) == 2 and not line.startswith(('#', 'stem\t')):
            mnc[f[1]].append(f[0])
    apps = sorted({app_of(n) for n in final if app_of(n) != 'tests/al-language'})
    written = []
    for area, scope in AREAS:
        if not in_part(f'tests/al-language/{area}/x', part):
            continue
        prefix = f'tests/al-language/{area}/'
        mine = [n for n in final if n.startswith(prefix)]
        topics = collections.Counter(n[len(prefix):].split('/')[0] if '/' in n[len(prefix):] else '' for n in mine if n.endswith('.al'))
        used = collections.Counter()
        if area != '_fixtures':
            for n in mine:
                if n.endswith('.al'):
                    src = read(n)
                    for name in fx:
                        if f'"{name}"' in src:
                            used[name] += 1
        L = [f'# {area}', '', scope, '']
        L += ['## Topics', '']
        if topics.get(''):
            L.append(f'- (area folder itself): {topics[""]} AL files that are about the area as a whole or were not given a topic yet.')
        for t in sorted(k for k in topics if k):
            scope = TOPIC_SCOPE.get(t, 'named after its old folder; scope to be written (REVIEW)')
            L.append(f'- `{t}/`: {scope} ({topics[t]} AL {"file" if topics[t] == 1 else "files"}).')
        L += ['', 'A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).', '']
        if area == '_fixtures':
            L += ['## Objects', '']
            for name in sorted(fx, key=lambda k: (fx[k].split()[0], int(fx[k].split()[1]))):
                L.append(f'- {fx[name]} "{name}"')
            L += ['', 'Shared fixtures are frozen once merged: never change their fields, keys or triggers. Add a new one '
                      'instead (ids 50000..50999), with a line here.', '']
        else:
            L += ['## Shared fixtures used here', '']
            if used:
                for name, c in used.most_common(12):
                    L.append(f'- {fx[name]} "{name}": {c} {"file" if c == 1 else "files"}')
            else:
                L.append('- none yet; see `../_fixtures/README.md` before you add a local object.')
            L.append('')
        other = [f'`{a}/{area}/`' for a in apps if any(n.startswith(f'{a}/{area}/') for n in final)]
        if area == 'test-framework':
            other += [f'`{a}/`' for a in apps if a.endswith('testlibraries')]
        L += ['## Other apps', '']
        L.append('- Same area in other apps (only what cannot compile in the Cloud app): ' + (', '.join(other) if other else 'none') + '.')
        if area in mnc:
            L.append(f'- Must-not-compile cases ({len(mnc[area])}, in `tests/must-not-compile/cases/`, listed by '
                     f'`tests/must-not-compile/areas.tsv`): ' + ', '.join(f'`{s}`' for s in sorted(mnc[area])) + '.')
        L.append('')
        mine_s = sorted(n for n in sens if n.startswith(prefix))
        if mine_s:
            L += ['## Line-sensitive files', '',
                  'These files assert line numbers or call stacks. Only append at the end of the codeunit; never add or remove '
                  'lines above existing code (standing rule 5).', '']
            L += [f'- `{n[len(prefix):]}`' for n in mine_s]
            L.append('')
        L += ['## Adding a test', '',
              '1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.',
              '2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.',
              '3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.',
              '4. Name the folder after the topic, never after a writer, an issue or a batch.',
              '5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.', '']
        p = os.path.join(root, prefix, 'README.md')
        os.makedirs(os.path.dirname(p), exist_ok=True)
        open(p, 'w', encoding='utf-8').write('\n'.join(L))
        written.append(prefix + 'README.md')
    return written


def cmd_check(root, base):
    edits = set()
    le = os.path.join(DATA, 'layout-edits.txt')
    if os.path.exists(le):
        edits = {line.strip() for line in open(le) if line.strip() and not line.startswith('#')}
    txt = subprocess.run(['git', '-c', 'diff.renameLimit=20000', 'diff', '--cached', '-M100%', '--name-status', base],
                         cwd=root, capture_output=True, text=True, check=True).stdout
    kinds, bad = collections.Counter(), []
    pm = read_map()
    for line in txt.splitlines():
        f = line.split('\t')
        k = f[0]
        path = f[-1]
        if k == 'R100':
            kinds['R100'] += 1
        elif k == 'A' and re.match(r'^tests/al-language/[^/]+/README\.md$', path):
            kinds['README'] += 1
        elif k == 'D' and BUILD_OUTPUT.match(path):
            kinds['build output removed'] += 1
        elif path.startswith('.github/restructure/') or path == '.github/scripts/restructure-move.py':
            kinds['restructure data'] += 1
        elif k == 'M' and path in DOCS:
            kinds['doc path edit'] += 1
        elif (k.startswith(('R', 'A', 'M')) and path in edits) or (k == 'D' and pm.get(path, ('',))[0] in edits):
            kinds['layout edit (' + k[:1] + ')'] += 1
        else:
            bad.append(line)
    print(dict(kinds))
    for b in bad:
        print('UNEXPECTED\t' + b)
    if edits:
        # a layout edit may only change quoted paths
        back = {n: o for o, (n, _) in read_map().items()}
        for path in sorted(edits):
            d = subprocess.run(['git', '-c', 'diff.renameLimit=20000', 'diff', '--cached', '-M50%', '-U0', base, '--',
                                back.get(path, path), path],
                               cwd=root, capture_output=True, text=True).stdout
            for line in d.splitlines():
                if line[:1] in '+-' and not line.startswith(('+++', '---')) and not QUOTED.search(line):
                    bad.append(f'{path}: {line}')
                    print(f'UNEXPECTED EDIT {path}: {line}')
    # a doc edit may only change paths
    for path in DOCS:
        d = subprocess.run(['git', 'diff', '--cached', '-U0', '--word-diff=porcelain', base, '--', path], cwd=root,
                           capture_output=True, text=True).stdout
        for line in d.splitlines():
            if line[:1] in '+-' and not line.startswith(('+++', '---')) and not DOC_PATH.search(line):
                bad.append(f'{path}: {line}')
                print(f'UNEXPECTED DOC EDIT {path}: {line}')
    return 1 if bad else 0


def main(argv):
    root = git('rev-parse', '--show-toplevel', cwd=HERE).strip()
    if argv[:1] == ['plan']:
        return cmd_plan(root, argv[1:])
    if argv[:1] == ['apply']:
        apply(root, int(argv[argv.index('--part') + 1]) if '--part' in argv else None)
        return 0
    if argv[:1] == ['check'] and len(argv) == 2:
        return cmd_check(root, argv[1])
    print(__doc__)
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
