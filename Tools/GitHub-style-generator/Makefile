NODE_SASS = node_modules/.bin/node-sass

target = ../../MacDown/Resources/Styles/GitHub-2020.css

all: $(target)

$(target): index.sass package-lock.json
	@set -e; \
	tmp_sass="$@.sass.tmp"; tmp_out="$@.tmp"; \
	rm -f "$$tmp_sass" "$$tmp_out"; \
	if [ ! -x "$(NODE_SASS)" ]; then \
		echo "warning: $(NODE_SASS) not found; skipping GitHub-2020.css generation (run: npm install)"; \
		exit 0; \
	fi; \
	$(NODE_SASS) --include-path node_modules $< > "$$tmp_sass"; \
	sed 's/\.markdown-body/body/g' "$$tmp_sass" > "$$tmp_out"; \
	mv "$$tmp_out" "$@"; \
	rm -f "$$tmp_sass"

clean:
	$(RM) $(target)

.PHONY: all clean
