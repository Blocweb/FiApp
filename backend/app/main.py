"""Expose the FastAPI application under the module path expected by Uvicorn."""

from main import app

__all__ = ["app"]
