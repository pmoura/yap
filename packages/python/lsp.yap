/*
 * Language Server support
 *
 */

:- module(lsp, [
	      validate_file/2,
	      validate_text/3,
symbol_at/3,
defi/2,
refs/2,
file_symbols/2,
workspace_symbols/1,
complete/2]).

    /*
highlight_text/2,pred_def/4,
pred_def/2,
pred_refs/4,
highlight_file/2,
add_dir/2
  ]).
*/
    
:- set_prolog_flag(double_quotes, string).

:- dynamic state/2, lsp_on/0, use/9, def/6.

:- use_module(library(lists)).
:- use_module(library(maplist)).
:- use_module(library(toks_lsp)).
:- reexport(library(python)).
:- use_module(library(yapi)).
:- use_module(library(hacks)).
:- use_module(library(completions)).

:- use_module(library(scanner)).

%:- python_import(lsprotocol.types as t).
%:- python_import(pygls.server).


    %%
    %% symbol(AllSymbowls)
    %%
file_symbols(URI, All) :-
    string_concat("file://", FileS, URI),
    string_to_atom(FileS, File),
    findall(t(Name,Line), def(Name,_,_,Line,File,_),All).

workspace_symbols(All) :-
    findall(t(Name,Line,URI), symbol_in_def(Name,Line,URI), All).

symbol_in_def(Name,Line,URI) :-
    def(Name,_,_,Line,File,_),
    string_to_atom(FileS, File),
    string_concat("file://", FileS, URI).

    %%
    %%
    
complete(Prefix, FCs) :-
    completions(Prefix,FCs),
!.
complete(_Prefix, []).

%%
%% @pred validate_uri(Self,URI)
%%
%% check for errors or warnings in the file pointed to by URI. Obj is the
%% absolute_file_name(File,Path,[file_type(prolog)]),
%%    validate_file(Self,Path).

:- dynamic lsp/1, m/1.


user:term_expansion(G, g) :-
    lsp(on),
!,
    prolog_load_context(term_position, '$stream_position'(_A,Line,_B,_C)),
    prolog_load_context(file, F),
    prolog_load_context(module,M),
analyse(G,Line,F,M).

analyse(( :- module(M,Ls)),L,F,M0) :-
    assert(def(''.0,M,L,F,module)),
    assert(use('',0,M,'',0,M0,L,F,module)),
    maplist(mod(L,F,M),Ls).
analyse(( :- op(A,B,C)), _Line,_File,M) :- 
    op(A,B,M:C).
analyse(( :- use_module(_A)), _Line,_File,_M) :- 
    !.
analyse(( :- use_module(_A,_B)), _Line,_File,_M) :- 
    !.
analyse(( :- load_files(_A,_B)), _Line,_File,_M) :- 
    !.
analyse(( :- ensure_loaded(_A)), _Line,_File,_M) :- 
    !.
analyse(( :- consult(_A)), _Line,_File,_M) :- 
    !.
analyse(( :- reconsult(_A)), _Line,_File,_M) :- 
    !.
analyse(( :- compile(_A)), _Line,_File,_M) :- 
    !.
analyse(( :- _), _Line,_File,_M) :- 
    !.
analyse(( :- use_module(_A,_B,_C)), _Line,_File,_M) :- 
    !.
analyse((A0:- B),L,F,M) :-
    strip_module(M:A0,MH,A),
    functor(A,Na,Ar),
    (
    def(Na,Ar,MH,_,_,predicate)
       ->
    true
    ;
    assert(def(Na,Ar,MH,L,F,predicate))
    ),
    body(B,L,F,M,M:Na/Ar).

body(A,_L,_F,_M,_) :-
    var(A),
!.
body(M:A,L,F,_M,P0) :-
    !,
    body(A,L,F,M,P0).
body((A,B),L,F,M,P0) :-
    !,
    body(A,L,F,M,P0),
    body(B,L,F,M,P0).
body((A;B),L,F,M,P0) :-
    !,
    body(A,L,F,M,P0),
    body(B,L,F,M,P0).
body((A->B),L,F,M,P0) :-
    !,
    body(A,L,F,M,P0),
    body(B,L,F,M,P0).
body(A,L,F,M,M0:Na0/Ar0) :-
    functor(A,NA,Ar),
    assert(use(NA,Ar,M,Na0,Ar0,M0,L,F,predicate)).

mod(Line,File,M,N/A) :- assert(dec(N,A,M,Line,File,export(predicate))).
mod(Line,File,M,N//A) :-
 A1 is A+ 2,
assert(dec(N,A1,M,Line,File,export(predicate))).
mod(Line,File,M, op(A,B,C)) :- 
    op(A,B,M:C),
 assert(dec(C,A,B,Line,File,export(op))).


validate_file(File, Errors) :-
%    atom_string(File, SFile),
%    string_concat("file://",SFile,URI),
writeln(ok),
   absolute_file_name(File, Path,
		       [ file_type(prolog),
			 access(read),
expand(true),
			 file_errors(fail)
		       ]),
assert(lsp(on)),
    load_files(Path,[]),
retractall(lsp(_)),
findall(T,retract(m(T)),Errors).

validate_text(URI,S,Ts) :-
    atomic_concat('file://', File, URI),
retractall(def(_,_,_,_,File,_)),
    retractall(use(_,_,_,_,_,_,_,File,_)),
retractall(dec(_,_,_,File._)),
    open(string(S),read,Stream),
    set_stream(Stream,[file_name(File)]),
assert(lsp(on)),
    load_files(File,[stream(Stream)]),
%close(Stream),
retractall(lsp(_)),
findall(T,retract(m(T)),Ts).


q_msg(informational, _, _) :-
    !,
    fail.
q_msg(help, _, _) :-
    !,
    fail.
q_msg(warning, error(style_check(singletons,[VName,Line,Column,_F0],_),_Desc),t("warning",S, Line,Column, Line,EndCol)) :-
    !,
    format(string(S), 'singleton variable ~s.~n ', [VName]),
    atom_length(VName, Len),
 EndCol is Column+Len.
q_msg(warning, error(style_check(multiple,[F0|L],I ) ,_Desc ), t("warning",S, L,Column,L,EndCol)) :-
    !,
Column=0,
    format(string(S), '~w previously defined at ~s.~n',[I,F0]),
I = _:Name/_,
    atom_length(Name, Len),
 EndCol is Column+Len.
q_msg(warning, error(style_check(discontiguous,_,_I ), _Desc), t("warning",S, L,Column, L, EndCol)) :-
    !,
Column=0,
    format(string(S), 'discontiguous definion for ~w.~n',[I]),
I = _:Name/_,
    atom_length(Name, Len),
 EndCol is Column+Len,
    S = "discontiguous.~n".
q_msg(_error, error(syntax_error(_Msg), Desc),  t("error","syntax error", L,1,L1,1)) :-
    !,
Desc \= [],
    exception_property(parserLine, Desc, L),
L1 is L+1.


add_file(Self, D, File) :-
    absolute_file_name(File, Path,
			   [ file_type(prolog),
relative_to(D),
			     access(read),
			     file_errors(fail)
			     ]),
    once((
		user:prolog_file_type(Suffix,prolog),
	   atom_concat(_, Suffix , Path)
	 )),
    !,
    validate_file(Self,Path).
add_file(_,_,_).

symbol_at(Line, Pos, Symbol) :-
    open(string(Line),read,Stream,[alias(data)]),
    scan_stream(Stream,Ts),
    close(Stream),
    at(Ts, Pos, Symbol),
    !.
    
at([t(atom(Name), _Line, PosS, Sz, _Ch)|_], Pos, Name ) :-
    PosS =< Pos,
    PosS+Sz >  Pos,
    !.
at([t(_, _Lne, PosS, _Sz, _Ch)|Toks], Pos, Name ) :-
    PosS <  Pos,
    !,
    at(Toks, Pos, Name ).

defi(NA,t(URI,L)) :-
    def(NA,_Ar,_MH,L,File,predicate),
    string_to_atom(FileS, File),
    string_concat("file://", FileS, URI).

    refs(NA,L) :-
    findall(t(URI,L), ref(NA,URI,L), L).

ref(Na0,URI,L) :-
    use(_NA,_Ar,_M,Na0,_Ar0,_M0,L,File,predicate),
    string_to_atom(FileS, File),
    string_concat("file://", FileS, URI).
   
 

    
user:highlight_uri( URI, Text, LTsf):-
	string_concat(`file://`,S,URI),
	atom_string(File,S),
	open(string(Text),read,Stream,[alias(File)]),
	set_stream(Stream,file_name(File)),
	highlight_and_convert_stream(Stream, LTsf).

highlight_file(Self, File) :-
    open(File,read,Stream,[alias(File)]),
    highlight_and_convert_stream(Self,Stream).

highlight_text(Text, LTsf):-
    open(string(Text),read,Stream,[alias(data)]),
    highlight_and_convert_stream(Stream, LTsf).

highlight_and_convert_stream(Stream, LTsf) :-
    scan_stream(Stream,Ts),
    close(Stream),
    symbols(Ts,LTsf).

user:portray_message(A,B):-
    lsp(on),
    !,
    (
    q_msg(A,B,T)
    ->
    assert(m(T))
       ;
    true
    ).




