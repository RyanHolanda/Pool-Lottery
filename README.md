## Pool Lottery

Pool Lottery is an on chain lottery where users enter a lottery pool(buy a ticket), and then at a chosen time a random number using chainlink VRF is generated to determine who is the winner. after the winner is selected, all the funds are sent to the winner.

## Requirements

・ **[Foundry](https://getfoundry.sh/).** _If you are unsure about Foundry being installed, simply run `forge --version`. The output should be something like `forge 0.2.0 (d58ab7f 2024-02-27T00:16:43.649244000Z)`_

・**[Make](https://www.gnu.org/software/make).** _MacOs and Linux
already come with Make by default. If you are unsure about Make being installed, simply run `make --version`. The output should be something like `GNU Make 3.81`_

・ **[lcov](https://github.com/linux-test-project/lcov)**. _If you are on MacOs it can be installed via brew `brew install lcov`. If you are on Linux it can be installed via apt `sudo apt-get install lcov`_.

## Setting up

In the project root folder, simply run:

```
make setup
```

this command will perform some tasks:

1. Configure Githooks to ensure conventions are followed between commits.

## Running tests

In the project root folder, simply run:

```
make test
```

This command will perform several tasks:

1.  Run all tests.
2.  Generate the lcov.info file (code coverage file).
3.  Verify if the current coverage is at least the minimum specified in the min.coverage file.
4.  Open the lcov HTML version if the current code coverage is less than the specified minimum.

## Code coverage

Code coverage is measured by Foundry, using lcov. To generate the coverage report, simply run:

```
make gen-coverage
```

this command will perform the following tasks:

1. Create a folder called `coverage` in the project root folder.
2. Generate the lcov.info file (code coverage file).
3. Generate the lcov HTML version.

to open the lcov HTML version, simply run:

```
make open-coverage
```

this command will open the latest lcov HTML version in your default browser.

## Make commands

- `make setup` - Setup conventions of the project that all members should follow.
- `make test` - Run tests, and open coverage (if tests pass).
- `make test-gas` - Run gas snapshot tests.
- `make gen-coverage` - Generate the coverage folder with the lcov.info file and the lcov HTML version.
- `make open-coverage` - Open the lcov HTML version.
- `make lint` - Lint the project (needs solhint installed).
