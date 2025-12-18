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

char *bound_strstr(char *heap, char *key, char *bnd)
{
  char *rc = strstr( heap, key );
  if (rc >= bnd)
    return NULL;
  return rc;
}


char *bound_strchr(char *heap, int key, char *bnd)
{
  char *rc = strchr( heap, key );
  if (rc >= bnd)
    return NULL;
  return rc;
}

static void OW(char *start, char *end, bool prolog)
{
  if (prolog)
    fputs("\n/* new comment */\n",ostream);
  else
    fwrite(start, 1, (int)(end-start), ostream);
}

static void DW(char *start, char *end)
{
  fwrite(start, 1, (int)(end-start), ostream);
}

static char *protect_class(char *where, size_t arity, char *what, ssize_t sz) {
  ssize_t i;
  char *out = where;
  for (i = 0; i < sz+2; i++) {
    int ch = what[i];
    if(i==sz) ch = '/';
    if(i==sz+1) {
      ch = '0'+arity;
    }
    if (isalnum(ch) && ch!='Z') {      *out++ = ch;
    } else {
      out[0] = 'Z';
      out[1] = 'A' + ch / 16;
      out[2] = 'A' + ch % 16;
      out += 3;
    }
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


static char * pred_indicator(char *pred, char *end, ssize_t sz) {
  char buf[4096], *aptr, *line;
  ssize_t arity_extra;
  do {
    char *begin = pred;
    pred = bound_strchr(pred+1, '/',end);
    // fprintf(ostream, "%*s",  (int)(pred-start),start);
    
    if (!pred) {
      DW(begin,end);
      return end;
    }
    if (pred[1] == '/') {
      if (!isdigit(pred[2])) {
	pred++;
      }
      arity_extra = 2;
      aptr =pred+2 ;
    } else {
      if (!isdigit(pred[1])) {
	continue;
      }
      arity_extra = 0;
      aptr =pred+1;
    }
    size_t arity = 0;
    int  ch;
    char *namep;
    while (isdigit((ch=*aptr++))) {
    
      arity = arity*10 + ch-'0';
    }
    arity += arity_extra;
    namep = pred;
    if (isalnum(namep[-1])){
      while (isalnum((ch =  *--namep))|| ch== '_');
      ch = *++namep;
      line = namep;
      if (!islower(ch)) {
	pred = aptr;
	DW(begin,aptr);
	continue;
      } else {
	char *op = protect_class(buf,
				 arity, namep, pred-namep);
	aptr--;
	DW(begin,line);
	fprintf(ostream, "%.*s[%.*s][class%s]", 
		(int)(namep-line),line,
		(int)(aptr-namep), namep,op);
      }
      line = pred = aptr;
      continue;
    }
  }
  while (true);
  return NULL;
}


static char * CW(char *start, char *end)
{
  pred_indicator(start, end,true);
  return end;
}

static char *openline(bool star)
{ return star ? "\n" : "\n/// ";}


static char * infixpred_doc(char *pred,   bool star) {
  char buf[4096];
  pred += strlen("@prefixpred");
  while ((isblank(*pred++)));
  char *arg1 = pred;
  while (!(isblank(*pred++)));
  char *arg1f = pred;
  while ((isblank(*pred++)));
  char *op = pred;
  while (!(isblank(*pred++)));
  char *opf = pred;
  while ((isblank(*pred++)));
  char *arg2 = pred;
  while (!(isblank(*pred++)));
  char *arg2f = pred;
  char *safe_op = protect_class(buf, 2, op, opf-op);
  fprintf(ostream, "@link%s@endlink%s@class %s%s@brief %.*s1 %.*s %.*s   ", safe_op, openline(star),  safe_op,  openline(star),  (int)(arg1f-arg1), arg1,  (int)(opf-op), op, (int)(arg2f-arg2), arg2);
  //ne = arg2 + strlen(arg2) + 1;
  return arg2f;
}

static char * prefixpred_doc(char *pred, bool star) {
  char buf[4096];
  pred += strlen("@prefixpred");
  while ((isblank(*pred++)));
  char *op = pred;
  while (!(isblank(*pred++)));
  char *opf = pred;
  while ((isblank(*pred++)));
  char *arg1 = pred;
  while (!(isblank(*pred++)));
  char *arg1f = pred;
  char *safe_op = protect_class(buf, 1, op, opf-op);
  fprintf(ostream, "@link%s@endlink%s@class %s%s@brief  %.*s  %.*s  ", safe_op, openline(star),  safe_op,  openline(star),   (int)(opf-op), op, (int)(arg1f-arg1), arg1);
  //ne = arg2 + strlen(arg2) + 1;
  return arg1f;
}

static int commas(char *ptr, char *end, char ** bfp) {
  int arity = 1;
  char *buf = *bfp;
  while (ptr<end) {
    int ch = *ptr++;
    if (ch=='_') continue;
    if (ch=='*') continue;
    if (ch==' ') continue;
    if (ch=='\t') continue;
    if (ch==',') {
      *buf++ = ',';
      *buf++ = ' ';
      arity++;
      continue;
    }
    *buf++ = ch;
  }
  *buf++ = '\0';
  *bfp = buf;
  return arity;
}

static char * pred_doc(char *pred,  bool star) {
  char *name;
  char buf[4096];

  pred += strlen("@pred");
  while ((isblank(*pred++))) {};
  name = -- pred;
  while (!isblank(*pred) && *pred !=  '(') {
    pred++;
  }
  if (*pred != '(') {
    char *bf = protect_class(buf, 0, name, (int)(pred-name));
    fprintf(ostream, "@link #%s @endink%s@class %s%s @brief  %s", bf,
            openline(star), bf,
            openline(star), name);
    
    return pred;
  } else {
    char *args = pred + 1;
    char *end = strchr(args,')');
    char *bf0 = buf;
    int arity = commas(args,end, &bf0);
    *bf0++ = '\0';
    char *bf =
      protect_class(bf0+strlen(bf0)+1, arity, name, (args-1)-(name));
    //      fprintf(ostream, "@link %s %.*s/%d()[]{ #%s }\n@class %s\n@brief
    //      <b>%.*s(%s)</b>%s",
    fprintf(ostream,
	    "@link %s %.*s/%d  @endlink%s@class %s %s@brief<b>%.*s(%s)</b>",
	    bf, (int)(  (args-1)-name), name, arity,openline(star),
	    bf,openline(star), (int)(  (args-1)-name), name, bf0);
    return end+1;
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
    s0 = CW(s0, vs[lpred-1]);
    if (lpred==1) {
      s0= pred_doc(vs[0],slash_star)+strlen("@pred");
      vs[0]  = bound_strstr(s0,"@pred",sf); // need?
    } else if (lpred == 2) {
      s0 =infixpred_doc(s0,slash_star)+strlen("@infixpred");
      vs[1]  = bound_strstr(s0,"@infixpred", sf);
    } else if (lpred == 3) {
      s0=prefixpred_doc(s0,slash_star)+strlen("@prefixpred");
      vs[2]  = bound_strstr(s0,"@prefixpred", sf);
    } else if (lpred == 4) {
      char *start_vb = s0 = vs[3];
      int l = strlen("\n```");
      char *end_vb = bound_strstr(s0+l,"\n```", sf)+l;
      vs[3] = end_vb;
      if ( !end_vb) {
	end_vb = sf;
	fprintf(stderr, " Ugh, verbatim not closed.\n" );
	return false;
      }
      DW(start_vb, end_vb);
      s0 = end_vb;
      shift_right(s0,sf);
    }
  }
  if (s0 < sf) {
    s0 = CW(s0, sf);
  }
  //  sf[0] = c;
  return sf;
  
}
static      bool prior = false;


static char *next_comment(char *s0, char *s_end, bool prolog) {
  char *s1,*s2, *sf;
  char *sep_short, *sep_long;
  if (s0[0] == '\0') {
    return NULL;
  }
  // s1 : /* comment
  s1 = bound_strstr(s0,"/**", s_end );
  // line comments
  if (prolog) {
    sep_short = "\n\% ";
    sep_long = "\n\%\% ";
  } else {
    sep_short = "\n// ";
    sep_long = "\n/// ";
  }
  /** line setup */
  s2 = bound_strstr(s0, sep_long, s_end );
  char *s2short = bound_strstr(s0, sep_short, s_end );
  if (s2short && (!s2 || s2short < s2)) {
    fputs("\n// ",ostream);
    s2 = s2short+strlen(sep_short)-1;
  } else if (s2)  {
    prior = true;
    s2 += strlen(sep_long)-1;
    fputs("\n/// ",ostream);
  } else {
    prior = false;
  }
  prior = true;
  if (s2)  {
    s2++;
  } else {
    prior = false;
  }
  // line done
  if (!s1 && !s2) {
    if (s0)
    DW(s0,s0+strlen(s0));
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
    DW(s0,s1);
  }
  s0 = s1 ? s1 :s2;
  if (s0) {
    sf = bound_strstr(s0,terminator, s_end);
    if (!sf) {
      OW(s0, s0+strlen(s0), prolog);
    } else if (s0==s1) {
      DW(sf,sf+2);
    }
    if (s2==s0) {
    }
    // should be done
    s0 = slash_star(s0, sf, s0==s1);
    if (s0 < sf) {
      DW(s0,sf);
    }
    if (s0==s2) fputc('\n',ostream);
    return sf;
  } else {
    if (s0==s1) fputs("*/\n", ostream);
    return NULL;
  }
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
  //  fprintf(stderr,"%s\n",inp);

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




