import type { NextConfig } from "next";

function getBackendUrl(): string {
  let url =
    process.env.BACKEND_URL ||
    process.env.NEXT_PUBLIC_API_URL ||
    "http://localhost:8000";

  // Prepend http:// if protocol is missing (Render's 'property: host' returns raw hostname)
  if (!url.startsWith("http://") && !url.startsWith("https://")) {
    url = `http://${url}`;
  }

  // If internal hostname without port and without domain dots, default to port 8000
  try {
    const parsed = new URL(url);
    if (!parsed.port && !parsed.hostname.includes(".")) {
      parsed.port = "8000";
      url = parsed.toString().replace(/\/$/, "");
    }
  } catch {
    // keep url as is
  }

  return url;
}

const backendUrl = getBackendUrl();

const nextConfig: NextConfig = {
  output: "standalone",
  async rewrites() {
    return [
      {
        source: "/api/:path*",
        destination: `${backendUrl}/api/:path*`,
      },
    ];
  },
};

export default nextConfig;
