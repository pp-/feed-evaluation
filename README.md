Overlap/linkage analysis of threat feeds
========================================

Prerequisites:
- Recent R environment (tested on 3.2.5).
- Internet connection (for installation of extra packages).
- Compiler toolchain and development libraries (for building R packages,
  distribution-dependent).


Usage:

    ./analyze-overlap.r

The command above should generate two files:
- `output-diagram.pdf`: chord diagram illustrating overlap between data sources
- `output-stats.csv`: table with overlap statistics for the analyzed sources


Default input file:

    anonymized-overlap-data-2015-07--2016-06.csv

Input format:

Tab-separated columns, no headers, no quotes. Columns:
- First: name of the analyzed source.
- Second: name of another source that shares an attribute.
  Can be null (\N) if the attribute is not shared with other sources.
- Third: value of the attribute shared between the sources.

Example:

    vendor12	alexa	8.8.8.8
    vendor12	cuckoo	8.8.4.4
    vendor12	cuckoo	10.0.0.1
    vendor12	cuckoo	10.0.0.2
    vendor12	\N	10.0.0.3
    ...


IP addresses and selected source names in the sample input file have been
anonymized.

For more details, read the source.
