function test() {
forge test --ast -vvv \
	&& rm -rf coverage \
	&& mkdir coverage \
	&& make gen-coverage
}

if ! test; then
	exit 1
fi


if ! lcov --summary coverage/lcov.info --fail-under-lines `cat min.coverage` --quiet; then
	echo -e "\033[0;31mCurrent tests coverage is less than 100%. Please consider increasing it\033[0m"
	make open-coverage
	exit 1
fi