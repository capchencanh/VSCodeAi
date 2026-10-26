"""sfgen - sinh file XML Smart Form (SMARTFORMS -> Utilities -> Upload form).

Mọi phần tử được phát ra đúng thứ tự con như file export thật của SAP
(đối chiếu với ZMM_SF_PXKPG_DOC). Dùng:

    from sfgen import SF, ALL, NONE
    sf = SF('ZMM_SF_ABC', 'Mô tả form', devclass='ZPK_HPDQ', user='KHOALD')
    tbl = sf.table('Bang', 28.70, linetypes, [sf.event('Header', 'H', [...]), ...],
                   tabname='GT_ITEM', tabheader='GS_ITEM')
    main = sf.window('MAIN', 'Main Window', 'M', [tbl], (0.5, 28.7, 0.5, 20.0), wid=1082)
    xml = sf.render(interface=[...], gdata=[...], windows=[main], orientation='L')

Xem SKILL.md / references/xml-structure.md để biết ý nghĩa từng tham số.
"""
from xml.sax.saxutils import escape as _esc
import datetime

ALL = (1, 1, 1, 1)    # viền trái, trên, phải, dưới
NONE = (0, 0, 0, 0)
# Chỉ EQ/NE đã thấy trong file export thật; toán tử khác cần lấy ICON từ 1 form thật trước khi thêm vào đây.
ICON = {'EQ': '@20\\QSelect: Equal to@', 'NE': '@21\\QSelect: Not equal to@'}

def _side(tag):
    return ('<%s><THICKNESS>0.00</THICKNESS><THICKNESSU>PT</THICKNESSU><DISTANCE>0.00</DISTANCE>'
            '<DISTANCEU>CM</DISTANCEU><COLOR><RED>000</RED><GREEN>000</GREEN><BLUE>000</BLUE>'
            '<TRANS>000</TRANS></COLOR></%s>') % (tag, tag)
_BORDER = '<BORDER>' + _side('LEFTATTR') + _side('TOPATTR') + _side('RIGHTATTR') + _side('BOTTOMATTR') + '</BORDER>'
_SEC_TAIL = ('<U_FHEIGHT>CM</U_FHEIGHT><PATTERN><PATTNUM>0000</PATTNUM><FRAME>0.00</FRAME><U_FRAME>PT</U_FRAME></PATTERN>'
             '<U_WIDTH>CM</U_WIDTH><U_LEFT>CM</U_LEFT><U_TOP>CM</U_TOP><U_SB>CM</U_SB><U_SA>CM</U_SA>')

# Tham số chuẩn SAP tự thêm vào mọi form (giữ nguyên khi sinh interface)
STANDARD_INTERFACE = [
    ('E', 'DOCUMENT_OUTPUT_INFO', 'TYPE', 'SSFCRESPD', False, True, None),
    ('E', 'JOB_OUTPUT_INFO', 'TYPE', 'SSFCRESCL', False, True, None),
    ('E', 'JOB_OUTPUT_OPTIONS', 'TYPE', 'SSFCRESOP', False, True, None),
    ('I', 'ARCHIVE_INDEX', 'TYPE', 'TOA_DARA', True, True, None),
    ('I', 'ARCHIVE_INDEX_TAB', 'TYPE', 'TSFDARA', True, True, None),
    ('I', 'ARCHIVE_PARAMETERS', 'TYPE', 'ARC_PARAMS', True, True, None),
    ('I', 'CONTROL_PARAMETERS', 'TYPE', 'SSFCTRLOP', True, True, None),
    ('I', 'MAIL_APPL_OBJ', 'TYPE', 'SWOTOBJID', True, True, None),
    ('I', 'MAIL_RECIPIENT', 'TYPE', 'SWOTOBJID', True, True, None),
    ('I', 'MAIL_SENDER', 'TYPE', 'SWOTOBJID', True, True, None),
    ('I', 'OUTPUT_OPTIONS', 'TYPE', 'SSFCOMPOP', True, True, None),
    ('I', 'USER_SETTINGS', 'TYPE', 'TDBOOL', True, True, "'X'"),
]
STANDARD_EXCEPTIONS = ['FORMATTING_ERROR', 'INTERNAL_ERROR', 'SEND_ERROR', 'USER_CANCELED']


class SF:
    def __init__(self, formname, caption, devclass, user, style='ZCORE_STYLE_REPORT', now=None):
        self.form, self.caption, self.devclass, self.user, self.style = formname, caption, devclass, user, style
        self.now = now or datetime.datetime.now()
        self._cnt = {}

    # ---------- tiện ích ----------
    def _id(self, prefix):
        self._cnt[prefix] = self._cnt.get(prefix, 0) + 1
        return '%' + prefix + str(self._cnt[prefix])

    def _tcap(self, objtype, iname, caption=None):
        s = '<T_CAPTION><item><LANGU>E</LANGU><FORMNAME>%s</FORMNAME><OBJTYPE>%s</OBJTYPE><INAME>%s</INAME>' % (
            self.form, objtype, _esc(iname))
        if caption is not None:
            s += '<CAPTION>%s</CAPTION>' % _esc(caption)
        return s + '</item></T_CAPTION>'

    @staticmethod
    def _succ(children):
        if not children:
            return '<sf:SUCC/>'
        return '<sf:SUCC>' + ''.join('<sf:item>%s</sf:item>' % c for c in children) + '</sf:SUCC>'

    def _outattr(self, linetype=None, protect=False):
        n = self._id('OUTATTRIB')
        s = '<sf:OUTATTR><sf:OUTATTR><NAME><INAME>%s</INAME></NAME>' % n
        if linetype:
            s += '<T_LINETYPE>%s</T_LINETYPE>' % linetype
        if protect:
            s += '<PROTECT>X</PROTECT>'
        s += ('<U_WFRAME>PT</U_WFRAME><U_WBOXV>CM</U_WBOXV><U_WBOXH>CM</U_WBOXH><U_WLEFT>CM</U_WLEFT>'
              '<U_WWIDTH>CM</U_WWIDTH><U_WTOP>CM</U_WTOP><U_WHEIGHT>CM</U_WHEIGHT>')
        return s + _BORDER + self._tcap('OA', n) + '</sf:OUTATTR></sf:OUTATTR>'

    def _win_outattr(self, left, width, top, height, caption=None):
        n = self._id('OUTATTRIB')
        s = '<sf:OUTATTR><sf:OUTATTR><NAME><INAME>%s</INAME></NAME>' % n
        if caption:
            s += '<CAPTION>%s</CAPTION>' % _esc(caption)
        s += ('<U_WFRAME>PT</U_WFRAME><U_WBOXV>CM</U_WBOXV><U_WBOXH>CM</U_WBOXH>'
              '<WLEFT>%.2f</WLEFT><U_WLEFT>CM</U_WLEFT><WWIDTH>%.2f</WWIDTH><U_WWIDTH>CM</U_WWIDTH>'
              '<WTOP>%.2f</WTOP><U_WTOP>CM</U_WTOP><WHEIGHT>%.2f</WHEIGHT><U_WHEIGHT>CM</U_WHEIGHT>') % (left, width, top, height)
        return s + _BORDER + self._tcap('OA', n) + '</sf:OUTATTR></sf:OUTATTR>'

    # ---------- điều kiện ----------
    def cond(self, items=None, ocond=None):
        """items: [(COP, OP1, OP2)] nối bằng AND; ocond: ['FPAGE'|'FOOTER'|'PAGEBREAK'|'HEADER']."""
        n = self._id('CONDITION')
        cap = 'New Alternative ' + n[len('%CONDITION'):]
        s = '<sf:COND><sf:CONDITION><NAME><INAME>%s</INAME></NAME><CAPTION>%s</CAPTION>' % (n, cap)
        if items:
            s += '<COND>'
            for i, (cop, op1, op2) in enumerate(items):
                s += ('<item>' + ('<LOP>AND</LOP>' if i else '') +
                      '<COP>%s</COP><OP1>%s</OP1><OP2>%s</OP2><ICON>%s</ICON></item>') % (
                    cop, _esc(op1), _esc(op2), _esc(ICON[cop]))
            s += '</COND>'
        if ocond:
            s += '<OCOND>' + ''.join('<%s>X</%s>' % (f, f) for f in ocond) + '</OCOND>'
        return s + self._tcap('CD', n, cap) + '</sf:CONDITION></sf:COND>'

    # ---------- node ----------
    def _section(self, prefix, caption, secttype, children, linetype=None, cnd=None, oa=True, protect=False):
        n = self._id(prefix)
        s = ('<sf:NODE><NODETYPE>SE</NODETYPE><sf:OBJ><sf:SECTION><NAME><INAME>%s</INAME></NAME>'
             '<CAPTION>%s</CAPTION><SECTTYPE>%s</SECTTYPE>') % (n, _esc(caption), secttype)
        s += _SEC_TAIL + self._tcap('SE', n, caption) + '</sf:SECTION></sf:OBJ>'
        if oa:
            s += self._outattr(linetype, protect)
        if cnd:
            s += cnd
        return s + self._succ(children) + '</sf:NODE>'

    def folder(self, caption, children, cnd=None, protect=False):
        return self._section('FOLDER', caption, 'F', children, cnd=cnd, oa=protect, protect=protect)

    def row(self, caption, linetype, cells, cnd=None):
        return self._section('ROW', caption, 'R', cells, linetype=linetype, cnd=cnd)

    def cell(self, caption, children):
        return self._section('CELL', caption, 'E', children)

    def text(self, lines, cnd=None, caption=None):
        """lines: [(TDFORMAT, TDLINE)]; TDLINE None = dòng trống."""
        n = self._id('TEXT')
        caption = caption or 'New Text ' + n[len('%TEXT'):]
        s = ('<sf:NODE><NODETYPE>TI</NODETYPE><sf:OBJ><sf:TEXT><NAME><INAME>%s</INAME></NAME><CAPTION>%s</CAPTION>'
             '<NOLANGUAGE>X</NOLANGUAGE><APPMODE>P</APPMODE><TEXT>') % (n, _esc(caption))
        for fmt, line in lines:
            s += '<item><TDFORMAT>%s</TDFORMAT>' % fmt + ('<TDLINE>%s</TDLINE>' % _esc(line) if line else '') + '</item>'
        s += ('</TEXT><STYLE_NAME>%s</STYLE_NAME><TEXT_AREA><ENABLED>F</ENABLED><NCOLS>0</NCOLS>'
              '<NROWS>0</NROWS></TEXT_AREA>') % self.style
        s += self._tcap('TI', n, caption) + '</sf:TEXT></sf:OBJ>'
        if cnd:
            s += cnd
        return s + '<sf:SUCC/></sf:NODE>'

    def code(self, caption, inputs, outputs, lines):
        n = self._id('CODE')
        s = ('<sf:NODE><NODETYPE>CO</NODETYPE><sf:OBJ><sf:CODE><NAME><INAME>%s</INAME></NAME>'
             '<CAPTION>%s</CAPTION><PLIST>') % (n, _esc(caption))
        s += ''.join('<item><OPD>%s</OPD><OUTIN>I</OUTIN></item>' % p for p in inputs)
        s += ''.join('<item><OPD>%s</OPD><OUTIN>O</OUTIN></item>' % p for p in outputs)
        s += '</PLIST><CODE>' + ''.join(('<item>%s</item>' % _esc(l)) if l else '<item/>' for l in lines) + '</CODE>'
        return s + self._tcap('CO', n, caption) + '</sf:CODE></sf:OBJ><sf:SUCC/></sf:NODE>'

    def event(self, caption, evtype, children):
        """evtype: H = Header, B = Main Area, F = Footer."""
        n = self._id('EVENT')
        s = ('<sf:NODE><NODETYPE>EV</NODETYPE><sf:OBJ><sf:EVENT><NAME><INAME>%s</INAME></NAME>'
             '<CAPTION>%s</CAPTION><EVTYPE>%s</EVTYPE>') % (n, _esc(caption), evtype)
        return s + self._tcap('EV', n, caption) + '</sf:EVENT></sf:OBJ>' + self._succ(children) + '</sf:NODE>'

    @staticmethod
    def _cells_xml(linetypes):
        s = ''
        for name, cols in linetypes:
            for i, (w, b) in enumerate(cols, 1):
                def c(tag, on):
                    return '<%s><RED>000</RED><GREEN>000</GREEN><BLUE>000</BLUE>%s</%s>' % (tag, '<USED>X</USED>' if on else '', tag)
                s += ('<item><NAME>%s</NAME><COLUMNNR>%03d</COLUMNNR><CWIDTH>%.2f</CWIDTH><U_CWIDTH>CM</U_CWIDTH>'
                      '<SHADING>000</SHADING><BORDERS><item><IDX>001</IDX><INTENSITY>000</INTENSITY>'
                      '<LLEFT>%s</LLEFT><LLEFT_U>TW</LLEFT_U><LTOP>%s</LTOP><LTOP_U>TW</LTOP_U>'
                      '<LRIGHT>%s</LRIGHT><LRIGHT_U>TW</LRIGHT_U><LBOTTOM>%s</LBOTTOM><LBOTTOM_U>TW</LBOTTOM_U>'
                      '<FILLCOLOR><RED>000</RED><GREEN>000</GREEN><BLUE>000</BLUE></FILLCOLOR>%s%s%s%s</item></BORDERS></item>') % (
                    name, i, w, *[('15.00' if x else '0.00') for x in b],
                    c('CLEFT', b[0]), c('CTOP', b[1]), c('CRIGHT', b[2]), c('CBOTTOM', b[3]))
        return s

    def table(self, caption, width, linetypes, events, tabname=None, tabheader=None, cnd=None):
        """linetypes: [(TEN, [(rong_cm, (trai, tren, phai, duoi))])]; tổng rộng mỗi line type = width.
        tabname/tabheader: bảng + work area để LOOP (bỏ trống = table không lặp dữ liệu)."""
        for name, cols in linetypes:
            assert abs(sum(w for w, _ in cols) - width) < 0.005, (name, sum(w for w, _ in cols), width)
        n = self._id('TABLE')
        s = ('<sf:NODE><NODETYPE>SE</NODETYPE><sf:OBJ><sf:SECTION><NAME><INAME>%s</INAME></NAME>'
             '<CAPTION>%s</CAPTION><SECTTYPE>C</SECTTYPE>') % (n, _esc(caption))
        if tabname:
            s += '<DATATYPE>L</DATATYPE><TABNAME>%s</TABNAME>' % tabname
        s += '<TABHTYPE>I</TABHTYPE>'
        if tabheader:
            s += '<TABHEADER>%s</TABHEADER>' % tabheader
        s += ('<OTABTYPE>D</OTABTYPE><OTABHEADER>A</OTABHEADER><OTABFOOTER>A</OTABFOOTER><FHEIGHT>1.00</FHEIGHT>'
              '<U_FHEIGHT>CM</U_FHEIGHT><PATTERN><PATTNUM>0000</PATTNUM><FRAME>0.00</FRAME><U_FRAME>PT</U_FRAME></PATTERN>')
        if tabname:
            s += '<USEBORDER>X</USEBORDER>'
        s += ('<WIDTH>%.2f</WIDTH><U_WIDTH>CM</U_WIDTH><APPMODE>L</APPMODE><U_LEFT>CM</U_LEFT><U_TOP>CM</U_TOP>'
              '<U_SB>CM</U_SB><U_SA>CM</U_SA>') % width
        s += '<DYNLINES>' + ''.join('<item><NAME>%s</NAME>%s<SHADING>000</SHADING></item>' % (
            nm, '<DEFAULTVAL>X</DEFAULTVAL>' if i == 0 else '') for i, (nm, _) in enumerate(linetypes)) + '</DYNLINES>'
        s += '<CELLS>' + self._cells_xml(linetypes) + '</CELLS>' + self._tcap('SE', n, caption) + '</sf:SECTION></sf:OBJ>'
        if cnd:
            s += cnd
        return s + self._succ(events) + '</sf:NODE>'

    def graphic(self, name_expr='&GS_PARA-LOGO&', caption='LOGO', alignment='L'):
        n = self._id('GRAPHIC')
        return ('<sf:NODE><NODETYPE>GR</NODETYPE><sf:OBJ><sf:GRAPHIC><NAME><INAME>%s</INAME></NAME><CAPTION>%s</CAPTION>'
                '<RESOLUTION>0600</RESOLUTION><GTYPE>B</GTYPE><GKEYBDS><OBJECT>GRAPHICS</OBJECT><NAME>%s</NAME>'
                '<ID>BMAP</ID><BTYPE>BCOL</BTYPE></GKEYBDS><APPMODE>B</APPMODE><U_SB>CM</U_SB><U_SA>CM</U_SA><RELMODE>W</RELMODE>'
                '<ALIGNMENT>%s</ALIGNMENT><U_MARGIN>CM</U_MARGIN><BGR_EXT><MARGINH>0.00</MARGINH><U_MARGINH>CM</U_MARGINH>'
                '<MARGINV>0.00</MARGINV><U_MARGINV>CM</U_MARGINV></BGR_EXT>%s</sf:GRAPHIC></sf:OBJ><sf:SUCC/></sf:NODE>') % (
            n, _esc(caption), _esc(name_expr), alignment, self._tcap('GR', n, caption))

    def window(self, iname, caption, wtype, content, geo, wid, cnd=None, oacap=None):
        """wtype: M = Main, T = secondary. geo = (left, width, top, height) cm. wid: số ID duy nhất cho mỗi window."""
        s = ('<sf:NODE><NODETYPE>WI</NODETYPE><sf:OBJ><sf:WINDOW ID="%d "><NAME><INAME>%s</INAME></NAME>'
             '<CAPTION>%s</CAPTION><WTYPE>%s</WTYPE>') % (wid, iname, _esc(caption), wtype)
        s += self._tcap('WI', iname, caption)
        s += ('<sf:PROC_CTRL><sf:NODE ID="%d "><NODETYPE>RC</NODETYPE>%s</sf:NODE></sf:PROC_CTRL>'
              '</sf:WINDOW></sf:OBJ>') % (wid + 24, self._succ(content))
        s += self._win_outattr(*geo, caption=oacap)
        if cnd:
            s += cnd
        return s + '<sf:SUCC/></sf:NODE>'

    # ---------- ghép form ----------
    def render(self, interface, gdata, windows, orientation='P', pageformat='DINA4', fcoding=True, background=False):
        """interface: [(IOTYPE, NAME, TYPING, TYPENAME)] cho tham số riêng của form
                      (IOTYPE I = import, T = tables); tham số chuẩn SAP được thêm tự động.
        gdata: [(NAME, TYPING, TYPENAME[, DEFAULTVAL])] — DEFAULTVAL viết như trên màn hình Global Data (CHAR: "' '", số: "0");
               biến gán trong code node nằm TRONG ô bảng cần DEFAULTVAL, không thì Form Builder cảnh báo "Field X has no defined value". windows: node trả về từ window(). orientation: P dọc / L ngang.
        fcoding=False: bỏ khối FCODING (form mẫu ZWM_SF_BCTKSP không có). background=True: thêm sf:BACKGROUND rỗng
        vào page (form mẫu ZWM_SF_BCTKSP có). Tham số riêng I/T không đặt BYVALUE (truyền byvalue=False)."""
        def item(iotype, name, typing=None, typename=None, optional=False, byvalue=False, default=None, standard=False):
            s = '<item><IOTYPE>%s</IOTYPE><NAME>%s</NAME>' % (iotype, name)
            if typing:
                s += '<TYPING>%s</TYPING><TYPENAME>%s</TYPENAME>' % (typing, typename)
            if optional:
                s += '<OPTIONAL>X</OPTIONAL>'
            if byvalue:
                s += '<BYVALUE>X</BYVALUE>'
            if default:
                s += '<DEFAULTVAL>%s</DEFAULTVAL>' % _esc(default)
            if standard:
                s += '<STANDARD>X</STANDARD>'
            return s + '</item>'
        own = {io: [p for p in interface if p[0] == io] for io in ('E', 'I', 'T')}
        parts = [item(io, n, ty, tn, opt, bv, df, True) for io, n, ty, tn, opt, bv, df in STANDARD_INTERFACE if io == 'E']
        parts += [item(*p) for p in own['E']]
        parts += [item(io, n, ty, tn, opt, bv, df, True) for io, n, ty, tn, opt, bv, df in STANDARD_INTERFACE if io == 'I']
        parts += [item(*p) for p in own['I']]
        parts += [item('X', n, standard=True) for n in STANDARD_EXCEPTIONS]
        parts += [item(*p) for p in own['T']]

        d, t = self.now.strftime('%Y-%m-%d'), self.now.strftime('%H:%M:%S')
        x = ('<?xml version="1.0" encoding="utf-8"?><sf:SMARTFORM xmlns:sf="urn:sap-com:SmartForms:2000:internal-structure" '
             'xmlns="urn:sap-com:sdixml-ifr:2000" sf:language="EN"><HEADER><FORMNAME>%s</FORMNAME><CAPTION>%s</CAPTION>'
             '<MASTERLANG>E</MASTERLANG><LANGVECTOR>*</LANGVECTOR><DEVCLASS>%s</DEVCLASS><VERSION>00001</VERSION>'
             '<FIRSTUSER>%s</FIRSTUSER><FIRSTDATE>%s</FIRSTDATE><FIRSTTIME>%s</FIRSTTIME>'
             '<LASTUSER>%s</LASTUSER><LASTDATE>%s</LASTDATE><LASTTIME>%s</LASTTIME></HEADER>') % (
            self.form, _esc(self.caption), self.devclass, self.user, d, t, self.user, d, t)
        x += '<INTERFACE>' + ''.join(parts) + '</INTERFACE>'
        x += '<GDATA>' + ''.join(
            '<item><NAME>%s</NAME><TYPING>%s</TYPING><TYPENAME>%s</TYPENAME>%s</item>' % (
                g[0], g[1], g[2], ('<DEFAULTVAL>%s</DEFAULTVAL>' % _esc(g[3])) if len(g) > 3 else '')
            for g in gdata) + '</GDATA>'
        x += '<GCODING>' + '<item/>' * 25 + '</GCODING>'
        if fcoding:
            x += '<FCODING>' + '<item/>' * 23 + '</FCODING>'
        page = ('<sf:NODE><NODETYPE>PA</NODETYPE><sf:OBJ><sf:PAGE><NAME><INAME>%PAGE1</INAME></NAME><CAPTION>New Page</CAPTION>'
                '<NEXTPAGE><INAME>%PAGE1</INAME></NEXTPAGE><NUMB_MODE>I</NUMB_MODE><NUMB_TYPE>A</NUMB_TYPE><PAGEORTN>' + orientation +
                '</PAGEORTN>' + self._tcap('PA', '%PAGE1', 'New Page') + (self._bg() if background else '') + '</sf:PAGE></sf:OBJ>' + self._succ(windows) + '</sf:NODE>')
        x += ('<sf:VARHEADER><sf:item><PAGEFORMAT>%s</PAGEFORMAT><CPI>10.00</CPI><LPI>6.00</LPI><STDSTYLE>%s</STDSTYLE>'
              '<sf:PAGETREE><sf:NODE><NODETYPE>RP</NODETYPE>%s</sf:NODE></sf:PAGETREE></sf:item></sf:VARHEADER>'
              '</sf:SMARTFORM>') % (pageformat, self.style, self._succ([page]))
        return x

    def _bg(self):
        n = self._id('GRAPHIC')
        return ('<sf:BACKGROUND><sf:GRAPHIC><NAME><INAME>%s</INAME></NAME><CAPTION>Background Picture</CAPTION><GTYPE>B</GTYPE>'
                '<GKEYBDS><BTYPE>BMON</BTYPE></GKEYBDS><APPMODE>B</APPMODE><U_SB>CM</U_SB><U_SA>CM</U_SA><RELMODE>S</RELMODE>'
                '<ALIGNMENT>L</ALIGNMENT><U_MARGIN>CM</U_MARGIN><BGR_EXT><MARGINH>0.00</MARGINH><U_MARGINH>CM</U_MARGINH>'
                '<MARGINV>0.00</MARGINV><U_MARGINV>CM</U_MARGINV></BGR_EXT>%s</sf:GRAPHIC></sf:BACKGROUND>') % (
            n, self._tcap('GR', n, 'Background Picture'))

    def write(self, path, xml):
        with open(path, 'w', encoding='utf-8', newline='') as f:
            f.write(xml)
