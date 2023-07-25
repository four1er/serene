---
title: Resources
---
# Development Resource

## LLVM
- [Brief Overview of LLVM](https://www.infoworld.com/article/3247799/what-is-llvm-the-power-behind-swift-rust-clang-and-more.html)
- [A bit in depth details on LLVM](https://aosabook.org/en/llvm.html)
- [Official LLVM tutorial C++](https://llvm.org/docs/tutorial/)
- [Interactive C++ with Cling](https://blog.llvm.org/posts/2020-11-30-interactive-cpp-with-cling/)
- [My First LLVM Compiler](https://www.wilfred.me.uk/blog/2015/02/21/my-first-llvm-compiler/)
- [A Complete Guide to LLVM for Programming Language Creators](https://mukulrathi.co.uk/create-your-own-programming-language/llvm-ir-cpp-api-tutorial/)
- [LLVM Internals](https://blog.yossarian.net/2021/07/19/LLVM-internals-part-1-bitcode-format)
- [How to learn about compilers (LLVM Version)](https://lowlevelbits.org/how-to-learn-compilers-llvm-edition/)

### TableGen
- [Create a backend](https://llvm.org/docs/TableGen/BackGuide.html#creating-a-new-backend)

## Data Structures
- [Pure functional datastructures papaer](https://www.cs.cmu.edu/~rwh/theses/okasaki.pdf)
- [Dynamic typing: syntax and proof theory](https://reader.elsevier.com/reader/sd/pii/0167642394000042?token=CEFF5C5D1B03FD680762FC4889A14C0CA2BB28FE390EC51099984536E12AC358F3D28A5C25C274296ACBBC32E5AE23CD)
- [Representing Type Information in Dynamically Typed Languages](https://citeseer.ist.psu.edu/viewdoc/summary?doi=10.1.1.39.4394)
- [An empirical study on the impact of static typing on software maintainability](https://www.researchgate.net/publication/259634489_An_empirical_study_on_the_impact_of_static_typing_on_software_maintainability)

## Other languages
- [Julia: A Fresh Approach toNumerical Computing](https://julialang.org/research/julia-fresh-approach-BEKS.pdf)



## Memory management
- [Visualizing memory management in Golang](https://deepu.tech/memory-management-in-golang/)
- [TCMalloc : Thread-Caching Malloc](http://goog-perftools.sourceforge.net/doc/tcmalloc.html)
- [A visual guide to Go Memory Allocator from scratch (Golang)](https://medium.com/@ankur_anand/a-visual-guide-to-golang-memory-allocator-from-ground-up-e132258453ed)

## Concurrency
- [Scheduling In Go (Series)](https://www.ardanlabs.com/blog/2018/08/scheduling-in-go-part1.html)

## Garbage collection
- [GC on V8](https://v8.dev/blog/high-performance-cpp-gc)
- [Perceus: Garbage Free Reference Counting with Reuse](https://www.microsoft.com/en-us/research/uploads/prod/2020/11/perceus-tr-v1.pdf)
- [Boehm GC](https://www.hboehm.info/gc/)
- [MPS](https://www.ravenbrook.com/project/mps/)
- [MMTK](https://www.mmtk.io/code)
- [Whiro](https://github.com/JWesleySM/Whiro)<br/>
  This is not GC but a tool to debug GC and memory allocation.

## JIT
- [Machine code generator for C++](https://asmjit.com/)
- [LLVM's Next Generation of JIT API](https://www.youtube.com/watch?v=hILdR8XRvdQ)

## Optimizations
- [Canonicalization](https://sunfishcode.github.io/blog/2018/10/22/Canonicalization.html)

## Compiler
- [Stack frame layout on x86-64](https://eli.thegreenplace.net/2011/09/06/stack-frame-layout-on-x86-64)
- [Pointers Are Complicated](https://www.ralfj.de/blog/2020/12/14/provenance.html)
- [Pointers Are Complicated III, or: Pointer-integer casts exposed](https://www.ralfj.de/blog/2022/04/11/provenance-exposed.html)
- [A compiler writting journal](https://github.com/DoctorWkt/acwj)

## Linker
- [20 part linker essay](https://lwn.net/Articles/276782/)
- [LLD Usage](https://lld.llvm.org/index.html)

## Toolchain
- [Building LLVM Distribution](https://llvm.org/docs/BuildingADistribution.html)

## Cross compilation

- [Creating portable Linux binaries](https://blog.gibson.sh/2017/11/26/creating-portable-linux-binaries/#some-general-suggestions)<br/>
  A nice to read article on some of the common problems when linking statically
  with none default libc or libc++

## Lang
- Scheme
  * [Chicken Scheme - Easy-to-use compiler and interpreter, with lots of libraries](https://call-cc.org)
  * [Stalin - Brutally optimizing Scheme compiler, with lots of optimization flags](https://github.com/barak/stalin)
* [Crafting Interpreters](https://craftinginterpreters.com/contents.html)

## Emacs mode
- [Adding A New Language to Emacs](https://www.wilfred.me.uk/blog/2015/03/19/adding-a-new-language-to-emacs/)
- [The Definitive Guide To Syntax Highlighting](https://www.wilfred.me.uk/blog/2014/09/27/the-definitive-guide-to-syntax-highlighting/)


## Mathematics
- [CS410 course: Advance Functional Programming](https://github.com/pigworker/CS410-18)<br/>
  If you need to learn Agda (We use it for the mathematics side of Serene, to proof certain features)
  check out

- [Programming Language Foundations in Agda](https://plfa.github.io/)<br/>
  This book is an introduction to programming language theory using the proof assistant Agda.

### Curry-Howard correspondence
- [The formulae-as-types notion of construction](https://www.dcc.fc.up.pt/~acm/howard2.pdf)
- [Propositions as Types](https://www.youtube.com/watch?v=IOiZatlZtGU)

### Type Theory
- [Homotopy Type Theory](https://www.cs.cmu.edu/~rwh/courses/hott/)
- [No, dynamic type systems are not inherently more open](https://lexi-lambda.github.io/blog/2020/01/19/no-dynamic-type-systems-are-not-inherently-more-open/)

- Practical Foundations of Programming Languages
    + [Online copy (2nd Edition Preview)](http://www.cs.cmu.edu/~rwh/pfpl/2nded.pdf)
    + [Dead-tree copy (2nd Edition)](https://www.amazon.com/Practical-Foundations-Programming-Languages-Robert/dp/1107150302)


- Types and Programming Languages
    + [Online supplements](http://www.cis.upenn.edu/~bcpierce/tapl/)
    + [Dead-tree copy](https://mitpress.mit.edu/books/types-and-programming-languages)

- Advanced Topics in Types and Programming Languages
    + [Online supplements](http://www.cis.upenn.edu/~bcpierce/attapl/)
    + [Dead-tree copy](http://www.amazon.com/exec/obidos/ASIN/0262162288/benjamcpierce)


- The Works of Per Martin-Löf:
    + [1972](https://github.com/michaelt/martin-lof/blob/master/pdfs/An-Intuitionistic-Theory-of-Types-1972.pdf?raw=true)
    + [1979](https://github.com/michaelt/martin-lof/blob/master/pdfs/Constructive-mathematics-and-computer-programming-1982.pdf?raw=true)
    + [1984](https://github.com/michaelt/martin-lof/blob/master/pdfs/Bibliopolis-Book-retypeset-1984.pdf?raw=true)
    + [The Complete Works of Per Martin-Löf](https://github.com/michaelt/martin-lof)


- [Programming In Martin-Löf's Type Theory](http://www.cse.chalmers.se/research/group/logic/book/book.pdf)

- The Works of John Reynolds
    * [Types, Abstraction and Parametric Polymorphism](http://www.cse.chalmers.se/edu/year/2010/course/DAT140_Types/Reynolds_typesabpara.pdf) (Parametricity for
     System F)
    * [A Logic For Shared Mutable State](http://www.cs.cmu.edu/~jcr/seplogic.pdf)
    * [Course notes on separation logic](http://www.cs.cmu.edu/afs/cs.cmu.edu/project/fox-19/member/jcr/www15818As2011/cs818A3-11.html)
    * [Course notes on denotational semantics](http://www.cs.cmu.edu/~jcr/cs819-00.html)

- [The HoTT book](http://homotopytypetheory.org/book/)
- [Student's Notes on HoTT](https://github.com/RobertHarper/hott-notes)
- [Materials for the Schools and Workshops on UniMath](https://github.com/UniMath/Schools)

### Proof Theory

- Frank Pfenning's Lecture Notes
     * [Introductory Course](http://www.cs.cmu.edu/~fp/courses/15317-f09/)
     * [Linear Logic](http://www.cs.cmu.edu/~fp/courses/15816-s12/)
     * [Modal Logic](http://www.cs.cmu.edu/~fp/courses/15816-s10/)

- [Proofs and Types](http://www.paultaylor.eu/stable/prot.pdf)
- [The Blind Spot: Lectures on Logic](http://www.ems-ph.org/books/book.php?proj_nr=136&srch=browse_authors%7CGirard%2C+Jean-Yves)
- [Mustard Watches: An Integrated Approach to Time and Food](http://girard.perso.math.cnrs.fr/mustard/page1.html)

### Category Theory

- Category Theory in Context
     * [Online version](http://www.math.jhu.edu/~eriehl/context.pdf)
     * [Dead-tree version](http://store.doverpublications.com/048680903x.html)
     * [The author's post on the book](https://golem.ph.utexas.edu/category/2016/11/category_theory_in_context.html)

- Practical Foundations of Mathematics
     * [HTML version](http://www.paultaylor.eu/~pt/prafm/)
     * [Dead-tree version](https://www.amazon.com/gp/product/0521631076)

- [Category Theory](http://www.amazon.com/Category-Theory-Oxford-Logic-Guides/dp/0199237182/ref=sr_1_1?ie=UTF8&qid=1439348930&sr=8-1&keywords=awodey+category+theory)

- [Ed Morehouse's Category Theory Lecture Notes](https://emorehouse.wescreates.wesleyan.edu/research/notes/intro_categorical_semantics.pdf)

- Categorical Logic and Type Theory
     * [Jacob's thesis, containing much of what went into the book](http://www.cs.ru.nl/B.Jacobs/PAPERS/PhD.ps)
     * [A definitely not suspicious online copy](https://people.mpi-sws.org/~dreyer/courses/catlogic/jacobs.pdf)
     * [Dead-tree copy](https://www.amazon.com/exec/obidos/ASIN/0444501703/qid%3D922441598/002-9790597-0750031)

- [Introduction to Higher-Order Categorical Logic](https://www.amazon.com/Introduction-Higher-Order-Categorical-Cambridge-Mathematics/dp/0521356539/ref=pd_sim_14_5?_encoding=UTF8&psc=1&refRID=V4H286NSZWK4MWDPV17R)

- [Sheaves in Geometry and Logic](https://www.amazon.com/Sheaves-Geometry-Logic-Introduction-Universitext/dp/0387977104)


### Others

- [Gunter's "Semantics of Programming Language"](http://www.amazon.com/Semantics-Programming-Languages-Structures-Foundations/dp/0262071436/ref=sr_1_1?ie=UTF8&qid=1439349219&sr=8-1&keywords=gunter+semantics+of+programming+languages)

- [Abramsky and Jung's "Domain Theory"](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.50.8851)

- [Realizability: An Introduction to Its Categorical Side](https://www.amazon.com/Realizability-Introduction-its-Categorical-Side/dp/0444550208)


- OPLSS:<br/>
  The Oregon Programming Languages Summer School is a 2 week long
  bootcamp on PLs held annually at the university of Oregon. It's a
  wonderful event to attend but if you can't make it they record all
  their lectures anyways! They're taught be a variety of lecturers
  but they're all world class researchers.

     * [2012](https://www.cs.uoregon.edu/research/summerschool/summer12/curriculum.html)
     * [2013](https://www.cs.uoregon.edu/research/summerschool/summer13/curriculum.html)
     * [2014](https://www.cs.uoregon.edu/research/summerschool/summer14/curriculum.html)
     * [2015](https://www.cs.uoregon.edu/research/summerschool/summer15/curriculum.html)
     * [2016](https://www.cs.uoregon.edu/research/summerschool/summer16/curriculum.php)
     * [2017](https://www.cs.uoregon.edu/research/summerschool/summer17/topics.php)
     * [2018](https://www.cs.uoregon.edu/research/summerschool/summer18/topics.php)
