

#include <ctype.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <wchar.h>

static FILE *ostream;

static char *protect_class(char *where, bool xtraunds, size_t arity, char *what, ssize_t sz) {
  ssize_t i;
  char *out = where;
  for (i = 0; i < sz; i++) {
    int ch = what[i];
    if (isalnum(ch)) {
      *out++ = ch;
    } else {
      out[0] = '_';
      if (xtraunds) {
	out[1] = '_';
	out[2] = 'A' + ch / 16;
	out[3] = 'A' + ch % 16;
	out += 4;
      }  else {
	out[1] = 'A' + ch / 16;
	out[2] = 'A' + ch % 16;
	out += 3;
      }
    }
  }
  *out++ = '_';
  if (xtraunds) {
    *out++ = '_';
  }
  *out++ = arity + '0';
  out[0] = '\0';
  return where;
}


static char *clean(char *b0, char *bf) {
  int ch;

  while ((ch = *b0++)) {
     ;
    if (ch == '(' || ch ==',') {
      *bf++ = ch;
      *bf++ = ' ';
    } else if (ch != '_' && ch != '*'&& ch != ' ' && ch != ' ') {
      *bf++ = ch;
    }
  }
  bf[0] = '\0';
  return bf;
}

static bool pred_pi(char *line, char *end, ssize_t sz) {
  char buf[4096], bf[4096];
  buf[0] = '\0';
  char *pred;
  if (!line)
    return false;
  if ((pred = strstr(line, "/")) != NULL && end && pred < end && pred[-1] != '*') {
    // fprintf(ostream, "%*s",  (int)(pred-start),start);
    if (!isdigit(pred[1])) { return false; }
    int i = -1;
    while (pred + i >= line && (isalnum(pred[i]) || pred[i] == '_'))
      i--;
    i++;
    char *op = clean(protect_class(buf, true, pred[1]-'0', pred+i, -i+2), bf);
    line = pred+2;
    fprintf(ostream, "[%.*s/%d][class%s]", -i, pred + i, pred[1] - '0', op);
    buf[0] = '0';
    return pred_pi(pred+2, end, (end-(pred+2)));
  }
  return false;
}

static bool infixpred_doc(char *line, char *end, ssize_t sz) {
  char buf[4096];
  char *pred;
  if (!line)
    return false;
  if ((pred = strstr(line, "@infixpred")) != NULL && end && pred < end) {
    // fprintf(ostream, "%*s",  (int)(pred-start),start);
    /* char *decl =*/strtok(pred, " \t");
    char *arg1 = strtok(NULL, " \t");
    char *op = strtok(NULL, "\t ");
    char *arg2 = strtok(NULL, " \t");

    op = protect_class(buf, false, 2, op, strlen(op));
    line = arg2 + strlen(arg2) + 1;
    fprintf(ostream, "@class %s__2\n \n @brief  %s %s %s ", op, arg1, op,
            arg2);
    buf[0] = '0';
    return true;
  }
  return false;
}

static int commas(char *args) {
  int nargs = 1;
  if (*args != '\0')
    do {
      if (*args == ',')
        nargs++;
      args++;
    } while (*args);
  return nargs;
}

static bool pred_doc(char *line, char *end, ssize_t sz) {
  char *name, *args, *pred, *start = line;
  char buf[4096];
  if (!line)
    return false;
  if ((pred = strstr(line, "@pred")) != NULL && (!end || pred < end)) {
    fprintf(ostream, "%.*s", (int)(pred - start), start);
    char *prefix = strtok(pred, " \t(");
    name = strtok(NULL, " \t(");
    if (name == NULL || name + strlen(name) == end) {
      name = prefix + strlen(prefix) + 1;
      name = strtok(name, " \n");
      fprintf(ostream, "@class %s\n@brief  %s",
              protect_class(buf, false, 0, name, strlen(name)), name);
      line = name + strlen(name);
    } else {
      args = strtok(NULL, ")");
      int arity = commas(args);
      fprintf(ostream, "@class  %s\n *%s(%s)*\n",
              protect_class(buf,false, arity, name, strlen(name)), name, args);
     buf[0] = '0';
     line = args + strlen(args) + 1;
    }
    return true;
  }
  return false;
}

static char *process_doc(char *line, ssize_t sz) {
  char *end = line + sz;
  if (!infixpred_doc(line, end, sz) && !pred_doc(line, end,  sz) &&!pred_pi(line,end,sz)) {
    fprintf(ostream, "%.*s", (int)sz, line);
  }
  return line + sz;
}

static bool codecomm(char *p, bool star) {
  if (star) {
    return (p[2] == '*' || p[2] == '!') &&
           (isspace(p[3]) || (p[3] == '<' && isspace(p[4])));
  }
  return (p[2] == '/' || p[2] == '!') &&
         (isspace(p[3]) || (p[3] == '<' && isspace(p[4])));

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

static bool star(char *line, char **p,char *buf, bool code, char *line0) {
  bool rc = code;
  if (*p > line) {
    fprintf(ostream, "%.*s", (int)(*p - line), line);
  }
   line = *p;
   if ((*p = strstr(line, "*/"))) {
     rc = false;
     *p += 2;
   } else {
     *p=NULL;
   }
   if (strstr(line, "* ") == line)
     line+=2;
   else if (strstr(line, " * ") == line)
     line+=3;
   else if (strstr(line, "  * ") == line)
     line+=4;
   size_t sz= *p ? *p-line : strlen(line);
   if (code) {
      process_doc(*p, sz);
    } else {
      fprintf(ostream, "%.*s", (int)sz, line);
    }
    return rc;
}

#if 0
static bool spaces(const char *p, ssize_t sz) {
  ssize_t i = 0;
  while (i < sz) {
    if (!isspace(p[i]))
      return false;
    i++;
  }
  return true;
}
#endif

int main(int argc, char *argv[]) {
  int current_line = 1;
  size_t n;
  char *line = NULL, *p;
  FILE *f;
  char buf[4096];

  const char *inp = argv[1];
//  fprintf(stderr,"%s\n",inp);
  bool open_comment = false;
  bool verbatim = false;
  if (strstr(inp, ".yap") || strstr(inp, ".ypp") || strstr(inp, ".pl")) {
    //      execl(YAPBIN, "-L",  PLFILTER, "--", inp, NULL);
    snprintf( buf, 2047, "%s %s -L %s -- %s", YAPBIN, YAPSTARTUP, PLFILTER, inp);
    system(buf);
    exit(0);
  } else if (strstr(inp, ".py") || strstr(inp, ".md")) {
    snprintf(buf, 2047, "cat %s", inp);
    system(buf);
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
  bool code = false;
  p = NULL;
  char *line0 = NULL;
  bool starl = false;
  // line -> current unvisited line
  // line0 -> true start of current line
  // start the line by line loop
  while (f && !feof(f) && (line || // line is still alive
                      getline(&p, &n, f) > 0)) {
    // line0 is NULL if this is a new line
    /// we need our stuff
    if (!line) {
      current_line++;
      line0 = line = p;
    }
    ///  start with verbatim
    if (open_comment) {
      if (line && code && strstr(line, "```")==line) {
        fprintf(ostream, "%s", line);
        line = NULL;
        verbatim = !verbatim;
      }
      if (verbatim && line) {
        fprintf(ostream, "%s", line);
        line = NULL;
      }
    }
    /// going in
    if (line) {
      if (!open_comment) {
        if ((p = strstr(line, "/*")) != NULL) {
          starl = true;
          open_comment = true;
	  if (p > line) {
            fprintf(ostream, "%.*s", (int)(p - line), line);
	    line =p;
          }
          code = codecomm(line, true);
        } else           if ((p = strstr(line, "///"))) {
            open_comment = true;
            starl = false;
            if (p > line) {
              fprintf(ostream, "%.*s", (int)(p - line), line);
	      line = p;
            }
            code = codecomm(line, true);
        }
      }
    }
    if (open_comment) {
      if (starl) {
        open_comment = star(line, &p, buf, code, line0);
        line = p;
      } else {
        if ((line = strstr(p, "//")) > p) {
          fprintf(ostream, "%.*s", (int)(p - (line+2)), line + 2);
          p = line;
        process_doc(p, strlen(p)); 
       line = NULL;
        } else {
          open_comment = false;
        process_doc(p, strlen(p)); 
       line = NULL;
        }
      }
    } else {
      if (line) {
	fprintf(ostream, "%s", line);
	line = NULL;
      }
    }

    if (!line) {
      if (line0)
        free(line0);
      line0 = p = NULL;
    }
  }
}

///
