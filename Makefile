setup:
	@git config core.hooksPath lib/githooks

############# Testing #############
test: tests

tests:
	@bash script/shell-script/test.sh

test-gas:
	@forge test --mp "test/gas-snapshot/*.gas.t.sol"

update-gas:
	@rm -rf .forge-snapshots && forge test --mp "test/gas-snapshot/*.gas.t.sol"

############# Covering #############
open-coverage:
	@open coverage/html/index.html

gen-coverage:
	@forge coverage --ast --report lcov --report-file coverage/lcov.info --silent \
	&& genhtml coverage/lcov.info -o coverage/html/ --quiet


############# Linting #############
lint:	
	@solhint src/**/*.sol


############# Deploying #############
deploy-lp:
	@forge script script/DeployLinkPool.s.sol --broadcast --rpc-url ${RPC_URL} --verify --account ${DEPLOY_ACCOUNT} --etherscan-api-key ${ETHERSCAN_API_KEY}

deploy-plm:
	@forge script script/DeployPoolLotteryManager.s.sol --broadcast --rpc-url ${RPC_URL} --verify --account ${DEPLOY_ACCOUNT} --etherscan-api-key ${ETHERSCAN_API_KEY}

deploy-pl:
	@forge script script/DeployPoolLottery.s.sol --broadcast --rpc-url ${RPC_URL} --verify --account ${DEPLOY_ACCOUNT} --etherscan-api-key ${ETHERSCAN_API_KEY}