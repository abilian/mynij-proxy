from __future__ import annotations

from typing import Mapping, Any

import httpx
from starlette.applications import Starlette
from starlette.endpoints import HTTPEndpoint
from starlette.requests import Request
from starlette.responses import PlainTextResponse, Response
from starlette.routing import Route

TIMEOUT = 60

DEFAULT_ACCESS_URL = "https://mynij.app.officejs.com"

httpx_session = httpx.AsyncClient()


class ProxyEndPoint(HTTPEndpoint):
    headers: Mapping[str, str]
    url: str

    async def get(self, request: Request) -> Response:
        self.headers = request.headers
        self.url = request.query_params["url"]

        status_code, content, new_headers = await self.fetch_content()
        response = Response(content, status_code, new_headers)
        return response

    async def fetch_content(self) -> tuple[int, bytes, dict]:
        proxy_query_header = self.make_query_headers(self.headers)
        body = b""
        response_headers = {}

        try:
            proxy_response = await httpx_session.get(
                self.url, headers=proxy_query_header, timeout=TIMEOUT
            )
            response_headers = self.filter_response_headers(proxy_response)
            response_headers["Access-Control-Allow-Origin"] = self.get_access_url()
            body = proxy_response.content
            status = proxy_response.status_code

        # except SSLError:
        #     # Invalid SSL Certificate
        #     status = 526
        except TimeoutError:
            # Gateway Timeout
            status = 504
        except httpx.TransportError:
            # Service Unavailable
            status = 503
        except httpx.HTTPError:
            # Internal Server Error
            status = 500

        return status, body, response_headers

    @staticmethod
    def make_query_headers(headers: Mapping[str, Any]) -> dict[str, str]:
        request_headers = {}
        keep_headers = [
            "Content-Type",
            "Accept",
            "Accept-Language",
            "Range",
            "If-Modified-Since",
            "If-None-Match",
        ]
        for k in keep_headers:
            v = headers.get(k)
            if v:
                request_headers[k] = str(v)

        return request_headers

    def get_access_url(self) -> str:
        return self.headers.get("Origin", DEFAULT_ACCESS_URL)

    def filter_response_headers(self, proxy_response: httpx.Response) -> dict[str, str]:
        headers = {}
        keep_headers = [
            "Content-Disposition",
            "Content-Type",
            "Date",
            "Last-Modified",
            "Vary",
            "Cache-Control",
            "Etag",
            "Accept-Ranges",
            "Content-Range",
        ]
        for k, v in proxy_response.headers.items():
            k = k.title()
            if k in keep_headers:
                headers[k] = v
        return headers


async def ping(request) -> Response:
    return PlainTextResponse("OK")


routes = [
    Route("/proxy", ProxyEndPoint),
    Route("/ping", ping),
]


app = Starlette(debug=True, routes=routes)
