
# User.mk has to set following
WIN32QMAKE :=
GCCLIBPATH := 
MINGWLIBPATH :=
WIN32PATH :=

include user.mk

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

ifneq ($(shell git ls-files -m),)
$(error "All changes has to be commited to the git")
endif

COMMONQML := \
	QtQuick.2/* \
	QtQuick/Controls/Private/* \
	QtQuick/Controls/* \
	QtQuick/Window.2/* \
	QtWebKit/experimental/* \
	QtWebKit/* \
	QtQuick/Controls/Styles/Private/* \
	QtQuick/Controls/Styles/Base/* \
	QtQuick/Controls/Styles/Base/images/* \
	QtQuick/Controls/Styles/* \
	QtQuick/Dialogs/* \
	QtQuick/Layouts/*

COMMONSRC := BridgeClock80.png \
	LICENSE \
	LICENSE.QT.LGPL \
	$(subst ../,,$(wildcard ../qml/BridgeClock/*))

LINUXCHROOTPATH := $(shell schroot -i -c $(LINUXCHROOT) | grep "^[ \t]*Directory" | sed 's/^[^\/]*//')
VERSION := $(shell date +'%y.%m.%d')

all: BridgeClock.msi BridgeClock-linux-${VERSION}.tar.gz BridgeClock-src-$(VERSION).tar.gz

# msi packaging
BridgeClock.msi: files.wixobj BridgeClock.wixobj
	WINEDEBUG=fixme-all light.exe -b win -sval BridgeClock.wixobj files.wixobj -o BridgeClock.msi
	chmod 0644 BridgeClock.msi

%.wixobj: %.wxs
	WINEDEBUG=fixme-all candle.exe $<

BridgeClock.wxs: BridgeClock.wxs.in vars.sh varsub
	(sh < vars.sh; cat BridgeClock.wxs.in;) | ./varsub > BridgeClock.wxs

DEST= \
      $(wildcard win/*) \
      $(wildcard win/*/*) \
      $(wildcard win/*/*/*)

files.wxs: win $(DEST) win/BridgeClock.exe
	WINEDEBUG=fixme-all heat.exe dir $< -gg -sfrag -srd -cg bcall -dr INSTALLDIR -o $@

win:

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
	libwebp-5.dll \
	Qt5WebKitWidgets.dll \
	Qt5MultimediaWidgets.dll \
	Qt5OpenGL.dll \
	Qt5PrintSupport.dll \
	libjpeg-9.dll \
	libpng16-16.dll \
	icudt51.dll \
	icuin51.dll \
	icuuc51.dll \
	Qt5Core.dll \
	Qt5Gui.dll \
	Qt5Multimedia.dll \
	Qt5Network.dll \
	Qt5Qml.dll \
	Qt5Quick.dll \
	Qt5Sensors.dll \
	Qt5Sql.dll \
	Qt5WebKit.dll \
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

WIN32ALL := $(WIN32GCCLIBS) \
	$(WIN32MINGWLIBS) \
	$(WIN32LIBS) \
	$(WIN32BIN) \
	$(addprefix plugins/,$(WIN32PLUGINS)) \
	$(addprefix qml/,$(WIN32QML)) \
	$(COMMONSRC) \
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

$(addprefix win/,$(WIN32LIBS)): win/%.dll: $(WIN32PATH)/lib/%.dll
	mkdir -p $(dir $@)
	cp $< $@

$(addprefix win/plugins/,$(WIN32PLUGINS)): win/plugins/%.dll: ${WIN32PATH}/plugins/%.dll
	mkdir -p $(dir $@)
	cp $< $@

$(addprefix win/,$(COMMONSRC)): win/%: ../%
	mkdir -p $(dir $@)
	cp $< $@

win/qml/%: ${WIN32PATH}/qml/%
	mkdir -p $(dir $@)
	[ -d $< ] || cp $< $@

win/qt.conf: qt.conf
	sed 's/\(Lib\|Binaries\).*/\1 = ./' < $< > $@

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
BridgeClock-linux-${VERSION}.tar.gz: linux/BridgeClock
	find $(dir $<) -type f -perm /u+x -exec strip {} +;
	find $(dir $<) -name "*.so*" -exec strip {} +;
	find $(dir $<) -name "*.debug" -delete
	[ -e BridgeClock-linux-${VERSION} ] || ln -s linux BridgeClock-linux-${VERSION}
	tar -h -cf - BridgeClock-linux-$(VERSION)/ | pigz -c -9 > $@

#Linux chroot build

LINUXBIN := QtWebProcess

LINUXLIBS := \
	libQt5Core.so.5.2.2 \
	libQt5DBus.so.5.2.2 \
	libQt5Gui.so.5.2.2 \
	libQt5Network.so.5.2.2 \
	libQt5OpenGL.so.5.2.2 \
	libQt5Positioning.so.5.2.2 \
	libQt5PrintSupport.so.5.2.2 \
	libQt5Qml.so.5.2.2 \
	libQt5Quick.so.5.2.2 \
	libQt5Sensors.so.5.2.2 \
	libQt5Sql.so.5.2.2 \
	libQt5Svg.so.5.2.2 \
	libQt5WebKit.so.5.2.2 \
	libQt5WebKitWidgets.so.5.2.2 \
	libQt5Widgets.so.5.2.2 \
	libQt5Xml.so.5.2.2

LINUXPLUGINS := \
	bearer/libqconnmanbearer.so \
	bearer/libqgenericbearer.so \
	bearer/libqnmbearer.so \
	imageformats/libqgif.so \
	imageformats/libqico.so \
	imageformats/libqjpeg.so \
	imageformats/libqmng.so \
	imageformats/libqsvg.so \
	imageformats/libqtga.so \
	imageformats/libqtiff.so \
	imageformats/libqwbmp.so \
	platforminputcontexts/libcomposeplatforminputcontextplugin.so \
	platforminputcontexts/libibusplatforminputcontextplugin.so \
	platforms/libqlinuxfb.so \
	platforms/libqxcb.so \
	platformthemes/libqgtk2.so \
	sqldrivers/libqsqlite.so

LINUXQML := $(subst $(LINUXQTPATH)/qml/,,$(wildcard $(addprefix $(LINUXQTPATH)/qml/,$(COMMONQML))))

LINUXALL := $(addprefix lib/,$(LINUXLIBS)) \
	$(LINUXBIN) \
	$(addprefix plugins/,$(LINUXPLUGINS)) \
	$(addprefix qml/,$(LINUXQML)) \
	$(COMMONSRC) \
	qt.conf

linux/%: $(LINUXQTPATH)/%
	mkdir -p $(dir $@)
	[ -d $< ] || cp $< $@

linux/%: $(LINUXQTPATH)/libexec/%
	mkdir -p $(dir $@)
	cp $< $@

linux/%: ../%
	mkdir -p $(dir $@)
	[ -d $< ] || cp $< $@

linux/qt.conf: qt.conf
	mkdir -p $(dir $@)
	[ -d $< ] || cp $< $@

linux/BridgeClock: linux-build/BridgeClock ldddeps $(addprefix linux/,$(LINUXALL))
	mkdir -p $(dir $@)
	cp $< $@

ldddeps: linux-build/BridgeClock
	mkdir -p linux/lib/
	CHROOTLIBS=`echo "ldd linux-build/BridgeClock" | schroot -c stable`; \
	MISSING=`ldd $< | grep "not found" | sed 's/^[\t ]*\([^=]*\) .*$$/\1/'`; \
	for F in $$MISSING; do \
		echo $$CHROOTLIBS | sed "s#^.* \(\/[^ ]*$$F\).*\$$#cp $(LINUXCHROOTPATH)\1 linux/lib/$$F#" | sh; \
	done

.PHONY: linux-build/BridgeClock
linux-build/BridgeClock:
	mkdir -p $(dir $@)
	echo "cd $(dir $@) && $(LINUXQTPATH)/bin/qmake ../../BridgeClock.pro && make -j4" | schroot -c $(LINUXCHROOT) /bin/bash

# Source package generation
source: BridgeClock-src-$(VERSION).tar.gz

BridgeClock-src-$(VERSION).tar.gz: BridgeClock-src-$(VERSION) ../.git/refs/heads/master
	cd $< && git fetch origin && git reset --hard origin/master
	tar --exclude-vcs -cf - BridgeClock-src-$(VERSION) | pigz -c -9 > $@

BridgeClock-src-$(VERSION):
	git clone ../.git BridgeClock-src-$(VERSION)

clean:
	rm -f varsub *.wxs *.wixobj *.wixpdb BridgeClock.msi
	rm -rf win win-build BridgeClock-src-* BridgeClock-linux* linux linux-build
