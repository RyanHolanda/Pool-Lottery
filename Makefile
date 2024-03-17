open-coverage:
	open coverage/html/index.html

gen-coverage:
	forge coverage --report lcov --report-file coverage/lcov.info --silent \
	&& genhtml coverage/lcov.info -o coverage/html/ --quiet

setup:
	@git config core.hooksPath lib/githooks

tests:
	@bash script/shell-script/test.sh