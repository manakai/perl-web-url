all: IDNEnabled.pm

IDNEnabled.pm: mozilla-pref.js generate-idnenabled.pl
	perl generate-idnenabled.pl mozilla-pref.js > $@

mozilla-pref.js:
	wget -O $@ https://raw.githubusercontent.com/mozilla/gecko-dev/master/modules/libpref/init/all.js

clean:

clean-for-update: clean
	rm -f IDNEnabled.pm

always:

## License: Public Domain.
