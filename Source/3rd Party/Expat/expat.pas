unit expat;

// ----------------------------------------------------------------------------
// Copyright (c) 1998, 1999, 2000 Thai Open Source Software Center Ltd
// and Clark Cooper
// Copyright (c) 2001, 2002, 2003, 2004, 2005, 2006 Expat maintainers.
//
// Expat - Version 2.0.0 Release Milano 0.83 (PasExpat 2.0.0 RM0.83)
// Pascal Port By: Milan Marusinec alias Milano
// milan@marusinec.sk
// http://www.pasports.org/pasexpat
// Copyright (c) 2006
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
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
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// [Pascal Port History] -----------------------------------------------------
//
// 01.05.2006-Milano: Unit port establishment
// 07.06.2006-Milano: porting
//

interface

uses
  Expat_basics,
  Expat_external,
  Xmltok,
  Xmlrole;

{$I expat_mode.inc}


type
  XML_Parser = ^XML_ParserStruct;

  XML_Bool = Int8u;

  { The XML_Status enum gives the possible return values for several API functions. }
  XML_Status = (XML_STATUS_ERROR, XML_STATUS_OK, XML_STATUS_SUSPENDED);

  XML_Error = (XML_ERROR_NONE, XML_ERROR_NO_MEMORY, XML_ERROR_SYNTAX,
    XML_ERROR_NO_ELEMENTS, XML_ERROR_INVALID_TOKEN, XML_ERROR_UNCLOSED_TOKEN,
    XML_ERROR_PARTIAL_CHAR, XML_ERROR_TAG_MISMATCH,
    XML_ERROR_DUPLICATE_ATTRIBUTE, XML_ERROR_JUNK_AFTER_DOC_ELEMENT,
    XML_ERROR_PARAM_ENTITY_REF, XML_ERROR_UNDEFINED_ENTITY,
    XML_ERROR_RECURSIVE_ENTITY_REF, XML_ERROR_ASYNC_ENTITY,
    XML_ERROR_BAD_CHAR_REF, XML_ERROR_BINARY_ENTITY_REF,
    XML_ERROR_ATTRIBUTE_EXTERNAL_ENTITY_REF, XML_ERROR_MISPLACED_XML_PI,
    XML_ERROR_UNKNOWN_ENCODING, XML_ERROR_INCORRECT_ENCODING,
    XML_ERROR_UNCLOSED_CDATA_SECTION, XML_ERROR_EXTERNAL_ENTITY_HANDLING,
    XML_ERROR_NOT_STANDALONE, XML_ERROR_UNEXPECTED_STATE,
    XML_ERROR_ENTITY_DECLARED_IN_PE, XML_ERROR_FEATURE_REQUIRES_XML_DTD,
    XML_ERROR_CANT_CHANGE_FEATURE_ONCE_PARSING,
    { Added in 1.95.7. }
    XML_ERROR_UNBOUND_PREFIX,
    { Added in 1.95.8. }
    XML_ERROR_UNDECLARING_PREFIX, XML_ERROR_INCOMPLETE_PE, XML_ERROR_XML_DECL,
    XML_ERROR_TEXT_DECL, XML_ERROR_PUBLICID, XML_ERROR_SUSPENDED,
    XML_ERROR_NOT_SUSPENDED, XML_ERROR_ABORTED, XML_ERROR_FINISHED,
    XML_ERROR_SUSPEND_PE,
    { Added in 2.0. }
    XML_ERROR_RESERVED_PREFIX_XML, XML_ERROR_RESERVED_PREFIX_XMLNS,
    XML_ERROR_RESERVED_NAMESPACE_URI);

  XML_Content_Type = (___SKIP_ZERO____, XML_CTYPE_EMPTY, XML_CTYPE_ANY,
    XML_CTYPE_MIXED, XML_CTYPE_NAME, XML_CTYPE_CHOICE, XML_CTYPE_SEQ);

  XML_Content_Quant = (XML_CQUANT_NONE, XML_CQUANT_OPT, XML_CQUANT_REP,
    XML_CQUANT_PLUS);

  XML_ParamEntityParsing = (XML_PARAM_ENTITY_PARSING_NEVER,
    XML_PARAM_ENTITY_PARSING_UNLESS_STANDALONE,
    XML_PARAM_ENTITY_PARSING_ALWAYS);

  { If type == XML_CTYPE_EMPTY or XML_CTYPE_ANY, then quant will be
    XML_CQUANT_NONE, and the other fields will be zero or NULL.
    If type == XML_CTYPE_MIXED, then quant will be NONE or REP and
    numchildren will contain number of elements that may be mixed in
    and children point to an array of TXmlContent cells that will be
    all of XML_CTYPE_NAME type with no quantification.

    If type == XML_CTYPE_NAME, then the name points to the name, and
    the numchildren field will be zero and children will be NULL. The
    quant fields indicates any quantifiers placed on the name.

    CHOICE and SEQ will have name NULL, the number of children in
    numchildren and children will point, recursively, to an array
    of TXmlContent cells.

    The EMPTY, ANY, and MIXED types will only occur at top level. }
  XML_Content_ptr = ^TXmlContent;

  XML_cp = record
    Type_: XML_Content_Type;
    Quant: XML_Content_Quant;
    Name: XML_PAnsiChar;

    Numchildren: Cardinal;
    Children: XML_Content_ptr;

  end;

  TXmlContent = XML_cp;

  { This is called for an element declaration. See above for
    description of the model argument. It's the caller's responsibility
    to free model when finished with it. }
  TXmlElementDeclHandler = procedure(UserData: Pointer; Name: XML_PAnsiChar;
    Model: XML_Content_ptr);

  { The Attlist declaration handler is called for *each* attribute. So
    a single Attlist declaration with multiple attributes declared will
    generate multiple calls to this handler. The "default" parameter
    may be NULL in the case of the "#IMPLIED" or "#REQUIRED"
    keyword. The "isrequired" parameter will be true and the default
    value will be NULL in the case of "#REQUIRED". If "isrequired" is
    true and default is non-NULL, then this is a "#FIXED" default. }
  TXmlAttlistDeclHandler = procedure(UserData: Pointer;
    Elname, Attname, Att_type, Dflt: XML_PAnsiChar; Isrequired: Integer);

  { The XML declaration handler is called for *both* XML declarations
    and text declarations. The way to distinguish is that the version
    parameter will be NULL for text declarations. The encoding
    parameter may be NULL for XML declarations. The standalone
    parameter will be -1, 0, or 1 indicating respectively that there
    was no standalone parameter in the declaration, that it was given
    as no, or that it was given as yes. }
  TXmlXmlDeclHandler = procedure(UserData: Pointer;
    Version, Encoding: XML_PAnsiChar; Standalone: Integer);

  { This is called for TEntity declarations. The is_parameter_entity
    argument will be non-zero if the TEntity is a parameter TEntity, zero
    otherwise.

    For internal entities (<!TEntity foo "bar">), value will
    be non-NULL and systemId, publicID, and notationName will be NULL.
    The value string is NOT nul-terminated; the length is provided in
    the value_length argument. Since it is legal to have zero-length
    values, do not use this argument to test for internal entities.

    For external entities, value will be NULL and systemId will be
    non-NULL. The publicId argument will be NULL unless a public
    identifier was provided. The notationName argument will have a
    non-NULL value only for unparsed TEntity declarations.

    Note that is_parameter_entity can't be changed to XML_Bool, since
    that would break binary compatibility. }
  TXmlEntityDeclHandler = procedure(UserData: Pointer; EntityName: XML_PAnsiChar;
    Is_parameter_entity: Integer; Value: XML_PAnsiChar; Value_length: Integer;
    Base, SystemId, PublicId, NotationName: XML_PAnsiChar);

  { atts is array of name/value pairs, terminated by 0;
    names and values are 0 terminated. }
  TXmlStartElementHandler = procedure(UserData: Pointer; Name: XML_PAnsiChar;
    Atts: XML_PPAnsiChar);
  TXmlEndElementHandler = procedure(UserData: Pointer; Name: XML_PAnsiChar);

  { s is not 0 terminated. }
  TXmlCharacterDataHandler = procedure(UserData: Pointer; S: XML_PAnsiChar;
    Len: Integer);

  { target and data are 0 terminated }
  TXmlProcessingInstructionHandler = procedure(UserData: Pointer;
    Target, Data: XML_PAnsiChar);

  { data is 0 terminated }
  TXmlCommentHandler = procedure(UserData: Pointer; Data: XML_PAnsiChar);

  TXmlStartCdataSectionHandler = procedure(UserData: Pointer);
  TXmlEndCdataSectionHandler = procedure(UserData: Pointer);

  { This is called for any characters in the XML document for which
    there is no applicable handler.  This includes both characters that
    are part of markup which is of a kind that is not reported
    (comments, markup declarations), or characters that are part of a
    construct which could be reported but for which no handler has been
    supplied. The characters are passed exactly as they were in the XML
    document except that they will be encoded in UTF-8 or UTF-16.
    Line boundaries are not normalized. Note that a byte order mark
    character is not passed to the default handler. There are no
    guarantees about how characters are divided between calls to the
    default handler: for example, a comment might be split between
    multiple calls. }
  TXmlDefaultHandler = procedure(UserData: Pointer; S: XML_PAnsiChar; Len: Integer);

  { This is called for the start of the DOCTYPE declaration, before
    any DTD or internal subset is parsed. }
  TXmlStartDoctypeDeclHandler = procedure(UserData: Pointer;
    DoctypeName, Sysid, Pubid: XML_PAnsiChar; HasInternal_subset: Integer);

  { This is called for the start of the DOCTYPE declaration when the
    closing > is encountered, but after processing any external
    subset. }
  TXmlEndDoctypeDeclHandler = procedure(UserData: Pointer);

  { OBSOLETE -- OBSOLETE -- OBSOLETE
    This handler has been superceded by the EntityDeclHandler above.
    It is provided here for backward compatibility.

    This is called for a declaration of an unparsed (NDATA) TEntity.
    The base argument is whatever was set by XML_SetBase. The
    entityName, systemId and notationName arguments will never be
    NULL. The other arguments may be. }
  TXmlUnparsedEntityDeclHandler = procedure(UserData: Pointer;
    EntityName, Base, SystemId, PublicId, NotationName: XML_PAnsiChar);

  { This is called for a declaration of notation.  The base argument is
    whatever was set by XML_SetBase. The notationName will never be
    NULL.  The other arguments can be. }
  TXmlNotationDeclHandler = procedure(UserData: Pointer;
    NotationName, Base, SystemId, PublicId: XML_PAnsiChar);

  { When namespace processing is enabled, these are called once for
    each namespace declaration. The call to the start and end element
    handlers occur between the calls to the start and end namespace
    declaration handlers. For an xmlns attribute, TPrefix will be
    NULL.  For an xmlns="" attribute, uri will be NULL. }
  TXmlStartNamespaceDeclHandler = procedure(UserData: Pointer;
    TPrefix, Uri: XML_PAnsiChar);
  TXmlEndNamespaceDeclHandler = procedure(UserData: Pointer;
    TPrefix: XML_PAnsiChar);

  { This is called if the document is not standalone, that is, it has an
    external subset or a reference to a parameter TEntity, but does not
    have standalone="yes". If this handler returns XML_STATUS_ERROR,
    then processing will not continue, and the parser will return a
    XML_ERROR_NOT_STANDALONE error.
    If parameter TEntity parsing is enabled, then in addition to the
    conditions above this handler will only be called if the referenced
    TEntity was actually read. }
  TXmlNotStandaloneHandler = function(UserData: Pointer): Integer;

  { This is called for a reference to an external parsed general
    TEntity.  The referenced TEntity is not automatically parsed.  The
    application can parse it immediately or later using
    XML_ExternalEntityParserCreate.

    The parser argument is the parser parsing the TEntity containing the
    reference; it can be passed as the parser argument to
    XML_ExternalEntityParserCreate.  The systemId argument is the
    system identifier as specified in the TEntity declaration; it will
    not be NULL.

    The base argument is the system identifier that should be used as
    the base for resolving systemId if systemId was relative; this is
    set by XML_SetBase; it may be NULL.

    The publicId argument is the public identifier as specified in the
    TEntity declaration, or NULL if none was specified; the whitespace
    in the public identifier will have been normalized as required by
    the XML spec.

    The context argument specifies the parsing context in the format
    expected by the context argument to XML_ExternalEntityParserCreate;
    context is valid only until the handler returns, so if the
    referenced TEntity is to be parsed later, it must be copied.
    context is NULL only when the TEntity is a parameter TEntity.

    The handler should return XML_STATUS_ERROR if processing should not
    continue because of a fatal error in the handling of the external
    TEntity.  In this case the calling parser will return an
    XML_ERROR_EXTERNAL_ENTITY_HANDLING error.

    Note that unlike other handlers the first argument is the parser,
    not userData. }
  TXmlExternalEntityRefHandler = function(Parser: XML_Parser;
    Context, Base, SystemId, PublicId: XML_PAnsiChar): Integer;

  { This is called in two situations:
    1) An TEntity reference is encountered for which no declaration
    has been read *and* this is not an error.
    2) An internal TEntity reference is read, but not expanded, because
    XML_SetDefaultHandler has been called.
    Note: skipped parameter entities in declarations and skipped general
    entities in attribute values cannot be reported, because
    the event would be out of sync with the reporting of the
    declarations or attribute values }
  TXmlSkippedEntityHandler = procedure(UserData: Pointer;
    EntityName: XML_PAnsiChar; Is_parameter_entity: Integer);

  (* This structure is filled in by the TXmlUnknownEncodingHandler to
    provide information to the parser about encodings that are unknown
    to the parser.

    The map[b] member gives information about byte sequences whose
    first byte is b.

    If map[b] is c where c is >= 0, then b by itself encodes the
    Unicode scalar value c.

    If map[b] is -1, then the byte sequence is malformed.

    If map[b] is -n, where n >= 2, then b is the first byte of an
    n-byte sequence that encodes a single Unicode scalar value.

    The data member will be passed as the first argument to the convert
    function.

    The convert function is used to convert multibyte sequences; s will
    point to a n-byte sequence where map[(Cardinal char)*s] == -n.  The
    convert function must return the Unicode scalar value represented
    by this byte sequence or -1 if the byte sequence is malformed.

    The convert function may be NULL if the encoding is a single-byte
    encoding, that is if map[b] >= -1 for all bytes b.

    When the parser is finished with the encoding, then if release is
    not NULL, it will call release passing it the data member; once
    release has been called, the convert function will not be called
    again.

    Expat places certain restrictions on the encodings that are supported
    using this mechanism.

    1. Every ASCII character that can appear in a well-formed XML document,
    other than the characters

    $@\^`{}~

    must be represented by a single byte, and that byte must be the
    same byte that represents that character in ASCII.

    2. No character may require more than 4 bytes to encode.

    3. All characters encoded must have Unicode scalar values <=
    0xFFFF, (i.e., characters that would be encoded by surrogates in
    UTF-16 are  not alLowed).  Note that this restriction doesn't
    apply to the built-in support for UTF-8 and UTF-16.

    4. No Unicode character may be encoded by more than one distinct
    sequence of bytes. *)
  PXmlEncoding = ^TXmlEncoding;

  TXmlEncoding = record
    Map: array [0..255] of Integer;
    Data: Pointer;

    Convert: function(Data: Pointer; S: PAnsiChar): Integer;
    Release: procedure(Data: Pointer);
  end;

  { This is called for an encoding that is unknown to the parser.

    The encodingHandlerData argument is that which was passed as the
    second argument to XML_SetUnknownEncodingHandler.

    The name argument gives the name of the encoding as specified in
    the encoding declaration.

    If the callback can provide information about the encoding, it must
    fill in the TXmlEncoding structure, and return XML_STATUS_OK.
    Otherwise it must return XML_STATUS_ERROR.

    If info does not describe a suitable encoding, then the parser will
    return an XML_UNKNOWN_ENCODING error. }
  TXmlUnknownEncodingHandler = function(EncodingHandlerData: Pointer;
    Name: XML_PAnsiChar; Info: PXmlEncoding): Integer;

  PXmlMemoryHandlingSuite = ^TXmlMemoryHandlingSuite;

  TXmlMemoryHandlingSuite = record
    Malloc_fcn: function(var Ptr: Pointer; Sz: Integer): Boolean;
    Realloc_fcn: function(var Ptr: Pointer; Old, Sz: Integer): Boolean;
    Free_fcn: function(var Ptr: Pointer; Sz: Integer): Boolean;
  end;

  KEY = XML_PAnsiChar;

  PPNamed = ^PNamed;
  PNamed = ^TNamed;

  TNamed = record
    Name: KEY;
    Alloc: Integer;
  end;

  PHashTable = ^THashTable;

  THashTable = record
    V: PPNamed;
    A: Integer;

    Power: Int8u;
    Size, Used: Size_t;
    Mem: PXmlMemoryHandlingSuite;
  end;

  PEntity = ^TEntity;

  TEntity = record
    Name: XML_PAnsiChar;
    Alloc: Integer;

    TextPtr: XML_PAnsiChar;
    TextLen, { length in XML_Chars }
    Processed: Integer; { # of processed bytes - when suspended }
    SystemId, Base, PublicId, Notation: XML_PAnsiChar;

    Open, Is_param, IsInternal: XML_Bool;
    { true if declared in internal subset outside PE }
  end;

  POpenInternalEntity = ^TOpenInternalEntity;

  TOpenInternalEntity = record
    InternalEventPtr, InternalEventEndPtr: PAnsiChar;

    Next: POpenInternalEntity;
    TEntity: PEntity;

    StartTagLevel: Integer;
    BetweenDecl: XML_Bool; { WFC: PE Between Declarations }
  end;

  PContentScaffold = ^TContentScaffold;

  TContentScaffold = record
    Type_: XML_Content_Type;
    Quant: XML_Content_Quant;
    Name: XML_PAnsiChar;

    Firstchild, Lastchild, Childcnt, Nextsib: Integer;
  end;

  PPrefix = ^TPrefix;

  PAttributeID = ^TAttributeID;

  TAttributeID = record
    Name: XML_PAnsiChar;
    Alloc: Integer;
    TPrefix: PPrefix;

    MaybeTokenized, Xmlns: XML_Bool;
  end;

  PDefaultAttribute = ^TDefaultAttribute;

  TDefaultAttribute = record
    Id: PAttributeID;

    IsCdata: XML_Bool;
    Value: XML_PAnsiChar;
  end;

  PElementType = ^TElementType;

  TElementType = record
    Name: XML_PAnsiChar;
    Alloc: Integer;
    TPrefix: PPrefix;
    IdAtt: PAttributeID;

    NDefaultAtts, AllocDefaultAtts, DefaultAttsAlloc: Integer;

    DefaultAtts: PDefaultAttribute;
  end;

  PTagName = ^TTagName;

  TTagName = record
    Str, LocalPart, TPrefix: XML_PAnsiChar;
    StrLen, UriLen, PrefixLen: Integer;
  end;

  { TAG represents an open element.
    The name of the element is stored in both the document and API
    encodings.  The memory buffer 'buf' is a separately-allocated
    memory area which stores the name.  During the XML_Parse()/
    XMLParseBuffer() when the element is open, the memory for the 'raw'
    version of the name (in the document encoding) is shared with the
    document buffer.  If the element is open across calls to
    XML_Parse()/XML_ParseBuffer(), the buffer is re-allocated to
    contain the 'raw' name as well.

    A parser re-uses these structures, maintaining a list of allocated
    TAG objects in a free list. }
  PPBinding = ^PBinding;
  PBinding = ^TBinding;

  TAG_ptr = ^TAG;

  TAG = record
    Parent: TAG_ptr; { parent of this element }
    RawName: PAnsiChar; { tagName in the original encoding }

    RawNameLength: Integer;

    Name: TTagName; { tagName in the API encoding }

    Buf, { buffer for name components }
    BufEnd: PAnsiChar; { end of the buffer }
    Alloc: Integer;

    Bindings: PBinding;
  end;

  TBinding = record
    TPrefix: PPrefix;

    NextTagBinding, PrevPrefixBinding: PBinding;

    AttId: PAttributeID;
    Uri: XML_PAnsiChar;

    UriLen, UriAlloc: Integer;
  end;

  TPrefix = record
    Name: XML_PAnsiChar;
    Alloc: Integer;
    TBinding: PBinding;
  end;

  NS_ATT_ptr = ^NS_ATT;

  NS_ATT = record
    Version, Hash: Int32u;
    UriName: XML_PAnsiChar;
  end;

  PBlock = ^TBlock;

  TBlock = record
    Next: PBlock;
    Size, Alloc: Integer;

    S: array [0..0] of XML_Char;
  end;

  PStringPool = ^TStringPool;

  TStringPool = record
    Blocks, FreeBlocks: PBlock;

    End_, Ptr, Start: XML_PAnsiChar;

    Mem: PXmlMemoryHandlingSuite;
  end;

  DTD_ptr = ^DTD;

  DTD = record
    GeneralEntities, ElementTypes, AttributeIds, Prefixes: THashTable;

    Pool, EntityValuePool: TStringPool;

    { false once a parameter TEntity reference has been skipped }
    KeepProcessing: XML_Bool;

    { true once an internal or external PE reference has been encountered;
      this includes the reference to an external subset }
    HasParamEntityRefs, Standalone: XML_Bool;

{$IFDEF XML_DTD }
    { indicates if external PE has been read }
    ParamEntityRead: XML_Bool;
    ParamEntities: THashTable;

{$ENDIF }
    DefaultPrefix: TPrefix;

    { === scaffolding for building content model === }
    In_eldecl: XML_Bool;
    Scaffold: PContentScaffold;

    ContentStringLen, ScaffSize, ScaffCount: Cardinal;

    ScaffLevel: Integer;
    ScaffIndex: PInteger;
    ScaffAlloc: Integer;
  end;

  XML_Parsing = (XML_INITIALIZED, XML_PARSING_, XML_FINISHED, XML_SUSPENDED);

  XML_ParsingStatus = record
    Parsing: XML_Parsing;
    FinalBuffer: XML_Bool;
  end;

  TProcessor = function(Parser: XML_Parser; Start, End_: PAnsiChar;
    EndPtr: PPAnsiChar): XML_Error;

  XML_ParserStruct = record
    UserData, HandlerArg: Pointer;

    Buffer: PAnsiChar;
    Mem: TXmlMemoryHandlingSuite;

    { first character to be parsed }
    BufferPtr: PAnsiChar;

    { past last character to be parsed }
    BufferEnd: PAnsiChar;

    { allocated end of buffer }
    BufferLim: PAnsiChar;

    { the size of the allocated buffer }
    BufferAloc: Integer;

    ParseEndByteIndex: XML_Index;

    ParseEndPtr: PAnsiChar;
    DataBuf, DataBufEnd: XML_PAnsiChar;

    { XML Handlers }
    StartElementHandler: TXmlStartElementHandler;
    EndElementHandler: TXmlEndElementHandler;
    CharacterDataHandler: TXmlCharacterDataHandler;
    ProcessingInstructionHandler: TXmlProcessingInstructionHandler;
    CommentHandler: TXmlCommentHandler;
    StartCdataSectionHandler: TXmlStartCdataSectionHandler;
    EndCdataSectionHandler: TXmlEndCdataSectionHandler;
    DefaultHandler: TXmlDefaultHandler;
    StartDoctypeDeclHandler: TXmlStartDoctypeDeclHandler;
    EndDoctypeDeclHandler: TXmlEndDoctypeDeclHandler;
    UnparsedEntityDeclHandler: TXmlUnparsedEntityDeclHandler;
    NotationDeclHandler: TXmlNotationDeclHandler;
    StartNamespaceDeclHandler: TXmlStartNamespaceDeclHandler;
    EndNamespaceDeclHandler: TXmlEndNamespaceDeclHandler;
    NotStandaloneHandler: TXmlNotStandaloneHandler;
    ExternalEntityRefHandler: TXmlExternalEntityRefHandler;
    ExternalEntityRefHandlerArg: XML_Parser;
    SkippedEntityHandler: TXmlSkippedEntityHandler;
    UnknownEncodingHandler: TXmlUnknownEncodingHandler;
    ElementDeclHandler: TXmlElementDeclHandler;
    AttlistDeclHandler: TXmlAttlistDeclHandler;
    EntityDeclHandler: TXmlEntityDeclHandler;
    XmlDeclHandler: TXmlXmlDeclHandler;

    Encoding: ENCODING_ptr;
    InitEncoding: INIT_ENCODING;
    InternalEncoding: ENCODING_ptr;
    ProtocolEncodingName: XML_PAnsiChar;

    M_ns, M_ns_triplets: XML_Bool;

    UnknownEncodingMem, UnknownEncodingData,
      UnknownEncodingHandlerData: Pointer;
    UnknownEncodingAlloc: Integer;

    UnknownEncodingRelease: procedure(Void: Pointer);

    PrologState: PROLOG_STATE;
    TProcessor: TProcessor;
    ErrorCode: XML_Error;
    EventPtr, EventEndPtr, PositionPtr: PAnsiChar;

    OpenInternalEntities, FreeInternalEntities: POpenInternalEntity;

    DefaultExpandInternalEntities: XML_Bool;

    TagLevel: Integer;
    DeclEntity: PEntity;

    DoctypeName, DoctypeSysid, DoctypePubid, DeclAttributeType,
      DeclNotationName, DeclNotationPublicId: XML_PAnsiChar;

    DeclElementType: PElementType;
    DeclAttributeId: PAttributeID;

    DeclAttributeIsCdata, DeclAttributeIsId: XML_Bool;

    M_dtd: DTD_ptr;

    CurBase: XML_PAnsiChar;

    TagStack, FreeTagList: TAG_ptr;

    InheritedBindings, FreeBindingList: PBinding;

    AttsSize, AttsAlloc, M_nsAttsAlloc, M_nSpecifiedAtts, IdAttIndex: Integer;

    Atts: ATTRIBUTE_ptr;
    M_nsAtts: NS_ATT_ptr;

    M_nsAttsVersion: Cardinal;
    M_nsAttsPower: Int8u;

    Position: POSITION;
    TempPool, M_temp2Pool: TStringPool;

    GroupConnector: PAnsiChar;
    GroupSize, M_groupAlloc: Cardinal;

    NamespaceSeparator: XML_Char;

    ParentParser: XML_Parser;
    ParsingStatus: XML_ParsingStatus;

{$IFDEF XML_DTD }
    IsParamEntity, M_useForeignDTD: XML_Bool;

    ParamEntityParsing: XML_ParamEntityParsing;
{$ENDIF }
  end;

const
  CXmlTrue = 1;
  CXmlFalse = 0;

{ Constructs a new parser; encoding is the encoding specified by the
  external protocol or NIL if there is none specified. }
function XML_ParserCreate(const Encoding: XML_PAnsiChar): XML_Parser;

{ Constructs a new parser using the memory management suite referred to
  by memsuite. If memsuite is NULL, then use the standard library memory
  suite. If namespaceSeparator is non-NULL it creates a parser with
  namespace processing as described above. The character pointed at
  will serve as the namespace separator.

  All further memory operations used for the created parser will come from
  the given suite. }
function XML_ParserCreate_MM(Encoding: XML_PAnsiChar;
  Memsuite: PXmlMemoryHandlingSuite; NamespaceSeparator: XML_PAnsiChar)
  : XML_Parser;

{ This value is passed as the userData argument to callbacks. }
procedure XML_SetUserData(Parser: XML_Parser; UserData: Pointer);

procedure XML_SetElementHandler(Parser: XML_Parser;
  Start: TXmlStartElementHandler; End_: TXmlEndElementHandler);

procedure XML_SetCharacterDataHandler(Parser: XML_Parser;
  Handler: TXmlCharacterDataHandler);

{ Parses some input. Returns XML_STATUS_ERROR if a fatal error is
  detected.  The last call to XML_Parse must have isFinal true; len
  may be zero for this call (or any other).

  Though the return values for these functions has always been
  described as a Boolean value, the implementation, at least for the
  1.95.x series, has always returned exactly one of the XML_Status
  values. }
function XML_Parse(Parser: XML_Parser; const S: PAnsiChar; Len, IsFinal: Integer)
  : XML_Status;

{ If XML_Parse or XML_ParseBuffer have returned XML_STATUS_ERROR, then
  XML_GetErrorCode returns information about the error. }
function XML_GetErrorCode(Parser: XML_Parser): XML_Error;

{ Returns a string describing the error. }
function XML_ErrorString(Code: XML_Error): XML_LPAnsiChar;

{ These functions return information about the current parse
  location.  They may be called from any callback called to report
  some parse event; in this case the location is the location of the
  first of the sequence of characters that generated the event.  When
  called from callbacks generated by declarations in the document
  prologue, the location identified isn't as neatly defined, but will
  be within the relevant markup.  When called outside of the callback
  functions, the position indicated will be just past the last parse
  event (regardless of whether there was an associated callback).

  They may also be called after returning from a call to XML_Parse
  or XML_ParseBuffer.  If the return value is XML_STATUS_ERROR then
  the location is the location of the character at which the error
  was detected; otherwise the location is the location of the last
  parse event, as described above. }
function XML_GetCurrentLineNumber(Parser: XML_Parser): XML_Size;

{ Frees memory used by the parser. }
procedure XML_ParserFree(Parser: XML_Parser);

implementation

{$Q-}
{$R-}

function PoolStoreString(Pool: PStringPool; Enc: ENCODING_ptr;
  Ptr, Stop: PAnsiChar): XML_PAnsiChar; forward;
procedure PoolFinish(Pool: PStringPool); forward;
procedure PoolClear(Pool: PStringPool); forward;
procedure PoolDestroy(Pool: PStringPool); forward;
function PoolAppendChar(Pool: PStringPool; C: AnsiChar): Integer; forward;

function ReportProcessingInstruction(Parser: XML_Parser; Enc: ENCODING_ptr;
  Start, Stop: PAnsiChar): Integer; forward;
function ReportComment(Parser: XML_Parser; Enc: ENCODING_ptr;
  Start, Stop: PAnsiChar): Integer; forward;

function GetAttributeId(Parser: XML_Parser; Enc: ENCODING_ptr;
  Start, Stop: PAnsiChar): PAttributeID; forward;

function StoreAttributeValue(Parser: XML_Parser; Enc: ENCODING_ptr;
  IsCdata: XML_Bool; Ptr, Stop: PAnsiChar; Pool: PStringPool)
  : XML_Error; forward;

const
  ImplicitContext: array [0 .. 40] of XML_Char = ('x', 'm', 'l', '=', 'h', 't',
    't', 'p', ':', '/', '/', 'w', 'w', 'w', '.', 'w', '3', '.', 'o', 'r', 'g',
    '/', 'X', 'M', 'L', '/', '1', '9', '9', '8', '/', 'n', 'a', 'm', 'e', 's',
    'p', 'a', 'c', 'e', #0);

  INIT_TAG_BUF_SIZE = 32; { must be a multiple of SizeOf(XML_Char) }
  INIT_DATA_BUF_SIZE = 1024;
  INIT_ATTS_SIZE = 16;
  INIT_ATTS_VERSION = $FFFFFFFF;
  INIT_BLOCK_SIZE = 1024;
  INIT_BUFFER_SIZE = 1024;

  EXPAND_SPARE = 24;

  INIT_SCAFFOLD_ELEMENTS = 32;

  INIT_POWER = 6;

type
  IPPAnsiChar = ^IPAnsiChar;
  IPAnsiChar = ^ICHAR;

{$IFDEF XML_UNICODE}
  ICHAR = Int16u;
{$ELSE }
  ICHAR = AnsiChar;
{$ENDIF }

  PHashTableIter = ^THashTableIter;

  THashTableIter = record
    P, Stop: PPNamed;
  end;

const
{$IFDEF XML_UNICODE}
  XML_ENCODE_MAX = XML_UTF16_ENCODE_MAX;
{$ELSE }
  XML_ENCODE_MAX = XML_UTF8_ENCODE_MAX;
{$ENDIF }

function MemCmp(P1, P2: Int8u_ptr; L: Integer): Integer;
begin
  while L > 0 do
  begin
    if P1^ <> P2^ then
    begin
      Result := P1^ - P2^;

      Exit;
    end;

    Dec(L);
    Inc(PtrComp(P1));
    Inc(PtrComp(P2));
  end;

  Result := 0;
end;

{ Basic character hash algorithm, taken from Python's string hash:
  h = h * 1000003 ^ character, the constant being a prime number. }
function CHAR_HASH(H: Int32u; C: XML_Char): Int32u;
begin
{$IFDEF XML_UNICODE}
  Result := (H * $F4243) xor Int16u(C);
{$ELSE }
  Result := (H * $F4243) xor Int8u(C);
{$ENDIF }
end;

function MUSRasterizerConverterERT(Enc: ENCODING_ptr; S: PAnsiChar): Integer;
begin
{$IFDEF XML_UNICODE}
  Result := Integer(not Boolean(Enc.IsUtf16) or Boolean(Int32u(S) and 1));
{$ELSE }
  Result := Integer(not Boolean(Enc.IsUtf8));
{$ENDIF }
end;

{ For probing (after a collision) we need a step size relative prime
  to the hash table size, which is a power of 2. We use double-hashing,
  since we can calculate a second hash value cheaply by taking those bits
  of the first hash value that were discarded (masked out) when the table
  index was calculated: index:=hash and mask, where mask:=table.size - 1.
  We limit the maximum step size to table.size div 4 (mask shr 2 ) and make
  it odd, since odd numbers are always relative prime to a power of 2. }
function SECOND_HASH(Hash, Mask: Int32u; Power: Int8u): Int8u;
begin
  Result := ((Hash and not Mask) shr (Power - 1)) and (Mask shr 2);
end;

function PROBE_STEP(Hash, Mask: Int32u; Power: Int8u): Int8u;
begin
  Result := SECOND_HASH(Hash, Mask, Power) or 1;
end;

function XML_T(X: AnsiChar): XML_Char;
begin
  Result := X;
end;

function XML_L(X: AnsiChar): XML_Char;
begin
  Result := X;
end;

{ Round up n to be a multiple of sz, where sz is a power of 2. }
function ROUND_UP(N, Sz: Integer): Integer;
begin
  Result := (N + (Sz - 1)) and not (Sz - 1);
end;

procedure XmlConvert(Enc: ENCODING_ptr; FromP, FromLim, ToP, ToLim: Pointer);
begin
{$IFDEF XML_UNICODE}
  XmlUtf16Convert(Enc, FromP, FromLim, ToP, ToLim);
{$ELSE }
  XmlUtf8Convert(Enc, FromP, FromLim, ToP, ToLim);
{$ENDIF }
end;

function XmlEncode(CharNumber: Integer; Buf: Pointer): Integer;
begin
{$IFDEF XML_UNICODE}
  Result := XmlUtf16Encode(CharNumber, Buf);
{$ELSE }
  Result := XmlUtf8Encode(CharNumber, Buf);
{$ENDIF }
end;

procedure PoolInit(Pool: PStringPool; Ms: PXmlMemoryHandlingSuite);
begin
  Pool.Blocks := nil;
  Pool.FreeBlocks := nil;
  Pool.Start := nil;
  Pool.Ptr := nil;
  Pool.End_ := nil;
  Pool.Mem := Ms;
end;

procedure HashTableDestroy(Table: PHashTable);
var
  I: Size_t;
begin
  I := 0;

  while I < Table.Size do
  begin
    if PPNamed(PtrComp(Table.V) + I * SizeOf(PNamed))^ <> nil then
      Table.Mem.Free_fcn(Pointer(PPNamed(PtrComp(Table.V) + I *
        SizeOf(PNamed))^), PPNamed(PtrComp(Table.V) + I *
        SizeOf(PNamed))^^.Alloc);

    Inc(I);
  end;

  Table.Mem.Free_fcn(Pointer(Table.V), Table.A);
end;

procedure HashTableInit(P: PHashTable; Ms: PXmlMemoryHandlingSuite);
begin
  P.Power := 0;
  P.Size := 0;
  P.Used := 0;
  P.V := nil;
  P.Mem := Ms;
end;

procedure HashTableIterInit(Iter: PHashTableIter; Table: PHashTable);
begin
  Iter.P := Table.V;
  Iter.Stop := PPNamed(PtrComp(Iter.P) + Table.Size * SizeOf(PNamed));
end;

function HashTableIterNext(Iter: PHashTableIter): PNamed;
var
  Tem: PNamed;
begin
  while Iter.P <> Iter.Stop do
  begin
    Tem := Iter.P^;

    Inc(PtrComp(Iter.P), SizeOf(PNamed));

    if Tem <> nil then
    begin
      Result := Tem;
      Exit;
    end;
  end;
  Result := nil;
end;

function DtdCreate(Ms: PXmlMemoryHandlingSuite): DTD_ptr;
var
  P: DTD_ptr;
begin
  Ms.Malloc_fcn(Pointer(P), SizeOf(DTD));

  if P = nil then
  begin
    Result := P;

    Exit;
  end;

  PoolInit(@P.Pool, Ms);
  PoolInit(@P.EntityValuePool, Ms);

  HashTableInit(@P.GeneralEntities, Ms);
  HashTableInit(@P.ElementTypes, Ms);
  HashTableInit(@P.AttributeIds, Ms);
  HashTableInit(@P.Prefixes, Ms);

{$IFDEF XML_DTD}
  P.ParamEntityRead := CXmlFalse;
  HashTableInit(@P.ParamEntities, Ms);
{$ENDIF }

  P.DefaultPrefix.Name := nil;
  P.DefaultPrefix.TBinding := nil;

  P.In_eldecl := CXmlFalse;
  P.ScaffIndex := nil;
  P.ScaffAlloc := 0;
  P.Scaffold := nil;
  P.ScaffLevel := 0;
  P.ScaffSize := 0;
  P.ScaffCount := 0;
  P.ContentStringLen := 0;

  P.KeepProcessing := CXmlTrue;
  P.HasParamEntityRefs := CXmlFalse;
  P.Standalone := CXmlFalse;

  Result := P;
end;

procedure DtdDestroy(P: DTD_ptr; IsDocEntity: XML_Bool;
  Ms: PXmlMemoryHandlingSuite);
var
  Iter: THashTableIter;
  E: PElementType;
begin
  HashTableIterInit(@Iter, @P.ElementTypes);

  repeat
    E := PElementType(HashTableIterNext(@Iter));

    if E = nil then
      Break;

    if E.AllocDefaultAtts <> 0 then
      Ms.Free_fcn(Pointer(E.DefaultAtts), E.DefaultAttsAlloc);
  until False;

  HashTableDestroy(@P.GeneralEntities);

{$IFDEF XML_DTD }
  HashTableDestroy(@P.ParamEntities);
{$ENDIF }

  HashTableDestroy(@P.ElementTypes);
  HashTableDestroy(@P.AttributeIds);
  HashTableDestroy(@P.Prefixes);

  PoolDestroy(@P.Pool);
  PoolDestroy(@P.EntityValuePool);

  if IsDocEntity <> 0 then
  begin
    Ms.Free_fcn(Pointer(P.ScaffIndex), P.ScaffAlloc);
    Ms.Free_fcn(Pointer(P.Scaffold), SizeOf(TContentScaffold));
  end;

  Ms.Free_fcn(Pointer(P), SizeOf(DTD));
end;

function HandleUnknownEncoding(Parser: XML_Parser; EncodingName: XML_PAnsiChar)
  : XML_Error;
begin
end;

function InitializeEncoding(Parser: XML_Parser): XML_Error;
var
  S : PAnsiChar;
  Ok: Integer;
begin
{$IFDEF XML_UNICODE {..}
{$ELSE }
  S := Pointer(Parser.ProtocolEncodingName);
{$ENDIF }

  if Parser.M_ns <> 0 then
    Ok := XmlInitEncodingNS(@Parser.InitEncoding, @Parser.Encoding,
      Pointer(S))
  else
    Ok := XmlInitEncoding(@Parser.InitEncoding, @Parser.Encoding,
      Pointer(S));

  if Ok <> 0 then
    Result := XML_ERROR_NONE
  else
    Result := HandleUnknownEncoding(Parser, Parser.ProtocolEncodingName);
end;

procedure ReportDefault(Parser: XML_Parser; Enc: ENCODING_ptr;
  Start, Stop: PAnsiChar);
begin
end;

function GetContext(Parser: XML_Parser): XML_PAnsiChar;
begin
end;

function ProcessXmlDecl(Parser: XML_Parser; IsGeneralTextEntity: Integer;
  S, Next: PAnsiChar): XML_Error;
var
  EncodingName, Version, Versionend: PAnsiChar;
  StoredEncName, Storedversion: XML_PAnsiChar;
  NewEncoding: ENCODING_ptr;
  Standalone, Ok: Integer;
  Result_: XML_Error;
begin
  EncodingName := nil;
  StoredEncName := nil;
  NewEncoding := nil;
  Version := nil;
  Storedversion := nil;
  Standalone := -1;

  if Parser.M_ns <> 0 then
    Ok := XmlParseXmlDeclNS(IsGeneralTextEntity, Parser.Encoding, Pointer(S),
      Pointer(Next), @Parser.EventPtr, @Version, @Versionend, @EncodingName,
      @NewEncoding, @Standalone)
  else
    Ok := XmlParseXmlDecl(IsGeneralTextEntity, Parser.Encoding, Pointer(S),
      Pointer(Next), @Parser.EventPtr, @Version, @Versionend, @EncodingName,
      @NewEncoding, @Standalone);

  if Ok = 0 then
    if IsGeneralTextEntity <> 0 then
    begin
      Result := XML_ERROR_TEXT_DECL;

      Exit;
    end
    else
    begin
      Result := XML_ERROR_XML_DECL;

      Exit;
    end;

  if (IsGeneralTextEntity = 0) and (Standalone = 1) then
  begin
    Parser.M_dtd.Standalone := CXmlTrue;

{$IFDEF XML_DTD }
    if Parser.ParamEntityParsing = XML_PARAM_ENTITY_PARSING_UNLESS_STANDALONE
    then
      Parser.ParamEntityParsing := XML_PARAM_ENTITY_PARSING_NEVER;
{$ENDIF }
  end;

  if @Parser.XmlDeclHandler <> nil then
  begin
    if EncodingName <> nil then
    begin
      StoredEncName := PoolStoreString(@Parser.M_temp2Pool, Parser.Encoding,
        EncodingName, PAnsiChar(PtrComp(EncodingName) +
        XmlNameLength(Parser.Encoding, Pointer(EncodingName))));

      if StoredEncName = nil then
      begin
        Result := XML_ERROR_NO_MEMORY;

        Exit;
      end;

      PoolFinish(@Parser.M_temp2Pool);
    end;

    if Version <> nil then
    begin
      Storedversion := PoolStoreString(@Parser.M_temp2Pool, Parser.Encoding,
        Version, PAnsiChar(PtrComp(Versionend) -
        Parser.Encoding.MinBytesPerChar));

      if Storedversion = nil then
      begin
        Result := XML_ERROR_NO_MEMORY;

        Exit;
      end;
    end;

    Parser.XmlDeclHandler(Parser.HandlerArg, Storedversion, StoredEncName,
      Standalone);
  end
  else if @Parser.DefaultHandler <> nil then
    ReportDefault(Parser, Parser.Encoding, S, Next);

  if Parser.ProtocolEncodingName = nil then
  begin
    if NewEncoding <> nil then
    begin
      if NewEncoding.MinBytesPerChar <> Parser.Encoding.MinBytesPerChar then
      begin
        Parser.EventPtr := EncodingName;

        Result := XML_ERROR_INCORRECT_ENCODING;

        Exit;
      end;

      Parser.Encoding := NewEncoding;
    end
    else if EncodingName <> nil then
    begin
      if StoredEncName = nil then
      begin
        StoredEncName := PoolStoreString(@Parser.M_temp2Pool, Parser.Encoding,
          EncodingName, PAnsiChar(PtrComp(EncodingName) +
          XmlNameLength(Parser.Encoding, Pointer(EncodingName))));

        if StoredEncName = nil then
        begin
          Result := XML_ERROR_NO_MEMORY;

          Exit;
        end;
      end;

      Result_ := HandleUnknownEncoding(Parser, StoredEncName);

      PoolClear(@Parser.M_temp2Pool);

      if Result_ = XML_ERROR_UNKNOWN_ENCODING then
        Parser.EventPtr := EncodingName;

      Result := Result_;
      Exit;
    end;
  end;

  if (StoredEncName <> nil) or (Storedversion <> nil) then
    PoolClear(@Parser.M_temp2Pool);

  Result := XML_ERROR_NONE;
end;

procedure PoolClear(Pool: PStringPool);
var
  P, Tem: PBlock;
begin
  if Pool.FreeBlocks = nil then
    Pool.FreeBlocks := Pool.Blocks

  else
  begin
    P := Pool.Blocks;

    while P <> nil do
    begin
      Tem := P.Next;
      P.Next := Pool.FreeBlocks;
      Pool.FreeBlocks := P;
      P := Tem;
    end;
  end;

  Pool.Blocks := nil;
  Pool.Start := nil;
  Pool.Ptr := nil;
  Pool.End_ := nil;
end;

procedure PoolDestroy(Pool: PStringPool);
var
  P, Tem: PBlock;
begin
  P := Pool.Blocks;

  while P <> nil do
  begin
    Tem := P.Next;

    Pool.Mem.Free_fcn(Pointer(P), P.Alloc);

    P := Tem;
  end;

  P := Pool.FreeBlocks;

  while P <> nil do
  begin
    Tem := P.Next;

    Pool.Mem.Free_fcn(Pointer(P), P.Alloc);

    P := Tem;
  end;
end;

function PoolGrow(Pool: PStringPool): XML_Bool;
var
  Tem: PBlock;
  BlockSize: Integer;
begin
  if Pool.FreeBlocks <> nil then
  begin
    if Pool.Start = nil then
    begin
      Pool.Blocks := Pool.FreeBlocks;
      Pool.FreeBlocks := Pool.FreeBlocks.Next;
      Pool.Blocks.Next := nil;

      Pool.Start := @Pool.Blocks.S;
      Pool.End_ := XML_PAnsiChar(PtrComp(Pool.Start) + Pool.Blocks.Size *
        SizeOf(XML_Char));
      Pool.Ptr := Pool.Start;

      Result := CXmlTrue;

      Exit;
    end;

    if PtrComp(Pool.End_) - PtrComp(Pool.Start) < Pool.FreeBlocks.Size then
    begin
      Tem := Pool.FreeBlocks.Next;

      Pool.FreeBlocks.Next := Pool.Blocks;
      Pool.Blocks := Pool.FreeBlocks;
      Pool.FreeBlocks := Tem;

      Move(Pool.Start^, Pointer(@Pool.Blocks.S)^, PtrComp(Pool.End_) -
        PtrComp(Pool.Start));

      Pool.Ptr := XML_PAnsiChar(PtrComp(@Pool.Blocks.S) + PtrComp(Pool.Ptr) -
        PtrComp(Pool.Start));
      Pool.Start := @Pool.Blocks.S;
      Pool.End_ := XML_PAnsiChar(PtrComp(Pool.Start) + Pool.Blocks.Size *
        SizeOf(XML_Char));

      Result := CXmlTrue;

      Exit;
    end;
  end;

  if (Pool.Blocks <> nil) and (Pool.Start = @Pool.Blocks.S) then
  begin
    BlockSize := (PtrComp(Pool.End_) - PtrComp(Pool.Start)) *
      2 div SizeOf(XML_Char);

    Pool.Mem.Realloc_fcn(Pointer(Pool.Blocks), Pool.Blocks.Alloc,
      (SizeOf(PBlock) + SizeOf(Integer) * 2) + BlockSize * SizeOf(XML_Char));

    if Pool.Blocks = nil then
    begin
      Result := CXmlFalse;

      Exit;
    end
    else
      Pool.Blocks.Alloc := (SizeOf(PBlock) + SizeOf(Integer) * 2) + BlockSize *
        SizeOf(XML_Char);

    Pool.Blocks.Size := BlockSize;

    Pool.Ptr := XML_PAnsiChar(PtrComp(@Pool.Blocks.S) +
      (PtrComp(Pool.Ptr) - PtrComp(Pool.Start)));
    Pool.Start := @Pool.Blocks.S;
    Pool.End_ := XML_PAnsiChar(PtrComp(Pool.Start) + BlockSize *
      SizeOf(XML_Char));
  end
  else
  begin
    BlockSize := (PtrComp(Pool.End_) - PtrComp(Pool.Start))
      div SizeOf(XML_Char);

    if BlockSize < INIT_BLOCK_SIZE then
      BlockSize := INIT_BLOCK_SIZE
    else
      BlockSize := BlockSize * 2;

    Pool.Mem.Malloc_fcn(Pointer(Tem), (SizeOf(PBlock) + SizeOf(Integer) * 2) +
      BlockSize * SizeOf(XML_Char));

    if Tem = nil then
    begin
      Result := CXmlFalse;

      Exit;
    end;

    Tem.Size := BlockSize;
    Tem.Alloc := (SizeOf(PBlock) + SizeOf(Integer) * 2) + BlockSize *
      SizeOf(XML_Char);
    Tem.Next := Pool.Blocks;

    Pool.Blocks := Tem;

    if Pool.Ptr <> Pool.Start then
      Move(Pool.Start^, Pointer(@Tem.S)^, PtrComp(Pool.Ptr) -
        PtrComp(Pool.Start));

    Pool.Ptr := XML_PAnsiChar(PtrComp(@Tem.S) +
      (PtrComp(Pool.Ptr) - PtrComp(Pool.Start)) * SizeOf(XML_Char));
    Pool.Start := @Tem.S;
    Pool.End_ := XML_PAnsiChar(PtrComp(@Tem.S) + BlockSize * SizeOf(XML_Char));
  end;

  Result := CXmlTrue;
end;

function PoolAppend(Pool: PStringPool; Enc: ENCODING_ptr;
  Ptr, Stop: PAnsiChar): XML_PAnsiChar;
begin
  if (Pool.Ptr = nil) and (PoolGrow(Pool) = 0) then
  begin
    Result := nil;

    Exit;
  end;

  repeat
    XmlConvert(Enc, @Ptr, Stop, IPPAnsiChar(@Pool.Ptr), IPAnsiChar(Pool.End_));

    if Ptr = Stop then
      Break;

    if PoolGrow(Pool) = 0 then
      Result := nil;
  until False;

  Result := Pool.Start;
end;

function PoolStoreString(Pool: PStringPool; Enc: ENCODING_ptr;
  Ptr, Stop: PAnsiChar): XML_PAnsiChar;
begin
  if PoolAppend(Pool, Enc, Ptr, Stop) = nil then
  begin
    Result := nil;

    Exit;
  end;

  if (Pool.Ptr = Pool.End_) and (PoolGrow(Pool) = 0) then
  begin
    Result := nil;

    Exit;
  end;

  Pool.Ptr^ := XML_Char(0);
  Inc(PtrComp(Pool.Ptr));
  Result := Pool.Start;
end;

function PoolCopyString(Pool: PStringPool; S: XML_PAnsiChar): XML_PAnsiChar;
label
  _w0;

begin
  goto _w0;

  while S^ <> XML_Char(0) do
  begin
  _w0:
    if PoolAppendChar(Pool, S^) = 0 then
    begin
      Result := nil;

      Exit;
    end;

    Inc(PtrComp(S), SizeOf(XML_Char));
  end;

  S := Pool.Start;
  PoolFinish(Pool);
  Result := S;
end;

function PoolAppendString(Pool: PStringPool; S: XML_PAnsiChar)
  : XML_PAnsiChar;
begin
end;

function PoolStart(Pool: PStringPool): XML_PAnsiChar;
begin
  Result := Pool.Start;
end;

function PoolLength(Pool: PStringPool): Integer;
begin
  Result := PtrComp(Pool.Ptr) - PtrComp(Pool.Start);
end;

procedure PoolChop(Pool: PStringPool);
begin
  Dec(PtrComp(Pool.Ptr), SizeOf(XML_Char));
end;

function PoolLastChar(Pool: PStringPool): XML_Char;
begin
  Result := XML_PAnsiChar(PtrComp(Pool.Ptr) - 1 * SizeOf(XML_Char))^;
end;

procedure PoolDiscard(Pool: PStringPool);
begin
  Pool.Ptr := Pool.Start;
end;

procedure PoolFinish(Pool: PStringPool);
begin
  Pool.Start := Pool.Ptr;
end;

function PoolAppendChar(Pool: PStringPool; C: AnsiChar): Integer;
begin
  if (Pool.Ptr = Pool.End_) and (PoolGrow(Pool) = 0) then
    Result := 0
  else
  begin
    Pool.Ptr^ := C;

    Inc(PtrComp(Pool.Ptr));

    Result := 1;
  end;
end;

function Keyeq(S1, S2: KEY): XML_Bool;
begin
  while S1^ = S2^ do
  begin
    if S1^ = #0 then
    begin
      Result := CXmlTrue;

      Exit;
    end;

    Inc(PtrComp(S1), SizeOf(XML_Char));
    Inc(PtrComp(S2), SizeOf(XML_Char));
  end;

  Result := CXmlFalse;
end;

function Hash(S: KEY): Int32u;
var
  H: Int32u;
begin
  H := 0;

  while S^ <> XML_Char(0) do
  begin
    H := CHAR_HASH(H, S^);

    Inc(PtrComp(S), SizeOf(XML_Char));
  end;

  Result := H;
end;

function Lookup(Table: PHashTable; Name: KEY; CreateSize: Size_t)
  : PNamed;
var
  I, Tsize, NewSize, J: Size_t;
  H, Mask, NewMask, NewHash: Int32u;
  Step, NewPower: Int8u;
  NewV: PPNamed;
begin
  if Table.Size = 0 then
  begin
    if CreateSize = 0 then
    begin
      Result := nil;

      Exit;
    end;

    Table.Power := INIT_POWER;

    { table->size is a power of 2 }
    Table.Size := Size_t(1 shl INIT_POWER);

    Tsize := Table.Size * SizeOf(PNamed);

    Table.Mem.Malloc_fcn(Pointer(Table.V), Tsize);

    if Table.V = nil then
    begin
      Table.Size := 0;

      Result := nil;

      Exit;
    end
    else
      Table.A := Tsize;

    FillChar(Table.V^, Tsize, 0);

    I := Hash(name) and (Table.Size - 1);
  end
  else
  begin
    H := Hash(name);
    Mask := Table.Size - 1;
    Step := 0;
    I := H and Mask;

    while PPNamed(PtrComp(Table.V) + I * SizeOf(PNamed))^ <> nil do
    begin
      if Keyeq(name, PPNamed(PtrComp(Table.V) + I * SizeOf(PNamed))
        ^^.Name) <> 0 then
      begin
        Result := PPNamed(PtrComp(Table.V) + I * SizeOf(PNamed))^;

        Exit;
      end;

      if Step = 0 then
        Step := PROBE_STEP(H, Mask, Table.Power);

      if I < Step then
        Inc(I, Table.Size - Step)
      else
        Dec(I, Step);
    end;

    if CreateSize = 0 then
    begin
      Result := nil;

      Exit;
    end;

    { check for overfLow (table is half full) }
    if Table.Used shr (Table.Power - 1) <> 0 then
    begin
      NewPower := Table.Power + 1;
      NewSize := Size_t(1 shl NewPower);
      NewMask := NewSize - 1;
      Tsize := NewSize * SizeOf(PNamed);

      Table.Mem.Malloc_fcn(Pointer(NewV), Tsize);

      if NewV = nil then
      begin
        Result := nil;

        Exit;
      end;

      FillChar(NewV^, Tsize, 0);

      I := 0;

      while I < Table.Size do
      begin
        if PPNamed(PtrComp(Table.V) + I * SizeOf(PNamed))^ <> nil then
        begin
          NewHash := Hash(PPNamed(PtrComp(Table.V) + I * SizeOf(PNamed)
            )^^.Name);
          J := NewHash and NewMask;
          Step := 0;

          while PPNamed(PtrComp(NewV) + J * SizeOf(PNamed))^ <> nil do
          begin
            if Step = 0 then
              Step := PROBE_STEP(NewHash, NewMask, NewPower);

            if J < Step then
              Inc(J, NewSize - Step)
            else
              Dec(J, Step);
          end;

          PPNamed(PtrComp(NewV) + J * SizeOf(PNamed))^ :=
            PPNamed(PtrComp(Table.V) + I * SizeOf(PNamed))^;
        end;

        Inc(I);
      end;

      Table.Mem.Free_fcn(Pointer(Table.V), Table.A);

      Table.V := NewV;
      Table.A := Tsize;
      Table.Power := NewPower;
      Table.Size := NewSize;

      I := H and NewMask;
      Step := 0;

      while PPNamed(PtrComp(Table.V) + I * SizeOf(PNamed))^ <> nil do
      begin
        if Step = 0 then
          Step := PROBE_STEP(H, NewMask, NewPower);

        if I < Step then
          Inc(I, NewSize - Step)
        else
          Dec(I, Step);
      end;
    end;
  end;

  Table.Mem.Malloc_fcn(Pointer(PPNamed(PtrComp(Table.V) + I *
    SizeOf(PNamed))^), CreateSize);

  if PPNamed(PtrComp(Table.V) + I * SizeOf(PNamed))^ = nil then
  begin
    Result := nil;

    Exit;
  end;

  FillChar(PPNamed(PtrComp(Table.V) + I * SizeOf(PNamed))^^,
    CreateSize, 0);

  PPNamed(PtrComp(Table.V) + I * SizeOf(PNamed))^^.Name := name;
  PPNamed(PtrComp(Table.V) + I * SizeOf(PNamed))^^.Alloc := CreateSize;

  Inc(Table.Used);

  Result := PPNamed(PtrComp(Table.V) + I * SizeOf(PNamed))^;
end;

procedure NormalizePublicId(PublicId: XML_PAnsiChar);
var
  P, S: XML_PAnsiChar;

begin
  P := PublicId;
  S := PublicId;

  while S^ <> XML_Char(0) do
  begin
    case S^ of
      XML_Char($20), XML_Char($D), XML_Char($A):
        if (P <> PublicId) and (XML_PAnsiChar(PtrComp(P) - 1 * SizeOf(XML_Char))
          ^ <> XML_Char($20)) then
        begin
          P^ := XML_Char($20);

          Inc(PtrComp(P), SizeOf(XML_Char));
        end;

    else
      begin
        P^ := S^;

        Inc(PtrComp(P), SizeOf(XML_Char));
      end;
    end;

    Inc(PtrComp(S), SizeOf(XML_Char));
  end;

  if (P <> PublicId) and (XML_PAnsiChar(PtrComp(P) - 1 * SizeOf(XML_Char))
    ^ = XML_Char($20)) then
    Dec(PtrComp(P), SizeOf(XML_Char));

  P^ := XML_T(#0);
end;

function SetElementTypePrefix(Parser: XML_Parser;
  ElementType: PElementType): Integer;
begin
end;

{ addBinding overwrites the value of TPrefix.TBinding without checking.
  Therefore one must keep track of the old value outside of addBinding. }
function AddBinding(Parser: XML_Parser; TPrefix: PPrefix;
  AttId: PAttributeID; Uri: XML_PAnsiChar; BindingsPtr: PPBinding)
  : XML_Error;
begin
end;

{ Initially tag.rawName always points into the parse buffer;
  for those TAG instances opened while the current parse buffer was
  processed, and not yet closed, we need to store tag.rawName in a more
  permanent location, since the parse buffer is about to be discarded. }
function StoreRawNames(Parser: XML_Parser): XML_Bool;
var
  Tag: TAG_ptr;
  BufSize, NameLen: Integer;
  RawNameBuf, Temp: PAnsiChar;
begin
  Tag := Parser.TagStack;

  while Tag <> nil do
  begin
    NameLen := SizeOf(XML_Char) * (Tag.Name.StrLen + 1);
    RawNameBuf := PAnsiChar(PtrComp(Tag.Buf) + NameLen);

    { Stop if already stored. Since tagStack is a stack, we can stop
      at the first entry that has already been copied; everything
      below it in the stack is already been accounted for in a
      previous call to this function. }
    if Tag.RawName = RawNameBuf then
      Break;

    { For re-use purposes we need to ensure that the
      size of tag.buf is a multiple of SizeOf(XML_Char ). }
    BufSize := NameLen + ROUND_UP(Tag.RawNameLength, SizeOf(XML_Char));

    if BufSize > PtrComp(Tag.BufEnd) - PtrComp(Tag.Buf) then
    begin
      if Parser.Mem.Realloc_fcn(Pointer(Tag.Buf), Tag.Alloc, BufSize) then
        Temp := Tag.Buf
      else
        Temp := nil;

      if Temp = nil then
      begin
        Result := CXmlFalse;

        Exit;

      end;

      Tag.Alloc := BufSize;

      { if tag.name.str points to tag.buf (only when namespace
        processing is off) then we have to update it }
      if Tag.Name.Str = XML_PAnsiChar(Tag.Buf) then
        Tag.Name.Str := XML_PAnsiChar(Temp);

      { if tag->name.localPart is set (when namespace processing is on)
        then update it as well, since it will always point into tag->buf }
      if Tag.Name.LocalPart <> nil then
        Tag.Name.LocalPart :=
          XML_PAnsiChar(PtrComp(Temp) + (PtrComp(Tag.Name.LocalPart) -
          PtrComp(Tag.Buf)));

      Tag.Buf := Temp;
      Tag.BufEnd := PAnsiChar(PtrComp(Temp) + BufSize);
      RawNameBuf := PAnsiChar(PtrComp(Temp) + NameLen);

    end;

    Move(Tag.RawName^, RawNameBuf^, Tag.RawNameLength);

    Tag.RawName := RawNameBuf;
    Tag := Tag.Parent;

  end;

  Result := CXmlTrue;

end;

{ Precondition: all arguments must be non-NULL;
  Purpose:
  - normalize attributes
  - check attributes for well-formedness
  - generate namespace aware attribute names (URI, TPrefix)
  - build list of attributes for startElementHandler
  - default attributes
  - process namespace declarations (check and report them)
  - generate namespace aware element name (URI, TPrefix) }
function StoreAtts(Parser: XML_Parser; Enc: ENCODING_ptr; AttStr: PAnsiChar;
  TagNamePtr: PTagName; BindingsPtr: PPBinding): XML_Error;
var
  Dtd: DTD_ptr;

  ElementType: PElementType;

  NDefaultAtts, AttIndex, PrefixLen, I, N, NPrefixes, OldAttsSize, J,
    NsAttsSize: Integer;

  Version, UriHash, Mask: Int32u;

  Step: Int8u;

  AppAtts: XML_PPAnsiChar; { the attribute list for the application }

  Uri, LocalPart, Name, S, S1, S2: XML_PAnsiChar;

  C: XML_Char;

  TBinding, B: PBinding;

  AttId, Id: PAttributeID;

  Result_: XML_Error;

  IsCdata: XML_Bool;

  Da: PDefaultAttribute;

  P: TAG_ptr;

label
  _w0, _w1;

begin
  Dtd := Parser.M_dtd; { save one level of indirection }

  AttIndex := 0;
  NPrefixes := 0;

  { lookup the element type name }
  ElementType := PElementType(Lookup(@Dtd.ElementTypes, TagNamePtr.Str, 0));

  if ElementType = nil then
  begin
    name := PoolCopyString(@Dtd.Pool, TagNamePtr.Str);

    if name = nil then
    begin
      Result := XML_ERROR_NO_MEMORY;

      Exit;
    end;

    ElementType := PElementType(Lookup(@Dtd.ElementTypes, name,
      SizeOf(TElementType)));

    if ElementType = nil then
    begin
      Result := XML_ERROR_NO_MEMORY;

      Exit;
    end;

    if (Parser.M_ns <> 0) and (SetElementTypePrefix(Parser, ElementType) = 0)
    then
    begin
      Result := XML_ERROR_NO_MEMORY;

      Exit;
    end;
  end;

  NDefaultAtts := ElementType.NDefaultAtts;

  { get the attributes from the tokenizer }
  N := XmlGetAttributes(Enc, Pointer(AttStr), Parser.AttsSize, Parser.Atts);

  if N + NDefaultAtts > Parser.AttsSize then
  begin
    OldAttsSize := Parser.AttsSize;
    Parser.AttsSize := N + NDefaultAtts + INIT_ATTS_SIZE;

    if not Parser.Mem.Realloc_fcn(Pointer(Parser.Atts), Parser.AttsAlloc,
      Parser.AttsSize * SizeOf(ATTRIBUTE)) then
    begin
      Result := XML_ERROR_NO_MEMORY;

      Exit;
    end
    else
      Parser.AttsAlloc := Parser.AttsSize * SizeOf(ATTRIBUTE);

    if N > OldAttsSize then
      XmlGetAttributes(Enc, Pointer(AttStr), N, Parser.Atts);
  end;

  AppAtts := XML_PPAnsiChar(Parser.Atts);

  I := 0;

  while I < N do
  begin
    { add the name and value to the attribute list }
    AttId := GetAttributeId(Parser, Enc,
      Pointer(ATTRIBUTE_ptr(PtrComp(Parser.Atts) + I * SizeOf(ATTRIBUTE))
      ^.Name), Pointer(PtrComp(ATTRIBUTE_ptr(PtrComp(Parser.Atts) + I *
      SizeOf(ATTRIBUTE))^.Name) + XmlNameLength(Enc,
      ATTRIBUTE_ptr(PtrComp(Parser.Atts) + I * SizeOf(ATTRIBUTE))^.Name)));

    if AttId = nil then
    begin
      Result := XML_ERROR_NO_MEMORY;

      Exit;
    end;

    { Detect duplicate attributes by their QNames. This does not work when
      namespace processing is turned on and different prefixes for the same
      namespace are used. For this case we have a check further down. }
    if XML_PAnsiChar(PtrComp(AttId.Name) - 1 * SizeOf(XML_Char))^ <> XML_Char(0)
    then
    begin
      if Enc = Parser.Encoding then
        Parser.EventPtr :=
          Pointer(ATTRIBUTE_ptr(PtrComp(Parser.Atts) + I *
          SizeOf(ATTRIBUTE))^.Name);

      Result := XML_ERROR_DUPLICATE_ATTRIBUTE;

      Exit;
    end;

    XML_PAnsiChar(PtrComp(AttId.Name) - 1 * SizeOf(XML_Char))^ := XML_Char(1);

    XML_PPAnsiChar(PtrComp(AppAtts) + AttIndex * SizeOf(XML_PAnsiChar))^ :=
      AttId.Name;

    Inc(AttIndex);

    if ATTRIBUTE_ptr(PtrComp(Parser.Atts) + I * SizeOf(ATTRIBUTE))
      ^.Normalized = #0 then
    begin
      IsCdata := CXmlTrue;

      { figure out whether declared as other than CDATA }
      if AttId.MaybeTokenized <> 0 then
      begin
        J := 0;

        while J < NDefaultAtts do
        begin
          if AttId = PDefaultAttribute(PtrComp(ElementType.DefaultAtts) + J
            * SizeOf(TDefaultAttribute))^.Id then
          begin
            IsCdata := PDefaultAttribute(PtrComp(ElementType.DefaultAtts) +
              J * SizeOf(TDefaultAttribute))^.IsCdata;

            Break;
          end;

          Inc(J);
        end;
      end;

      { normalize the attribute value }
      Result_ := StoreAttributeValue(Parser, Enc, IsCdata,
        Pointer(ATTRIBUTE_ptr(PtrComp(Parser.Atts) + I * SizeOf(ATTRIBUTE))
        ^.ValuePtr), Pointer(ATTRIBUTE_ptr(PtrComp(Parser.Atts) + I *
        SizeOf(ATTRIBUTE))^.ValueEnd), @Parser.TempPool);

      if Result_ <> XML_Error(0) then
      begin
        Result := Result_;

        Exit;
      end;

      XML_PPAnsiChar(PtrComp(AppAtts) + AttIndex * SizeOf(XML_PAnsiChar))^ :=
        PoolStart(@Parser.TempPool);

      PoolFinish(@Parser.TempPool);
    end
    else
    begin
      { the value did not need normalizing }
      XML_PPAnsiChar(PtrComp(AppAtts) + AttIndex * SizeOf(XML_PAnsiChar))^ :=
        PoolStoreString(@Parser.TempPool, Enc,
        Pointer(ATTRIBUTE_ptr(PtrComp(Parser.Atts) + I * SizeOf(ATTRIBUTE))
        ^.ValuePtr), Pointer(ATTRIBUTE_ptr(PtrComp(Parser.Atts) + I *
        SizeOf(ATTRIBUTE))^.ValueEnd));

      if XML_PPAnsiChar(PtrComp(AppAtts) + AttIndex * SizeOf(XML_PAnsiChar))^ = nil
      then
      begin
        Result := XML_ERROR_NO_MEMORY;

        Exit;
      end;

      PoolFinish(@Parser.TempPool);
    end;

    { handle prefixed attribute names }
    if AttId.TPrefix <> nil then
      if AttId.Xmlns <> 0 then
      begin
        { deal with namespace declarations here }
        Result_ := AddBinding(Parser, AttId.TPrefix, AttId,
          XML_PPAnsiChar(PtrComp(AppAtts) + AttIndex * SizeOf(XML_PAnsiChar))^,
          BindingsPtr);

        if Result_ <> XML_Error(0) then
        begin
          Result := Result_;

          Exit;
        end;

        Dec(AttIndex);
      end
      else
      begin
        { deal with other prefixed names later }
        Inc(AttIndex);
        Inc(NPrefixes);

        XML_PAnsiChar(PtrComp(AttId.Name) - 1 * SizeOf(XML_Char))^ :=
          XML_Char(2);
      end
    else
      Inc(AttIndex);

    Inc(I);
  end;

  { set-up for XML_GetSpecifiedAttributeCount and XML_GetIdAttributeIndex }
  Parser.M_nSpecifiedAtts := AttIndex;

  if (ElementType.IdAtt <> nil) and
    (XML_PAnsiChar(PtrComp(ElementType.IdAtt.Name) - 1 * SizeOf(XML_Char))^ <>
    XML_Char(0)) then
  begin
    I := 0;

    while I < AttIndex do
    begin
      if XML_PPAnsiChar(PtrComp(AppAtts) + I * SizeOf(XML_PAnsiChar))
        ^ = ElementType.IdAtt.Name then
      begin
        Parser.IdAttIndex := I;

        Break;
      end;

      Inc(I, 2);
    end;
  end
  else
    Parser.IdAttIndex := -1;

  { do attribute defaulting }
  I := 0;

  while I < NDefaultAtts do
  begin
    Da := PDefaultAttribute(PtrComp(ElementType.DefaultAtts) + I *
      SizeOf(TDefaultAttribute));

    if (XML_PAnsiChar(PtrComp(Da.Id.Name) - 1 * SizeOf(XML_Char))^ = XML_Char(0)
      ) and (Da.Value <> nil) then
      if Da.Id.TPrefix <> nil then
        if Da.Id.Xmlns <> 0 then
        begin
          Result_ := AddBinding(Parser, Da.Id.TPrefix, Da.Id, Da.Value,
            BindingsPtr);

          if Result_ <> XML_Error(0) then
          begin
            Result := Result_;

            Exit;
          end;
        end
        else
        begin
          XML_PAnsiChar(PtrComp(Da.Id.Name) - 1 * SizeOf(XML_Char))^ :=
            XML_Char(2);

          Inc(NPrefixes);

          XML_PPAnsiChar(PtrComp(AppAtts) + AttIndex * SizeOf(XML_PAnsiChar))^
            := Da.Id.Name;

          Inc(AttIndex);

          XML_PPAnsiChar(PtrComp(AppAtts) + AttIndex * SizeOf(XML_PAnsiChar))^
            := Da.Value;

          Inc(AttIndex);
        end
      else
      begin
        XML_PAnsiChar(PtrComp(Da.Id.Name) - 1 * SizeOf(XML_Char))^ :=
          XML_Char(1);

        XML_PPAnsiChar(PtrComp(AppAtts) + AttIndex * SizeOf(XML_PAnsiChar))^ :=
          Da.Id.Name;

        Inc(AttIndex);

        XML_PPAnsiChar(PtrComp(AppAtts) + AttIndex * SizeOf(XML_PAnsiChar))^
          := Da.Value;

        Inc(AttIndex);
      end;

    Inc(I);
  end;

  XML_PPAnsiChar(PtrComp(AppAtts) + AttIndex * SizeOf(XML_PAnsiChar))^ := nil;

  { expand prefixed attribute names, check for duplicates,
    and clear flags that say whether attributes were specified }
  I := 0;

  if NPrefixes <> 0 then
  begin
    { j = hash table index }
    Version := Parser.M_nsAttsVersion;
    NsAttsSize := 1 shl Parser.M_nsAttsPower;

    { size of hash table must be at least 2 * (# of prefixed attributes) }
    if ShrInt32(NPrefixes shl 1, Parser.M_nsAttsPower) <> 0
    then { true for nsAttsPower = 0 }
    begin
      { hash table size must also be a power of 2 and >= 8 }
      while ShrInt32(NPrefixes, Parser.M_nsAttsPower) <> 0 do
        Inc(Parser.M_nsAttsPower);

      if Parser.M_nsAttsPower < 3 then
        Parser.M_nsAttsPower := 3;

      NsAttsSize := 1 shl Parser.M_nsAttsPower;

      if not Parser.Mem.Realloc_fcn(Pointer(Parser.M_nsAtts),
        Parser.M_nsAttsAlloc, NsAttsSize * SizeOf(NS_ATT)) then
      begin
        Result := XML_ERROR_NO_MEMORY;

        Exit;

      end
      else
        Parser.M_nsAttsAlloc := NsAttsSize * SizeOf(NS_ATT);

      Version := 0; { force re-initialization of nsAtts hash table }

    end;

    { using a version flag saves us from initializing nsAtts every time }
    if Version = 0 then { initialize version flags when version wraps around }
    begin
      Version := INIT_ATTS_VERSION;

      J := NsAttsSize;

      while J <> 0 do
      begin
        Dec(J);

        NS_ATT_ptr(PtrComp(Parser.M_nsAtts) + J * SizeOf(NS_ATT))^.Version
          := Version;

      end;

    end;

    Dec(Version);

    Parser.M_nsAttsVersion := Version;

    { expand prefixed names and check for duplicates }
    while I < AttIndex do
    begin
      S := XML_PPAnsiChar(PtrComp(AppAtts) + I * SizeOf(XML_PAnsiChar))^;

      if XML_PAnsiChar(PtrComp(S) - 1 * SizeOf(XML_Char))^ = XML_Char(2)
      then { prefixed }
      begin
        UriHash := 0;

        XML_PAnsiChar(PtrComp(S) - 1 * SizeOf(XML_Char))^ := XML_Char(0);
        { clear flag }

        Id := PAttributeID(Lookup(@Dtd.AttributeIds, S, 0));
        B := Id.TPrefix.TBinding;

        if B = nil then
        begin
          Result := XML_ERROR_UNBOUND_PREFIX;

          Exit;
        end;

        { as we expand the name we also calculate its hash value }
        J := 0;

        while J < B.UriLen do
        begin
          C := XML_PAnsiChar(PtrComp(B.Uri) + J * SizeOf(XML_Char))^;

          if PoolAppendChar(@Parser.TempPool, C) = 0 then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

          UriHash := CHAR_HASH(UriHash, C);

          Inc(J);
        end;

        while S^ <> XML_T(':') do
          Inc(PtrComp(S), SizeOf(XML_Char));

        goto _w0;

        while S^ <> XML_Char(0) do { copies null terminator }
        begin
        _w0:
          C := S^;

          if PoolAppendChar(@Parser.TempPool, S^) = 0 then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

          UriHash := CHAR_HASH(UriHash, C);

          Inc(PtrComp(S), SizeOf(XML_Char));
        end;

        { Check hash table for duplicate of expanded name (uriName).
          Derived from code in lookup(THashTable *table, ...). }
        Step := 0;
        Mask := NsAttsSize - 1;
        J := UriHash and Mask; { index into hash table }

        while NS_ATT_ptr(PtrComp(Parser.M_nsAtts) + J * SizeOf(NS_ATT))
          ^.Version = Version do
        begin
          { for speed we compare stored hash values first }
          if UriHash = NS_ATT_ptr(PtrComp(Parser.M_nsAtts) + J * SizeOf(NS_ATT))
            ^.Hash then
          begin
            S1 := PoolStart(@Parser.TempPool);
            S2 := NS_ATT_ptr(PtrComp(Parser.M_nsAtts) + J * SizeOf(NS_ATT)
              )^.UriName;

            { s1 is null terminated, but not s2 }
            while (S1^ = S2^) and (S1^ <> XML_Char(0)) do
            begin
              Inc(PtrComp(S1), SizeOf(XML_Char));
              Inc(PtrComp(S2), SizeOf(XML_Char));

            end;

            if S1^ = XML_Char(0) then
            begin
              Result := XML_ERROR_DUPLICATE_ATTRIBUTE;

              Exit;

            end;

          end;

          if Step = 0 then
            Step := PROBE_STEP(UriHash, Mask, Parser.M_nsAttsPower);

          if J < Step then
            Inc(J, NsAttsSize - Step)
          else
            Dec(J, Step);
        end;

        if Parser.M_ns_triplets <> 0
        then { append namespace separator and TPrefix }
        begin
          XML_PAnsiChar(PtrComp(Parser.TempPool.Ptr) - 1 * SizeOf(XML_Char))^
            := Parser.NamespaceSeparator;

          S := B.TPrefix.Name;

          goto _w1;

          while S^ <> XML_Char(0) do
          begin
          _w1:
            if PoolAppendChar(@Parser.TempPool, S^) = 0 then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            Inc(PtrComp(S), SizeOf(XML_Char));
          end;
        end;

        { store expanded name in attribute list }
        S := PoolStart(@Parser.TempPool);

        PoolFinish(@Parser.TempPool);

        XML_PPAnsiChar(PtrComp(AppAtts) + I * SizeOf(XML_PAnsiChar))^ := S;

        { fill empty slot with new version, uriName and hash value }
        NS_ATT_ptr(PtrComp(Parser.M_nsAtts) + J * SizeOf(NS_ATT))^.Version
          := Version;
        NS_ATT_ptr(PtrComp(Parser.M_nsAtts) + J * SizeOf(NS_ATT))^.Hash
          := UriHash;
        NS_ATT_ptr(PtrComp(Parser.M_nsAtts) + J * SizeOf(NS_ATT))^.UriName := S;

        Dec(NPrefixes);

        if NPrefixes = 0 then
        begin
          Inc(I, 2);

          Break;
        end;
      end
      else { not prefixed }
        XML_PAnsiChar(PtrComp(S) - 1 * SizeOf(XML_Char))^ := XML_Char(0);
      { clear flag }

      Inc(I, 2);
    end;
  end;

  { clear flags for the remaining attributes }
  while I < AttIndex do
  begin
    XML_PAnsiChar(PtrComp(XML_PPAnsiChar(PtrComp(AppAtts) + I *
      SizeOf(XML_PAnsiChar))^) - 1 * SizeOf(XML_Char))^ := XML_Char(0);

    Inc(I, 2);
  end;

  TBinding := BindingsPtr^;

  while TBinding <> nil do
  begin
    XML_PAnsiChar(PtrComp(TBinding.AttId.Name) - 1 * SizeOf(XML_Char))^ :=
      XML_Char(0);

    TBinding := TBinding.NextTagBinding;
  end;

  if Parser.M_ns = 0 then
  begin
    Result := XML_ERROR_NONE;

    Exit;
  end;

  { expand the element type name }
  if ElementType.TPrefix <> nil then
  begin
    TBinding := ElementType.TPrefix.TBinding;

    if TBinding = nil then
    begin
      Result := XML_ERROR_UNBOUND_PREFIX;

      Exit;
    end;

    LocalPart := TagNamePtr.Str;

    while LocalPart^ <> XML_T(':') do
      Inc(PtrComp(LocalPart), SizeOf(XML_Char));

  end
  else if Dtd.DefaultPrefix.TBinding <> nil then
  begin
    TBinding := Dtd.DefaultPrefix.TBinding;
    LocalPart := TagNamePtr.Str;
  end
  else
  begin
    Result := XML_ERROR_NONE;

    Exit;
  end;

  PrefixLen := 0;

  if (Parser.M_ns_triplets <> 0) and (TBinding.TPrefix.Name <> nil) then
  begin
    while XML_PAnsiChar(PtrComp(TBinding.TPrefix.Name) + PrefixLen *
      SizeOf(XML_Char))^ <> XML_Char(0) do
      Inc(PrefixLen);

    Inc(PrefixLen); { prefixLen includes null terminator }
  end;

  TagNamePtr.LocalPart := LocalPart;
  TagNamePtr.UriLen := TBinding.UriLen;
  TagNamePtr.TPrefix := TBinding.TPrefix.Name;
  TagNamePtr.PrefixLen := PrefixLen;

  I := 0;

  while XML_PAnsiChar(PtrComp(LocalPart) + I * SizeOf(XML_Char))^ <>
    XML_Char(0) do
    Inc(I);

  Inc(I); { i includes null terminator }

  N := I + TBinding.UriLen + PrefixLen;

  if N > TBinding.UriAlloc then
  begin
    Parser.Mem.Malloc_fcn(Pointer(Uri), (N + EXPAND_SPARE) *
      SizeOf(XML_Char));

    if Uri = nil then
    begin
      Result := XML_ERROR_NO_MEMORY;

      Exit;
    end;

    J := TBinding.UriAlloc;

    TBinding.UriAlloc := N + EXPAND_SPARE;

    Move(TBinding.Uri^, Uri^, TBinding.UriLen * SizeOf(XML_Char));

    P := Parser.TagStack;

    while P <> nil do
    begin
      if P.Name.Str = TBinding.Uri then
        P.Name.Str := Uri;

      P := P.Parent;
    end;

    Parser.Mem.Free_fcn(Pointer(TBinding.Uri), J * SizeOf(XML_Char));

    TBinding.Uri := Uri;
  end;

  { if namespaceSeparator != '\0' then uri includes it already }
  Uri := XML_PAnsiChar(PtrComp(TBinding.Uri) + TBinding.UriLen *
    SizeOf(XML_Char));

  Move(LocalPart^, Uri^, I * SizeOf(XML_Char));

  { we always have a namespace separator between localPart and TPrefix }
  if PrefixLen <> 0 then
  begin
    Inc(PtrComp(Uri), (I - 1) * SizeOf(XML_Char));

    Uri^ := Parser.NamespaceSeparator; { replace null terminator }

    Move(TBinding.TPrefix.Name^, XML_PAnsiChar(PtrComp(Uri) + 1 * SizeOf(XML_Char)
      )^, PrefixLen * SizeOf(XML_Char));
  end;

  TagNamePtr.Str := TBinding.Uri;

  Result := XML_ERROR_NONE;
end;

function ProcessInternalEntity(Parser: XML_Parser; TEntity: PEntity;
  BetweenDecl: XML_Bool): XML_Error;
begin
end;

function EpilogProcessor(Parser: XML_Parser; S, Stop: PAnsiChar;
  NextPtr: PPAnsiChar): XML_Error;
var
  Next: PAnsiChar;

  Tok: Integer;
begin
  Parser.TProcessor := @EpilogProcessor;
  Parser.EventPtr := S;

  repeat
    Next := nil;
    Tok := XmlPrologTok(Parser.Encoding, Pointer(S), Pointer(Stop), @Next);

    Parser.EventEndPtr := Next;

    case Tok of
      - XML_TOK_PROLOG_S:
        begin
          if @Parser.DefaultHandler <> nil then
          begin
            ReportDefault(Parser, Parser.Encoding, S, Next);

            if Parser.ParsingStatus.Parsing = XML_FINISHED then
            begin
              Result := XML_ERROR_ABORTED;

              Exit;
            end;
          end;

          NextPtr^ := Next;
          Result := XML_ERROR_NONE;

          Exit;
        end;

      XML_TOK_NONE:
        begin
          NextPtr^ := S;
          Result := XML_ERROR_NONE;

          Exit;
        end;

      XML_TOK_PROLOG_S:
        if @Parser.DefaultHandler <> nil then
          ReportDefault(Parser, Parser.Encoding, S, Next);

      XML_TOK_PI:
        if ReportProcessingInstruction(Parser, Parser.Encoding, S, Next) = 0
        then
        begin
          Result := XML_ERROR_NO_MEMORY;

          Exit;
        end;

      XML_TOK_COMMENT:
        if ReportComment(Parser, Parser.Encoding, S, Next) = 0 then
        begin
          Result := XML_ERROR_NO_MEMORY;

          Exit;
        end;

      XML_TOK_INVALID:
        begin
          Parser.EventPtr := Next;

          Result := XML_ERROR_INVALID_TOKEN;

          Exit;
        end;

      XML_TOK_PARTIAL:
        begin
          if Parser.ParsingStatus.FinalBuffer = 0 then
          begin
            NextPtr^ := S;
            Result := XML_ERROR_NONE;

            Exit;
          end;

          Result := XML_ERROR_UNCLOSED_TOKEN;

          Exit;
        end;

      XML_TOK_PARTIAL_CHAR:
        begin
          if Parser.ParsingStatus.FinalBuffer = 0 then
          begin
            NextPtr^ := S;
            Result := XML_ERROR_NONE;

            Exit;
          end;

          Result := XML_ERROR_PARTIAL_CHAR;

          Exit;
        end;

    else
      begin
        Result := XML_ERROR_JUNK_AFTER_DOC_ELEMENT;

        Exit;
      end;

    end;

    Parser.EventPtr := Next;

    S := Next;

    case Parser.ParsingStatus.Parsing of
      XML_SUSPENDED:
        begin
          NextPtr^ := Next;
          Result := XML_ERROR_NONE;

          Exit;
        end;

      XML_FINISHED:
        begin
          Result := XML_ERROR_ABORTED;

          Exit;
        end;
    end;
  until False;
end;

{ doCdataSection {.. }
{ startPtr gets set to non-null if the section is closed, and to null if
  the section is not yet closed. }
function DoCdataSection(Parser: XML_Parser; Enc: ENCODING_ptr;
  StartPtr: PPAnsiChar; Stop: PAnsiChar; NextPtr: PPAnsiChar;
  HaveMore: XML_Bool): XML_Error;
begin
end;

{ cdataSectionProcessor {.. }
{ The idea here is to avoid using stack for each CDATA section when
  the whole file is parsed with one call. }
function CdataSectionProcessor(Parser: XML_Parser; Start, Stop: PAnsiChar;
  EndPtr: PPAnsiChar): XML_Error;
begin
end;

{ doContent }
function DoContent(Parser: XML_Parser; StartTagLevel: Integer; Enc: ENCODING_ptr;
  S, Stop: PAnsiChar; NextPtr: PPAnsiChar; HaveMore: XML_Bool): XML_Error;
var
  Dtd: DTD_ptr;
  EventPP, EventEndPP: PPAnsiChar;
  Next, RawNameEnd, FromPtr, Temp, RawName: PAnsiChar;
  Tok, BufSize, ConvLen, Len, N: Integer;
  C, Ch: XML_Char;
  Name, Context, ToPtr, LocalPart, TPrefix, Uri: XML_PAnsiChar;
  TEntity: PEntity;
  Result_: XML_Error;
  Tag: TAG_ptr;
  Bindings, B: PBinding;
  NoElmHandlers: XML_Bool;
  Name_: TTagName;
  Buf: array [0 .. XML_ENCODE_MAX - 1] of XML_Char;
  DataPtr: IPAnsiChar;

label
  _break;

begin
  { save one level of indirection }
  Dtd := Parser.M_dtd;

  if Enc = Parser.Encoding then
  begin
    EventPP := @Parser.EventPtr;
    EventEndPP := @Parser.EventEndPtr;
  end
  else
  begin
    EventPP := @Parser.OpenInternalEntities.InternalEventPtr;
    EventEndPP := @Parser.OpenInternalEntities.InternalEventEndPtr;
  end;

  EventPP^ := S;

  repeat
    Next := S; { XmlContentTok doesn't always set the last arg }

    Tok := XmlContentTok(Enc, Pointer(S), Pointer(Stop), @Next);

    EventEndPP^ := Next;

    case Tok of
      XML_TOK_TRAILING_CR:
        begin
          if HaveMore <> 0 then
          begin
            NextPtr^ := S;
            Result := XML_ERROR_NONE;

            Exit;
          end;

          EventEndPP^ := Stop;

          if @Parser.CharacterDataHandler <> nil then
          begin
            C := XML_Char($A);

            Parser.CharacterDataHandler(Parser.HandlerArg, @C, 1);

          end
          else if @Parser.DefaultHandler <> nil then
            ReportDefault(Parser, Enc, S, Stop);

          { We are at the end of the final buffer, should we check for
            XML_SUSPENDED, XML_FINISHED? }
          if StartTagLevel = 0 then
          begin
            Result := XML_ERROR_NO_ELEMENTS;

            Exit;
          end;

          if Parser.TagLevel <> StartTagLevel then
          begin
            Result := XML_ERROR_ASYNC_ENTITY;

            Exit;
          end;

          NextPtr^ := Stop;
          Result := XML_ERROR_NONE;

          Exit;
        end;

      XML_TOK_NONE:
        begin
          if HaveMore <> 0 then
          begin
            NextPtr^ := S;
            Result := XML_ERROR_NONE;

            Exit;
          end;

          if StartTagLevel > 0 then
          begin
            if Parser.TagLevel <> StartTagLevel then
            begin
              Result := XML_ERROR_ASYNC_ENTITY;

              Exit;
            end;

            NextPtr^ := S;
            Result := XML_ERROR_NONE;

            Exit;
          end;

          Result := XML_ERROR_NO_ELEMENTS;

          Exit;
        end;

      XML_TOK_INVALID:
        begin
          EventPP^ := Next;
          Result := XML_ERROR_INVALID_TOKEN;

          Exit;
        end;

      XML_TOK_PARTIAL:
        begin
          if HaveMore <> 0 then
          begin
            NextPtr^ := S;
            Result := XML_ERROR_NONE;

            Exit;
          end;

          Result := XML_ERROR_UNCLOSED_TOKEN;

          Exit;
        end;

      XML_TOK_PARTIAL_CHAR:
        begin
          if HaveMore <> 0 then
          begin
            NextPtr^ := S;
            Result := XML_ERROR_NONE;

            Exit;
          end;

          Result := XML_ERROR_PARTIAL_CHAR;

          Exit;
        end;

      XML_TOK_ENTITY_REF:
        begin
          Ch := XML_Char(XmlPredefinedEntityName(Enc,
            Pointer(PtrComp(S) + Enc.MinBytesPerChar),
            Pointer(PtrComp(Next) - Enc.MinBytesPerChar)));

          if Ch <> XML_Char(0) then
          begin
            if @Parser.CharacterDataHandler <> nil then
              Parser.CharacterDataHandler(Parser.HandlerArg, @Ch, 1)
            else if @Parser.DefaultHandler <> nil then
              ReportDefault(Parser, Enc, S, Next);

            goto _break;
          end;

          name := PoolStoreString(@Dtd.Pool, Enc,
            PAnsiChar(PtrComp(S) + Enc.MinBytesPerChar),
            PAnsiChar(PtrComp(Next) - Enc.MinBytesPerChar));

          if name = nil then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

          TEntity := PEntity(Lookup(@Dtd.GeneralEntities, name, 0));

          PoolDiscard(@Dtd.Pool);

          { First, determine if a check for an existing declaration is needed;
            if yes, check that the TEntity exists, and that it is internal,
            otherwise call the skipped TEntity or default handler. }
          if (Dtd.HasParamEntityRefs = 0) or (Dtd.Standalone <> 0) then
            if TEntity = nil then
            begin
              Result := XML_ERROR_UNDEFINED_ENTITY;

              Exit;
            end
            else if TEntity.IsInternal = 0 then
            begin
              Result := XML_ERROR_ENTITY_DECLARED_IN_PE;

              Exit;
            end
            else
          else if TEntity = nil then
          begin
            if @Parser.SkippedEntityHandler <> nil then
              Parser.SkippedEntityHandler(Parser.HandlerArg, name, 0)
            else if @Parser.DefaultHandler <> nil then
              ReportDefault(Parser, Enc, S, Next);

            goto _break;
          end;

          if TEntity.Open <> 0 then
          begin
            Result := XML_ERROR_RECURSIVE_ENTITY_REF;

            Exit;
          end;

          if TEntity.Notation <> nil then
          begin
            Result := XML_ERROR_BINARY_ENTITY_REF;

            Exit;
          end;

          if TEntity.TextPtr <> nil then
          begin
            if Parser.DefaultExpandInternalEntities <> 0 then
            begin
              if @Parser.SkippedEntityHandler <> nil then
                Parser.SkippedEntityHandler(Parser.HandlerArg,
                  TEntity.Name, 0)
              else if @Parser.DefaultHandler <> nil then
                ReportDefault(Parser, Enc, S, Next);

              goto _break;
            end;

            Result_ := ProcessInternalEntity(Parser, TEntity, CXmlFalse);

            if Result_ <> XML_ERROR_NONE then
            begin
              Result := Result_;

              Exit;
            end;

          end
          else if @Parser.ExternalEntityRefHandler <> nil then
          begin
            TEntity.Open := CXmlTrue;
            Context := GetContext(Parser);
            TEntity.Open := CXmlFalse;

            if Context = nil then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            if Parser.ExternalEntityRefHandler
              (Parser.ExternalEntityRefHandlerArg, Context, TEntity.Base,
              TEntity.SystemId, TEntity.PublicId) = 0 then
            begin
              Result := XML_ERROR_EXTERNAL_ENTITY_HANDLING;

              Exit;
            end;

            PoolDiscard(@Parser.TempPool);
          end
          else if @Parser.DefaultHandler <> nil then
            ReportDefault(Parser, Enc, S, Next);

        end;

      XML_TOK_START_TAG_NO_ATTS, XML_TOK_START_TAG_WITH_ATTS:
        begin
          if Parser.FreeTagList <> nil then
          begin
            Tag := Parser.FreeTagList;

            Parser.FreeTagList := Parser.FreeTagList.Parent;
          end
          else
          begin
            Parser.Mem.Malloc_fcn(Pointer(Tag), SizeOf(Expat.TAG));

            if Tag = nil then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            Parser.Mem.Malloc_fcn(Pointer(Tag.Buf), INIT_TAG_BUF_SIZE);

            if Tag.Buf = nil then
            begin
              Parser.Mem.Free_fcn(Pointer(Tag), SizeOf(Expat.TAG));

              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end
            else
              Tag.Alloc := INIT_TAG_BUF_SIZE;

            Tag.BufEnd := PAnsiChar(PtrComp(Tag.Buf) + INIT_TAG_BUF_SIZE);
          end;

          Tag.Bindings := nil;
          Tag.Parent := Parser.TagStack;
          Parser.TagStack := Tag;
          Tag.Name.LocalPart := nil;
          Tag.Name.TPrefix := nil;
          Tag.RawName := PAnsiChar(PtrComp(S) + Enc.MinBytesPerChar);
          Tag.RawNameLength := XmlNameLength(Enc, Pointer(Tag.RawName));

          Inc(Parser.TagLevel);

          RawNameEnd := PAnsiChar(PtrComp(Tag.RawName) + Tag.RawNameLength);
          FromPtr := Tag.RawName;
          ToPtr := XML_PAnsiChar(Tag.Buf);

          repeat
            XmlConvert(Enc, @FromPtr, RawNameEnd, IPPAnsiChar(@ToPtr),
              IPAnsiChar(PtrComp(Tag.BufEnd) - 1));

            ConvLen := (PtrComp(ToPtr) - PtrComp(Tag.Buf)) div SizeOf(XML_Char);

            if FromPtr = RawNameEnd then
            begin
              Tag.Name.StrLen := ConvLen;

              Break;
            end;

            BufSize := (PtrComp(Tag.BufEnd) - PtrComp(Tag.Buf)) shl 1;

            Parser.Mem.Realloc_fcn(Pointer(Tag.Buf), Tag.Alloc, BufSize);

            if Temp = nil then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end
            else
              Tag.Alloc := BufSize;

            Tag.Buf := Temp;
            Tag.BufEnd := PAnsiChar(PtrComp(Temp) + BufSize);

            ToPtr := XML_PAnsiChar(PtrComp(Temp) + ConvLen);
          until False;

          Tag.Name.Str := XML_PAnsiChar(Tag.Buf);

          ToPtr^ := XML_T(#0);
          Result_ := StoreAtts(Parser, Enc, S, @Tag.Name, @Tag.Bindings);

          if Result_ <> XML_Error(0) then
          begin
            Result := Result_;

            Exit;
          end;

          if @Parser.StartElementHandler <> nil then
            Parser.StartElementHandler(Parser.HandlerArg, Tag.Name.Str,
              XML_PPAnsiChar(Parser.Atts))
          else if @Parser.DefaultHandler <> nil then
            ReportDefault(Parser, Enc, S, Next);

          PoolClear(@Parser.TempPool);
        end;

      XML_TOK_EMPTY_ELEMENT_NO_ATTS, XML_TOK_EMPTY_ELEMENT_WITH_ATTS:
        begin
          RawName := PAnsiChar(PtrComp(S) + Enc.MinBytesPerChar);
          Bindings := nil;
          NoElmHandlers := CXmlTrue;

          Name_.Str := PoolStoreString(@Parser.TempPool, Enc, RawName,
            PAnsiChar(PtrComp(RawName) + XmlNameLength(Enc, Pointer(RawName))));

          if Name_.Str = nil then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;

          end;

          PoolFinish(@Parser.TempPool);

          Result_ := StoreAtts(Parser, Enc, S, @Name_, @Bindings);

          if Result_ <> XML_Error(0) then
          begin
            Result := Result_;

            Exit;

          end;

          PoolFinish(@Parser.TempPool);

          if @Parser.StartElementHandler <> nil then
          begin
            Parser.StartElementHandler(Parser.HandlerArg, Name_.Str,
              XML_PPAnsiChar(Parser.Atts));

            NoElmHandlers := CXmlFalse;

          end;

          if @Parser.EndElementHandler <> nil then
          begin
            if @Parser.StartElementHandler <> nil then
              EventPP^ := EventEndPP^;

            Parser.EndElementHandler(Parser.HandlerArg, Name_.Str);

            NoElmHandlers := CXmlFalse;

          end;

          if (NoElmHandlers <> 0) and (@Parser.DefaultHandler <> nil) then
            ReportDefault(Parser, Enc, S, Next);

          PoolClear(@Parser.TempPool);

          while Bindings <> nil do
          begin
            B := Bindings;

            if @Parser.EndNamespaceDeclHandler <> nil then
              Parser.EndNamespaceDeclHandler(Parser.HandlerArg,
                B.TPrefix.Name);

            Bindings := Bindings.NextTagBinding;
            B.NextTagBinding := Parser.FreeBindingList;

            Parser.FreeBindingList := B;
            B.TPrefix.TBinding := B.PrevPrefixBinding;

          end;

          if Parser.TagLevel = 0 then
          begin
            Result := EpilogProcessor(Parser, Next, Stop, NextPtr);

            Exit;

          end;

        end;

      XML_TOK_END_TAG:
        if Parser.TagLevel = StartTagLevel then
        begin
          Result := XML_ERROR_ASYNC_ENTITY;

          Exit;

        end
        else
        begin
          Tag := Parser.TagStack;
          Parser.TagStack := Tag.Parent;
          Tag.Parent := Parser.FreeTagList;
          Parser.FreeTagList := Tag;

          RawName := PAnsiChar(PtrComp(S) + Enc.MinBytesPerChar * 2);
          Len := XmlNameLength(Enc, Pointer(RawName));

          if (Len <> Tag.RawNameLength) or
            (MemCmp(Pointer(Tag.RawName), Pointer(RawName), Len) <> 0) then
          begin
            EventPP^ := RawName;
            Result := XML_ERROR_TAG_MISMATCH;

            Exit;

          end;

          Dec(Parser.TagLevel);

          if @Parser.EndElementHandler <> nil then
          begin
            LocalPart := Tag.Name.LocalPart;

            if (Parser.M_ns <> 0) and (LocalPart <> nil) then
            begin
              { localPart and TPrefix may have been overwritten in
                tag->name.str, since this points to the TBinding->uri
                buffer which gets re-used; so we have to add them again }
              Uri := XML_PAnsiChar(PtrComp(Tag.Name.Str) + Tag.Name.UriLen);

              { don't need to check for space - already done in storeAtts() }
              while LocalPart^ <> XML_Char(0) do
              begin
                Uri^ := LocalPart^;

                Inc(PtrComp(Uri), SizeOf(XML_Char));
                Inc(PtrComp(LocalPart), SizeOf(XML_Char));

              end;

              TPrefix := XML_PAnsiChar(Tag.Name.TPrefix);

              if (Parser.M_ns_triplets <> 0) and (TPrefix <> nil) then
              begin
                Uri^ := Parser.NamespaceSeparator;

                Inc(PtrComp(Uri), SizeOf(XML_Char));

                while TPrefix^ <> XML_Char(0) do
                begin
                  Uri^ := TPrefix^;

                  Inc(PtrComp(Uri), SizeOf(XML_Char));
                  Inc(PtrComp(TPrefix), SizeOf(XML_Char));

                end;

              end;

              Uri^ := XML_T(#0);

            end;

            Parser.EndElementHandler(Parser.HandlerArg, Tag.Name.Str);

          end
          else if @Parser.DefaultHandler <> nil then
            ReportDefault(Parser, Enc, S, Next);

          while Tag.Bindings <> nil do
          begin
            B := Tag.Bindings;

            if @Parser.EndNamespaceDeclHandler <> nil then
              Parser.EndNamespaceDeclHandler(Parser.HandlerArg,
                B.TPrefix.Name);

            Tag.Bindings := Tag.Bindings.NextTagBinding;
            B.NextTagBinding := Parser.FreeBindingList;
            Parser.FreeBindingList := B;
            B.TPrefix.TBinding := B.PrevPrefixBinding;

          end;

          if Parser.TagLevel = 0 then
          begin
            Result := EpilogProcessor(Parser, Next, Stop, NextPtr);

            Exit;

          end;

        end;

      XML_TOK_CHAR_REF:
        begin
          N := XmlCharRefNumber(Enc, Pointer(S));

          if N < 0 then
          begin
            Result := XML_ERROR_BAD_CHAR_REF;

            Exit;

          end;

          if @Parser.CharacterDataHandler <> nil then
            Parser.CharacterDataHandler(Parser.HandlerArg, @Buf[0],
              XmlEncode(N, IPAnsiChar(@Buf)))
          else if @Parser.DefaultHandler <> nil then
            ReportDefault(Parser, Enc, S, Next);

        end;

      XML_TOK_XML_DECL:
        begin
          Result := XML_ERROR_MISPLACED_XML_PI;

          Exit;

        end;

      XML_TOK_DATA_NEWLINE:
        if @Parser.CharacterDataHandler <> nil then
        begin
          C := XML_Char($A);

          Parser.CharacterDataHandler(Parser.HandlerArg, @C, 1);

        end
        else if @Parser.DefaultHandler <> nil then
          ReportDefault(Parser, Enc, S, Next);

      XML_TOK_CDATA_SECT_OPEN:
        begin
          if @Parser.StartCdataSectionHandler <> nil then
            Parser.StartCdataSectionHandler(Parser.HandlerArg)
{$IFDEF 0}
            { Suppose you doing a transformation on a document that involves
              changing only the AnsiCharacter data.  You set up a defaultHandler
              and a AnsiCharacterDataHandler.  The defaultHandler simply copies
              AnsiCharacters through.  The AnsiCharacterDataHandler does the
              transformation and writes the AnsiCharacters out escaping them as
              necessary.  This case will fail to work if we leave out the
              following two lines (because & and < inside CDATA sections will
              be incorrectly escaped).

              However, now we have a start/endCdataSectionHandler, so it seems
              easier to let the user deal with this. }
          else if @Parser.CharacterDataHandler <> nil then
            Parser.CharacterDataHandler(Parser.HandlerArg,
              Parser.DataBuf, 0)
{$ENDIF}
          else if @Parser.DefaultHandler <> nil then
            ReportDefault(Parser, Enc, S, Next);

          Result_ := DoCdataSection(Parser, Enc, @Next, Stop, NextPtr,
            HaveMore);

          if Result_ <> XML_ERROR_NONE then
          begin
            Result := Result_;

            Exit;

          end
          else if Next = nil then
          begin
            Parser.TProcessor := @CdataSectionProcessor;

            Result := Result_;

            Exit;

          end;

        end;

      XML_TOK_TRAILING_RSQB:
        begin
          if HaveMore <> 0 then
          begin
            NextPtr^ := S;
            Result := XML_ERROR_NONE;

            Exit;

          end;

          if @Parser.CharacterDataHandler <> nil then
            if MUSRasterizerConverterERT(Enc, S) <> 0 then
            begin
              DataPtr := IPAnsiChar(Parser.DataBuf);

              XmlConvert(Enc, @S, Stop, @DataPtr,
                IPAnsiChar(Parser.DataBufEnd));

              Parser.CharacterDataHandler(Parser.HandlerArg,
                Parser.DataBuf, (PtrComp(DataPtr) - PtrComp(Parser.DataBuf))
                div SizeOf(ICHAR));

            end
            else
              Parser.CharacterDataHandler(Parser.HandlerArg,
                XML_PAnsiChar(S), (PtrComp(Stop) - PtrComp(S))
                div SizeOf(XML_Char))
          else if @Parser.DefaultHandler <> nil then
            ReportDefault(Parser, Enc, S, Stop);

          { We are at the end of the final buffer, should we check for
            XML_SUSPENDED, XML_FINISHED? }
          if StartTagLevel = 0 then
          begin
            EventPP^ := Stop;
            Result := XML_ERROR_NO_ELEMENTS;

            Exit;

          end;

          if Parser.TagLevel <> StartTagLevel then
          begin
            EventPP^ := Stop;
            Result := XML_ERROR_ASYNC_ENTITY;

            Exit;

          end;

          NextPtr^ := Stop;
          Result := XML_ERROR_NONE;

          Exit;

        end;

      XML_TOK_DATA_CHARS:
        if @Parser.CharacterDataHandler <> nil then
          if MUSRasterizerConverterERT(Enc, S) <> 0 then
            repeat
              DataPtr := IPAnsiChar(Parser.DataBuf);

              XmlConvert(Enc, @S, Next, @DataPtr,
                IPAnsiChar(Parser.DataBufEnd));

              EventEndPP^ := S;

              Parser.CharacterDataHandler(Parser.HandlerArg,
                Parser.DataBuf, (PtrComp(DataPtr) - PtrComp(Parser.DataBuf))
                div SizeOf(ICHAR));

              if S = Next then
                Break;

              EventPP^ := S;

            until False
          else
            Parser.CharacterDataHandler(Parser.HandlerArg, XML_PAnsiChar(S),
              (PtrComp(Next) - PtrComp(S)) div SizeOf(XML_Char))

        else if @Parser.DefaultHandler <> nil then
          ReportDefault(Parser, Enc, S, Next);

      XML_TOK_PI:
        if ReportProcessingInstruction(Parser, Enc, S, Next) = 0 then
        begin
          Result := XML_ERROR_NO_MEMORY;

          Exit;
        end;

      XML_TOK_COMMENT:
        if ReportComment(Parser, Enc, S, Next) = 0 then
        begin
          Result := XML_ERROR_NO_MEMORY;

          Exit;
        end;

    else
      if @Parser.DefaultHandler <> nil then
        ReportDefault(Parser, Enc, S, Next);
    end;

  _break:
    EventPP^ := Next;
    S := Next;

    case Parser.ParsingStatus.Parsing of
      XML_SUSPENDED:
        begin
          NextPtr^ := Next;
          Result := XML_ERROR_NONE;

          Exit;
        end;

      XML_FINISHED:
        begin
          Result := XML_ERROR_ABORTED;

          Exit;
        end;
    end;
  until False;

  { not reached }
end;

function ContentProcessor(Parser: XML_Parser; Start, Stop: PAnsiChar;
  EndPtr: PPAnsiChar): XML_Error;
var
  Result_: XML_Error;

begin
  Result_ := DoContent(Parser, 0, Parser.Encoding, Start, Stop, EndPtr,
    XML_Bool(not Parser.ParsingStatus.FinalBuffer));

  if Result_ = XML_ERROR_NONE then
    if StoreRawNames(Parser) = 0 then
    begin
      Result := XML_ERROR_NO_MEMORY;

      Exit;
    end;

  Result := Result_;
end;

function GetElementType(Parser: XML_Parser; Enc: ENCODING_ptr;
  Ptr, Stop: PAnsiChar): PElementType;
begin
end;

function GetAttributeId(Parser: XML_Parser; Enc: ENCODING_ptr;
  Start, Stop: PAnsiChar): PAttributeID;
var
  Dtd: DTD_ptr;
  Id: PAttributeID;
  Name: XML_PAnsiChar;
  I, J: Integer;
begin
  { save one level of indirection }
  Dtd := Parser.M_dtd;

  if PoolAppendChar(@Dtd.Pool, XML_T(#0)) = 0 then
  begin
    Result := nil;

    Exit;
  end;

  name := PoolStoreString(@Dtd.Pool, Enc, Start, Stop);

  if name = nil then
  begin
    Result := nil;

    Exit;
  end;

  { skip quotation mark - its storage will be re-used (like in name[-1]) }
  Inc(PtrComp(name), SizeOf(XML_Char));

  Id := PAttributeID(Lookup(@Dtd.AttributeIds, name, SizeOf(TAttributeID)));

  if Id = nil then
  begin
    Result := nil;

    Exit;
  end;

  if Id.Name <> name then
    PoolDiscard(@Dtd.Pool)
  else
  begin
    PoolFinish(@Dtd.Pool);

    if Parser.M_ns = 0 then
    else if (XML_PAnsiChar(PtrComp(name) + 0 * SizeOf(XML_Char))^ = XML_T('x'))
      and (XML_PAnsiChar(PtrComp(name) + 1 * SizeOf(XML_Char))^ = XML_T('m'))
      and (XML_PAnsiChar(PtrComp(name) + 2 * SizeOf(XML_Char))^ = XML_T('l'))
      and (XML_PAnsiChar(PtrComp(name) + 3 * SizeOf(XML_Char))^ = XML_T('n'))
      and (XML_PAnsiChar(PtrComp(name) + 4 * SizeOf(XML_Char))^ = XML_T('s'))
      and ((XML_PAnsiChar(PtrComp(name) + 5 * SizeOf(XML_Char))^ = XML_T(#0)) or
      (XML_PAnsiChar(PtrComp(name) + 5 * SizeOf(XML_Char))^ = XML_T(':'))) then
    begin
      if XML_PAnsiChar(PtrComp(name) + 5 * SizeOf(XML_Char))^ = XML_T(#0) then
        Id.TPrefix := @Dtd.DefaultPrefix
      else
        Id.TPrefix := PPrefix(Lookup(@Dtd.Prefixes,
          XML_PAnsiChar(PtrComp(name) + 6 * SizeOf(XML_Char)), SizeOf(TPrefix)));

      Id.Xmlns := CXmlTrue;
    end
    else
    begin
      I := 0;

      while XML_PAnsiChar(PtrComp(name) + I * SizeOf(XML_Char))^ <>
        XML_Char(0) do
      begin
        { attributes without TPrefix are *not* in the default namespace }
        if XML_PAnsiChar(PtrComp(name) + I * SizeOf(XML_Char))^ = XML_T(':')
        then
        begin
          J := 0;

          while J < I do
          begin
            if PoolAppendChar(@Dtd.Pool,
              XML_PAnsiChar(PtrComp(name) + J * SizeOf(XML_Char))^) = 0 then
            begin
              Result := nil;

              Exit;
            end;

            Inc(J);
          end;

          if PoolAppendChar(@Dtd.Pool, XML_T(#0)) = 0 then
          begin
            Result := nil;

            Exit;
          end;

          Id.TPrefix := PPrefix(Lookup(@Dtd.Prefixes, PoolStart(@Dtd.Pool),
            SizeOf(TPrefix)));

          if Id.TPrefix.Name = PoolStart(@Dtd.Pool) then
            PoolFinish(@Dtd.Pool)
          else
            PoolDiscard(@Dtd.Pool);

          Break;
        end;

        Inc(I);
      end;
    end;
  end;

  Result := Id;
end;

function DefineAttribute(Type_: PElementType; AttId: PAttributeID;
  IsCdata, IsId: XML_Bool; Value: XML_PAnsiChar; Parser: XML_Parser): Integer;
begin
end;

function AppendAttributeValue(Parser: XML_Parser; Enc: ENCODING_ptr;
  IsCdata: XML_Bool; Ptr, Stop: PAnsiChar; Pool: PStringPool): XML_Error;
var
  Dtd: DTD_ptr;
  Next: PAnsiChar;
  Tok, I, N: Integer;
  Buf: array [0 .. XML_ENCODE_MAX - 1] of XML_Char;
  Name, TextEnd: XML_PAnsiChar;
  TEntity: PEntity;
  CheckEntityDecl: AnsiChar;
  Ch: XML_Char;
  Result_: XML_Error;

label
  _break, _go0;

begin
  { save one level of indirection }
  Dtd := Parser.M_dtd;

  repeat
    Tok := XmlAttributeValueTok(Enc, Pointer(Ptr), Pointer(Stop), @Next);

    case Tok of
      XML_TOK_NONE:
        begin
          Result := XML_ERROR_NONE;

          Exit;

        end;

      XML_TOK_INVALID:
        begin
          if Enc = Parser.Encoding then
            Parser.EventPtr := Next;

          Result := XML_ERROR_INVALID_TOKEN;
        end;

      XML_TOK_PARTIAL:
        begin
          if Enc = Parser.Encoding then
            Parser.EventPtr := Ptr;

          Result := XML_ERROR_INVALID_TOKEN;
        end;

      XML_TOK_CHAR_REF:
        begin
          N := XmlCharRefNumber(Enc, Pointer(Ptr));

          if N < 0 then
          begin
            if Enc = Parser.Encoding then
              Parser.EventPtr := Ptr;

            Result := XML_ERROR_BAD_CHAR_REF;
          end;

          if (IsCdata = 0) and (N = $20) and { space }
            ((PoolLength(Pool) = 0) or (PoolLastChar(Pool) = XML_Char($20)))
          then
            goto _break;

          N := XmlEncode(N, IPAnsiChar(Buf));

          if N = 0 then
          begin
            if Enc = Parser.Encoding then
              Parser.EventPtr := Ptr;

            Result := XML_ERROR_BAD_CHAR_REF;

            Exit;
          end;

          I := 0;

          while I < N do
          begin
            if PoolAppendChar(Pool, Buf[I]) = 0 then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            Inc(I);
          end;

        end;

      XML_TOK_DATA_CHARS:
        if PoolAppend(Pool, Enc, Ptr, Next) = nil then
        begin
          Result := XML_ERROR_NO_MEMORY;

          Exit;
        end;

      XML_TOK_TRAILING_CR:
        begin
          Next := PAnsiChar(PtrComp(Ptr) + Enc.MinBytesPerChar);

          goto _go0;
        end;

      XML_TOK_ATTRIBUTE_VALUE_S, XML_TOK_DATA_NEWLINE:
      _go0:
        begin
          if (IsCdata = 0) and
            ((PoolLength(Pool) = 0) or (PoolLastChar(Pool) = XML_Char($20)))
          then
            goto _break;

          if PoolAppendChar(Pool, AnsiChar($20)) = 0 then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;
        end;

      XML_TOK_ENTITY_REF:
        begin
          Ch := XML_Char(XmlPredefinedEntityName(Enc,
            Pointer(PAnsiChar(PtrComp(Ptr) + Enc.MinBytesPerChar)),
            Pointer(PAnsiChar(PtrComp(Next) - Enc.MinBytesPerChar))));

          if Ch <> XML_Char(0) then
          begin
            if PoolAppendChar(Pool, Ch) = 0 then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            goto _break;
          end;

          name := PoolStoreString(@Parser.M_temp2Pool, Enc,
            PAnsiChar(PtrComp(Ptr) + Enc.MinBytesPerChar),
            PAnsiChar(PtrComp(Next) - Enc.MinBytesPerChar));

          if name = nil then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

          TEntity := PEntity(Lookup(@Parser.M_dtd.GeneralEntities, name, 0));

          PoolDiscard(@Parser.M_temp2Pool);

          { First, determine if a check for an existing declaration is needed;
            if yes, check that the TEntity exists, and that it is internal. }
          if Pool = @Parser.M_dtd.Pool then { are we called from prolog? }
          begin
            if Dtd.Standalone <> 0 then
              CheckEntityDecl := AnsiChar(Parser.OpenInternalEntities = nil)
            else
              CheckEntityDecl := AnsiChar(Dtd.HasParamEntityRefs = 0);

{$IFDEF XML_DTD }
            CheckEntityDecl := AnsiChar((CheckEntityDecl <> #0) and
              (Parser.PrologState.DocumentEntity <> 0))
{$ENDIF }
          end
          else { if pool = @tempPool: we are called from content }
            CheckEntityDecl := AnsiChar((Dtd.HasParamEntityRefs = 0) or
              (Dtd.Standalone <> 0));

          if CheckEntityDecl <> #0 then
            if TEntity = nil then
            begin
              Result := XML_ERROR_UNDEFINED_ENTITY;

              Exit;
            end
            else if TEntity.IsInternal = 0 then
            begin
              Result := XML_ERROR_ENTITY_DECLARED_IN_PE;

              Exit;
            end
            else
          else if TEntity = nil then
            { Cannot report skipped TEntity here - see comments on
              skippedEntityHandler.
              if @parser.SkippedEntityHandler <> NIL then
              parser.SkippedEntityHandler(parser.HandlerArg ,name ,0 ); }
            { Cannot call the default handler because this would be
              out of sync with the call to the startElementHandler.
              if (pool = @parser.TempPool ) and
              (@parser.DefaultHandler <> NIL ) then
              reportDefault(parser ,enc ,ptr ,next ); }
            goto _break;

          if TEntity.Open <> 0 then
          begin
            if Enc = Parser.Encoding then
              Parser.EventPtr := Ptr;

            Result := XML_ERROR_RECURSIVE_ENTITY_REF;

            Exit;
          end;

          if TEntity.Notation <> nil then
          begin
            if Enc = Parser.Encoding then
              Parser.EventPtr := Ptr;

            Result := XML_ERROR_BINARY_ENTITY_REF;

            Exit;
          end;

          if TEntity.TextPtr = nil then
          begin
            if Enc = Parser.Encoding then
              Parser.EventPtr := Ptr;

            Result := XML_ERROR_ATTRIBUTE_EXTERNAL_ENTITY_REF;

            Exit;
          end
          else
          begin
            TextEnd := XML_PAnsiChar(PtrComp(TEntity.TextPtr) + TEntity.TextLen *
              SizeOf(XML_Char));

            TEntity.Open := CXmlTrue;

            Result_ := AppendAttributeValue(Parser, Parser.InternalEncoding,
              IsCdata, PAnsiChar(TEntity.TextPtr), PAnsiChar(TextEnd), Pool);

            TEntity.Open := CXmlFalse;

            if Result_ <> XML_Error(0) then
            begin
              Result := Result_;

              Exit;
            end;
          end;
        end;
    else
      begin
        if Enc = Parser.Encoding then
          Parser.EventPtr := Ptr;

        Result := XML_ERROR_UNEXPECTED_STATE;

        Exit;
      end;
    end;

  _break:
    Ptr := Next;

  until False;

  { not reached }
end;

function StoreAttributeValue(Parser: XML_Parser; Enc: ENCODING_ptr;
  IsCdata: XML_Bool; Ptr, Stop: PAnsiChar; Pool: PStringPool): XML_Error;
var
  Result_: XML_Error;
begin
  Result_ := AppendAttributeValue(Parser, Enc, IsCdata, Ptr, Stop, Pool);

  if Result_ <> XML_Error(0) then
  begin
    Result := Result_;

    Exit;
  end;

  if (IsCdata = 0) and (PoolLength(Pool) <> 0) and
    (PoolLastChar(Pool) = XML_Char($20)) then
    PoolChop(Pool);

  if PoolAppendChar(Pool, XML_T(#0)) = 0 then
  begin
    Result := XML_ERROR_NO_MEMORY;

    Exit;
  end;

  Result := XML_ERROR_NONE;
end;

function StoreEntityValue(Parser: XML_Parser; Enc: ENCODING_ptr;
  Start, Stop: PAnsiChar): XML_Error;
begin
end;

{ startPtr gets set to non-null is the section is closed, and to null
  if the section is not yet closed. }
function DoIgnoreSection(Parser: XML_Parser; Enc: ENCODING_ptr;
  StartPtr: PPAnsiChar; Stop: PAnsiChar; NextPtr: PPAnsiChar;
  HaveMore: XML_Bool): XML_Error;
begin
end;

{ The idea here is to avoid using stack for each IGNORE section when
  the whole file is parsed with one call. }
function IgnoreSectionProcessor(Parser: XML_Parser; Start, Stop: PAnsiChar;
  EndPtr: PPAnsiChar): XML_Error;
begin
end;

function NextScaffoldPart(Parser: XML_Parser): Integer;
begin
end;

function Build_model(Parser: XML_Parser): XML_Content_ptr;
begin
end;

function ReportProcessingInstruction(Parser: XML_Parser; Enc: ENCODING_ptr;
  Start, Stop: PAnsiChar): Integer;
begin
end;

procedure NormalizeLines(S: XML_PAnsiChar);
begin
end;

function ReportComment(Parser: XML_Parser; Enc: ENCODING_ptr;
  Start, Stop: PAnsiChar): Integer;
var
  Data: XML_PAnsiChar;
begin
  if @Parser.CommentHandler = nil then
  begin
    if @Parser.DefaultHandler <> nil then
      ReportDefault(Parser, Enc, Start, Stop);

    Result := 1;

    Exit;
  end;

  Data := PoolStoreString(@Parser.TempPool, Enc,
    PAnsiChar(PtrComp(Start) + Enc.MinBytesPerChar * 4),
    PAnsiChar(PtrComp(Stop) - Enc.MinBytesPerChar * 3));

  if Data = nil then
  begin
    Result := 0;

    Exit;
  end;

  NormalizeLines(Data);

  Parser.CommentHandler(Parser.HandlerArg, Data);

  PoolClear(@Parser.TempPool);

  Result := 1;
end;

function DoProlog(Parser: XML_Parser; Enc: ENCODING_ptr; S, Stop: PAnsiChar;
  Tok: Integer; Next: PAnsiChar; NextPtr: PPAnsiChar; HaveMore: XML_Bool)
  : XML_Error;
const
{$IFDEF XML_DTD }
  ExternalSubsetName: array [0 .. 1] of XML_Char = ('#', #0);

{$ENDIF }
  AtypeCDATA: array [0 .. 5] of XML_Char = ('C', 'D', 'A', 'T', 'A', #0);
  AtypeID: array [0 .. 2] of XML_Char = ('I', 'D', #0);
  AtypeIDREF: array [0 .. 5] of XML_Char = ('I', 'D', 'R', 'E', 'F', #0);
  AtypeIDREFS: array [0 .. 6] of XML_Char = ('I', 'D', 'R', 'E', 'F', 'S', #0);
  AtypeENTITY: array [0 .. 6] of XML_Char = ('E', 'N', 'T', 'I', 'T', 'Y', #0);
  AtypeENTITIES: array [0 .. 8] of XML_Char = ('E', 'N', 'T', 'I', 'T', 'I',
    'E', 'S', #0);
  AtypeNMTOKEN: array [0 .. 7] of XML_Char = ('N', 'M', 'T', 'O', 'K',
    'E', 'N', #0);
  AtypeNMTOKENS: array [0 .. 8] of XML_Char = ('N', 'M', 'T', 'O', 'K', 'E',
    'N', 'S', #0);
  NotationPrefix: array [0 .. 8] of XML_Char = ('N', 'O', 'T', 'A', 'T', 'I',
    'O', 'N', #0);
  EnumValueSep: array [0 .. 1] of XML_Char = ('|', #0);
  EnumValueStart: array [0 .. 1] of XML_Char = ('(', #0);

var
  Dtd: DTD_ptr;
  EventPP, EventEndPP: PPAnsiChar;
  Quant: XML_Content_Quant;
  Role, Myindex, NameLen: Integer;
  HandleDefault, HadParamEntityRefs, Ok, BetweenDecl: XML_Bool;
  Result_: XML_Error;
  Tem, TPrefix, AttVal, Name, SystemId: XML_PAnsiChar;
  TEntity: PEntity;
  Nxt: PAnsiChar;
  Content, Model: XML_Content_ptr;
  El: PElementType;

label
  _break, _go0, _go1,
  AlreadyChecked, CheckAttListDeclHandler, ElementContent, CloseGroup;

begin
  { save one level of indirection }
  Dtd := Parser.M_dtd;

  if Enc = Parser.Encoding then
  begin
    EventPP := @Parser.EventPtr;
    EventEndPP := @Parser.EventEndPtr;
  end
  else
  begin
    EventPP := @Parser.OpenInternalEntities.InternalEventPtr;
    EventEndPP := @Parser.OpenInternalEntities.InternalEventEndPtr;
  end;

  repeat
    HandleDefault := CXmlTrue;
    EventPP^ := S;
    EventEndPP^ := Next;

    if Tok <= 0 then
    begin
      if (HaveMore <> 0) and (Tok <> XML_TOK_INVALID) then
      begin
        NextPtr^ := S;
        Result := XML_ERROR_NONE;

        Exit;
      end;

      case Tok of
        XML_TOK_INVALID:
          begin
            EventPP^ := Next;
            Result := XML_ERROR_INVALID_TOKEN;

            Exit;
          end;

        XML_TOK_PARTIAL:
          begin
            Result := XML_ERROR_UNCLOSED_TOKEN;

            Exit;
          end;

        XML_TOK_PARTIAL_CHAR:
          begin
            Result := XML_ERROR_PARTIAL_CHAR;

            Exit;
          end;

        XML_TOK_NONE:
          begin
{$IFDEF XML_DTD }
            { for internal PE NOT referenced between declarations }
            if (Enc <> Parser.Encoding) and
              (Parser.OpenInternalEntities.BetweenDecl = 0) then
            begin
              NextPtr^ := S;
              Result := XML_ERROR_NONE;

              Exit;
            end;

            { WFC: PE Between Declarations - must check that PE contains
              complete markup, not only for external PEs, but also for
              internal PEs if the reference occurs between declarations. }
            if (Parser.IsParamEntity <> 0) or (Enc <> Parser.Encoding) then
            begin
              if XmlTokenRole(@Parser.PrologState, XML_TOK_NONE,
                Pointer(Stop), Pointer(Stop), Enc) = XML_ROLE_ERROR then
              begin
                Result := XML_ERROR_INCOMPLETE_PE;

                Exit;
              end;

              NextPtr^ := S;
              Result := XML_ERROR_NONE;

              Exit;
            end;
{$ENDIF }

            Result := XML_ERROR_NO_ELEMENTS;

            Exit;
          end;

      else
        begin
          Tok := -Tok;
          Next := Stop;
        end;
      end;
    end;

    Role := XmlTokenRole(@Parser.PrologState, Tok, Pointer(S),
      Pointer(Next), Enc);

    case Role of
      XML_ROLE_XML_DECL:
        begin
          Result_ := ProcessXmlDecl(Parser, 0, S, Next);

          if Result_ <> XML_ERROR_NONE then
          begin
            Result := Result_;

            Exit;
          end;

          Enc := Parser.Encoding;
          HandleDefault := CXmlFalse;
        end;

      XML_ROLE_DOCTYPE_NAME:
        begin
          if @Parser.StartDoctypeDeclHandler <> nil then
          begin
            Parser.DoctypeName := PoolStoreString(@Parser.TempPool,
              Enc, S, Next);

            if Parser.DoctypeName = nil then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            PoolFinish(@Parser.TempPool);

            Parser.DoctypePubid := nil;
            HandleDefault := CXmlFalse;
          end;

          Parser.DoctypeSysid := nil; { always initialize to NULL }
        end;

      XML_ROLE_DOCTYPE_INTERNAL_SUBSET:
        if @Parser.StartDoctypeDeclHandler <> nil then
        begin
          Parser.StartDoctypeDeclHandler(Parser.HandlerArg,
            Parser.DoctypeName, Parser.DoctypeSysid,
            Parser.DoctypePubid, 1);

          Parser.DoctypeName := nil;
          PoolClear(@Parser.TempPool);
          HandleDefault := CXmlFalse;
        end;

{$IFDEF XML_DTD}
      XML_ROLE_TEXT_DECL:
        begin
          Result_ := ProcessXmlDecl(Parser, 1, S, Next);

          if Result_ <> XML_ERROR_NONE then
          begin
            Result := Result_;

            Exit;
          end;

          Enc := Parser.Encoding;
          HandleDefault := CXmlFalse;
        end;

{$ENDIF}
      XML_ROLE_DOCTYPE_PUBLIC_ID:
        begin
{$IFDEF XML_DTD}
          Parser.M_useForeignDTD := CXmlFalse;
          Parser.DeclEntity :=
            PEntity(Lookup(@Dtd.ParamEntities, @ExternalSubsetName[0],
            SizeOf(Expat.TEntity)));

          if Parser.DeclEntity = nil then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

{$ENDIF}
          Dtd.HasParamEntityRefs := CXmlTrue;

          if @Parser.StartDoctypeDeclHandler <> nil then
          begin
            if XmlIsPublicId(Enc, Pointer(S), Pointer(Next), Pointer(EventPP)) = 0
            then
            begin
              Result := XML_ERROR_PUBLICID;

              Exit;
            end;

            Parser.DoctypePubid := PoolStoreString(@Parser.TempPool, Enc,
              PAnsiChar(PtrComp(S) + Enc.MinBytesPerChar),
              PAnsiChar(PtrComp(Next) - Enc.MinBytesPerChar));

            if Parser.DoctypePubid = nil then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            NormalizePublicId(XML_PAnsiChar(Parser.DoctypePubid));
            PoolFinish(@Parser.TempPool);

            HandleDefault := CXmlFalse;

            goto AlreadyChecked;
          end;

          { fall through }
          goto _go0;
        end;

      XML_ROLE_ENTITY_PUBLIC_ID:
      _go0:
        begin
          if XmlIsPublicId(Enc, Pointer(S), Pointer(Next), Pointer(EventPP)) = 0
          then
          begin
            Result := XML_ERROR_PUBLICID;

            Exit;
          end;

        AlreadyChecked:
          if (Dtd.KeepProcessing <> 0) and (Parser.DeclEntity <> nil) then
          begin
            Tem := PoolStoreString(@Dtd.Pool, Enc,
              PAnsiChar(PtrComp(S) + Enc.MinBytesPerChar),
              PAnsiChar(PtrComp(Next) - Enc.MinBytesPerChar));

            if Tem = nil then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            NormalizePublicId(Tem);
            Parser.DeclEntity.PublicId := Tem;
            PoolFinish(@Dtd.Pool);

            if @Parser.EntityDeclHandler <> nil then
              HandleDefault := CXmlFalse;
          end;
        end;

      XML_ROLE_DOCTYPE_CLOSE:
        begin
          if Parser.DoctypeName <> nil then
          begin
            Parser.StartDoctypeDeclHandler(Parser.HandlerArg,
              Parser.DoctypeName, Parser.DoctypeSysid,
              Parser.DoctypePubid, 0);

            PoolClear(@Parser.TempPool);
            HandleDefault := CXmlFalse;
          end;

          { doctypeSysid will be non-NULL in the case of a previous
            XML_ROLE_DOCTYPE_SYSTEM_ID, even if startDoctypeDeclHandler
            was not set, indicating an external subset }
{$IFDEF XML_DTD }
          if (Parser.DoctypeSysid <> nil) or (Parser.M_useForeignDTD <> 0)
          then
          begin
            HadParamEntityRefs := Dtd.HasParamEntityRefs;
            Dtd.HasParamEntityRefs := CXmlTrue;

            if (Parser.ParamEntityParsing <> XML_ParamEntityParsing(0)) and
              (@Parser.ExternalEntityRefHandler <> nil) then
            begin
              TEntity := PEntity(Lookup(@Dtd.ParamEntities,
                @ExternalSubsetName[0], SizeOf(Expat.TEntity)));

              if TEntity = nil then
              begin
                Result := XML_ERROR_NO_MEMORY;

                Exit;
              end;

              if Parser.M_useForeignDTD <> 0 then
                TEntity.Base := Parser.CurBase;

              Dtd.ParamEntityRead := CXmlFalse;

              if Parser.ExternalEntityRefHandler
                (Parser.ExternalEntityRefHandlerArg, 0, TEntity.Base,
                TEntity.SystemId, TEntity.PublicId) = 0 then
              begin
                Result := XML_ERROR_EXTERNAL_ENTITY_HANDLING;

                Exit;
              end;

              if Dtd.ParamEntityRead <> 0 then
                if (Dtd.Standalone = 0) and
                  (@Parser.NotStandaloneHandler <> nil) and
                  (Parser.NotStandaloneHandler(Parser.HandlerArg) = 0) then
                begin
                  Result := XML_ERROR_NOT_STANDALONE;

                  Exit;
                end
                else
              else
                { if we didn't read the foreign DTD then this means that there
                  is no external subset and we must reset dtd.hasParamEntityRefs }
                if Parser.DoctypeSysid = nil then
                  Dtd.HasParamEntityRefs := HadParamEntityRefs;

              { end of DTD - no need to update dtd.keepProcessing }
            end;

            Parser.M_useForeignDTD := CXmlFalse;
          end;

{$ENDIF}
          if @Parser.EndDoctypeDeclHandler <> nil then
          begin
            Parser.EndDoctypeDeclHandler(Parser.HandlerArg);

            HandleDefault := CXmlFalse;
          end;
        end;

      XML_ROLE_INSTANCE_START:
        begin
{$IFDEF XML_DTD}
          { if there is no DOCTYPE declaration then now is the
            last chance to read the foreign DTD }
          if Parser.M_useForeignDTD <> 0 then
          begin
            HadParamEntityRefs := Dtd.HasParamEntityRefs;
            Dtd.HasParamEntityRefs := CXmlTrue;

            if (Parser.ParamEntityParsing <> XML_ParamEntityParsing(0)) and
              (@Parser.ExternalEntityRefHandler <> nil) then
            begin
              TEntity := PEntity(Lookup(@Dtd.ParamEntities,
                @ExternalSubsetName[0], SizeOf(Expat.TEntity)));

              if TEntity = nil then
              begin
                Result := XML_ERROR_NO_MEMORY;

                Exit;
              end;

              TEntity.Base := Parser.CurBase;
              Dtd.ParamEntityRead := CXmlFalse;

              if Parser.ExternalEntityRefHandler
                (Parser.ExternalEntityRefHandlerArg, 0, TEntity.Base,
                TEntity.SystemId, TEntity.PublicId) = 0 then
              begin
                Result := XML_ERROR_EXTERNAL_ENTITY_HANDLING;

                Exit;
              end;

              if Dtd.ParamEntityRead <> 0 then
                if (Dtd.Standalone = 0) and
                  (@Parser.NotStandaloneHandler <> nil) and
                  (Parser.NotStandaloneHandler(Parser.HandlerArg) = 0) then
                begin
                  Result := XML_ERROR_NOT_STANDALONE;

                  Exit;
                end
                else
              else
                { if we didn't read the foreign DTD then this means that there
                  is no external subset and we must reset dtd.hasParamEntityRefs }
                Dtd.HasParamEntityRefs := HadParamEntityRefs;

              { end of DTD - no need to update dtd.keepProcessing }
            end;
          end;

{$ENDIF}
          Parser.TProcessor := @ContentProcessor;
          Result := ContentProcessor(Parser, S, Stop, NextPtr);

          Exit;
        end;

      XML_ROLE_ATTLIST_ELEMENT_NAME:
        begin
          Parser.DeclElementType := GetElementType(Parser, Enc, S, Next);

          if Parser.DeclElementType = nil then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

          goto CheckAttListDeclHandler;
        end;

      XML_ROLE_ATTRIBUTE_NAME:
        begin
          Parser.DeclAttributeId := GetAttributeId(Parser, Enc, S, Next);

          if Parser.DeclAttributeId = nil then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

          Parser.DeclAttributeIsCdata := CXmlFalse;
          Parser.DeclAttributeType := nil;
          Parser.DeclAttributeIsId := CXmlFalse;

          goto CheckAttListDeclHandler;
        end;

      XML_ROLE_ATTRIBUTE_TYPE_CDATA:
        begin
          Parser.DeclAttributeIsCdata := CXmlTrue;
          Parser.DeclAttributeType := @AtypeCDATA[0];

          goto CheckAttListDeclHandler;
        end;

      XML_ROLE_ATTRIBUTE_TYPE_ID:
        begin
          Parser.DeclAttributeIsId := CXmlTrue;
          Parser.DeclAttributeType := @AtypeID[0];

          goto CheckAttListDeclHandler;
        end;

      XML_ROLE_ATTRIBUTE_TYPE_IDREF:
        begin
          Parser.DeclAttributeType := @AtypeIDREF[0];

          goto CheckAttListDeclHandler;
        end;

      XML_ROLE_ATTRIBUTE_TYPE_IDREFS:
        begin
          Parser.DeclAttributeType := @AtypeIDREFS[0];

          goto CheckAttListDeclHandler;
        end;

      XML_ROLE_ATTRIBUTE_TYPE_ENTITY:
        begin
          Parser.DeclAttributeType := @AtypeENTITY[0];

          goto CheckAttListDeclHandler;
        end;

      XML_ROLE_ATTRIBUTE_TYPE_ENTITIES:
        begin
          Parser.DeclAttributeType := @AtypeENTITIES[0];

          goto CheckAttListDeclHandler;
        end;

      XML_ROLE_ATTRIBUTE_TYPE_NMTOKEN:
        begin
          Parser.DeclAttributeType := @AtypeNMTOKEN[0];

          goto CheckAttListDeclHandler;
        end;

      XML_ROLE_ATTRIBUTE_TYPE_NMTOKENS:
        begin
          Parser.DeclAttributeType := @AtypeNMTOKENS[0];

        CheckAttListDeclHandler:
          if (Dtd.KeepProcessing <> 0) and (@Parser.AttlistDeclHandler <> nil)
          then
            HandleDefault := CXmlFalse;
        end;

      XML_ROLE_ATTRIBUTE_ENUM_VALUE, XML_ROLE_ATTRIBUTE_NOTATION_VALUE:
        if (Dtd.KeepProcessing <> 0) and (@Parser.AttlistDeclHandler <> nil)
        then
        begin
          if Parser.DeclAttributeType <> nil then
            TPrefix := @EnumValueSep[0]

          else if Role = XML_ROLE_ATTRIBUTE_NOTATION_VALUE then
            TPrefix := @NotationPrefix[0]
          else
            TPrefix := @EnumValueStart[0];

          if PoolAppendString(@Parser.TempPool, TPrefix) = nil then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

          if PoolAppend(@Parser.TempPool, Enc, S, Next) = nil then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

          Parser.DeclAttributeType := Parser.TempPool.Start;

          HandleDefault := CXmlFalse;
        end;

      XML_ROLE_IMPLIED_ATTRIBUTE_VALUE, XML_ROLE_REQUIRED_ATTRIBUTE_VALUE:
        if Dtd.KeepProcessing <> 0 then
        begin
          if DefineAttribute(Parser.DeclElementType, Parser.DeclAttributeId,
            Parser.DeclAttributeIsCdata, Parser.DeclAttributeIsId, 0,
            Parser) = 0 then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

          if (@Parser.AttlistDeclHandler <> nil) and
            (Parser.DeclAttributeType <> nil) then
          begin
            if (Parser.DeclAttributeType^ = XML_T('(')) or
              ((Parser.DeclAttributeType^ = XML_T('N')) and
              (XML_PAnsiChar(PtrComp(Parser.DeclAttributeType) + 1)
              ^ = XML_T('O'))) then
            begin
              { Enumerated or Notation type }
              if (PoolAppendChar(@Parser.TempPool, XML_T(')')) = 0) or
                (PoolAppendChar(@Parser.TempPool, XML_T(#0)) = 0) then
              begin
                Result := XML_ERROR_NO_MEMORY;

                Exit;
              end;

              Parser.DeclAttributeType := Parser.TempPool.Start;

              PoolFinish(@Parser.TempPool);
            end;

            EventEndPP^ := S;

            Parser.AttlistDeclHandler(Parser.HandlerArg,
              Parser.DeclElementType.Name, Parser.DeclAttributeId.Name,
              Parser.DeclAttributeType, 0,
              Integer(Role = XML_ROLE_REQUIRED_ATTRIBUTE_VALUE));

            PoolClear(@Parser.TempPool);

            HandleDefault := CXmlFalse;
          end;
        end;

      XML_ROLE_DEFAULT_ATTRIBUTE_VALUE, XML_ROLE_FIXED_ATTRIBUTE_VALUE:
        if Dtd.KeepProcessing <> 0 then
        begin
          Result_ := StoreAttributeValue(Parser, Enc,
            Parser.DeclAttributeIsCdata,
            PAnsiChar(PtrComp(S) + Enc.MinBytesPerChar),
            PAnsiChar(PtrComp(Next) - Enc.MinBytesPerChar), @Dtd.Pool);

          if Result_ <> XML_Error(0) then
          begin
            Result := Result_;

            Exit;
          end;

          AttVal := PoolStart(@Dtd.Pool);

          PoolFinish(@Dtd.Pool);

          { ID attributes aren't alLowed to have a default }
          if DefineAttribute(Parser.DeclElementType, Parser.DeclAttributeId,
            Parser.DeclAttributeIsCdata, CXmlFalse, AttVal, Parser) = 0 then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

          if (@Parser.AttlistDeclHandler <> nil) and
            (Parser.DeclAttributeType <> nil) then
          begin
            if (Parser.DeclAttributeType^ = XML_T('(')) or
              ((Parser.DeclAttributeType^ = XML_T('N')) and
              (XML_PAnsiChar(PtrComp(Parser.DeclAttributeType) + 1)
              ^ = XML_T('O'))) then
            begin
              { Enumerated or Notation type }
              if (PoolAppendChar(@Parser.TempPool, XML_T(')')) = 0) or
                (PoolAppendChar(@Parser.TempPool, XML_T(#0)) = 0) then
              begin
                Result := XML_ERROR_NO_MEMORY;

                Exit;
              end;

              Parser.DeclAttributeType := Parser.TempPool.Start;

              PoolFinish(@Parser.TempPool);

            end;

            EventEndPP^ := S;

            Parser.AttlistDeclHandler(Parser.HandlerArg,
              Parser.DeclElementType.Name, Parser.DeclAttributeId.Name,
              Parser.DeclAttributeType, AttVal,
              Integer(Role = XML_ROLE_FIXED_ATTRIBUTE_VALUE));

            PoolClear(@Parser.TempPool);

            HandleDefault := CXmlFalse;
          end;
        end;

      XML_ROLE_ENTITY_VALUE:
        if Dtd.KeepProcessing <> 0 then
        begin
          Result_ := StoreEntityValue(Parser, Enc,
            PAnsiChar(PtrComp(S) + Enc.MinBytesPerChar),
            PAnsiChar(PtrComp(Next) - Enc.MinBytesPerChar));

          if Parser.DeclEntity <> nil then
          begin
            Parser.DeclEntity.TextPtr := PoolStart(@Dtd.EntityValuePool);
            Parser.DeclEntity.TextLen := PoolLength(@Dtd.EntityValuePool);

            PoolFinish(@Dtd.EntityValuePool);

            if @Parser.EntityDeclHandler <> nil then
            begin
              EventEndPP^ := S;

              Parser.EntityDeclHandler(Parser.HandlerArg,
                Parser.DeclEntity.Name, Parser.DeclEntity.Is_param,
                Parser.DeclEntity.TextPtr, Parser.DeclEntity.TextLen,
                Parser.CurBase, 0, 0, 0);

              HandleDefault := CXmlFalse;
            end;
          end
          else
            PoolDiscard(@Dtd.EntityValuePool);

          if Result_ <> XML_ERROR_NONE then
          begin
            Result := Result_;

            Exit;
          end;
        end;

      XML_ROLE_DOCTYPE_SYSTEM_ID:
        begin
{$IFDEF XML_DTD}
          Parser.M_useForeignDTD := CXmlFalse;

{$ENDIF}
          Dtd.HasParamEntityRefs := CXmlTrue;

          if @Parser.StartDoctypeDeclHandler <> nil then
          begin
            Parser.DoctypeSysid := PoolStoreString(@Parser.TempPool, Enc,
              PAnsiChar(PtrComp(S) + Enc.MinBytesPerChar),
              PAnsiChar(PtrComp(Next) - Enc.MinBytesPerChar));

            if Parser.DoctypeSysid = nil then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            PoolFinish(@Parser.TempPool);

            HandleDefault := CXmlFalse;
          end
{$IFDEF XML_DTD}
          else
            { use externalSubsetName to make doctypeSysid non-NULL
              for the case where no startDoctypeDeclHandler is set }
            Parser.DoctypeSysid := @ExternalSubsetName[0];

{$ELSE}; {$ENDIF}
          if (Dtd.Standalone = 0) and
{$IFDEF XML_DTD}
            (Parser.ParamEntityParsing = XML_ParamEntityParsing(0)) and
{$ENDIF}
            (@Parser.NotStandaloneHandler <> nil) and
            (Parser.NotStandaloneHandler(Parser.HandlerArg) = 0) then
          begin
            Result := XML_ERROR_NOT_STANDALONE;

            Exit;
          end;

{$IFNDEF XML_DTD}
{$ELSE}
          if Parser.DeclEntity = nil then
          begin
            Parser.DeclEntity :=
              PEntity(Lookup(@Dtd.ParamEntities, @ExternalSubsetName[0],
              SizeOf(Expat.TEntity)));

            if Parser.DeclEntity = nil then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            Parser.DeclEntity.PublicId := nil;
          end;

{$ENDIF}
          { fall through }
          goto _go1;
        end;

      XML_ROLE_ENTITY_SYSTEM_ID:
      _go1:
        if (Dtd.KeepProcessing <> 0) and (Parser.DeclEntity <> nil) then
        begin
          Parser.DeclEntity.SystemId := PoolStoreString(@Dtd.Pool, Enc,
            PAnsiChar(PtrComp(S) + Enc.MinBytesPerChar),
            PAnsiChar(PtrComp(Next) - Enc.MinBytesPerChar));

          if Parser.DeclEntity.SystemId = nil then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

          Parser.DeclEntity.Base := Parser.CurBase;

          PoolFinish(@Dtd.Pool);

          if @Parser.EntityDeclHandler <> nil then
            HandleDefault := CXmlFalse;
        end;

      XML_ROLE_ENTITY_COMPLETE:
        if (Dtd.KeepProcessing <> 0) and (Parser.DeclEntity <> nil) and
          (@Parser.EntityDeclHandler <> nil) then
        begin
          EventEndPP^ := S;

          Parser.EntityDeclHandler(Parser.HandlerArg,
            Parser.DeclEntity.Name, Parser.DeclEntity.Is_param, 0, 0,
            Parser.DeclEntity.Base, Parser.DeclEntity.SystemId,
            Parser.DeclEntity.PublicId, 0);

          HandleDefault := CXmlFalse;
        end;

      XML_ROLE_ENTITY_NOTATION_NAME:
        if (Dtd.KeepProcessing <> 0) and (Parser.DeclEntity <> nil) then
        begin
          Parser.DeclEntity.Notation := PoolStoreString(@Dtd.Pool,
            Enc, S, Next);

          if Parser.DeclEntity.Notation = nil then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

          PoolFinish(@Dtd.Pool);

          if @Parser.UnparsedEntityDeclHandler <> nil then
          begin
            EventEndPP^ := S;

            Parser.UnparsedEntityDeclHandler(Parser.HandlerArg,
              Parser.DeclEntity.Name, Parser.DeclEntity.Base,
              Parser.DeclEntity.SystemId, Parser.DeclEntity.PublicId,
              Parser.DeclEntity.Notation);

            HandleDefault := CXmlFalse;
          end
          else if @Parser.EntityDeclHandler <> nil then
          begin
            EventEndPP^ := S;

            Parser.EntityDeclHandler(Parser.HandlerArg,
              Parser.DeclEntity.Name, 0, 0, 0, Parser.DeclEntity.Base,
              Parser.DeclEntity.SystemId, Parser.DeclEntity.PublicId,
              Parser.DeclEntity.Notation);

            HandleDefault := CXmlFalse;
          end;
        end;

      XML_ROLE_GENERAL_ENTITY_NAME:
        begin
          if XmlPredefinedEntityName(Enc, Pointer(S), Pointer(Next)) <> 0 then
          begin
            Parser.DeclEntity := nil;

            goto _break;
          end;

          if Dtd.KeepProcessing <> 0 then
          begin
            name := PoolStoreString(@Dtd.Pool, Enc, S, Next);

            if name = nil then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            Parser.DeclEntity :=
              PEntity(Lookup(@Dtd.GeneralEntities, name,
              SizeOf(Expat.TEntity)));

            if Parser.DeclEntity = nil then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            if Parser.DeclEntity.Name <> name then
            begin
              PoolDiscard(@Dtd.Pool);

              Parser.DeclEntity := nil;
            end
            else
            begin
              PoolFinish(@Dtd.Pool);

              Parser.DeclEntity.PublicId := nil;
              Parser.DeclEntity.Is_param := CXmlFalse;

              { if we have a parent parser or are reading an internal parameter
                TEntity, then the TEntity declaration is not considered "internal" }
              Parser.DeclEntity.IsInternal :=
                XML_Bool(not((Parser.ParentParser <> nil) or
                (Parser.OpenInternalEntities <> nil)));

              if @Parser.EntityDeclHandler <> nil then
                HandleDefault := CXmlFalse;
            end;
          end
          else
          begin
            PoolDiscard(@Dtd.Pool);

            Parser.DeclEntity := nil;
          end;
        end;

      XML_ROLE_PARAM_ENTITY_NAME:
{$IFDEF XML_DTD}
        if Dtd.KeepProcessing <> 0 then
        begin
          name := PoolStoreString(@Dtd.Pool, Enc, S, Next);

          if name <> nil then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

          Parser.DeclEntity :=
            PEntity(Lookup(@Dtd.ParamEntities, name, SizeOf(Expat.TEntity)));

          if Parser.DeclEntity = nil then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

          if Parser.DeclEntity.Name <> name then
          begin
            PoolDiscard(@Dtd.Pool);

            Parser.DeclEntity := nil;
          end
          else
          begin
            PoolFinish(@Dtd.Pool);

            Parser.DeclEntity.PublicId := nil;
            Parser.DeclEntity.Is_param := CXmlTrue;

            { if we have a parent parser or are reading an internal parameter
              TEntity, then the TEntity declaration is not considered "internal" }
            Parser.DeclEntity.IsInternal :=
              XML_Bool(not((Parser.ParentParser <> nil) or
              (Parser.OpenInternalEntities <> nil)));

            if @Parser.EntityDeclHandler <> nil then
              HandleDefault := CXmlFalse;
          end;
        end
        else
        begin
          PoolDiscard(@Dtd.Pool);

          Parser.DeclEntity := nil;
        end;

{$ELSE}
        Parser.DeclEntity := nil;

{$ENDIF}
      XML_ROLE_NOTATION_NAME:
        begin
          Parser.DeclNotationPublicId := nil;
          Parser.DeclNotationName := nil;

          if @Parser.NotationDeclHandler <> nil then
          begin
            Parser.DeclNotationName := PoolStoreString(@Parser.TempPool,
              Enc, S, Next);

            if Parser.DeclNotationName = nil then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            PoolFinish(@Parser.TempPool);

            HandleDefault := CXmlFalse;
          end;
        end;

      XML_ROLE_NOTATION_PUBLIC_ID:
        begin
          if XmlIsPublicId(Enc, Pointer(S), Pointer(Next), Pointer(EventPP)) = 0
          then
          begin
            Result := XML_ERROR_PUBLICID;

            Exit;
          end;

          if Parser.DeclNotationName <> nil
          then { means notationDeclHandler <> NIL }
          begin
            Tem := PoolStoreString(@Parser.TempPool, Enc,
              PAnsiChar(PtrComp(S) + Enc.MinBytesPerChar),
              PAnsiChar(PtrComp(Next) - Enc.MinBytesPerChar));

            if Tem = nil then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            NormalizePublicId(Tem);

            Parser.DeclNotationPublicId := Tem;

            PoolFinish(@Parser.TempPool);

            HandleDefault := CXmlFalse;
          end;
        end;

      XML_ROLE_NOTATION_SYSTEM_ID:
        begin
          if (Parser.DeclNotationName <> nil) and
            (@Parser.NotationDeclHandler <> nil) then
          begin
            SystemId := PoolStoreString(@Parser.TempPool, Enc,
              PAnsiChar(PtrComp(S) + Enc.MinBytesPerChar),
              PAnsiChar(PtrComp(Next) - Enc.MinBytesPerChar));

            if SystemId = nil then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            EventEndPP^ := S;

            Parser.NotationDeclHandler(Parser.HandlerArg,
              Parser.DeclNotationName, Parser.CurBase, SystemId,
              Parser.DeclNotationPublicId);

            HandleDefault := CXmlFalse;
          end;

          PoolClear(@Parser.TempPool);
        end;

      XML_ROLE_NOTATION_NO_SYSTEM_ID:
        begin
          if (Parser.DeclNotationPublicId <> nil) and
            (@Parser.NotationDeclHandler <> nil) then
          begin
            EventEndPP^ := S;

            Parser.NotationDeclHandler(Parser.HandlerArg,
              Parser.DeclNotationName, Parser.CurBase, 0,
              Parser.DeclNotationPublicId);

            HandleDefault := CXmlFalse;
          end;

          PoolClear(@Parser.TempPool);
        end;

      XML_ROLE_ERROR:
        case Tok of
          XML_TOK_PARAM_ENTITY_REF:
            { PE references in internal subset are
              not alLowed within declarations. }
            begin
              Result := XML_ERROR_PARAM_ENTITY_REF;

              Exit;
            end;

          XML_TOK_XML_DECL:
            begin
              Result := XML_ERROR_MISPLACED_XML_PI;

              Exit;
            end;

        else
          begin
            Result := XML_ERROR_SYNTAX;

            Exit;
          end;
        end;

{$IFDEF XML_DTD}
      XML_ROLE_IGNORE_SECT:
        begin
          if @Parser.DefaultHandler <> nil then
            ReportDefault(Parser, Enc, S, Next);

          HandleDefault := CXmlFalse;

          Result_ := DoIgnoreSection(Parser, Enc, @Next, Stop, NextPtr,
            HaveMore);

          if Result_ <> XML_ERROR_NONE then
          begin
            Result := Result_;

            Exit;
          end
          else if Next = nil then
          begin
            Parser.TProcessor := @IgnoreSectionProcessor;

            Result := Result_;

            Exit;
          end;
        end;

{$ENDIF}
      XML_ROLE_GROUP_OPEN:
        begin
          if Parser.PrologState.Level >= Parser.GroupSize then
            if Parser.GroupSize <> 0 then
            begin
              Parser.GroupSize := Parser.GroupSize * 2;

              if Parser.Mem.Realloc_fcn(Pointer(Parser.GroupConnector),
                Parser.M_groupAlloc, Parser.GroupSize) then
                Parser.M_groupAlloc := Parser.GroupSize

              else
              begin
                Result := XML_ERROR_NO_MEMORY;

                Exit;
              end;

              if Dtd.ScaffIndex <> nil then
                if Parser.Mem.Realloc_fcn(Pointer(Dtd.ScaffIndex),
                  Dtd.ScaffAlloc, Parser.GroupSize * SizeOf(Integer)) then
                  Dtd.ScaffAlloc := Parser.GroupSize * SizeOf(Integer)

                else
                begin
                  Result := XML_ERROR_NO_MEMORY;

                  Exit;
                end;
            end
            else
            begin
              Parser.GroupSize := 32;

              if Parser.Mem.Malloc_fcn(Pointer(Parser.GroupConnector),
                Parser.GroupSize) then
                Parser.M_groupAlloc := Parser.GroupSize
              else
              begin
                Result := XML_ERROR_NO_MEMORY;

                Exit;
              end;
            end;

          PAnsiChar(PtrComp(Parser.GroupConnector) +
            Parser.PrologState.Level)^ := #0;

          if Dtd.In_eldecl <> 0 then
          begin
            Myindex := NextScaffoldPart(Parser);

            if Myindex < 0 then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            PInteger(PtrComp(Dtd.ScaffIndex) + Dtd.ScaffLevel * SizeOf(Integer))^
              := Myindex;

            Inc(Dtd.ScaffLevel);

            PContentScaffold(PtrComp(Dtd.Scaffold) + Myindex *
              SizeOf(TContentScaffold))^.Type_ := XML_CTYPE_SEQ;

            if @Parser.ElementDeclHandler <> nil then
              HandleDefault := CXmlFalse;
          end;
        end;

      XML_ROLE_GROUP_SEQUENCE:
        begin
          if PAnsiChar(PtrComp(Parser.GroupConnector) +
            Parser.PrologState.Level)^ = '|' then
          begin
            Result := XML_ERROR_SYNTAX;

            Exit;
          end;

          PAnsiChar(PtrComp(Parser.GroupConnector) +
            Parser.PrologState.Level)^ := ',';

          if (Dtd.In_eldecl <> 0) and (@Parser.ElementDeclHandler <> nil) then
            HandleDefault := CXmlFalse;
        end;

      XML_ROLE_GROUP_CHOICE:
        begin
          if PAnsiChar(PtrComp(Parser.GroupConnector) +
            Parser.PrologState.Level)^ = ',' then
          begin
            Result := XML_ERROR_SYNTAX;

            Exit;
          end;

          if (Dtd.In_eldecl <> 0) and
            (PAnsiChar(PtrComp(Parser.GroupConnector) +
            Parser.PrologState.Level)^ <> #0) and
            (PContentScaffold(PtrComp(Dtd.Scaffold) +
            PInteger(PtrComp(Dtd.ScaffIndex) + (Dtd.ScaffLevel - 1) * SizeOf(Integer))^
            * SizeOf(TContentScaffold))^.Type_ <> XML_CTYPE_MIXED) then
          begin
            PContentScaffold(PtrComp(Dtd.Scaffold) +
              PInteger(PtrComp(Dtd.ScaffIndex) + (Dtd.ScaffLevel - 1) * SizeOf(Integer))
              ^ * SizeOf(TContentScaffold))^.Type_ := XML_CTYPE_CHOICE;

            if @Parser.ElementDeclHandler <> nil then
              HandleDefault := CXmlFalse;
          end;

          PAnsiChar(PtrComp(Parser.GroupConnector) +
            Parser.PrologState.Level)^ := '|';
        end;

      XML_ROLE_PARAM_ENTITY_REF
      {$IFDEF XML_DTD} , XML_ROLE_INNER_PARAM_ENTITY_REF: {$ELSE}: {$ENDIF}
        begin
{$IFDEF XML_DTD}
          Dtd.HasParamEntityRefs := CXmlTrue;

          if Parser.ParamEntityParsing = XML_ParamEntityParsing(0) then
            Dtd.KeepProcessing := Dtd.Standalone
          else
          begin
            name := PoolStoreString(@Dtd.Pool, Enc,
              PAnsiChar(PtrComp(S) + Enc.MinBytesPerChar),
              PAnsiChar(PtrComp(Next) - Enc.MinBytesPerChar));

            if name = nil then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            TEntity := PEntity(Lookup(@Dtd.ParamEntities, name, 0));

            PoolDiscard(@Dtd.Pool);

            { first, determine if a check for an existing declaration is needed;
              if yes, check that the TEntity exists, and that it is internal,
              otherwise call the skipped TEntity handler }
            if Dtd.Standalone <> 0 then
              Ok := XML_Bool(Parser.OpenInternalEntities = nil)
            else
              Ok := XML_Bool(Dtd.HasParamEntityRefs = 0);

            if (Parser.PrologState.DocumentEntity <> 0) and (Ok <> 0) then
              if TEntity = nil then
              begin
                Result := XML_ERROR_UNDEFINED_ENTITY;

                Exit;
              end
              else if TEntity.IsInternal = 0 then
              begin
                Result := XML_ERROR_ENTITY_DECLARED_IN_PE;

                Exit;
              end
              else
            else if TEntity = nil then
            begin
              Dtd.KeepProcessing := Dtd.Standalone;

              { cannot report skipped entities in declarations }
              if (Role = XML_ROLE_PARAM_ENTITY_REF) and
                (@Parser.SkippedEntityHandler <> nil) then
              begin
                Parser.SkippedEntityHandler(Parser.HandlerArg, name, 1);

                HandleDefault := CXmlFalse;
              end;

              goto _break;
            end;

            if TEntity.Open <> 0 then
            begin
              Result := XML_ERROR_RECURSIVE_ENTITY_REF;

              Exit;
            end;

            if TEntity.TextPtr <> nil then
            begin
              if Role = XML_ROLE_PARAM_ENTITY_REF then
                BetweenDecl := CXmlTrue
              else
                BetweenDecl := CXmlFalse;

              Result_ := ProcessInternalEntity(Parser, TEntity, BetweenDecl);

              if Result_ <> XML_ERROR_NONE then
              begin
                Result := Result_;

                Exit;
              end;

              HandleDefault := CXmlFalse;

              goto _break;
            end;

            if @Parser.ExternalEntityRefHandler <> nil then
            begin
              Dtd.ParamEntityRead := CXmlFalse;
              TEntity.Open := CXmlTrue;

              if Parser.ExternalEntityRefHandler
                (Parser.ExternalEntityRefHandlerArg, nil, TEntity.Base,
                TEntity.SystemId, TEntity.PublicId) = 0 then
              begin
                TEntity.Open := CXmlFalse;

                Result := XML_ERROR_EXTERNAL_ENTITY_HANDLING;

                Exit;
              end;

              TEntity.Open := CXmlFalse;
              HandleDefault := CXmlFalse;

              if Dtd.ParamEntityRead = 0 then
              begin
                Dtd.KeepProcessing := Dtd.Standalone;

                goto _break;
              end;
            end
            else
            begin
              Dtd.KeepProcessing := Dtd.Standalone;

              goto _break;
            end;
          end;

{$ENDIF}
          if (Dtd.Standalone = 0) and (@Parser.NotStandaloneHandler <> nil)
            and (Parser.NotStandaloneHandler(Parser.HandlerArg) = 0) then
          begin
            Result := XML_ERROR_NOT_STANDALONE;

            Exit;
          end;
        end;

      { Element declaration stuff }
      XML_ROLE_ELEMENT_NAME:
        if @Parser.ElementDeclHandler <> nil then
        begin
          Parser.DeclElementType := GetElementType(Parser, Enc, S, Next);

          if Parser.DeclElementType = nil then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

          Dtd.ScaffLevel := 0;
          Dtd.ScaffCount := 0;
          Dtd.In_eldecl := CXmlTrue;
          HandleDefault := CXmlFalse;
        end;

      XML_ROLE_CONTENT_ANY, XML_ROLE_CONTENT_EMPTY:
        if Dtd.In_eldecl <> 0 then
        begin
          if @Parser.ElementDeclHandler <> nil then
          begin
            Parser.Mem.Malloc_fcn(Pointer(Content), SizeOf(TXmlContent));

            if Content = nil then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            Content.Quant := XML_CQUANT_NONE;
            Content.Name := nil;
            Content.Numchildren := 0;
            Content.Children := nil;

            if Role = XML_ROLE_CONTENT_ANY then
              Content.Type_ := XML_CTYPE_ANY
            else
              Content.Type_ := XML_CTYPE_EMPTY;

            EventEndPP^ := S;

            Parser.ElementDeclHandler(Parser.HandlerArg,
              Parser.DeclElementType.Name, Content);

            HandleDefault := CXmlFalse;
          end;

          Dtd.In_eldecl := CXmlFalse;
        end;

      XML_ROLE_CONTENT_PCDATA:
        if Dtd.In_eldecl <> 0 then
        begin
          PContentScaffold(PtrComp(Dtd.Scaffold) +
            PInteger(PtrComp(Dtd.ScaffIndex) + (Dtd.ScaffLevel - 1) * SizeOf(Integer))^
            * SizeOf(TContentScaffold))^.Type_ := XML_CTYPE_MIXED;

          if @Parser.ElementDeclHandler <> nil then
            HandleDefault := CXmlFalse;
        end;

      XML_ROLE_CONTENT_ELEMENT:
        begin
          Quant := XML_CQUANT_NONE;

          goto ElementContent;
        end;

      XML_ROLE_CONTENT_ELEMENT_OPT:
        begin
          Quant := XML_CQUANT_OPT;

          goto ElementContent;
        end;

      XML_ROLE_CONTENT_ELEMENT_REP:
        begin
          Quant := XML_CQUANT_REP;

          goto ElementContent;
        end;

      XML_ROLE_CONTENT_ELEMENT_PLUS:
        begin
          Quant := XML_CQUANT_PLUS;

        ElementContent:
          if Dtd.In_eldecl <> 0 then
          begin
            if Quant = XML_CQUANT_NONE then
              Nxt := Next
            else
              Nxt := PAnsiChar(PtrComp(Next) - Enc.MinBytesPerChar);

            Myindex := NextScaffoldPart(Parser);

            if Myindex < 0 then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            PContentScaffold(PtrComp(Dtd.Scaffold) + Myindex *
              SizeOf(TContentScaffold))^.Type_ := XML_CTYPE_NAME;

            PContentScaffold(PtrComp(Dtd.Scaffold) + Myindex *
              SizeOf(TContentScaffold))^.Quant := Quant;

            El := GetElementType(Parser, Enc, S, Nxt);

            if El = nil then
            begin
              Result := XML_ERROR_NO_MEMORY;

              Exit;
            end;

            name := El.Name;

            PContentScaffold(PtrComp(Dtd.Scaffold) + Myindex *
              SizeOf(TContentScaffold))^.Name := name;

            NameLen := 0;

            while XML_PAnsiChar(PtrComp(name) + NameLen)^ <> XML_Char(0) do
              Inc(NameLen);

            Inc(Dtd.ContentStringLen, NameLen);

            if @Parser.ElementDeclHandler <> nil then
              HandleDefault := CXmlFalse;
          end;
        end;

      XML_ROLE_GROUP_CLOSE:
        begin
          Quant := XML_CQUANT_NONE;

          goto CloseGroup;
        end;

      XML_ROLE_GROUP_CLOSE_OPT:
        begin
          Quant := XML_CQUANT_OPT;

          goto CloseGroup;
        end;

      XML_ROLE_GROUP_CLOSE_REP:
        begin
          Quant := XML_CQUANT_REP;

          goto CloseGroup;
        end;

      XML_ROLE_GROUP_CLOSE_PLUS:
        begin
          Quant := XML_CQUANT_PLUS;

        CloseGroup:
          if Dtd.In_eldecl <> 0 then
          begin
            if @Parser.ElementDeclHandler <> nil then
              HandleDefault := CXmlFalse;

            Dec(Dtd.ScaffLevel);

            PContentScaffold(PtrComp(Dtd.Scaffold) +
              PInteger(PtrComp(Dtd.ScaffIndex) + Dtd.ScaffLevel * SizeOf(Integer))^ *
              SizeOf(TContentScaffold))^.Quant := Quant;

            if Dtd.ScaffLevel = 0 then
            begin
              if HandleDefault = 0 then
              begin
                Model := Build_model(Parser);

                if Model = nil then
                begin
                  Result := XML_ERROR_NO_MEMORY;

                  Exit;
                end;

                EventEndPP^ := S;

                Parser.ElementDeclHandler(Parser.HandlerArg,
                  Parser.DeclElementType.Name, Model);
              end;

              Dtd.In_eldecl := CXmlFalse;
              Dtd.ContentStringLen := 0;
            end;
          end;
        end; { End element declaration stuff }

      XML_ROLE_PI:
        begin
          if ReportProcessingInstruction(Parser, Enc, S, Next) = 0 then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

          HandleDefault := CXmlFalse;
        end;

      XML_ROLE_COMMENT:
        begin
          if ReportComment(Parser, Enc, S, Next) = 0 then
          begin
            Result := XML_ERROR_NO_MEMORY;

            Exit;
          end;

          HandleDefault := CXmlFalse;
        end;

      XML_ROLE_NONE:
        case Tok of
          XML_TOK_BOM:
            HandleDefault := CXmlFalse;
        end;

      XML_ROLE_DOCTYPE_NONE:
        if @Parser.StartDoctypeDeclHandler <> nil then
          HandleDefault := CXmlFalse;

      XML_ROLE_ENTITY_NONE:
        if (Dtd.KeepProcessing <> 0) and (@Parser.EntityDeclHandler <> nil)
        then
          HandleDefault := CXmlFalse;

      XML_ROLE_NOTATION_NONE:
        if @Parser.NotationDeclHandler <> nil then
          HandleDefault := CXmlFalse;

      XML_ROLE_ATTLIST_NONE:
        if (Dtd.KeepProcessing <> 0) and (@Parser.AttlistDeclHandler <> nil)
        then
          HandleDefault := CXmlFalse;

      XML_ROLE_ELEMENT_NONE:
        if @Parser.ElementDeclHandler <> nil then
          HandleDefault := CXmlFalse;

    end; { end of big case }

  _break:
    if (HandleDefault = CXmlTrue) and (@Parser.DefaultHandler <> nil) then
      ReportDefault(Parser, Enc, S, Next);

    case Parser.ParsingStatus.Parsing of
      XML_SUSPENDED:
        begin
          NextPtr^ := Next;
          Result := XML_ERROR_NONE;

          Exit;
        end;

      XML_FINISHED:
        begin
          Result := XML_ERROR_ABORTED;

          Exit;
        end;

    else
      begin
        S := Next;
        Tok := XmlPrologTok(Enc, Pointer(S), Pointer(Stop), @Next);
      end;

    end;

  until False;

  { not reached }
end;

function PrologProcessor(Parser: XML_Parser; S, Stop: PAnsiChar;
  NextPtr: PPAnsiChar): XML_Error;
var
  Next: PAnsiChar;
  Tok : Integer;
begin
  Next := S;
  Tok := XmlPrologTok(Parser.Encoding, Pointer(S), Pointer(Stop), @Next);

  Result := DoProlog(Parser, Parser.Encoding, S, Stop, Tok, Next, NextPtr,
    XML_Bool(not Parser.ParsingStatus.FinalBuffer));

end;

function PrologInitProcessor(Parser: XML_Parser; S, Stop: PAnsiChar;
  NextPtr: PPAnsiChar): XML_Error;
var
  Result_: XML_Error;
begin
  Result_ := InitializeEncoding(Parser);

  if Result_ <> XML_ERROR_NONE then
  begin
    Result := Result_;

    Exit;
  end;

  Parser.TProcessor := @PrologProcessor;

  Result := PrologProcessor(Parser, S, Stop, NextPtr);
end;

procedure ParserInit(Parser: XML_Parser; EncodingName: XML_PAnsiChar);
begin
  Parser.TProcessor := @PrologInitProcessor;

  XmlPrologStateInit(@Parser.PrologState);

  if EncodingName <> nil then
    Parser.ProtocolEncodingName := PoolCopyString(@Parser.TempPool,
      EncodingName)
  else
    Parser.ProtocolEncodingName := nil;

  Parser.CurBase := nil;

  XmlInitEncoding(@Parser.InitEncoding, @Parser.Encoding, nil);

  Parser.UserData := nil;
  Parser.HandlerArg := nil;

  Parser.StartElementHandler := nil;
  Parser.EndElementHandler := nil;
  Parser.CharacterDataHandler := nil;
  Parser.ProcessingInstructionHandler := nil;
  Parser.CommentHandler := nil;
  Parser.StartCdataSectionHandler := nil;
  Parser.EndCdataSectionHandler := nil;
  Parser.DefaultHandler := nil;
  Parser.StartDoctypeDeclHandler := nil;
  Parser.EndDoctypeDeclHandler := nil;
  Parser.UnparsedEntityDeclHandler := nil;
  Parser.NotationDeclHandler := nil;
  Parser.StartNamespaceDeclHandler := nil;
  Parser.EndNamespaceDeclHandler := nil;
  Parser.NotStandaloneHandler := nil;
  Parser.ExternalEntityRefHandler := nil;
  Parser.ExternalEntityRefHandlerArg := Parser;
  Parser.SkippedEntityHandler := nil;
  Parser.ElementDeclHandler := nil;
  Parser.AttlistDeclHandler := nil;
  Parser.EntityDeclHandler := nil;
  Parser.XmlDeclHandler := nil;

  Parser.BufferPtr := Parser.Buffer;
  Parser.BufferEnd := Parser.Buffer;

  Parser.ParseEndByteIndex := 0;
  Parser.ParseEndPtr := nil;

  Parser.DeclElementType := nil;
  Parser.DeclAttributeId := nil;
  Parser.DeclEntity := nil;

  Parser.DoctypeName := nil;
  Parser.DoctypeSysid := nil;
  Parser.DoctypePubid := nil;

  Parser.DeclAttributeType := nil;
  Parser.DeclNotationName := nil;
  Parser.DeclNotationPublicId := nil;
  Parser.DeclAttributeIsCdata := CXmlFalse;
  Parser.DeclAttributeIsId := CXmlFalse;

  FillChar(Parser.Position, SizeOf(POSITION), 0);

  Parser.ErrorCode := XML_ERROR_NONE;

  Parser.EventPtr := nil;
  Parser.EventEndPtr := nil;
  Parser.PositionPtr := nil;

  Parser.OpenInternalEntities := nil;
  Parser.DefaultExpandInternalEntities := CXmlTrue;

  Parser.TagLevel := 0;
  Parser.TagStack := nil;
  Parser.InheritedBindings := nil;
  Parser.M_nSpecifiedAtts := 0;

  Parser.UnknownEncodingMem := nil;
  Parser.UnknownEncodingRelease := nil;
  Parser.UnknownEncodingData := nil;
  Parser.UnknownEncodingAlloc := 0;

  Parser.ParentParser := nil;
  Parser.ParsingStatus.Parsing := XML_INITIALIZED;

{$IFDEF XML_DTD}
  Parser.IsParamEntity := CXmlFalse;
  Parser.M_useForeignDTD := CXmlFalse;

  Parser.ParamEntityParsing := XML_PARAM_ENTITY_PARSING_NEVER;
{$ENDIF}
end;

function ParserCreate(EncodingName: XML_PAnsiChar;
  Memsuite: PXmlMemoryHandlingSuite; NameSep: XML_PAnsiChar; Dtd: DTD_ptr)
  : XML_Parser;
var
  Parser: XML_Parser;
  Mtemp : PXmlMemoryHandlingSuite;

begin
  Parser := nil;

  if Memsuite <> nil then
  begin
    Memsuite.Malloc_fcn(Pointer(Parser), SizeOf(XML_ParserStruct));

    if Parser <> nil then
    begin
      Mtemp := @Parser.Mem;

      Mtemp.Malloc_fcn := Memsuite.Malloc_fcn;
      Mtemp.Realloc_fcn := Memsuite.Realloc_fcn;
      Mtemp.Free_fcn := Memsuite.Free_fcn;
    end;
  end
  else
  begin
    Expat_getmem(Pointer(Parser), SizeOf(XML_ParserStruct));

    if Parser <> nil then
    begin
      Mtemp := @Parser.Mem;

      Mtemp.Malloc_fcn := @Expat_getmem;
      Mtemp.Realloc_fcn := @Expat_realloc;
      Mtemp.Free_fcn := @Expat_freemem;
    end;
  end;

  if Parser = nil then
  begin
    Result := nil;

    Exit;
  end;

  Parser.Buffer := nil;
  Parser.BufferLim := nil;
  Parser.AttsSize := INIT_ATTS_SIZE;

  Parser.AttsAlloc := 0;
  Parser.M_nsAttsAlloc := 0;

  Parser.Mem.Malloc_fcn(Pointer(Parser.Atts),
    Parser.AttsSize * SizeOf(ATTRIBUTE));

  if Parser.Atts = nil then
  begin
    Parser.Mem.Free_fcn(Pointer(Parser), SizeOf(XML_ParserStruct));

    Result := nil;

    Exit;
  end
  else
    Parser.AttsAlloc := Parser.AttsSize * SizeOf(ATTRIBUTE);

  Parser.Mem.Malloc_fcn(Pointer(Parser.DataBuf),
    INIT_DATA_BUF_SIZE * SizeOf(XML_Char));

  if Parser.DataBuf = nil then
  begin
    Parser.Mem.Free_fcn(Pointer(Parser.Atts), Parser.AttsAlloc);
    Parser.Mem.Free_fcn(Pointer(Parser), SizeOf(XML_ParserStruct));

    Result := nil;

    Exit;
  end;

  Parser.DataBufEnd := XML_PAnsiChar(PtrComp(Parser.DataBuf) +
    INIT_DATA_BUF_SIZE);

  if Dtd <> nil then
    Parser.M_dtd := Dtd
  else
  begin
    Parser.M_dtd := DtdCreate(@Parser.Mem);

    if Parser.M_dtd = nil then
    begin
      Parser.Mem.Free_fcn(Pointer(Parser.DataBuf),
        INIT_DATA_BUF_SIZE * SizeOf(XML_Char));
      Parser.Mem.Free_fcn(Pointer(Parser.Atts), Parser.AttsAlloc);
      Parser.Mem.Free_fcn(Pointer(Parser), SizeOf(XML_ParserStruct));

      Result := nil;

      Exit;
    end;
  end;

  Parser.FreeBindingList := nil;
  Parser.FreeTagList := nil;
  Parser.FreeInternalEntities := nil;

  Parser.GroupSize := 0;
  Parser.M_groupAlloc := 0;
  Parser.GroupConnector := nil;

  Parser.UnknownEncodingHandler := nil;
  Parser.UnknownEncodingHandlerData := nil;

  Parser.NamespaceSeparator := '!';

  Parser.M_ns := CXmlFalse;
  Parser.M_ns_triplets := CXmlFalse;

  Parser.M_nsAtts := nil;
  Parser.M_nsAttsVersion := 0;
  Parser.M_nsAttsPower := 0;

  PoolInit(@Parser.TempPool, @Parser.Mem);
  PoolInit(@Parser.M_temp2Pool, @Parser.Mem);
  ParserInit(Parser, EncodingName);

  if (EncodingName <> nil) and (Parser.ProtocolEncodingName = nil) then
  begin
    XML_ParserFree(Parser);

    Result := nil;

    Exit;
  end;

  if NameSep <> nil then
  begin
    Parser.M_ns := CXmlTrue;

    Parser.InternalEncoding := XmlGetInternalEncodingNS;
    Parser.NamespaceSeparator := NameSep^;
  end
  else
    Parser.InternalEncoding := XmlGetInternalEncoding;

  Result := Parser;
end;

function SetContext(Parser: XML_Parser; Context: XML_PAnsiChar): XML_Bool;
begin
end;

function XML_ParserCreate;
begin
  Result := XML_ParserCreate_MM(Encoding, nil, nil);
end;

function XML_ParserCreate_MM;
var
  Parser: XML_Parser;
begin
  Parser := ParserCreate(Encoding, Memsuite, NamespaceSeparator, nil);

  if (Parser <> nil) and (Parser.M_ns <> 0) then
    { implicit context only set for root parser, since child
      parsers (i.e. external TEntity parsers) will inherit it }
    if not SetContext(Parser, @ImplicitContext[0]) <> 0 then
    begin
      XML_ParserFree(Parser);

      Result := nil;
      Exit;
    end;

  Result := Parser;
end;

procedure XML_SetUserData;
begin
  if Parser.HandlerArg = Parser.UserData then
  begin
    Parser.HandlerArg := UserData;
    Parser.UserData := UserData;
  end
  else
    Parser.UserData := UserData;
end;

procedure XML_SetElementHandler;
begin
  Parser.StartElementHandler := Start;
  Parser.EndElementHandler := End_;
end;

procedure XML_SetCharacterDataHandler;
begin
  Parser.CharacterDataHandler := Handler;
end;

function XML_GetBuffer(Parser: XML_Parser; Len: Integer): Pointer;
var
  NeededSize, Keep, Offset, BufferSize: Integer;
  NewBuf: PAnsiChar;
begin
  case Parser.ParsingStatus.Parsing of
    XML_SUSPENDED:
      begin
        Parser.ErrorCode := XML_ERROR_SUSPENDED;
        Result := nil;
        Exit;
      end;

    XML_FINISHED:
      begin
        Parser.ErrorCode := XML_ERROR_FINISHED;
        Result := nil;
        Exit;
      end;
  end;

  if Len > PtrComp(Parser.BufferLim) - PtrComp(Parser.BufferEnd) then
  begin
    { FIXME avoid integer overflow }
    NeededSize := Len + (PtrComp(Parser.BufferEnd) -
      PtrComp(Parser.BufferPtr));

{$IFDEF XML_CONTEXT_BYTES}
    Keep := PtrComp(Parser.BufferPtr) - PtrComp(Parser.Buffer);

    if Keep > _XML_CONTEXT_BYTES then
      Keep := _XML_CONTEXT_BYTES;

    Inc(NeededSize, Keep);

{$ENDIF}
    if NeededSize <= PtrComp(Parser.BufferLim) - PtrComp(Parser.Buffer) then
    begin
{$IFDEF XML_CONTEXT_BYTES}
      if Keep < PtrComp(Parser.BufferPtr) - PtrComp(Parser.Buffer) then
      begin
        Offset := PtrComp(Parser.BufferPtr) - PtrComp(Parser.Buffer) - Keep;

        Move(PAnsiChar(PtrComp(Parser.Buffer) + Offset)^, Parser.Buffer^,
          PtrComp(Parser.BufferEnd) - PtrComp(Parser.BufferPtr) + Keep);

        Dec(PtrComp(Parser.BufferEnd), Offset);
        Dec(PtrComp(Parser.BufferPtr), Offset);

      end;

{$ELSE}
      Move(Parser.BufferPtr^, Parser.Buffer^, PtrComp(Parser.BufferEnd) -
        PtrComp(Parser.BufferPtr));

      Parser.BufferEnd := PAnsiChar(PtrComp(Parser.Buffer) +
        (PtrComp(Parser.BufferEnd) - PtrComp(Parser.BufferPtr)));
      Parser.BufferPtr := Parser.Buffer;
{$ENDIF}
    end
    else
    begin
      BufferSize := PtrComp(Parser.BufferLim) - PtrComp(Parser.BufferPtr);

      if BufferSize = 0 then
        BufferSize := INIT_BUFFER_SIZE;

      repeat
        BufferSize := BufferSize * 2;

      until BufferSize >= NeededSize;

      Parser.Mem.Malloc_fcn(Pointer(NewBuf), BufferSize);

      if NewBuf = nil then
      begin
        Parser.ErrorCode := XML_ERROR_NO_MEMORY;

        Result := nil;

        Exit;
      end;

      Parser.BufferLim := PAnsiChar(PtrComp(NewBuf) + BufferSize);

{$IFDEF XML_CONTEXT_BYTES}
      if Parser.BufferPtr <> nil then
      begin
        Keep := PtrComp(Parser.BufferPtr) - PtrComp(Parser.Buffer);

        if Keep > _XML_CONTEXT_BYTES then
          Keep := _XML_CONTEXT_BYTES;

        Move(PAnsiChar(PtrComp(Parser.BufferPtr) - Keep)^, NewBuf^,
          PtrComp(Parser.BufferEnd) - PtrComp(Parser.BufferPtr) + Keep);

        Expat_freemem(Pointer(Parser.Buffer), Parser.BufferAloc);

        Parser.Buffer := NewBuf;
        Parser.BufferAloc := BufferSize;

        Parser.BufferEnd :=
          PAnsiChar(PtrComp(Parser.Buffer) + (PtrComp(Parser.BufferEnd) -
          PtrComp(Parser.BufferPtr)) + Keep);

        Parser.BufferPtr := PAnsiChar(PtrComp(Parser.Buffer) + Keep);

      end
      else
      begin
        Parser.BufferEnd :=
          PAnsiChar(PtrComp(NewBuf) + (PtrComp(Parser.BufferEnd) -
          PtrComp(Parser.BufferPtr)));
        Parser.Buffer := NewBuf;
        Parser.BufferPtr := NewBuf;
        Parser.BufferAloc := BufferSize;
      end;
{$ELSE}
      if Parser.BufferPtr <> nil then
      begin
        Move(Parser.BufferPtr^, NewBuf^, PtrComp(Parser.BufferEnd) -
          PtrComp(Parser.BufferPtr));

        Expat_freemem(Pointer(Parser.Buffer), Parser.BufferAloc);
      end;

      Parser.BufferEnd :=
        PAnsiChar(PtrComp(NewBuf) + (PtrComp(Parser.BufferEnd) -
        PtrComp(Parser.BufferPtr)));
      Parser.Buffer := NewBuf;
      Parser.BufferPtr := NewBuf;
      Parser.BufferAloc := BufferSize;
{$ENDIF}
    end;
  end;

  Result := Parser.BufferEnd;
end;

function ErrorProcessor(Parser: XML_Parser; S, Stop: PAnsiChar;
  NextPtr: PPAnsiChar): XML_Error;
begin
  Result := Parser.ErrorCode;
end;

function XML_ParseBuffer(Parser: XML_Parser; Len, IsFinal: Integer): XML_Status;
var
  Start  : PAnsiChar;
  Result_: XML_Status;

begin
  Result_ := XML_STATUS_OK;

  case Parser.ParsingStatus.Parsing of
    XML_SUSPENDED:
      begin
        Parser.ErrorCode := XML_ERROR_SUSPENDED;

        Result := XML_STATUS_ERROR;

        Exit;
      end;

    XML_FINISHED:
      begin
        Parser.ErrorCode := XML_ERROR_FINISHED;

        Result := XML_STATUS_ERROR;

        Exit;
      end;

  else
    Parser.ParsingStatus.Parsing := XML_PARSING_;
  end;

  Start := Parser.BufferPtr;
  Parser.PositionPtr := Start;

  Inc(PtrComp(Parser.BufferEnd), Len);

  Parser.ParseEndPtr := Parser.BufferEnd;

  Inc(PtrComp(Parser.ParseEndByteIndex), Len);

  Parser.ParsingStatus.FinalBuffer := XML_Bool(IsFinal);

  Parser.ErrorCode := Parser.TProcessor(Parser, Start, Parser.ParseEndPtr,
    @Parser.BufferPtr);

  if Parser.ErrorCode <> XML_ERROR_NONE then
  begin
    Parser.EventEndPtr := Parser.EventPtr;
    Parser.TProcessor := @ErrorProcessor;

    Result := XML_STATUS_ERROR;

    Exit;
  end
  else
    case Parser.ParsingStatus.Parsing of
      XML_SUSPENDED:
        Result_ := XML_STATUS_SUSPENDED;

      XML_INITIALIZED, XML_PARSING_:
        if IsFinal <> 0 then
        begin
          Parser.ParsingStatus.Parsing := XML_FINISHED;

          Result := Result_;

          Exit;
        end;
    else
      { should not happen }
      NoP;
    end;

  Parser.Encoding.UpdatePosition(Parser.Encoding,
    Pointer(Parser.PositionPtr), Pointer(Parser.BufferPtr),
    @Parser.Position);

  Parser.PositionPtr := Parser.BufferPtr;

  Result := Result_;
end;

function XML_Parse;
var
  Buff: Pointer;
begin
  case Parser.ParsingStatus.Parsing of
    XML_SUSPENDED:
      begin
        Parser.ErrorCode := XML_ERROR_SUSPENDED;

        Result := XML_STATUS_ERROR;

        Exit;
      end;

    XML_FINISHED:
      begin
        Parser.ErrorCode := XML_ERROR_FINISHED;

        Result := XML_STATUS_ERROR;

        Exit;
      end;

  else
    Parser.ParsingStatus.Parsing := XML_PARSING_;
  end;

  if Len = 0 then
    NoP
{$IFNDEF XML_CONTEXT_BYTES}
  else if Parser.BufferPtr = Parser.BufferEnd then
    NoP
{$ENDIF}
  else
  begin
    Buff := XML_GetBuffer(Parser, Len);

    if Buff = nil then
      Result := XML_STATUS_ERROR

    else
    begin
      Move(S^, Buff^, Len);

      Result := XML_ParseBuffer(Parser, Len, IsFinal);
    end;
  end;
end;

function XML_GetErrorCode;
begin
end;

function XML_ErrorString;
begin
end;

function XML_GetCurrentLineNumber;
begin
end;

procedure DestroyBindings(Bindings: PBinding; Parser: XML_Parser);
var
  B: PBinding;
begin
  repeat
    B := Bindings;

    if B = nil then
      Break;

    Bindings := B.NextTagBinding;

    Parser.Mem.Free_fcn(Pointer(B.Uri), B.UriAlloc);
    Parser.Mem.Free_fcn(Pointer(B), SizeOf(Expat.TBinding));

  until False;
end;

procedure XML_ParserFree;
var
  TagList, P: TAG_ptr;

  EntityList, OpenEntity: POpenInternalEntity;
begin
  if Parser = nil then
    Exit;

  { free tagStack and freeTagList }
  TagList := Parser.TagStack;

  repeat
    if TagList = nil then
    begin
      if Parser.FreeTagList = nil then
        Break;

      TagList := Parser.FreeTagList;

      Parser.FreeTagList := nil;

    end;

    P := TagList;
    TagList := TagList.Parent;

    Parser.Mem.Free_fcn(Pointer(P.Buf), P.Alloc);
    DestroyBindings(P.Bindings, Parser);
    Parser.Mem.Free_fcn(Pointer(P), SizeOf(Expat.TAG));

  until False;

  { free openInternalEntities and freeInternalEntities }
  EntityList := Parser.OpenInternalEntities;

  repeat
    if EntityList = nil then
    begin
      if Parser.FreeInternalEntities = nil then
        Break;

      EntityList := Parser.FreeInternalEntities;

      Parser.FreeInternalEntities := nil;

    end;

    OpenEntity := EntityList;
    EntityList := EntityList.Next;

    Parser.Mem.Free_fcn(Pointer(OpenEntity), SizeOf(TOpenInternalEntity));

  until False;

  DestroyBindings(Parser.FreeBindingList, Parser);
  DestroyBindings(Parser.InheritedBindings, Parser);

  PoolDestroy(@Parser.TempPool);
  PoolDestroy(@Parser.M_temp2Pool);

{$IFDEF XML_DTD}
  { external parameter TEntity parsers share the DTD structure
    parser->m_dtd with the root parser, so we must not destroy it }
  if (Parser.IsParamEntity = 0) and (Parser.M_dtd <> nil) then
{$ELSE}
  if Parser.M_dtd <> nil then {$ENDIF }
    DtdDestroy(Parser.M_dtd, XML_Bool(Parser.ParentParser = nil),
      @Parser.Mem);

  Parser.Mem.Free_fcn(Pointer(Parser.Atts), Parser.AttsAlloc);
  Parser.Mem.Free_fcn(Pointer(Parser.GroupConnector), Parser.M_groupAlloc);
  Parser.Mem.Free_fcn(Pointer(Parser.Buffer), Parser.BufferAloc);
  Parser.Mem.Free_fcn(Pointer(Parser.DataBuf),
    INIT_DATA_BUF_SIZE * SizeOf(XML_Char));
  Parser.Mem.Free_fcn(Pointer(Parser.M_nsAtts), Parser.M_nsAttsAlloc);
  Parser.Mem.Free_fcn(Pointer(Parser.UnknownEncodingMem),
    Parser.UnknownEncodingAlloc);

  if @Parser.UnknownEncodingRelease <> nil then
    Parser.UnknownEncodingRelease(Parser.UnknownEncodingData);

  Parser.Mem.Free_fcn(Pointer(Parser), SizeOf(XML_ParserStruct));
end;

end.
