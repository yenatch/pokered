PYTHON := python

.SUFFIXES:
.SUFFIXES: .asm .tx .o .gbc
.PHONY: all clean red blue compare pngs
.SECONDEXPANSION:

POKEMONTOOLS := extras/pokemontools
GFX          := $(PYTHON) $(POKEMONTOOLS)/gfx.py
PIC          := $(PYTHON) $(POKEMONTOOLS)/pic.py
INCLUDES     := $(PYTHON) $(POKEMONTOOLS)/scan_includes.py
PREPROCESS   := $(PYTHON) prequeue.py

TEXTQUEUE :=

RED_OBJS  := \
pokered.o \
audio_red.o \
wram.o \
text.o

BLUE_OBJS := \
pokeblue.o \
audio_blue.o \
wram.o \
text.o

OBJS := $(RED_OBJS) $(BLUE_OBJS)
OBJS := $(sort $(OBJS))

ROMS := pokered.gbc pokeblue.gbc

# object dependencies
$(shell $(foreach obj, $(OBJS), $(eval $(obj:.o=)_DEPENDENCIES := $(shell $(INCLUDES) $(obj:.o=.asm)))))

all: $(ROMS)
red:  pokered.gbc
blue: pokeblue.gbc
compare:
	@md5sum -c --quiet roms.md5
clean:
	rm -f $(ROMS)
	rm -f $(OBJS)
	find . -iname '*.tx' -exec rm {} +
	rm -f redrle


redrle: extras/redtools/redrle.c
	${CC} -o $@ $<


%.asm: ;
.asm.tx:
	$(eval TEXTQUEUE += $<)
	@rm -f $@

$(OBJS): $$*.tx $$(patsubst %.asm, %.tx, $$($$*_DEPENDENCIES))
	@$(PYTHON) prequeue.py $(TEXTQUEUE)
	@$(eval TEXTQUEUE :=)
	rgbasm -o $@ $*.tx


OPTIONS = -jsv -k 01 -l 0x33 -m 0x13 -p 0 -r 03

pokered.gbc: $(RED_OBJS)
	rgblink -n $*.sym -m $*.map -o $@ $^
	rgbfix $(OPTIONS) -t "POKEMON RED" $@

pokeblue.gbc: $(BLUE_OBJS)
	rgblink -n $*.sym -m $*.map -o $@ $^
	rgbfix $(OPTIONS) -t "POKEMON BLUE" $@


pngs:
	find . -iname "*.pic"     -exec $(PIC) decompress {} +
	find . -iname "*.[12]bpp" -exec $(GFX) png {} +
	find . -iname "*.[12]bpp" -exec touch {} +
	find . -iname "*.pic"     -exec touch {} +

%.2bpp: %.png  ; $(GFX) 2bpp $<
%.1bpp: %.png  ; $(GFX) 1bpp $<
%.pic:  %.2bpp ; $(PIC) compress $<


