CC = arm-apple-darwin9-gcc
LD = $(CC)
SYSROOT = /var/mobile/sysroot

CFLAGS = -c -Wall -isysroot $(SYSROOT)
LDFLAGS = -w -isysroot $(SYSROOT)

xwebkitspeech.dylib: tweak.o
	$(LD) $(LDFLAGS) -dynamiclib -F/System/Library/PrivateFrameworks -lobjc -lsubstrate -framework Foundation -framework AppSupport -o $@ $^

xwksserver: server.o XWKSServer.o
	$(LD) $(LDFLAGS) -F/System/Library/PrivateFrameworks -lobjc -lsprec -framework Foundation -framework AppSupport -o $@ $^

XWKS: XWKSSettings.o
	$(LD) $(LDFLAGS) -dynamiclib -F/System/Library/PrivateFrameworks -lobjc -framework Foundation -framework Preferences -o $@ $^

install:
	cp xwebkitspeech.dylib /Library/MobileSubstrate/DynamicLibraries/
	cp XWKS /System/Library/PreferenceBundles/XWKS.bundle/

%.o: %.m
	$(CC) $(CFLAGS) -o $@ $<

