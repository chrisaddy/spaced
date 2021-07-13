build:
	nim compile --threads:on spaced.nim

release:
	nim compile -d:release --threads:on spaced.nim

run:
	nim compile --run --threads:on spaced.nim

test:
	nimble test
