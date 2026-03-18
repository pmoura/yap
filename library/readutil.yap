/*************************************************************************
*									 *
*	 YAP Prolog 							 *
*									 *
*	Yap Prolog was developed at NCCUP - Universidade do Porto	 *
*									 *
* Copyright L.Damas, V.S.Costa and Universidade do Porto 1985-1997	 *
*									 *
**************************************************************************
*									 *
* File:		readutil.yap						 *
* Last rev:	5/12/99							 *
* mods:									 *
* comments:	SWI compatible read utilities				 *
*									 *
*************************************************************************/

/**
 * @file   readutil.yap
 * @author VITOR SANTOS COSTA <vsc@VITORs-MBP.lan>
 * @date   Wed Nov 18 00:16:15 2015
 *
 * @brief  Read full lines and a full file in a single call.
 * 
 *
*/

:- module(readutil, [
	read_file_to_atom/2,
	read_file_to_chars/2,
	read_file_to_chars/3,
	read_file_to_codes/2,
	read_file_to_codes/3,
	read_file_to_string/2, 
                     read_file_to_terms/2,
                     read_file_to_terms/3,
                     read_file_to_terms/4,
	read_line_to_atom/2,
	read_line_to_chars/2,
	read_line_to_chars/3,
	read_line_to_codes/2,
	read_line_to_codes/3,
                     read_line_to_string/2,
	read_stream_to_atom/2,
	read_stream_to_chars/2,
	read_stream_to_chars/3,
	read_stream_to_codes/2,
	read_stream_to_codes/3,
	read_stream_to_string/2,
                     read_stream_to_terms/2,
                     read_stream_to_terms/3,
                     read_stream_to_terms/4             
		    ]).

/**
* @defgroup readutil Reading Lines and Files
* @ingroup YAPLibrary
* @{
*  Read full lines and a full file in a single call.
*
*/

/**
   read_file_to_atom( +_File_, -_Atom_)

   If _File_ is a readable text file, unify _Atom_ with
   the sequence of character atoms available from the file.

   If the file had been emptied before, unify _Atom_ with `end_of_file`.
   */
read_file_to_atom(File, Atom) :-
	open(File, read, Stream),
	read_stream_to_atom(Stream, Atom),
	close(Stream).

/**
   read_file_to_string( +_File_, -_String_)

   If _File_ is a readable text file, unify _String_ with
   the sequence of character strings available from the file.

   If the file had been emptied before, unify _String_ with `end_of_file`.
   */
read_file_to_string(File, String) :-
	open(File, read, Stream),
	read_stream_to_string(Stream, String),
	close(Stream).

/**
   read_stream_to_chars( +_Stream_, -_Chars_)

   If _Stream_ is a readable text stream, unify _Chars_ with
   the sequence of character charss available from the stream.

   If the stream had been emptied before, unify _Chars_ with `end_of_file`.
   */
read_stream_to_chars(Stream, Chars) :-
	read_stream_to_chars(Stream, Chars, []).

/**
   read_file_to_chars( +_File_, -_Chars_, ?_Tail_)

   If _File_ is a readable text file, unify _Chars_-_Tail with
   the sequence of character chars available from the file.

   */
read_file_to_chars(File, Chars, Chars0) :-
	open(File, read, Stream),
	read_stream_to_chars(Stream, Chars, Chars0),
	close(Stream).

/**
   read_file_to_chars( +_File_, -_Chars_)

   If _File_ is a readable text file, unify _Chars_ with
   the sequence of character chars available from the file.

   */
read_file_to_chars(File, Chars) :-
	open(File, read, Stream),
	read_stream_to_chars(Stream, Chars, []),
	close(Stream).

/**
   read_stream_to_codes( +_Stream_, -_Codes_)

   If _Stream_ is a readable text stream, unify _Codes_ with
   the sequence of character codess available from the stream.

   If the stream had been emptied before, unify _Codes_ with `end_of_file`.
   */
read_stream_to_codes(Stream, Codes) :-
	read_stream_to_codes(Stream, Codes, []).

/**
   read_file_to_codes( +_File_, -_Codes_, ?_Tail_)

   If _File_ is a readable text file, unify _Codes_-_Tail with
   the sequence of character codes available from the file.

   */
read_file_to_codes(File, Codes, Codes0) :-
	open(File, read, Stream),
	read_stream_to_codes(Stream, Codes, Codes0),
	close(Stream).

/**
   read_file_to_codes( +_File_, -_Codes_)

   If _File_ is a readable text file, unify _Codes_ with
   the sequence of character codes available from the file.

   */
read_file_to_codes(File, Codes) :-
	open(File, read, Stream),
	read_stream_to_codes(Stream, Codes, []),
	close(Stream).


 /**
   @pred read_file_to_terms( +_Stream_, -Terms, ?Tail, Opts)

   If _Stream_ is a file text stream, unify _Terms_ with
   the contents of the stream as a difference list of terms. Opts are the arguments used to
   read the term.

 */

read_file_to_terms(File, Codes, Tail, Opts) :-
    open(File, read, Stream),
	read_stream_to_terms(Stream, Codes, Tail, Opts),
	close(Stream).

/**
   @pred read_file_to_terms( +_Stream_, -Terms, ?Tail))
`
   If _Stream_ is a file text stream, unify _Terms_ with
   the contents of the stream as a difference list of terms.
 ,

 */
read_file_to_terms(File, Codes, Tail) :-
    open(File, read, Stream),
	read_stream_to_terms(Stream, Codes, Tail, []),
	close(Stream).

/**
   @pred read_file_to_terms( +_Stream_, -Codes)

   If _Stream_ is a file text stream, unify _String_ with
   the contents of the stream as a list of terms.

 */

read_file_to_terms(File, Codes) :-
    open(File, read, Stream),
	read_stream_to_terms(Stream, Codes, [], []),
	close(Stream).

%% @}
