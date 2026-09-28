"use client";

import { useState, useCallback, useRef } from "react";
import styles from "./page.module.css";

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";

interface ShortenResponse {
  short_code: string;
  short_url: string;
  original_url: string;
  click_count: number;
  created_at: string;
  is_active: boolean;
}

interface StatsResponse {
  short_code: string;
  original_url: string;
  click_count: number;
  created_at: string;
  is_active: boolean;
}

function LinkIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M10 13a5 5 0 007.54.54l3-3a5 5 0 00-7.07-7.07l-1.72 1.71"/>
      <path d="M14 11a5 5 0 00-7.54-.54l-3 3a5 5 0 007.07 7.07l1.71-1.71"/>
    </svg>
  );
}

function BarChartIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/>
      <line x1="6" y1="20" x2="6" y2="14"/>
    </svg>
  );
}

function CopyIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="9" y="9" width="13" height="13" rx="2" ry="2"/>
      <path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/>
    </svg>
  );
}

function CheckIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="20 6 9 17 4 12"/>
    </svg>
  );
}

function ExternalIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 13v6a2 2 0 01-2 2H5a2 2 0 01-2-2V8a2 2 0 012-2h6"/>
      <polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/>
    </svg>
  );
}

export default function HomePage() {
  const [activeTab, setActiveTab] = useState<"shorten" | "stats">("shorten");

  // Shorten
  const [url, setUrl] = useState("");
  const [alias, setAlias] = useState("");
  const [result, setResult] = useState<ShortenResponse | null>(null);
  const [shortenError, setShortenError] = useState("");
  const [shortenLoading, setShortenLoading] = useState(false);
  const [copied, setCopied] = useState(false);
  const urlRef = useRef<HTMLInputElement>(null);

  // Stats
  const [statsCode, setStatsCode] = useState("");
  const [stats, setStats] = useState<StatsResponse | null>(null);
  const [statsError, setStatsError] = useState("");
  const [statsLoading, setStatsLoading] = useState(false);

  const handleShorten = useCallback(async (e: React.FormEvent) => {
    e.preventDefault();
    setShortenError("");
    setResult(null);
    setCopied(false);
    if (!url.trim()) { setShortenError("Enter a URL to shorten."); return; }
    setShortenLoading(true);
    try {
      const body: Record<string, string> = { url: url.trim() };
      if (alias.trim()) body.custom_alias = alias.trim();
      const res = await fetch(`${API_URL}/api/v1/shorten`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      if (!res.ok) {
        const err = await res.json();
        setShortenError(err.detail ?? "Request failed.");
        return;
      }
      setResult(await res.json());
    } catch {
      setShortenError("Could not reach the backend. Is it running?");
    } finally {
      setShortenLoading(false);
    }
  }, [url, alias]);

  const handleCopy = useCallback(() => {
    if (!result) return;
    navigator.clipboard.writeText(result.short_url).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  }, [result]);

  const handleStats = useCallback(async (e: React.FormEvent) => {
    e.preventDefault();
    setStatsError("");
    setStats(null);
    if (!statsCode.trim()) { setStatsError("Enter a short code."); return; }
    setStatsLoading(true);
    try {
      const res = await fetch(`${API_URL}/api/v1/stats/${statsCode.trim()}`);
      if (!res.ok) {
        const err = await res.json();
        setStatsError(err.detail ?? "Not found.");
        return;
      }
      setStats(await res.json());
    } catch {
      setStatsError("Could not reach the backend. Is it running?");
    } finally {
      setStatsLoading(false);
    }
  }, [statsCode]);

  const formatDate = (iso: string) =>
    new Date(iso).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });

  const truncate = (s: string, n: number) => s.length > n ? s.slice(0, n) + "…" : s;

  return (
    <div className={styles.layout}>
      {/* ── Nav ── */}
      <nav className={styles.nav}>
        <div className={styles.navInner}>
          <div className={styles.logo}>
            <div className={styles.logoMark} aria-hidden="true">
              <LinkIcon />
            </div>
            <span className={styles.logoName}>LinkSnip</span>
          </div>
          {/* <div className={styles.navPills}>
            <span className={styles.pill}>FastAPI</span>
            <span className={styles.pill}>Redis</span>
            <span className={styles.pill}>PostgreSQL</span>
            <span className={styles.pillLive}>
              <span className={styles.liveDot} />
              Live
            </span>
          </div> */}
        </div>
      </nav>

      <main className={styles.main}>
        {/* ── Hero ── */}
        <header className={styles.hero}>
          <h1 className={styles.heading}>
            Short links, <span className={styles.accent}>at scale</span>
          </h1>
          <p className={styles.subheading}>
            Production-grade URL shortener backed by Redis caching and PostgreSQL persistence.
            Serving redirects in under 10&nbsp;ms.
          </p>
        </header>

        {/* ── Panel ── */}
        <section className={styles.panel} aria-label="URL shortener tool">
          {/* Tab row */}
          <div className={styles.tabRow} role="tablist">
            <button
              role="tab"
              id="tab-shorten"
              aria-selected={activeTab === "shorten"}
              aria-controls="panel-shorten"
              className={`${styles.tabBtn} ${activeTab === "shorten" ? styles.tabBtnActive : ""}`}
              onClick={() => setActiveTab("shorten")}
            >
              <LinkIcon /> Shorten
            </button>
            <button
              role="tab"
              id="tab-stats"
              aria-selected={activeTab === "stats"}
              aria-controls="panel-stats"
              className={`${styles.tabBtn} ${activeTab === "stats" ? styles.tabBtnActive : ""}`}
              onClick={() => setActiveTab("stats")}
            >
              <BarChartIcon /> Analytics
            </button>
          </div>

          {/* ── Shorten ── */}
          {activeTab === "shorten" && (
            <div id="panel-shorten" role="tabpanel" aria-labelledby="tab-shorten">
              <form onSubmit={handleShorten} noValidate className={styles.form}>
                {/* URL field */}
                <div className={styles.field}>
                  <label className={styles.label} htmlFor="url-input">
                    Destination URL
                  </label>
                  <input
                    ref={urlRef}
                    id="url-input"
                    type="url"
                    className={styles.input}
                    placeholder="https://example.com/very/long/path"
                    value={url}
                    onChange={e => setUrl(e.target.value)}
                    autoComplete="url"
                    spellCheck={false}
                  />
                </div>

                {/* Alias field */}
                <div className={styles.field}>
                  <div className={styles.labelRow}>
                    <label className={styles.label} htmlFor="alias-input">Custom alias</label>
                    <span className={styles.labelHint}>optional</span>
                  </div>
                  <div className={styles.inputGroup}>
                    <span className={styles.inputPrefix}>short.ly/</span>
                    <input
                      id="alias-input"
                      type="text"
                      className={`${styles.input} ${styles.inputSuffix}`}
                      placeholder="my-link"
                      value={alias}
                      onChange={e => setAlias(e.target.value)}
                      maxLength={50}
                      spellCheck={false}
                    />
                  </div>
                </div>

                {shortenError && (
                  <p className={styles.errorBanner} role="alert">{shortenError}</p>
                )}

                <button
                  id="shorten-btn"
                  type="submit"
                  className={styles.submitBtn}
                  disabled={shortenLoading}
                >
                  {shortenLoading
                    ? <span className={styles.spinner} aria-label="Loading" />
                    : "Generate short link"}
                </button>
              </form>

              {result && (
                <div className={styles.resultBox} role="status" aria-live="polite">
                  <div className={styles.resultTopRow}>
                    <span className={styles.resultLabel}>Short link ready</span>
                    <a
                      href={result.short_url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className={styles.externalLink}
                      aria-label="Open short link"
                    >
                      <ExternalIcon />
                    </a>
                  </div>

                  <div className={styles.resultLinkRow}>
                    <code className={styles.shortUrl}>{result.short_url}</code>
                    <button
                      id="copy-btn"
                      onClick={handleCopy}
                      className={`${styles.copyBtn} ${copied ? styles.copyBtnDone : ""}`}
                      aria-label="Copy to clipboard"
                    >
                      {copied ? <><CheckIcon /> Copied</> : <><CopyIcon /> Copy</>}
                    </button>
                  </div>

                  <div className={styles.resultMeta}>
                    <span className={styles.metaItem}>
                      <span className={styles.metaKey}>Original</span>
                      <span className={styles.metaVal} title={result.original_url}>
                        {truncate(result.original_url, 52)}
                      </span>
                    </span>
                    <span className={styles.metaDivider} />
                    <span className={styles.metaItem}>
                      <span className={styles.metaKey}>Code</span>
                      <code className={styles.metaCode}>{result.short_code}</code>
                    </span>
                    <span className={styles.metaDivider} />
                    <span className={styles.metaItem}>
                      <span className={styles.metaKey}>Created</span>
                      <span className={styles.metaVal}>{formatDate(result.created_at)}</span>
                    </span>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* ── Stats ── */}
          {activeTab === "stats" && (
            <div id="panel-stats" role="tabpanel" aria-labelledby="tab-stats">
              <form onSubmit={handleStats} noValidate className={styles.form}>
                <div className={styles.field}>
                  <label className={styles.label} htmlFor="stats-input">
                    Short code
                  </label>
                  <input
                    id="stats-input"
                    type="text"
                    className={styles.input}
                    placeholder="aB91xK"
                    value={statsCode}
                    onChange={e => setStatsCode(e.target.value)}
                    spellCheck={false}
                    autoCapitalize="none"
                  />
                </div>

                {statsError && (
                  <p className={styles.errorBanner} role="alert">{statsError}</p>
                )}

                <button
                  id="stats-btn"
                  type="submit"
                  className={styles.submitBtn}
                  disabled={statsLoading}
                >
                  {statsLoading
                    ? <span className={styles.spinner} aria-label="Loading" />
                    : "Look up analytics"}
                </button>
              </form>

              {stats && (
                <div className={styles.resultBox} role="status" aria-live="polite">
                  <div className={styles.statsGrid}>
                    <div className={styles.statCell}>
                      <span className={styles.statNum}>{stats.click_count.toLocaleString()}</span>
                      <span className={styles.statDesc}>Clicks</span>
                    </div>
                    <div className={styles.statCell}>
                      <span className={`${styles.statNum} ${stats.is_active ? styles.statGreen : styles.statRed}`}>
                        {stats.is_active ? "Active" : "Inactive"}
                      </span>
                      <span className={styles.statDesc}>Status</span>
                    </div>
                    <div className={styles.statCell}>
                      <span className={styles.statNum}>{formatDate(stats.created_at)}</span>
                      <span className={styles.statDesc}>Created</span>
                    </div>
                  </div>
                  <div className={styles.statsOriginal}>
                    <span className={styles.metaKey}>Destination</span>
                    <a
                      href={stats.original_url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className={styles.statsLink}
                      title={stats.original_url}
                    >
                      {truncate(stats.original_url, 60)} <ExternalIcon />
                    </a>
                  </div>
                </div>
              )}
            </div>
          )}
        </section>

        {/* ── Stack row ── */}
        <footer className={styles.footer}>
        </footer>
      </main>
    </div>
  );
}
