#docu!/home/vsc/.local/bin/yap -L --

/** @file filter.yap
 *
 * This filter extends doxygen with YAP documentation support.
 *
 */

:- set_prolog_flag(double_quotes, string).
 
:- include(docutils).
:- include(yapops).

:-dynamic exported/3, defines_module/1,visited/1.

:- dynamic defines_module/1.
defines_module(prolog).

:- dynamic defined/1.

:- initialization(main).



valid_suffix('.yap').
valid_suffix('.pl').
valid_suffix('.prolog').
valid_suffix('.P').
valid_suffix('.ypp').

/**
 * @pred main
 *
 * Call the filter.
*/

main :-
    forall(member(F,Fs),evaluate(IDir,ODir,F)).



    forall(member(F,Fs),clmember(IDir,F)),
    forall(member(F,Fs),do(IDir,ODir,F)).


group(compound( OAtts,_OProps)) :-
    key_in(kind(Kind),OAtts),
    (
	Kind == "group"
    ->
    true
    ;
    Kind == "page"
    
    ).

class(compound( OAtts,_OProps)) :-
    key_in(kind(Kind),OAtts),
    (
	Kind == "class"
    
    ).

clmember(IDir,F) :-
    atom_concat(group,_,F),
    atom_string(F,Id),
    get_xml(IDir,Id, _Atts,Children),
    member(innerclass(Atts,_),Children),
    key_in(refid(Ref),Atts),
    atom_string(R,Ref),
    assert(edge(R,Id)),
    fail.
clmember(_,_).


do(_IDir,_ODir,'.') :-
    !.
do(_IDir,_ODir,'..') :-
    !.
do(_IDir,_ODir,F) :-
    atom_concat(_,'_8h.xml',F),
    !.
do(_IDir,_ODir,F) :-
    atom_concat(_,'_8c.xml',F),
    !.
do(_IDir,_ODir,F) :-
    atom_concat(_,'_8cxx.xml',F),
    !.
do(_IDir,_ODir,F) :-
    atom_concat(_,'_8pl.xml',F),
    !.
do(_IDir,_ODir,F) :-
    atom_concat(_,'_8yap.xml',F),
    !.
do(_IDir,_ODir,F) :-
    atom_concat(_,'_8ypp.xml',F),
    !.
do(_IDir,_ODir,F) :-
    atom_concat(_,'_8md.xml',F),
    !.
do(_IDir,_ODir,F) :-
    atom_concat(_,'_8cpp.xml',F),
    !.
do(_IDir,_ODir,F) :-
    atom_concat(_,'_8pl.xml',F),
    !.
do(_IDir,_ODir,F) :-
    atom_concat(_,'_8yap.xml',F),
    !.
do(_IDir,_ODir,F) :-
    atom_concat(Id, '.xml',F),
    atom_string(Id,S),
    sub_string(S ,_, 1, 0, Arity),
    string_chars(Arity,[Dig]),
    char_type_digit(Dig),
    !.
do(IDir,ODir,F) :-
    writeln(F),
    atom_concat(Id, '.xml',F),
    atom_concat(group, _,Id),
    % (atom_concat(group__ReadTerm,_) -> spy children2page; true),
    get_xml(IDir,Id, _Atts,Children),
    children2page([idir=IDir,odir=ODir,kind="group"],Children,All),
    path_concat([ODir,Id],OF),
    atom_concat(OF,'.md',OFile),
    open(OFile,write,O,[]),
    format(O,'~s',[All]),
    close(O).   
do(_,_,_).
 
 parents(Id,ODir,O) :-
   edge(Id, P),
    !,
    parents(P,ODir, PPath),
    path_concat([PPath,Id],O),
    ( exists_directory(PPath)
      ->
      true
      ;
      make_directory(PPath)
    ).
parents(Id,ODir,Path) :-
    path_concat([ODir,Id],Path).

sub_do(IDir,Id,All) :-
    pred(Id),
    get_xml(IDir,Id, Atts,Children),
    key_in(kind("class"),Atts),
    !,

    pred2page(Id,[idir=IDir,kind="class"],Children,All).
sub_do(_,_,"").
 
get_xml(IDir,Id,Atts,Children) :-
    path_concat([IDir,Id], XFile),
    catch(load_xml(XFile,XML),Error,(format(user_error,'failed while processsing ~w: ~w',[XFile,Error]),fail)),  
    XML = [doxygen(_,XMLData)],
    member(compounddef(Atts,Children),XMLData),
    !.

children2page(State,Children,All) :-
    get_name(Children,Name),
    as_title(Name,Children,Title),
%(Title="term_hash_E" -> spy process_all ; true ),
    foldl(process_all(State),Children,t([],[],[],[],[],[],[],[],[]),t(AllRaw,Briefs,Details,Pages,Groups,Predicates,XPreds,Infs,Locations)),
   foldl(add_text,[Briefs,Pages,Groups,Details,Predicates,XPreds,Infs,AllRaw,Locations],Text, []),
   string_concat(["# ",Title, "\n"|Text], All).

pred2page(Id,State,Children,All) :-
    get_name(Children,Name),
    as_title(Name,Children,Title),
%(Title="term_hash_E" -> spy process_all ; true ),
    foldl(process_all(State),Children,t([],[],[],[],[],[],[],[],[]),t(_AllRaw,Briefs,Details,Pages,Groups,Predicates,XPreds,_Infs,_Locations)),
   foldl(add_text,[Briefs,Pages,Groups,Predicates,Details,XPreds],Text,[]),   
   string_concat(["[](){ #",Id, "}\n## ",Title,"\n"|Text], All).

add_text([]) --> !.
add_text(H)  --> {string_concat(H, S)}, [S].







process_all(State,innerclass(Atts,_CHildren),S0s,SFs) :-
    !,
    process(State,Op,Strings,[]),
    string_concat(Strings,String),
    add2strings(Op,String,S0s,S1s),
    member(idir=IDir, State),
    key_in(refid(Ref),Atts),
    !,
    atom_string(ARef,Ref),
    sub_do(IDir,ARef,ClassText),
    add2strings(extra,(ClassText),S1s,SFs).
process_all(State,Op,S0s,SFs) :-
    %    functor(Op,N,_),
    process(State,Op,Strings,[]),
    string_concat(Strings,String),
    add2strings(Op,String,S0s,SFs),
    !.
process_all(State,Op,S0s,SFs):-
    spy process_all,
    writeln(failed:Op:State),
    (process_all(State,Op,S0s,SFs)),
    !,
    S0s=SFs.

%    spy process_all
%    process_all(State,Op,S0s,SFs).


add2strings(_,[], Target, Target) :-
   !.
add2strings(_, "", Target, Target) :-
    !.
add2strings(_,[""], Target, Target) :-
    !.
add2strings(briefdescription(_,_),Strings,Source, Target) :-
    !,
    Source = t(S, Sb, Sd, Sa, Sg, Sp, Sx, Si, Sl),
    Target = t(S, NSb, Sd, Sa, Sg, Sp, Sx, Si, Sl),
    NSb =[Strings|Sb],
    !.
add2strings(detaileddescription(_,_),Strings,Source, Target) :-
    !,
    Source = t(S, Sb, Sd, Sa, Sg, Sp, Sx, Si, Sl),
    Target = t(S, Sb, NSd, Sa, Sg, Sp, Sx, Si, Sl),
    NSd =[Strings|Sd].
add2strings(innerclass(_,_),Strings,Source, Target) :-
    !,
    Source = t(S, Sb, Sd, Sa, Sg, Sp, Sx, Si, Sl),
    Target = t(S, Sb, Sd, Sa, Sg, NSp, Sx, Si, Sl),
    NSp=[Strings|Sp].
add2strings(extra,Strings,Source, Target) :-
    !,
    Source = t(S, Sb, Sd, Sa, Sg, Sp, Sx, Si, Sl),
    Target = t(S, Sb, Sd, Sa, Sg, Sp, NSx, Si, Sl),
    NSx=["\n\n---\n\n",Strings|Sx].
add2strings(innergroup(_,_),Strings,Source, Target) :-
    !,
    Source = t(S, Sb, Sd, Sa, Sg, Sp, Sx, Si, Sl),
    Target = t(S, Sb, Sd, Sa, NSg, Sp, Sx, Si, Sl),
    NSg=[Strings|Sg].
add2strings(innerpage(_,_),Strings,Source, Target) :-
    !,
    Source = t(S, Sb, Sd, Sa, Sg, Sp, Sx, Si, Sl),
    Target = t(S, Sb, Sd, NSa, Sg, Sp, Sx, Si, Sl),
    NSa=[Strings|Sa].
add2strings(location(_,_),Strings,Source, Target) :-
    !,
    Source = t(S, Sb, Sd, Sa, Sg, Sp, Sx, Si, Sl),
    Target = t(S, Sb, Sd, Sa, Sg, Sp, Sx, Si, NSl),
    NSl=[Strings|Sl].
add2strings(_,Strings,Source, Target) :-
    Source = t(S, Sb, Sd, Sa, Sg, Sp, Sx, Si, Sl),
    Target = t(NS, Sb, Sd, Sa, Sg, Sp, Sx, Si, Sl),
    NS=[Strings|S].

		
process(_State,compoundname(_Atts,_Children)) -->
!.
process(_State,title(_Atts,_Children)) -->
!.
process(State,basecompoundref(Atts,Children)) -->
    !,
    seq(State,basecompoundref(Atts,Children)).
process(State,derivedcompoundref(Atts,Children)) -->
    !,
    seq(State,derivedcompoundref(Atts,Children)).
% incType
% ignoreseq(NState,includes(_,_),Derivedmpoundref,Includes),
% ignoreseq(NState,includedby(_,_),Includes,Includedby),
% graphType
% ignoreseq(NState,incdepgraph(_,_),Includedby,Incdepgraph),
% ignoreseq(NState,invincdepgraph(_,_),Incdepgraph,Invincdepgraph),
% refType
% ignoreseq(NState,innermodule(_,_),Invincdepgraph,Innermodule),
% ignoreseq(NState,innerdir(_,_),Innermodule,Innerdir),
% ignoreseq(NState,innerfile(_,_),Innerdir,Innerfile),
% ignoreseq(NState,innerclass(_,_),Innerfile,Innerclass),
process(State,innerclass(Atts,Children)) -->
    !,
    innerclass([kind="class"|State],Atts,Children).    % ignoreseq(NState,innernamespace(_,_),Innerclass,Innernamespace),,
process(State,innerpage(Atts,Children)) -->
    !,
    innerpage([kind="page"|State],Atts,Children).
process(State,innergroup(Atts,Children)) -->
    !,
    innergroup([kind="group"|State],Atts,Children).
% ignoreseq(NState,qualifier(_,_),Innergroup,Qualifier),
% ignoreseq(NState,templateparamlist(_,_),Qualifier,Templateparamlist),
process(_,sectiondef(Atts,Children)) -->
    !,
    sectiondef(Atts,Children).
% ignoreseq(NState,tableofcontents(_,_),Sectiondef,Tableofcontents),
% ignoreseq(NState,requiresclause(_,_),Tableofcontents,Requiresclause),
% ignoreseq(NState,initializer(_,_),Requiresclause,Initializer),
process(_,briefdescription(Atts,Children)) -->
    !,
    briefs(briefdescription(Atts,Children)).
process(_,detaileddescription(Atts,Children)) -->
    !,
    detaileds(detaileddescription(Atts,Children)),!.
%process(_,location(Atts,_Children)) -->
%    { key_in(file(F),Atts) },
%    !,
%    ["[^1]  generated by YAPDocs from ",F,"~n"].
process(_,location(_,_)) --> !.
% ignoreseq(NState,exports(_,_),Detaileddescription,Exports),
process(_NState,inheritancegraph(_,_))--> !.
process(_NState,innerdir(_,_))--> !.
process(_NState,incdepgraph(_,_))--> !.
process(_NState,invincdepgraph(_,_))--> !.
process(_NState,includedby(_,_))--> !.
process(_NState,collaborationgraph(_,_))-->!.
process(_NState,listofallmembers(_,_))--> !.
process(_NState,innerfile(_,_))--> !.
process(_NState,includes(_,_))--> !.
process(_NState,templateparamlist(_,_))--> !.
process(_NState,listofallmembersin(_,_))--> !.
process(_NState,innernamespace(_,_))--> !.
process(A,B,L,L0) :-  writeln(process(A,B,L,L0)), L=L0.

xtract_label([_,[Label]],Label) :-
    !.
xtract_label([Label],Label) :-
    !.
xtract_label(Label,Label).

innerclass(Status,Atts,AllLabel) -->
    ["\n* "], 
    {key_in(refid(Ref),Atts),
     string_concat("class", _, Ref)
    },
    !,
    {
      xtract_label(AllLabel,Label),
      decode(Label,Pred)
    },
    link_inner(Status,Ref,Pred).
innerclass(_Status,_Atts,_AllLabel) -->
    [].

innerpage(Status,Atts,AllLabel) -->
    ["\n|","[](){#",Ref,"}\n     "], 
    {key_in(refid(Ref),Atts),
     xtract_label(AllLabel,Label)},
    link_inner(Status,Ref,Label).

innergroup(Status,Atts,AllLabel) -->
    ["\n\n* "], 
    {key_in(refid(Ref),Atts),
     xtract_label(AllLabel,Label)},
    link_inner(Status,Ref,Label).

link_inner(_Status,Ref,Label) -->
    { decode(Label,PLabel) },
    ref(Ref,PLabel).

innermodule(Status,Atts,AllLabel) -->
    {key_in(refid(Ref),Atts),
     xtract_label(AllLabel,Label)},
    {
	key_in(modules=Found,Status),
	var(Found),
	!,
	Found=found
    },
    ["\n\n\n### Modules:\n"],
    ref(Ref,Label),
    ["\n."].
innermodule(_Status,Atts,AllLabel) -->
    {key_in(refid(Ref),Atts),
     xtract_label(AllLabel,Label)},
    ref(Ref,Label),
    ["\n."].


sectiondef(Atts,Els) -->
    {
	key_in(kind(Kind),Atts)
    },
    { top_sectiondef_name(Kind,Name)
    },
    !,
    ["## ",Name,":\n"],
    foldl(sectdef,Els).

v(Msg,S0,S0) :-
    writeln(Msg:S0).

sectdef(header([],[Text]))-->
    {decode(Text,PText)},
    ["\n",PText,"\n"].
sectdef(member(Atts,Children))-->
    { key_in(refid(Ref),Atts) },
	(
	 {   key_in(defname(_,[Name] ),Children) }
	->
	true
	;
	{ key_in(name(_,[Name] ),Children) }
	->
	true
	;
	Name = "" %writeln(Children)
	),
    ["%- " ],
    {decode(Name,PName)},
    ref(Ref,PName).

sectdef(memberdef(Atts,Children))-->
    { key_in(kind(Kind), Atts) },
    (
      { Kind == "enum" }
      ->
      (
      { Children=[name(_,[Name])|Extra] }
      ->
      [" case ",Name,":\n\n"]
      ;
      {Extra=Children}
      ),
      foldl(enumvalue,Extra)
      ;
    []
    ).

/* ignore for now */


enumvalue(enumvalue(_,[name(_,[Name])|Children])) -->
    !,
    ["- ",Name," "],
    get_descriptions(Children).
enumvalue(location(_,_Children)) -->
    !.
enumvalue(initializer(_,_Children)) -->
    !.
enumvalue(_What) --> 
    !.

get_descriptions(Children) -->
    get_description(briefdescription(_,Brief),Brief,Children),
    get_description(inbpdydescription(_,Brief),Brief,Children),
    get_description(detaileddescription(_,Brief),Brief,Children).


get_description(Desc, Text, Children) -->
    {key_in(Desc, Children) },
    !,
    description(Text),
    [ "\n"].
get_description(_Desc, _Text, _Children) -->
    [].

%sectiondef(A,Remainder) --> {writeln(A),fail}.
briefs(briefdescription(_Atts,Els)) -->
    !,
    description(Els).

detaileds(detaileddescription(_Atts,Els)) -->
    !,
    [ "\n"],
    detaileddescription(Els),
    [ "\n"].

detaileddescription([]) --> [].
detaileddescription([D|Detailed]) -->
    %    {writeln(D)},
    description(D),
    [ "\n\n"],
    detaileddescription( Detailed).


codeline(codeline(_,Highlights)) -->
    foldl(highlight,Highlights),
    [ "\n"].

highlight(highlight(_,Line)) -->
    foldl(rawt,Line).

rawt(L) -->
    {
      string(L)
    },
    [L].
rawt(Text) -->
    {writeln(ugh:Text)}.

rawl([]) -->
    !.


rawl([A|Text]) -->
    foldl(raw,[A|Text]).

raw(ref([refid(Id)|_],[Info])) -->
!,
ref(Id,Info).
raw(highlight(_,Text)) -->
    !,
    rawl( Text).

raw(L) -->
    {
    string(L),
      sub_string(L,Left,1,Extra,"/"),
      Left > 0,
      Extra > 0,
      Extra1  is Extra+1,
      Left2 is Left+2,
      get_string_code(Left2,L,D),
      code_type_digit(D),
    back(Left,L,NPrefix),
    NPrefix \= Left,
    !,
    sub_string(L,NPrefix,_,Extra1,Name),
      sub_string(L,0,NPrefix,_,Prefix),
      sub_string(L,Left2,_,0,RightLine),
      Arity is D-"0",
    number_string(Arity,AS),
      encode(Name/Arity,DoxName)
      %    encode_dox(DoxName0,DoxName),
    },
    [Prefix,"[",Name,"/" ,AS,"][class",DoxName,"]"],
    raw(RightLine).
raw(Text) -->
{string(Text) },
!,
[Text].


%  foldl(para).

parlist(_Pars,Items) -->
["\n"],
    foldl(paritem,Items).

paritem(parameteritem(_,List)) -->
foldl(parameternamelist,List).

parameternamelist(parameternamelist(_,Args))  -->
  foldl(parameterargs, Args).
parameternamelist(parameterdescription(_,Args))  -->
  foldl(parameterargs, Args).

parameterargs(parametername(_,[Name])) -->
 ["  ",Name].
parameterargs(parameterdescription(_,Para)) -->
  foldl(description,Para),
["\n"].
parameterargs(para(_,Para)) -->
  foldl(description,Para),
["\n"].


doxolist(_Pars,Items) -->
["\n"],
    foldl(item("1"),Items).

itemlist(_Pars,Items) -->
["\n\n"],
    foldl(item("i"),Items).

varlist(_Pars,Items) -->

["\n"],
    foldl(varentry,Items).

varentry(varlistentry(_,Terms)) -->
    [ "\n"],
maplist(term,Terms).

term(term(_,[S|_])) -->
[S].

item(Type,listitem(_,Para)) -->
    typel(Type),
    description(Para),
    ["\n"].

typel("1") -->
    [  "1. "].
typel("a") -->
    [  "a. "].
typel("A") -->
    [  "A. "].
typel("i") -->
    [  "- "].
typel("I") -->
    [  "* "].


sect( Parms, Args, _Level) -->
    (
	{  key_in(id(Id),Parms)  }
    ->
    [Id],["\n"]
    ;
[]
    ),
    (
	{ Args = [title([],[T])|Body] }
    ->
     {encode_text(T,TT)},
    [TT],["\n"]
    ;
{Body = Args},
    ["\n"]
    )
,
    description(Body).

description(para([],S)) -->
    !,
    description(S),
 ["\n\n"].
description(ref([refid(Id)|_],[Info])) -->
!,
ref(Id,Info).
description(S) -->
    { string(S) },
    !,
    raw(S).
description(title([],S)) -->
    { string(S),
      encode_text(S,T) },
    !,
    [T].
description(sect1([id(Id)],[sect2(Parms,Data)])) -->
!,
    anchor([id(Id)],[]),
    description(sect2(Parms,Data)).
description(sect1(Parms,S)) -->
!,
    sect(Parms,S,"### ").
description(sect2([id(Id)],[sect3(Parms,Data)])) -->
!,
    anchor([id(Id)],[]),
    description(sect3(Parms,Data)).
description(sect2(Parms,S)) -->
!,
    sect(Parms,S,"#### ").
description(sect3(Parms,S)) -->
!,
    sect(Parms,S,"##### ").
description(simplesect(Parms,S)) -->
!,
    sect(Parms,S," ").

description(itemizedlist(Atts,Text)) -->
    !,
    itemlist(Atts,Text).
    
description([G|S]) -->
    !,
    description(G),
    description(S).
description(S) -->
    para(S).

seq(State,G0) -->
    %    v(G0),
    {
	G0=..[_N,Atts,[NameS|Els]],
	get_name(NameS, Name),
	key_in(id(Ref),Atts),
	!,
	seqhdr(State,Type)
    } ,
    ["## ",Type,": "],
    ref(Ref,Name),
    foldl(seqdef,Els),
    ["\n"].
seq(State,G0) -->
    {
	arg(2,G0,NameS),
	!,
	get_name(NameS, Name),
	seqhdr(State,Type)
    } ,
    ["## ",Type,": ",Name,"\n"].

seqhdr(State,Name) :-
    key_in(kind=Kind, State),
    top_seq_name( Kind, Name).

top_seq_name( "class", "Class" ).
top_seq_name( "struct", "Struct" ).
top_seq_name( "union", "Union" ).
top_seq_name( "interface", "Interface" ).
top_seq_name( "protocol", "Protocol" ).
top_seq_name( "category", "Category" ).
top_seq_name( "exception", "Exception" ).
top_seq_name( "service", "Service" ).
top_seq_name( "singleton", "Singleton" ).
top_seq_name( "module", "Module" ).
top_seq_name( "type", "Type" ).
top_seq_name( "file", "File" ).
top_seq_name( "namespace", "Namespace" ).
top_seq_name( "group", "Group" ).
top_seq_name( "page", "Page" ).
top_seq_name( "example", "Example" ).
top_seq_name( "dir", "Dir" ).
top_seq_name( "concept", "Concept" ).

top_sectiondef_name( "friend", "Friends").
top_sectiondef_name( "protected-attrib", "Protected Attributes").
top_sectiondef_name( "public-func", "Public Function").
top_sectiondef_name( "public-type", "Public Type").
top_sectiondef_name( "public-type", "Public Type").

top_sectiondef_name( "user-defined", "User-defined").
top_sectiondef_name( "public-type", "Public-type" ).
top_sectiondef_name( "public-func", "Public-func" ).
top_sectiondef_name( "public-attrib", "Public-attrib" ).
top_sectiondef_name( "public-slot", "Public-slot" ).
top_sectiondef_name( "signal", "Signal" ).
top_sectiondef_name( "dcop-func", "Dcop-func" ).
top_sectiondef_name( "property", "Property" ).
top_sectiondef_name( "event", "Event" ).
top_sectiondef_name( "public-static-func", "Public-static-func" ).
top_sectiondef_name( "public-static-attrib", "Public-static-attrib" ).
top_sectiondef_name( "protected-type", "Protected-type" ).
top_sectiondef_name( "protected-func", "Protected-func" ).
top_sectiondef_name( "protected-attrib", "Protected-attrib" ).
top_sectiondef_name( "protected-slot", "Protected-slot" ).
top_sectiondef_name( "protected-static-func", "Protected-static-func" ).
top_sectiondef_name( "protected-static-attrib", "Protected-static-attrib" ).
top_sectiondef_name( "package-type", "Package-type" ).
top_sectiondef_name( "package-func", "Package-func" ).
top_sectiondef_name( "package-attrib", "Package-attrib" ).
top_sectiondef_name( "package-static-func", "Package-static-func" ).
top_sectiondef_name( "package-static-attrib", "Package-static-attrib" ).
top_sectiondef_name( "private-type", "Private-type" ).
top_sectiondef_name( "private-func", "Private-func" ).
top_sectiondef_name( "private-attrib", "Private-attrib" ).
top_sectiondef_name( "private-slot", "Private-slot" ).
top_sectiondef_name( "private-static-func", "Private-static-func" ).
top_sectiondef_name( "private-static-attrib", "Private-static-attrib" ).
top_sectiondef_name( "friend", "Friend" ).
top_sectiondef_name( "related", "Related" ).
top_sectiondef_name( "define", "Define" ).
top_sectiondef_name( "prototype", "Prototype" ).
top_sectiondef_name( "typedef", "Typedef" ).
top_sectiondef_name( "enum", "Enum" ).
top_sectiondef_name( "func", "Functions" ).
top_sectiondef_name(   "var", "Var" ).

as_title(_,Props,PredTitle) :-
key_in(title(_,[Title]), Props),
!,
decode(Title, PredTitle).
as_title(Title,_,PredTitle) :-
decode(Title, PredTitle).

bd(blockquote,"\n~~~\n").
bd(bold,"**").
bd(cstrike, "~~").
bd(computeroutput, "\`").
bd(emphasis, "__").
bd(quot, "\`").
bd(verbatim, "\`").
bd(s, "~~").
	   bd(sp, "~~").
	       bd(ref,"\"").
bd(underline, "<ins>").

para(verbatim(_,[Link])) -->
{
string(Link),
string_concat([_A,"[",_B,"][",_C,"]",_D],Link)
},
!,
[Link].
para(ulink([url(URL)],[Title|_])) -->
    ref(Title , URL),
    !.
para(hruler([],_)) -->
    [ "\n- - -\n"].
para(preformatted([],Text)) -->
    unimpl(preformatted,Text). % docMarkupType
para(programlisting(_,Text)) -->

    [ "```\n"],
    foldl(codeline,Text),
    ["```\n"].


para(javadocliteral([],Text)) -->
    unimpl(javadocliteral,Text). % xsd:unimpling
para(javadoccode([],Text)) -->
    unimpl(javadoccode,Text). % xsd:unimpling
para(indexentry([],Text)) -->
    unimpl(indexentry,Text). % docIndexEntryType
para(orderedlist(Atts,Text)) -->
    doxolist(Atts,Text). % docListType
para(parameterlist(Atts,Text)) -->
    parlist(Atts,Text). % docParamListType
para(itemizedlist(Atts,Text)) -->
    itemlist(Atts,Text). % docListType
para(variablelist(Atts,Text)) -->
    varlist(Atts,Text). % docVariableListType
para(simplesect([kind(Kind)|Text])) -->
    !,
    ["\n\n"],
    [Kind],
    [" "],
    description(Text).
para(table(_,Text)) -->
   table(Text). % docTableType
para(heading(_,Text)) -->
    unimpl(heading,Text). % docHeadingType
para(dotfile(_,Text)) -->
    unimpl(dotfile,Text). % docImageFileType
para(mscfile(_,Text)) -->
    unimpl(mscfile,Text). % docImageFileType
para(diafile(_,Text)) -->
    unimpl(diafile,Text). % docImageFileType
para(toclist(_,Text)) -->
    unimpl(toclist,Text). % docTocListType
para(language(_,Text)) -->
    unimpl(language,Text). % docLanguageType
para(xrefsect(_,Text)) -->
    unimpl(xrefsect,Text). % docXRefSectType
para(copydoc(_,Text)) -->
    unimpl(copydoc,Text). % docCopyType
para(details(_,Text)) -->
    unimpl(details,Text). % docDetailsType
para(parblock(_,Text))-->
    para(Text). % docParBlockType         
para(superscript(_,Text)) -->
    {string(Text)},
    !,
    ["<sup>"], [Text], ["<sup>"].
para(superscript([],Text)) -->
    ["<sup>"], para(Text), [ "</sup>"].
para(center([],Text)) --> % unsupported
    para(Text). % docMarkupType
para(small([],Text)) -->
    [ "<small>"], para(Text), [ "</small>"].
para(cite([],Text)) -->
    para(Text). % docMarkupType
para(del([],Text)) -->
    [ "<del>"], para(Text), [ "</del>"].
para(ins([],Text)) -->
    [ "<ins>"], para(Text), [ "</ins>"].
para(nonbreakablespace([],_)) -->
    [      "<nonbreakablespace/>"].
para('iexcl'(_,_))  -->
    [     "<iexcl/>"].
para('cent'(_,_))  -->
    [      "<cent/>"].
para('pound'(_,_))  -->
    [     "<pound/>"].
para('curren'(_,_))  -->
    [    "<curren/>"].
para('yen'(_,_))  -->
    [       "<yen/>"].
para('brvbar'(_,_))  -->
    [    "<brvbar/>"].
para('sect'(_,_))  -->
    [      "<sect/>"].
para('uml'(_,_))  -->
    [       "<umlaut/>"].
para('copy'(_,_))  -->
    [      "<copy/>"].
para('ordf'(_,_))  -->
    [      "<ordf/>"].
para('laquo'(_,_))  -->
    [     "<laquo/>"].
para('sup3'(_,_))  -->
    [      "<sup3/>"].
para('acute'(_,_))  -->
    [     "<acute/>"].
para('micro'(_,_))  -->
    [     "<micro/>"].
para('middot'(_,_))  -->
    [    "<middot/>"].
para('cedil'(_,_))  -->
    [     "<cedil/>"].
para('sup1'(_,_))  -->
    [      "<sup1/>"].
para('ordm'(_,_))  -->
    [      "<ordm/>"].
para('raquo'(_,_))  -->
    [     "<raqUo/>"].
para('frac14'(_,_))  -->
    [    "<frac14/>"].
para('frac12'(_,_))  -->
    [    "<frac12/>"].
para('frac34'(_,_))  -->
    [    "<frac34/>"].
para('iquest'(_,_))  -->
    [    "<iquest/>"].
para('Agrave'(_,_))  -->
    [    "<Agrave/>"].
para('Aacute'(_,_))  -->
    [    "<Aacute/>"].
para('Acirc'(_,_))  -->
    [     "<Acirc/>"].
para('Atilde'(_,_))  -->
    [    "<Atilde/>"].
para('Auml'(_,_))  -->
    [      "<Aumlaut/>"].
para('Aring'(_,_))  -->
    [     "<Aring/>"].
para('AElig'(_,_))  -->
    [     "<AElig/>"].
para('Ccedil'(_,_))  -->
    [    "<Ccedil/>"].
para('Egrave'(_,_))  -->
    [    "<Egrave/>"].
para('Eacute'(_,_))  -->
    [    "<Eacute/>"].
para('Ecirc'(_,_))  -->
    [     "<Ecirc/>"].
para('Euml'(_,_))  -->
    [      "<Eumlaut/>"].
para('Igrave'(_,_))  -->
    [    "<Igrave/>"].
para('Iacute'(_,_))  -->
    [    "<Iacute/>"].
para('Icirc'(_,_))  -->
    [     "<Icirc/>"].
para('Iuml'(_,_))  -->
    [      "<Iumlaut/>"].
para('ETH'(_,_))  -->
    [       "<ETH/>"].
para('Ntilde'(_,_))  -->
    [    "<Ntilde/>"].
para('Ograve'(_,_))  -->
    [    "<Ograve/>"].
para('Oacute'(_,_))  -->
    [    "<Oacute/>"].
para('Ocirc'(_,_))  -->
    [     "<Ocirc/>"].
para('Otilde'(_,_))  -->
    [    "<Otilde/>"].
para('Ouml'(_,_))  -->
    [      "<Oumlaut/>"].
para('times'(_,_))  -->
    [     "<times/>"].
para('Oslash'(_,_))  -->
    [    "<Oslash/>"].
para('Ugrave'(_,_))  -->
    [    "<Ugrave/>"].
para('Uacute'(_,_))  -->
    [    "<Uacute/>"].
para('Ucirc'(_,_))  -->
    [     "<Ucirc/>"].
para('Uuml'(_,_))  -->
    [      "<Uumlaut/>"].
para('Yacute'(_,_))  -->
    [    "<Yacute/>"].
para('THORN'(_,_))  -->
    [     "<THORN/>"].
para('szlig'(_,_))  -->
    [     "<szlig/>"].
para('agrave'(_,_))  -->
    [    "<agrave/>"].
para('aacute'(_,_))  -->
    [    "<aacute/>"].
para('acirc'(_,_))  -->
    [     "<acirc/>"].
para('atilde'(_,_))  -->
    [    "<atilde/>"].
para('auml'(_,_))  -->
    [      "<aumlaut/>"].
para('aring'(_,_))  -->
    [     "<aring/>"].
para('aelig'(_,_))  -->
    [     "<aelig/>"].
para('ccedil'(_,_))  -->
    [    "<ccedil/>"].
para('egrave'(_,_))  -->
    [    "<egrave/>"].
para('eacute'(_,_))  -->
    [    "<eacute/>"].
para('ecirc'(_,_))  -->
    [     "<ecirc/>"].
para('euml'(_,_))  -->
    [      "<eumlaut/>"].
para('igrave'(_,_))  -->
    [    "<igrave/>"].
para('iacute'(_,_))  -->
    [    "<iacute/>"].
para('icirc'(_,_))  -->
    [     "<icirc/>"].
para('iuml'(_,_))  -->
    [      "<iumlaut/>"].
para('eth'(_,_))  -->
    [       "<eth/>"].
para('ntilde'(_,_))  -->
    [    "<ntilde/>"].
para('ograve'(_,_))  -->
    [    "<ograve/>"].
para('oacute'(_,_))  -->
    [    "<oacute/>"].
para('ocirc'(_,_))  -->
    [     "<ocirc/>"].
para('otilde'(_,_))  -->
    [    "<otilde/>"].
para('ouml'(_,_))  -->
    [      "<oumlaut/>"].
para('divide'(_,_))  -->
    [    "<divide/>"].
para('oslash'(_,_))  -->
    [    "<oslash/>"].
para('ugrave'(_,_))  -->
    [    "<ugrave/>"].
para('uacute'(_,_))  -->
    [    "<uacute/>"].
para('ucirc'(_,_))  -->
    [     "<ucirc/>"].
para('uuml'(_,_))  -->
    [      "<uumlaut/>"].
para('yacute'(_,_))  -->
    [    "<yacute/>"].
para('thorn'(_,_))  -->
    [     "<thorn/>"].
para('yuml'(_,_))  -->
    [      "<yumlaut/>"].
para('fnof'(_,_))  -->
    [      "<fnof/>"].
para('Alpha'(_,_))  -->
    [     "<Alpha/>"].
para('Beta'(_,_))  -->
    [      "<Beta/>"].
para('Gamma'(_,_))  -->
    [     "<Gamma/>"].
para('Delta'(_,_))  -->
    [     "<Delta/>"].
para('Epsilon'(_,_))  -->
    [   "<Epsilon/>"].
para('Zeta'(_,_))  -->
    [      "<Zeta/>"].
para('Eta'(_,_))  -->
    [       "<Eta/>"].
para('Theta'(_,_))  -->
    [     "<Theta/>"].
para('Iota'(_,_))  -->
    [      "<Iota/>"].
para('Kappa'(_,_))  -->
    [     "<Kappa/>"].
para('Lambda'(_,_))  -->
    [    "<Lambda/>"].
para('Mu'(_,_))  -->
    [        "<Mu/>"].
para('Nu'(_,_))  -->
    [        "<Nu/>"].
para('Xi'(_,_))  -->
    [        "<Xi/>"].
para('Omicron'(_,_))  -->
    [   "<Omicron/>"].
para('Pi'(_,_))  -->
    [        "<Pi/>"].
para('Rho'(_,_))  -->
    [       "<Rho/>"].
para('Sigma'(_,_))  -->
    [     "<Sigma/>"].
para('Tau'(_,_))  -->
    [       "<Tau/>"].
para('Upsilon'(_,_))  -->
    [   "<Upsilon/>"].
para('Phi'(_,_))  -->
    [       "<Phi/>"].
para('Chi'(_,_))  -->
    [       "<Chi/>"].
para('Psi'(_,_))  -->
    [       "<Psi/>"].
para('Omega'(_,_))  -->
    [     "<Omega/>"].
para('alpha'(_,_))  -->
    [     "<alpha/>"].
para('beta'(_,_))  -->
    [      "<beta/>"].
para('gamma'(_,_))  -->
    [     "<gamma/>"].
para('delta'(_,_))  -->
    [     "<delta/>"].
para('epsilon'(_,_))  -->
    [   "<epsilon/>"].
para('zeta'(_,_))  -->
    [      "<zeta/>"].
para('eta'(_,_))  -->
    [       "<eta/>"].
para('theta'(_,_))  -->
    [     "<theta/>"].
para('iota'(_,_))  -->
    [      "<iota/>"].
para('kappa'(_,_))  -->
    [     "<kappa/>"].
para('lambda'(_,_))  -->
    [    "<lambda/>"].
para('mu'(_,_))  -->
    [        "<mu/>"].
para('nu'(_,_))  -->
    [        "<nu/>"].
para('xi'(_,_))  -->
    [        "<xi/>"].
para('omicron'(_,_))  -->
    [   "<omicron/>"].
para('pi'(_,_))  -->
    [        "<pi/>"].
para('rho'(_,_))  -->
    [       "<rho/>"].
para('sigmaf'(_,_))  -->
    [    "<sigmaf/>"].
para('sigma'(_,_))  -->
    [     "<sigma/>"].
para('tau'(_,_))  -->
    [       "<tau/>"].
para('upsilon'(_,_))  -->
    [   "<upsilon/>"].
para('phi'(_,_))  -->
    [       "<phi/>"].
para('chi'(_,_))  -->
    [       "<chi/>"].
para('psi'(_,_))  -->
    [       "<psi/>"].
para('omega'(_,_))  -->
    [     "<omega/>"].
para('thetasym'(_,_))  -->
    [  "<thetasym/>"].
para('upsih'(_,_))  -->
    [     "<upsih/>"].
para('piv'(_,_))  -->
    [       "<piv/>"].
para('bull'(_,_))  -->
    [      "<bull/>"].
para('hellip'(_,_))  -->
    [    "<hellip/>"].
para('prime'(_,_))  -->
    [     "<prime/>"].
para('Prime'(_,_))  -->
    [     "<Prime/>"].
para('oline'(_,_))  -->
    [     "<oline/>"].
para('frasl'(_,_))  -->
    [     "<frasl/>"].
para('weierp'(_,_))  -->
    [    "<weierp/>"].
para('image'(_,_))  -->
    [     "<imaginary/>"].
para('real'(_,_))  -->
    [      "<real/>"].
para('trade'(_,_))  -->
    [     "<trademark/>"].
para('alefsym'(_,_))  -->
    [   "<alefsym/>"].
para('larr'(_,_))  -->
    [      "<larr/>"].
para('uarr'(_,_))  -->
    [      "<uarr/>"].
para('rarr'(_,_))  -->
    [      "<rarr/>"].
para('darr'(_,_))  -->
    [      "<darr/>"].
para('harr'(_,_))  -->
    [      "<harr/>"].
para('crarr'(_,_))  -->
    [     "<crarr/>"].
para('lArr'(_,_))  -->
    [      "<lArr/>"].
para('uArr'(_,_))  -->
    [      "<uArr/>"].
para('rArr'(_,_))  -->
    [      "<rArr/>"].
para('dArr'(_,_))  -->
    [      "<dArr/>"].
para('hArr'(_,_))  -->
    [      "<hArr/>"].
para('forall'(_,_))  -->
    [    "<forall/>"].
para('part'(_,_))  -->
    [      "<part/>"].
para('exist'(_,_))  -->
    [     "<exist/>"].
para('empty'(_,_))  -->
    [     "<empty/>"].
para('nabla'(_,_))  -->
    [     "<nabla/>"].
para('isin'(_,_))  -->
    [      "<isin/>"].
para('notin'(_,_))  -->
    [     "<notin/>"].
para('ni'(_,_))  -->
    [        "<ni/>"].
para('prod'(_,_))  -->
    [      "<prod/>"].
para('sum'(_,_))  -->
    [       "<sum/>"].
para('minus'(_,_))  -->
    [     "<minus/>"].
para('lowast'(_,_))  -->
    [    "<lowast/>"].
para('radic'(_,_))  -->
    [     "<radic/>"].
para('prop'(_,_))  -->
    [      "<prop/>"].
para('infin'(_,_))  -->
    [     "<infin/>"].
para('ang'(_,_))  -->
    [       "<ang/>"].
para('and'(_,_))  -->
    [       "<and/>"].
para('or'(_,_))  -->
    [        "<or/>"].
para('cap'(_,_))  -->
    [       "<cap/>"].
para('cup'(_,_))  -->
    [       "<cup/>"].
para('int'(_,_))  -->
    [       "<int/>"].
para('there4'(_,_))  -->
    [    "<there4/>"].
para('sim'(_,_))  -->
    [       "<sim/>"].
para('cong'(_,_))  -->
    [      "<cong/>"].
para('asymp'(_,_))  -->
    [     "<asymp/>"].
para('ne'(_,_))  -->
    [        "<ne/>"].
para('equiv'(_,_))  -->
    [     "<equiv/>"].
para('le'(_,_))  -->
    [        "<le/>"].
para('ge'(_,_))  -->
    [        "<ge/>"].
para('sub'(_,_))  -->
    [       "<sub/>"].
para('sup'(_,_))  -->
    [       "<sup/>"].
para('nsub'(_,_))  -->
    [      "<nsub/>"].
para('sube'(_,_))  --> 
    [      "<sube/>"].
para('supe'(_,_))  -->
    [      "<supe/>"].
para('oplus'(_,_))  -->
    [     "<oplus/>"].
para('otimes'(_,_))  -->
    [    "<otimes/>"].
para('perp'(_,_))  -->
    [      "<perp/>"].
para('sdot'(_,_))  -->
    [      "<sdot/>"].
para('lceil'(_,_))  -->
    [     "<lceil/>"].
para('rceil'(_,_))  -->
    [     "<rceil/>"].
para('lfloor'(_,_))  -->
    [    "<lfloor/>"].
para('rfloor'(_,_))  -->
    [    "<rfloor/>"].
para('lang'(_,_))  -->
    [      "<lang/>"].
para('rang'(_,_))  -->
    [      "<rang/>"].
para('loz'(_,_))  -->
    [       "<loz/>"].
para('spades'(_,_))  -->
    [    "<spades/>"].
para('clubs'(_,_))  -->
    [     "<clubs/>"].
para('hearts'(_,_))  -->
    [    "<hearts/>"].
para('diams'(_,_))  -->
    [     "<diams/>"].
para('quot'(_,_))  -->
    [ "&quot;"].
para('amp'(_,_))  -->
    [       "&amp;"].
para('lt'(_,_))  -->
    [        "&lt;"].
para('gt'(_,_))  -->
    [        "&gt;"].
para('OElig'(_,_))  -->
    [     "<OElig/>"].
para('oelig'(_,_))  -->
    [     "<oelig/>"].
para('Scaron'(_,_))  -->
    [    "<Scaron/>"].
para('scaron'(_,_))  -->
    [    "<scaron/>"].
para('Yuml'(_,_))  -->
    [      "<Yumlaut/>"].
para('circ'(_,_))  -->
    [      "<circ/>"].
para('tilde'(_,_))  -->
    [     "<tilde/>"].
para(ensp(_,_)) -->
    [ "<ensp/>"].
para('emsp'(_,_))  -->
    [ "<emsp/>"].
para('thinsp'(_,_))  -->
    [   "<thinsp/>"].
para('zwnj'(_,_))  -->
    [  "<zwnj/>"].
para('zwj'(_,_)) -->
    [ "<zwj/>"].
para('lrm'(_,_)) -->
    [ "<lrm/>"].
para('rlm'(_,_)) -->
    [ "<rlm/>"].
para('ndash'(_,_)) -->
    [ "<ndash/>"].
para('mdash'(_,_)) -->
    [ "<mdash/>"].
para('lsquo'(_,_)) -->
    [ "<lsquo/>"].
para('rsquo'(_,_)) -->
    [ "<rsquo/>"].
para('sbquo'(_,_)) -->
    [ "<sbquo/>"].
para('ldquo'(_,_)) -->
    [ "<ldquo/>"].
para('rdquo'(_,_)) -->
    [ "<rdquo/>"].
para('bdquo'(_,_)) -->
    [ "<bdquo/>"].
para('dagger'(_,_)) -->
    [ "<dagger/>"].
para('Dagger'(_,_)) -->
    [ "<Dagger/>"].
para('permil'(_,_)) -->
    [ "<permil/>"].
para('lsaquo'(_,_)) -->
    [ "<lsaquo/>"].
para('rsaquo'(_,_)) -->
    [ "<rsaquo/>"].
para('euro'(_,_)) -->
    [ "<euro/>"].
%  // doxygen extension to the HTML4 table of HTML entities
para('tm'(_,_))  -->
    [    "<tm/>"].
para('apos'(_,_))  -->
    [ "&apos;"].

%  // doxygen commands represented as HTML entities
para('BSlash'(_,_)) -->
    [ "\\"].
para('BSlash'(_,_)) -->
    [ "@"].
para('Less'(_,_)) -->
    [ "&lt;"].
para('Greater'(_,_)) -->
    [ "&lt;"].
%<!-- end workaround for xsd.exe -->
para(center([],Text)) --> % unsupported
    para(Text). % docMarkupType
para(small([],Text)) -->
    [ "<small>"], para(Text), [ "</small>"].
para(cite([],Text)) -->
    para(Text). % docMarkupType
para(del([],Text)) -->
    [ "<del>"], para(Text), [ "</del>"].
para(ins([],Text)) -->
    [ "<ins>"], para(Text), [ "</ins>"].
para(htmlonly([],_Text)) -->
    []. % docHtmlOnlyType
para(manonly([],_Text)) -->
    [].
para(xmlonly([],Text)) -->
    para(Text).
para(rtfonly([],_Text)) -->
    []. % xsd:cstring
para(latexonly([],_Text)) -->
    []. % xsd:cstring
para(docbookonly([],_Text)) -->
    []. % xsd:cstring
para(image([],_Text)) -->
    para(_Text). % docImageType
para(dot([],_Text)) -->
    []. % docDotMscType
para(msc([],_Text)) -->
    []. % docDotMscType
para(plantuml([],_Text)) -->
    []. % docPlantumlType
para(anchor(Parms,Children))-->
anchor(Parms,Children).

para([]) --> !.
para(ref(Atts,[Name])) -->
    {
        key_in(refid(Ref),Atts)
    },
    !,
    ref(Ref,Name).
para(linebreak([],_)) -->
    ["<br>"]. % docEmptyType
para('not'(_,_))  -->
    [       "<not/>"].
para('shy'(_,_))  -->
    [       "<shy/>"].
para('reg'(_,_))  -->
    [       "<registered/>"].
para('macr'(_,_))  -->
    [      "<macr/>"].
para('deg'(_,_))  -->
    [       "<deg/>"].
para('plusmn'(_,_))  -->
    [    "<plusmn/>"].
para('sup2'(_,_))  -->
    [     "<sup2/>"].
para('raquo'(_,_))  -->
    [     "<raquo/>"].
para('frac14'(_,_))  -->
    [    "<frac14/>"].
para('frac12'(_,_))  -->
    [    "<frac12/>"].
para('frac34'(_,_))  -->
    [    "<frac34/>"].
para('iquest'(_,_))  -->
    [    "<iquest/>"].
para('Agrave'(_,_))  -->
    [    "<Agrave/>"].
para('Aacute'(_,_))  -->
    [    "<Aacute/>"].
para('Acirc'(_,_))  -->
    [     "<Acirc/>"].
para('Atilde'(_,_))  -->
    [    "<Atilde/>"].
para('Auml'(_,_))  -->
    [      "<Aumlaut/>"].
para('Aring'(_,_))  -->
    [     "<Aring/>"].
para('AElig'(_,_))  -->
    [     "<AElig/>"].
para('Ccedil'(_,_))  -->
    [    "<Ccedil/>"].
para('Egrave'(_,_))  -->
    [    "<Egrave/>"].
para('Eacute'(_,_))  -->
    [    "<Eacute/>"].
para('Ecirc'(_,_))  -->
    [     "<Ecirc/>"].
para('Euml'(_,_))  -->
    [      "<Eumlaut/>"].
para('Igrave'(_,_))  -->
    [    "<Igrave/>"].
para('Iacute'(_,_))  -->
    [    "<Iacute/>"].
para('Icirc'(_,_))  -->
    [     "<Icirc/>"].
para('Iuml'(_,_))  -->
    [      "<Iumlaut/>"].
para('ETH'(_,_))  -->
    [       "<ETH/>"].
para('Ntilde'(_,_))  -->
    [    "<Ntilde/>"].
para('Ograve'(_,_))  -->
    [    "<Ograve/>"].
para('Oacute'(_,_))  -->
    [    "<Oacute/>"].
para('Ocirc'(_,_))  -->
    [     "<Ocirc/>"].
para('Otilde'(_,_))  -->
    [    "<Otilde/>"].
para('Ouml'(_,_))  -->
    [      "<Oumlaut/>"].
para('times'(_,_))  -->
    [     "<times/>"].
para('Oslash'(_,_))  -->
    [    "<Oslash/>"].
para('Ugrave'(_,_))  -->
    [    "<Ugrave/>"].
para('Uacute'(_,_))  -->
    [    "<Uacute/>"].
para('Ucirc'(_,_))  -->
    [     "<Ucirc/>"].
para('Uuml'(_,_))  -->
    [      "<Uumlaut/>"].
para('Yacute'(_,_))  -->
    [    "<Yacute/>"].
para('THORN'(_,_))  -->
    [     "<THORN/>"].
para('szlig'(_,_))  -->
    [     "<szlig/>"].
para('agrave'(_,_))  -->
    [    "<agrave/>"].
para('aacute'(_,_))  -->
    [    "<aacute/>"].
para('acirc'(_,_))  -->
    [     "<acirc/>"].
para('atilde'(_,_))  -->
    [    "<atilde/>"].
para('auml'(_,_))  -->
    [      "<aumlaut/>"].
para('aring'(_,_))  -->
    [     "<aring/>"].
para('aelig'(_,_))  -->
    [     "<aelig/>"].
para('ccedil'(_,_))  -->
    [    "<ccedil/>"].
para('egrave'(_,_))  -->
    [    "<egrave/>"].
para('eacute'(_,_))  -->
    [    "<eacute/>"].
para('ecirc'(_,_))  -->
    [     "<ecirc/>"].
para('euml'(_,_))  -->
    [      "<eumlaut/>"].
para('igrave'(_,_))  -->
    [    "<igrave/>"].
para('iacute'(_,_))  -->
    [    "<iacute/>"].
para('icirc'(_,_))  -->
    [     "<icirc/>"].
para('iuml'(_,_))  -->
    [      "<iumlaut/>"].
para('eth'(_,_))  -->
    [       "<eth/>"].
para('ntilde'(_,_))  -->
    [    "<ntilde/>"].
para('ograve'(_,_))  -->
    [    "<ograve/>"].
para('oacute'(_,_))  -->
    [    "<oacute/>"].
para('ocirc'(_,_))  -->
    [     "<ocirc/>"].
para('otilde'(_,_))  -->
    [    "<otilde/>"].
para('ouml'(_,_))  -->
    [      "<oumlaut/>"].
para('divide'(_,_))  -->
    [    "<divide/>"].
para('oslash'(_,_))  -->
    [    "<oslash/>"].
para('ugrave'(_,_))  -->
    [    "<ugrave/>"].
para('uacute'(_,_))  -->
    [    "<uacute/>"].
para('ucirc'(_,_))  -->
    [     "<ucirc/>"].
para('uuml'(_,_))  -->
    [      "<uumlaut/>"].
para('yacute'(_,_))  -->
    [    "<yacute/>"].
para('thorn'(_,_))  -->
    [     "<thorn/>"].
para('yuml'(_,_))  -->
    [      "<yumlaut/>"].
para('fnof'(_,_))  -->
    [      "<fnof/>"].
para('Alpha'(_,_))  -->
    [     "<Alpha/>"].
para('Beta'(_,_))  -->
    [      "<Beta/>"].
para('Gamma'(_,_))  -->
    [     "<Gamma/>"].
para('Delta'(_,_))  -->
    [     "<Delta/>"].
para('Epsilon'(_,_))  -->
    [   "<Epsilon/>"].
para('Zeta'(_,_))  -->
    [      "<Zeta/>"].
para('Eta'(_,_))  -->
    [       "<Eta/>"].
para('Theta'(_,_))  -->
    [     "<Theta/>"].
para('Iota'(_,_))  -->
    [      "<Iota/>"].
para('Kappa'(_,_))  -->
    [     "<Kappa/>"].
para('Lambda'(_,_))  -->
    [    "<Lambda/>"].
para('Mu'(_,_))  -->
    [        "<Mu/>"].
para('Nu'(_,_))  -->
    [        "<Nu/>"].
para('Xi'(_,_))  -->
    [        "<Xi/>"].
para('Omicron'(_,_))  -->
    [   "<Omicron/>"].
para('Pi'(_,_))  -->
    [        "<Pi/>"].
para('Rho'(_,_))  -->
    [       "<Rho/>"].
para('Sigma'(_,_))  -->
    [     "<Sigma/>"].
para('Tau'(_,_))  -->
    [       "<Tau/>"].
para('Upsilon'(_,_))  -->
    [   "<Upsilon/>"].
para('Phi'(_,_))  -->
    [       "<Phi/>"].
para('Chi'(_,_))  -->
    [       "<Chi/>"].
para('Psi'(_,_))  -->
    [       "<Psi/>"].
para('Omega'(_,_))  -->
    [     "<Omega/>"].
para('alpha'(_,_))  -->
    [     "<alpha/>"].
para('beta'(_,_))  -->
    [      "<beta/>"].
para('gamma'(_,_))  -->
    [     "<gamma/>"].
para('delta'(_,_))  -->
    [     "<delta/>"].
para('epsilon'(_,_))  -->
    [   "<epsilon/>"].
para('zeta'(_,_))  -->
    [      "<zeta/>"].
para('eta'(_,_))  -->
    [       "<eta/>"].
para('theta'(_,_))  -->
    [     "<theta/>"].
para('iota'(_,_))  -->
    [      "<iota/>"].
para('kappa'(_,_))  -->
    [     "<kappa/>"].
para('lambda'(_,_))  -->
    [    "<lambda/>"].
para('mu'(_,_))  -->
    [        "<mu/>"].
para('nu'(_,_))  -->
    [        "<nu/>"].
para('xi'(_,_))  -->
    [        "<xi/>"].
para('omicron'(_,_))  -->
    [   "<omicron/>"].
para('pi'(_,_))  -->
    [        "<pi/>"].
para('rho'(_,_))  -->
    [       "<rho/>"].
para('sigmaf'(_,_))  -->
    [    "<sigmaf/>"].
para('sigma'(_,_))  -->
    [     "<sigma/>"].
para('tau'(_,_))  -->
    [       "<tau/>"].
para('upsilon'(_,_))  -->
    [   "<upsilon/>"].
para('phi'(_,_))  -->
    [       "<phi/>"].
para('chi'(_,_))  -->
    [       "<chi/>"].
para('psi'(_,_))  -->
    [       "<psi/>"].
para('omega'(_,_))  -->
    [     "<omega/>"].
para('thetasym'(_,_))  -->
    [  "<thetasym/>"].
para('upsih'(_,_))  -->
    [     "<upsih/>"].
para('piv'(_,_))  -->
    [       "<piv/>"].
para('bull'(_,_))  -->
    [      "<bull/>"].
para('hellip'(_,_))  -->
    [    "<hellip/>"].
para('prime'(_,_))  -->
    [     "<prime/>"].
para('Prime'(_,_))  -->
    [     "<Prime/>"].
para('oline'(_,_))  -->
    [     "<oline/>"].
para('frasl'(_,_))  -->
    [     "<frasl/>"].
para('weierp'(_,_))  -->
    [    "<weierp/>"].
para('image'(_,_))  -->
    [     "<imaginary/>"].
para('real'(_,_))  -->
    [      "<real/>"].
para('trade'(_,_))  -->
    [     "<trademark/>"].
para('alefsym'(_,_))  -->
    [   "<alefsym/>"].
para('larr'(_,_))  -->
    [      "<larr/>"].
para('uarr'(_,_))  -->
    [      "<uarr/>"].
para('rarr'(_,_))  -->
    [      "<rarr/>"].
para('darr'(_,_))  -->
    [      "<darr/>"].
para('harr'(_,_))  -->
    [      "<harr/>"].
para('crarr'(_,_))  -->
    [     "<crarr/>"].
para('lArr'(_,_))  -->
    [      "<lArr/>"].
para('uArr'(_,_))  -->
    [      "<uArr/>"].
para('rArr'(_,_))  -->
    [      "<rArr/>"].
para('dArr'(_,_))  -->
    [      "<dArr/>"].
para('hArr'(_,_))  -->
    [      "<hArr/>"].
para('forall'(_,_))  -->
    [    "<forall/>"].
para('part'(_,_))  -->
    [      "<part/>"].
para('exist'(_,_))  -->
    [     "<exist/>"].
para('empty'(_,_))  -->
    [     "<empty/>"].
para('nabla'(_,_))  -->
    [     "<nabla/>"].
para('isin'(_,_))  -->
    [      "<isin/>"].
para('notin'(_,_))  -->
    [     "<notin/>"].
para('ni'(_,_))  -->
    [        "<ni/>"].
para('prod'(_,_))  -->
    [      "<prod/>"].
para('sum'(_,_))  -->
    [       "<sum/>"].
para('minus'(_,_))  -->
    [     "<minus/>"].
para('lowast'(_,_))  -->
    [    "<lowast/>"].
para('radic'(_,_))  -->
    [     "<radic/>"].
para('prop'(_,_))  -->
    [      "<prop/>"].
para('infin'(_,_))  -->
    [     "<infin/>"].
para('ang'(_,_))  -->
    [       "<ang/>"].
para('and'(_,_))  -->
    [       "<and/>"].
para('or'(_,_))  -->
    [        "<or/>"].
para('cap'(_,_))  -->
    [       "<cap/>"].
para('cup'(_,_))  -->
    [       "<cup/>"].
para('int'(_,_))  -->
    [       "<int/>"].
para('there4'(_,_))  -->
    [    "<there4/>"].
para('sim'(_,_))  -->
    [       "<sim/>"].
para('cong'(_,_))  -->
    [      "<cong/>"].
para('asymp'(_,_))  -->
    [     "<asymp/>"].
para('ne'(_,_))  -->
    [        "<ne/>"].
para('equiv'(_,_))  -->
    [     "<equiv/>"].
para('le'(_,_))  -->
    [        "<le/>"].
para('ge'(_,_))  -->
    [        "<ge/>"].
para('sub'(_,_))  -->
    [       "<sub/>"].
para('sup'(_,_))  -->
    [       "<sup/>"].
para('nsub'(_,_))  -->
    [      "<nsub/>"].
para('sube'(_,_))  --> 
    [      "<sube/>"].
para('supe'(_,_))  -->
    [      "<supe/>"].
para('oplus'(_,_))  -->
    [     "<oplus/>"].
para('otimes'(_,_))  -->
    [    "<otimes/>"].
para('perp'(_,_))  -->
    [      "<perp/>"].
para('sdot'(_,_))  -->
    [      "<sdot/>"].
para('lceil'(_,_))  -->
    [     "<lceil/>"].
para('rceil'(_,_))  -->
    [     "<rceil/>"].
para('lfloor'(_,_))  -->
    [    "<lfloor/>"].
para('rfloor'(_,_))  -->
    [    "<rfloor/>"].
para('lang'(_,_))  -->
    [      "<lang/>"].
para('rang'(_,_))  -->
    [      "<rang/>"].
para('loz'(_,_))  -->
    [       "<loz/>"].
para('spades'(_,_))  -->
    [    "<spades/>"].
para('clubs'(_,_))  -->
    [     "<clubs/>"].
para('hearts'(_,_))  -->
    [    "<hearts/>"].
para('diams'(_,_))  -->
    [     "<diams/>"].
para('amp'(_,_))  -->
    [       "&amp;"].
para('lt'(_,_))  -->
    [        "&lt;"].
para('gt'(_,_))  -->
    [        "&gt;"].
para('OElig'(_,_))  -->
    [     "<OElig/>"].
para('oelig'(_,_))  -->
    [     "<oelig/>"].
para('Scaron'(_,_))  -->
    [    "<Scaron/>"].
para('scaron'(_,_))  -->
    [    "<scaron/>"].
para('Yuml'(_,_))  -->
    [      "<Yumlaut/>"].
para('circ'(_,_))  -->
    [      "<circ/>"].
para('tilde'(_,_))  -->
    [     "<tilde/>"].
para(ensp(_,_)) -->
    [ "<ensp/>"].
para('emsp'(_,_))  -->
    [ "<emsp/>"].
para('thinsp'(_,_))  -->
    [   "<thinsp/>"].
para('zwnj'(_,_))  -->
    [  "<zwnj/>"].
para('zwj'(_,_)) -->
    [ "<zwj/>"].
para('lrm'(_,_)) -->
    [ "<lrm/>"].
para('rlm'(_,_)) -->
    [ "<rlm/>"].
para('ndash'(_,_)) -->
    [ "<ndash/>"].
para('mdash'(_,_)) -->
    [ "<mdash/>"].
para('lsquo'(_,_)) -->
    [ "<lsquo/>"].
para('rsquo'(_,_)) -->
    [ "<rsquo/>"].
para('sbquo'(_,_)) -->
    [ "<sbquo/>"].
para('ldquo'(_,_)) -->
    [ "<ldquo/>"].
para('rdquo'(_,_)) -->
    [ "<rdquo/>"].
para('bdquo'(_,_)) -->
    [ "<bdquo/>"].
para('dagger'(_,_)) -->
    [ "<dagger/>"].
para('Dagger'(_,_)) -->
    [ "<Dagger/>"].
para('permil'(_,_)) -->
    [ "<permil/>"].
para('lsaquo'(_,_)) -->
    [ "<lsaquo/>"].
para('rsaquo'(_,_)) -->
    [ "<rsaquo/>"].
para('euro'(_,_)) -->
    [ "<euro/>"].

%  // doxygen extension to the HTML4 table of HTML entities
para('tm'(_,_))  -->
    [    "<tm/>"].
para('apos'(_,_))  -->
    [ "&apos;"].

%  // doxygen commands represented as HTML entities
para('BSlash'(_,_)) -->
    [ "\\"].
para('BSlash'(_,_)) -->
    [ "@"].
para('Less'(_,_)) -->
    [ "&lt;"].
para('Greater'(_,_)) -->
    [ "&lt;"].
para(P) -->
    {
	P=..[N,_,A],
(	bd(N,H)->true;H="")
    },
    [H],
    (
	{string(A)}
    ->
    [A]
    ;
    description(A)
    ),
!,
    [H].
para(P) -->
{writeln(para(P))}.
%<!-- end workaround for xsd.exe -->
unimpl(Cmd,Arg) -->
    { format(user_error,'unimplemented: ~w (called with ~w)',[Cmd,Arg]) }.



split_domains([],[],[],[]).
split_domains([briefdescription-A|All],[A|Bs],Ds,Ts):-
    !,
    split_domains(All,Bs,Ds,Ts).
split_domains([detaileddescription-A|All],Bs,[A|Ds],Ts):-
    !,
    split_domains(All,Bs,Ds,Ts).
split_domains([_-A|All],Bs,Ds,[A|Ts]):-
    !,
    split_domains(All,Bs,Ds,Ts).


short_ref(Ref,Short) :-
    inner(Ref,Short),
    !.
short_ref(Ref,Ref).

/*
%% ref(+Link,+Name)0
% -translate a ref to mkdocs
%
ref(S,W) -->
    {      writeln(S:W),
	   sub_string(S,0,_,_,"class"),
    atom_to_string(A,S),
    g(A,Group) },
    !,
    {
      decode_dox(W,L0),
      decode(L0,L),
      format(string(Str),'[~s](~s#~s})' ,[L,Group,A]) ,
    writeln(0:Str)},
    [Str].
  */  
ref(S,W) -->
%     {writeln(S:W)},
    {
	   sub_string(W,0,_,_,"class")
    },
    !,
    {
%      format(string(Str),'[~s]({{~s}})' ,[L,S]),
      format(string(Str),' [~s][#~s]' ,[S,W])
    },
    [Str].
ref(S,W)-->
    { format(string(Str),'[~s](~s.md)' ,[W,S]) },
    [Str].

%% ref(+Link,+Name)
% create a new target
%

key_in(X,[X|_]) :- !.
key_in(X,[_|L]) :-
    key_in(X,L).

to_predicate(P,S) :-
check_prid(P,S).

strip_module_from_pred(ROS,EOS,Final):-
    sub_string(ROS,Left,3,Right,"::P"),
    !,
    sub_string(ROS,0,Left,_,Mod),
    sub_string(ROS,_,Right,0,Name),
    string_concat([Mod,":",Name,"/",EOS],Final).
strip_module_from_pred(ROS,EOS,Final) :-
    sub_string(ROS,0,1,Left,"P"),
    !,
    sub_string(ROS,1,Left,0,Name),
    string_concat([Name,"/",EOS],Final).
strip_module_from_pred(ROS,EOS,Final) :-
    sub_string(ROS,Left,_,Right,"::"),
    sub_string(ROS,0,Left,_,NMod),
    sub_string(ROS,_,Right,0,NPred),
    strip_module_from_pred(NPred,EOS,SemiFinal),
    !,
    string_concat([NMod,":",SemiFinal],Final).


get_safe_name(S,N) :-
get_name(S,N0),
   decode(N0,N).
get_name([Name],Name) :-
string(Name),
!.
get_name(Children,Name) :-
    key_in(qualifiedname(_,NameS ),Children),
    (
	NameS = [_,[Name]]
    ;
    NameS = [Name]
    ;
    NameS = Name
    ),
    string(Name),
    !.
get_name(Children,PName) :-
    key_in(compoundname(_,NameS ),Children),
    (
	NameS = [_,[Name]]
    ;
    NameS = [Name]
    ;
    NameS = Name
    ),
    string(Name),
decode(Name,PName),
    !.
get_name(Children,Name) :-
    key_in(name(_,NameS ),Children),
    (
	NameS = [_,[Name]]
    ;
    NameS = [Name]
    ;
    NameS = Name
    ),
    string(Name),
    !.


anchor([id(Ref)],[]) -->
  ["[](){#",Ref,"}\n"].

gengroup(Ref0) :-
    string_concat("/group__",Ref0,Ref),
    Kind="group",
    unix(argv([IDir,ODir,_])),
    trl(compound([refid(Ref),kind(Kind)],[]),IDir,ODir).

genclass(Ref0) :-
    Kind="class",
    unix(argv([IDir,ODir,_])),
    trl(compound([refid(Ref0),kind(Kind)],[]),IDir,ODir).

 % 
table([Row|Rows]) -->
    ["\n\n"],
    row(Row),
    centering(Row),
    foldl(row,Rows),
    ["\n\n"].

row(row(_,Entries)) -->
    foldl(entry,Entries),
    ["  |\n"].

entry(entry([thead(_),align(_)],Info)) -->
    ["|     "],
   foldl(para,Info).

centering(row([],Entries)) -->
foldl(align,Entries),
["|\n"].

align(entry([thead("yes"),align("center")],_In:fo)) -->
!,
    ["|:                 :"].
align(entry([thead("yes"),align("right")],_Info)) -->
!,
    ["|                 :"].
align(entry([thead("yes"),align("left")],_Info)) -->
!,
    ["|:                 "].

group_edge(IDir,F) :-
    atom_concat(group,_,F),
    ge(IDir,F),
    !.
group_edge(_,_).

ge(IDir,F) :-
    atom_concat(F0,'.xml',F),
    path_concat([IDir,F], XFile),
    catch(load_xml(XFile,XML),Error,(format(user_error,'failed while processsing ~w: ~w',[XFile,Error]))),  
    XML = [doxygen(_,[compounddef(_,XMLData)|_XData])],
    (member(title([],[Title]),XMLData) ->
         assert(title(F0,Title))
     ;
     member(compoundname([],[Title]),XMLData)

    retractall(visited(_)),
    retractall(pred_found(_,_,_)),
    unix(argv([File])),
    W = user_output,
    absolute_file_name(File, Y, [access(read),file_type(prolog),file_errors(fail),solutions(first)]),
    \+ visited(File),
    %    valid_suffix(ValidSuffix),
    %    sub_atom(Y,_,_,0,ValidSuffix),
    open(Y,read,S,[alias(loop_stream)]),
    script(S),
    trl(S,W),
     insert_module_tail(W),
     flush_output,
     close(S).
 %    fail.
 

 /*
 atom_concat('cat ',File,Command),
 unix(system(Command)).


     read_stream_to_string(S,Text),
     format(ostream,'~s',[Text]).
 */

 %%
 %% @pred script(+S)
 %%
 script(S) :-
     peek_char(S,'#'),
     !,
      readutil:read_line_to_string(S,_),
     script(S).
 script(_).

comments( W, Comments ) :-
    forall(
member(Comment, Comments),
    out_comment(W,Comment, false, _ )
).
    
/**
  * @pred entry(+Stream, -Units).
  * Obtain text units
  */
 trl(S,W) :-
     repeat,
     read_clause(S,T,[comments(Comments),variable_names(Vs)]),
     comments( W, Comments ) ,
     (	T == end_of_file
       ->
            !,
  O = directive(end_of_file, Comments, Vs)
       ;
        T = ( :- Directive )
       ->
       (
	 dxpand(Directive)
	 ;
	 O = directive(Directive, Comments, Vs)
       ),
	 fail
       ;

       T = (( Grammar --> _Expansion ))
       ->
       functor(Grammar,Name,Arity),      
       A is Arity+2,
       predicate_definition(Name/A,W),
       fail
       ;
       T = (( Head :- _Body ))
       ->
       functor(Head,Name,Arity),
       predicate_definition(Name/Arity, W),
       fail
       ;
       functor(T,Name,Arity),
       predicate_definition(Name/Arity, W),
       fail
     ).

 %% initial directive
  % predicates([H|_],_,_,_) :-
  %     writeln(H),
  %     fail.


predicate_definition(N/A,_W) :-
%    defined(N/A),
    !.
predicate_definition(N/A,W) :-
    assert(defined(N/A)),
    encode(N/A,S1),
    atom_string(NA,S1),
    findall(I,between(1,A,I),Is),
    maplist(number_atom,Is,AIs),
    maplist(atom_concat('int ARG'),AIs,NIs),
    (
      is_exported(N,0)
      ->
      format(W,' class  ~s {        ~w();~n};~n~n~n',[ S1,NA])
      ;
      is_exported(NA,_)
->
      T =.. [NA|NIs],
      format(W,' class  ~s {        ~w();~n};~n~n~n',[ S1,T])
;
true
    ).

:- dynamic new_mod/0.

insert_module_header(W) :-
    current_source_module(M,M),
    %    format(ostream,'class Predicate(M),
    !,
    format(W,'namespace ~s~n{~n',[M]),
    assert(new_mod).
insert_module_header(_).

insert_module_tail(W) :-
    new_mod,
    defines_module(_M),
    !,
    format(W,'}~n',[]).
insert_module_tail(_).

out_comment(W,C, InitialVerbatim, FinalVerbatim) :-
    sub_string(C,0,3,_,"```"),
    !,
    (InitialVerbatim == true ->  FinalVerbatim = false ; FinalVerbatim = true),
    format(W,'~s~n',[C]).
out_comment(W,C, true, true) :-
    !,
    format(W,'~s~n',[C]).
out_comment(W,C, false, false) :-
    simplify(C,Simplified),
    !,
    format(W,'~s~n',[Simplified]).

simplify(C,Simplified) :-
    sub_string(C,0,4,_,"/**<"),
    sub_string(C,4,1,_,Space),
    sp(Space),
    sub_string(C,5,_,0,NC),
    !,
    string_list_concat(ListSlashStar, "\n", NC),
    maplist(simplify_slash, ListSlashStar,  S),
    string_list_concat([ "\n",S, "\n\n"], Simplified).
simplify(C, Simplified) :-
    sub_string(C,0,3,_,"/**"),
    sub_string(C,3,1,_,Space),
    sp(Space),
    sub_string(C,4,_,0,NC),
    !,
    string_list_concat(ListSlashStar, "\n", NC),
    maplist(simplify_slash, ListSlashStar,  S),
    string_list_concat(S,"\n", Simplified0),
    string_concat(["\n", Simplified0,"\n\n"], Simplified).


simplify(C,C) :-
    sub_string(C,0,2,_,"/*"),
    !.
simplify(C,Simplified) :-
    sub_string(C,0,3,_,"%%<"),
    sub_string(C,3,1,_,Space),
    sp(Space),
    !,
    sub_string(C,4,_,0,Slash),
    string_list_concat(ListSlash, "\n", Slash),
    maplist(simplify_slash, ListSlash,  [H0|S]),
    %    string_concat("///< ", H0, H),
    H = H0,
    string_list_concat([H|S], "\n", Simplified).
simplify(C,Simplified) :-
    sub_string(C,0,2,_,"%%"),
    sub_string(C,2,1,_,Space),
    sp(Space),
     !,
     sub_string(C,3,_,0,Slash),
    string_list_concat(ListSlash, "\n", Slash),
    maplist(simplify_slash, ListSlash,  S),
    %    append(["/** "|S],["*/\n"],HS),
    S = HS,
    string_list_concat(HS, "\n", Simplified).
simplify(C, "\n") :-
    sub_string(C,0,1,_,"%"),
    !.
simplify(C,C).

simplify_slash(S, NS) :-
    sub_string(S, 0 ,_,_, "%%"),
    sub_string(S,2,1,_,Space),
    sp(Space),
    !,
    sub_string(S, 3,_,0, IS),
    simplify_slash_star(IS,NS).
simplify_slash(S, NS) :-
    sub_string(S, 0 ,_,_, " *"),
    sub_string(S,2,1,_,Space),
    sp(Space),
    !,
    sub_string(S, 3,_,0, IS),
    simplify_slash_star(IS,NS).
simplify_slash(S, NS) :-
    sub_string(S, 0 ,_,_, "%!"),
    sub_string(S,2,1,_,Space),
    sp(Space),
    !,
    sub_string(S, 3 ,_,0, IS),
    simplify_slash_star(IS,NS).
simplify_slash(S,NS) :-
    sub_string(S, 0 ,_,_, "%%<"),
    sub_string(S,3,1,_,Space),
    sp(Space),
    !,
    sub_string(S, 4,_,0, IS),
    simplify_slash_star(IS,NS).
simplify_slash(S, NS) :-
    sub_string(S, 0 ,_,_, "%"),
    sub_string(S,1,1,_,Space),
    sp(Space),
    !,
    sub_string(S, 2 ,_,0, IS),
    simplify_slash_star(IS,NS).
simplify_slash(S, NS) :- 
    simplify_slash_star(S,NS),
    !.
simplify_slash(S, S).

simplify_slash_star(IS,NS) :-
    trl_pred(IS, NSI),
    trl_pi(NSI,NS).

sp(" ").
sp("\t").
sp("\n").

sp(" ").
sp("\t").


% arity > 0
trl_pred(L,NewLine) :-
    % EL = Bef+"@pred"+After
    (
      sub_string(L,Bef,_5,After,"@defgroup")
      ->
      true
      ;
      sub_string(L,Bef,_5,After,"@addgroup")
      ),
    After1 is After-10,

    sub_string(L,_,1,After1,SP),
    sp(SP),
    sub_string(L,_,After1,0,Line0),
    strip_whitespace(Line0,0,Line),
   sub_string(Line,_,1,Tit," "),
   sub_string(Line,_,Tit,0,NewLine),
   !.
% arity == 0
trl_pred(L,NewLine) :-
    % EL = Bef+"@pred"+After
    (
      sub_string(L,Bef,_,After,"@pred")
      ->
      true
      ;
      sub_string(L,Bef,5,After,"@Pred")
      ),
    After1 is After-1,

    sub_string(L,_,1,After1,SP),
    sp(SP),
    sub_string(L,_,After1,0,Line0),
    strip_whitespace(Line0,0,Line),
   sub_string(Line,_,1,_,"("),
    detect_name(Line,Name,Args,Arity,RL),
    !,
    atom_string(At,Name),
    defines_module(M),
    assert(pred_found(M,At,Arity)),
    sub_string(L,0,Bef,_, Prefix),
    string_concat([Prefix,"##       <b>",Name,Args,"</b> ",RL],NewLine).
% arity == 0
trl_pred(L,NewLine) :-
    (
      sub_string(L,Bef,5,After,"@pred")
      ->
      true
      ;
      sub_string(L,Bef,5,After,"@Pred")
      ),
    sub_string(L,_,After,0,L1),
    strip_whitespace(L1,0,L2),
    detect_name(L2,Name,Args,A,RL),
    !,
    atom_string(At,Name),
    defines_module(M),
    assert(pred_found(M,At,A)),
    sub_string(L,0,Bef,_, Prefix),
    %encode(Name/A,DoxName),
    string_concat( [Prefix,"##       <b>",Name ,"</b> ",RL],NewLine).
trl_pred(L,NewLine) :-
    sub_string(L,Bef,10,_After,"@infixpred"),
    A0 is Bef+10,
    skip_whitespace(A0,L,A1),
    A1>A0,
    block(A1,L,B1),
	       skip_whitespace(B1,L,A2),
	A2>A1,	
		block(A2,L,B2),
		skip_whitespace(B2,L,A3),
		A3>A2,
		block(A3,L,B3),
			   !,
			    L2 is B2-A2,
			    L1 is B3-A1,
			    sub_string(L,A2,L2,_,Name),
			    sub_string(L,A1,L1,_,NameArgs),
			    sub_string(L,B3,_,0,RL),
		%	    encode(Name/2,DoxName),
			    atom_string( At, Name),
			    defines_module(Mod),
			    assert(pred_found(Mod,At,2)),
			    sub_string(L,0,Bef,_, Prefix),
			    string_concat([Prefix,"##       ",NameArgs," ",RL],NewLine).
trl_pred(L,NewLine) :-
    sub_string(L,Bef,Sz,_After,"@prefixpred"),
    A0 is Bef+Sz,
    skip_whitespace(A0,L,A1),
    A1>A0,
    block(A1,L,B1),
	       skip_whitespace(B1,L,A2),
	A2>A1,	
		block(A2,L,B2),
			   !,
			    L2 is B1-A1,
			    L1 is B2-A1,
			    sub_string(L,A1,L2,_,Name),
			    sub_string(L,A1,L1,_,NameArgs),
			    sub_string(L,B2,_,0,RL),
  			    %ncode(Name/1,DoxName),
			    atom_string( At, Name),
			    defines_module(Mod),
			    assert(pred_found(Mod,At,1)),
			    sub_string(L,0,Bef,_, Prefix),
			    string_concat([Prefix,"## "   ",NameArgs," ",RL],NewLine).
rl_pred(L,L).

    strip_whitespace(Line0,I0,Line) :-
    sub_string(Line0,I0,1,_,SP),
    sp(SP),
    !,
    I is I0+1,
    strip_whitespace(Line0,I,Line).
    strip_whitespace(Line,0,Line) :-
    !.
    strip_whitespace(Line0,I0,Line) :-
    sub_string(Line0,I0,_,0,Line).

    skip_whitespace(I0,Line,IF) :-
    sub_string(Line,I0,1,_,SP),
    sp(SP),
    !,
    I is I0+1,
    skip_whitespace(I,Line,IF).
    skip_whitespace(I,_Line,I).

  
    block(I0,Line,IF) :-
    sub_string(Line,I0,1,_,SP),
\+    sp(SP),
    !,
    I is I0+1,
    block(I,Line,IF).
    block(I,_Line,I).

  
detect_name(Line,Name,NewArgs,Arity,Extra) :-
    sub_string(Line,Bef,1,_,"("),
    !,
    sub_string(Line,_,1,After,")"),
    sub_string(Line,0,Bef,_,Name),
    sub_string(Line,Bef,_Sz,After,Args),
    sub_string(Line,_,After,0,Extra),
    findall(I,sub_string(Args,I,1,_,","),Is),
    length([_|Is],Arity),
    string_chars(Args,LArgs),
    exclude(controlarg,LArgs,EAs),
    EAs = ['('|Cs], 
    Out = ['(',' '|NCs],

    addsp(Cs,NCs),
    string_chars(NewArgs,Out).

controlarg(' ').
controlarg('\t').
controlarg('*').
controlarg('_').
/*
controlarg('+').
controlarg('?').
*/

addsp([','|Cs],[',',' '|NCs]) :-
    !,
    addsp(Cs,NCs).
addsp([C|Cs],[C|NCs]) :-
    addsp(Cs,NCs).
addsp([],[]).

    
back(0,_L,0) :-
    !.
back(I0,S,I0) :-
    I is I0-1,
    sub_string(S,I,1,_,SP),
    sp(SP),    !.
    back(I0,S,P) :-
     I is I0-1,
    back(I,S,P).
   

digit("0").
digit("1").
digit("2").
digit("3").
digit("4").
digit("5").
digit("6").
digit("7").
digit("8").
digit("9").
    


trl_pi(L,NewLine) :-
    sub_string(L,Left,1,Extra,"/"),
    Left > 0,
    Extra > 0,
    Extra1 is Extra-1,
    sub_string(L,_,1,Extra1,D),
    digit(D),
    string_number(D,Arity),
    


    back(Left,L,NPrefix),
    NPrefix \= Left,
    !,
    sub_string(L,0,NPrefix,_,Prefix),
    ExtraP1 is Extra+1,
    sub_string(L,NPrefix,_,ExtraP1,Name),
%    encode(Name/Arity,DoxName0),
%    encode_dox(DoxName0,DoxName),
    Right is Extra-1,
    sub_string(L,_,Right,0,RightLine),
    trl_pi(RightLine,More),
    format(string(NewLine), "~s [~s/~d][#class~s] ~s", [Prefix,Name,Arity,DoxName,More]).
trl_pi(S,S).
    
alphanum(A) :-
    char_type(A,csym),
    !.
alphanum(':').

addcomm(N/A,S,false) :-
    is_exported(N,A),
    \+ pred_found(_M,N,A),
    !, length(L,A),
    maplist(=('?'),L),
    T =.. [N|L],
    format(ostream,'~n~n/** ~n@class #~s ~w     (undocumented)  **/~n~n',[S,T]).

addcomm(_,_,_).



user:directive(S,_M) :-
     repeat,
     read_clause(S,T,[]),
     (
	T == end_of_file
       ->

	!
       ;
       T = ( :- Directive )
       ->
	 user:dxpand(Directive)),
	 fail.

dxpand(module(M,Gs)) :-
    assert(defines_module(M,Gs)),
    maplist(pxpand(M),Gs),
    current_source_module(_,M).
dxpand(use_module(M,Gs)) :-
    decls(M),
    maplist(pxpand(M),Gs).
dxpand(use_module(M)) :-
    decls(M),
defines_module(Gs),
maplist(pxpand(M),Gs).
dxpand(compile(M)) :-
    decls(M),
defines_module(Gs),
maplist(pxpand(M),Gs).
dxpand(consult(M)) :-
    decls(M),
defines_module(Gs),
maplist(pxpand(M),Gs).
dxpand(reconsult(M)) :-
    decls(M),
defines_module(Gs),
maplist(pxpand(M),Gs).
dxpand(load_files(M._)) :-
    decls(M),
    defines_module(Gs),
    maplist(pxpand(M),Gs).
dxpand((A,B)) :-
    dxpand(A),
    dxpand(B).
dxpand(op(M,Gs,Y)) :-
    op(M,Gs,Y).


pxpand(Mod,op(M,Gs,Y)) :-
    op(M,Gs,Mod:Y),
    op(M,Gs,Y).
pxpand(Mod,A/B) :-
    assert(exported(Mod,A,B)).
pxpand(Mod,_ as A/B) :-
    assert(exported(Mod,A,B)).
pxpand(Mod,A//B):-
    B2 is B+2,
    assert(exported(Mod,A,B2)) .

decls(File) :-
    absolute_file_name(File, Y, [access(read),file_type(prolog),file_errors(fail),solutions(first)]),
    \+ visited(Y),
    assert(visited(Y)),
    %    valid_suffix(ValidSuffix),
    %    sub_atom(Y,_,_,0,ValidSuffix),
    file_directory_name(Y, Dir),
    working_directory(OldD,Dir),
    current_source_module(M0,M0),
    open(Y,read,S,[alias(loop_stream)]),
    script(S),
    findall(O, user:directive(S,O), _Info),
%spy trl,
    close(S),
     working_directory(_,OldD),
     current_source_module(_,M0).


is_exported(N,_) :-
    string(N),
    string_concat(`$`,_,N),
    !,
    fail.
is_exported(N,_) :-
    atom(N),
    sub_atom(N,0,1,_,'$'),
    !,
    fail.
is_exported(_,_) :-
    defines_module(user),
    !.
is_exported(N,A) :-
    defines_module(Mod),
    exported(Mod,N,A).

list([]) :- !.
list([_|L]) :-
    list(L).
