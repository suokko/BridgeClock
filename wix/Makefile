# User.mk has to set following
WIN32QMAKE :=
GCCLIBPATH := 
MINGWLIBPATH :=
WIN32PATH :=
LINUXCHROOT :=
LINUXQTPATH :=

include user.mk

WIN32QMAKE:=$(strip $(WIN32QMAKE))
GCCLIBPATH:=$(strip $(GCCLIBPATH))
MINGWLIBPATH:=$(strip $(MINGWLIBPATH))
WIN32PATH:=$(strip $(WIN32PATH))
LINUXCHROOT:=$(strip $(LINUXCHROOT))
LINUXQTPATH:=$(strip $(LINUXQTPATH))

ifeq ($(WIN32QMAKE),)
$(error "Win32 qmake path not set in user.mk")
endif
ifeq ($(GCCLIBPATH),)
$(error "Win32 gcc lib path not set in user.mk")
endif
ifeq ($(MINGWLIBPATH),)
$(error "Win32 mingw lib path not set in user.mk")
endif
ifeq ($(WIN32PATH),)
$(error "Win32 win32 root path not set in user.mk")
endif
ifeq ($(LINUXCHROOT),)
$(error "Linux build schroot name not set in user.mk")
endif
ifeq ($(LINUXQTPATH),)
$(error "Linux qt path not set in user.mk")
endif

ifeq ($(shell which heat.exe),)
$(error "Wix executables must be in path (heat.exe, light.exe and candle.exe)")
endif

ifneq ($(MAKECMDGOALS),clean_tr)
ifneq ($(shell cd .. && git ls-files -m),)
$(error "All changes has to be commited to the git")
endif
endif

COMMONQML := \
	QtQuick.2/* \
	QtQuick/Controls/Private/* \
	QtQuick/Controls/* \
	QtQuick/PrivateWidgets/* \
	QtQuick/Window.2/* \
	Qt/labs/settings/* \
	Qt/labs/folderlistmodel/* \
	QtWebKit/experimental/* \
	QtWebKit/* \
	QtQuick/Controls/Styles/Private/* \
	QtQuick/Controls/Styles/Base/* \
	QtQuick/Controls/Styles/Base/images/* \
	QtQuick/Controls/Styles/* \
	QtQuick/Dialogs/* \
	QtQuick/Dialogs/Private/* \
	QtQuick/Layouts/*

COMMONSRC := LICENSE \
	LICENSE.QT.LGPL \
	README \
	$(subst ../,,$(wildcard ../qml/BridgeClock/*)) \
	$(subst ../,,$(wildcard ../locale/*.qm))

LINUXCHROOTPATH := $(shell schroot -i -c $(LINUXCHROOT) | grep "^[ \t]*Directory" | sed 's/^[^\/]*//')
VERSION := $(shell date +'%Y.%m.%d')

all: BridgeClock-${VERSION}.msi BridgeClock-linux-${VERSION}.tar.gz BridgeClock-src-$(VERSION).tar.gz BridgeClock-versions.xml
	$(MAKE) clean_tr

#Localization rules
$(wildcard ../locale/*.qm): ../locale/stamp.release

../locale/stamp.release: ../BridgeClock.pro $(wildcard ../locale/*.ts)
	touch $@.tmp
	cd .. && lrelease $(notdir $<)
	mv $@.tmp $@

$(wildcard ../locale/*.ts): ../locale/stamp.update

../locale/stamp.update: ../BridgeClock.pro $(wildcard ../*.cpp ../qml/BridgeClock/*.qml)
	touch $@.tmp
	lupdate -locations absolute $<
	mv $@.tmp $@

# msi packaging
BridgeClock-${VERSION}.msi: files.wixobj BridgeClock.wixobj
	WINEDEBUG=fixme-all wine $$(which light.exe) -b win -sval BridgeClock.wixobj files.wixobj -o $@
	chmod 0644 $@

%.wixobj: %.wxs
	WINEDEBUG=fixme-all wine $$(which candle.exe) $<

BridgeClock.wxs BridgeClock-versions.xml: %: %.in vars.sh varsub date.stamp
	(sh < vars.sh; cat $<) | ./varsub > $@

.PHONY: date.stamp
date.stamp:
	( [ -e $@ ] && STAMPDATE=$$(date --date="`stat -c '%y' $@`" +'%Y.%m.%d') && CURDATE=$$(date  +'%Y.%m.%d') && \
		  [ $$STAMPDATE = $$CURDATE ] ) || touch $@

DEST= \
      $(wildcard win/*) \
      $(wildcard win/*/*) \
      $(wildcard win/*/*/*)

files.wxs: win $(DEST) win/BridgeClock.exe
	WINEDEBUG=fixme-all wine $$(which heat.exe) dir $< -gg -sfrag -srd -cg bcall -dr INSTALLDIR -o $@

win:
	
win32: BridgeClock-${VERSION}.msi

varsub: varsub.cpp
	${CXX} -O2 -g $^ -o $@

#windows build and file collecting

WIN32GCCLIBS := libgcc_s_sjlj-1.dll \
	libstdc++-6.dll

WIN32MINGWLIBS := libwinpthread-1.dll

WIN32LIBS := \
	libeay32.dll \
	ssleay32.dll \
	Qt5Positioning.dll \
	libGLESv2.dll \
	libEGL.dll \
	d3dcompiler_46.dll \
	Qt5WebKitWidgets.dll \
	Qt5QuickParticles.dll \
	Qt5XmlPatterns.dll \
	Qt5MultimediaWidgets.dll \
	Qt5OpenGL.dll \
	Qt5PrintSupport.dll \
	icudt55.dll \
	icuin55.dll \
	icuuc55.dll \
	Qt5Core.dll \
	Qt5Gui.dll \
	Qt5Multimedia.dll \
	Qt5Network.dll \
	Qt5Qml.dll \
	Qt5Quick.dll \
	Qt5Sensors.dll \
	Qt5Sql.dll \
	Qt5WebKit.dll \
	Qt5WebChannel.dll \
	Qt5Widgets.dll

WIN32BIN := QtWebProcess.exe

WIN32PLUGINS := \
	imageformats/qgif.dll \
	imageformats/qico.dll \
	imageformats/qjpeg.dll \
	imageformats/qtga.dll \
	imageformats/qtiff.dll \
	platforms/qwindows.dll

WIN32QML := $(subst $(WIN32PATH)/qml/,,$(wildcard $(addprefix $(WIN32PATH)/qml/,$(COMMONQML))))

WIN32RES := \
	icons/BridgeClock64.ico \
#

WIN32ALL := $(WIN32GCCLIBS) \
	$(WIN32MINGWLIBS) \
	$(WIN32LIBS) \
	$(WIN32BIN) \
	$(addprefix plugins/,$(WIN32PLUGINS)) \
	$(addprefix qml/,$(WIN32QML)) \
	$(COMMONSRC) \
	$(WIN32RES) \
	qt.conf

$(addprefix win/,$(WIN32GCCLIBS)): win/%.dll: ${GCCLIBPATH}/%.dll
	mkdir -p $(dir $@)
	cp $< $@

$(addprefix win/,$(WIN32MINGWLIBS)): win/%.dll: ${MINGWLIBPATH}/%.dll
	mkdir -p $(dir $@)
	cp $< $@

$(addprefix win/,$(WIN32BIN)): win/%.exe: ${WIN32PATH}/bin/%.exe
	mkdir -p $(dir $@)
	cp $< $@

$(addprefix win/,$(WIN32LIBS)): win/%.dll: $(WIN32PATH)/bin/%.dll
	mkdir -p $(dir $@)
	cp $< $@

$(addprefix win/plugins/,$(WIN32PLUGINS)): win/plugins/%.dll: ${WIN32PATH}/plugins/%.dll
	mkdir -p $(dir $@)
	cp $< $@

$(addprefix win/,$(filter-out %main.qml,$(COMMONSRC) $(WIN32RES))): win/%: ../%
	mkdir -p $(dir $@)
	cp $< $@

win/qml/%: ${WIN32PATH}/qml/%
	mkdir -p $(dir $@)
	[ -d $< ] || cp $< $@

win/qt.conf: qt.conf
	sed 's/\(Lib\|Binaries\).*/\1 = ./' < $< > $@

win/qml/BridgeClock/main.qml: ../qml/BridgeClock/main.qml date.stamp
	mkdir -p $(dir $@)
	sed 's/\$$(VERSION)/$(VERSION)/' < $< > $@

win/BridgeClock.exe: win-build/BridgeClock.exe $(addprefix win/,$(WIN32ALL))
	mkdir -p $(dir $@)
	cp $< $@

# Always try rebuild the binary
.PHONY: win-build/BridgeClock.exe
win-build/BridgeClock.exe:
	mkdir -p $(dir $@)
	cd $(dir $@) && $(WIN32QMAKE) "CONFIG+=release" "CONFIG-=debug_and_release_target debug_and_release" ../../BridgeClock.pro -o Makefile
	$(MAKE) -C $(dir $@)


#Linux package
BridgeClock-linux-${VERSION}.tar.gz: linux/BridgeClock date.stamp
	find $(dir $<) -type f -perm /u+x -exec strip {} +;
	find $(dir $<) -name "*.so*" -exec strip {} +;
	find $(dir $<) -name "*.debug" -delete
	[ -e BridgeClock-linux-${VERSION} ] || ln -s linux BridgeClock-linux-${VERSION}
	tar -h -cf - BridgeClock-linux-$(VERSION)/ | pigz -c -9 > $@

#Linux chroot build

LINUXBIN :=

LINUXLIBS :=

LINUXPLUGINS :=

LINUXQML :=

LINUXRES := \
	BridgeClock.desktop \
	icons/BridgeClock64.png \
#

LINUXALL := $(addprefix lib/,$(LINUXLIBS)) \
	$(LINUXBIN) \
	$(addprefix plugins/,$(LINUXPLUGINS)) \
	$(addprefix qml/,$(LINUXQML)) \
	$(COMMONSRC) \
	$(LINUXRES)

linux/lib/%: $(LINUXCHROOTPATH)/$(LINUXQTPATH)/%
	mkdir -p $(dir $@)
	[ -d $< ] || cp $< $@

linux/%: $(LINUXCHROOTPATH)/$(LINUXQTPATH)/%
	mkdir -p $(dir $@)
	[ -d $< ] || cp $< $@

linux/%: $(LINUXCHROOTPATH)/$(LINUXQTPATH)/qt5/%
	mkdir -p $(dir $@)
	[ -d $< ] || cp $< $@

linux/%: $(LINUXCHROOTPATH)/$(LINUXQTPATH)/qt5/libexec/%
	mkdir -p $(dir $@)
	cp $< $@

linux/%: ../%
	mkdir -p $(dir $@)
	[ -d $< ] || cp $< $@

linux/qt.conf: qt.conf
	mkdir -p $(dir $@)
	[ -d $< ] || cp $< $@

linux/qml/BridgeClock/main.qml: ../qml/BridgeClock/main.qml date.stamp
	sed 's/\$$(VERSION)/$(VERSION)/' < $< > $@

linux/BridgeClock: linux-build/BridgeClock ldddeps $(addprefix linux/,$(LINUXALL))
	mkdir -p $(dir $@)
	cp $< $@

ldddeps: linux-build/BridgeClock $(addprefix linux/plugins/,$(LINUXPLUGINS))
	mkdir -p linux/lib/
	CHROOTLIBS=`echo "ldd $^" | schroot -c stable`; \
	MISSING=`ldd $^ | grep "not found" | sed 's/^[\t ]*\([^=]*\) .*$$/\1/'`; \
	for F in $$MISSING; do \
		echo $$CHROOTLIBS | sed "s#^.* \(\/[^ ]*$$F\).*\$$#cp $(LINUXCHROOTPATH)\1 linux/lib/$$F#" | sh; \
	done

.PHONY: linux-build/BridgeClock
linux-build/BridgeClock:
	mkdir -p $(dir $@)
	echo "cd $(dir $@) && $(LINUXQTPATH)/qt5/bin/qmake ../../BridgeClock.pro && make -j4" | schroot -c $(LINUXCHROOT) /bin/bash

# Source package generation
source: BridgeClock-src-$(VERSION).tar.gz

BridgeClock-src-$(VERSION).tar.gz: BridgeClock-src-$(VERSION) ../.git/refs/heads/master date.stamp
	cd $< && git fetch origin && git reset --hard origin/master
	sed -i 's/\$$(VERSION)/$(VERSION)/' $</qml/BridgeClock/main.qml
	tar --exclude-vcs -cf - $< | pigz -c -9 > $@

BridgeClock-src-$(VERSION):
	git clone ../.git BridgeClock-src-$(VERSION)

clean_tr:
	cd .. && git diff -- locale | git apply -R || true

clean:
	rm -f varsub *.wxs *.wixobj *.wixpdb BridgeClock*.msi date.stamp
	rm -rf win win-build BridgeClock-src-* BridgeClock-linux* linux linux-build
	rm -f  ../locale/stamp.*
