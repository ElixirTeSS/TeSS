# RDoc Conventions

## Class/module documentation

A comment block above every `class`/`module`, explaining:
- **its role** in one short sentence,
- the **business context** if necessary (e.g. why this model exists, what it collaborates with),
- points of attention (e.g. "inherits from X rather than Y").

```ruby
# One-line summary.
#
# Explanatory paragraph(s) if the role isn't trivial.
class MyClass
```

## Method documentation

Systematic structure, in this order:

1. **Description** of what the method does (behavior, not implementation).
2. **Parameters**, listed as `name:: description` (classic RDoc style, double `::`).
3. **Return value**, with the `Returns::` keyword.
4. **Exceptions**, with `Raises::`, if the method can intentionally raise an error.
5. **Yields**, if the method takes a block.

```ruby
# Does this and that.
#
# param1:: description of the parameter.
# param2:: description, with default value if relevant.
#
# Raises:: ExceptionClass if such condition.
#
# Returns:: description of the returned type/object.
def my_method(param1, param2 = nil)
```

## Specific rules to follow

- **Rails callbacks** (`before_action`, `before_destroy`, custom validators, etc.): documented like regular methods, explicitly stating that it's a callback and when it runs (e.g. *"before_destroy callback that..."*).
- **Trivial methods** (e.g. simple accessors, `default?` that returns `false`): one line is enough, no over-documentation.
- **Constants**: a one-line comment right above (`FEATURES`, `DEFAULT_PAGE_SIZE`, etc.).
- **Nested classes** (e.g. `ApplicationPolicy::Scope`, `Space::CheckPrivateSpace`): documented as full-fledged classes, with their own `initialize`/methods commented.
- **No duplication**: if the behavior is fully explained by `Returns::` (e.g. `def update? = manage?`), the logic isn't re-explained in the description body.

## Important notes

- `param::` / `Returns::` / `Raises::` are **natively recognized by RDoc** and will generate clean HTML docs (parameter list separated from the text).
- Documenting *behavior* rather than *paraphrasing the code* makes the docs useful even without reading the implementation.
- Documenting callbacks/private methods as well helps understand the flow (e.g. `set_current_space`, `fetch_resources`) without having to trace through the whole controller.