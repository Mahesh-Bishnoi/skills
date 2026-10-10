# Pydantic

Read for Pydantic models, validation, and settings. Always read alongside the Python guide. (ECC has no standalone Pydantic skill; this is distilled from its FastAPI/Pydantic sections.)

## When to use

Pydantic v2 models, validation, settings. Read alongside the Python guide.

## Detection signals

- `pydantic` in `pyproject.toml` / `requirements*.txt`, `BaseModel` / `BaseSettings` imports.

## Conventions

- Pydantic v2 only: `BaseModel` + `Field(min_length=..., max_length=...)`; cross-field checks via `@model_validator(mode="after")`; ORM mapping via `model_config = {"from_attributes": True}`.
- Separate `*Create` / `*Update` (all-optional, `exclude_unset=True` on apply) / response schemas; always set `response_model` on FastAPI routes.
- Settings via `pydantic-settings` `BaseSettings` with `SettingsConfigDict(env_file=".env")`; required secrets (`database_url`, `secret_key`) with no defaults.
- Prefer `EmailStr` and constrained `Field` over hand-rolled regex; rely on DB unique constraints + `IntegrityError` mapping rather than race-prone app prechecks.

```python
class UserCreate(UserBase):
    password: str = Field(min_length=8)
    password_confirm: str

    @model_validator(mode="after")
    def passwords_match(self) -> "UserCreate":
        if self.password != self.password_confirm:
            raise ValueError("Passwords do not match")
        return self

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")
    database_url: str
    secret_key: str
```

## Pitfalls

- v1 idioms in v2 code (`class Config: orm_mode`, `@validator`, `@root_validator`) — use `model_config`, `@field_validator`, `@model_validator`.
- Mutable list defaults are safe in v2-settings but still use `Field(default_factory=...)` on plain `BaseModel` list fields.
- Optional update fields without `exclude_unset=True` overwrite stored values with `None`.
- `str | None = None` without `Field` constraints silently drops length validation — repeat constraints on update schemas.
- Validating secrets/URLs as bare `str` instead of constrained types; hand-parsing JWT payload ints/strings without defensive casts.

Source: adapted from affaan-m/ECC `fastapi-patterns` (Pydantic Schemas v2 + pydantic-settings sections) — MIT, Copyright (c) 2026 Affaan Mustafa.
