# Python

Read for any Python implementation task (language idioms, packaging, layout, testing). Companion: `pydantic.md` when `pydantic`/`BaseModel` appears; vendor FastAPI skill when `fastapi` appears (see router).

## When to use

Any Python implementation task (language-level idioms, packaging, layout, pytest).

## Detection signals

- `pyproject.toml`, `requirements*.txt`, `setup.py`, `*.py` sources, `.venv` / `uv.lock`.

## Conventions

- Target Python 3.9+; use builtin generics (`list[str]`, `dict[str, int]`), not `typing.List/Dict`.
- Annotate all function signatures; keep `pyproject.toml` with `requires-python`, dev extras (pytest, ruff/black, mypy).
- Prefer EAFP (try/except) over look-before-you-leap; catch specific exceptions and chain with `raise ... from e`.
- Manage resources with `with` / `@contextmanager`; never manual open/close.
- Use list comprehensions for simple transforms, generator expressions/functions for large data (`sum(x*x for x in ...)`).
- Model data with `@dataclass` (validate in `__post_init__`) or `NamedTuple` for immutable values.
- Decorators must use `functools.wraps`; import order stdlib → third-party → local (isort).
- Layout: `src/<pkg>/{api,models,utils}`, `tests/` with `conftest.py`, `pyproject.toml` at root.
- Tooling: `ruff check .`, `black .`, `mypy .` (with `disallow_untyped_defs`), `pytest --cov=<pkg>`.
- Testing (TDD red-green-refactor, 80%+ coverage): fixtures with `yield` for setup/teardown in `conftest.py`; `@pytest.mark.parametrize` for variants; `unittest.mock.patch` for boundaries; `pytest-asyncio` for async code.

```python
def first(items: list[str]) -> str | None:
    return items[0] if items else None

@pytest.mark.parametrize("a,b,expected", [(2, 3, 5), (0, 0, 0)])
def test_add(a: int, b: int, expected: int) -> None:
    assert add(a, b) == expected
```

## Pitfalls

- Mutable default args (`def f(items=[])`) — use `None` + construct inside.
- Bare `except:` / silent `None` returns — catch specific errors, log, rethrow.
- `type(x) == list` and `== None` — use `isinstance(x, list)` and `is None`.
- `from module import *` — explicit imports only.
- String `+=` in loops (O(n²)) — use `"".join(...)`.
- Threads for I/O-bound, processes for CPU-bound, `asyncio` for concurrent I/O — do not mix blocking calls into async code.
- For workflow/test-infrastructure detail (TDD cycle, coverage, mocking), see the `clean-code` skill §7.

Source: adapted from affaan-m/ECC `python-patterns` + `python-testing` — MIT, Copyright (c) 2026 Affaan Mustafa.
