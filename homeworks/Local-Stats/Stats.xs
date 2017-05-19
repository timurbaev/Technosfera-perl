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

void add(SV *self, char *name, double value)
	PPCODE:
		ENTER;
		SAVETMPS;
		if (!(SvOK(self) && SvROK(self)))
			croak("$self must be a hashref");
		HV *hself = (HV *)(SvRV(self));
		if (!hv_exists(hself, "stats", 5))
			croak("$self->{stats} does not exist");
		SV **_stats_ = hv_fetch(hself, "stats", 5, 0);
		if (!_stats_)
			croak("$self->{stats} is NULL");
		HV *stats = (HV *)(SvRV(*_stats_));
		if (!hv_exists(stats, name, strlen(name)))
		{
			if (!hv_exists(hself, "code", 4))
				croak("$self->{code} does not exist");
			SV **_sub_ = hv_fetch(hself, "code", 4, 0);
			if (!(_sub_ && SvTYPE(SvRV(*_sub_)) == SVt_PVCV))
				croak("$self->{code} is not a sub");
			SV *sub = SvRV(*_sub_);
			PUSHMARK(SP);
			XPUSHs(sv_2mortal(newSVpv(name, strlen(name))));
			PUTBACK;
			int count = call_sv(sub, G_ARRAY);
			SPAGAIN;
			HV *parameters = (HV *)sv_2mortal((SV *)newHV());
			int i;
			for (i = 0; i < count; i++) {
				SV *parameter = newSVsv(POPs);
				char *sname = (char *)SvPV_nolen(parameter);
				hv_store(parameters, sname, strlen(sname), newSV(0), 0);
			}
			SV *rparameters = newRV((SV *)parameters);
			hv_store(stats, name, strlen(name), rparameters, 0);
			SV *rstats = newRV((SV *)stats);
			hv_store(hself, "stats", 5, rstats, 0);
			self = newRV((SV *)hself);
		}
		SV **_mstats = hv_fetch(stats, name, strlen(name), 0);
		if (!(_mstats && SvTYPE(SvRV(*_mstats)) == SVt_PVHV))
			croak("$self->{stats}->{%s} is not a hashref", name);
		HV *mstats = (HV *)SvRV(*_mstats);
		if (hv_exists(mstats, "avg", 3)) {
			if (!hv_exists(hself, "_stats_", 7))
				hv_store(hself, "_stats_", 7, newRV((SV *)sv_2mortal((SV *)newHV())), 0);
			SV **_stats = hv_fetch(hself, "_stats_", 7, 0);
			if (!(_stats && SvTYPE(SvRV(*_stats)) == SVt_PVHV))
				croak("$self->{_stats_} is not a hashref");
			HV *_istats_ = (HV *)(SvRV(*_stats));
			if (!hv_exists(_istats_, name, strlen(name))) {
				HV *metric = (HV *)sv_2mortal((SV *)newHV());
				hv_store(metric, "cnt", 3, newSVuv(0), 0);
				hv_store(_istats_, name, strlen(name), newRV((SV *)metric), 0);
			}
			SV **_metric = hv_fetch(_istats_, name, strlen(name), 0);
			if (!(_metric && SvTYPE(SvRV(*_metric)) == SVt_PVHV))
				croak("$self->{_stats_}->{%s} is not a hashref", name);
			HV *metric = (HV *)(SvRV(*_metric));
			if (!hv_exists(metric, "cnt", 3))
				hv_store(metric, "cnt", 3, newSVuv(0), 0);
			SV **_cnt_ = hv_fetch(metric, "cnt", 3, 0);
			if (!(_cnt_ && SvTYPE(*_cnt_) == SVt_IV))
				croak("$self->{_stats_}->{%s}->{cnt} is not an uint", name);
			unsigned int cnt = SvUV(*_cnt_);
			SV **_avg_ = hv_fetch(mstats, "avg", 3, 0);
			if (!_avg_)
				croak("$self->{stats}->{%s}->{avg} is NULL", name);
			double avg;
			if (SvTYPE(*_avg_) == SVt_NULL) {
				avg = value;
				cnt = 1;
			} else {
				avg = SvNV(*_avg_);
				avg = (avg * cnt + value) / (cnt + 1);
				cnt++;
			}
			hv_store(mstats, "avg", 3, newSVnv(avg), 0);
			hv_store(metric, "cnt", 3, newSVuv(cnt), 0);
			hv_store(_istats_, name, strlen(name), newRV((SV *)metric), 0);
			hv_store(hself, "_stats_", 7, newRV((SV *)_istats_), 0);
			self = newRV((SV *)hself);
		}
		if (hv_exists(mstats, "cnt", 3)) {
			SV **cnt_ = hv_fetch(mstats, "cnt", 3, 0);
			if (!(cnt_))
				croak("$self->{stats}->{%s}->{cnt} is NULL", name);
			double cnt = (SvTYPE(*cnt_) == SVt_NULL) ? 1 : SvUV(*cnt_) + 1;
			hv_store(mstats, "cnt", 3, newSVuv(cnt), 0);
		}
		if (hv_exists(mstats, "min", 3)) {
			SV **min_ = hv_fetch(mstats, "min", 3, 0);
			if (!(min_))
				croak("$self->{stats}->{%s}->{min} is NULL", name);
			double min = (SvTYPE(*min_) == SVt_NULL) ? value : SvNV(*min_);
			if (value < min)
				min = value;
			hv_store(mstats, "min", 3, newSVnv(min), 0);
		}
		if (hv_exists(mstats, "max", 3)) {
			SV **max_ = hv_fetch(mstats, "max", 3, 0);
			if (!(max_))
				croak("$self->{stats}->{%s}->{max} is NULL", name);
			double max = (SvTYPE(*max_) == SVt_NULL) ? value : SvNV(*max_);
			if (value > max)
				max = value;
			hv_store(mstats, "max", 3, newSVnv(max), 0);
		}
		if (hv_exists(mstats, "sum", 3)) {
			SV **sum_ = hv_fetch(mstats, "sum", 3, 0);
			if (!(sum_))
				croak("$self->{stats}->{%s}->{sum} is NULL", name);
			double sum = (SvTYPE(*sum_) == SVt_NULL) ? value : SvNV(*sum_) + value;
			hv_store(mstats, "sum", 3, newSVnv(sum), 0);
		}
		hv_store(stats, name, strlen(name), newRV((SV *)mstats), 0);
		hv_store(hself, "stats", 5, newRV((SV *)stats), 0);
		self = newRV((SV *)hself);
		FREETMPS;
		LEAVE;
		
SV *stat(SV *self)
	PPCODE:
		ENTER;
		SAVETMPS;
		if (!(SvOK(self) && SvROK(self)))
			croak("$self must be a hashref");
		HV *hself = (HV *)(SvRV(self));
		if (!hv_exists(hself, "stats", 5))
			croak("$self->{stats} does not exist");
		SV **_stats_ = hv_fetch(hself, "stats", 5, 0);
		if (!_stats_)
			croak("$self->{stats} is NULL");
		HV *stats = (HV *)(SvRV(*_stats_));
		hv_iterinit(stats);
		SV *_mstats;
		char *name;
		int length;
		HV *result = (HV *)(sv_2mortal((SV *)newHV()));
		while ((_mstats = hv_iternextsv(stats, &name, &length))) {
			if (!SvTYPE(SvRV(_mstats)) == SVt_PVHV)
				croak("$self->{stats} are not hashrefs");
			HV *mstats = (HV *)(SvRV(_mstats));
			hv_iterinit(mstats);
			SV *value;
			char *stat_name;
			int _length;
			int keys = 0;
			HV *buffer = (HV *)sv_2mortal((SV *)newHV());
			while ((value = hv_iternextsv(mstats, &stat_name, &_length))) {
				hv_store(buffer, stat_name, _length, newSVsv(value), 0);
				hv_store(mstats, stat_name, _length, newSV(0), 0);
				keys++;
			}
			if (keys > 0)
				hv_store(result, name, length, newRV((SV *)buffer), 0);
			hv_store(stats, name, length, newRV((SV *)mstats), 0);
		}
		SV *rresult = newRV((SV *)result);
		FREETMPS;
		LEAVE;
		XPUSHs(sv_2mortal(rresult));
