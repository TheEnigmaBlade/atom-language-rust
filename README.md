# Rust language support in Atom

[![Build Status](https://travis-ci.org/TheEnigmaBlade/atom-language-rust-redux.svg?branch=master)](https://travis-ci.org/TheEnigmaBlade/atom-language-rust-redux)

Adds syntax highlighting and snippets for [Rust](http://www.rust-lang.org/) files in [Atom](http://atom.io/).

Forked from the existing [atom-language-rust](https://github.com/zargony/atom-language-rust) due to lack of support. A number of improvements and fixes provided by this package were originally submitted as pull requests, which have yet to be accepted.

## Install

Install the package `language-rust-redux` in Atom (Preferences->Packages) or Atom's package manager:

```bash
$ apm install language-rust-redux
```

## Key changes from fork

Previews taken with Firewatch syntax. More improvements to come.

* Format macro syntax highlighting  
  ![](http://i.imgur.com/mUlh8P0.png)
* Markdown syntax highlighting in doc comments  
  ![](http://i.imgur.com/JDSoPSQ.png)
* Invalid syntax common in similar languages  
  ![](http://i.imgur.com/KsS24Di.png)
* Common mistake recognition  
  ![](http://i.imgur.com/kPhbuE7.png)
* Improved keyword context (`where` actually works)
* Numerous fixes, including lifetimes in associated type definitions and `fn` in function arguments

## Bugs and suggestions

Because this is a fork, there may be bugs I haven't noticed from the original version. Please submit an issue or pull request to get them fixed.

If you have any suggestions for improvement, please submit an issue with a full description and example code for when your suggestion should apply.
