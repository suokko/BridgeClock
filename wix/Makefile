all: BridgeClock.msi

BridgeClock.msi: files.wixobj BridgeClock.wixobj
	WINEDEBUG=fixme-all ../../dBC/wix/light.exe -b ../../dBC/BridgeClock-windows/ -sval BridgeClock.wixobj files.wixobj -o BridgeClock.msi
	chmod 0644 BridgeClock.msi

%.wixobj: %.wxs
	WINEDEBUG=fixme-all ../../dBC/wix/candle.exe $<

BridgeClock.wxs: BridgeClock.wxs.in vars.sh varsub
	(sh < vars.sh; cat BridgeClock.wxs.in;) | ./varsub > BridgeClock.wxs

DEST= \
      $(wildcard ../../dBC/BridgeClock-windows/*) \
      $(wildcard ../../dBC/BridgeClock-windows/*/*) \
      $(wildcard ../../dBC/BridgeClock-windows/*/*/*)

files.wxs: ../../dBC/BridgeClock-windows $(DEST)
	WINEDEBUG=fixme-all ../../dBC/wix/heat.exe dir $< -gg -sfrag -srd -cg bcall -dr INSTALLDIR -o $@


varsub: varsub.cpp
	${CXX} -O2 -g $^ -o $@

clean:
	rm -f varsub *.wxs *.wixobj *.wixpdb BridgeClock.msi
