ROKU_ADDR=192.168.0.55
ROKU_USER=rokudev
ROKU_PASS=rokudev
PORT_CONS=8085
PORT_DEBG=8080
ZIP_FILE=suplex.zip
CONTENTS=source image components manifest

all: install

install: zip
	@curl --anyauth -u $(ROKU_USER):$(ROKU_PASS) -s -S -F "mysubmit=Install" -F "archive=@$(ZIP_FILE)" -F "passwd=" http://$(ROKU_ADDR)/plugin_install \
		| grep "<font color"             \
		| sed "s/<font color=\"[^\"]*\">//" \
		| sed "s/<\/font>//"

zip:
	@rm -f $(ZIP_FILE)
	@zip -9 -r $(ZIP_FILE) $(CONTENTS)

console:
	telnet $(ROKU_ADDR) $(PORT_CONS)

debug:
	telnet $(ROKU_ADDR) $(PORT_DEBG)
