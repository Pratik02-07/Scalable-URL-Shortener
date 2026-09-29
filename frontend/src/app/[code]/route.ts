import { NextRequest, NextResponse } from "next/server";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ code: string }> }
) {
  const { code } = await params;

  // Skip static assets or reserved routes
  if (
    code === "favicon.ico" ||
    code === "robots.txt" ||
    code === "sitemap.xml" ||
    code === "api"
  ) {
    return new NextResponse(null, { status: 404 });
  }

  const base = (
    process.env.BACKEND_URL ||
    process.env.NEXT_PUBLIC_API_URL ||
    "http://localhost:8000"
  ).replace(/\/+$/, "");

  try {
    const res = await fetch(`${base}/${code}`, {
      method: "GET",
      redirect: "manual",
    });

    const location = res.headers.get("location");
    if (location) {
      return NextResponse.redirect(location, 302);
    }

    if (res.status === 404) {
      return new NextResponse("Short link not found", { status: 404 });
    }

    return new NextResponse(await res.text(), { status: res.status });
  } catch (error) {
    console.error("Redirect proxy error:", error);
    return NextResponse.redirect(`${base}/${code}`, 302);
  }
}
