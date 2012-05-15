//----------------------------------------------------------------------------
// copyright (c) 1998, 1999, 2000 Thai Open Source Software Center Ltd
//                                and Clark Cooper
// copyright (c) 2001, 2002, 2003, 2004, 2005, 2006 Expat maintainers.
//
// Expat - Version 2.0.0 Release Milano 0.83 (PasExpat 2.0.0 RM0.83)
// Pascal Port By: Milan Marusinec alias Milano
//                 milan@marusinec.sk
//                 http://www.pasports.org/pasexpat
// copyright (c) 2006
//
// Permission is hereby granted, free of charge, to any person obtaining
// a Copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, Copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR copyright HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

const
{$IFDEF XML_NS}
  EncodingsNS: array [0 .. 6] of ENCODING_ptr = (@Latin1_encoding_ns.Enc,
    @Ascii_encoding_ns.Enc, @Utf8_encoding_ns.Enc, @Big2_encoding_ns.Enc,
    @Big2_encoding_ns.Enc, @Little2_encoding_ns.Enc, @Utf8_encoding_ns.Enc);
  { NO_ENC }
{$ENDIF}
  Encodings: array [0 .. 6] of ENCODING_ptr = (@Latin1_encoding.Enc,
    @Ascii_encoding.Enc, @Utf8_encoding.Enc, @Big2_encoding.Enc,
    @Big2_encoding.Enc, @Little2_encoding.Enc, @Utf8_encoding.Enc); { NO_ENC }

function InitScanProlog(Enc: ENCODING_ptr; Ptr, End_: PAnsiChar;
  NextTokPtr: PPAnsiChar): Integer;
begin
  Result := InitScan(@Encodings, INIT_ENCODING_ptr(Enc), XML_PROLOG_STATE, Ptr,
    End_, NextTokPtr);
end;

function InitScanContent(Enc: ENCODING_ptr; Ptr, End_: PAnsiChar;
  NextTokPtr: PPAnsiChar): Integer;
begin
end;

function XmlInitEncoding(P: INIT_ENCODING_ptr; EncPtr: ENCODING_ptr_ptr;
  Name: PAnsiChar): Integer;
var
  I: Integer;
begin
  I := GetEncodingIndex(name);

  if I = UNKNOWN_ENC then
  begin
    Result := 0;
    Exit;
  end;

  SET_INIT_ENC_INDEX(P, I);

  P.InitEnc.Scanners[XML_PROLOG_STATE] := @InitScanProlog;
  P.InitEnc.Scanners[XML_CONTENT_STATE] := @InitScanContent;

  P.InitEnc.UpdatePosition := @InitUpdatePosition;

  P.EncPtr := EncPtr;
  EncPtr^ := @P.InitEnc;

  Result := 1;
end;

function XmlInitEncodingNS(P: INIT_ENCODING_ptr; EncPtr: ENCODING_ptr_ptr;
  Name: PAnsiChar): Integer;
begin
end;

function XmlGetUtf8InternalEncoding: ENCODING_ptr;
begin
  Result := @Internal_utf8_encoding.Enc;
end;

function XmlGetUtf16InternalEncoding: ENCODING_ptr;
begin
end;

function XmlGetInternalEncoding: ENCODING_ptr;
begin
{$IFDEF XML_UNICODE }
  Result := XmlGetUtf16InternalEncoding;
{$ELSE}
  Result := XmlGetUtf8InternalEncoding;
{$ENDIF}
end;

function XmlGetUtf8InternalEncodingNS: ENCODING_ptr;
begin
end;

function XmlGetUtf16InternalEncodingNS: ENCODING_ptr;
begin
end;

function XmlGetInternalEncodingNS: ENCODING_ptr;
begin
{$IFDEF XML_UNICODE}
  Result := XmlGetUtf16InternalEncodingNS;
{$ELSE}
  Result := XmlGetUtf8InternalEncodingNS;
{$ENDIF}
end;

function FindEncoding(Enc: ENCODING_ptr; Ptr, End_: PAnsiChar): ENCODING_ptr;
begin
end;

function XmlParseXmlDecl(IsGeneralTextEntity: Integer; Enc: ENCODING_ptr;
  Ptr, Stop: PAnsiChar; BadPtr, VersionPtr, VersionEndPtr,
  EncodingNamePtr: PPAnsiChar; NamedEncodingPtr: ENCODING_ptr_ptr;
  StandalonePtr: PInteger): Integer;
begin
  Result := DoParseXmlDecl(@FindEncoding, IsGeneralTextEntity, Enc, Ptr, Stop,
    BadPtr, VersionPtr, VersionEndPtr, EncodingNamePtr, NamedEncodingPtr,
    StandalonePtr);
end;
