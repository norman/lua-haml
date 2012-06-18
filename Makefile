.PHONY: spec test

test:
	@tsc spec/haml-spec/lua_haml_spec.lua spec/*_spec.lua

spec:
	@tsc -f spec/haml-spec/lua_haml_spec.lua spec/*_spec.lua

