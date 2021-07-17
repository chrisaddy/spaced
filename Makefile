build:
	nimble c --verbose --showAllMismatches:on --threads:on -d:release src/spaced.nim
	mv src/spaced .

run:
	nim compile --run --threads:on spaced.nim

test:
	nimble test --verbose
