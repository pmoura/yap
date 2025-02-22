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
* File:		eval.c							 *
* Last rev:								 *
* mods:									 *
* comments:	arithmetical expression evaluation			 *
*									 *
*************************************************************************/
#ifdef SCCS
static char     SccsId[] = "%W% %G%";
#endif

/**
   @file arith0.c

*/

//! @{

/**
   @defgroup arithmetic_operators Arithmetic Functions
   @ingroup arithmetic

   YAP implements several arithmetic functions, they are defined as
   fields in three enumerations, such that there is one enumeration
   per each different arity:  

    - #arith0_op defines constants and arity 0 arithmetic functions

      @copydoc #arith0_op

    - #arith1_op defines single argument arithmetic functions

      @copydoc #arith1_op

    - #arith2_op defines binary arithmetic functions

      @copydoc #arith2_op

  Arithmetic expressions
  in YAP may use the following operators:

  {#pi_0}
   - <b>pi [ISO]</b><p> 

     An approximation to the value of <em>pi</em>, that is, the ratio of a circle's circumference to its diameter.

     {#e_0}
   - <b>e</b><p>    

     Euler's number, the base of the natural logarithms.


     <{#>epsilon</b><p> {#epsilon_0}
   -

     The difference between the float `1.0` and the next largest floating point number.
{#inf_0}
     - `inf`  

     Infinity according to the IEEE Floating-Point standard. Note that evaluating this term will generate a domain error in the `iso` language mode.

     Note also that YAP supports `+inf` and  `-inf`

      {#nan_0}
   - <b>nan (not a number)</b><p>  

     Not-a-number according to the IEEE Floating-Point standard. Note that evaluating this term will generate a domain error in the `iso` language mode.

   - <b>random</b><p>  @anchor random_0

     A pseudo-random floating point number between 0 and 1.

   - <b>signed_integer_random</b><p>  @anchor random_i

     A pseudo-random integer number with 32 bits.

   - <b>unsigned_integer_random</b><p>  @anchor random_u

     A pseudo-random unsigned integer number with 32 bits.

   - <b>cputime</b><p>  @anchor cputime_0

     CPU time since YAP was invoked, in seconds.

   - <b>heapused</b><p>  @anchor heapused_0

     Heap (data-base) space used, in bytes.

   - <b>local</b><p>  @anchor local_0

     Local stack in use, in bytes

   - <b>$b</b><p>  @anchor b_0

     current choicepoint

   - <b>$env</b><p>  @anchor env_0

     Environment

   - <b>$tr</b><p>  @anchor tr_0

     Trail in use

   - <b>$free_stack</b><p>  @anchor free_stack_0
     
     Amount of free stack space, that is, free space between global and local stacks.

   - <b>global</b><p>  @anchor global_0

     Global stack in use, in bytes.
 *
 */

#include "Yap.h"
#include "Yatom.h"
#include "YapHeap.h"
#include "YapEval.h"



static Term
eval0(Int fi) {
  CACHE_REGS
  arith0_op fop = fi;
  switch (fop) {
  case op_pi:
    {
      RFLOAT(PI);
    }
  case op_e:
    {
      RFLOAT(M_E);
    }
  case op_epsilon:
    {
      RFLOAT(DBL_EPSILON);
    }
  case op_inf:
    {
#ifdef _MSC_VER /* Microsoft's Visual C++ Compiler */
      Yap_ThrowError(TYPE_ERROR_EVALUABLE, TermNil, "evaluating infinity");
#else
      if (isoLanguageFlag()) {/* iso */
      P = (yamop *)FAILCODE;
	Yap_ThrowError(TYPE_ERROR_EVALUABLE, TermNil, "evaluating infinity");
	P = (yamop *)FAILCODE;
	return false;
      } else {
	RFLOAT(INFINITY);
      }
#endif
    }
  case op_nan:
    {
#ifdef _MSC_VER /* Microsoft's Visual C++ Compi<ler */
      Yap_ThrowError(TYPE_ERROR_EVALUABLE, TermNil, "evaluating infinity");
       P = (yamop *)FAILCODE;
     return false;
#else
      if (isoLanguageFlag()) {/* iso */
	Yap_ThrowError(TYPE_ERROR_EVALUABLE, TermNil, "evaluating not-a-number");
      P = (yamop *)FAILCODE;
	return false;
      } else {
	RFLOAT(NAN);
      }
#endif
    }
  case op_random:
    {
      RFLOAT(Yap_random());
    }
  case op_signed_integer_random:
    {
      RINT(Yap_signed_integer_random());
    }
  case op_unsigned_integer_random:
    {
      RINT(Yap_unsigned_integer_random());
    }
  case op_cputime:
    {
      RFLOAT((Float)Yap_cputime()/1000000.0);
    }
  case op_heapused:
    /// - heapused
    ///   Heap (data-base) space used, in bytes.
    ///
    RINT(HeapUsed);
  case op_localsp:
    /// - local
    ///   Local stack in use, in bytes
    ///
#if YAPOR_SBA
    RINT((Int)ASP);
#else
    RINT(LCL0 - ASP);
#endif
  case op_b:
    /// - $b
    ///   current choicepoint
    ///
#if YAPOR_SBA
    RINT((Int)B);
#else
    RINT(LCL0 - (CELL *)B);
#endif
  case op_env:
    /// - $env
    ///   Environment
    ///
#if YAPOR_SBA
    RINT((Int)YENV);
#else
    RINT(LCL0 - YENV);
#endif
  case op_tr:
    /// - $tr
    ///   Trail in use
    ///
#if YAPOR_SBA
    RINT(TR);
#else
    RINT(((CELL *)TR)-LCL0);
#endif
  case op_stackfree:
    /// - $free_stack
    ///   
    /// Not-a-number according to the IEEE Floating-Point standard. Note that evaluating this term will generate a domain error in the `iso` language mode.
    RINT(Unsigned(ASP) - Unsigned(HR));
  case op_globalsp:
    /// - global
    ///   Global stack in use, in bytes.
    ///
#if YAPOR_SBA
    RINT((Int)HR);
#else
    RINT(HR - H0);
#endif
  }
  /// end of switch
  return false;
}

Term Yap_eval_atom(Int f)
{
  return eval0(f);
}

typedef struct init_const_eval {
  char          *OpName;
  arith0_op      f;
} InitConstEntry;

static InitConstEntry InitConstTab[] = {
  {"pi", op_pi},
  {"e", op_e},
  {"epsilon", op_epsilon},
  {"inf", op_inf},
  {"nan", op_nan},
  {"random", op_random},
  {"signed_integer_random", op_signed_integer_random},
  {"unsigned_integer_random", op_unsigned_integer_random},
  {"cputime", op_cputime},
  {"heapused", op_heapused},
  {"local_sp", op_localsp},
  {"global_sp", op_globalsp},
  {"$last_choice_pt", op_b},
  {"$env", op_env},
  {"$tr", op_tr},
  {"stackfree", op_stackfree},
};


static Int
current_evaluable_property_0( USES_REGS1 )
{
  Int i = IntOfTerm(Deref(ARG1));
  if (i >= sizeof(InitConstTab)/sizeof(InitConstEntry)) {
    return false;
  }
  return Yap_unify(ARG2, MkAtomTerm(Yap_LookupAtom(InitConstTab[i].OpName)));
}

static Int
is_evaluable_property_0( USES_REGS1 )
{
  int i = 0;
  const char *s = RepAtom(AtomOfTerm(Deref(ARG1)))->StrOfAE;
  while (i < sizeof(InitConstTab)/sizeof(InitConstEntry)) {
    if (!strcmp(s,InitConstTab[i].OpName)) {
      return true;
    }
  }
    return false;
}

void
Yap_InitConstExps(void)
{
  unsigned int    i;
  ExpEntry       *p;

  for (i = 0; i < sizeof(InitConstTab)/sizeof(InitConstEntry); ++i) {
    AtomEntry *ae = RepAtom(Yap_LookupAtom(InitConstTab[i].OpName));
    if (ae == NULL) {
      Yap_ThrowError(RESOURCE_ERROR_HEAP,TermNil,"at InitConstExps");
      return;
    }
    WRITE_LOCK(ae->ARWLock);
    if (Yap_GetExpPropHavingLock(ae, 0)) {
      WRITE_UNLOCK(ae->ARWLock);
      break;
    }
    p = (ExpEntry *) Yap_AllocAtomSpace(sizeof(ExpEntry));
    p->KindOfPE = ExpProperty;
    p->ArityOfEE = 0;
    p->ENoOfEE = 0;
    p->FOfEE = InitConstTab[i].f;
    AddPropToAtom(ae, (PropEntry *)p);
    WRITE_UNLOCK(ae->ARWLock);
  }
  Yap_InitCPred("$current_evaluable_property0", 2, current_evaluable_property_0, SafePredFlag);
  Yap_InitCPred("$is_evaluable_property0", 1, is_evaluable_property_0, SafePredFlag);
}

/* This routine is called from Restore to make sure we have the same arithmetic operators */
int
Yap_ReInitConstExps(void)
{
  return TRUE;
}

/// @}
