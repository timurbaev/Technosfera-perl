#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

MODULE = Local::Stats		PACKAGE = Local::Stats		

INCLUDE: const-xs.inc

SV *new(char *class, SV *code)
	PPCODE:
		HV *hash = (HV *)sv_2mortal((SV *)newHV());
		hv_store(hash, "stats", 5, newRV(sv_2mortal((SV *)newHV())), 0);
		hv_store(hash, "code", 4, newSVsv(code), 0);
		XPUSHs(sv_2mortal(sv_bless(newRV((SV *)hash), gv_stashpv(class, TRUE))));

