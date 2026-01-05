/** 
 @file xml2yap.yap
 @author V Santos Costa

 @defgroup XML4PL XML to Prolog parser
 @ingroup YAPPackages
@{
 @brief Load XML files using the YAP C++ interface and the PUGI library.

This library imports a XML file as a Prolog term.

*/
:- module( xml4yap, [load_xml/2,
		     xml_load/2,
		     xml_pretty_print/1,
		     op(50, yf, []),
		     op(50, yf, '()'),
     op(50, yf, '{}'),
     op(100, xfy, '.'),
     op(100, fy, '.')
] ).


:- use_module(library(maplist)).

:- load_foreign_files([],['YAPxml'],libxml_yap_init).




/**
 @pred load_xml(+File, -Term)

Loads a XML file as a single Prolog term of the form key(Attr,Children)
where Key is the name of the term, Attr is a (possibly empty) list of attributes,
 and Children a list of nodes.

*/
load_xml(Inp, Out) :-
    absolute_file_name(Inp,File,[extensions([xml,html]),expand(true)]),
    c_load_xml(File, Out).

xml_load(Inp,Out) :-
    load_xml(Inp, Out).



/**
 @pred xml_pretty_print(+Stream)

Loads a XML Term that is then printed out on the
current output stream.
*/
xml_pretty_print(S) :-
    load_xml(S,Gs),
    maplist(pp(0),Gs).

pp(D,Node) :-
    string(Node),
    !,
    format('~*c"~s"~n' , [D,0' ,Node]).
pp(D,[Node]) :-
    string(Node),
    !,
    format('~*c["~s"]~n' , [D,0' ,Node]).
pp(D,Node) :-
    Node=..[Name,Atts,Tree],
    format('~*c(~q ',[D,0' ,Name]),
maplist(watt, Atts),
nl,
    D1 is D+1,
    maplist(pp(D1),Tree),
    format('~*c)~n',[D,0' ]).

watt(Att) :-
    atom(Att),
    !,
    format('~s ', [Att]).
watt(Att) :-
    string(Att),
    !,
    format('~s ', [Att]).
watt(Att) :-
    Att =.. [N,A],
    format('~s=~w ', [N,A]).

%% @}

