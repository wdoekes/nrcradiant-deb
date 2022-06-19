#!/usr/bin/make -f

Q3A_HOMEPATH := $(realpath $(HOME)/.q3a)
Q3A_BASEGAME := baseq3

RADIANT_TOOLSDIR := /usr/lib/x86_64-linux-gnu/nrcradiant
#RADIANT_TOOLSDIR := /usr/bin
BUILD_BASEDIR := $(Q3A_HOMEPATH)
BUILD_PK3DIR := $(Q3A_HOMEPATH)/$(Q3A_BASEGAME)
BUILD_MAPDIR := $(Q3A_HOMEPATH)/$(Q3A_BASEGAME)/maps
BUILD_TEMP := $(Q3A_HOMEPATH)/_build
ifneq ($(BASENAME),)
BUILD_TEMPZIP := $(BUILD_TEMP)/$(BASENAME)
endif

SAMPLE_LEVELSHOT := /usr/share/nrcradiant/docs/shaderManual/antiportal_sm.jpg
#SAMPLE_LEVELSHOT := /usr/share/netradiant/gamepacks/q3.game/docs/Q3AShader_Manual/q3ashader_manual_files/image002.jpg


# ----------------------------------------------------------------------
# How does this work?
# ----------------------------------------------------------------------

.PHONY: settings
settings:
	@echo Q3A_HOMEPATH = $(Q3A_HOMEPATH)
	@echo Q3A_BASEGAME = $(Q3A_BASEGAME)
	@echo
	@echo BUILD_MAPDIR = $(BUILD_MAPDIR)
	@echo BUILD_PK3DIR = $(BUILD_PK3DIR)
	@echo BUILD_BASEDIR = $(BUILD_BASEDIR)
	@echo BUILD_TEMP = $(BUILD_TEMP)
	@echo
	@echo BASENAME = $(BASENAME)
	@echo "INCLUDE = $(INCLUDE)   # add extra ZIP includes"
	@echo
	@echo Invocation:
	@echo 'q3.make MYPROJECT.bsp'
	@echo "q3.make INCLUDE='scripts/my.shader textures/my' MYPROJECT.pk3"

#.PHONY: symlinks
#symlinks:

# ----------------------------------------------------------------------
# Shortcuts so we don't have to specify the full path
# ----------------------------------------------------------------------

ifeq ($(BASENAME),)
.PHONY: %.bsp
%.bsp:
	$(MAKE) -f $(firstword $(MAKEFILE_LIST)) BASENAME=$(notdir $(basename $@)) $(BUILD_MAPDIR)/$@

.PHONY: %.aas
%.aas:
	$(MAKE) -f $(firstword $(MAKEFILE_LIST)) BASENAME=$(notdir $(basename $@)) $(BUILD_MAPDIR)/$@

.PHONY: %.pk3
%.pk3:
	$(MAKE) -f $(firstword $(MAKEFILE_LIST)) BASENAME=$(notdir $(basename $@)) $(BUILD_PK3DIR)/$@

.PHONY: %.map.num
%.map.num:
	$(MAKE) -f $(firstword $(MAKEFILE_LIST)) BASENAME=$(notdir $(basename $(basename $@))) $(BUILD_MAPDIR)/$@

.PHONY: %.map.nonum
%.map.nonum:
	$(MAKE) -f $(firstword $(MAKEFILE_LIST)) BASENAME=$(notdir $(basename $(basename $@))) $(BUILD_MAPDIR)/$@
endif

# ----------------------------------------------------------------------
# Basic build stuff
# ----------------------------------------------------------------------

# Auto variables $< $@ etc...
# https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html
.PRECIOUS: $(BUILD_MAPDIR)/%.aas
$(BUILD_MAPDIR)/%.aas: $(BUILD_MAPDIR)/%.bsp
	mkdir -p $(BUILD_TEMP)
	cd $(BUILD_TEMP) && $(RADIANT_TOOLSDIR)/mbspc -optimize -forcesidesvisible -bsp2aas $^

.PRECIOUS: $(BUILD_MAPDIR)/%.bsp
$(BUILD_MAPDIR)/%.bsp: $(BUILD_MAPDIR)/%.map
	# First build lin, prt and srf. PRT only if there are leaks?
	$(RADIANT_TOOLSDIR)/q3map2 -v -game quake3 -fs_basepath "$(BUILD_BASEDIR)" -meta $^
	# Build vis, needed for optimized map rendering.
	$(RADIANT_TOOLSDIR)/q3map2 -v -game quake3 -fs_basepath "$(BUILD_BASEDIR)" -vis -saveprt $^
	# Full(ish) build
	$(RADIANT_TOOLSDIR)/q3map2 -v -game quake3 -fs_basepath "$(BUILD_BASEDIR)" \
	  -light -fast -patchshadows -samples 2 -bounce 2 -dirty -gamma 2 \
	  -compensate 4 $^

# ----------------------------------------------------------------------
# Hacks
# See: https://github.com/Garux/netradiant-custom/issues/106
# ----------------------------------------------------------------------

.PHONY: $(BUILD_MAPDIR)/%.map.num
$(BUILD_MAPDIR)/%.map.num: $(BUILD_MAPDIR)/%.map
	if ! grep -q '^// entity ' $<; then \
	  perl \
	    -e 'sub pe{print "// entity ".$$e++."\n";$$b=0;};' \
	    -e 'sub pb{print "// brush ".$$b++."\n"};' \
	    -e '$$d=0;' \
	    -e 'for(<>){' \
	    -e '/^{/ && $$d eq 0 && pe;' \
	    -e '/^{/ && $$d eq 1 && pb;' \
	    -e '/^{/ && $$d++;' \
	    -e '/^}/ && $$d--;' \
	    -e 'print;' \
	    -e '}' <$< >$@ && \
	  cat $@ >$< && \
	  rm $@; \
	fi

.PHONY: $(BUILD_MAPDIR)/%.map.nonum
$(BUILD_MAPDIR)/%.map.nonum: $(BUILD_MAPDIR)/%.map
	if grep -q '^// entity ' $<; then \
	  sed -e '/^\/\/ \(brush\|entity\) [0-9]/d' $< >$@ && \
	  cat $@ >$< && \
	  rm $@; \
	fi

# ----------------------------------------------------------------------
# Populate _build dir so we can zip it up
# ----------------------------------------------------------------------

ifneq ($(BUILD_TEMPZIP),)
ifneq ($(BASENAME),)
$(BUILD_TEMPZIP)/maps/%.aas: $(BUILD_MAPDIR)/%.aas
	mkdir -p $(BUILD_TEMPZIP)/maps && cp -L $< $@
$(BUILD_TEMPZIP)/maps/%.bsp: $(BUILD_MAPDIR)/%.bsp
	mkdir -p $(BUILD_TEMPZIP)/maps && cp -L $< $@
$(BUILD_TEMPZIP)/maps/%.map: $(BUILD_MAPDIR)/%.map
	mkdir -p $(BUILD_TEMPZIP)/maps && cp -L $< $@
$(BUILD_TEMPZIP)/levelshots:
	# Make levelshots dir, but also add sample JPG if we're creating it.
	mkdir -p "$@" && cp -a "$(SAMPLE_LEVELSHOT)" "$@/$(BASENAME).jpg"
$(BUILD_TEMPZIP)/scripts:
	# Make scripts dir, but also add sample ARENA file
	mkdir -p "$@"
	printf '%s\n' \
	  '{' \
	  "map \"$(BASENAME)\"" \
	  "longname \"The $(BASENAME) Map\"" \
	  'bots "grunt doom major bones sorlag"' \
	  'timelimit "20"' \
	  'fraglimit 30' \
	  'type "ctf team ffa tourney"' \
	  '}' >"$@/$(BASENAME).arena"

.PRECIOUS: $(BUILD_PK3DIR)/%.pk3  # do not auto-delete
$(BUILD_PK3DIR)/%.pk3: \
    $(BUILD_TEMPZIP)/maps/%.aas \
    $(BUILD_TEMPZIP)/maps/%.bsp \
    $(BUILD_TEMPZIP)/maps/%.map \
    $(BUILD_TEMPZIP)/levelshots \
    $(BUILD_TEMPZIP)/scripts
	mapdir="$(BUILD_TEMP)/$(notdir $(basename $@))" && \
	  includesdir="$(BUILD_BASEDIR)/$(Q3A_BASEGAME)" && \
	  mkdir -p "$$mapdir" && \
	  cd "$$includesdir" && \
	  find env/$(BASENAME) scripts/$(BASENAME).shader textures/$(BASENAME) 2>/dev/null | \
	    rsync -L -v -r --files-from=- . "$$mapdir/"
	  if test -n "$(INCLUDE)"; then \
	    find $(INCLUDE) -type f | \
	      rsync -L -v --files-from=- . "$$mapdir/"; \
	  fi && \
	  cd "$(BUILD_TEMPZIP)" && \
	  zip -r $@ *
endif
endif
