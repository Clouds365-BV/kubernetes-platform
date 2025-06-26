"""
FastAPI Demo Application.

This module provides a simple REST API with CRUD operations for items.
It demonstrates basic FastAPI functionality including path parameters and Pydantic models.
"""

import os
from typing import Union

from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()


class Item(BaseModel):
    """Item model representing products in the system."""

    name: str
    price: float
    is_offer: Union[bool, None] = None


@app.get("/")
def read_root():
    """Root endpoint that returns a simple greeting message."""
    return {"Hello": "World"}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: Union[str, None] = None):
    """Retrieve an item by its ID with an optional query parameter."""
    return {"item_id": item_id, "q": q}


@app.put("/items/{item_id}")
def update_item(item_id: int, item: Item):
    """Update an existing item by its ID."""
    return {"item_name": item.name, "item_id": item_id}


@app.get("/data")
def data():
    """Retrieve environment configuration data."""
    db_password = os.getenv("DB_PASSWORD")

    api_base_url = os.getenv("API_BASE_URL")
    log_level = os.getenv("LOG_LEVEL")
    max_connections = os.getenv("MAX_CONNECTIONS")

    return {
        "DB_PASSWORD": db_password,
        "API_BASE_URL": api_base_url,
        "LOG_LEVEL": log_level,
        "MAX_CONNECTIONS": max_connections,
        "ENVIRONMENT": os.getenv("ENVIRONMENT"),
    }
