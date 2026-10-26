# -*- coding: utf-8 -*-
"""afgen - sinh file XML Adobe Form (SFP -> Utilities -> Upload) cho SAP GUI On-Premise.

1 form = 2 object, mỗi object 1 file, upload theo thứ tự:
  SFPI_<INTERFACE>.XML   interface: tham số import, global data, code Initialization
  SFPF_<FORM>.XML        form: tên interface + context + layout XDP (base64 trong thẻ LAYOUT)

Khung asXML phát ra khớp từng byte file SAP export (kiểm bằng af_selftest.py).
Layout XDP dựng bằng page/text/field/qrcode/image/image_field/block/flow/repeat/table.

    from afgen import Interface, Form, page, repeat, block, text, field
    Interface('Mô tả').param('GT_DATA', 'ZTT_ABC').write('SFPI_ZIF_ABC.XML')
    f = Form('ZAF_ABC', 'ZIF_ABC', 'Mô tả form')
    f.loop('GT_DATA', ['MATNR', 'MAKTX'])      # đủ field, đúng thứ tự line type trong SE11
    f.layout(page('A4', margin=10), [repeat('GT_DATA', [field('MATNR', w=60, h=6)])])
    f.write('SFPF_ZAF_ABC.XML')

Form có context làm bằng SFP (node chưa có mẫu): inject_layout(src, dst, page(...), [...]).
Chi tiết: ../references/xml-structure.md, ../references/xdp-layout.md
"""
import base64
import datetime
import os
import re
import uuid
import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape as _esc

# ======================================================================
# 1. asXML - khung chung SFPI/SFPF
# ======================================================================
_ASX = 'http://www.sap.com/abapxml'
_HEAD = '<?xml version="1.0" encoding="utf-8"?><asx:abap version="1.0" xmlns:asx="%s">' % _ASX
_HEAP = ('<asx:heap xmlns:xsd="http://www.w3.org/2001/XMLSchema" '
         'xmlns:abap="http://www.sap.com/abapxml/types/built-in" '
         'xmlns:cls="http://www.sap.com/abapxml/classes/global" '
         'xmlns:dic="http://www.sap.com/abapxml/types/dictionary">')
_END = '</asx:heap></asx:abap>'


def _t(tag, val=''):
    """<TAG>val</TAG>, rỗng thì <TAG/> - đúng cách SAP ghi."""
    return '<%s>%s</%s>' % (tag, _esc(val), tag) if val else '<%s/>' % tag


def _r(tag, obj):
    return '<%s href="#%s"/>' % (tag, obj.oid) if obj is not None else '<%s/>' % tag


def _lst(tag, inner):
    return '<%s>%s</%s>' % (tag, inner, tag) if inner else '<%s/>' % tag


def _rows(tag, cols, rows):
    return ''.join('<%s>%s</%s>' % (tag, ''.join(_t(c, r.get(c, '')) for c in cols), tag) for r in rows)


def _guid():
    return uuid.uuid4().hex.upper()


def _local(tag):
    return tag.rsplit('}', 1)[-1]


def _x(e, tag):
    c = e.find(tag) if e is not None else None
    return (c.text or '') if c is not None else ''


def _href(e, tag):
    c = e.find(tag) if e is not None else None
    h = c.get('href') if c is not None else None
    return h[1:] if h else None


def _load(src):
    data = src if isinstance(src, bytes) else open(src, 'rb').read()
    root = ET.fromstring(data)
    vals = root.find('{%s}values' % _ASX)
    heap = {e.get('id'): e for e in root.find('{%s}heap' % _ASX)}
    return vals, heap


def _write(path, text):
    with open(path, 'w', encoding='utf-8', newline='') as f:   # newline='' giữ nguyên LF trong base64
        f.write(text)
    return path


def _b64(data):
    """base64 76 ký tự/dòng, xuống dòng LF, không có LF cuối - như SAP export."""
    return base64.encodebytes(data).decode('ascii').rstrip('\n')


class _Obj(object):
    """1 đối tượng trong asx:heap."""
    CLS = ''
    oid = None

    def refs(self):
        return []

    def body(self):
        return ''

    def xml(self):
        return '<cls:%s id="%s">%s</cls:%s>' % (self.CLS, self.oid, self.body(), self.CLS)


def _heap(roots):
    """Thứ tự heap như SAP ghi: duyệt kiểu stack (LIFO), mỗi đối tượng đẩy các tham chiếu theo đúng
    thứ tự thuộc tính. Đối tượng chưa có id được đánh oN (giữ id cũ khi đọc từ file)."""
    order, seen, stack = [], set(), list(roots)
    while stack:
        o = stack.pop()
        if o is None or id(o) in seen:
            continue
        seen.add(id(o))
        order.append(o)
        stack.extend(r for r in o.refs() if r is not None and id(r) not in seen)
    used, n = {o.oid for o in order if o.oid}, 1
    for o in order:
        if not o.oid:
            while 'o%d' % n in used:
                n += 1
            o.oid = 'o%d' % n
            used.add(o.oid)
    return order


# ----------------------------------------------------------------------
# 1a. Interface (SFPI)
# ----------------------------------------------------------------------
_IOPAR = ('NAME', 'TYPING', 'TYPENAME', 'OPTIONAL', 'BYVALUE', 'DEFAULTVAL', 'STANDARD', 'CONSTANT')
_GDATA = ('NAME', 'TYPING', 'TYPENAME', 'DEFAULTVAL', 'CONSTANT')
_ITF_PARTS = ('CODING', 'PARAMETERS', 'GLOBAL_DEFINITIONS', 'REFERENCE_FIELDS')


class _Part(_Obj):
    """Con của CL_FP_INTERFACE_DATA, có khối CL_FP_INTERFACE_DATA_CHANGED trỏ ngược về interface."""

    def __init__(self, cls, owner, inner):
        self.CLS, self.owner, self.inner = cls, owner, inner

    def refs(self):
        return [self.owner]

    def body(self):
        return ('<CL_FP_INTERFACE_DATA_CHANGED classVersion="1">%s</CL_FP_INTERFACE_DATA_CHANGED>'
                '<%s classVersion="1">%s</%s>' % (_r('INTERFACE_DATA', self.owner), self.CLS, self.inner(), self.CLS))


class _ItfData(_Obj):
    CLS = 'CL_FP_INTERFACE_DATA'

    def __init__(self):
        self.parts = []          # coding, parameters, global definitions, reference fields

    def refs(self):
        return list(self.parts)

    def body(self):
        return ('<CL_FP_INTERFACE_DATA classVersion="1">%s<XSD_DEFINITIONS/></CL_FP_INTERFACE_DATA>'
                % ''.join(_r(k, o) for k, o in zip(_ITF_PARTS, self.parts)))


class Interface(object):
    """Interface 'ABAP Dictionary-based' (thẻ TYPE rỗng như cả 3 mẫu)."""

    def __init__(self, text='', lang='E'):
        self.text, self.lang = text, lang
        self.imports, self.gdata = [], []
        self.inputs, self.outputs, self.init_lines, self.form_lines = [], [], [], []
        self.unsupported = []    # phần có dữ liệu nhưng chưa có mẫu (khi đọc file)
        self.oids = {}           # id gốc khi đọc file (để selftest so từng byte)

    def param(self, name, typename, typing='TYPE', optional=False, default=''):
        """Tham số import. Mẫu thật: 1 tham số TYPE <table type>."""
        self.imports.append({'NAME': name.upper(), 'TYPING': typing, 'TYPENAME': typename.upper(),
                             'OPTIONAL': 'X' if optional else '', 'DEFAULTVAL': default})
        return self

    def global_data(self, name, typename, typing='TYPE', default='', constant=False):
        self.gdata.append({'NAME': name.upper(), 'TYPING': typing, 'TYPENAME': typename.upper(),
                           'DEFAULTVAL': default, 'CONSTANT': 'X' if constant else ''})
        return self

    def init_code(self, lines, inputs=(), outputs=(), user=None, now=None):
        """Code Initialization. outputs: biến code ghi (phải là global data để context dùng).
        user: tên viết tắt trong UserName.md -> bọc marker "<user> add begin/end dd.mm.yyyy hh:mm:ss."""
        lines = list(lines)
        if user:
            ts = (now or datetime.datetime.now()).strftime('%d.%m.%Y %H:%M:%S')
            lines = ['"%s add begin %s' % (user, ts)] + lines + ['"%s add end %s' % (user, ts)]
        self.inputs += [p.upper() for p in inputs if p.upper() not in self.inputs]
        self.outputs += [p.upper() for p in outputs if p.upper() not in self.outputs]
        self.init_lines += lines
        return self

    def logo_bds(self, name, var='LOGO', btype='BCOL', user=None, now=None):
        """Đọc ảnh SE78 (BDS, id BMAP) vào global data XSTRING - y code mẫu ZIF_BC_NHAN_BC_LSX."""
        self.global_data(var, 'XSTRING')
        return self.init_code([
            "CALL METHOD CL_SSF_XSF_UTILITIES=>GET_BDS_GRAPHIC_AS_BMP",
            "  EXPORTING",
            "    P_OBJECT       = 'GRAPHICS'",
            "    P_NAME         = '%s'" % name.upper(),
            "    P_ID           = 'BMAP'",
            "    P_BTYPE        = '%s'" % btype,
            "  RECEIVING",
            "    P_BMP          = %s" % var.upper(),
            "  EXCEPTIONS",
            "    NOT_FOUND      = 1",
            "    INTERNAL_ERROR = 2",
            "    OTHERS         = 3."], outputs=[var], user=user, now=now)

    def render(self):
        root = _ItfData()
        root.parts = [
            _Part('CL_FP_CODING', root, lambda: (
                _lst('INPUT_PARAMETERS', ''.join(_t('FPPARAMETER', p) for p in self.inputs))
                + _lst('OUTPUT_PARAMETERS', ''.join(_t('FPPARAMETER', p) for p in self.outputs))
                + _lst('INITIALIZATION', ''.join(_t('FPCLINE', l) for l in self.init_lines))
                + _lst('FORMS', ''.join(_t('FPCLINE', l) for l in self.form_lines)))),
            _Part('CL_FP_PARAMETERS', root, lambda: (
                _lst('IMPORT_PARAMETERS', _rows('SFPIOPAR', _IOPAR, self.imports))
                + '<EXPORT_PARAMETERS/><TABLE_PARAMETERS/><EXCEPTIONS/>')),
            _Part('CL_FP_GLOBAL_DEFINITIONS', root, lambda: (
                _lst('GLOBAL_DATA', _rows('SFPGDATA', _GDATA, self.gdata)) + '<TYPES/><FIELDSYMBOLS/>')),
            _Part('CL_FP_REFERENCE_FIELDS', root, lambda: '<REFERENCE_FIELDS/>')]
        for key, o in zip(('INTERFACE',) + _ITF_PARTS, [root] + root.parts):
            o.oid = self.oids.get(key)
        objs = _heap([root])
        values = ('<asx:values><VERSION>1</VERSION><TYPE/>%s<INTERFACET><FPINTERFACET><NAME/><STATE/>%s<ID/>%s'
                  '</FPINTERFACET></INTERFACET></asx:values>'
                  % (_r('INTERFACE', root), _t('LANGUAGE', self.lang), _t('TEXT', self.text)))
        return _HEAD + values + _HEAP + ''.join(o.xml() for o in objs) + _END

    def write(self, path):
        return _write(path, self.render())

    @classmethod
    def parse(cls, src):
        vals, heap = _load(src)
        ft = vals.find('INTERFACET/FPINTERFACET')
        itf = cls(_x(ft, 'TEXT'), _x(ft, 'LANGUAGE'))
        itf.oids['INTERFACE'] = _href(vals, 'INTERFACE')
        data = heap[itf.oids['INTERFACE']].find('CL_FP_INTERFACE_DATA')
        part = {}
        for key in _ITF_PARTS:
            itf.oids[key] = _href(data, key)
            part[key] = heap[itf.oids[key]].find('CL_FP_' + key)
        cod = part['CODING']
        itf.inputs = [p.text or '' for p in cod.find('INPUT_PARAMETERS')]
        itf.outputs = [p.text or '' for p in cod.find('OUTPUT_PARAMETERS')]
        itf.init_lines = [l.text or '' for l in cod.find('INITIALIZATION')]
        itf.form_lines = [l.text or '' for l in cod.find('FORMS')]
        par = part['PARAMETERS']
        itf.imports = [{c.tag: c.text or '' for c in p} for p in par.find('IMPORT_PARAMETERS')]
        gd = part['GLOBAL_DEFINITIONS']
        itf.gdata = [{c.tag: c.text or '' for c in g} for g in gd.find('GLOBAL_DATA')]
        for e, tags in ((par, ('EXPORT_PARAMETERS', 'TABLE_PARAMETERS', 'EXCEPTIONS')), (gd, ('TYPES', 'FIELDSYMBOLS')),
                        (part['REFERENCE_FIELDS'], ('REFERENCE_FIELDS',)), (data, ('XSD_DEFINITIONS',))):
            itf.unsupported += [t for t in tags if e.find(t) is not None and (len(e.find(t)) or (e.find(t).text or '').strip())]
        return itf


# ----------------------------------------------------------------------
# 1b. Context (SFPF)
# ----------------------------------------------------------------------
class _Cond(_Obj):
    """CL_FP_CONDITION rỗng - mọi node (trừ gốc) có 1 cái, node LOOP có thêm 1 cái cho WHERE."""
    CLS = 'CL_FP_CONDITION'

    def __init__(self, node):
        self.node = node

    def refs(self):
        return [self.node]

    def body(self):
        return '<CL_FP_CONDITION classVersion="1">%s<CONDITIONS/></CL_FP_CONDITION>' % _r('NODE', self.node)


class Node(_Obj):
    """Phần CL_FP_NODE chung: ID (GUID 32 hex), NAME, GENERATED, STATE, CONDITION, PARENT, SUCCESSOR, CHILD."""
    has_condition = False        # True khi đọc file có điều kiện node/WHERE (chưa có mẫu)

    def __init__(self, name, generated=False, guid=None, text=None):
        self.name, self.generated, self.guid, self.text = name, generated, guid or _guid(), text
        self.state = 'A'
        self.parent = self.successor = self.child = None
        self.cond = _Cond(self)
        self.kids = []

    def add(self, node):
        node.parent = self
        if self.kids:
            self.kids[-1].successor = node
        else:
            self.child = node
        self.kids.append(node)
        return node

    def walk(self):
        yield self
        for k in self.kids:
            for n in k.walk():
                yield n

    def refs(self):
        return [self.cond, self.parent, self.successor, self.child]

    def tail(self):
        return '<%s classVersion="1"/>' % self.CLS

    def body(self):
        return ('<CL_FP_NODE classVersion="1">' + _t('ID', self.guid) + _t('NAME', self.name)
                + _t('GENERATED', 'X' if self.generated else '') + _t('STATE', self.state)
                + _r('CONDITION', self.cond) + _r('PARENT', self.parent) + _r('SUCCESSOR', self.successor)
                + _r('CHILD', self.child) + '</CL_FP_NODE>' + self.tail())


class Context(Node):
    CLS = 'CL_FP_CONTEXT'

    def __init__(self, guid=None):
        Node.__init__(self, 'CONTEXT', guid=guid)
        self.cond = None


class Loop(Node):
    """Node bảng (kéo tham số TYPE table type vào context)."""
    CLS = 'CL_FP_LOOP'

    def __init__(self, table, **kw):
        Node.__init__(self, table, **kw)
        self.table = self.work_area = table
        self.loop_into, self.first_line, self.last_line = 'X', '0000000000', '0000000000'
        self.where = _Cond(self)

    def refs(self):
        return Node.refs(self) + [self.where]

    def tail(self):
        return ('<CL_FP_LOOP classVersion="1">' + _t('TABLE_NAME', self.table) + _t('LOOP_INTO', self.loop_into)
                + _t('WORK_AREA', self.work_area) + _t('FIRST_LINE', self.first_line) + _t('LAST_LINE', self.last_line)
                + _r('WHERE_CONDITION', self.where) + '<SORTED/><CONTROL_LEVEL/></CL_FP_LOOP>')


class LoopData(Node):
    """Node 'DATA' (dòng của bảng) - SAP luôn đặt tên DATA."""
    CLS = 'CL_FP_LOOP_DATA'


class Data(Node):
    """Field; dưới LOOP_DATA thì GENERATED=X, FIELD = <WORK_AREA>-<FIELD>."""
    CLS = 'CL_FP_DATA'

    def __init__(self, name, field, **kw):
        Node.__init__(self, name, **kw)
        self.field = field

    def tail(self):
        return '<CL_FP_DATA classVersion="1">%s<FIELD_LABEL/></CL_FP_DATA>' % _t('FIELD', self.field)


class Graphic(Node):
    """Graphic content: ảnh lấy từ 1 biến XSTRING (global data) - mẫu ZAF_BC_NHAN_BC_LSX_12X16N."""
    CLS = 'CL_FP_GRAPHIC_CONTENT'

    def __init__(self, name, field, mime='image/bmp', **kw):
        Node.__init__(self, name, **kw)
        self.field, self.mime = field, mime

    def tail(self):
        return ('<CL_FP_GRAPHIC classVersion="1"/><CL_FP_GRAPHIC_CONTENT classVersion="1">%s<GRAPHIC_MIME>%s'
                '<MIMEFIELD/></GRAPHIC_MIME></CL_FP_GRAPHIC_CONTENT>' % (_t('GRAPHIC_FIELD', self.field), _t('MIME', self.mime)))


class Other(Node):
    """Loại node chưa có mẫu (chỉ đọc để in/kiểm tra, không sinh lại được)."""

    def __init__(self, cls, name, **kw):
        Node.__init__(self, name, **kw)
        self.CLS = cls

    def tail(self):
        raise ValueError('Node %s (%s) chưa có mẫu - không sinh lại được, dùng inject_layout()' % (self.name, self.CLS))


class _Layout(_Obj):
    CLS = 'CL_FP_LAYOUT'

    def __init__(self, cache_info, layout_type):
        self.cache_info, self.layout_type = cache_info, layout_type

    def body(self):
        return ('<CL_FP_LAYOUT classVersion="1"><TRANSLATION_TYPE/>%s%s<FORM_TECH/></CL_FP_LAYOUT>'
                % (_t('CACHE_INFO', self.cache_info), _t('LAYOUT_TYPE', self.layout_type)))


def _parse_node(heap, oid):
    e = heap[oid]
    cls, nd = _local(e.tag), e.find('CL_FP_NODE')
    name, guid = _x(nd, 'NAME'), _x(nd, 'ID')
    if cls == 'CL_FP_CONTEXT':
        n = Context(guid)
    elif cls == 'CL_FP_LOOP':
        lp = e.find('CL_FP_LOOP')
        n = Loop(_x(lp, 'TABLE_NAME'), guid=guid)
        n.name, n.work_area, n.loop_into = name, _x(lp, 'WORK_AREA'), _x(lp, 'LOOP_INTO')
        n.first_line, n.last_line = _x(lp, 'FIRST_LINE'), _x(lp, 'LAST_LINE')
        n.where.oid = _href(lp, 'WHERE_CONDITION')
    elif cls == 'CL_FP_LOOP_DATA':
        n = LoopData(name, guid=guid)
    elif cls == 'CL_FP_DATA':
        n = Data(name, _x(e.find('CL_FP_DATA'), 'FIELD'), guid=guid)
    elif cls == 'CL_FP_GRAPHIC_CONTENT':
        g = e.find('CL_FP_GRAPHIC_CONTENT')
        n = Graphic(name, _x(g, 'GRAPHIC_FIELD'), _x(g.find('GRAPHIC_MIME'), 'MIME'), guid=guid)
    else:
        n = Other(cls, name, guid=guid)
    n.oid, n.generated, n.state = oid, _x(nd, 'GENERATED') == 'X', _x(nd, 'STATE')
    if n.cond is not None:
        n.cond.oid = _href(nd, 'CONDITION')
    for cid in (_href(nd, 'CONDITION'), getattr(getattr(n, 'where', None), 'oid', None)):
        conds = heap[cid].find('CL_FP_CONDITION/CONDITIONS') if cid in heap else None
        if conds is not None and len(conds):
            n.has_condition = True           # điều kiện node/WHERE có nội dung - chưa có mẫu
    c = _href(nd, 'CHILD')
    while c:
        n.add(_parse_node(heap, c))
        c = _href(heap[c].find('CL_FP_NODE'), 'SUCCESSOR')
    return n


# ----------------------------------------------------------------------
# 1c. Form (SFPF)
# ----------------------------------------------------------------------
class Form(object):
    def __init__(self, name, interface, text='', lang='E'):
        self.name, self.interface, self.text, self.lang = name.upper(), interface.upper(), text, lang
        self.ctx = Context()
        self.xdp = b''               # layout XDP (UTF-8)
        self.cache_info = ''
        self.layout_type = 'S'
        self.layout_oid = None
        self.ctx_texts = None        # [(ID node, mô tả)] - giữ nguyên khi đọc từ file
        self.unsupported = []        # thẻ đầu file có giá trị chưa gặp trong mẫu (khi đọc file)

    # ---- context ----
    def loop(self, table, fields, text=None):
        """Node bảng cho tham số import `table` (TYPE table type). fields: TẤT CẢ field của line type,
        đúng thứ tự SE11 (SAP tự sinh đủ, kể cả field layout không dùng)."""
        table = table.upper()
        lp = self.ctx.add(Loop(table, text=text))
        row = lp.add(LoopData('DATA'))
        for f in fields:
            row.add(Data(f.upper(), '%s-%s' % (table, f.upper()), generated=True))
        return lp

    def graphic(self, name, field, mime='image/bmp', text=None):
        """Graphic content lấy ảnh từ global data `field` (XSTRING, điền trong code Initialization)."""
        return self.ctx.add(Graphic(name.upper(), field.upper(), mime,
                                    text='Graphic Node %s' % name.upper() if text is None else text))

    def data_description(self):
        """Cây dd:dataDescription suy từ context - đúng như SAP sinh trong 3 form mẫu."""
        def conv(n):
            if isinstance(n, Loop):
                return E(n.name, {'dd:minOccur': '0'}, [E(r.name, {'dd:maxOccur': '-1'}, [conv(f) for f in r.kids])
                                                        for r in n.kids])
            if isinstance(n, (Data, Graphic)) and not n.kids:
                return E(n.name)
            raise ValueError('Node %s (%s) chưa có mẫu dataDescription - tạo context bằng SFP rồi dùng inject_layout()'
                             % (n.name, n.CLS))
        return E('data', kids=[conv(k) for k in self.ctx.kids])

    # ---- layout ----
    def layout(self, pages, content, font='Arial', base_url='', now=None):
        """pages: page() hoặc list page(); content: các phần tử đặt dưới subform gốc 'data'.
        font: font mặc định cho mọi text/field không khai font. base_url: thẻ <base> của Designer (để trống được)."""
        self.xdp, self.cache_info = build_xdp(self.name, pages, content, self.data_description(), font, base_url, now)
        return self

    # ---- xuất / đọc file ----
    def render(self):
        if not self.xdp:
            raise ValueError('Chưa có layout - gọi layout() trước')
        lay = _Layout(self.cache_info, self.layout_type)
        lay.oid = self.layout_oid
        objs = _heap([self.ctx, lay])
        texts = self.ctx_texts if self.ctx_texts is not None else (
            [('', self.text)] + [(n.guid, n.text) for n in self.ctx.walk() if n.text])
        ctxt = ''.join('<FPCONTEXTT><NAME/><STATE/>%s%s%s</FPCONTEXTT>' % (_t('LANGUAGE', self.lang), _t('ID', i), _t('TEXT', t))
                       for i, t in texts)
        values = ('<asx:values><VERSION>1</VERSION><TYPE/>%s<OFFLINEHANDLER/><DATAPROVIDER/><FRTYPE/><CNTSET/><FNTEMB/>'
                  '<MIRRORING/>%s<CONTEXTT>%s</CONTEXTT>%s<LAYOUTT><FPLAYOUTT><NAME/><STATE/>%s<ID/><DIRTY/>%s<LAYOUTM/>'
                  '</FPLAYOUTT></LAYOUTT></asx:values>'
                  % (_t('INTERFACE', self.interface), _r('CONTEXT', self.ctx), ctxt, _r('LAYOUT', lay),
                     _t('LANGUAGE', self.lang), _t('LAYOUT', _b64(self.xdp))))
        return _HEAD + values + _HEAP + ''.join(o.xml() for o in objs) + _END

    def write(self, path):
        return _write(path, self.render())

    @classmethod
    def parse(cls, src):
        vals, heap = _load(src)
        f = cls('', _x(vals, 'INTERFACE'))
        f.unsupported = [t for t in ('TYPE', 'OFFLINEHANDLER', 'DATAPROVIDER', 'FRTYPE', 'CNTSET', 'FNTEMB', 'MIRRORING')
                         if _x(vals, t).strip()]
        f.ctx_texts = [(_x(t, 'ID'), _x(t, 'TEXT')) for t in vals.find('CONTEXTT')]
        f.text = next((t for i, t in f.ctx_texts if not i), '')
        lt = vals.find('LAYOUTT/FPLAYOUTT')
        f.lang = _x(lt, 'LANGUAGE')
        b64 = _x(lt, 'LAYOUT')
        f.xdp = base64.b64decode(b64) if b64.strip() else b''
        f.layout_oid = _href(vals, 'LAYOUT')
        lay = heap[f.layout_oid].find('CL_FP_LAYOUT')
        f.cache_info, f.layout_type = _x(lay, 'CACHE_INFO'), _x(lay, 'LAYOUT_TYPE')
        f.ctx = _parse_node(heap, _href(vals, 'CONTEXT'))
        m = re.search(rb'<xsdConnection [^>]*name="([^"]*)"', f.xdp)
        f.name = m.group(1).decode('utf-8') if m else ''
        return f


# ======================================================================
# 2. Layout XDP
# ======================================================================
_TPL_NS = 'http://www.xfa.org/schema/xfa-template/3.3/'
_GENERATOR = '<?xfa generator="AdobeLiveCycleDesigner_V11.0.1.20140218.1.907162_SAP" APIVersion="3.6.13324.0"?>'
_DESIGNER_VER = '11.0.1.20140218.1.907162.903801'
_TPL_PIS = ['DefaultPreviewDynamic 1', 'DefaultRunAt client', 'WidowOrphanControl 0',
            'DefaultCaptionFontSettings face:{font};size:10;weight:normal;style:normal',
            'DefaultValueFontSettings face:{font};size:10;weight:normal;style:normal', 'DefaultLanguage JavaScript']


class E(object):
    """Phần tử XDP. Thuộc tính sắp A-Z (như Designer ghi), bỏ thuộc tính None.
    text: nội dung trên cùng dòng; raw: 1 dòng XML có sẵn (thân exData)."""

    def __init__(self, tag, attrs=None, kids=None, text=None, raw=None):
        self.tag = tag
        self.attrs = dict((k, v) for k, v in (attrs or {}).items() if v is not None)
        self.kids = [k for k in (kids or []) if k is not None]
        self.text, self.raw = text, raw

    def lines(self, ind, out, ctx):
        pad, attrs = ' ' * ind, dict(self.attrs)
        if self.tag == 'font' and 'typeface' not in attrs:
            attrs['typeface'] = ctx.get('font', 'Arial')
        a = ''.join(' %s="%s"' % (k, _esc(str(v), {'"': '&quot;'})) for k, v in sorted(attrs.items()))
        if self.raw is not None:
            out += [pad + '<%s%s>' % (self.tag, a), pad + '   ' + self.raw, pad + '</%s>' % self.tag]
        elif self.text is not None:
            out.append(pad + '<%s%s>%s</%s>' % (self.tag, a, _esc(self.text), self.tag))
        elif not self.kids:
            out.append(pad + '<%s%s/>' % (self.tag, a))
        else:
            out.append(pad + '<%s%s>' % (self.tag, a))
            for k in self.kids:
                k.lines(ind + 3, out, ctx)
            out.append(pad + '</%s>' % self.tag)
        return out


def _num(v):
    return ('%.4f' % v).rstrip('0').rstrip('.')


def _mm(v):
    return None if v is None else (v if isinstance(v, str) else _num(v) + 'mm')


def _pos(v):
    """x/y: Designer bỏ thuộc tính khi = 0."""
    return None if v in (None, 0) else _mm(v)


def _font(font=None, size=None, bold=False):
    return E('font', {'typeface': font, 'size': None if size is None else (size if isinstance(size, str) else _num(size) + 'pt'),
                      'weight': 'bold' if bold else None})


def _para(align=None, valign=None):
    a = {'hAlign': None if align in (None, 'left') else align, 'vAlign': None if valign in (None, 'top') else valign}
    return E('para', a) if any(v is not None for v in a.values()) else None


def _margin(m):
    m = _mm(m)
    return E('margin', {'bottomInset': m, 'leftInset': m, 'rightInset': m, 'topInset': m})


def _border(sides=None, fill=None, thickness=0.254):
    """sides: None = không kẻ; True/'TRBL' = 4 cạnh; chuỗi con của 'TRBL' = chỉ các cạnh đó. fill = (r, g, b)."""
    sides = 'TRBL' if sides is True else (sides or '').upper()
    if not sides and not fill:
        return None
    th, kids = _mm(thickness), []
    if sides == 'TRBL':
        kids += [E('edge', {'thickness': th}), E('corner', {'thickness': th})]
    elif sides:
        kids += [E('edge', {'thickness': th} if s in sides else {'presence': 'hidden'}) for s in 'TRBL']
        kids += [E('corner', {'thickness': th} if (a in sides or b in sides) else {'presence': 'hidden'})
                 for a, b in (('T', 'L'), ('T', 'R'), ('B', 'R'), ('B', 'L'))]
    else:
        kids.append(E('edge', {'presence': 'hidden'}))
    if fill:
        kids.append(E('fill', kids=[E('color', {'value': '%d,%d,%d' % tuple(fill)})]))
    return E('border', kids=kids)


# Rich text: '<b>..</b>' đậm, '<i>' nghiêng, '<bi>' đậm nghiêng, '<n>' thường, '<ni>' thường nghiêng; '\n' = xuống dòng.
_SPAN = {'b': 'font-weight:bold', 'i': 'font-style:italic', 'bi': 'font-weight:bold;font-style:italic',
         'n': 'font-weight:normal;font-style:normal', 'ni': 'font-weight:normal;font-style:italic'}
_MARK = re.compile(r'<(bi|ni|b|i|n)>(.*?)</\1>', re.S)


def _rich(value):
    ps = []
    for line in value.split('\n'):
        out, pos = [], 0
        for m in _MARK.finditer(line):
            out += [_esc(line[pos:m.start()]), '<span style="%s">%s</span>' % (_SPAN[m.group(1)], _esc(m.group(2)))]
            pos = m.end()
        out.append(_esc(line[pos:]))
        body = ''.join(out)
        ps.append('<p>%s</p>' % (body or '<span style="xfa-spacerun:yes"> </span>'))
    return '<body xmlns="http://www.w3.org/1999/xhtml" xmlns:xfa="http://www.xfa.org/schema/xfa-data/1.0/">%s</body>' % ''.join(ps)


def _rid():
    return str(uuid.uuid4()).upper()


def _value(value):
    if not value:
        return None
    if '\n' in value or _MARK.search(value):
        return E('value', kids=[E('exData', {'contentType': 'text/html', 'xliff:rid': _rid()}, raw=_rich(value))])
    return E('value', kids=[E('text', {'xliff:rid': _rid()}, text=value)])


def _ref(ref):
    """'MATNR' -> '$.MATNR' (tương đối với subform đang bind); chuỗi bắt đầu bằng '$' giữ nguyên."""
    return ref if ref.startswith('$') else '$.' + ref


def _refname(ref):
    return re.sub(r'\[[^\]]*\]', '', ref).split('.')[-1]


# ---------- trang ----------
_PAPER = {'A3': (297, 420, 'a3'), 'A4': (210, 297, 'a4'), 'A5': (148, 210, 'a5'), 'LETTER': (215.9, 279.4, 'letter')}


def page(size='A4', landscape=False, margin=10, kids=(), name='Page1'):
    """Master page. size: 'A4'/'A5'/'A3'/'LETTER' hoặc (rộng, cao) mm cho tem/khổ riêng (stock custom,
    short = rộng, long = cao như 2 tem mẫu). margin: số (mm) hoặc (trên, phải, dưới, trái).
    kids: đối tượng in lặp mọi trang (text/image tĩnh)."""
    if isinstance(size, str):
        sw, sh, stock = _PAPER[size.upper()]
        medium = {'short': _mm(sw), 'long': _mm(sh), 'stock': stock, 'orientation': 'landscape' if landscape else None}
        pw, ph = (sh, sw) if landscape else (sw, sh)
    else:
        pw, ph = size
        medium = {'short': _mm(pw), 'long': _mm(ph), 'stock': 'custom'}
    t, r, b, l = (margin,) * 4 if isinstance(margin, (int, float)) else margin
    area = E('contentArea', {'x': _mm(l) if l else None, 'y': _mm(t) if t else None, 'w': _mm(pw - l - r), 'h': _mm(ph - t - b)})
    return E('pageArea', {'id': name, 'name': name}, [area, E('medium', medium)] + list(kids))


# ---------- đối tượng ----------
def text(value, x=None, y=None, w=None, h=None, size=None, bold=False, font=None, align=None, valign=None,
         border=None, fill=None, margin=0.5, name='Text1'):
    """Text tĩnh (draw). value có '\n' hoặc thẻ <b>/<i>/<bi>/<n>/<ni> -> rich text (exData)."""
    return E('draw', {'name': name, 'x': _pos(x), 'y': _pos(y), 'w': _mm(w), 'h': _mm(h)},
             [E('ui', kids=[E('textEdit')]), _value(value), _font(font, size, bold), _margin(margin),
              _para(align, valign), _border(border, fill)])


def field(ref, x=None, y=None, w=None, h=None, caption=None, caption_w=None, caption_bold=None, size=None, bold=False,
          font=None, align=None, valign='middle', multiline=False, grow=False, border=None, fill=None, margin=1, name=None):
    """Text field bind dữ liệu. ref: 'FIELD' (tương đối) hoặc '$.BANG.DATA[0].FIELD' (tuyệt đối).
    caption: nhãn bên trái (rich text được), caption_w: độ rộng nhãn (mm).
    grow=True: cao theo nội dung (minH = h) - CHƯA có mẫu."""
    bind = _ref(ref)
    cap = None
    if caption is not None:
        cap = E('caption', {'reserve': _mm(caption_w)},
                [_para(None, valign), _value(caption), _font(font, size, bold if caption_bold is None else caption_bold)])
    edit = E('textEdit', {'multiLine': '1' if multiline or grow else None},
             [E('border', {'presence': 'hidden'}), E('margin')])
    return E('field', {'name': name or _refname(bind), 'x': _pos(x), 'y': _pos(y), 'w': _mm(w),
                       'h': None if grow else _mm(h), 'minH': _mm(h) if grow else None},
             [E('ui', kids=[edit]), _font(font, size, bold), _margin(margin), _para(align, valign), cap,
              E('bind', {'match': 'dataRef', 'ref': bind}), _border(border, fill)])


def qrcode(ref, data_length, x=None, y=None, size=30, ecc=3, module='0.03in', name=None):
    """QR code. data_length = độ dài dữ liệu QR lớn nhất thực tế (mẫu: 26). ecc 0-3 (mẫu: 3).
    module: cỡ 1 ô (mẫu: 0.03in, 0.041in) - QR to theo dữ liệu, ô vuông `size` mm phải đủ chỗ."""
    bind = _ref(ref)
    return E('field', {'access': 'readOnly', 'name': name or _refname(bind), 'x': _pos(x), 'y': _pos(y),
                       'w': _mm(size), 'h': _mm(size)},
             [E('ui', kids=[E('barcode', {'dataLength': str(data_length), 'errorCorrectionLevel': str(ecc),
                                          'moduleHeight': module, 'moduleWidth': module, 'type': 'QRCode'})]),
              E('bind', {'match': 'dataRef', 'ref': bind})])


_MIME = {'.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.bmp': 'image/bmp', '.gif': 'image/gif'}


def image(path, x=None, y=None, w=None, h=None, aspect='fit', name='Image1'):
    """Ảnh tĩnh nhúng thẳng vào layout (logo cố định, nền). aspect: fit/none/actual/width/height."""
    data = open(path, 'rb').read()
    b64 = base64.encodebytes(data).decode('ascii').rstrip('\n').replace('\n', '\r\n')
    return E('draw', {'name': name, 'x': _pos(x), 'y': _pos(y), 'w': _mm(w), 'h': _mm(h)},
             [E('value', kids=[E('image', {'aspect': aspect, 'contentType': _MIME[os.path.splitext(path)[1].lower()]},
                                 text=b64)]),
              E('ui', kids=[E('imageEdit')])])


def image_field(ref, x=None, y=None, w=None, h=None, name=None):
    """Ảnh động bind vào node graphic: '$.GRAPHIC' ngoài khung lặp, '$record.GRAPHIC' trong repeat()
    - CHƯA có mẫu dùng thật trên layout."""
    bind = _ref(ref)
    return E('field', {'name': name or _refname(bind), 'x': _pos(x), 'y': _pos(y), 'w': _mm(w), 'h': _mm(h)},
             [E('ui', kids=[E('imageEdit')]), E('bind', {'match': 'dataRef', 'ref': bind})])


# ---------- khung chứa ----------
def block(kids, x=None, y=None, w=None, h=None, name='Subform1', border=None, fill=None):
    """Subform vị trí cố định (con đặt theo x/y), không bind."""
    return E('subform', {'name': name, 'x': _pos(x), 'y': _pos(y), 'w': _mm(w), 'h': _mm(h)},
             [E('bind', {'match': 'none'})] + list(kids) + [_border(border, fill)])


def flow(kids, w=None, name='Subform1', direction='tb', border=None, fill=None):
    """Subform chảy: 'tb' trên->dưới (tự sang trang), 'lr-tb' trái->phải rồi xuống dòng. Không bind."""
    return E('subform', {'layout': direction, 'name': name, 'w': _mm(w)},
             [E('bind', {'match': 'none'})] + list(kids) + [E('keep', {'intact': 'none'}), _border(border, fill)])


def repeat(table, kids, w=None, h=None, name=None, flowed=True, ref=None):
    """Lặp 1 lần/dòng của `table` (bind $.<table>.DATA[*]); con bên trong dùng ref tương đối 'FIELD'.
    Mỗi dòng 1 trang/tem: đặt 1 block có h = chiều cao contentArea (mẫu tem)."""
    return E('subform', {'layout': 'tb' if flowed else None, 'name': name or table, 'w': _mm(w), 'h': _mm(h)},
             [E('bind', {'match': 'dataRef', 'ref': ref or '$.%s.DATA[*]' % table})] + list(kids)
             + [E('occur', {'max': '-1'})])


def table(data, columns, x=None, y=None, name='Table1', row_h=6, header_h=None, size=None, header_size=None,
          font=None, header_bold=True, header_fill=None, grid=True, grow=False, footer=None, footer_bold=True,
          ref=None):
    """Bảng: 1 dòng tiêu đề + 1 dòng lặp theo `data` (bind $.<data>.DATA[*]) + dòng cuối tuỳ chọn.
    columns: [(rộng_mm, 'Tiêu đề cột', 'FIELD' hoặc None, align)].
    footer: list cùng số cột, mỗi ô None | 'text tĩnh' | '$.ref' | (text hoặc '$.ref', align).
    Đặt bảng trong khung chảy (thẳng dưới gốc 'data', flow(), repeat()) để tự sang trang, không đặt trong block()."""
    edge = 'TRBL' if grid else None
    cells_h = [text(c[1], h=header_h or row_h, size=header_size or size, bold=header_bold, font=font, align='center',
                    valign='middle', border=edge, fill=header_fill, name='Cell%d' % (i + 1)) for i, c in enumerate(columns)]
    rows = [E('subform', {'layout': 'row', 'name': 'HeaderRow'},
              [E('assist', {'role': 'TH'})] + cells_h + [E('bind', {'match': 'none'})])]
    cells = []
    for i, c in enumerate(columns):
        fld, al = (c[2] if len(c) > 2 else None), (c[3] if len(c) > 3 else None)
        cells.append(field(fld, h=row_h, size=size, font=font, align=al, multiline=grow, grow=grow, border=edge,
                           margin=0.5) if fld else text(None, h=row_h, size=size, font=font, border=edge, name='Cell%d' % (i + 1)))
    rows.append(E('subform', {'layout': 'row', 'name': 'Row1'},
                  [E('assist', {'role': 'TR'})] + cells
                  + [E('bind', {'match': 'dataRef', 'ref': ref or '$.%s.DATA[*]' % data}), E('occur', {'max': '-1'})]))
    if footer:
        cells_f = []
        for i, item in enumerate(footer):
            val, al = item if isinstance(item, tuple) else (item, None)
            if val and val.startswith('$'):
                cells_f.append(field(val, h=row_h, size=size, bold=footer_bold, font=font, align=al, border=edge, margin=0.5))
            else:
                cells_f.append(text(val, h=row_h, size=size, bold=footer_bold, font=font, align=al, valign='middle',
                                    border=edge, name='Cell%d' % (i + 1)))
        rows.append(E('subform', {'layout': 'row', 'name': 'FooterRow'},
                      [E('assist', {'role': 'TR'})] + cells_f + [E('bind', {'match': 'none'})]))
    return E('subform', {'columnWidths': ' '.join(_mm(c[0]) for c in columns), 'layout': 'table', 'name': name,
                         'x': _pos(x), 'y': _pos(y)},
             rows + [E('keep', {'intact': 'none'}), E('bind', {'match': 'none'})])


# ---------- ráp file XDP ----------
def _stamp(now=None):
    now = now or datetime.datetime.now(datetime.timezone.utc)
    return now.strftime('%Y-%m-%dT%H:%M:%SZ'), str(uuid.uuid4())


def _cache_info(ts, uid):
    """CL_FP_LAYOUT-CACHE_INFO khớp timeStamp/uuid của thẻ xdp:xdp (như cả 3 mẫu)."""
    return '%s$%s$0$en_US$v1.0$?' % (ts, uid)


def _template(pages, content, font):
    pages = [pages] if isinstance(pages, E) else list(pages)
    root = E('subform', {'layout': 'tb', 'locale': 'en_US', 'name': 'data', 'restoreState': 'auto'},
             [E('pageSet', kids=pages)] + list(content)
             + [E('proto'), E('desc', kids=[E('text', {'name': 'version'}, text=_DESIGNER_VER)])])
    out = ['<template xmlns:xliff="urn:oasis:names:tc:xliff:document:1.1" xmlns="%s">' % _TPL_NS,
           '   <?formServer defaultPDFRenderFormat acrobat10.0dynamic?>']
    root.lines(3, out, {'font': font})
    out += ['   <?templateDesigner %s?>' % p.replace('{font}', font) for p in _TPL_PIS]
    out += ['   <?acrobat JavaScript strictScoping?>', '   <?templateDesigner FormTargetVersion 33?>',
            '   <?templateDesigner Rulers horizontal:1, vertical:1, guidelines:1, crosshairs:0?>', '</template>']
    return out


def _config(base_url=''):
    return (['<config xmlns="http://www.xfa.org/schema/xci/3.0/">', '   <agent name="designer">', '      <!--  [0..n]  -->',
             '      <destination>pdf</destination>', '      <pdf>', '         <!--  [0..n]  -->', '         <fontInfo/>',
             '      </pdf>', '      <common>', '         <template>',
             '            ' + ('<base>%s</base>' % _esc(base_url) if base_url else '<base/>'),
             '         </template>', '      </common>', '   </agent>', '   <present>', '      <!--  [0..n]  -->',
             '      <pdf>', '         <!--  [0..n]  -->', '         <version>1.7</version>',
             '         <adobeExtensionLevel>8</adobeExtensionLevel>', '      </pdf>', '      <common>', '         <data>',
             '            <xsl>', '               <uri/>', '            </xsl>', '            <outputXSL>',
             '               <uri/>', '            </outputXSL>', '         </data>', '      </common>', '      <xdp>',
             '         <packets>*</packets>', '      </xdp>', '   </present>', '</config>'])


def _connection(form):
    return ['<connectionSet xmlns="http://www.xfa.org/schema/xfa-connection-set/2.8/">',
            '   <xsdConnection dataDescription="data" name="%s">' % form, '      <uri/>',
            '      <rootElement>data</rootElement>', '   </xsdConnection>', '</connectionSet>']


def _datasets(dd):
    out = ['<xfa:datasets xmlns:xfa="http://www.xfa.org/schema/xfa-data/1.0/">', '   <xfa:data xfa:dataNode="dataGroup"/>',
           '   <dd:dataDescription xmlns:dd="http://ns.adobe.com/data-description/" dd:name="data">']
    dd.lines(6, out, {})
    return out + ['   </dd:dataDescription>', '</xfa:datasets>']


def _localeset():
    """Packet localeSet en_US - giống hệt cả 3 mẫu (Designer tự nhúng)."""
    out = ['<localeSet xmlns="http://www.xfa.org/schema/xfa-locale-set/2.7/">',
           '   <locale desc="English (United States)" name="en_US">', '      <calendarSymbols name="gregorian">']

    def group(tag, item, values, abbr=False, ind=9):
        out.append(' ' * ind + '<%s%s>' % (tag, ' abbr="1"' if abbr else ''))
        out.extend(' ' * (ind + 3) + '<%s>%s</%s>' % (item, v, item) for v in values)
        out.append(' ' * ind + '</%s>' % tag)

    def named(tag, item, pairs):
        out.append('      <%s>' % tag)
        out.extend('         <%s name="%s">%s</%s>' % (item, k, _esc(v), item) for k, v in pairs)
        out.append('      </%s>' % tag)

    months = 'January February March April May June July August September October November December'.split()
    days = 'Sunday Monday Tuesday Wednesday Thursday Friday Saturday'.split()
    group('monthNames', 'month', months)
    group('monthNames', 'month', [m[:3] for m in months], True)
    group('dayNames', 'day', days)
    group('dayNames', 'day', [d[:3] for d in days], True)
    group('meridiemNames', 'meridiem', ['AM', 'PM'])
    group('eraNames', 'era', ['BC', 'AD'])
    out.append('      </calendarSymbols>')
    named('datePatterns', 'datePattern', [('full', 'EEEE, MMMM D, YYYY'), ('long', 'MMMM D, YYYY'),
                                          ('med', 'MMM D, YYYY'), ('short', 'M/D/YY')])
    named('timePatterns', 'timePattern', [('full', 'h:MM:SS A Z'), ('long', 'h:MM:SS A Z'), ('med', 'h:MM:SS A'),
                                          ('short', 'h:MM A')])
    out.append('      <dateTimeSymbols>GyMdkHmsSEDFwWahKzZ</dateTimeSymbols>')
    named('numberPatterns', 'numberPattern', [('numeric', 'z,zz9.zzz'), ('currency', '$z,zz9.99|($z,zz9.99)'),
                                              ('percent', 'z,zz9%')])
    named('numberSymbols', 'numberSymbol', [('decimal', '.'), ('grouping', ','), ('percent', '%'), ('minus', '-'),
                                            ('zero', '0')])
    named('currencySymbols', 'currencySymbol', [('symbol', '$'), ('isoname', 'USD'), ('decimal', '.')])
    out.append('      <typefaces>')
    out.extend('         <typeface name="%s"/>' % t for t in (
        'Myriad Pro', 'Minion Pro', 'Courier Std', 'Adobe Pi Std', 'Adobe Hebrew', 'Adobe Arabic', 'Adobe Thai',
        'Kozuka Gothic Pro-VI M', 'Kozuka Mincho Pro-VI R', 'Adobe Ming Std L', 'Adobe Song Std L',
        'Adobe Myungjo Std M', 'Adobe Devanagari'))
    return out + ['      </typefaces>', '   </locale>', '</localeSet>']


def _xmp(ts, uid):
    return ['<x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="Adobe XMP Core 5.4-c005 78.150055, 2013/08/07-22:58:47        ">',
            '   <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">',
            '      <rdf:Description xmlns:xmp="http://ns.adobe.com/xap/1.0/" xmlns:pdf="http://ns.adobe.com/pdf/1.3/" '
            'xmlns:xmpMM="http://ns.adobe.com/xap/1.0/mm/" xmlns:desc="http://ns.adobe.com/xfa/promoted-desc/" rdf:about="">',
            '         <xmp:MetadataDate>%s</xmp:MetadataDate>' % ts,
            '         <xmp:CreatorTool>Adobe LiveCycle Designer 11.0</xmp:CreatorTool>',
            '         <pdf:Producer>Adobe LiveCycle Designer 11.0</pdf:Producer>',
            '         <xmpMM:DocumentID>uuid:%s</xmpMM:DocumentID>' % uid,
            '         <desc:version rdf:parseType="Resource">', '            <rdf:value>%s</rdf:value>' % _DESIGNER_VER,
            '            <desc:ref>/template/subform[1]</desc:ref>', '         </desc:version>', '      </rdf:Description>',
            '   </rdf:RDF>', '</x:xmpmeta></xdp:xdp>']


def build_xdp(form, pages, content, dd, font='Arial', base_url='', now=None):
    """Ráp file XDP đầy đủ (template, config, connectionSet, datasets, localeSet, xmpmeta).
    Trả (bytes UTF-8, CACHE_INFO). Dòng 1 kết thúc LF, các dòng sau CRLF - như Designer ghi."""
    ts, uid = _stamp(now)
    lines = ([_GENERATOR + '<xdp:xdp xmlns:xdp="http://ns.adobe.com/xdp/" timeStamp="%s" uuid="%s">' % (ts, uid)]
             + _template(pages, content, font) + _config(base_url) + _connection(form) + _datasets(dd)
             + _localeset() + _xmp(ts, uid))
    return ('<?xml version="1.0" encoding="utf-8"?>\n' + '\r\n'.join(lines)).encode('utf-8'), _cache_info(ts, uid)


def inject_layout(src, dst, pages, content, font='Arial', now=None):
    """Thay packet <template> trong 1 file SFPF tải từ SAP (interface + context làm bằng SFP, đã mở tab
    Layout 1 lần rồi Save), giữ nguyên context, dataDescription, config của SAP. Cập nhật timeStamp/uuid
    của XDP và CACHE_INFO cho khớp nhau."""
    raw = open(src, 'rb').read().decode('utf-8')
    m = re.search(r'<FPLAYOUTT>.*?<LAYOUT>([^<]*)</LAYOUT>', raw, re.S)
    if not m or not m.group(1).strip():
        raise ValueError('%s chưa có layout: mở tab Layout trong SFP 1 lần, Save, rồi Download lại' % src)
    xdp = base64.b64decode(m.group(1)).decode('utf-8')
    ts, uid = _stamp(now)
    tpl = '\r\n'.join(_template(pages, content, font))
    xdp, n = re.subn(r'<template\b[^>]*xfa-template[^>]*>.*?</template>', lambda _: tpl, xdp, count=1, flags=re.S)
    if n != 1:
        raise ValueError('Không tìm thấy packet <template> trong layout của %s' % src)
    for pat, rep in ((r'(<xdp:xdp\b[^>]*?timeStamp=")[^"]*', r'\g<1>' + ts), (r'(<xdp:xdp\b[^>]*?uuid=")[^"]*', r'\g<1>' + uid),
                     (r'(<xmp:MetadataDate>)[^<]*', r'\g<1>' + ts), (r'(<xmpMM:DocumentID>uuid:)[^<]*', r'\g<1>' + uid)):
        xdp = re.sub(pat, rep, xdp, count=1)
    out = raw[:m.start(1)] + _b64(xdp.encode('utf-8')) + raw[m.end(1):]
    out = re.sub(r'<CACHE_INFO>[^<]*</CACHE_INFO>', '<CACHE_INFO>%s</CACHE_INFO>' % _cache_info(ts, uid), out, count=1)
    return _write(dst, out)


# ======================================================================
# 3. Kiểm tra layout (dùng chung cho af_validate.py / af_inspect.py)
# ======================================================================
_XDP_DATA = '{http://www.xfa.org/schema/xfa-data/1.0/}'
_DD = '{http://ns.adobe.com/data-description/}'
_WALK = ('subform', 'subformSet', 'field', 'draw', 'pageSet', 'pageArea', 'area', 'exclGroup')

# Thẻ/thuộc tính template đã thấy trong 3 form mẫu - ngoài danh sách này = chưa có mẫu, cần xem trên SAP.
SEEN_VOCAB = {
    'assist': {'role'}, 'barcode': {'dataLength', 'errorCorrectionLevel', 'moduleHeight', 'moduleWidth', 'type'},
    'bind': {'match', 'ref'}, 'border': {'presence'}, 'caption': {'reserve'}, 'color': {'value'},
    'contentArea': {'h', 'w', 'x', 'y'}, 'corner': {'presence', 'thickness'}, 'desc': set(),
    'draw': {'h', 'name', 'w', 'x', 'y'}, 'edge': {'presence', 'thickness'}, 'exData': {'contentType', 'rid'},
    'field': {'access', 'h', 'name', 'w', 'x', 'y'}, 'fill': set(),
    'font': {'baselineShift', 'size', 'typeface', 'weight'}, 'image': {'aspect', 'contentType'}, 'imageEdit': set(),
    'keep': {'intact'}, 'margin': {'bottomInset', 'leftInset', 'rightInset', 'topInset'},
    'medium': {'long', 'short', 'stock'}, 'occur': {'max'}, 'pageArea': {'id', 'name'}, 'pageSet': set(),
    'para': {'hAlign', 'marginLeft', 'marginRight', 'spaceAbove', 'spaceBelow', 'textIndent', 'vAlign'},
    'proto': set(), 'subform': {'columnWidths', 'h', 'layout', 'locale', 'name', 'restoreState', 'w', 'x', 'y'},
    'subformSet': {'name'}, 'text': {'maxChars', 'name', 'rid'}, 'textEdit': {'multiLine'}, 'ui': set(), 'value': set()}
SEEN_FONTS = {'Arial', 'Times New Roman'}


class DNode(object):
    """Node của dd:dataDescription (= cấu trúc XML dữ liệu SAP gửi sang ADS)."""

    def __init__(self, name, repeat=False):
        self.name, self.repeat, self.kids, self.used = name, repeat, [], 0

    def leaves(self, path=''):
        p = path + '.' + self.name if path else self.name
        if not self.kids:
            yield p, self
        for k in self.kids:
            for x in k.leaves(p):
                yield x


def to_mm(v):
    m = re.match(r'^\s*(-?[\d.]+)\s*(mm|cm|in|pt)?\s*$', v or '')
    if not m:
        return None
    return float(m.group(1)) * {'mm': 1, 'cm': 10, 'in': 25.4, 'pt': 25.4 / 72, None: 25.4}[m.group(2)]


def parse_xdp(xdp):
    """Trả (root, template, cây dữ liệu DNode 'data' hoặc None)."""
    root = ET.fromstring(xdp)
    tpl = next((c for c in root if _local(c.tag) == 'template' and 'xfa-template' in c.tag), None)
    ds = root.find(_XDP_DATA + 'datasets')
    dd = ds.find(_DD + 'dataDescription') if ds is not None else None

    def conv(e):
        n = DNode(_local(e.tag), e.get(_DD + 'maxOccur') == '-1')
        n.kids = [conv(k) for k in e]
        return n
    return root, tpl, (conv(dd[0]) if dd is not None and len(dd) else None)


def tns(tpl):
    return tpl.tag[:tpl.tag.index('}') + 1]


def check_bindings(tpl, droot):
    """Duyệt template, phân giải mọi bind. Trả (lỗi, [(đường dẫn layout, ref, DNode|None)])."""
    T, errs, binds = tns(tpl), [], []
    top = DNode('#'); top.kids = [droot]

    def resolve(scope, ref):
        ref = ref.strip()
        if ref.startswith('$record'):
            cur, rest = droot, ref[len('$record'):]
        elif ref.startswith('$data'):
            cur, rest = top, ref[len('$data'):]
        elif ref.startswith('$'):
            cur, rest = scope, ref[1:]
        else:
            cur, rest = scope, ref
        for seg in [s for s in rest.split('.') if s]:
            nm = re.sub(r'\[[^\]]*\]$', '', seg)
            cur = next((k for k in cur.kids if k.name == nm), None)
            if cur is None:
                return None
        return cur

    def walk(el, scope, path):
        tag, name = _local(el.tag), el.get('name')
        here = '%s/%s' % (path, name or tag)
        if tag in ('field', 'subform', 'exclGroup'):
            b = el.find(T + 'bind')
            match = b.get('match', 'once') if b is not None else 'once'
            node = None
            if match == 'dataRef':
                ref = b.get('ref', '')
                node = resolve(scope, ref)
                binds.append((here, ref, node))
                if node is None:
                    errs.append('%s: bind "%s" không trỏ tới node dữ liệu nào' % (here, ref))
                elif tag == 'field' and node.kids:
                    errs.append('%s: field bind "%s" vào nhóm, cần field lá' % (here, ref))
                elif tag == 'subform' and not node.kids:
                    errs.append('%s: subform bind "%s" vào field lá, cần nhóm/bảng' % (here, ref))
            elif match in ('once', 'global') and name:
                node = next((k for k in scope.kids if k.name == name), None)
                if node is not None:
                    binds.append((here, '(theo tên)', node))
            if node is not None:
                node.used += 1
                if tag != 'field':
                    scope = node
        for k in el:
            if _local(k.tag) in _WALK:
                walk(k, scope, here)

    rs = tpl.find(T + 'subform')
    if rs is not None and droot is not None:
        walk(rs, top, '')
    return errs, binds


def vocab_unseen(tpl):
    """{'tag' hoặc 'tag@attr': số lần} cho thẻ/thuộc tính chưa thấy trong form mẫu."""
    res = {}

    def walk(el):
        tag = _local(el.tag)
        keys = ['<%s>' % tag] if tag not in SEEN_VOCAB else ['%s@%s' % (tag, _local(a)) for a in el.attrib
                                                             if _local(a) not in SEEN_VOCAB[tag]]
        for k in keys:
            res[k] = res.get(k, 0) + 1
        if tag != 'exData':
            for c in el:
                walk(c)
    for c in tpl:
        walk(c)
    return res


def geometry_warnings(tpl):
    """Con vượt khung subform vị trí cố định; bảng/khối rộng hơn contentArea."""
    T, warns = tns(tpl), []
    areas = [to_mm(a.get('w')) for a in tpl.iter(T + 'contentArea')]
    width = min([a for a in areas if a] or [0])

    def walk(el, path):
        tag, name = _local(el.tag), el.get('name') or _local(el.tag)
        here = '%s/%s' % (path, name)
        if tag == 'subform' and not el.get('layout') and el.get('w') and el.get('h'):
            pw, ph = to_mm(el.get('w')), to_mm(el.get('h'))
            for k in el:
                if _local(k.tag) in ('field', 'draw', 'subform') and k.get('w') and k.get('h'):
                    x, y = to_mm(k.get('x') or '0'), to_mm(k.get('y') or '0')
                    if x + to_mm(k.get('w')) > pw + 0.05 or y + to_mm(k.get('h')) > ph + 0.05:
                        warns.append('%s/%s vượt khung %s (%.1fx%.1fmm)' % (here, k.get('name'), name, pw, ph))
        if width and tag == 'subform' and el.get('columnWidths'):
            tw = sum(to_mm(c) or 0 for c in el.get('columnWidths').split())
            if tw > width + 0.05:
                warns.append('%s: tổng độ rộng cột %.1fmm > contentArea %.1fmm' % (here, tw, width))
        if width and tag == 'subform' and el.get('w') and path.count('/') <= 2 and to_mm(el.get('w')) > width + 0.05:
            warns.append('%s: rộng %.1fmm > contentArea %.1fmm' % (here, to_mm(el.get('w')), width))
        for k in el:
            if _local(k.tag) in _WALK:
                walk(k, here)
    rs = tpl.find(T + 'subform')
    if rs is not None:
        walk(rs, '')
    return warns


def fonts_used(tpl):
    return sorted({f.get('typeface') for f in tpl.iter(tns(tpl) + 'font') if f.get('typeface')})
