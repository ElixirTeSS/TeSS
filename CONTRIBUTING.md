# Contributing to TeSS

While TeSS was originally developed to serve as the training portal for [ELIXIR](https://www.elixir-europe.org/), it endeavours to be a generic training platform that can be easily customized and re-used in other communities. 
To that end we welcome and encourage new contributors to get involved and help to shape and improve TeSS. This document discusses and explains different ways you can contribute to TeSS.

### TeSS Club

If you are interested in TeSS or contributing to it, you may want to join the [TeSS Club](https://elixirtess.github.io/about/) - an open biweekly meeting to discuss TeSS and steer the direction of TeSS' development.

## Before You Begin

If you plan on making a change to TeSS' code or documentation, it's a good idea to open an issue, or comment on an existing issue to explain and discuss why. This makes the TeSS contributors and members of the community aware of what activities are taking place, and gives them a chance to offer insight and advice.

Any major changes should be first discussed at the [TeSS Club](https://elixirtess.github.io/about/) before being worked on.

### Contributor Agreement

By contributing, you agree that we may redistribute your work under [our BSD 3-Clause licence](LICENSE). In exchange, we will address your issues or assess your change proposals as promptly as we can, and help you become a member of our community.

### Code of Conduct

When contributing to TeSS you are expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md). Basically, this means that we are dedicated to providing a safe, inclusive and harassment-free environment for all.

### Credit

We maintain a [list of contributors to the TeSS codebase](CONTRIBUTORS.md). If you would like to be recognized on this list, please append your name and email address to the end of the `CONTRIBUTORS.md` file when submitting a pull request.

## How to Contribute

If you decide to contribute to TeSS you will need to have registered, and been signed in to, a GitHub account - as all contributions are managed by GitHub. You do not have to be a software developer, however, to make helpful and meaningful contributions. You can contribute to TeSS in various ways, including:

- [Bug reports and feature suggestions](#Bug-Reports-and-Feature-Suggestions)
- [Commenting, voting and participating in discussions](#Commenting-and-Voting) on existing issues or proposed code changes and pull requests
- [Contributing to TeSS code](#Contributions-to-Code)
- [Contributing to TeSS documentation](#Contributions-to-Documentation)


# Bug Reports and Feature Suggestions

If you notice a problem or a bug in TeSS, have an idea on something, or would like to see a new feature or some functionality in TeSS, please submit a bug report or make a feature suggestion by creating a new issue on [TeSS issues page](https://github.com/ElixirTeSS/TeSS/issues).

Before opening a new issue, check the list of opened issues first to see if there is already an existing report on the same subject. If so, consider [adding your thoughts]((#Commenting-and-Voting)) to the existing issue instead of starting a new one.


# Commenting and Voting

We welcome people to comment and vote on any issues, discussions or pull requests that they feel are important - this is an opportunity to explain your point of view and discuss why certain changes are needed.

Voting is done by leaving a reaction (👍 for +1, 👎 for -1) on an issue or pull request. Community votes on issues are used to help gauge opinion when prioritizing work, and votes on pull requests are taken into account by the core TeSS development team when deciding whether to accept it.


# Contributions to Code

Contributions to TeSS code are done on a separate fork that you can create in your GitHub account from the [TeSS repository landing page](https://github.com/ElixirTeSS/TeSS/). Within your fork, you should create a separate feature branch to contain your changes. After you are done, you then create a pull request to bring your proposed changes back from your feature branch into the main TeSS codebase. A summary of instructions to do so are given below.

## Fork TeSS

Create a fork of [TeSS on Github](https://github.com/ElixirTeSS/TeSS) check out your copy, and create an `upstream` remote to make it easier to pull in changes from the main TeSS code.

```
git clone https://github.com/<your account>/TeSS.git
cd TeSS
git remote add upstream https://github.com/ElixirTeSS/TeSS.git
```

Further information on how to create and work with a forked repository can be found [here](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/getting-started/about-collaborative-development-models).

## Create a Feature Branch

Decide which branch to base your feature branch off. This will probably be `master` unless you are contributing a bug fix to a release of TeSS, in which case use, e.g. branch `tess-1.2`.

Make sure your fork is up-to-date with upstream TeSS.

```
git checkout master
git pull upstream master
git checkout -b my-feature-branch
```

## Set Up TeSS

In order to run and test your code, you will need to be able to run TeSS locally. 
Follow our [native installation](https://github.com/ElixirTeSS/TeSS/blob/master/docs/install.md) or
[docker](https://github.com/ElixirTeSS/TeSS/blob/master/docs/docker.md) guides to set up your local instance of TeSS.

## Write Code

### Code Style

TeSS tries to follow the [Ruby Style Guide](https://github.com/rubocop/ruby-style-guide). We also make use of [rubocop](https://github.com/rubocop/rubocop), a Ruby static code analyzer and formatter that automatically checks and can enforce conformance to the [Ruby Style Guide](https://github.com/rubocop/ruby-style-guide).

Your IDE may have rubocop integration. If if does not, you can run it manually from command line as:

```
rubocop lib/my_code_that_i_wrote.rb
```

or to automatically apply fixes:

```
rubocop -a lib/my_code_that_i_wrote.rb
```

### Testing

Ensure your code is completely covered by test cases. Read through some existing tests to get an idea of how your code could be tested.

TeSS has an extensive test suite and aims to have as close to 100% test coverage as possible. Run the existing TeSS test suite to check your change has not broken any existing code:

```
bundle exec rails test
```

or if using docker:
```
docker-compose run test
```

You can also see the test coverage % after the tests finish - make sure it has not decreased from before adding your code.

### Commit Meaningfully

Make sure your commits contain meaningful and related changes, and a commit message describing the change.

If you fix something unrelated to the rest of your changes, e.g. you found a typo somewhere, try and do it in a separate commit.

If your commit is related to an issue, tag the issue using in the commit message - e.g. use `#123` to tag the issue number 123.

You can always [rebase](https://docs.github.com/en/get-started/using-git/about-git-rebase) any rough commits later on to make them easier to follow.

### Open a Pull Request

Make sure that your feature branch is pushed to your fork of TeSS on GitHub and from it select your feature branch. Click the 'Pull Request' button and fill out the form. In the comment, make sure to include:
- A brief summary of what changes were made.
- Why the changes were made, with links to any relevant issues or discussions.
- If appropriate, screenshots of the changes, or instructions on how the changes can be tried out.

Also be sure to select the branch of TeSS where you want the changes to be merged back into, and if your contribution is a work-in-progress, flag the pull request as being a "Draft" (Click the arrow next to the "Create Pull Request" button).

Your pull request should trigger a build that can be monitored on our [actions](https://github.com/ElixirTeSS/TeSS/actions) page. The core TeSS development team will also be notified, and a member of the team will review your Pull Request in a timely manner.

Check in from time to time, or wait for notifications of any reviewer comments or build failures.

If you need to make additional code changes (in response to review comments, for example), just push them to your original branch on your fork and GitHub will update the open pull request automatically.


# Contributions to Documentation

TeSS has various levels of documentation that can also be contributed to:

* [Technical documentation](https://github.com/ElixirTeSS/TeSS/tree/master/docs) - mostly related to how to install and configure TeSS (Markdown)
* [API documentation](https://github.com/ElixirTeSS/TeSS/tree/master/public/api/definitions) - specifications on how TeSS APIs function, with some descriptions and guidance (Swagger 2.0 YAML)
* User documentation - *Help wanted!* - Guidance for users of TeSS on best practices, how they can automatically register resources, etc. (Markdown?)

Small changes can be made directly in GitHub. Simply open the relevant file, click the pencil icon to edit, make your change, and click the "Proprose changes" button - GitHub will automatically create a fork, a feature branch and a pull request for you.


# Thank You

Thank you for considering contributing to TeSS.
