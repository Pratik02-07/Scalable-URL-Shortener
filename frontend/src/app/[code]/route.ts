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

  return NextResponse.redirect(`${base}/${code}`, 302);
}
