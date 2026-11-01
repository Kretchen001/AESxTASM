#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Modelltest fuer AES in TASM (Version 2.0.0)

Dieses Skript bildet die Rechen-PROCs aus ASM/VERS.asm und ASM/ENTS.asm Zeile
fuer Zeile in Python nach (gleiche Register-/Speicherbelegung, gleiche
Schleifen) und liest die Tabellen (S-Box, Standardschluessel, InvMixMatrix)
direkt aus ASM/SBOX.asm und ASM/config.asm. Die Ergebnisse werden gegen
unabhaengige Referenzen geprueft (AES-S-Box aus der Definition, GF(2^8)-
Multiplikation per Polynomdivision, Testvektoren zu MixColumns).

WICHTIG: Das ist KEIN Lauf in TASM/DOS-Box. Es prueft die Logik der
Assemblerroutinen, nicht ihre Uebersetzung. Aufruf:  python3 modelltest.py
"""
import os
import random
import re
import sys

BASIS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "ASM")


def lies(name):
    with open(os.path.join(BASIS, name), encoding="latin-1") as f:
        return f.read()


def tabelle(text, name, ende):
    m = re.search(r"^" + name + r"\s+DB(.*?)" + ende, text, re.S | re.M)
    body = re.sub(r";.*", "", m.group(1))
    return [int(x, 16) for x in re.findall(r"([0-9A-Fa-f]+)h", body, re.I)]


SB = lies("SBOX.asm")
S0 = tabelle(SB, "s_0", r"(?=^s_1_0)")
S1 = tabelle(SB, "s_1_0", r"\Z")
CFG = lies("config.asm")
_k = re.search(r"Rundenschluessel_0(.*?)Rundenschluessel_Expand", CFG, re.S).group(1)
STANDARDSCHLUESSEL = [int(b[:-1], 2) for b in re.findall(r"[01]{8}b", _k)]
_m = re.search(r"InvMixMatrix(.*)", CFG, re.S).group(1)
INVMIX = [int(x, 16) for x in re.findall(r"([0-9A-Fa-f]+)h", re.sub(r";.*", "", _m), re.I)][:16]
KONSTANTE = 0x5F


# ------------------------------------------------------------------ Referenzen
def ref_mul(a, b):
    """Multiplikation in GF(2^8) per Polynommultiplikation + Division durch 11B."""
    p = 0
    for i in range(8):
        if (b >> i) & 1:
            p ^= a << i
    for i in range(15, 7, -1):
        if (p >> i) & 1:
            p ^= 0x11B << (i - 8)
    return p


def ref_sbox():
    def inv(x):
        if x == 0:
            return 0
        return next(y for y in range(1, 256) if ref_mul(x, y) == 1)
    out = []
    for x in range(256):
        b = inv(x)
        r = 0
        for i in range(8):
            bit = ((b >> i) ^ (b >> ((i + 4) % 8)) ^ (b >> ((i + 5) % 8))
                   ^ (b >> ((i + 6) % 8)) ^ (b >> ((i + 7) % 8)) ^ (0x63 >> i)) & 1
            r |= bit << i
        out.append(r)
    return out


C = [[2, 3, 1, 1], [1, 2, 3, 1], [1, 1, 2, 3], [3, 1, 1, 2]]


def ref_mixcol(col):
    return [ref_mul(C[r][0], col[0]) ^ ref_mul(C[r][1], col[1]) ^ ref_mul(C[r][2], col[2])
            ^ ref_mul(C[r][3], col[3]) for r in range(4)]


# ------------------------------------------------- Nachbau der Assembler-PROCs
class Maschine:
    def __init__(self):
        self.TB = [0] * 65                 # TastaturBuffer
        self.RK0 = list(STANDARDSCHLUESSEL)  # Rundenschluessel_0
        self.RKE = [0] * 64                # Rundenschluessel_Expand
        self.Rundekonstante = 0
        self.ZW = [0] * 4                  # ShiftZwSpeicher
        self.CZW = 0                       # ShiftColumnZW
        self.CZW2 = [0] * 4                # ShiftColumnZW2

    # --- VERS.asm
    def SchluesselInitialisieren(self):
        self.Rundekonstante = KONSTANTE
        for si in range(64):
            self.RKE[si] = self.RK0[si]

    def SchluesselAnwenden(self):
        for di in range(64):
            self.TB[di] ^= self.RKE[di]

    def Schluesselexpansion(self):
        dl = self.Rundekonstante
        al = self.RKE[0]
        di = self.RKE[63]
        cl = S0[di]
        al ^= cl
        al ^= dl
        self.RKE[0] = al
        dl = ((dl << 1) | (dl >> 7)) & 0xFF          # ROL DL,1
        self.Rundekonstante = dl
        di = 1
        while di != 64:
            al = self.RKE[di - 1]
            dl = self.RKE[di]
            al ^= dl
            self.RKE[di] = al
            di += 1

    def SBOXSubstitution(self, tab=S0):
        for si in range(64):
            self.TB[si] = tab[self.TB[si]]

    def SBOXSubstitution_1(self):
        self.SBOXSubstitution(S1)

    def _shiftrow(self, schreibe):
        bx, cx, si = 4, 0, 4
        while True:
            di = 0
            cx += 1
            if cx == 5:                              # CMP CX,5 / JE Ende
                return
            while True:
                while True:                          # TastaturBufferInit
                    al = self.TB[si]
                    self.ZW[si - bx] = al
                    si += 1
                    if si == bx + 4:
                        break
                zeile = {0: 2, 1: 3, 2: 4}[di]
                schreibe(zeile, si)
                if zeile == 4:
                    si += 4
                    bx += 8
                    break
                di += 1
                bx += 4

    def ShiftRow(self):
        def w(zeile, si):
            z, tb = self.ZW, self.TB
            if zeile == 2:
                tb[si - 1], tb[si - 4], tb[si - 3], tb[si - 2] = z[0], z[1], z[2], z[3]
            elif zeile == 3:
                tb[si - 2], tb[si - 1], tb[si - 4], tb[si - 3] = z[0], z[1], z[2], z[3]
            else:
                tb[si - 3], tb[si - 2], tb[si - 1], tb[si - 4] = z[0], z[1], z[2], z[3]
        self._shiftrow(w)

    def ShiftRow_1(self):
        def w(zeile, si):
            z, tb = self.ZW, self.TB
            if zeile == 2:
                tb[si - 3], tb[si - 2], tb[si - 1], tb[si - 4] = z[0], z[1], z[2], z[3]
            elif zeile == 3:
                tb[si - 2], tb[si - 1], tb[si - 4], tb[si - 3] = z[0], z[1], z[2], z[3]
            else:
                tb[si - 1], tb[si - 4], tb[si - 3], tb[si - 2] = z[0], z[1], z[2], z[3]
        self._shiftrow(w)

    @staticmethod
    def MalZweiPROC(al):
        carry = al >> 7
        al = (al << 1) & 0xFF
        if carry:
            al ^= 0x1B
        return al

    @staticmethod
    def GFMulPROC(al, dl):
        bl, bh, al = al, dl, 0
        for _ in range(8):
            if bh & 1:
                al ^= bl
            carry = bl >> 7
            bl = (bl << 1) & 0xFF
            if carry:
                bl ^= 0x1B
            bh >>= 1
        return al

    def ShiftColumn(self):
        mz, tb = self.MalZweiPROC, self.TB
        bx, cx, di = 4, 0, 0
        while True:
            a = lambda o: tb[di + o]
            # Zeile 1: 2 3 1 1
            zw = mz(a(0))
            al = a(4); ah = al; al = mz(al); al ^= ah; al ^= zw
            ah = a(8); ah ^= al; ah ^= a(12)
            self.CZW2[0] = ah
            # Zeile 2: 1 2 3 1
            ah = a(0); al = mz(a(4)); al ^= ah; zw = al
            al = a(8); ah = al; al = mz(al); al ^= ah; al ^= zw; al ^= a(12)
            self.CZW2[1] = al
            # Zeile 3: 1 1 2 3
            ah = a(0) ^ a(4); al = mz(a(8)); al ^= ah; zw = al
            al = a(12); ah = al; al = mz(al); al ^= ah; al ^= zw
            self.CZW2[2] = al
            # Zeile 4: 3 1 1 2
            al = a(0); ah = al; al = mz(al); al ^= ah; al ^= a(4); al ^= a(8)
            ah = al; al = mz(a(12)); al ^= ah
            self.CZW2[3] = al
            tb[di], tb[di + 4] = self.CZW2[0], self.CZW2[1]
            tb[di + 8], tb[di + 12] = self.CZW2[2], self.CZW2[3]
            di += 1
            if di < bx:
                continue
            cx += 1
            di += 12
            bx += 16
            if cx >= 4:
                return

    def ShiftColumn_1(self):
        tb = self.TB
        for bp in range(16):
            di = (bp & 3) + ((bp >> 2) << 4)
            for k in range(4):
                self.CZW2[k] = tb[di + 4 * k]
            for si in range(0, 16, 4):
                ch = 0
                for bx in range(4):
                    ch ^= self.GFMulPROC(self.CZW2[bx], INVMIX[si + bx])
                tb[di + si] = ch


# ------------------------------------------------------- Ver-/Entschluesselung
def verschluesseln(text, schluessel=None):
    m = Maschine()
    if schluessel:
        m.RK0[:len(schluessel)] = schluessel
    m.TB[:len(text)] = list(text)
    m.SchluesselInitialisieren()
    # Ablauf_V.asm (aktiver Teil)
    m.SBOXSubstitution()
    m.Schluesselexpansion(); m.SchluesselAnwenden()
    m.ShiftRow()
    m.SBOXSubstitution()
    m.Schluesselexpansion(); m.SchluesselAnwenden()
    m.ShiftRow()
    m.SBOXSubstitution()
    return m.TB[:64]


def entschluesseln(chiffrat, schluessel=None):
    m = Maschine()
    if schluessel:
        m.RK0[:len(schluessel)] = schluessel
    m.TB[:64] = list(chiffrat)
    m.SchluesselInitialisieren()
    # Ablauf_E.asm (aktiver Teil)
    m.SBOXSubstitution_1()
    m.ShiftRow_1()
    m.Schluesselexpansion(); m.Schluesselexpansion(); m.SchluesselAnwenden()
    m.SBOXSubstitution_1()
    m.ShiftRow_1()
    m.SchluesselInitialisieren()
    m.Schluesselexpansion(); m.SchluesselAnwenden()
    m.SBOXSubstitution_1()
    return m.TB[:64]


# --------------------------------------------------------------------- Tests
ERGEBNISSE = []


def test(nr, name, fn):
    try:
        info = fn()
        ERGEBNISSE.append((nr, name, True, info or ""))
    except Exception as e:      # AssertionError, IndexError, ...
        ERGEBNISSE.append((nr, name, False, "FEHLER: %r" % (e,)))


def hexs(lst):
    return "".join("%02X" % x for x in lst)


def t_sbox():
    r = ref_sbox()
    assert S0 == r, "s_0 weicht von der AES-S-Box ab"
    assert S1 == [r.index(i) for i in range(256)], "s_1_0 ist nicht die Inverse"
    return "256 Eintraege je Tabelle"


def t_shiftrow():
    rnd = random.Random(1)
    for _ in range(300):
        st = [rnd.randrange(256) for _ in range(64)]
        m = Maschine(); m.TB[:64] = st; m.ShiftRow()
        erw = [st[16 * b + 4 * r + (c + r) % 4] for b in range(4) for r in range(4) for c in range(4)]
        assert m.TB[:64] == erw, "ShiftRow weicht von neu[c]=alt[(c+r) mod 4] ab"
        m.ShiftRow_1()
        assert m.TB[:64] == st, "ShiftRow_1 macht ShiftRow nicht rueckgaengig"
    st = list(range(64)); m = Maschine(); m.TB[:64] = st; m.ShiftRow()
    assert m.TB[48:64] == [48, 49, 50, 51, 53, 54, 55, 52, 58, 59, 56, 57, 63, 60, 61, 62], "Block 4"
    return "300 Zufallszustaende, Block 4 eigens geprueft"


def t_expansion():
    m = Maschine(); m.SchluesselInitialisieren()
    assert m.RKE[63] == 0x05
    m.Schluesselexpansion()
    assert m.RKE[:4] == [0x65, 0xBE, 0x13, 0xDC] and m.RKE[63] == 0xF1, hexs(m.RKE[:4])
    assert m.Rundekonstante == 0xBE
    k1 = list(m.RKE)
    m.Schluesselexpansion()
    assert m.RKE[:4] == [0x7A, 0xC4, 0xD7, 0x0B] and m.Rundekonstante == 0x7D, hexs(m.RKE[:4])
    # unabhaengig nach Formel k'[0]=k[0]^S(k[63])^RC, k'[j]=k'[j-1]^k[j]
    k = list(STANDARDSCHLUESSEL); rc = KONSTANTE
    for _ in range(2):
        n = list(k); n[0] = k[0] ^ S0[k[63]] ^ rc
        for j in range(1, 64):
            n[j] = n[j - 1] ^ k[j]
        k = n; rc = ((rc << 1) | (rc >> 7)) & 0xFF
    assert k == m.RKE
    return "K1 = 65 BE 13 DC ..., K2 = 7A C4 D7 0B ..., Konstante 5F, BE, 7D"


def t_mul2():
    for a in range(256):
        assert Maschine.MalZweiPROC(a) == ref_mul(a, 2), hex(a)
    assert Maschine.MalZweiPROC(0xDB) == 0xAD
    return "alle 256 Eingaben; DBh*2 = ADh"


def t_gfmul():
    for a in range(256):
        for b in range(256):
            assert Maschine.GFMulPROC(a, b) == ref_mul(a, b), (hex(a), hex(b))
    assert Maschine.GFMulPROC(0x4D, 0x0B) == 0x89
    assert Maschine.GFMulPROC(0x0E, 0x80) == 0x41
    return "alle 65536 Paare; 4Dh*0Bh = 89h, 0Eh*80h = 41h"


VEKTOREN = [
    ([0xDB, 0x13, 0x53, 0x45], [0x8E, 0x4D, 0xA1, 0xBC]),
    ([0xF2, 0x0A, 0x22, 0x5C], [0x9F, 0xDC, 0x58, 0x9D]),
    ([0x01, 0x01, 0x01, 0x01], [0x01, 0x01, 0x01, 0x01]),
    ([0xC6, 0xC6, 0xC6, 0xC6], [0xC6, 0xC6, 0xC6, 0xC6]),
    ([0xD4, 0xD4, 0xD4, 0xD5], [0xD5, 0xD5, 0xD7, 0xD6]),
    ([0x2D, 0x26, 0x31, 0x4C], [0x4D, 0x7E, 0xBD, 0xF8]),
]


def t_mixcol():
    for ein, aus in VEKTOREN:
        assert ref_mixcol(ein) == aus, "Referenz/Testvektor passt nicht: " + hexs(ein)
        m = Maschine()
        for blk in range(4):
            for c in range(4):
                for r in range(4):
                    m.TB[16 * blk + 4 * r + c] = ein[r]
        m.ShiftColumn()
        for blk in range(4):
            for c in range(4):
                assert [m.TB[16 * blk + 4 * r + c] for r in range(4)] == aus, hexs(ein)
        m.ShiftColumn_1()
        for blk in range(4):
            for c in range(4):
                assert [m.TB[16 * blk + 4 * r + c] for r in range(4)] == ein, "invers " + hexs(ein)
    return "6 Testvektoren (u. a. DB 13 53 45 -> 8E 4D A1 BC), alle 16 Spalten, vor und zurueck"


def t_mixcol_zufall():
    rnd = random.Random(2)
    for _ in range(2000):
        st = [rnd.randrange(256) for _ in range(64)]
        m = Maschine(); m.TB[:64] = st; m.ShiftColumn()
        for b in range(4):
            for c in range(4):
                col = [st[16 * b + 4 * r + c] for r in range(4)]
                assert [m.TB[16 * b + 4 * r + c] for r in range(4)] == ref_mixcol(col)
        m.ShiftColumn_1()
        assert m.TB[:64] == st, "ShiftColumn_1(ShiftColumn(x)) != x"
    return "2000 Zufallszustaende: gegen Referenz und Umkehrung"


def t_hallo():
    c = verschluesseln(b"Hallo")
    erw = ("E159BDA88E0FB958AA4DF3D15667AD0013BB19720FE93893BD6D3C6F4F5F5F55"
           "6C6F54B35C31772729100D090EA23AA57A1DB20902CD8E80311DA85033765168")
    assert hexs(c) == erw, hexs(c)
    assert bytes(entschluesseln(c)).rstrip(b"\x00") == b"Hallo"
    return "Chiffrat wie in Kapitel 4"


def t_roundtrip_standard():
    rnd = random.Random(3)
    for _ in range(500):
        n = rnd.randrange(0, 65)
        text = bytes(rnd.randrange(1, 256) for _ in range(n))
        c = verschluesseln(text)
        assert bytes(entschluesseln(c))[:n] == text and not any(entschluesseln(c)[n:])
    return "500 Zufallstexte, Standardschluessel"


def t_roundtrip_key():
    rnd = random.Random(4)
    for _ in range(500):
        n = rnd.randrange(0, 65)
        text = bytes(rnd.randrange(1, 256) for _ in range(n))
        k = [rnd.randrange(256) for _ in range(rnd.randrange(1, 65))]   # auch Teilschluessel
        c = verschluesseln(text, k)
        assert bytes(entschluesseln(c, k))[:n] == text
    c1 = verschluesseln(b"Hallo", [1] * 64)
    assert c1 != verschluesseln(b"Hallo")
    return "500 Zufallsfaelle mit eigenem (Teil-)Schluessel; anderer Schluessel -> anderes Chiffrat"


def t_blocks():
    m = Maschine(); m.TB[:64] = [7] * 48 + list(range(16)); m.ShiftRow()
    assert m.TB[48:64] != list(range(16)), "Block 4 wird nicht verschoben"
    return "Block 4 (Pos 48..63) wird verschoben"


if __name__ == "__main__":
    test("M1", "S-Box und inverse S-Box = AES (FIPS-197)", t_sbox)
    test("M2", "ShiftRow / ShiftRow_1 ueber alle 4 Bloecke", t_shiftrow)
    test("M3", "Schluesselexpansion (K1, K2, Rundenkonstante)", t_expansion)
    test("M4", "MalZweiPROC (Multiplikation mit 2)", t_mul2)
    test("M5", "GFMulPROC (allgemeine Multiplikation)", t_gfmul)
    test("M6", "ShiftColumn / ShiftColumn_1 gegen Testvektoren", t_mixcol)
    test("M7", "ShiftColumn / ShiftColumn_1 Zufall und Umkehrung", t_mixcol_zufall)
    test("M8", "Verschluesselung 'Hallo' (Beispiel Kapitel 4)", t_hallo)
    test("M9", "Ver- und Entschluesseln, Standardschluessel", t_roundtrip_standard)
    test("M10", "Ver- und Entschluesseln, eigener Schluessel", t_roundtrip_key)
    test("M11", "vierter Block wird verarbeitet", t_blocks)
    ok = True
    for nr, name, gut, info in ERGEBNISSE:
        print("%-4s %-52s %s  %s" % (nr, name, "OK    " if gut else "FEHLER", info))
        ok = ok and gut
    sys.exit(0 if ok else 1)
