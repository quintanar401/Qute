#### Function definition

```
{|| expr; ... } // without arguments
{|a b c| expr; ...} // with arguments
\_ expr // ??? inline definition for small functions with optional default arguments x,y,z
\_ {expr; ...} // possible but unnecessary syntax
{expr; ...} // NOT a function, just a block
```

#### Function return

```
{|| expr; ...; last_expr } // by default the result of the last expr is returned
{|| expr; ...;} // all functions return a value, by default it is ID function
{|| expr;...;ret expr;...} // ret keyword can be used to return a result explicitly
ret; // return the default value (ID function)
```

#### Function environment

* Global environment - language functions, static binding.
* Local environment - imports, definitions, dynamic binding.
* Local variables in outer functions.
* Local variables in the function.

Interractive loop:
```
eval(env;expr) -> (new env;result)
```

Global environment - a namespace within the local environment.

#### Function calls

```
fn(); fn(arg); fn(arg1;...;argN) // generic way to call a function
fn (); fn arg; // generic way to call a function with 0/1 argument
fn arg1 ` arg2 ` ... ` argN // alternative way to call a function with more than 1 argument
arg1 transitive_fn arg2 ` ... ` argN // if fn is transitive arg1 is expected before fn
```

There are related syntactic features:
```
f@a b // @ without spaces can be used to modify the order of evaluation
      // parsed as "(f a) b"
a f@b c // if f is transitive then: (a f b) c
.. a b@ c // if there is a space after @: (.. a b) c
a@-b // ????
```

#### Recursion

```
{|..| .. self(arg1;..) ..} // use self to refer to the current function
```

#### Composition

```
a b c@ // if an expression ends with @ it is treated as a composition of functions
a b trans_f // if it ends with a transitive function - also a composition
a\. // create a function that accepts any number of args and passes them as a list into a
```

### Pattern matching

```Rust
?[expr; patt1 => expr1; ...] // large expression
?[patt1 => expr1; ...] expr  // small expressions, more readable 
```

#### Evaluation order

expr is always evaluated first, then patterns one by one until one matches. If there is none an exception is thrown. All bindings in the previous patterns are visible in the next patterns.

#### Patterns

```Rust
_  // anything, always succeeds
10 "str" and etc // constants, match: value ~ constant
name // always succeeds, value is assigned to the name
() (p) (p1;p2) (p;..) (..;p) (p1;..;p2) // match a generic list or vector with a fixed or variable number of elements
L(..) S() and etc // type letter can be put before () to specify the exact type with L - generic
name[..] name[field: p1] name[field: p1; field2: p2] // match a record
p1 | p2 // p1 or p2
name: p1 // assign p1 value to name
@name // take a constant from variable 'name'
p & expr // a guard expr is evaluated if p is true, expr is limited by )];| and =>
?[(expr1;expr2);(p1;p2) => .. ] // match more than 1 expr at the same time
```

### Code Quality

Precondition:
```Rust
\pre a>b
f:{|a b| ...}
```

Postcondition:
```Rust
\post res>0
f:{|a b| ...}
```

Invariant on a record:
```Rust
// rec is rec[a;b;c]
invariant('rec';`a;{|r a| a > r.b r.c}); // when a is changed run this fn, raise an exception if it is not true
```

Interaction: monitor, superviser, link between processes, priority, resource limits.

### Dynamic environment and expressions

Every expression is evaluated within a dynamic enviroment: name!value. Any top level assignment will be to this environment:
```Rust
a:10 // means dyn_env(`a):10
{ a:10 } // means local assignment
```

Any new function will be indirectly associated with the current dynamic environment. Whenever a function is spawned/sent via a channel or
in other words looses its connection with the environment its indirect link to the environment will be substituted with the environment's
current value list capturing the dynamic state at this moment and making it static. Functions can access the dynamic environment directly
by a variable name. In this case spawn and etc will not affect them:
```Rust
{ 'a' set 10; get 'a'} // access the dynamic variable 'a'
```

Modularization happens when we take the current dynamic environment, "sanitize" (to be specified) the values by making all
functions static and save this list as a module under some name. Make a snapshot of the current state that is guaranteed to be
static and the same after this for all functions.

### Interractive vs module mode

Interractive mode is to be used by users that what to execute expressions 1 by 1. In this case we need to allow somethings that
should be denied if in module mode.

#### Undefined global

In the module mode it is an error. We can't allow dangling referencies. If a developer wants to use a dynamic variable he/she
must do it explicitly or explicitly define it as a global within the module.
```Rust
f:{ a+1 }; // No! a is undefined
g:{ b+1 }; // yes, b is defined
b:10;
```

On the other hand in the interractive mode such variables are inevitable and must be added implicitly to the dynamic environment.
```Rust
f:{ a+1 }; // a is undefined atm but probably will be defined before f is called
```

#### Assignments

In the module mode an assignment to global is an error. All module functions share the same static environment so assignments do not make sense.

In the interractive mode assignments are allowed. Not sure what to do if such a function becomes static - error or proceed with the assigment?

### Global vs local vars

A variable is a local if there is an assign before any read (as in Q). In cases when the rule doesn't work mark a var as either global or local:
```Rust
{|| \glob a b c; \loc f g h; ...};
```
`loc` will create locals even if they are not used. `glob` will not create a global variable in a module you need to define it explicitly.