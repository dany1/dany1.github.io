EMACS=emacs
ORG_CONFIG_FILE=publish-config.el
EMACS_OPTS=--eval "(load-file \"$(ORG_CONFIG_FILE)\")"
DEST_HOST='myhost.com:public_html/'
OUTPUT_DIR=~/Documents/github/dany1.github.io/publish_html

all:html upload
html:
	@echo "Generating HTML..."
	@mkdir -p $(OUTPUT_DIR)
	@$(EMACS) $(EMACS_OPTS)
	@echo "HTML generation done"
upload:
	@cd $(OUTPUT_DIR) && scp -r . $(DEST_HOST) && cd ..

clean:
	@rm -rf $(OUTPUT_DIR)
