#include <ctype.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <wchar.h>
static bool prolog;

static FILE *ostream;

static char *protect_class(char *where, size_t arity, char *what, ssize_t sz) {
  ssize_t i;
  char *out = where;
  for (i = 0; i < sz+2; i++) {
    int ch = what[i];
    if(i==sz) ch = '/';
    if(i==sz+1) {
      ch = '0'+arity;
    }
    if (isalnum(ch) && ch!='Z') {
      *out++ = ch;
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

static bool pred_indicator(char **linep, char *end, ssize_t sz) {
  char *pred, *line = *linep, *aptr;
  ssize_t arity_extra;
  char buf[4096];
  pred = line;
  bool rc = false;
  while ((pred = strstr(pred+1, "/")) != NULL && end && pred < end) {
    // fprintf(ostream, "%*s",  (int)(pred-start),start);
    if (pred[1] == '/') {
      if (!isdigit(pred[2])) {
	pred++;
	continue;
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
    if (isalnum(namep[-1])) {
      while (isalnum((ch =  *--namep))|| ch== '_');
      ch = *++namep;
      if (!islower(ch)) {
	pred = aptr;
	continue;
      } else {
	char *op = protect_class(buf,
				 arity, namep, pred-namep);
	aptr--;
	fprintf(ostream, "%.*s[%.*s][class%s]", 
		(int)(namep-line),line,
		(int)(aptr-namep), namep,op);
      }
      *linep = line = pred = aptr;
      rc = true;
      continue;
    }
  }
  if (rc && line) {
    fprintf(ostream, "%s", line);
    *linep = NULL;
  }
  return rc;
}

static void CW(char *start, char *end)
{
  fwrite(start, 1, (int)(end-start), ostream);
}

static void OW(char *start, char *end, bool prolog)
{
  if (prolog)
    fputs("\n/* new comment */\n",ostream);
  else
    fwrite(start, 1, (int)(end-start), ostream);
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
  return arity;
}

static char * pred_doc(char *pred,  bool star) {
  char *name;
  char buf[4096];

  name = pred;
  pred += strlen("@pred");
  while ((isblank(*pred++))) {};
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
      char *bf =
	protect_class(bf0+strlen(bf0)+1, arity, name, (args-1)-(name));
      //      fprintf(ostream, "@link %s %.*s/%d()[]{ #%s }\n@class %s\n@brief
      //      <b>%.*s(%s)</b>%s",
      fprintf(ostream,
              "@link %s %.*s/%d  @endlink%s@class %s %s@brief<b>%.*s(%s)</b>%s",
              bf, (int)(  (args-1)-name), name, arity,openline(star),
              bf,openline(star), (int)(  (args-1)-name), name, bf0, end+1);
    return end+1;
  }
}

int minall(char *vs[5]) {
  char *min = NULL;
  int lmin=0;
  if (vs[0] && vs[0] < min) { min = vs[0]; lmin = 1; }
  if (vs[1] && vs[1] < min) {  min = vs[1]; lmin = 2; }
  if (vs[2] && vs[2] < min) {  min  =  vs[2]; lmin = 3; }
//  if (vs[3] && prefixd < min) {  min  =  prefixd; lmin = 4; }
  return lmin;
  }

static char * slash_star(char *s0, char *sf) {
  int lpred;
  int c = sf[0];
  char *vs[5];
  sf[0] =  '\0';
    vs[0] = strstr(s0,"@pred");
  vs[1] = strstr(s0,"@infixpred");
  vs[2] = strstr(s0,"@prefixpred");
  vs[3] = strstr(s0,"\n```");
  char *f0 = s0;
  while ((lpred=minall(vs))) {
    CW(vs[lpred],s0);
    if (lpred==1) {
     f0= pred_doc(vs[0],true);
      vs[0]  = strstr(vs[0],"@pred");
    } else if (lpred == 2) {
      f0 =infixpred_doc(vs[1],true);
      vs[1]  = strstr(vs[0],"@infixpred");
    } else if (lpred == 3) {
      f0=prefixpred_doc(vs[2],true);
      vs[2]  = strstr(vs[0],"@prefixpred");
    }
  }
  CW(f0,sf);
  sf[0] = c;
  return sf;
}

static char *next_comment(char *s0, bool prolog) {
    char *s1 = strstr(s0,"/**");
    if (!s1) {
      OW(s0, s0+strlen(s0), prolog);
      return NULL;
    }
    char *sf = strstr(s1+3,"*/");

    if (!sf) {
      OW(sf, s0+strlen(sf), prolog);
      return NULL;
    }
    sf += 2;
    OW(s0,s1,prolog);
    slash_star(s1, sf);
    return sf;
}

static FILE *input(char *inp) {
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

int main(int argc, char *argv[])
{
  char *p;
  FILE *f;



  const char *inp = argv[1];
  //  fprintf(xstderr,"%s\n",inp);

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
  fread(buf,  fsize-1, 1, f);
  p = buf;
  buf[fsize] = 0;
  while (p)
    p  = next_comment(p, prolog);
}
///



