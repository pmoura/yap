/*
 * Language Server support
 *
 */

:- module(lsp, [
	      validate_file/2,
	      validate_text/3,
highlight_text/2,pred_def/4,
pred_def/2,
pred_refs/4,
complete/2,
highlight_file/2,
add_dir/2
  ]).

:- set_prolog_flag(double_quotes, string).

:- dynamic state/2, lsp_on/0.

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


name2symbol(File,UL0,U,Mod:N0/Ar0):-
	scanner:use(predicate,N0/Ar0,Mod,_NAr,_MI,File,UL0-UC0,UL0-UCF,_S1,_E1),
    UC0=<U,
    U=<UCF,
    !.

name2symbol(File,UL0,U,Mod:N0/Ar0):-
%listing(scanner:use),
	scanner:def(predicate,N0/Ar0,Mod,File,UL0-UC0,UL0-UCF,_S1,_E1),
	UC0=<U,
	U=<UCF,
	!.


symbol(N0/Ar0,Mod,
	t(SFile,L0,C0,LF,CF,LL0,LC0,LLF,LCF)) :-
    (
 	 scanner:def(predicate,N0/Ar0,Mod,DFile,L0-C0,LF-CF,LL0-LC0,LLF-LCF)
      *->
      true
    ;
      functor(G0,N0,Ar0),
      predicate_property(Mod:G0,file_name(DFile)),
      predicate_property(Mod:G0,line_number(L0)),
      C0=0,
      LF=L0,
      atom_length(N0,CF),
      LL0=L0,
      LC0= 0,
      LLF is L0+2,
      LCF= 0
    ),
    atom_string(DFile,SFile).

%%
%% @pred pred_def(Ob,N0)
%%
%% find the definition for the text at URI:Line:Ch
%%
pred_def(Ob,URI,Line,Ch) :-
	string_concat(`file://`, FS, URI),
	string_to_atom(FS, Afs),
	name2symbol(Afs,Line,Ch,Mod:N0/Ar0),
	findall(P,symbol(N0/Ar0, Mod,P),Ps),
	(var(Ob)
	->
	  Ob = Ps
	;
	  Ob.items := Ps
	).

pred_def(Ob, S) :-
    atom_string( Name, S),
    current_module( Mod),
    current_predicate(Mod:Name/Ar),
    functor(G,Name,Ar),
    predicate_property(Mod:G,file(F) ),
    predicate_property(Mod:G,line_count(L)),
    string_atom( SMod, Mod),
    Ob.defs.append(t(F,L,0,SMod,Ar)),
    fail.
pred_def(_Ob, _Name).

name2symbol(Name,t(F,Lines,0)) :-
    strip_module(Name,Mod,N),
    current_predicate(N,Mod:G),
    functor(G,N,_Ar),
    predicate_property(Mod:G,file(F) ),
    predicate_property(Mod:G,line_count(Lines)).

get_ref(N/A,M,Ref) :-
	scanner:use(predicate,N/A,M,_N0/_A0,_M0,File,L0-C0,LF-CF,LL0-LC0,LLF-LCF),
    atom_string(File,SFile),
    Ref = t(SFile,L0,C0,LF,CF,LL0,LC0,LLF,LCF).


%%
%% @pred pred_refs(URI,Line,Ch,Ob
%%
%% find the definition for the text at URI:Line:Ch
%%
pred_refs(Ob,URI,Line,Ch) :-
	string_concat(`file://`, FS, URI),
	string_to_atom(FS, Afs),
%	mkgraph(Afs),
	name2symbol(Afs,Line,Ch,M:N/A),
	findall(Ref,get_ref(N/A,M,Ref),Refs),
%	writeln(go2t:Refs) ,
	(var(Ob)
	->
	  Ob = Refs
	;
	  Ob.items := Refs
	).


complete(Prefix, FCs) :-
    completions(Prefix,FCs).

    add_dir(Self,URI):-
	string_concat(`file://`, FS, URI),
	atom_string(F,FS),
	file_directory_name(F,D),
	list_directory(D, Fs),
	maplist(add_file(Self, D), Fs).

%%
%% @pred validate_uri(Self,URI)
%%
%% check for errors or warnings in the file pointed to by URI. Obj is the
%% absolute_file_name(File,Path,[file_type(prolog)]),
%%    validate_file(Self,Path).

:- dynamic lsp/1.


user:term_expansion(G, []) :-
    lsp(on),
writeln(user_error,G).

exit_file(_Self,_) :-
    retractall(lsp(_)).


validate_file( Self,File) :-
%    atom_string(File, SFile),
%    string_concat("file://",SFile,URI),
    absolute_file_name(File, Path,
		       [ file_type(prolog),
			 access(read),
expand(true),
			 file_errors(fail)
		       ]),
assert(lsp(on)),
    load_files(Path,[syntax_errors(warning)]),
retract(lsp(_)).

validate_text(URI,S,Ts) :-
    atomic_concat('file://', File, URI),
    open(string(S),read,Stream),
    set_stream(Stream,[file_name(File)]),
assert(lsp(on)),
    load_files(File,[stream(Stream)]),
%close(Stream),
retract(lsp(_)),
findall(T,m(T),Ts),
writeln(user_error,out:Ts).

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
 EndCol is Column+Len.
    S = "discontiguous.~n".
q_msg(_error, error(syntax_error(_Msg), Desc),  t("error","syntax error", L,0,L1,0)) :-
    !,
L1 is L+1,
     exception_property(parserLine, Desc, L).
q_msg(_error, error(_,_Desc),  t("error","unknown error", 0,0,0,0)) :-
    !,
L1 is L+1,
     exception_property(parserLine, Desc, L).

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

user:highlight_uri(Self, URI, Text):-
	string_concat(`file://`,S,URI),
	atom_string(File,S),
	open(string(Text),read,Stream,[alias(File)]),
	set_stream(Stream,file_name(File)),
	highlight_and_convert_stream(Self,Stream).

highlight_file(Self, File) :-
    open(File,read,Stream,[alias(File)]),
    highlight_and_convert_stream(Self,Stream).

highlight_text(Self,Text):-
    open(string(Text),read,Stream,[alias(data)]),
    highlight_and_convert_stream(Self, Stream).

highlight_and_convert_stream(Self,Stream) :-
    scan_stream(Stream,Ts),
    close(Stream),
    symbols(Ts,LTsf),
    (var(Self)
    ->
      Self = LTsf
    ;
%:= print(LTsf).
     Self.data := LTsf
    ).

user:portray_message(A,B):-
    q_msg(A,B,T),
    !,
    assert(m(T)).



