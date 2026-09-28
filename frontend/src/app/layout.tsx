import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "LinkSnip — Scalable URL Shortener",
  description:
    "A blazing-fast, production-grade URL shortener built on FastAPI, Redis, and PostgreSQL. Shorten long links in milliseconds.",
  keywords: ["url shortener", "link shortener", "short url", "linksnip"],
  openGraph: {
    title: "LinkSnip — Scalable URL Shortener",
    description: "Shorten long URLs instantly. Built for scale.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>{children}</body>
    </html>
  );
}
