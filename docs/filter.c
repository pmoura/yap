#include <ctype.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <wchar.h>

static FILE *ostream;

static char *vs[5];
static  char *buf;

static char * CW(bool star, char *start, char *end);

char *bound_strstr(char *heap, char *key, char *bnd)
{
  char *rc = strstr( heap, key );
  if (rc >= bnd)
    return NULL;
  return rc;
}

static const char *openline(bool star)
{ return star ? "\n" : "\n/// ";}


char *bound_strchr(char *heap, int key, char *bnd)
{
  char *rc = strchr( heap, key );
  if (rc >= bnd)
    return NULL;
  return rc;
}

static int commas(char *ptr, char *end, char ** bfp, size_t *bfl) {
  int arity = 1;
  char *bf = buf;
	 
  size_t  len = 0;
  while (ptr<end) {
    int ch = *ptr++;
    if (ch=='_') continue;
    if (ch=='*') continue;
    if (ch==' ') continue;
    if (ch=='\t') continue;
    if (ch==',') {
      *bf++ = ',';
      *bf++ = ' ';
      len += 2;
      arity++;
      continue;
    }
    len ++;
    *bf++ = ch;
  }
  *bf++ = '\0';
  *bfp = buf;
  *bfl = len;
  return arity;
}

static void OW(char *start, char *end, bool prolog)
{
  if (prolog)
    fputs("\n\n",ostream);
  else
    fwrite(start, 1, (int)(end-start), ostream);
}

static void DW
(char *start, char *end)
{
  fwrite(start, 1, (int)(end-start), ostream);
}

static char *protect_class(char *where, size_t arity, char *what, ssize_t sz) {
  ssize_t i;
  char *out = where;
  for (i = 0; i < sz; i++) {
    int ch = what[i];
    if (isalnum(ch) && ch!='Z') {
      *out++ = ch;
    } else {
      out[0] = 'Z';
      out[1] = 'A' + ch / 16;
      out[2] = 'A' + ch % 16;
      out += 3;
    }
    out[0] = '0'+arity;
  }
  /*  if (isdigit(what[i-1]) && what[i-2] == '/'  	)
      {
      out[0] = '\0';
      return where;
      }
   *out++ = 'Z';
  
   *out++ = 'A' + '/'/16;
   *out++ = 'A' + '/'%16;
   *out++ = '0'+arity;
   */
  out[0] = '\0';
  //fprintf(stderr,"¨%.*s=>%s\n",(int)sz,where);
  return where;
}

static char *atomr(char *p) {
  int ch;
  do {
    ch = *--p;
  }  while (isalnum(ch) || ch=='_');
  if (p+1==p)
    return NULL;
  if (p[1] == '_' || isdigit(p[1]))
    return NULL;
  return p+1;
  
}

static long int arityf(char **ap)
{
  char *p = *ap;
  int ch;
  
  long int arity, arity_extra;
  if (p[0] == '/') {
    arity_extra = 2;
    p++;
  } else
    arity_extra = 0;
  arity = 0;
  if (!isdigit(*p))
    return -1;
  while (isdigit((ch=*p++))) {
    
      arity = arity*10 + ch-'0';
    }
    arity += arity_extra;
    *ap =  p;
    return arity;
}

typedef enum {
  STDPRED,
  STDPRED0,
  INFIX,
  PREFIX
} preds_t;


static char *def(int type, bool star, char *name, ssize_t namel, char *args, size_t argsl, char *arg2s, ssize_t arg2sl)
{
  const char *nl = openline(star);
  char *b0 = buf;
  b0[0]= '\0';
  size_t lcl;
  char be0[256], *be = be0;
  char bf0[256], *bf = bf0;
  char *rc;
  char pi0[256], *pi = pi0;
  switch (type) {
  case STDPRED:
    ssize_t arity = commas(args, args+argsl, &b0, &lcl);
   bf =  protect_class(  bf0, arity, name, (int)namel);
    sprintf(be, "%.*s(%.*s)", (int)namel, name, (int)strlen(buf), buf);
    sprintf(pi,"%.*s/%ld",(int)namel,name,arity);
   rc= args+(argsl+2);
   break;
  case STDPRED0:
    bf = protect_class(bf0, 0, name, (int)namel);
    sprintf(be, "%.*s", (int)namel, name);
    sprintf(pi,"%.*s/0",(int)namel,name);
    rc= name+(namel);
    break;
  case INFIX:
    bf = protect_class(buf, 2, name, (int)namel);
    sprintf(be, "%.*s %.*s", (int)namel, name, (int)argsl, args);
    sprintf(pi,"%.*s/2",(int)namel,name);
    rc = args + argsl;
    break;
  case PREFIX:
    bf = protect_class(buf, 1, name, (int)namel);
    sprintf(be, "%.*s %.*s %.*s", (int)argsl, args, (int)namel, name, (int)arg2sl, arg2s);
    sprintf(pi,"%.*s/1",(int)namel,name);
    rc = arg2s + arg2sl;
    break;
  }

/*
  fprintf(ostream, "%s@ %s%s@brief <b>%s</b> ", 
	  nl, be,nl,
	  bf);
*/
fprintf(ostream, "@class  %s%s@brief <b>%s</b> ", 
	//nl, bf,nl,
	  bf,nl,
	  be);

return rc;
}

static char * pred_indicator(char *s0, char *sf, bool star) {
  char  *name, *s=s0, *aptr, *pred;
  long int arity;
  
  while(s && s<sf) {
      if (!(pred = bound_strchr(s, '/',sf))) {
         DW(s0,sf);
	 return sf;
      } else {
	aptr=pred+1;
	arity = arityf(&(aptr));
	name = atomr(pred);
	if (arity >= 0 && name ) {
	  char *bf = protect_class(buf, arity, name, (int)(pred-name));
	  DW(s0, name);
	  fprintf(ostream,

		  "@ref class%.*s", 
		  //"@ref #%.*s% "
		  (int)strlen(bf)+1, bf
	  );
	  s0 = s = aptr+1;
	}
	s=aptr;
      }
 
  }

      DW(s0-1,sf);
      return sf;
}


static char * CW(bool star, char *start, char *end)
{

  
  pred_indicator(start, end,star);
  return end;
}


static char * infixpred_doc(char *pred,   bool star) {
  pred += strlen("@infixpred");
  while ((isblank(*pred++)));
  char *arg1 = pred;
  while (!(isspace(*pred++)));
  char *arg1f = pred;
  while ((isblank(*pred++)));
  char *op = pred;
  while (!(isspace(*pred++)));
  char *opf = pred;
  while ((isblank(*pred++)));
  char *arg2 = pred;
  while (!(isspace(*pred++)));
  char *arg2f = pred;
  return def(INFIX, star, op, opf-op, arg1, arg1f-arg1, arg2, arg2f-arg2);
}

static char * prefixpred_doc(char *pred, bool star) {
  pred += strlen("@prefixpred");
  while ((isspace(*pred++)));
  char *op = pred;
  while (!(isspace(*pred++)));
  char *opf = pred;
  while ((isblank(*pred++)));
  char *arg1 = pred;
  while (!(isspace(*pred++)));
  char *arg1f = pred;
  return def(INFIX, star, op, opf-op, arg1, arg1f-arg1, NULL, 0);
}

static char * pred_doc(char *pred,  bool star) {
  char *name;
  pred += strlen("@pred");
  while ((isblank(*pred++))) {};
  name = -- pred;
  while (isalnum(*pred) || *pred=='_') {
    pred++;
  }
  if  (*pred =='(') {
    char *args = pred + 1;
    char *end = strchr(args,')');
    //      <b>%.*s(%s)</b>%s",
    /* fprintf(ostream, */
    /* 	    "", */
    /* 	    bf, openline(star), */
    /* 	    bf,openline(star), (int)(  (args-1)-name), name, bf0); */
    return def(STDPRED, star, name, pred-name, args, end-args, NULL, 0);
  } else {
    return def(STDPRED0, star, name, pred-name, NULL, 0, NULL, 0);
  }
}

int minall( char *min) {
  int lmin=0;
  if (vs[0] && vs[0] < min) { min = vs[0]; lmin = 1; }
  if (vs[1] && vs[1] < min) {  min = vs[1]; lmin = 2; }
  if (vs[2] && vs[2] < min) {  min  =  vs[2]; lmin = 3; }
  if (vs[3] && vs[3] < min) {  min  =  vs[3]; lmin = 4; }
  return lmin;
}

static void    shift_right( char*s0, char *sf)
{
  vs[0] = bound_strstr(s0,"@pred", sf); 
  vs[1] = bound_strstr(s0,"@infixpred", sf); 
  vs[2] = bound_strstr(s0,"@prefixpred", sf);
  vs[3] = bound_strstr(s0,"\n```", sf);
  //  if (vs[3]) vs[3] += strlen("\n```");
}

static char * slash_star( char *s0, char *sf, bool slash_star) {
  int lpred;
  //   sf[0] =  '\0';

  vs[0] = bound_strstr(s0,"@pred", sf);
  vs[1] = bound_strstr(s0,"@infixpred", sf);
  vs[2] = bound_strstr(s0,"@prefixpred", sf);
  vs[3] = bound_strstr(s0,"\n```", sf) ;
  while ((lpred=minall(sf))) {
    if (lpred==1) {
      CW(slash_star, s0, vs[0]);
      s0= pred_doc(vs[0],slash_star)+strlen("@pred");
      vs[0]  = bound_strstr(s0,"@pred",sf); // need?
    } else if (lpred == 2) {
      CW(slash_star,s0, vs[1]);
      s0 =infixpred_doc(s0,slash_star)+strlen("@infixpred");
      vs[1]  = bound_strstr(s0,"@infixpred", sf);
    } else if (lpred == 3) {
      CW(slash_star,s0, vs[2]);
      s0=prefixpred_doc(s0,slash_star)+strlen("@prefixpred");
      vs[2]  = bound_strstr(s0,"@prefixpred", sf);
    } else if (lpred == 4) {

      CW(slash_star,s0, vs[3]);
char *start_vb = s0 = vs[3];
      int l = strlen("\n```");
      char *end_vb = bound_strstr(s0+l,"\n```", sf)+l;
      vs[3] = end_vb;
      if ( !end_vb) {
	end_vb = sf;
	fprintf(stderr, " Ugh, verbatim not closed.\n" );
	return false;
      }
      DW(start_vb, end_vb+3);
      s0 = end_vb+3;
      shift_right(s0,sf);
    }
  }
  if (s0 < sf) {
    s0 = CW(slash_star,s0, sf);
  }
  //  sf[0] = c;
  return sf;
  
}
static      bool prior = false;

bool is_valid(char *s10, char *ref)
{
  int i;
  int l = strlen(ref);
  if (s10) {
    for (i=0;i<l-1;i++) {
      if (s10[i]!=ref[i])
	return false;
    }
    return isspace(s10[i]);
  }
  return false;
}

static char *next_comment(char *s0, char *s_end, bool prolog) {
  char *s1,*s2, *s10,*s20;
  char *seq_short, *seq_long;
  if (s0[0] == '\0') {
    return NULL;
  }
  // s1 : /* comment
    // line comments
    if (prolog) {
      seq_short = "\n\% ";
     seq_long = "\n\%\% ";
    } else {
      seq_short = "\n// ";
      seq_long = "\n/// ";
    }
    char * s10o = s10=s0;
    s10 = bound_strstr(s10,"/*" , s_end);
  while (!is_valid(s10, "/** ")) {
    if (!s10) {
      break;
    }
    if (s10==s10o) {
      s10++;
      s10o = s10;
    }
    s10 = bound_strstr(s10+1,"/*" , s_end);
  }
  s1 = s10;
  char *s20o=s20=s0;
  if (prior) {
    s20 = bound_strstr(s20,seq_short, s_end );
  } else {
    prior = false;
    s20 = bound_strstr(s20,"/*" , s_end);
    while (!is_valid(s20, seq_long)) {
      if (!s20) {
	break;
      }
      if (s20==s20o) {
	s20++;
      s20o = s20;
    }
      s20 = bound_strstr(s20+1,seq_short, s_end );
    }
  }
  s2 = s20;
  if (s1 && (!s2|| s2 > s1))
    s2= NULL;
  else
    s1 = NULL;
  if (s2)  {
      s2++;
    } else {
      prior = false;
    }
  // line done
  if (!s1 && !s2) {
    OW(s0,s0+strlen(s0),prolog);
    return NULL;
  }
   char *terminator;
    if (s1 && (!s2 || s1<s2)) {
      terminator = "*/";
      prior = false;
    } else {
      terminator = "\n";
    }
    if (prolog) {
      if (!prior)
	fputs( "\n\n" ,ostream);
    }else {
      OW(s0,s1,prolog);
    }
    s0 = s1 ? s1 :s2;
    if (s0) {
      char *sf = bound_strstr(s0,terminator, s_end);
      if (!sf) {
	OW(s0, s0+strlen(s0), prolog);
	return  NULL;
      } else  {
	sf += strlen(terminator);
      }
      if (s2==s0) {
	if (!s1 && !s2) {
	  if (s0)
	    OW(s0,s0+strlen(s0), prolog);
	  return NULL;
	}
       }
      // should be done
      s0 = slash_star(s0, sf, s0==s1);
      if (s0 < sf) {
	OW(s0,sf,prolog);
      }
      if (s0==s2) fputc('\n',ostream);
      return sf;
    } else {
  //    if (s0==s1) fputs("*/\n", ostream);
      }
      return NULL;
}


static FILE *input( char *inp) {
  {
    return fopen(inp, "r");
  }
  return NULL;
}

static FILE *output(char *inp, char *out) {
  if (out)

    return fopen(out, "w");
  return stdout;
}
  


int main(int argc, char *argv[]) {
  char *p;
  FILE *f;
  bool prolog = false;

  //  fprintf(xstderr,"%s\n",inp);
  const char *inp = argv[1];
  if (!inp)
    exit(1);
  fprintf(stderr,"%s\n",inp);

  if (strstr(inp, ".yap") || strstr(inp, ".ypp") || strstr(inp, ".pl")) {
    //  char s[2048];
    //      execl(YAPBIN, "-L",  PLFILTER, "--", inp, NULL);
    //  snprintf(s, 2047, "%s %s -L %s -- %s", YAPBIN, YAPSTARTUP, PLFILTER, inp);
    prolog = true;
  } else if (strstr(inp, ".py") || strstr(inp, ".md")) {
    char s[2048];
    snprintf(s, 2047, "cat %s", inp);
    system(s);
    exit(0);
    return 1;
  }
  buf = calloc(1<<20,1);
  if (argc == 1) {
    f = stdin;
    ostream = stdout;
  } else if (argc == 2) {
    f = input(argv[1]);
    ostream = output(argv[1], NULL);
  } else {
    f = input(argv[1]);
    ostream = output(argv[1], argv[2]);
  }
  fseek(f, 0, SEEK_END) ;
  size_t fsize = ftell(f)+1;
  fseek(f,0,SEEK_SET);
  char *buf=(char *)malloc(fsize);
  fread(buf+1,  fsize, 1, f);
  p = buf;
  p[0] = '\n';
  buf[fsize] = 0;
  while (p && p<buf+fsize)
    p  = next_comment(p, buf+fsize, prolog);
}
///



