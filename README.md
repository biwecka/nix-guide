# Learning Nix & NixOS
In this repository I'm writing down my approach to learn the *nix* language
as well as how to use *NixOS*.

---
# Content
1.  [Basics](#basics)
2.  [Data Types](#data-types)
    1.  [Primitive Data Types](#primitive-data-types)
        1.  [Numbers](#numbers)
        2.  [Strings](#strings)
        3.  [Booleans](#booleans)
        4.  [Null](#null)
        5.  [Paths](#paths)
    2.  [Collection Types](#collection-types)
        1.  [Lists](#lists)
        2.  [Sets](#sets)
    3.  [Functions](#functions)
3.  [Language Constructs](#language-constructs)
    1.  [`let... in...` Expressions and Scoping](#let--in--expressions-and-scoping)
    2.  [`if... then... else...` Conditions](#if-then-else-conditions)
    3.  [`with` Keyword](#with-keyword)
    4.  [`inherit` Keyword](#inherit-keyword)
4.  [Immutability](#immutability)
5.  [Code Organization and Imports](#code-organization-and-imports)
6.  [`builtins`](#builtins)
7.  [`pkgs.lib`](#pkgslib)
8.  [Derivations](#derivations)
9.  [Overrides and Overlays](#overrides-and-overlays)
10. [Flakes](#flakes)
11. [NixOS](#nixos)
    1.  [NixOS Modules](#nixos-modules)


---

# Basics
Nix is a purely functional, lazily evaluated, dynamically typed programming
language.

The Nix language consists of expressions that evaluate to values.
```nix
2 + 2           # evaluates to 4
"foo" + "bar"   # evaluates to "foobar"
[1 "hi" true]   # list with three items of different type
```

To easily test this out yourself, and for trying out the examples in the
following chapters Nix provides a *REPL* (Read-eval-print loop).
You can use the *REPL* like follows:
1.  Start the *REPL* with `nix repl`
2.  Enter `2 + 2` (or any other expression)
3.  Press `Enter`/`Return` and observe the evaluation/result.

Additionally, the following commands are very helpful for working with the
*REPL*:
-   `:?`    : Prints the available commands
-   `:q`    : Quits the *REPL*
-   `:l`    : Load a Nix expression from a file (later covered in this guide)
-   `:lf`   : Load flake
-   `:r`    : Reload all files
-   `:t`    : Describe the result of an evaluation

As these first expressions might have shown, Nix expressions are made up of
*values* and *operators*. The following chapter introduces the data types
Nix values can have, and which operators can be used with each of those data
types.

# Data Types
All data types you'll get to know in the following chapters, can be compared
with the `==` and `!=` operators.

## Primitive Data Types
### Numbers
Nix supports integer numbers as well as floating point numbers like so:
```nix
42
-7
3.14
-0.1
```

Those numbers can be used with the common mathematical operators `+`, `-`,
`*`, `/`:
```nix
5 + 3           # evaluates to 8
7 - 2.5         # evaluates to 4.5
2 * 3           # evaluates to 6
10 / 4          # evaluates to 4 (integer division)
10 / 4.         # evaluates to 2.5
```

Be aware, that the spaces around the operators are **only needed** for the
division operator `/`. If you leave out the spaces like so `10/4`, Nix won't
interpret this as an arithmetic expression, but as a **Path** (which is another
data type covered later).

### Strings
Strings in Nix use double quotes and can easily concatenated with the `+`
operator:
```nix
"Hello World!"          # evaluates to "Hello World!"
"Hello, " + "Tim" + "!" # evaluates to "Hello, Tim!"
```

Strings also allow for interpolation with the following syntax:
```nix
"Hello ${name}"         # assuming "name" is a string variable
```

There are also "indented strings", which are denoted by double single quotes:
```nix
''
multi
line
string
''
# evaluates to: "multi\nline\nstring\n"
```

### Booleans
Nix obviously also supports booleans. But there's not a lot to say about those:
```nix
true
false
```
Booleans can be combined with `&&` and `||`:
```nix
true && true        # evaluates to: true
true && false       # evaluates to: false
true || false       # evaluates to: true
```

### Null
Nix contains a `null` value, which represents the absence of a value.
```nix
null
```

### Paths
As Nix is primarily used for building and distributing software in a
deterministic way, file paths are primitive data type in Nix.

Depending on where your Nix file is evaluated or where you start your *REPL*,
the evaluated paths differ. For the examples below I started the *REPL* in
the root directory `/`:
```nix
./foo           # evaluates to: /foo
./.             # evaluates to: / (-> this represents the CURRENT PATH)
../.            # denotes the PARENT DIRECTORY
```
The current path is represented by `./.`, because **paths** in Nix
**must** always **contain** at least one `/`.

Paths can be concatenated and manipulated like this:
```nix
./foo + "bar"           # evaluates to: /foobar (adding a string to a path)
./foo + ./bar           # evaluates to: /foo/bar
(x: ./foo${x}bar) "X"   # evaluates to: /fooXbar
(x: ./foo + ./${x}) "x" # evaluates to: /foo/x
```

> **Absolute** paths always start with a `/`.
> **Relative** paths contain at least one `/` but **do not** start with one.
> They evaluate the path relative to the path of the file, which contains the
> expression.

## Collection Types
### Lists
A list in Nix is an **ordered** list of items, which can be of **varying**
types. Here are some examples of lists:
```nix
[1 2 3 4 5]         # list of numbers
[1 "hello" true]    # list of different types
```
List items are **separated** by **whitespaces**.

Items from a list can be accessed by indices (0-based), with a function
from `builtins`:
```nix
builtins.elemAt [1 "hello" true] 0  # evaluates to 1
builtins.elemAt [1 "hello" true] 1  # evaluates to "hello"
```

Furthermore, lists can be concatenated with the `++` operator:
```nix
[1 2] ++ [3] # evaluates to [1 2 3]
```

### Sets
The primary data type you'll encounter when using Nix is the **set**. It's
comparable to dictionaries or maps known from other programming languages.
A **set** contains **key/value**-pairs called **attributes**.
```nix
{}              # the empty set
{ x=5; y=2; }   # a set with two attributes
{ x=5; }.x      # evaluates to x
```
**Attributes** have a **mandatory *trailing semicolon***. As demonstrated
above, the attributes of a set can be accessed with the `.` (dot) syntax.

Nix also provides a merge operator (`//`) which applies the attributes of the
**right** set to the **left** one:
```nix
{ a=1; } // { a=2; b=3; }   # evaluates to: { a=2; b=3; }
{ a=1; } // { b=2; }        # evaluates to: { a=1; b=2; }
```

Be aware, that the merge operatore **does not work** for **deeply nested** sets.
```nix
{ sub_set = { a=1; }; } // { sub_set = { b=2; }; }
# evaluates to: { sub_set = { b=2; }; }
# -> the top-level attributes are applied, which overwrites the nested values!
```

In some cases it may be necessary, to access a set's attributes from within
the same set. This is possible in Nix when using the `rec` keyword:
```nix
rec {
    a = 1;
    b = 2;
    c = a+b;
}
    .c

# evaluates to 3
```


## Functions
Functions are first-class citizen in Nix and **anonymous** by default.
Despite of that, anonymous functions can be assigned to variables, to handle
them like named functions (as we'll later see).

Functions technically only have one parameter. Multiple parameter functions
can be created by using higher-order functions (chaining functions like in
Haskell).
```nix
(x: x + 1) 5        # evaluates to 6
(x: y: x + y) 1     # evaluates to y: 1+y
{ a, b }: a + b     # function with set as parameter (named arguments)
```

For passing large sets as parameter to a function, it's helpful to ignore
all attributes of the parameter set, which are not needed. This is done with
the `...` syntax:
```nix
({ a, b, ... }: a + b)
    { a = 1; b = 2; c = 3; }
# evaluates to: 3
```

Functions with a set as parameter may define **default values/arguments**
for some attributes:
```nix
let
  f = {a, b ? 0}: a + b;
in
    f { a = 1; }
# evaluates to: 1
```

When an attributes set is passed as parameter to a function, it can also be
assigned a name to be accessible as a whole:
```nix
let
    func = {a, b, ...}@args: a + b + args.c;

    # Alternative
    alt  = args@{a, b, ...}: a + b + args.c;
in
    func { a=1; b=2; c=3; }     # evaluates to: 6
    # alt { a=1; b=2; c=3; }    # evaluates to: 6
```

# Language Constructs
## `let... in...` Expressions and Scoping
Let expressions allow you to bind variables within a local scope.
```nix
let
  a = "Hi";
  b = "Max";
in
  "${a} ${b}!"
```
As this expression might be hard to type out in the *REPL*, you can also create
a file (e.g., `playground.nix`) and write out the Nix expression in that file.
When you now open the *REPL* in the same folder as where the file resides in,
you can evaluate the file by using the following command:
```sh
nix-repl> import ./playground.nix
```

Alternatively, Nix files can also be evaluated with the following command
(without the need for a *REPL*):
```sh
nix-instantiate --eval playground.nix
```

Let expressions can also be nested, whereby variables of the inner let binding
shadow outer variables of the same name:
```nix
let
    x = 1;
    y = 2; # <- this variables is not used at all!
    z = let y = 10; in x + y;
in
    z
# evaluates to 11 (NOT 3)
```

## `if... then... else...` Conditions
```nix
let
    # this is a function assigned to a variable
    listLength = lst:
        if lst == [] then 0
        else 1 + listLength (builtins.tail lst);

in
    listLength [1 2 3 4]
# evaluates to: 4
```

## `with` Keyword
The `with` keyword allows referencing attributes from a set, without always
specifying the set's name:
```nix
let
    age = {
        max = 23;
        lea = 26;
        tim = 32;
    };

in {
    without_with = [ age.max age.lea ];     # [ 23 26 ]
    with_with    = with age; [ max lea];    # [ 23 26 ]
}
```

## `inherit` Keyword
The `inherit` is shorthand for assigning the value of a *name* from an existing
scope to the *same name* in a nested scope.
```nix
let
    x = 1;
    y = 2;
in
{
    inherit x y;
}

# evaluates to: { x=1; y=2; }
```

It's also possible to `inherit` names from a specific attribute set with
parentheses:
```nix
let
    a = { x=1; y=2; };
in
{
    inherit (a) x y;    # equivalent to: x = a.x; y = a.y;
}
# evaluates to: { x=1; y=2; }
```

Inherit also works inside `let` expressions:
```nix
let
    inherit ({ x = 1; y = 2; }) x y;
in
    [ x y ]

# evaluates to: [ 1 2 ]
```


# Immutability
In Nix all values are immutable. Once a variable is set, it cannot be changed.

# Code Organization and Imports
Nix allows you to organize code into multiple `.nix` files and import them as
needed.
```nix
# utils.nix
{
    greet = name: "Hello ${name}!";
}
```

```nix
# main.nix
let
    utils = import ./utils.nix;
in
    utils.greet "John"
# evaluates to: "Hello John!"
```

If the path points to a directory, the file `default.nix` in that directory
is imported.

# `builtins`
Nix comes with many functions that are built into the language. They are
implemented in C++ as part of the Nix language interpreter.
These functions are available under the `builtins` constant.

All available `builtins` are listed here:
[Nix Reference Manual](https://nix.dev/manual/nix/2.24/language/builtins.html)

The following sections show some examples of built-in functions.

## `head list`
Return the first element of a list.
```nix
builtins.head [1 2 3] # evaluates to: 1
```

## `tail list`
Return the list without its first item.
```nix
builtins.tail [1 2 3] # evaluates to: [2 3]
```

## `attrNames set`
Return the names of the attributes in the parameter set in an alphabetically
sorted list.
```nix
builtins.attrNames { y=1; x="test"; } # evaluates to: [ "x" "y" ]
```

## `attrValues set`
Return the values of the attributes in the parameter set in the order
**corresponding to the sorted attribute names**.
```nix
builtins.attrValues { y=1; x="test"; } # evaluates to: [ "test" 1 ]
```

## `listToAttrs list`
Construct a set from a list specifying the names and values of each attribute.
Each element of the list should be a set consisting of a string-valued attribute
`name` specifying the name of the attribute, and an attribute `value`
specifying its value.

In case of duplicate occurrences of the same name, the first takes
precedence.

```nix
builtins.listToAttrs
    [
        { name = "foo"; value = 123; }
        { name = "bar"; value = 456; }
        { name = "bar"; value = 420; }
    ]
# evaluates to: { foo = 456; foo = 123; }
```

## `map f list`
Apply `f` to each element in `list`.
```nix
builtins.map (x: "foo" + x) [ "1" "2" "3" ]
# evaluates to: [ "foo1" "foo2" "foo3" ]
```

## `mapAttrs f attrset`
Apply functions `f` to every element of `attrset`.
```nix
builtins.mapAttrs (name: value: value * 10) { a = 1; b = 2; }
# evaluates to: { a = 10; b = 20; }
```

# `pkgs.lib`
The `nixpkgs` repository contains an attribute set called `lib`, which provides
a large number of useful functions. Tey are implemented in the Nix language,
as opposed to `builtins`, which are part of the language itself.


# Derivations
Derivations are at the core of both Nix and the Nix language:
-   The Nix language is used to describe derivations.
-   Nix runs derivations to produce build results.
-   Build results can in turn be used as inputs for other derivations.

The Nix language primitive to declare a derivation is the built-in *impure*
function `derivation`. It is usually wrapped by the Nixpkgs build mechanism
`stdenv.mkDerivation`, which hides much of the complexity involved in
non-trivial build procedures.

Whenever you encounter `mkDerivation`, it denotes something that Nix will
eventually **build**.

The evaluation result of `derivation` (and `mkDerivation`) is an attribute set
with a **certain structure** and a special property: It can be used in
string interpolation, and in that case evaluates to the Nix store path of
its build result, like the following examples shows:
```nix
let
    pkgs = import <nixpkgs> {};
in "${pkgs.nix}"
# evaluates to: "/nix/store/ixjixjj9f1k7h8rqab8frjhl6gm8k466-nix-2.18.8"
```

## The "raw" `derivation` Function
Derivations are created using the built-in `derivation` function, but you should
typically use a helper function from `nixpkgs` (which we'll talk about in a
moment) rather than calling `derivation` yourself.
However, under the hood, all helper functions eventually call the built-in
`derivation` function.

A derivation, upon evaluation, creates an immutable `.drv` file in the Nix store
(typically located at `/nix/store`) named by the hash of the derivation's
inputs. A separate step, called *realisation*, ensures that the outputs of the
derivation's builder programm are available as an immutable directory in the
Nix store, either by running the builder program or downloading the results of a
previous run from a cache. Since Nix takes precautions to make the builder
invocation hermetic
(details [here](https://nix.dev/manual/nix/2.24/language/derivations.html)),
these outputs can be shared safely between machines of the same OS and
architecture.


# Overrides and Overlays
*TODO*

# Flakes
Reading about Nix you also probably stumbled across the term "Flake". From a
language perspective, flakes are nothing but an **attribute set** with a
**standardized structure**.

That's what a flake looks like:
```nix
{
    description = "...";
    inputs = {
        # ...
    };
    outputs = {
        # ...
    };
}
```
A `flake.nix` file is an attribute set with two attributes called inputs and
outputs. The inputs attribute describes the other flakes that you would like to
use; things like `nixpkgs` or `home-manager`. You have to give it the url where
the code for that other flake is, and usually people use GitHub. The outputs
attribute is a function, which is where we really start getting into the nix
programming language. Nix will go and fetch all the inputs, load up their
`flake.nix` files, and it will call your outputs function with all of their
outputs as arguments. The outputs of a flake are just whatever its outputs
function returns, which can be basically anything the flake wants it to be.
Finally, nix records exactly which revision was fetched from GitHub in
flake.lock so that the versions of all your inputs are pinned to the same thing
until you manually update the lock file.

Now, I said that the outputs of a flake can be basically anything you want, but
by convention, there's a schema that most flakes adhere to. For instance,
flakes often include outputs like `packages.x86_64-linux.foo` as the derivation
for the foo package for `x86_64-linux`. But it's important to understand that
this is a convention, which the nix CLI uses by default for a lot of commands.
The reason I consider this important to understand is because people often
assume flakes are some complicated thing, and that therefore flakes somehow
change the fundamentals of how nix works and how we use it. They don't. All
the flakes feature does is look at the inputs you need, fetch them, and call
your outputs function. It's truly that simple. Pretty much everything else that
comes up when using flakes is actually just traditional nix, and not
flakes-related at all.

The only other significant difference from traditional nix is "purity". Flakes
disallow a lot of "impure" ideas, like depending on config files or environment
variables that aren't a part of the flake's source directory or its inputs'.
This makes it so that a derivation / system / etc. is reproducible no matter
what context you're evaluating the flake from.

In the following chapter we'll learn how to define a whole NixOS system
using such flakes. For this, it's important to know, that the output attribute
set is usually defined as a function, which takes in the inputs (defined the
`inputs` section) and produces an attribute set as return value.
This **output function** can also take a special parameter called `self`, which
is best explained with an example:
```nix
# flake.nix
{
    outputs = { self }: {
        a = 1;
        b = self.a + 1;
    };
}
```
Such a `flake.nix` file can be evaluated using the following command:
```sh
$ nix eval .#b      # evaluates to: 2
```
But `self` is much more than that. It references `inputs`, `outputs` and many
other things. It essentially is a reference to the entire flake "object".


# NixOS
With the basic understanding of what a flake is, we can now continue with the
probably most exciting part about Nix - namely NixOS. A NixOS configuration
can be defined in two different ways - as flake and "traditionally". I'll only
focus on the "flake way" of configuring NixOS.

Configuring NixOS with a flake means, that the "main entry point" of the
configuration is a flake. For a flake to be a NixOS configuration, we need
some special inputs, as well as certain outputs.

The `inputs` attribute set must at least contain `nixpkgs`, which is the
collection of Nix packages and therefore the source of all packages and
programs.

The `outputs` attribute set is usually defined as a function, which takes
the inputs and returns an attribute set. The returned attribute set must
then contain the attribute `nixosConfiguration` which again is an attribute
set with attributes for each system. Here's an example:
```nix
{
    description = "...";
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    };

    outputs = { self, nixpkgs, ...}@inputs: {
        nixosConfiuration = {
            machine-1 = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    # ...
                ];
            };

            machine-2 = nixpkgs.lib.nixosSystem { ... };
        };
    };
}
```

The function `nixosSystem` takes in an attribute set which must contain two
attributes:
-   `system`: defines the system architecture (e.g. `x86_64-linux`)
-   `modules`: a list of NixOS modules (explained later)

The **list of modules** passed to the `nixosSystem` function is then finally
the place, where the actual system configuration "happens". They are explained
in the next section.

## NixOS Modules
A NixOS module is a reusable, declarative configuration unit that defines how
various aspects of a NixOS system should be set up. Modules allow you to
configure services, system settings and packages in a modular and composable
way.

NixOS Modules are not anything special in regards to the Nix language.
A NixOS Module is just a Nix function, which returns an attribute set with
the attributes `imports`, `options` and `config`. Like so:
```nix
{ config, options, pkgs, lib, ... }: # <- Parameters of a NixOS module
{
    imports = [
        # ...
    ];

    options = {
        # define config options
    };

    config = {
        # set actual values for your system
    };
}
```

Explanation:
-   `options`: Defines configurable parameters (options) for the module,
    including their types, default values and descriptions. Example:
    ```nix
    options.myService.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable my custom service.";
    };
    ```

-   `config`: Accesses the *current system configuration* and allows the module
    to modify or extend it based on the options.
    ```nix
    config = mkIf config.myService.enable {
        systemd.services.myService = {
            description = "My Custom Service";
            after = [ "network.target" ];
            serviceConfig = {
                ExecStart = "${pkgs.myService}/bin/myService";
                Restart = "always";
            };
            wantedBy = [ "multi-user.target" ];
        };
    };
    ```

-   `imports`: Modules can import other NixOS modules


Under the hood, the NixOS configuration machinery merges all these module sets
together into one giant configuration.

### Parameters of NixOS Modules `{ config, options, pkgs, lib, ...}`
Before clarifying where the parameters are coming from, we first have to
understand what they mean:
-   `config`: the configuration of the entire system
-   `options`: all option declarations refined with all definition and
    declaration references
-   `lib`: an instance of the `nixpkgs` "standard library", providing what
    usually is in `pkgs.lib`
-   `pkgs`: the attribute set extracted from the nix package collection and
    enhanced with the `nixpkgs.config` option
-   `modulesPath`: location of the `module` directory of NixOS

These parameters are all passed automatically to a NixOS module, when it is
imported.

> The `config` **argument** is not the same as the `config` attribute:
>
> The `config` *argument* holds the result of the module system’s lazy
> evaluation, which takes into account all modules passed to evalModules and
> their imports.
>
> The `config` *attribute* of a module exposes that particular module’s option
> values to the module system for evaluation.


#### How do `pkgs` and `lib` get there?
The question now is, how does the `nixosSystem` function "get" the `pkgs`
and `lib` values, to pass them to all the modules?

And to be honest with you, I tried following the Nix source code, but couldn't
fully understand. But still, I want to try and explain the basic concept.

The `nixosSystem` function "knows" `nixpkgs` from our inputs and `system`,
because the `system` attribute is provided to the function as parameter.
`nixpkgs` is just a function, which returns the packages that are compatible
with your system, by providing the `system` variable. In simple terms this means
something like this: `pkgs = nixpkgs { inherit system };`

With that the `nixosSystem` function now has the `pkgs` variable and the
`lib` variable is easily extracted from it like so: `pkgs.lib`.


#### Adding additional Parameters
The `nixosSystem` function has an *optional* attribute set parameter called
`specialArgs`, which passes **its attributes** to all modules. Example:
```nix
nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
        myCustomArg = 1234;
        anotherValue = "hello";
    };
    modules = [
        ./configuration.nix
    ];
}
```

And here is the corresponding module:
```nix
{ config, pkgs, lib, myCustomArg, anotherValue, ... }:
{
    # Now we can use these custom arguments inside the module
    environment.systemPackages = [
        pkgs.hello
    ];

    # Example usage of myCustomArg:
    boot.initrd.luks.devices = {
        myEncDev = {
            device = "/dev/disk/by-uuid/${myCustomArg}";
            preLVM = true;
        };
    };
}
```

**Should You Use `specialArgs` for Everything?**
If it’s truly a global or advanced argument not covered by the normal NixOS
options system, `specialArgs` can be handy. But if you want to expose an option
that behaves like other NixOS configuration, you usually define a NixOS option
(using mkOption) and then set it in your configuration.nix.


#### Add unstable packages to `pkgs`
Example:
```nix
{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05"; # stable default
        nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable"; # unstable
    };

    outputs = { self, nixpkgs, nixpkgs-unstable, ... }:
        let
        system = "x86_64-linux";
        in {
        nixosConfigurations.yourSystem = nixpkgs.lib.nixosSystem {
            inherit system;

            modules = [
                # 0) Optional: Enable unfree for stable pkgs
                {
                    nixpkgs.config.allowUnfree = true;
                }

                # 1) Overlay the stable pkgs so that `pkgs.unstable` points to
                #    an imported unstable set
                {
                    nixpkgs.overlays = [
                        (final: prev: {
                            unstable = import nixpkgs-unstable {
                                inherit system;
                                # Optionally set allowUnfree, overlays, etc.
                                config = {
                                    allowUnfree = true;
                                };
                            };
                        })
                    ];
                }

                # 2) Normal system config
                {
                    # Now you can use pkgs.stableStuff or
                    # pkgs.unstable.someNewerPackage
                    environment.systemPackages = [
                        pkgs.hello                     # from stable
                        pkgs.unstable.firefox-nightly  # from unstable
                    ];
                }
            ];
        };
    };
}
```

## Inspect a (NixOS) Flake
When writing a new configuration it's oftentimes helpful to check if a
configuration is actually applied or if you might have an error in your code
somewhere. Setting up language servers like `nil` and `nixd` is very helpful
in this case, but only to a certain extend.

First, to get a basic view of what outputs a flake has, we can use
```sh
$ nix flake show .

# Example output when executing command on my system configuration
git+file:///...
└───nixosConfigurations
    ├───nuc: NixOS configuration
    └───p14s: NixOS configuration
```

To actually expect what your Nix flake **evaluates to** you can load it up in
the repl, and query the configurations/options.
```sh
$ nix repl

nix-repl> :lf . # <- loads flake from the current directory
Added X variables

# Example from my system configuration
nix-repl> nixosConfigurations.<machine-name>.config.programs.sway.enable
true
```


---

# Attributions
-   [Nix from the Ground up](https://www.zombiezen.com/blog/2021/12/nix-from-the-ground-up/)
-   [Nix Dev - Nix Language Tutorial](https://nix.dev/tutorials/nix-language.html)
-   [Nix Dev - Module System Deep Dive](https://nix.dev/tutorials/module-system/deep-dive.html)
-   [Nix Manual - Builtins](https://nix.dev/manual/nix/2.24/language/builtins.html)
-   [YouTube - Nix explained from the ground up](https://www.youtube.com/watch?v=5D3nUU1OVx8)
-   [YouTube - Introduction to Nix and NixOS (Wil T)](https://www.youtube.com/watch?v=QKoQ1gKJY5A)
-   [NixOS Wiki - Modules](https://nixos.wiki/wiki/NixOS_modules)
-   [Reddit - Flake Explanation](https://www.reddit.com/r/NixOS/comments/131fvqs/comment/ji0f3gl)
