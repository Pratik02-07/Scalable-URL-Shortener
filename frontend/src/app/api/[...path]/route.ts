import { NextRequest, NextResponse } from "next/server";

function getTargetUrl(path: string[], search: string): string {
  const base = (
    process.env.BACKEND_URL ||
    process.env.NEXT_PUBLIC_API_URL ||
    "http://localhost:8000"
  ).replace(/\/+$/, "");

  return `${base}/api/${path.join("/")}${search}`;
}

async function handleProxy(request: NextRequest, path: string[]) {
  const targetUrl = getTargetUrl(path, request.nextUrl.search);

  try {
    const headers: Record<string, string> = {};
    const contentType = request.headers.get("content-type");
    if (contentType) headers["content-type"] = contentType;
    const accept = request.headers.get("accept");
    if (accept) headers["accept"] = accept;
    const auth = request.headers.get("authorization");
    if (auth) headers["authorization"] = auth;

    let body: string | undefined = undefined;
    if (request.method !== "GET" && request.method !== "HEAD") {
      body = await request.text();
    }

    const res = await fetch(targetUrl, {
      method: request.method,
      headers,
      body,
    });

    const data = await res.text();
    return new NextResponse(data, {
      status: res.status,
      headers: {
        "content-type": res.headers.get("content-type") || "application/json",
      },
    });
  } catch (error) {
    console.error("Backend proxy error:", error);
    return NextResponse.json(
      { detail: `Failed to connect to backend at ${targetUrl}: ${String(error)}` },
      { status: 502 }
    );
  }
}

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const { path } = await params;
  return handleProxy(request, path);
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const { path } = await params;
  return handleProxy(request, path);
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const { path } = await params;
  return handleProxy(request, path);
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const { path } = await params;
  return handleProxy(request, path);
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const { path } = await params;
  return handleProxy(request, path);
}

export async function HEAD(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const { path } = await params;
  return handleProxy(request, path);
}

