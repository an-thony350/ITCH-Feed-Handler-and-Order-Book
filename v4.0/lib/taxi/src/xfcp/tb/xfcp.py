# SPDX-License-Identifier: MIT
"""

Copyright (c) 2017-2025 FPGA Ninja, LLC

Authors:
- Alex Forencich

"""

import struct


def cobs_encode(block):
    block = bytes(block)
    enc = bytearray()

    seg = bytearray()
    code = 1

    new_data = True

    for b in block:
        if b == 0:
            enc.append(code)
            enc.extend(seg)
            code = 1
            seg = bytearray()
            new_data = True
        else:
            code += 1
            seg.append(b)
            new_data = True
            if code == 255:
                enc.append(code)
                enc.extend(seg)
                code = 1
                seg = bytearray()
                new_data = False

    if new_data:
        enc.append(code)
        enc.extend(seg)

    return bytes(enc)


def cobs_decode(block):
    block = bytes(block)
    dec = bytearray()

    code = 0

    i = 0

    if 0 in block:
        return None

    while i < len(block):
        code = block[i]
        i += 1
        if i+code-1 > len(block):
            return None
        dec.extend(block[i:i+code-1])
        i += code-1
        if code < 255 and i < len(block):
            dec.append(0)

    return bytes(dec)


class XfcpFrame(object):
    def __init__(self, payload=b'', path=[], rpath=[], ptype=0):
        self._payload = b''
        self.path = path
        self.rpath = rpath
        self.ptype = ptype

        if type(payload) is bytes:
            self.payload = payload
        if type(payload) is XfcpFrame:
            self.payload = payload.payload
            self.path = list(payload.path)
            self.rpath = list(payload.rpath)
            self.ptype = payload.ptype

    @property
    def payload(self):
        return self._payload

    @payload.setter
    def payload(self, value):
        self._payload = bytes(value)

    def build(self):
        data = bytearray()

        for p in self.path:
            data.extend(struct.pack('B', p))

        if self.rpath:
            data.extend(struct.pack('B', 0xFE))
            for p in self.rpath:
                data.extend(struct.pack('B', p))

        data.extend(struct.pack('B', 0xFF))

        data.extend(struct.pack('B', self.ptype))

        data.extend(self.payload)

        return data

    def build_cobs(self):
        return cobs_encode(self.build())+b'\x00'

    @classmethod
    def parse(cls, data):
        data = bytes(data)

        i = 0

        path = []
        rpath = []

        while i < len(data) and data[i] < 0xFE:
            path.append(data[i])
            i += 1

        if data[i] == 0xFE:
            i += 1
            while i < len(data) and data[i] < 0xFE:
                rpath.append(data[i])
                i += 1

        assert data[i] == 0xFF
        i += 1

        ptype = data[i]
        i += 1

        payload = data[i:]

        return cls(payload, path, rpath, ptype)

    @classmethod
    def parse_cobs(cls, data):
        return cls.parse(cobs_decode(bytes(data)))

    def __eq__(self, other):
        if type(other) is XfcpFrame:
            return (self.path == other.path and
                self.rpath == other.rpath and
                self.ptype == other.ptype and
                self.payload == other.payload)
        return False

    def __repr__(self):
        return f"XfcpFrame(payload={self.payload!r}, path={self.path!r}, rpath={self.rpath!r}, ptype={self.ptype})"
