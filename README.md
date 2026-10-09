# Fanbase

Welcome to Fanbase! Fanbase is a collection of [Fandango](https://fandango-fuzzer.github.io/) input specifications (grammars) with which you can produce thousands of random test input files in dozens of image, video, audio, and other formats.

## Available Formats

Browse the `specs/` folder, above, to see the formats already in Fanbase. Every week, we will add a handful of new formats, aiming for a total of 100+ file formats by the end of 2026.

## Installation

Fanbase comes with Fandango. You need [Fandango](https://fandango-fuzzer.github.io/) 1.3 or later:

```shell
$ pip install --upgrade fandango-fuzzer
```

This also installs the `fanbase` command. To use it without Fandango, `pip install fanbase`.


## Usage

To produce test inputs for a format, give its name to `fandango` with `-F`:

```shell
$ fandango fuzz -F png -n 10
```

Fandango fetches the default PNG spec from Fanbase, installs it where Fandango looks for specs, and writes 10 PNG files to the directory `png-inputs`. Whenever Fanbase has a newer version of the spec, it is updated.

A format can have more than one spec. The default is named after the format; the others are named `<format>-<what makes it different>`, such as `png-apng` for animated PNGs:

```shell
$ fandango fuzz -F png-apng -n 10 -d apngs
```

Use `fanbase list` to see the available formats, and `fanbase list png` to see the specs of a format. All other options of `fandango fuzz` work as usual. `fanbase install png` installs a spec without using it. `fanbase install --all` installs all available formats at once.

Check the full CLI and all commands [here](https://github.com/fandango-fuzzer/fanbase-cli) 

### Customizing Fanbase files

To customize a Fanbase file, create a local spec file (say, `mypng.fan`) that _redefines_ individual definitions from the Fanbase file.

For instance, the default PNG spec chooses between five kinds of images:

```python
<image> ::= <png_grayscale> | <png_grayscale_alpha> | <png_truecolor> | <png_truecolor_alpha> | <png_indexed>
```

You can _override_ this definition by redefining it in your own `.fan` file that first _includes_ the Fanbase file.

To produce only RGB images, create a file `mypng.fan` as

```python
# mypng.fan
include("png/png.fan")  # include from local Fanbase installation
<image> ::= <png_truecolor>
```

and then use

```shell
$ fandango fuzz -f mypng.fan -n 10 -d mypngs -x .png
```

to create PNG files with RGB images only. (`-d` sets an output directory, `-x` sets the file extension.)

This needs the PNG spec to be installed already, which `fanbase install png`, or any earlier use of `-F png`, takes care of.

Mechanisms to include a particular version are in the making.



## Questions and Answers


### Should I use your tool to create test inputs?

Yes.

* If you maintain a _library_ that processes files in one of the Fanbase formats (say, a PNG library), we _strongly recommend_ that you test it against Fandango-generated input files. We have found several bugs and vulnerabilities in so-far well-tested libraries.
* If you maintain a _system_ that uses a third-party library as above to process input files, stay tuned for patches and updates of the library.
* If Fandango finds no bugs today, this is not a guarantee for the future. Consider having your continuous testing chain include Fandango and Fanbase to create (and re-create) input files for testing and re-testing.
* Update Fandango and Fanbase on a regular basis to benefit from the latest algorithms and specifications.


### Can I test infrastructures other than my own?

Technically yes, but you should not, as you would likely break the law and face intrusion claims. When testing third-party systems, always be sure to maintain professional conduct and have proper authorization. For best practices, read this article on [ethical hacking](https://www.sprocketsecurity.com/blog/ethical-hacking).


### How many test inputs do I need?

This very much depends on the variety of input and code features. In our experiments, 1,000 to 2,000 inputs yielded sufficient coverage of the input space; but 10 to 20 inputs can already find first bugs.


### Are these specs effective for fuzzing?

Yes. Common fuzzing tools mutate existing "seed" inputs, which works pretty well in practice. Our specifications, however, often cover features not found in any seed inputs, and thus can cover code and find bugs that other tools cannot. Also, specification-based fuzzing does not require (coverage) feedback from the program under test, which opens up several new systems and domains for testing.


### Have you found any bugs?

Yes. Our specifications have found (and keep on finding) dozens of bugs and vulnerabilities in several existing systems and libraries, including some of the best-tested on the planet. Following the principle of responsible disclosure, we have reported all bugs to the developers; details will be disclosed in accordance with our disclosure policy.


### I found a bug using Fanbase and/or Fandango! What should I do?

First and foremost, contact the maintainers of the respective system. If you found Fandango and/or Fanbase helpful, we'd appreciate if you could let us know; see ["Contact us"](#contact-us) below.


### What are the ethics behind releasing such tools and specs?

This question has kept us pretty busy! See our [Ethical Considerations](ETHICS.md) for details.


### How do you create these specs?

We have been writing specifications since February 2026, using a variety of techniques:

* We typically start with _custom automated converters_ that create specifications. Sources include:
  - existing _formal format specifications_ such as [010 binary templates](https://www.sweetscape.com/010editor/repository/templates/), [ANTLR grammars](https://github.com/antlr/grammars-v4), or XML and JSON schemas;
  - existing _parser code_, which we analyze statically using [symbolic parsing](https://dl.acm.org/doi/10.1145/3776743); and
  - existing _natural language documentation_, using [AI agents to formalize it](https://ieeexplore.ieee.org/abstract/document/11600525).
* Once we have a draft spec, we use custom _agentic workflows_ as well as manual work to refine it. This includes extending _parser specs_ into _producer specs_ and continuously validating their outputs against existing input parsers. This step also adds some "AI flavor" to the specs.
* Finally, we consolidate structure and documentation to make the specs human-readable. This again is mostly human work (and work in progress).

As our tool chain evolves and agentic capabilities improve, we hope to release a fully automated tool chain in 2027.


### How complete are these specs?

The specs sure are "good enough" to be mostly valid and find bugs and vulnerabilities. However,

* they are optimized for _producing_ inputs rather than _parsing_ them;
* we do not claim they cover every single aspect of the format;
* we often do not know all data field details, and then fill in (working) constants from sample files; and
* our sources and tool chains may be incomplete.

Consequently, the Fanbase specs thus cannot serve (yet) as the authoritative formal specification for a format.

We sure would like to improve! If you are a format or domain expert, let us know which features are missing; we also [happily accept fixes and pull requests](#contact-us).


### How well-structured are these specs?

In this project, our first priority was to get _valid_ specifications that do well in finding bugs. As you will see studying them, their structure and documentation can still be much improved; this is work in progress. It is also an interesting research question: What makes a well-structured input spec?


### How can I contribute?

We [happily accept pull requests](#contact-us) for any of the Fanbase files! If you want to write and share a spec for a new file format, [coordinate with us](#contact-us) beforehand, as we may already have this format in our queue.

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to write, check and submit a spec.


### How do I cite Fanbase?

The registry is archived on Zenodo. The DOI [10.5281/zenodo.23261474](https://doi.org/10.5281/zenodo.23261474) stands for Fanbase as a whole and always leads to the latest release; each release has a DOI of its own, on that page. `fanbase cite SPEC` says how to cite one spec.

```bibtex
@misc{fanbase,
  author = {{The Fandango Fuzzer Team}},
  title  = {Fanbase: a registry of Fandango input specifications},
  doi    = {10.5281/zenodo.23261474},
  url    = {https://doi.org/10.5281/zenodo.23261474}
}
```

The command that installs from the registry, [fanbase-cli](https://github.com/fandango-fuzzer/fanbase-cli), is archived separately: [10.5281/zenodo.23259520](https://doi.org/10.5281/zenodo.23259520).

### Who are you?

Fanbase is brought to you by Norman Becker, Valentin Huber, Florian Bauckholt, Addison Crump, Rafael Dutra, Keno Hassler, Alexander Liggesmeyer, Kuangxiangzi Liu, Tim Scheckenbach, José Antonio Zamudio Amaya, and Andreas Zeller, researchers at [CISPA Helmholtz Center for Information Security](https://www.cispa.de/), Germany; [Federal University of Ceará](https://www.ufc.br/), Brazil; and [Volkswagen AG](https://www.volkswagen-group.com/en), Germany.


### Contact us

For issues and suggestions, the easiest way is to [report an issue](https://github.com/fandango-fuzzer/fanbase/issues/new/choose). For all other matters, contact [Andreas Zeller](https://andreas-zeller.info), leading faculty at CISPA.
