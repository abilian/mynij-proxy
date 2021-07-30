Mynij Proxy 
===========

A proxy that adds CORS headers to GET request for use by the Mynij
search engine.

Uses Starlette as its ASGI framework, and HTTPX as the HTTP client.

(We may switch to aiohttp.client instead of httpx later).

Web server + workers are: gunicorn + uvicorn.
